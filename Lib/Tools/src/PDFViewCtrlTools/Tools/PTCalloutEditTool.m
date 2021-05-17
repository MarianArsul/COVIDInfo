//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCalloutEditTool.h"

#import "PTAnnotEditToolSubclass.h"

#import "PTAnnotStyle.h"
#import "PTSelectionView.h"

#import "CGGeometry+PTAdditions.h"

#import "PTPDFPoint+PTAdditions.h"
#import "PTPDFRect+PTAdditions.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTCalloutEditTool ()

@property (nonatomic, assign) CGPoint touchStartLocation;

@property (nonatomic, strong) PTSelectionView *contentSelectionView;

@property (nonatomic, assign) UIEdgeInsets contentResizingInsets;

@property (nonatomic, strong, nullable) PTAnnotStyle *annotStyle;

@end

NS_ASSUME_NONNULL_END

@implementation PTCalloutEditTool

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        self.opaque = NO;
        
        _calloutStartResizeWidget = [[PTResizeWidgetView alloc] initAtPoint:CGPointZero WithLocation:PTResizeHandleLocationNone];
        _calloutKneeResizeWidget = [[PTResizeWidgetView alloc] initAtPoint:CGPointZero WithLocation:PTResizeHandleLocationNone];
        
        _touchStartLocation = PTCGPointNull;
        
        _contentSelectionView = [[PTSelectionView alloc] init];
        
        _contentResizingInsets = UIEdgeInsetsZero;
        
        self.aspectRatioGuideEnabled = NO;
    }
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        self.frame = self.superview.bounds;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

#pragma mark - Annotation selection

- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber
{
    BOOL selected = [super selectAnnotation:annotation onPageNumber:pageNumber];
    if (selected) {
        [self setSelectedAnnotation:annotation onPageNumber:pageNumber];
    }
    return selected;
}

- (void)setSelectedAnnotation:(PTAnnot *)annot onPageNumber:(unsigned int)pageNumber
{
    if (![annot IsValid]) {
        return;
    }
    
    PTFreeText *freetext = nil;
    if ([annot isKindOfClass:[PTFreeText class]]) {
        freetext = (PTFreeText *)annot;
    } else {
        freetext = [[PTFreeText alloc] initWithAnn:annot];
    }
    
    // Extract callout points.
    const CGPoint calloutStartPagePoint = [freetext GetCalloutLinePoint1].CGPointValue;
    const CGPoint calloutKneePagePoint = [freetext GetCalloutLinePoint2].CGPointValue;
    const CGPoint calloutEndPagePoint = [freetext GetCalloutLinePoint3].CGPointValue;
    
    self.calloutStartPoint = [self convertPagePtToScreenPt:calloutStartPagePoint
                                              onPageNumber:pageNumber];
    self.calloutKneePoint = [self convertPagePtToScreenPt:calloutKneePagePoint
                                             onPageNumber:pageNumber];
    self.calloutEndPoint = [self convertPagePtToScreenPt:calloutEndPagePoint
                                            onPageNumber:pageNumber];
    
    // Extract content rect.
    PTPDFRect *contentRect = [freetext GetContentRect];
    [contentRect Normalize];
    
    self.contentRect = [self PDFRectPage2CGRectScreen:contentRect
                                           PageNumber:self.annotationPageNumber];
    
    // Add callout point resize widgets.
    [self.selectionRectContainerView addSubview:self.calloutStartResizeWidget];
    [self.selectionRectContainerView addSubview:self.calloutKneeResizeWidget];
    
    // Hide the builtin resize widgets.
    [self.selectionRectContainerView hideResizeWidgetViews];
    // Hide border around selected annotation.
    self.selectionRectContainerView.borderView.hidden = YES;
    
    [self.selectionRectContainerView addSubview:self.contentSelectionView];
    
    self.annotStyle = [[PTAnnotStyle allocOverridden] initWithAnnot:freetext];
}

- (void)deselectAnnotation
{
    [super deselectAnnotation];
    
    self.calloutStartPoint = PTCGPointNull;
    self.calloutKneePoint = PTCGPointNull;
    self.calloutEndPoint = PTCGPointNull;
    
    self.contentRect = CGRectNull;
    
    [self.calloutStartResizeWidget removeFromSuperview];
    [self.calloutKneeResizeWidget removeFromSuperview];
    
    [self.contentSelectionView removeFromSuperview];
    
    self.annotStyle = nil;
}

#pragma mark - PDFViewCtrl touch events

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    if (!touch) {
        return NO;
    }
    
    // Record the touch's starting location.
    self.touchStartLocation = [touch locationInView:self.pdfViewCtrl];
    
    if ([touch.view isKindOfClass:[PTResizeWidgetView class]]) {
        PTResizeWidgetView *touchedResizeWidget = (PTResizeWidgetView *)touch.view;
        
        PTResizeWidgetView *selectedResizeWidget = nil;
        
        if ([touchedResizeWidget isDescendantOfView:self.contentSelectionView]) {
            selectedResizeWidget = touchedResizeWidget;
        }
        else {
            NSArray<PTResizeWidgetView *> *resizeWidgets = @[
                self.calloutStartResizeWidget,
                self.calloutKneeResizeWidget,
            ];
            for (PTResizeWidgetView *resizeWidget in resizeWidgets) {
                if (touchedResizeWidget == resizeWidget) {
                    selectedResizeWidget = resizeWidget;
                    break;
                }
            }
        }
        
        self.selectedResizeWidget = selectedResizeWidget;
    }
    
    return [super pdfViewCtrl:pdfViewCtrl onTouchesBegan:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // Move the selected resize widget.
    if (self.selectedResizeWidget) {
        UITouch *touch = touches.anyObject;
        const CGPoint touchLocation = [touch locationInView:self.pdfViewCtrl];
        
        const CGPoint boundedTouchLocation = [self boundPointToPage:touchLocation];
        
        if (self.selectedResizeWidget == self.calloutStartResizeWidget) {
            self.calloutStartPoint = boundedTouchLocation;
        }
        else if (self.selectedResizeWidget == self.calloutKneeResizeWidget) {
            self.calloutKneePoint = boundedTouchLocation;
            
            [self snapCalloutEndPoint];
        }
        else {
            [self resizeContentForTouchLocation:boundedTouchLocation];
            
            [self snapCalloutEndPoint];
        }
    }
    
    return [super pdfViewCtrl:pdfViewCtrl onTouchesMoved:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.selectedResizeWidget) {
        UITouch *touch = touches.anyObject;
        const CGPoint touchLocation = [touch locationInView:self.pdfViewCtrl];
        const CGPoint boundedTouchLocation = [self boundPointToPage:touchLocation];
        
        if (self.selectedResizeWidget == self.calloutStartResizeWidget) {
            self.calloutStartPoint = boundedTouchLocation;
        }
        else if (self.selectedResizeWidget == self.calloutKneeResizeWidget) {
            self.calloutKneePoint = boundedTouchLocation;
            
            [self snapCalloutEndPoint];
        }
        else {
            [self resizeContentForTouchLocation:boundedTouchLocation];
            
            [self snapCalloutEndPoint];
            
            self.contentRect = UIEdgeInsetsInsetRect(self.contentRect,
                                                     self.contentResizingInsets);
        }
        
        [self commitAnnotation];
        
        [self resetHandleTransformsWithFeedback:YES];
        
        // Deselect and reselect the current annotation to reset internal state in PTAnnotEditTool.
        PTAnnot *currentAnnot = self.currentAnnotation;
        unsigned int pageNumber = self.annotationPageNumber;
        [self deselectAnnotation];
        [self selectAnnotation:currentAnnot onPageNumber:pageNumber];

        [self reset];
        
        return YES;
    }
    
    [self reset];
        
    return [super pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    return [super pdfViewCtrl:pdfViewCtrl onTouchesCancelled:touches withEvent:event];
}

- (void)resizeContentForTouchLocation:(CGPoint)touchLocation
{
    const CGVector displacement = PTCGPointOffsetFromPoint(touchLocation,
                                                           self.touchStartLocation);
    UIEdgeInsets resizingInsets = UIEdgeInsetsZero;
    
    switch (self.selectedResizeWidget.location) {
        case PTResizeHandleLocationTop:
            resizingInsets.top = displacement.dy;
            break;
        case PTResizeHandleLocationTopLeft:
            resizingInsets.top = displacement.dy;
            resizingInsets.left = displacement.dx;
            break;
        case PTResizeHandleLocationLeft:
            resizingInsets.left = displacement.dx;
            break;
        case PTResizeHandleLocationBottomLeft:
            resizingInsets.bottom = -displacement.dy;
            resizingInsets.left = displacement.dx;
            break;
        case PTResizeHandleLocationBottom:
            resizingInsets.bottom = -displacement.dy;
            break;
        case PTResizeHandleLocationBottomRight:
            resizingInsets.bottom = -displacement.dy;
            resizingInsets.right = -displacement.dx;
            break;
        case PTResizeHandleLocationRight:
            resizingInsets.right = -displacement.dx;
            break;
        case PTResizeHandleLocationTopRight:
            resizingInsets.top = displacement.dy;
            resizingInsets.right = -displacement.dx;
            break;
        case PTResizeHandleLocationNone:
            break;
    }
    
    const CGRect contentRect = self.contentRect;
    
    // Minimum width and height ensure that resize widgets do not overlap.
    const CGFloat minimumWidth = fmax(PTResizeWidgetView.length,
                                      CGRectGetWidth(contentRect) - PTResizeWidgetView.length);
    const CGFloat minimumHeight = fmax(PTResizeWidgetView.length,
                                       CGRectGetHeight(contentRect) - PTResizeWidgetView.length);
    
    // Ensure that minimum width and height are maintained by resizing insets.
    resizingInsets.top = fmin(resizingInsets.top, minimumHeight);
    resizingInsets.left = fmin(resizingInsets.left, minimumWidth);
    resizingInsets.bottom = fmin(resizingInsets.bottom, minimumHeight);
    resizingInsets.right = fmin(resizingInsets.right, minimumWidth);
    
    self.contentResizingInsets = resizingInsets;
}

- (void)commitAnnotation
{
    PTFreeText *freetext = nil;
    if ([self.currentAnnotation isKindOfClass:[PTFreeText class]]) {
        freetext = (PTFreeText *)self.currentAnnotation;
    } else {
        freetext = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];
    }
    
    @try {
        // Save the annotation's current bounding box, to be re-rendered later.
        PTPDFRect *oldBbox = [freetext GetRect];
        const CGRect oldScreenBbox = [self PDFRectPage2CGRectScreen:oldBbox PageNumber:self.annotationPageNumber];
        
        PTPDFRect *contentRect = [self CGRectScreen2PDFRectPage:self.contentRect PageNumber:self.annotationPageNumber];
        
        const CGPoint startPageLocation = [self convertScreenPtToPagePt:self.calloutStartPoint onPageNumber:self.annotationPageNumber];
        PTPDFPoint *startPoint = [PTPDFPoint pointWithCGPoint:startPageLocation];
        
        const CGPoint kneePageLocation = [self convertScreenPtToPagePt:self.calloutKneePoint onPageNumber:self.annotationPageNumber];
        PTPDFPoint *kneePoint = [PTPDFPoint pointWithCGPoint:kneePageLocation];
        
        const CGPoint endPageLocation = [self convertScreenPtToPagePt:self.calloutEndPoint onPageNumber:self.annotationPageNumber];
        PTPDFPoint *endPoint = [PTPDFPoint pointWithCGPoint:endPageLocation];
        
        NSMutableArray<PTPDFPoint *> *allPoints = [NSMutableArray array];
        
        // Add callout points.
        [allPoints addObjectsFromArray:@[
            startPoint,
            kneePoint,
            endPoint,
        ]];
        // Add content rect points.
        NSArray<PTPDFPoint *> *contentRectPoints = contentRect.points;
        if (contentRectPoints) {
            [allPoints addObjectsFromArray:contentRectPoints];
        }
        
        // Calculate bounding box for callout and content rect points.
        PTPDFRect *bbox = [PTPDFRect boundingBoxForPoints:allPoints];
        
        // Set callout points.
        [freetext SetCalloutLinePointsWithKneePoint:startPoint
                                                 p2:kneePoint
                                                 p3:endPoint];
        
        // Update annotation rect.
        [freetext SetRect:bbox];
        
        // Update content rect.
        [freetext SetContentRect:contentRect];
        
        [freetext RefreshAppearance];
        
        // Re-render annotation and clear old location.
        [self.pdfViewCtrl UpdateWithAnnot:freetext page_num:self.annotationPageNumber];
        
        [self.pdfViewCtrl UpdateWithRect:[PTPDFRect rectFromCGRect:oldScreenBbox]];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
}

- (void)reset
{
    self.selectedResizeWidget = nil;
    
    self.touchStartLocation = PTCGPointNull;
    self.contentResizingInsets = UIEdgeInsetsZero;
    
    [self setNeedsDisplay];
}

#pragma mark - Moving

- (void)setSelectionRectDelta:(CGRect)deltaRect
{
    // Don't move selection rect while moving a callout point.
    if (self.selectedResizeWidget) {
        return;
    }
    
    [super setSelectionRectDelta:deltaRect];
}

- (void)moveAnnotation:(CGPoint)down
{
    [super moveAnnotation:down];
    
    // Re-"select" the annotation to update callout points and content rect,
    // in screen space.
    [self setSelectedAnnotation:self.currentAnnotation
                   onPageNumber:self.annotationPageNumber];
}

#pragma mark - Editing

- (void)editSelectedAnnotationFreeText
{
    [super editSelectedAnnotationFreeText];
    
    self.calloutStartResizeWidget.hidden = YES;
    self.calloutKneeResizeWidget.hidden = YES;
}

- (CGRect)frameForEditingFreeTextAnnotation
{
    CGRect frame = [self.pdfViewCtrl convertRect:self.contentRect
                                          toView:self.selectionRectContainerView];
    const double lineWidth = self.annotStyle.thickness * self.pdfViewCtrl.zoom;
    const double offset = lineWidth / 2;
    frame = CGRectInset(frame, offset, offset);
    frame = CGRectOffset(frame, -offset/4, offset/4);
    
    return frame;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.calloutStartResizeWidget.superview) {
        const CGPoint center = [self.pdfViewCtrl convertPoint:self.calloutStartPoint toView:self.selectionRectContainerView];
        self.calloutStartResizeWidget.center = center;
    }
    if (self.calloutKneeResizeWidget.superview) {
        const CGPoint center = [self.pdfViewCtrl convertPoint:self.calloutKneePoint toView:self.selectionRectContainerView];
        self.calloutKneeResizeWidget.center = center;
    }
    
    if (self.contentSelectionView.superview) {
        const CGRect resizedRect = UIEdgeInsetsInsetRect(self.contentRect,
                                                         self.contentResizingInsets);
        const CGRect frame = [self.pdfViewCtrl convertRect:resizedRect toView:self.selectionRectContainerView];
        self.contentSelectionView.frame = frame;
    }
}

#pragma mark - Callout points (screen space)

- (void)setCalloutStartPoint:(CGPoint)calloutStartPoint
{
    _calloutStartPoint = calloutStartPoint;
    
    [self PT_calloutPointChanged];
}

- (void)setCalloutKneePoint:(CGPoint)calloutKneePoint
{
    _calloutKneePoint = calloutKneePoint;
    
    [self PT_calloutPointChanged];
}

- (void)setCalloutEndPoint:(CGPoint)calloutEndPoint
{
    _calloutEndPoint = calloutEndPoint;
    
    [self PT_calloutPointChanged];
}

- (void)PT_calloutPointChanged
{
    [self setNeedsLayout];
    
    if (self.selectedResizeWidget) {
        [self setNeedsDisplay];
    }
}

- (void)snapCalloutEndPoint
{
    NSAssert(!PTCGPointIsNull(self.calloutStartPoint), @"calloutStartPoint is null");
    NSAssert(!PTCGPointIsNull(self.calloutKneePoint), @"calloutKneePoint is null");
    NSAssert(!PTCGPointIsNull(self.calloutEndPoint), @"calloutEndPoint is null");
    NSAssert(!CGRectIsNull(self.contentRect), @"contentRect is null");
    
    const CGRect contentRect = UIEdgeInsetsInsetRect(self.contentRect,
                                                     self.contentResizingInsets);
    
    const CGFloat top = CGRectGetMinY(contentRect);
    const CGFloat left = CGRectGetMinX(contentRect);
    const CGFloat bottom = CGRectGetMaxY(contentRect);
    const CGFloat right = CGRectGetMaxX(contentRect);
    
    const CGPoint rectCenter = PTCGRectGetCenter(contentRect);
    const CGFloat centerX = rectCenter.x;
    const CGFloat centerY = rectCenter.y;
    
    const CGPoint topEdgePoint = CGPointMake(centerX, top);
    const CGPoint leftEdgePoint = CGPointMake(left, centerY);
    const CGPoint bottomEdgePoint = CGPointMake(centerX, bottom);
    const CGPoint rightEdgePoint = CGPointMake(right, centerY);
    
    // Calculate the distances from the knee point to the content rect's edges.
    NSDictionary<NSNumber *, NSNumber *> *distances = @{
        // Distance to top edge.
        @(UIRectEdgeTop): @(fabs(PTCGPointDistanceToPoint(topEdgePoint,
                                                          self.calloutKneePoint))),
        // Distance to left edge.
        @(UIRectEdgeLeft): @(fabs(PTCGPointDistanceToPoint(leftEdgePoint,
                                                           self.calloutKneePoint))),
        // Distance to bottom edge.
        @(UIRectEdgeBottom): @(fabs(PTCGPointDistanceToPoint(bottomEdgePoint,
                                                             self.calloutKneePoint))),
        // Distance to right edge.
        @(UIRectEdgeRight): @(fabs(PTCGPointDistanceToPoint(rightEdgePoint,
                                                            self.calloutKneePoint))),
    };
    
    // Find the closest edge to the knee point.
    UIRectEdge closestEdge = UIRectEdgeNone;
    CGFloat minimumDistance = CGFLOAT_MAX;
    for (NSNumber *edge in distances) {
        const CGFloat distance = distances[edge].doubleValue;
        if (distance < minimumDistance) {
            minimumDistance = distance;
            closestEdge = (UIRectEdge)edge.unsignedIntegerValue;
        }
    }
    
    if (closestEdge == UIRectEdgeNone || minimumDistance == CGFLOAT_MAX) {
        return;
    }
    
    // Snap the end point to the closest content rect edge.
    switch (closestEdge) {
        case UIRectEdgeTop:
            self.calloutEndPoint = topEdgePoint;
            break;
        case UIRectEdgeLeft:
            self.calloutEndPoint = leftEdgePoint;
            break;
        case UIRectEdgeBottom:
            self.calloutEndPoint = bottomEdgePoint;
            break;
        case UIRectEdgeRight:
            self.calloutEndPoint = rightEdgePoint;
            break;
        default:
            break;
    }
}

- (void)setContentRect:(CGRect)contentRect
{
    _contentRect = contentRect;
    
    [self setNeedsLayout];
    
    if (self.selectedResizeWidget) {
        [self setNeedsDisplay];
    }
}

- (void)setContentResizingInsets:(UIEdgeInsets)contentResizingInsets
{
    _contentResizingInsets = contentResizingInsets;
    
    [self setNeedsLayout];
    
    if (self.selectedResizeWidget) {
        [self setNeedsDisplay];
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!self.annotStyle || !self.selectedResizeWidget) {
        return;
    }
    
    const CGRect resizedRect = UIEdgeInsetsInsetRect(self.contentRect,
                                                     self.contentResizingInsets);
    const CGRect contentRect = [self.pdfViewCtrl convertRect:resizedRect
                                                      toView:self];
    
    const CGPoint startPoint = [self.pdfViewCtrl convertPoint:self.calloutStartPoint
                                                       toView:self];
    const CGPoint kneePoint = [self.pdfViewCtrl convertPoint:self.calloutKneePoint
                                                      toView:self];
    const CGPoint endPoint = [self.pdfViewCtrl convertPoint:self.calloutEndPoint
                                                     toView:self];
    
    const double lineWidth = 2.0;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.tintColor.CGColor);
    CGContextSetLineWidth(context, lineWidth);
    
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetMiterLimit(context, 10);
    
    CGContextSetFillColorWithColor(context, UIColor.clearColor.CGColor);
    
    CGContextBeginPath(context);
    
    // Draw content rect:
    // Adjust drawn content rect for the width of the line, so that the drawn rect fits
    // entirely inside the content rect.
    CGRect adjustedContentRect = CGRectInset(contentRect,
                                                lineWidth / 4,
                                                lineWidth / 4);
    adjustedContentRect = CGRectOffset(adjustedContentRect,
                                       -(lineWidth / 4),
                                       lineWidth / 4);
    
    CGContextAddRect(context, adjustedContentRect);
    
    // Draw callout line and arrow.
    CGContextMoveToPoint(context, endPoint.x, endPoint.y);
    
    CGContextAddLineToPoint(context, kneePoint.x, kneePoint.y);
    CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
    
    CGContextDrawPath(context, kCGPathFillStroke);
}

@end
