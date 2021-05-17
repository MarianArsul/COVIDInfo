//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPolylineEditTool.h"
#import "PTAnnotEditToolSubclass.h"

#import "PTAnnotStyle.h"
#import "PTMeasurementUtil.h"
#import "PTSelectionRectContainerView.h"
#import "PTAnnotStyleDraw.h"
#import "PTMagnifierView.h"

#import "NSArray+PTAdditions.h"
#import "CGGeometry+PTAdditions.h"
#import "PTLineAnnot+PTAdditions.h"

static const CGPoint PTCGPointInvalid = { .x = CGFLOAT_MAX, .y = CGFLOAT_MAX };

static CGPoint PTPDFPointToCGPoint( PTPDFPoint * _Nonnull point)
{
    return CGPointMake([point getX], [point getY]);
}

static PTPDFPoint * _Nonnull CGPointToPTPDFPoint(CGPoint point)
{
    return [[PTPDFPoint alloc] initWithPx:point.x py:point.y];
}

static PTPDFRect * _Nonnull CGRectToPTPDFRect(CGRect rect)
{
    double x1 = CGRectGetMinX(rect);
    double y1 = CGRectGetMaxY(rect);
    double x2 = CGRectGetMaxX(rect);
    double y2 = CGRectGetMinY(rect);
    
    return [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
}

@interface PTPolylineEditTool ()

@property (nonatomic, strong, nullable) PTLineAnnot *polyLineAnnot;

@property (nonatomic, strong, nullable) PTAnnotStyle *annotStyle;

@property (nonatomic, assign) double borderEffectIntensity;

@end

@interface PTPolylineEditTool ()
{
  PTMagnifierView* loupe;
}
@end

@implementation PTPolylineEditTool

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        self.opaque = NO;
        
        _selectedVertexIndex = NSNotFound;
        _touchStartPoint = PTCGPointInvalid;
        _touchEndPoint = PTCGPointInvalid;
        
    }
    return self;
}

#pragma mark - PTAnnotEditTool

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didCommitStyle:(PTAnnotStyle *)annotStyle
{
    [super annotStyleViewController:annotStyleViewController didCommitStyle:annotStyle];
    
    self.annotStyle = [[PTAnnotStyle allocOverridden] initWithAnnot:self.currentAnnotation];
}

-(void)setCurrentAnnotation:(PTAnnot *)currentAnnotation
{
    [super setCurrentAnnotation:currentAnnotation];
    
    if (currentAnnotation) {
        self.annotStyle = [[PTAnnotStyle allocOverridden] initWithAnnot:currentAnnotation];
    } else {
        self.annotStyle = nil;
    }
}

- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber
{
    
    self.annotStyle = [[PTAnnotStyle allocOverridden] initWithAnnot:annotation];
    BOOL selected = [super selectAnnotation:annotation onPageNumber:pageNumber];
    if (selected) {
        [self selectCurrentAnnotation];
    }
    
    return selected;
}

-(void)setPolyLineAnnotFromCurrentAnnotation
{
    if( [self.currentAnnotation GetType] == e_ptPolygon || [self.currentAnnotation GetType] == e_ptPolyline )
    {
        self.polyLineAnnot = [[PTPolyLine alloc] initWithAnn:self.currentAnnotation];
    }
    else
    {
        self.polyLineAnnot = [[PTLineAnnot alloc] initWithAnn:self.currentAnnotation];
    }
}


- (void)selectCurrentAnnotation
{
    NSArray<PTPDFPoint *> *vertices = nil;
    PTPDFRect *annotPageRect = nil;
 
    @try {
        [self.pdfViewCtrl DocLockRead];
        
        [self setPolyLineAnnotFromCurrentAnnotation];
        
        // Get polyline rect and vertices.
        annotPageRect = [self.polyLineAnnot GetRect];
        
        vertices = [self extractVerticies];
        
        self.borderEffectIntensity = [self.polyLineAnnot GetBorderEffectIntensity];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    self.vertices = vertices;
    
    
    self.annotRect = [self tightScreenBoundingBoxForAnnot:self.currentAnnotation];
    
    self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:CGRectGetMidX(self.annotRect) y:CGRectGetMidY(self.annotRect)];
    
    self.annotRect = CGRectOffset(self.annotRect, [self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos]);
    
    [self.selectionRectContainerView setFrameFromAnnot:self.annotRect];
    
    self.selectionRectContainerView.hidden = NO;
    self.selectionRectContainerView.borderView.hidden = YES;
    
    [self.selectionRectContainerView hideResizeWidgetViews];
    [self.selectionRectContainerView showSelectionRect];
    
    [self.selectionRectContainerView setAnnot:self.currentAnnotation];
    
    if (self.selectionRectContainerView.superview != self.pdfViewCtrl.toolOverlayView) {
        [self.pdfViewCtrl.toolOverlayView addSubview:self.selectionRectContainerView];
    }
    
    // Cover screen (in canvas space).
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], CGRectGetWidth(self.pdfViewCtrl.bounds), CGRectGetHeight(self.pdfViewCtrl.bounds));
    
    self.annotRect = CGRectOffset(self.annotRect, - [self.pdfViewCtrl GetHScrollPos], - [self.pdfViewCtrl GetVScrollPos]);
    
    [self hideMenu];
    if (!PT_ToolsMacCatalyst) {
        [self showSelectionMenu:self.annotRect];
    }
    
    // Remove existing resize widgets.
    NSArray<PTResizeWidgetView *> *resizeWidgets = [self.selectionRectContainerView.subviews pt_objectsPassingTest:^BOOL(UIView *subview, NSUInteger index, BOOL *stop) {
        return ([subview isKindOfClass:[PTResizeWidgetView class]]);
    }];
    for (PTResizeWidgetView *resizeWidget in resizeWidgets) {
        [resizeWidget removeFromSuperview];
    }
    
    // Check if the annot is resizable.
    if ([self annotIsResizable:self.currentAnnotation]) {
        // Add resize widgets for all vertices.
        [self.vertices enumerateObjectsUsingBlock:^(PTPDFPoint *pagePoint, NSUInteger vertexIndex, BOOL *stop) {
            PTPDFPoint *screenPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:pagePoint page_num:self.annotationPageNumber];
            
            CGPoint widgetCenter = [self.selectionRectContainerView convertPoint:PTPDFPointToCGPoint(screenPoint) fromView:self.pdfViewCtrl];
            
            PTResizeWidgetView *resizeWidget = [[PTResizeWidgetView alloc] initAtPoint:widgetCenter WithLocation:PTResizeHandleLocationTop /* unused */];
            resizeWidget.center = widgetCenter;
            resizeWidget.tag = vertexIndex;
            
            [self.selectionRectContainerView addSubview:resizeWidget];
        }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self layoutResizeWidgets];
}

- (void)layoutResizeWidgets
{
    for (UIView *subview in self.selectionRectContainerView.subviews) {
        if (![subview isKindOfClass:[PTResizeWidgetView class]]) {
            continue;
        }
        PTResizeWidgetView *resizeWidget = (PTResizeWidgetView *)subview;
        
        const NSUInteger vertexIndex = resizeWidget.tag;
        if (vertexIndex >= self.vertices.count) {
            continue;
        }
        
        if (self.selectedVertexIndex != NSNotFound &&
            vertexIndex == self.selectedVertexIndex) {
            continue;
        }
        
        PTPDFPoint *pagePoint = self.vertices[vertexIndex];
        
        PTPDFPoint *screenPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:pagePoint page_num:self.annotationPageNumber];
        
        CGPoint widgetCenter = [self.selectionRectContainerView convertPoint:PTPDFPointToCGPoint(screenPoint) fromView:self.pdfViewCtrl];
        
        resizeWidget.center = widgetCenter;
    }
}

#pragma mark Moving

- (void)setSelectionRectDelta:(CGRect)deltaRect
{
    // Don't move selection rect while moving a vertex.
    if (self.selectedVertexIndex != NSNotFound) {
        return;
    }
    
    [super setSelectionRectDelta:deltaRect];
}

- (void)moveAnnotation:(CGPoint)down
{
    if (![self.currentAnnotation IsValid]) {
        return;
    }
    
    @try {
        [self.pdfViewCtrl DocLock:YES];
        
        PTPDFPoint *touchStartPointPage = [self.pdfViewCtrl ConvScreenPtToPagePt:CGPointToPTPDFPoint(self.touchStartPoint) page_num:self.annotationPageNumber];
        
        PTPDFPoint *touchEndPointPage = [self.pdfViewCtrl ConvScreenPtToPagePt:CGPointToPTPDFPoint(self.touchEndPoint) page_num:self.annotationPageNumber];
        
        // Calculate the proposed annotation displacement.
        CGFloat proposedDiffX = [touchEndPointPage getX] - [touchStartPointPage getX];
        CGFloat proposedDiffY = [touchEndPointPage getY] - [touchStartPointPage getY];
        
        PTPDFRect *oldRect = [self tightPageBoundingBoxFromAnnot:self.polyLineAnnot];
        
        PTPDFRect *proposedRect = [[PTPDFRect alloc] initWithX1:([oldRect GetX1] + proposedDiffX) y1:([oldRect GetY1] + proposedDiffY) x2:([oldRect GetX2] + proposedDiffX) y2:([oldRect GetY2] + proposedDiffY)];
        
        // Bound the proposed annotation rect to the page crop box.
        PTPDFRect *boundedRect = [self boundPageRect:proposedRect toPage:self.annotationPageNumber];
        
        double diffX = [boundedRect GetX1] - [oldRect GetX1];
        double diffY = [boundedRect GetY1] - [oldRect GetY1];
        
        // Get vertices.
        NSArray<PTPDFPoint *> *vertices = self.vertices;
        if (!vertices) {
            vertices = [self extractVerticies];
            self.vertices = vertices;
        }
        
        // Move vertices.
        for (PTPDFPoint *vertex in vertices) {
            [vertex setX:[vertex getX] + diffX];
            [vertex setY:[vertex getY] + diffY];
        }
        
        PTPDFRect *newAnnotRect = [self boundingBoxForPoints:vertices];
        [newAnnotRect Normalize];
        
        [newAnnotRect InflateWithAmount:(PTResizeWidgetView.length / 2)];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        
        
        for (int i = 0; i < vertices.count; i++) {
            [self.polyLineAnnot SetVertex:i pt:vertices[i]];
        }
        
        [self.polyLineAnnot SetRect:newAnnotRect];
        
        if (self.annotType == PTExtendedAnnotTypeRuler || self.annotType == PTExtendedAnnotTypePerimeter || self.annotType == PTExtendedAnnotTypeArea ) {
            [PTMeasurementUtil setContentsForAnnot:self.currentAnnotation];
        }
        
        [self.polyLineAnnot RefreshAppearance];
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        
        [self.pdfViewCtrl Update];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    
    [self selectCurrentAnnotation];
}

#pragma mark - Tool

#pragma mark Touch events

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects.firstObject;
    if (!touch) {
        return NO;
    }
    
    self.touchStartPoint = [touch locationInView:self.pdfViewCtrl];
    
    if ([self snappingEnabled]) {
        PTPDFPoint* snapPoint = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:self.touchStartPoint.x py:self.touchStartPoint.y]];
        self.touchStartPoint = PTCGPointSnapToPoint(self.touchStartPoint, CGPointMake(snapPoint.getX, snapPoint.getY));
    }
    
    self.touchEndPoint = self.touchStartPoint;
    
    if ([touch.view isKindOfClass:[PTResizeWidgetView class]]) {
        PTResizeWidgetView *resizeWidget = (PTResizeWidgetView *)(touch.view);
        
        self.selectedVertexIndex = resizeWidget.tag;
        
        [self.selectionRectContainerView hideSelectionRect];
                
        [self setNeedsDisplay];
    }
    
    return [super pdfViewCtrl:pdfViewCtrl onTouchesBegan:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{

    self.selectionRectContainerView.borderView.hidden = YES;
    
    
    UITouch *touch = touches.allObjects.firstObject;
    if (!touch) {
        return NO;
    }
    
    CGPoint point = [self boundPointToPage:[touch locationInView:self.pdfViewCtrl]];
    
    if ([self snappingEnabled]) {
        PTPDFPoint* snapPoint = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:point.x py:point.y]];
        point = PTCGPointSnapToPoint(point, CGPointMake(snapPoint.getX, snapPoint.getY));
    }
    
    self.touchEndPoint = point;
    
    if ([touch.view isKindOfClass:[PTResizeWidgetView class]]) {
        PTResizeWidgetView *resizeWidget = (PTResizeWidgetView *)(touch.view);
        
        NSAssert(resizeWidget.tag == self.selectedVertexIndex, @"Initially selected vertex does not match moved vertex");
        
        resizeWidget.center = [self.selectionRectContainerView convertPoint:point fromView:self.pdfViewCtrl];
        if ( self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeRuler ||
            self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypePerimeter ||
            self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeArea ){
            [self addLoupeAtMagnifyPoint:point touchPoint:point];
            [resizeWidget setHidden:YES];
        }

        [self setNeedsDisplay];
    }
    
    return [super pdfViewCtrl:pdfViewCtrl onTouchesMoved:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    if( [self.currentAnnotation GetType] != e_ptLine )
//    {
//        self.selectionRectContainerView.borderView.hidden = NO;
//    }
    [loupe removeFromSuperview];
    if (self.selectedVertexIndex != NSNotFound) {
        [self commitAnnotation];

        // Deselect and reselect the current annotation to reset internal state in PTAnnotEditTool.
        PTAnnot *currentAnnot = self.currentAnnotation;
        unsigned int pageNumber = self.annotationPageNumber;
        [self deselectAnnotation];
        [self selectAnnotation:currentAnnot onPageNumber:pageNumber];
        
        // Avoid calling super when vertices have changed and the annotation rect has changed.
        return YES;
    }
    
    return [super pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    if( [self.currentAnnotation GetType] != e_ptLine )
//    {
//        self.selectionRectContainerView.borderView.hidden = NO;
//    }
    [loupe removeFromSuperview];
    return [super pdfViewCtrl:pdfViewCtrl onTouchesCancelled:touches withEvent:event];
}

-(void)addLoupeAtMagnifyPoint:(CGPoint)magnifyPoint touchPoint:(CGPoint)touchPoint
{
    if(loupe == nil){
        loupe = [[PTMagnifierView alloc] initWithViewToMagnify:self.pdfViewCtrl];
    }

    [self.pdfViewCtrl.superview addSubview:loupe];

    [loupe setMagnifyPoint:magnifyPoint TouchPoint:touchPoint];
    [loupe setNeedsDisplay];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if( gestureRecognizer.state == UIGestureRecognizerStateBegan )
    {
        self.touchStartPoint = [gestureRecognizer locationInView:self.pdfViewCtrl];
    }
    else if( gestureRecognizer.state == UIGestureRecognizerStateEnded )
    {
        self.touchEndPoint = [gestureRecognizer locationInView:self.pdfViewCtrl];
    }
    
    return [super pdfViewCtrl:pdfViewCtrl handleLongPress:gestureRecognizer];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    return YES;
}

#pragma mark - Convenience

- (BOOL)snappingEnabled
{
    return ( self.toolManager.snapToDocumentGeometry &&
            ( self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeRuler ||
             self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypePerimeter ||
             self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeArea ) );
}

- (NSArray<PTPDFPoint *> *)extractVerticies {
    
    NSMutableArray<PTPDFPoint *> *mutableVertices = [NSMutableArray array];
    
    const int vertexCount = [self.polyLineAnnot GetVertexCount];
    
    for (int i = 0; i < vertexCount; i++) {
        [mutableVertices addObject:[self.polyLineAnnot GetVertex:i]];
    }
    

    return [mutableVertices copy];
}

#pragma mark - Annotation saving

- (void)commitAnnotation
{
    if (self.selectedVertexIndex == NSNotFound) {
        return;
    }
    
    NSAssert(self.selectedVertexIndex < self.vertices.count, @"Selected vertex index is out of bounds");
        
    PTPDFPoint *screenPoint = CGPointToPTPDFPoint(self.touchEndPoint);
    PTPDFPoint *pagePoint = [self.pdfViewCtrl ConvScreenPtToPagePt:screenPoint page_num:self.annotationPageNumber];
    
    NSMutableArray<PTPDFPoint *> *mutableVertices = [self.vertices mutableCopy];
    mutableVertices[self.selectedVertexIndex] = pagePoint;
    self.vertices = [mutableVertices copy];
    
    PTPDFRect *annotRect = [self boundingBoxForPoints:self.vertices];
    [annotRect Normalize];
    
    [annotRect InflateWithAmount:(PTResizeWidgetView.length / 2)];
    
    PTPDFRect *oldRect = nil;
    // Update selected vertex and commit annotation.
    @try {
        [self.pdfViewCtrl DocLock:YES];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        oldRect = [self.polyLineAnnot GetRect];
        
        const int vertexCount = [self.polyLineAnnot GetVertexCount];
        for (int i = 0; i < vertexCount; i++) {
            PTPDFPoint *vertexPoint = self.vertices[i];
            [self.polyLineAnnot SetVertex:i pt:vertexPoint];
        }
        
        [self.polyLineAnnot SetRect:annotRect];
        
        PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];
        
        if (annotType == PTExtendedAnnotTypeRuler || annotType == PTExtendedAnnotTypePerimeter || annotType == PTExtendedAnnotTypeArea ) {
            [PTMeasurementUtil setContentsForAnnot:self.currentAnnotation];
        }
        
        [self.polyLineAnnot RefreshAppearance];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    } @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    if (oldRect) {
        // Update old annotation rect.
        PTPDFRect *screenRect = CGRectToPTPDFRect([self.pdfViewCtrl PDFRectPage2CGRectScreen:oldRect PageNumber:self.annotationPageNumber]);
        [self.pdfViewCtrl UpdateWithRect:screenRect];
    }
    
    [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
    
    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    
    self.currentAnnotation = self.polyLineAnnot;
    
    [self deselectVertex];
}

- (void)deselectVertex
{
    // Reset selected vertex index.
    self.selectedVertexIndex = NSNotFound;
    [self setNeedsDisplay];
}

-(PTPDFRect*)tightPageBoundingBoxFromAnnot:(PTLineAnnot*)annot
{
    NSAssert(annot == self.polyLineAnnot, @"expected passed annot to be the poly annot");
    NSArray<PTPDFPoint *> *pageVertices = self.vertices;
    if (!pageVertices) {
        pageVertices = [self extractVerticies];
        self.vertices = pageVertices;
    }
    
    return [self boundingBoxForPoints:pageVertices];
}

-(CGRect)tightScreenBoundingBoxForAnnot:(PTAnnot*)annot
{
    
    if( self.polyLineAnnot == Nil )
    {
        [self setPolyLineAnnotFromCurrentAnnotation];
    }
    
    NSArray<PTPDFPoint *> *pageVertices = self.vertices;
    if (!pageVertices) {
        pageVertices = [self extractVerticies];
        self.vertices = pageVertices;
    }
    
    PTPDFRect *newAnnotRect = [self boundingBoxForPoints:pageVertices];
    
    return [self PDFRectPage2CGRectScreen:newAnnotRect PageNumber:self.annotationPageNumber];
}

// Calculate bounding box for the specified points.
- (nullable PTPDFRect *)boundingBoxForPoints:(NSArray<PTPDFPoint *> *)points
{
    double minX = DBL_MAX;
    double minY = DBL_MAX;
    
    double maxX = DBL_MIN;
    double maxY = DBL_MIN;
    
    for (PTPDFPoint *point in points) {
        double x = [point getX];
        double y = [point getY];
        
        minX = fmin(minX, x);
        minY = fmin(minY, y);
        
        maxX = fmax(maxX, x);
        maxY = fmax(maxY, y);
    }
    
    if (minX == DBL_MAX || minY == DBL_MAX
        || maxX == DBL_MIN || maxY == DBL_MIN) {
        return nil;
    }
    
    // Create and normalize bounding box rect.
    PTPDFRect *rect = nil;
    @try {
        rect = [[PTPDFRect alloc] initWithX1:minX y1:minY x2:maxX y2:maxY];
        [rect Normalize];
    } @catch (NSException *exception) {
        return nil;
    }
    
    return rect;
}

- (NSArray<NSValue *> *)screenPointsFromPagePoints:(NSArray<PTPDFPoint *> *)pagePoints pageNumber:(int)pageNumber
{
    NSMutableArray<NSValue *> *screenPoints = [NSMutableArray array];
    
    for (PTPDFPoint *pagePoint in pagePoints) {
        PTPDFPoint *screenPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:pagePoint
                                                                page_num:pageNumber];
        [screenPoints addObject:@(CGPointMake([screenPoint getX],
                                              [screenPoint getY]))];
    }
    
    return [screenPoints copy];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    if (self.selectedVertexIndex == NSNotFound || CGPointEqualToPoint(self.touchEndPoint, PTCGPointInvalid)) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.4 green:0.4 blue:1.0 alpha:1.0].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    UIGraphicsPushContext(context);
    
    CGContextBeginPath(context);
    
    [self drawEditGuidesWithRect:rect];
    
    CGContextStrokePath(context);
    
    UIGraphicsPopContext();
}

#pragma mark Edit guides

- (void)drawEditGuidesWithRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSUInteger selectedVertexIndex = self.selectedVertexIndex;
    NSUInteger vertexCount = self.vertices.count;
    
    CGPoint touchedPoint = self.touchEndPoint;
    touchedPoint = [self convertPoint:touchedPoint fromView:self.pdfViewCtrl];
    
    UIColor* strokeColor = self.annotStyle.strokeColor;
    
    if( strokeColor == Nil )
    {
        strokeColor = UIColor.clearColor;
    }
    
    UIColor* fillColor = self.annotStyle.fillColor;
    
    if( fillColor == Nil )
    {
        fillColor = UIColor.clearColor;
    }
    
    double opacity = self.annotStyle.opacity;
    
    double thickness = self.annotStyle.thickness;
    
    thickness *= [self.pdfViewCtrl GetZoom];
    
    CGContextSetLineWidth(context, thickness);
    CGContextSetLineCap(context, kCGLineCapButt);
    
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextSetAlpha(context, opacity);
    
    const PTExtendedAnnotType annotationType = self.polyLineAnnot.extendedAnnotType;
    
    if (annotationType == PTExtendedAnnotTypeArrow) {
    
        CGPoint startPoint = PTPDFPointToCGPoint([self.pdfViewCtrl ConvPagePtToScreenPt:self.vertices[0] page_num:self.annotationPageNumber]);
        startPoint = [self convertPoint:startPoint fromView:self.pdfViewCtrl];
        
        if( selectedVertexIndex == 0 )
        {
            startPoint = touchedPoint;
        }

        
        CGPoint endPoint = PTPDFPointToCGPoint([self.pdfViewCtrl ConvPagePtToScreenPt:self.vertices[1] page_num:self.annotationPageNumber]);
        endPoint = [self convertPoint:endPoint fromView:self.pdfViewCtrl];
        
        if( selectedVertexIndex == 1 )
        {
            endPoint = touchedPoint;
        }

        
        if( [self.polyLineAnnot GetEndStyle] == e_ptOpenArrow )
        {
            CGPoint temp;
            temp = startPoint;
            startPoint = endPoint;
            endPoint = temp;
        }
        
        const double cosAngle = cos(3.1415926/6);
        const double sinAngle = sin(3.1415926/6);
        const double  arrowLength = 10*thickness/2;
        
        double dx = startPoint.x - endPoint.x;
        double dy = startPoint.y - endPoint.y;
        double len = dx*dx+dy*dy;
        
        CGPoint firstSmall, secondSmall;
        
        if( len > 0 )
        {
            len = sqrt(len);
            dx /= len;
            dy /= len;
            
            double dx1 = dx * cosAngle - dy * sinAngle;
            double dy1 = dy * cosAngle + dx * sinAngle;
            
            firstSmall = CGPointMake(startPoint.x - arrowLength*dx1, startPoint.y - arrowLength*dy1);
            
            double dx2 = dx * cosAngle + dy * sinAngle;
            double dy2 = dy * cosAngle - dx * sinAngle;
            
            secondSmall = CGPointMake(startPoint.x - arrowLength*dx2, startPoint.y - arrowLength*dy2);
            
            // end of small line
            CGContextMoveToPoint(context, firstSmall.x, firstSmall.y);
            
            // tip of arrow
            CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
            
            // end of second small line
            CGContextAddLineToPoint(context, secondSmall.x, secondSmall.y);
            
            // tip of arrow
            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            
            // base of long arrow line
            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            
           
        }
        
         return;
    }
    
    if (annotationType == PTExtendedAnnotTypeCloudy) {
        
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        
        NSArray<PTPDFPoint *> *currentVertices = self.vertices;
        if (self.selectedVertexIndex != NSNotFound) {
            CGPoint touchEndPagePoint = [self convertScreenPtToPagePt:self.touchEndPoint onPageNumber:self.annotationPageNumber];
            PTPDFPoint *editedVertex = [[PTPDFPoint alloc] initWithPx:touchEndPagePoint.x py:touchEndPagePoint.y];

            NSMutableArray<PTPDFPoint *> *editingVertices = [currentVertices mutableCopy];
            editingVertices[self.selectedVertexIndex] = editedVertex;
            currentVertices = [editingVertices copy];
        }
        
        NSArray<NSValue *> *screenPoints = [self screenPointsFromPagePoints:currentVertices pageNumber:self.annotationPageNumber];
        
        screenPoints = [screenPoints arrayByAddingObject:[screenPoints.firstObject copy]];
        
        CGContextBeginPath(context);
        
        CGPoint firstVertex = screenPoints.firstObject.CGPointValue;
        CGContextMoveToPoint(context, firstVertex.x, firstVertex.y);
                
        [PTAnnotStyleDraw drawCloudWithRect:rect points:screenPoints
                            borderIntensity:self.borderEffectIntensity
                                       zoom:self.pdfViewCtrl.zoom];
        
        CGContextClosePath(context);
                
        return;
    }
    
    NSUInteger initialVertexIndex = 0;
    NSUInteger previousVertexIndex = vertexCount - 1;
    
    if (annotationType == e_ptPolyline) {
        initialVertexIndex = 1;
        previousVertexIndex = 0;
    }
    
    for (NSUInteger vertexIndex = initialVertexIndex; vertexIndex < vertexCount; vertexIndex++) {
        if ([self shouldDrawEditGuideFromVertexIndex:previousVertexIndex toVertexIndex:vertexIndex]) {
            PTPDFPoint *previousVertex = self.vertices[previousVertexIndex];
            
            CGPoint previousPoint;
            
            if( previousVertexIndex != selectedVertexIndex )
            {
                previousPoint = PTPDFPointToCGPoint([self.pdfViewCtrl ConvPagePtToScreenPt:previousVertex page_num:self.annotationPageNumber]);
                previousPoint = [self convertPoint:previousPoint fromView:self.pdfViewCtrl];
            }
            else
            {
                previousPoint = touchedPoint;
            }
            
            CGPoint selectedPoint;
            
            if( vertexIndex != selectedVertexIndex )
            {
                selectedPoint = PTPDFPointToCGPoint([self.pdfViewCtrl ConvPagePtToScreenPt:self.vertices[vertexIndex] page_num:self.annotationPageNumber]);
                selectedPoint = [self convertPoint:selectedPoint fromView:self.pdfViewCtrl];
            }
            else
            {
                selectedPoint = touchedPoint;
            }
            
            if( vertexIndex == initialVertexIndex )
            {
                CGContextMoveToPoint(context, previousPoint.x, previousPoint.y);
            }
            
            CGContextAddLineToPoint(context, selectedPoint.x, selectedPoint.y);
        }

        previousVertexIndex = vertexIndex;
    }

    CGContextDrawPath(context, kCGPathFillStroke);
}

- (BOOL)shouldDrawEditGuideFromVertexIndex:(NSUInteger)fromVertexIndex toVertexIndex:(NSUInteger)toVertexIndex
{
    // Don't draw for zero length lines.
    if (fromVertexIndex == toVertexIndex) {
        return NO;
    }
    
    const PTExtendedAnnotType annotationType = self.polyLineAnnot.extendedAnnotType;
    
    // Always draw edit guides for polygon annotations.
    if (annotationType == PTExtendedAnnotTypePolygon ||
        annotationType == PTExtendedAnnotTypeCloudy ||
        annotationType == PTExtendedAnnotTypeArea) {
        return YES;
    }
    
    const NSUInteger vertexCount = self.vertices.count;
    
    // Draw edit guide for straight line.
    if (vertexCount < 3) {
        return YES;
    }
    
    // Don't draw edit guide between end points.
    if ((fromVertexIndex == 0 || fromVertexIndex == vertexCount - 1)
        && (toVertexIndex == 0 || toVertexIndex == vertexCount - 1)) {
        return NO;
    }
    
    return YES;
}

@end
