//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentSlider.h"

#include <tgmath.h>

@interface PTDocumentSliderThumbView : UIView

@property (nonatomic, weak) PTDocumentSlider* slider;

@end

@implementation PTDocumentSliderThumbView

- (instancetype)initWithSlider:(PTDocumentSlider*)slider
{
    self = [super init];
    if (self) {
        _slider = slider;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef currentContext = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(currentContext, 2.0);
    CGContextSetLineCap(currentContext, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(currentContext, UIColor.lightGrayColor.CGColor);

    CGContextBeginPath (currentContext);

    if( self.slider.axis == UILayoutConstraintAxisHorizontal)
    {
        CGContextMoveToPoint(currentContext, self.bounds.size.width/2-2, self.center.y-5);
        CGContextAddLineToPoint(currentContext, self.bounds.size.width/2-2, self.center.y+5);

        CGContextMoveToPoint(currentContext, self.bounds.size.width/2+2, self.center.y-5);
        CGContextAddLineToPoint(currentContext, self.bounds.size.width/2+2, self.center.y+5);
    }
    else
    {
        CGContextMoveToPoint(currentContext, self.bounds.size.width/2-5, self.center.y-2);
        CGContextAddLineToPoint(currentContext, self.bounds.size.width/2+5, self.center.y-2);
        
        CGContextMoveToPoint(currentContext, self.bounds.size.width/2-5, self.center.y+2);
        CGContextAddLineToPoint(currentContext, self.bounds.size.width/2+5, self.center.y+2);
    }

    CGContextStrokePath(currentContext);
}

@end

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentSlider ()
{
    BOOL _needsUpdateThumbConstraints;
}

@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *thumbConstraints;
@property (nonatomic, weak, nullable) NSLayoutConstraint *thumbValueConstraint;

@property (nonatomic, nullable) UIImpactFeedbackGenerator *impactFeedbackGenerator;

@property (nonatomic, retain) NSLayoutConstraint* compressConstraint;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentSlider

- (void)PTDocumentSlider_commonInit
{
    _axis = UILayoutConstraintAxisHorizontal;
    
    _minimumValue = 0.0;
    _maximumValue = 1.0;
    
    _value = _minimumValue;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTDocumentSlider_commonInit];
        
        _thumbView = [[UIView alloc] init];
        _thumbView.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 13.0, *)) {
            _thumbView.backgroundColor = UIColor.secondarySystemBackgroundColor;
        } else {
            _thumbView.backgroundColor = UIColor.whiteColor;
        }
        
        _thumbView.layer.shadowColor = UIColor.blackColor.CGColor;
        _thumbView.layer.shadowOpacity = 0.2;
        _thumbView.layer.shadowRadius = 1.0;
        _thumbView.layer.shadowOffset = CGSizeMake(0.0, 2.0);
        
        
        
        [self addSubview:_thumbView];
        
        PTDocumentSliderThumbView *appearanceView = [[PTDocumentSliderThumbView alloc] initWithSlider:self];
        appearanceView.contentMode = UIViewContentModeRedraw;
        appearanceView.opaque = NO;
        appearanceView.frame = _thumbView.bounds;
        appearanceView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight);
        [_thumbView addSubview:appearanceView];
        
        _compress = 1.0;
        
        _needsUpdateThumbConstraints = YES;
    }
    return self;
}

#pragma mark - Constraints

-(void)setCompress:(CGFloat)compress
{
    if( _compress != compress )
    {
        _compress = compress;
        
        self.compressConstraint.constant = 44*compress;
        [self layoutIfNeeded];

    }
}

- (void)setNeedsUpdateThumbConstraints
{
    _needsUpdateThumbConstraints = YES;
    [self setNeedsUpdateConstraints];
}

- (void)updateThumbConstraints
{
    if (self.thumbConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.thumbConstraints];
        self.thumbConstraints = nil;
    }
        
    switch (self.axis) {
        case UILayoutConstraintAxisHorizontal:
        {
            NSLayoutConstraint *valueConstraint = ({
                const CGFloat constant = [self constraintConstantForValue:self.value];
                [self.thumbView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor
                                                             constant:constant];
            });
            valueConstraint.priority = (UILayoutPriorityRequired - 1);
            
            self.compressConstraint = [self.thumbView.widthAnchor constraintEqualToConstant:44.0];
            
            self.thumbConstraints = @[
                [self.thumbView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
                [self.thumbView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
                [self.thumbView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                
                self.compressConstraint ,
                [self.thumbView.heightAnchor constraintEqualToConstant:32.0],

                (valueConstraint),
            ];
            self.thumbValueConstraint = valueConstraint;
        }
            break;
        case UILayoutConstraintAxisVertical:
        {
            NSLayoutConstraint *valueConstraint = ({
                const CGFloat constant = [self constraintConstantForValue:self.value];
                [self.thumbView.topAnchor constraintEqualToAnchor:self.topAnchor
                                                         constant:constant];
            });
            valueConstraint.priority = (UILayoutPriorityRequired - 1);
            
            
            self.compressConstraint = [self.thumbView.heightAnchor constraintEqualToConstant:44.0];
            
            self.thumbConstraints = @[
                [self.thumbView.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor],
                [self.thumbView.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor],
                [self.thumbView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                
                [self.thumbView.widthAnchor constraintEqualToConstant:32.0],
                self.compressConstraint,
                
                (valueConstraint),
            ];
            self.thumbValueConstraint = valueConstraint;
        }
            break;
    }
    
    if (self.thumbConstraints) {
        [NSLayoutConstraint activateConstraints:self.thumbConstraints];
    }
}

- (void)updateConstraints
{
    if (_needsUpdateThumbConstraints) {
        [self updateThumbConstraints];
        
        _needsUpdateThumbConstraints = NO;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

- (CGFloat)constraintConstantForValue:(CGFloat)value
{
    const CGRect trackRect = [self trackRect];
    
    switch (self.axis) {
        case UILayoutConstraintAxisHorizontal:
            return CGRectGetWidth(trackRect) * value;
        case UILayoutConstraintAxisVertical:
            return CGRectGetHeight(trackRect) * value;
    }
}

- (void)updateThumbValueConstraint
{
    self.thumbValueConstraint.constant = [self constraintConstantForValue:self.value];
}

- (CGSize)intrinsicContentSize
{
    switch (self.axis) {
        case UILayoutConstraintAxisHorizontal:
            return CGSizeMake(UIViewNoIntrinsicMetric, 44.0);
        case UILayoutConstraintAxisVertical:
            return CGSizeMake(44.0, UIViewNoIntrinsicMetric);
    }
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Layout

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    [self updateThumbValueConstraint];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.thumbView.layer.cornerRadius = fmin(CGRectGetWidth(self.thumbView.bounds),
                                             CGRectGetHeight(self.thumbView.bounds)) / 2;
}

#pragma mark Track rect

- (UIEdgeInsets)trackInsetsForThumbRect:(CGRect)thumbRect
{
    switch (self.axis) {
        case UILayoutConstraintAxisHorizontal:
        {
            // Inset track left & right edges by half of thumb width.
            return UIEdgeInsetsMake(0, CGRectGetWidth(thumbRect) / 2,
                                    0, CGRectGetWidth(thumbRect) / 2);
        }
        case UILayoutConstraintAxisVertical:
        {
            // Inset trakc top & bottom edges by half of thumb height.
            return UIEdgeInsetsMake(CGRectGetHeight(thumbRect) / 2, 0,
                                    CGRectGetHeight(thumbRect) / 2, 0);
        }
    }
}

- (CGRect)trackRect
{
    const CGRect thumbRect = self.thumbView.frame;
    const UIEdgeInsets insets = [self trackInsetsForThumbRect:thumbRect];
    
    return UIEdgeInsetsInsetRect(self.bounds, insets);
}

#pragma mark - Axis

- (void)setAxis:(UILayoutConstraintAxis)axis
{
    const UILayoutConstraintAxis previousAxis = _axis;
    if (previousAxis == axis) {
        return;
    }
    
    _axis = axis;
    
    [self setNeedsUpdateThumbConstraints];
    [self invalidateIntrinsicContentSize];
}

#pragma mark - Touches

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    // Only accept touches on subviews.
    if (view == self) {
        return nil;
    }
    // "Steal" touches from subviews. Necessary for touch tracking to work in this control.
    // The other option is to disable user interaction on all subviews but then they we would need
    // to manually perform the hit test (ie. replicate the internal UIKit implementation).
    if ([view isDescendantOfView:self]) {
        return self;
    }
    return view;
}

#pragma mark - Tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    const BOOL tracking = [super beginTrackingWithTouch:touch withEvent:event];
    if (tracking) {
        // Use a medium impact for touch tracking feedback.
        // NOTE: UIScrollView's scroll indicators use a _UIClickFeedbackGenerator, so
        // the exact haptic feedback can't be replicated.
        self.impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [self.impactFeedbackGenerator prepare];
        
        // Trigger an impact when touch tracking begins.
        [self.impactFeedbackGenerator impactOccurred];
    }
    return tracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    const BOOL tracking = [super continueTrackingWithTouch:touch withEvent:event];
    
    const CGPoint touchLocation = [touch locationInView:self];
    switch (self.axis) {
        case UILayoutConstraintAxisHorizontal:
        {
            const CGFloat offset = touchLocation.x - CGRectGetMinX(self.bounds);
            self.value = (offset) / CGRectGetWidth(self.bounds) * [self extentOfValue];
        }
            break;
        case UILayoutConstraintAxisVertical:
        {
            const CGFloat offset = touchLocation.y - CGRectGetMinY(self.bounds);
            self.value = (offset) / CGRectGetHeight(self.bounds) * [self extentOfValue];
        }
            break;
    }
    [self sendActionsForControlEvents:(UIControlEventValueChanged)];
    
    // Keep feedback generator in prepared state.
    [self.impactFeedbackGenerator prepare];
    
    return tracking;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    
    // Trigger an impact when touch tracking ends.
    [self.impactFeedbackGenerator impactOccurred];
    self.impactFeedbackGenerator = nil;
}

#pragma mark - Value

- (void)setValue:(CGFloat)value
{
    [self setValue:value animated:NO];
}

- (void)setValue:(CGFloat)value animated:(BOOL)animated
{
    [self willChangeValueForKey:PT_SELF_KEY(value)];
    
    // Clamp value to [minimumValue, maximumValue].
    const CGFloat clampedValue = fmax(self.minimumValue, fmin(value, self.maximumValue));
    
    _value = clampedValue;
    
    self.thumbValueConstraint.constant = [self constraintConstantForValue:clampedValue];

    [self didChangeValueForKey:PT_SELF_KEY(value)];
}

+ (BOOL)automaticallyNotifiesObserversOfValue
{
    return NO;
}

#pragma mark - Minimum/maximum value

- (void)setMinimumValue:(CGFloat)minimumValue
{
    _minimumValue = minimumValue;
    
    if (self.maximumValue < minimumValue) {
        self.maximumValue = minimumValue;
    }
    if (self.value < minimumValue) {
        self.value = minimumValue;
    }
}

- (void)setMaximumValue:(CGFloat)maximumValue
{
    _maximumValue = maximumValue;
    
    if (self.minimumValue > maximumValue) {
        self.minimumValue = maximumValue;
    }
    if (self.value > maximumValue) {
        self.value = maximumValue;
    }
}

- (CGFloat)extentOfValue
{
    return self.maximumValue - self.minimumValue;
}

@end
