//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFadingScrollView.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTFadingScrollView ()

@property (nonatomic, readwrite) UIEdgeInsets fadingInsets;

@property (nonatomic, strong) CALayer *maskLayer;

@property (nonatomic, strong) CAGradientLayer *horizontalGradientLayer;
@property (nonatomic, strong) CAGradientLayer *verticalGradientLayer;

@end

NS_ASSUME_NONNULL_END

@implementation PTFadingScrollView

static CAGradientLayer *PT_createGradientLayer(void)
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];

    gradientLayer.colors = @[
        ((__bridge id)UIColor.clearColor.CGColor),
        ((__bridge id)UIColor.whiteColor.CGColor),
        ((__bridge id)UIColor.whiteColor.CGColor),
        ((__bridge id)UIColor.clearColor.CGColor),
    ];
    
    gradientLayer.locations = @[
        @0.0,
        @0.0,
        @1.0,
        @1.0,
    ];
    
    return gradientLayer;
}

- (void)PTFadingScrollView_commonInit
{
    _fadingDistance = 44;
    
    _fadingInsets = UIEdgeInsetsZero;
    
    // Horizontal gradient layer.
    _horizontalGradientLayer = PT_createGradientLayer();
    _horizontalGradientLayer.startPoint = CGPointMake(0, 0.5);
    _horizontalGradientLayer.endPoint = CGPointMake(1, 0.5);
    
    // Vertical gradient layer.
    _verticalGradientLayer = PT_createGradientLayer();
    _verticalGradientLayer.startPoint = CGPointMake(0.5, 0);
    _verticalGradientLayer.endPoint = CGPointMake(0.5, 1.0);
    
    _verticalGradientLayer.hidden = YES;
    
    // Masking layer.
    _maskLayer = [CALayer layer];
    
    [_maskLayer addSublayer:_horizontalGradientLayer];
    [_maskLayer addSublayer:_verticalGradientLayer];
    
    self.layer.mask = _maskLayer;
    
    // Schedule layer layout.
    [self.layer setNeedsLayout];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTFadingScrollView_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTFadingScrollView_commonInit];
    }
    return self;
}

#pragma mark - <CALayerDelegate>

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    const CGRect bounds = self.bounds;
    
    // Disable implicit animation of mask layers frame change.
    // Otherwise the mask layers appear to "lag" behind during scrolling,
    // clipping content at the edges.
    [CATransaction begin];
    CATransaction.disableActions = YES;
    
    self.maskLayer.frame = bounds;
    self.horizontalGradientLayer.frame = self.maskLayer.bounds;
    self.verticalGradientLayer.frame = self.maskLayer.bounds;
    
    [CATransaction commit];
    
    const CGSize contentSize = self.contentSize;
    const CGPoint contentOffset = self.contentOffset;
    
    UIEdgeInsets contentInset = self.contentInset;
    if (@available(iOS 11.0, *)) {
        contentInset = self.adjustedContentInset;
    }
    
    CGSize adjustedContentSize = contentSize;
    adjustedContentSize.width += contentInset.left + contentInset.right;
    adjustedContentSize.height += contentInset.top + contentInset.bottom;
    
    UIEdgeInsets fadingInsets = UIEdgeInsetsZero;
    
    // Scrollable up?
    if (contentOffset.y + contentInset.top > 0) {
        fadingInsets.top = fmin(contentOffset.y + contentInset.top,
                                self.fadingDistance);
    }
    // Scrollable left?
    if (contentOffset.x + contentInset.left > 0) {
        fadingInsets.left = fmin(contentOffset.x + contentInset.left,
                                 self.fadingDistance);
    }
    // Scrollable down?
    if (CGRectGetMaxY(bounds) < adjustedContentSize.height) {
        fadingInsets.bottom = fmin(adjustedContentSize.height - CGRectGetMaxY(bounds),
                                   self.fadingDistance);
    }
    // Scrollable right?
    if (CGRectGetMaxX(bounds) < adjustedContentSize.width) {
        fadingInsets.right = fmin(adjustedContentSize.width - CGRectGetMaxX(bounds),
                                  self.fadingDistance);
    }
    
    self.fadingInsets = fadingInsets;
}

#pragma mark - Fading insets

- (void)setFadingInsets:(UIEdgeInsets)fadingInsets
{
    _fadingInsets = fadingInsets;
    
    const CGRect frame = self.frame;
    
    [CATransaction begin];
    CATransaction.disableActions = YES;
    
    self.horizontalGradientLayer.locations = @[
        @0.0,
        @(fadingInsets.left / CGRectGetWidth(frame)),
        @(1.0 - (fadingInsets.right / CGRectGetWidth(frame))),
        @1.0,
    ];
    
    self.verticalGradientLayer.locations = @[
        @0.0,
        @(fadingInsets.top / CGRectGetHeight(frame)),
        @(1.0 - (fadingInsets.bottom / CGRectGetHeight(frame))),
        @1.0,
    ];
    
    [CATransaction commit];
}

@end
