//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationUnreadIndicatorView.h"

@implementation PTCollaborationUnreadIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _shapeLayer = [[CAShapeLayer alloc] init];
        _shapeLayer.frame = self.layer.bounds;
        
        _shapeLayer.strokeColor = nil;
        _shapeLayer.fillColor = self.tintColor.CGColor;
        
        [self.layer addSublayer:_shapeLayer];
        
        [_shapeLayer setNeedsLayout];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(10.0, 10.0);
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    self.shapeLayer.frame = self.layer.bounds;
    
    self.shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.shapeLayer.bounds].CGPath;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    self.shapeLayer.fillColor = self.tintColor.CGColor;
}

@end
