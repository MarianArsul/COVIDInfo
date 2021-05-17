//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTResizeWidgetView.h"

static const int circleDiameter = 12;

@interface PTResizeWidgetView ()

@property (nonatomic, readonly, strong, nonnull) CAShapeLayer *shapeLayer;

@end

@implementation PTResizeWidgetView

- (void)PTResizeWidgetView_commonInit
{
    _location = PTResizeHandleLocationNone;
    
    self.backgroundColor = [UIColor clearColor];
    
    // Set up circle shape.
    const CGRect ellipseRect = CGRectInset(self.bounds,
                                           circleDiameter / 2,
                                           circleDiameter / 2);
    
    self.shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:ellipseRect].CGPath;
    
    self.shapeLayer.fillColor = self.tintColor.CGColor;
    self.shapeLayer.strokeColor = UIColor.whiteColor.CGColor;
    self.shapeLayer.lineWidth = 1.0;
    
    self.shapeLayer.shadowColor = UIColor.blackColor.CGColor;
    self.shapeLayer.shadowRadius = 0.5;
    self.shapeLayer.shadowOpacity = 0.2;
    self.shapeLayer.shadowOffset = CGSizeMake(0, 1);
}

- (instancetype)initAtPoint:(CGPoint)point WithLocation:(PTResizeHandleLocation)loc
{
    const int length = PTResizeWidgetView.length;
    
    self = [self initWithFrame:CGRectMake(point.x, point.y, length, length)];
    if (self) {
        _location = loc;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTResizeWidgetView_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTResizeWidgetView_commonInit];
    }
    return self;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    [self updateShapeLayer];
}

-(void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        // Update color after moving to a window (and obtaining an inherited tint color).
        [self updateColor];
    }
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    [self updateColor];
}

- (void)updateColor
{
    self.shapeLayer.fillColor = self.tintColor.CGColor;
}

+ (int)length
{
    return circleDiameter*2;
}

#pragma mark - Constraints

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(PTResizeWidgetView.length, PTResizeWidgetView.length);
}

#pragma mark - Layer

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer
{
    return (CAShapeLayer *)(self.layer);
}

- (void)updateShapeLayer
{
    const CGRect ellipseRect = CGRectInset(self.bounds,
                                           circleDiameter / 2,
                                           circleDiameter / 2);
    
    self.shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:ellipseRect].CGPath;
}

@end
