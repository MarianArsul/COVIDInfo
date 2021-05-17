//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "ToolsDefines.h"

#import "PTCheckmarkView.h"

static NSString * const PTCheckmarkView_strokeEndAnimationKey = @"PTCheckmarkView_strokeEndAnimationKey";

@interface PTCheckmarkView ()

@property (nonatomic, assign, getter=isFillColorSet) BOOL fillColorSet;

@property (nonatomic, strong) CAShapeLayer *circleLayer;

@property (nonatomic, strong) CAShapeLayer *pathLayer;
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) UIColor *unselectedFillColor;
@property (nonatomic, strong) UIColor *unselectedStrokeColor;

@end

@implementation PTCheckmarkView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _strokeColor = UIColor.whiteColor;
        _fillColor = self.tintColor;
        _unselectedFillColor = [UIColor.whiteColor colorWithAlphaComponent:0.7];
        _unselectedStrokeColor = [UIColor.blackColor colorWithAlphaComponent:0.2];

        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        circleLayer.strokeColor = _unselectedStrokeColor.CGColor;
        circleLayer.fillColor = _unselectedFillColor.CGColor;
        circleLayer.lineWidth = 1.0;
        
        CGPathRef circlePath = CGPathCreateWithEllipseInRect(frame, nil);
        circleLayer.path = circlePath;
        CGPathRelease(circlePath);
        
        [self.layer addSublayer:circleLayer];
        
        _circleLayer = circleLayer;
        
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.strokeColor = _strokeColor.CGColor;
        pathLayer.fillColor = nil;
        pathLayer.lineWidth = 1.25;
        
        [self.layer addSublayer:pathLayer];
        
        _pathLayer = pathLayer;
        
        // Draw checkmark path at 24pt x 24pt.
        UIBezierPath *path = [UIBezierPath bezierPath];
        
        [path moveToPoint:CGPointMake(5.5, 12.5)];
        [path addLineToPoint:CGPointMake(9, 16)];
        [path addLineToPoint:CGPointMake(17.5, 7.5)];
        
        _path = path;
    }
    return self;
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(24.0, 24.0);
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    if (layer != self.layer) {
        return;
    }
    
    [self layoutCircleLayer];
    [self layoutPathLayer];
}

- (void)layoutCircleLayer
{
    self.circleLayer.frame = self.layer.bounds;
    
    // Update circle path.
    CGPathRef circlePath = CGPathCreateWithEllipseInRect(self.circleLayer.bounds, nil);
    self.circleLayer.path = circlePath;
    CGPathRelease(circlePath);
}

- (void)layoutPathLayer
{
    CGSize size = self.intrinsicContentSize;
    CGRect bounds = self.layer.bounds;
    
    // Center path layer in superlayer.
    CGPoint origin = CGPointMake(CGRectGetMidX(bounds) - (size.width / 2), CGRectGetMidY(bounds) - (size.height / 2));
    
    self.pathLayer.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
}

#pragma mark - Colors

- (void)setStrokeColor:(UIColor *)strokeColor
{
    if (strokeColor) {
        _strokeColor = strokeColor;
    } else {
        _strokeColor = UIColor.whiteColor;
    }
    
    self.pathLayer.strokeColor = _strokeColor.CGColor;
}

- (void)setFillColor:(UIColor *)fillColor
{
    if (fillColor) {
        _fillColor = fillColor;
        self.fillColorSet = YES;
    } else {
        _fillColor = self.tintColor;
        self.fillColorSet = NO;
    }
}

#pragma mark - Tint color

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.fillColor = self.tintColor;
}

#pragma mark - Path animation

- (void)addPathStrokeEndAnimation
{
    [self removePathStrokeEndAnimation];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 0.1;
    pathAnimation.fromValue = @0.0;
    pathAnimation.toValue = @1.0;
    [self.pathLayer addAnimation:pathAnimation forKey:PTCheckmarkView_strokeEndAnimationKey];
}

- (void)removePathStrokeEndAnimation
{
    [self.pathLayer removeAnimationForKey:PTCheckmarkView_strokeEndAnimationKey];
}

#pragma mark - Selected

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selected == selected) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_KEY(self, selected)];
    
    _selected = selected;
    
    if (selected) {
        self.circleLayer.fillColor = self.fillColor.CGColor;
        self.circleLayer.strokeColor = self.strokeColor.CGColor;
        self.pathLayer.path = self.path.CGPath;
        if (animated) {
            [self addPathStrokeEndAnimation];
        }
    } else {
        self.circleLayer.fillColor = self.unselectedFillColor.CGColor;
        self.circleLayer.strokeColor = self.unselectedStrokeColor.CGColor;
        self.pathLayer.path = nil;
        [self removePathStrokeEndAnimation];
    }
    
    [self didChangeValueForKey:PT_KEY(self, selected)];
}

+ (BOOL)automaticallyNotifiesObserversOfSelected
{
    return NO;
}

@end
