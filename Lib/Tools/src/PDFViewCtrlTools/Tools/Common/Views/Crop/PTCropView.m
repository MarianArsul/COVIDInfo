//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCropView.h"

#import "CGGeometry+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTCropView ()

// BEGIN: RE-DECLARE AS READWRITE INTERNALLY
@property (nonatomic, readwrite, strong) UIView *contentView;
@property (nonatomic, readwrite, strong) PTShapeView *cropAreaView;
@property (nonatomic, readwrite, copy) NSArray<PTShapeView *> *handleViews;

@property (nonatomic, readwrite, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, readwrite, assign) UIRectEdge resizingEdges;
@property (nonatomic, readwrite, assign) UIEdgeInsets resizingCropInset;
// END: RE-DECLARE AS READWRITE INTERNALLY

@property (nonatomic, strong, nullable) NSLayoutConstraint *topCropLayoutConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *leftCropLayoutConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomCropLayoutConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *rightCropLayoutConstraint;

@property (nonatomic, strong) UIView *cropMaskView;
@property (nonatomic, strong) UIView *cropMaskBackgroundView;
@property (nonatomic, strong) UIView *cropMaskForegroundView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTCropView

- (void)PTCropView_commonInit
{
    // drawRect: does not fill the entire view's contents.
    self.opaque = NO;
    
    // Content view.
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _contentView.backgroundColor = nil;
    
    [self addSubview:_contentView];
    
    _cropMaskView = [[UIView alloc] initWithFrame:_contentView.bounds];
    _cropMaskView.backgroundColor = nil;
    _cropMaskView.alpha = 1.0;
    
    _cropMaskBackgroundView = [[UIView alloc] initWithFrame:_cropMaskView.bounds];
    _cropMaskBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _cropMaskBackgroundView.backgroundColor = UIColor.whiteColor;
    _cropMaskBackgroundView.alpha = 0.5;
    
    [_cropMaskView addSubview:_cropMaskBackgroundView];
    
    _cropMaskForegroundView = [[UIView alloc] initWithFrame:_cropMaskView.bounds];
    _cropMaskForegroundView.backgroundColor = UIColor.whiteColor;
    _cropMaskForegroundView.alpha = 1.0;
    
    [_cropMaskView addSubview:_cropMaskForegroundView];
    
    _contentView.maskView = _cropMaskView;
    
    // Crop area view.
    _cropAreaView = [[PTShapeView alloc] init];
    _cropAreaView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _cropAreaView.layer.fillColor = nil;
    _cropAreaView.layer.strokeColor = UIColor.blackColor.CGColor;
    _cropAreaView.layer.lineWidth = 2.0;
    _cropAreaView.layer.lineDashPattern = @[ @5.0, @5.0 ];
    
    [self addSubview:_cropAreaView];
    
    // Handle views.
    NSMutableArray<PTShapeView *> *handleViews = [NSMutableArray array];
    
    // Handle locations, in clockwise order from top-left.
    const UIRectEdge handleLocations[] = {
        (UIRectEdgeTop | UIRectEdgeLeft),
        (UIRectEdgeTop),
        (UIRectEdgeTop | UIRectEdgeRight),
        (UIRectEdgeRight),
        (UIRectEdgeBottom | UIRectEdgeRight),
        (UIRectEdgeBottom),
        (UIRectEdgeBottom | UIRectEdgeLeft),
        (UIRectEdgeLeft),
    };
    const size_t locationCount = PT_C_ARRAY_SIZE(handleLocations);
    for (size_t i = 0; i < locationCount; i++) {
        const UIRectEdge handleLocation = handleLocations[i];
        
        // Create a view for the handle location.
        PTShapeView *handleView = [[PTShapeView alloc] init];
        handleView.tag = handleLocation;
        
        handleView.layer.fillColor = UIColor.blackColor.CGColor;
        handleView.layer.strokeColor = UIColor.whiteColor.CGColor;
        handleView.layer.lineWidth = 1.0;
        
        handleView.layer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0,
                                                                            10, 10)].CGPath;
        
        [self addSubview:handleView];
        
        [handleViews addObject:handleView];
    }
    
    _handleViews = [handleViews copy];
    
    // Schedule constraints load.
    [self setNeedsUpdateConstraints];
    
    // (Edge) pan gesture recognizer.
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    _panGestureRecognizer.delegate = self;
    
    [_panGestureRecognizer addTarget:self action:@selector(handlePanGesture:)];
    
    [self addGestureRecognizer:_panGestureRecognizer];
    
    _cropInset = UIEdgeInsetsZero;
    
    _resizingEdges = UIRectEdgeNone;
    _resizingCropInset = UIEdgeInsetsZero;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTCropView_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)updateCropConstraints
{
    const UIEdgeInsets effectiveCropInset = [self effectiveCropInset];
    
    self.topCropLayoutConstraint.constant = effectiveCropInset.top;
    self.leftCropLayoutConstraint.constant = effectiveCropInset.left;
    // The bottom and right crop insets are positive and must be negated to get the offset of
    // the cropped area from the bottom or right of the view. The follows the normal convention
    // for UIEdgeInsets from the interior edges of views.
    self.bottomCropLayoutConstraint.constant = -effectiveCropInset.bottom;
    self.rightCropLayoutConstraint.constant = -effectiveCropInset.right;
    
//    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (NSArray<NSLayoutConstraint *> *)constraintsForHandleView:(PTShapeView *)shapeView atLocation:(UIRectEdge)location withAnchorView:(UIView *)anchorView
{
    NSLayoutXAxisAnchor *horizontalAnchor = nil;
    if ((location & UIRectEdgeLeft) == UIRectEdgeLeft) {
        horizontalAnchor = anchorView.leadingAnchor;
    }
    else if ((location & UIRectEdgeRight) == UIRectEdgeRight) {
        horizontalAnchor = anchorView.trailingAnchor;
    }
    else { // Centered.
        horizontalAnchor = anchorView.centerXAnchor;
    }
    
    NSLayoutYAxisAnchor *verticalAnchor = nil;
    if ((location & UIRectEdgeTop) == UIRectEdgeTop) {
        verticalAnchor = anchorView.topAnchor;
    }
    else if ((location & UIRectEdgeBottom) == UIRectEdgeBottom) {
        verticalAnchor = anchorView.bottomAnchor;
    }
    else { // Centered.
        verticalAnchor = anchorView.centerYAnchor;
    }
    
    return @[
        [shapeView.centerXAnchor constraintEqualToAnchor:horizontalAnchor],
        [shapeView.centerYAnchor constraintEqualToAnchor:verticalAnchor],
    ];
}

- (void)loadConstraints
{
    UILayoutGuide *cropLayoutGuide = [[UILayoutGuide alloc] init];
    [self addLayoutGuide:cropLayoutGuide];
    
    // Crop layout guide.
    [NSLayoutConstraint activateConstraints:@[
        [cropLayoutGuide.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor],
        [cropLayoutGuide.leftAnchor constraintGreaterThanOrEqualToAnchor:self.leftAnchor],
        [cropLayoutGuide.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor],
        [cropLayoutGuide.rightAnchor constraintLessThanOrEqualToAnchor:self.rightAnchor],
    ]];
    
    // (Optional) crop layout guide edge constraints, with constants for the crop inset(s).
    [NSLayoutConstraint pt_activateConstraints:@[
        (self.topCropLayoutConstraint =
         [cropLayoutGuide.topAnchor constraintEqualToAnchor:self.topAnchor constant:0]),
        (self.leftCropLayoutConstraint =
         [cropLayoutGuide.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0]),
        (self.bottomCropLayoutConstraint =
         [cropLayoutGuide.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0]),
        (self.rightCropLayoutConstraint =
         [cropLayoutGuide.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0]),
    ] withPriority:UILayoutPriorityDefaultHigh];
    
    self.cropAreaView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Crop area view.
    [NSLayoutConstraint activateConstraints:@[
        [self.cropAreaView.leadingAnchor constraintEqualToAnchor:cropLayoutGuide.leadingAnchor],
        [self.cropAreaView.topAnchor constraintEqualToAnchor:cropLayoutGuide.topAnchor],
        [self.cropAreaView.trailingAnchor constraintEqualToAnchor:cropLayoutGuide.trailingAnchor],
        [self.cropAreaView.bottomAnchor constraintEqualToAnchor:cropLayoutGuide.bottomAnchor],
    ]];
    
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];
    
    for (PTShapeView *handleView in self.handleViews) {
        handleView.translatesAutoresizingMaskIntoConstraints = NO;
        
        const UIRectEdge handleLocation = (UIRectEdge)handleView.tag;
        
        [constraints addObjectsFromArray:[self constraintsForHandleView:handleView
                                                             atLocation:handleLocation
                                                         withAnchorView:self.cropAreaView]];
        
        [constraints addObjectsFromArray:@[
            // Dimension constraints.
            [handleView.widthAnchor constraintEqualToConstant:10],
            [handleView.widthAnchor constraintEqualToAnchor:handleView.heightAnchor],
            
            // Constrain handle view to interior of this view.
            [handleView.centerXAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
            [handleView.centerXAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
            [handleView.centerYAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor],
            [handleView.centerYAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor],
        ]];
    }
    
    if (constraints.count > 0) {
        [NSLayoutConstraint activateConstraints:constraints];
    }
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    const CGRect cropBounds = self.cropAreaView.frame;
    
    // Update crop mask frames.
    self.cropMaskView.frame = self.contentView.bounds;
    self.cropMaskForegroundView.frame = cropBounds;
    self.cropMaskBackgroundView.frame = self.cropMaskView.bounds;
    
    // Only show content outside crop bounds while resizing.
    self.cropMaskBackgroundView.alpha = ([self isResizing]) ? 0.5 : 0.0;
    
    UIBezierPath *borderPath = [UIBezierPath bezierPath];
    const CGPoint borderPathPoints[] = {
        CGPointMake(0, 0),
        CGPointMake(1, 0),
        CGPointMake(1, 1),
        CGPointMake(0, 1),
        CGPointMake(0, 0),
    };
    const size_t borderPathPointCount = PT_C_ARRAY_SIZE(borderPathPoints);
    for (size_t i = 0; i < borderPathPointCount; i++) {
        CGPoint point = borderPathPoints[i];
        point.x *= CGRectGetWidth(cropBounds);
        point.y *= CGRectGetHeight(cropBounds);
        
        if (![borderPath isEmpty]) {
            [borderPath addLineToPoint:point];
        }
        [borderPath moveToPoint:point];
    }
    self.cropAreaView.layer.path = borderPath.CGPath;
}

#pragma mark - Crop insets

- (void)setCropInset:(UIEdgeInsets)cropInset
{
    _cropInset = cropInset;
    
    [self updateCropConstraints];
}

- (void)setResizingCropInset:(UIEdgeInsets)resizingCropInset
{
    _resizingCropInset = resizingCropInset;
    
    [self updateCropConstraints];
}

- (UIEdgeInsets)effectiveCropInset
{
    const UIEdgeInsets cropInset = self.cropInset;
    const UIEdgeInsets resizingCropInset = self.resizingCropInset;
    
    return UIEdgeInsetsMake(cropInset.top + resizingCropInset.top,
                            cropInset.left + resizingCropInset.left,
                            cropInset.bottom + resizingCropInset.bottom,
                            cropInset.right + resizingCropInset.right);
}

#pragma mark - Crop bounds

- (CGRect)cropBounds
{
    return UIEdgeInsetsInsetRect(self.bounds, [self effectiveCropInset]);
}

#pragma mark - Resizing

- (BOOL)isResizing
{
    return (self.resizingEdges != UIRectEdgeNone);
}

#pragma mark - Gestures

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            const CGPoint touchLocation = [recognizer locationInView:self];
            
            // Find the handle closest to the touch.
            CGFloat minimumDistance = CGFLOAT_MAX;
            PTShapeView *closestHandleView = nil;
            for (PTShapeView *handleView in self.handleViews) {
                CGFloat distanceToTouch = PTCGPointDistanceToPoint(touchLocation,
                                                                   handleView.center);
                if (distanceToTouch < minimumDistance) {
                    minimumDistance = distanceToTouch;
                    closestHandleView = handleView;
                }
            }
            NSAssert(closestHandleView != nil,
                     @"The touch must be close to a handle view");
            
            const UIRectEdge handleLocation = (UIRectEdge)closestHandleView.tag;
            
            self.resizingEdges = handleLocation;
            self.resizingCropInset = UIEdgeInsetsZero;
            
            [UIView animateWithDuration:0.1 animations:^{
                [self layoutIfNeeded];
            }];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            NSAssert(self.resizingEdges != UIRectEdgeNone,
                     @"Crop resizing edges must be set");
            
            const CGPoint translation = [recognizer translationInView:self];
            
            UIEdgeInsets resizingCropInset = self.resizingCropInset;
            
            // Horizontal resizing crop inset changes.
            if (PT_BITMASK_CHECK(self.resizingEdges, UIRectEdgeLeft)) {
                resizingCropInset.left = translation.x;
            }
            else if (PT_BITMASK_CHECK(self.resizingEdges, UIRectEdgeRight)) {
                // Flip x-translation, to make a positive right inset from a rightwards translation.
                resizingCropInset.right = -(translation.x);
            }
            
            // Vertical resizing crop inset changes.
            if (PT_BITMASK_CHECK(self.resizingEdges, UIRectEdgeTop)) {
                resizingCropInset.top = translation.y;
            }
            else if (PT_BITMASK_CHECK(self.resizingEdges, UIRectEdgeBottom)) {
                // Flip y-translation, to make a positive bottom inset from an upwards translation.
                resizingCropInset.bottom = -(translation.y);
            }
                        
            self.resizingCropInset = resizingCropInset;
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            const UIEdgeInsets resizingCropInset = self.resizingCropInset;
            
            // Apply the resizing crop inset to the (normal) crop inset.
            UIEdgeInsets cropInset = self.cropInset;
            
            cropInset.top = fmax(0, cropInset.top + resizingCropInset.top);
            cropInset.left = fmax(0, cropInset.left + resizingCropInset.left);
            cropInset.bottom = fmax(0, cropInset.bottom + resizingCropInset.bottom);
            cropInset.right = fmax(0, cropInset.right + resizingCropInset.right);
            
            self.cropInset = cropInset;
            
            self.resizingEdges = UIRectEdgeNone;
            self.resizingCropInset = UIEdgeInsetsZero;
            
            [UIView animateWithDuration:0.1 animations:^{
                [self layoutIfNeeded];
            }];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        {
            // Don't apply the resizing crop inset to the (normal) crop inset.
            self.resizingEdges = UIRectEdgeNone;
            self.resizingCropInset = UIEdgeInsetsZero;
        }
            break;
        default:
            break;
    }
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.panGestureRecognizer) {
        // The pan gesture recognizer should only receive touches within the outer 44pts of its
        // interior.
        // In other words, touches inside the 44pts-inset bounds rect should be ignored.
        const CGPoint touchLocation = [touch locationInView:self];
        
        const CGRect cropBounds = self.cropAreaView.frame;
        
        const CGFloat adjustment = 44.0 / 2;
        const CGRect outerTouchBounds = CGRectInset(cropBounds, -adjustment, -adjustment);
        const CGRect innerTouchBounds = CGRectInset(cropBounds, adjustment, adjustment);
        
        NSAssert(!CGRectIsNull(outerTouchBounds), @"Unhandled null rect");
        NSAssert(!CGRectIsNull(innerTouchBounds), @"Unhandled null rect");
        
        return (CGRectContainsPoint(outerTouchBounds, touchLocation) &&
                !CGRectContainsPoint(innerTouchBounds, touchLocation));
    }
    
    return YES;
}



@end
