//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPolylineCreate.h"

#import "PTPolylineCreateSubclass.h"

#import "PTToolsUtil.h"
#import "PTColorDefaults.h"

#import "PTPerimeterCreate.h"
#import "PTAreaCreate.h"
#import "PTMeasurementUtil.h"
#import "PTMagnifierView.h"

#import "PTKeyValueObserving.h"
#import "CGGeometry+PTAdditions.h"

@interface PTPolylineCreate ()

@property (nonatomic, assign) int touchPageNumber;

@property (nonatomic, copy) NSArray<NSValue *> *touchPoints;

@property (nonatomic, copy) NSArray<NSValue *> *pageTouchPoints;

@property (nonatomic, assign) BOOL isPencilTouch;

@property (nonatomic, assign) BOOL commitAnnotationOnToolChange;

@end

@interface PTPolylineCreate ()
{
    PTMagnifierView* loupe;
}
@end

@implementation PTPolylineCreate

@dynamic isPencilTouch;

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        _touchPoints = [NSMutableArray array];
        _pageTouchPoints = [NSArray array];
        _commitAnnotationOnToolChange = YES;
        self.backgroundColor = UIColor.clearColor;
        // Add pinch gesture recognizer to block pinch-zoom.
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(ignorePinch:)];
        [self addGestureRecognizer:pinchRecognizer];
        
        self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos],
                                self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);
    }
    return self;
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview == nil && self.commitAnnotationOnToolChange) {
        [self commitAnnotation];
    }
    [super willMoveToSuperview:newSuperview];
}

#pragma mark - CreateToolBase

- (Class)annotClass
{
    return [PTPolyLine class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypePolyline;
}

+ (BOOL)canEditStyle
{
    return YES;
}

- (BOOL)requiresEditSupport
{
    return YES;
}

- (BOOL)isUndoManagerEnabled
{
    return YES;
}

#pragma mark - View

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        PTExtendedAnnotName annotName = PTExtendedAnnotNameFromType(self.annotType);
        
        // Observe changes to the stroke color, thickness, and opacity attributes.
        NSArray<NSString *> *attributes = @[
            ATTRIBUTE_STROKE_COLOR,
            ATTRIBUTE_FILL_COLOR,
            ATTRIBUTE_BORDER_THICKNESS,
            ATTRIBUTE_OPACITY,
        ];
        
        for (NSString *attribute in attributes) {
            // User defaults keys are of the form "<annot-name><attribute>".
            NSString *key = [annotName stringByAppendingString:attribute];
            
            // Observe changes to the specified user defaults key.
            [self pt_observeObject:NSUserDefaults.standardUserDefaults
                        forKeyPath:key
                          selector:@selector(userDefaultsChanged)];
        }
    } else {
        // Remove all user defaults observers.
        for (PTKeyValueObservation *observation in self.pt_observations) {
            [observation invalidate];
        }
    }
}

- (void)userDefaultsChanged
{
    [self setNeedsDisplay];
}

#pragma mark - Tool

#pragma mark Touch events

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    
    if( self.toolManager.annotationsCreatedWithPencilOnly && self.isPencilTouch == NO )
    {
        return YES;
    }
    
    UITouch *touch = touches.allObjects.firstObject;
    if (!touch) {
        return YES;
    }
    CGPoint point = [touch locationInView:self.pdfViewCtrl];
    
    int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:point.x y:point.y];
    if (pageNumber < 1) {
        return YES;
    }
    
    self.touchPageNumber = pageNumber;
    
    if (self.pageNumber < 1) {
        // Record the starting page for touches. All subsequent touches must occur on this page.
        _pageNumber = pageNumber;
    }
    else if (pageNumber != self.pageNumber) {
        // Touch occurred on a page other than the starting page.
        return YES;
    }
    
    if ([self snappingEnabled]) {
        PTPDFPoint* snapPoint = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:point.x py:point.y]];
        point = PTCGPointSnapToPoint(point, CGPointMake(snapPoint.getX, snapPoint.getY));
    }
    
    self.startPoint = point;
    
    [self addTouchPoint:point];
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.bounds.size.width, self.pdfViewCtrl.bounds.size.height);

    [self setNeedsDisplay];
    
    // Handled event.
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.pageNumber < 1 || self.pageNumber != self.touchPageNumber || self.touchPoints.count < 1) {
        return YES;
    }
    
    UITouch *touch = touches.allObjects.firstObject;
    if (!touch) {
        return YES;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly && self.isPencilTouch == NO )
    {
        return YES;
    }
    
    CGPoint point = [self boundToPageScreenPoint:[touch locationInView:self.pdfViewCtrl] withThicknessCorrection:0];

    if ([self snappingEnabled]) {
        PTPDFPoint* snapPoint = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:point.x py:point.y]];
        point = PTCGPointSnapToPoint(point, CGPointMake(snapPoint.getX, snapPoint.getY));
    }
    
    if ([self isKindOfClass:[PTPerimeterCreate class]] ||
        [self isKindOfClass:[PTAreaCreate class]]) {
        [self addLoupeAtMagnifyPoint:point touchPoint:point];
    }

    if (self.touchPoints.count == 1) {
        // Add a second point to create the first segment.
        [self addTouchPoint:point];
    } else {
        // Update the last point.
        [self updateLastTouchPoint:point];
    }
    
    self.endPoint = point;
    
    [self setNeedsDisplay];
    
    // Handled event.
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [loupe removeFromSuperview];
    if (self.pageNumber < 1 || self.pageNumber != self.touchPageNumber || self.touchPoints.count < 1) {
        return YES;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly && self.isPencilTouch == NO )
    {
        return YES;
    }
    
    [self saveTouchPointsInPageSpace];
    
    // Handled event.
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
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

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // Ignore: handled by touchesEnded.
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // Ignore: zooming is disabled.
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    
    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;

    return YES;

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    // Necessary to disable pinch-zooming.
    return NO;
}

- (void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl *)pdfViewCtrl
{
    [super pdfViewCtrlOnLayoutChanged:pdfViewCtrl];
    
    [self restoreTouchPointsFromPageSpace];
    [self setNeedsDisplay];
}

#pragma mark - Pinch

- (void)ignorePinch:(UIPinchGestureRecognizer *)pinchRecognizer
{
    // Ignore: pinch-zoom is disabled.
    return;
}

#pragma mark - Screen/Page space points

- (NSArray<NSValue *> *)pagePointsForScreenPoints:(NSArray<NSValue *> *)screenPoints
{
    if (!screenPoints) {
        return nil;
    }
    
    NSMutableArray<NSValue *> *pagePoints = [NSMutableArray arrayWithCapacity:screenPoints.count];
    
    for (NSValue *value in screenPoints) {
        CGPoint screenPoint = value.CGPointValue;
        CGPoint pagePoint = [self convertScreenPtToPagePt:screenPoint onPageNumber:self.pageNumber];
        [pagePoints addObject:@(pagePoint)];
    }
    
    return [pagePoints copy];
}

- (NSArray<NSValue *> *)screenPointsForPagePoints:(NSArray<NSValue *> *)pagePoints
{
    if (!pagePoints) {
        return nil;
    }
    
    NSMutableArray<NSValue *> *screenPoints = [NSMutableArray arrayWithCapacity:pagePoints.count];
    
    for (NSValue *value in pagePoints) {
        CGPoint pagePoint = value.CGPointValue;
        CGPoint screenPoint = [self convertPagePtToScreenPt:pagePoint onPageNumber:self.pageNumber];
        [screenPoints addObject:@(screenPoint)];
    }
    
    return [screenPoints copy];
}

- (void)saveTouchPointsInPageSpace
{
    self.pageTouchPoints = [[self pagePointsForScreenPoints:self.touchPoints] mutableCopy];
}

- (void)restoreTouchPointsFromPageSpace
{
    self.touchPoints = [[self screenPointsForPagePoints:self.pageTouchPoints] mutableCopy];
}

#pragma mark - Annotation saving

// Calculate bounding box for the specified points.
- (nullable PTPDFRect *)getBoundingBoxForPoints:(NSArray<PTPDFPoint *> *)points
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

- (PTPolyLine *)createPolylineWithDoc:(PTPDFDoc *)doc pagePoints:(NSArray<PTPDFPoint *> *)pagePoints
{
    PTPDFRect *annotRect = [self getBoundingBoxForPoints:pagePoints];
    if (!annotRect) {
        return nil;
    }
    [annotRect InflateWithAmount:self.thickness];

    
    PTAnnotType polyType = e_ptPolygon;
    if(self.annotType == PTExtendedAnnotTypePolyline || self.annotType == PTExtendedAnnotTypePerimeter){
        polyType = e_ptPolyline;
    }
    
    PTAnnot *annot = [PTAnnot Create:[doc GetSDFDoc] type:polyType pos:annotRect];
    PTPolyLine *poly = [[PTPolyLine alloc] initWithAnn:annot];
    
    int pointIndex = 0;
    for (PTPDFPoint *point in pagePoints) {
        [poly SetVertex:pointIndex pt:point];
        pointIndex++;
    }
    [poly SetRect:annotRect];

    return poly;
}

- (void)cancelEditingAnnotation
{
    self.commitAnnotationOnToolChange = NO;
}

- (void)commitAnnotation
{
    self.commitAnnotationOnToolChange = NO;
    if (self.pageNumber < 1) {
        return;
    }
    
    NSArray<NSValue *> *pageTouchPoints = self.pageTouchPoints;
    if (pageTouchPoints.count < 1) {
        return;
    }
    
    NSMutableArray<PTPDFPoint *> *mutablePagePoints = [NSMutableArray arrayWithCapacity:pageTouchPoints.count];
    
    for (NSValue *value in pageTouchPoints) {
        CGPoint pageTouchPoint = value.CGPointValue;
        [mutablePagePoints addObject:[[PTPDFPoint alloc] initWithPx:pageTouchPoint.x py:pageTouchPoint.y]];
    }
    
    NSArray<PTPDFPoint *> *pagePoints = [mutablePagePoints copy];
    
    PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
    
    PTAnnot *annot = nil;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        
        PTPage *page = [doc GetPage:self.pageNumber];
        if (![page IsValid]) {
            return;
        }
        
        annot = [self createPolylineWithDoc:doc pagePoints:pagePoints];
        if (!annot) {
            return;
        }
        
        if ([self isKindOfClass:[PTPerimeterCreate class]] || [self isKindOfClass:[PTAreaCreate class]])
        {
            PTObj *obj = [annot GetSDFObj];
            // This is needed so that PTExtendedAnnotType can be correctly inferred from here on out
            [obj PutDict:@"Measure"];
        }

        [self setPropertiesFromAnnotation:annot];
        
        [annot RefreshAppearance];
        
        [page AnnotPushBack:annot];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
        annot = nil;
    } @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    if (annot) {
        self.currentAnnotation = annot;
        self.annotationPageNumber = self.pageNumber;
        
        [self keepToolAppearanceOnScreen];
        
        [self.pdfViewCtrl UpdateWithAnnot:annot page_num:self.pageNumber];
        [self.pdfViewCtrl RequestRendering];
        
        [self annotationAdded:annot onPageNumber:self.pageNumber];
    }

    NSMutableArray<NSValue *> *touchPoints = [self mutableArrayValueForTouchPoints];
    [touchPoints removeAllObjects];
    
    self.pageTouchPoints = nil;
}

#pragma mark - Drawing

- (void)beginDrawPolylineWithRect:(CGRect)rect atPoint:(CGPoint)point withPoints:(NSArray<NSValue *> *)points
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextMoveToPoint(context, point.x, point.y);
}

- (void)drawPolylineWithRect:(CGRect)rect points:(NSArray<NSValue *> *)points
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (NSValue *value in points) {
        CGPoint point = value.CGPointValue;
        
        CGContextAddLineToPoint(context, point.x, point.y);
    }
}

- (void)endDrawPolylineWithRect:(CGRect)rect atPoint:(CGPoint)point withPoints:(NSArray<NSValue *> *)points
{
    // Do nothing.
}

#pragma mark CreateToolBase

- (double)setupContext:(CGContextRef)currentContext
{
    
    double thickness = [super setupContext:currentContext];
    
    if (!currentContext) {
        return thickness;
    }
    
    CGContextSetLineCap(currentContext, kCGLineCapButt);
    CGContextSetLineJoin(currentContext, kCGLineJoinMiter);
    
    return thickness;
}

#pragma mark UIView

- (void)drawRect:(CGRect)rect
{
    NSArray<NSValue *> *points = self.vertices;
    if (points.count < 1) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }
    
    [self setupContext:context];
    
    UIGraphicsPushContext(context);
    
    CGContextBeginPath(context);
    
    [self beginDrawPolylineWithRect:rect atPoint:points.firstObject.CGPointValue withPoints:points];
    
    [self drawPolylineWithRect:rect points:points];
    
    [self endDrawPolylineWithRect:rect atPoint:points.lastObject.CGPointValue withPoints:points];
    
    CGContextDrawPath(context, kCGPathFillStroke);
    
    
    UIGraphicsPopContext();
}

#pragma mark - Property accessors

- (NSArray<NSValue *> *)vertices
{
    return self.touchPoints;
}

- (void)setVertices:(NSArray<NSValue *> *)vertices
{
    self.touchPoints = vertices;
    [self saveTouchPointsInPageSpace];
    
    // Clear undo/redo stack.
    [self.undoManager removeAllActions];
    
    [self setNeedsDisplay];
}

- (BOOL)snappingEnabled
{
    return ( self.toolManager.snapToDocumentGeometry &&
            ( [self isKindOfClass:[PTPerimeterCreate class]] ||
             [self isKindOfClass:[PTAreaCreate class]] ) );
}

#pragma mark - Touch points

- (NSMutableArray<NSValue *> *)mutableArrayValueForTouchPoints
{
    return [self mutableArrayValueForKey:PT_KEY(self, touchPoints)];
}

- (void)addTouchPoint:(CGPoint)point
{
    NSMutableArray<NSValue *> *touchPoints = [self mutableArrayValueForTouchPoints];
    [touchPoints addObject:@(point)];
    
    // Undo support.
    [self.undoManager registerUndoWithTarget:self handler:^(PTPolylineCreate *target) {
        [target removeLastTouchPoint];
        
        // Update page points and redraw.
        [target saveTouchPointsInPageSpace];
        [target setNeedsDisplay];
    }];
    if (![self.undoManager isUndoing]) {
        [self.undoManager setActionName:PTLocalizedString(@"Add vertex", @"Undo/redo action for multi-point annotations")];
    }
}

- (void)removeLastTouchPoint
{
    CGPoint lastTouchPoint = self.touchPoints.lastObject.CGPointValue;
    
    NSMutableArray<NSValue *> *touchPoints = [self mutableArrayValueForTouchPoints];
    [touchPoints removeLastObject];
    
    // Undo suport.
    [self.undoManager registerUndoWithTarget:self handler:^(PTPolylineCreate *target) {
        [target addTouchPoint:lastTouchPoint];
        
        // Update page points and redraw.
        [target saveTouchPointsInPageSpace];
        [target setNeedsDisplay];
    }];
    if (![self.undoManager isUndoing]) {
        [self.undoManager setActionName:PTLocalizedString(@"Remove vertex", @"Undo/redo action for multi-point annotations")];
    }
}

- (void)updateLastTouchPoint:(CGPoint)point
{
    NSMutableArray<NSValue *> *touchPoints = [self mutableArrayValueForTouchPoints];

    [touchPoints removeLastObject];
    [touchPoints addObject:@(point)];
}

@end
