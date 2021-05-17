//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBadgeIndicatorView.h"

@interface PTBadgeIndicatorView ()

@property (nonatomic, readonly, strong) CAShapeLayer *shapeLayer;

@end

@implementation PTBadgeIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _shapeLayer = [[CAShapeLayer alloc] init];
        _shapeLayer.strokeColor = nil;
        _shapeLayer.fillColor = UIColor.redColor.CGColor;
        [self.layer addSublayer:_shapeLayer];
    }
    return self;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    CGRect oldFrame = _shapeLayer.frame;
    _shapeLayer.frame = layer.bounds;
    
    if (!CGRectEqualToRect(oldFrame, _shapeLayer.frame)) {
        _shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:_shapeLayer.bounds].CGPath;
    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(8.0, 8.0);
}

@end
