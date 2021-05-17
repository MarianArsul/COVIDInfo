//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTColorIndicatorView.h"

#import "PTToolsUtil.h"

#import "NSLayoutConstraint+PTPriority.h"

@interface PTColorIndicatorView ()

@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@property (nonatomic, strong) CAShapeLayer *noColorLayer;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

@implementation PTColorIndicatorView

- (void)PTColorIndicatorView_commonInit
{
    _shapeLayer = [CAShapeLayer layer];
    [self.layer addSublayer:_shapeLayer];
    
    _noColorLayer = [CAShapeLayer layer];
    [_shapeLayer addSublayer:_noColorLayer];
    
    UIImage *image = [UIImage imageNamed:@"checkmark_black"
                                inBundle:[PTToolsUtil toolsBundle]
           compatibleWithTraitCollection:self.traitCollection];
    
    // Render image as template (for tint color).
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    _checkmarkView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:_checkmarkView];
    _checkmarkView.hidden = YES;
    
    _checkmarkView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.80];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTColorIndicatorView_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.checkmarkView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.checkmarkView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.checkmarkView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.widthAnchor constraintEqualToAnchor:self.heightAnchor],
    ] withPriority:(UILayoutPriorityRequired - 1)];
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

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    if (layer == self.shapeLayer.superlayer) {
        self.shapeLayer.frame = self.shapeLayer.superlayer.bounds;
        self.shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.shapeLayer.frame].CGPath;
        self.shapeLayer.strokeColor = [UIColor colorWithWhite:0.0 alpha:0.3].CGColor;
        if (@available(iOS 13.0, *)) {
            self.shapeLayer.strokeColor = UIColor.opaqueSeparatorColor.CGColor;
        }
        self.shapeLayer.lineWidth = 1.0;

        CGRect noColorFrame = self.shapeLayer.bounds;
        self.noColorLayer.frame = noColorFrame;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        CGFloat delta = sin(M_PI_4)*noColorFrame.size.width*0.5;
        CGPoint center = CGPointMake(noColorFrame.size.width*0.5, noColorFrame.size.height*0.5);
        CGPoint topRight = CGPointMake(center.x+delta, center.y-delta);
        CGPoint bottomLeft = CGPointMake(center.x-delta, center.y+delta);
        [path moveToPoint:bottomLeft];
        [path addLineToPoint:topRight];
        self.noColorLayer.path = path.CGPath;
        self.noColorLayer.strokeColor = [UIColor redColor].CGColor;
    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(30, 30);
}

#pragma mark - Color

- (void)setColor:(UIColor *)color
{
    _color = color;
    
    self.shapeLayer.fillColor = color.CGColor;
    if ([color isEqual:UIColor.clearColor] || CGColorGetAlpha(color.CGColor) == 0.0) {
        self.noColorLayer.lineWidth = 1.0;
    } else{
        self.noColorLayer.lineWidth = 0.0;
    }
    
//    // Adjust checkmark tint color for improved constrast.
//    CGFloat red, green, blue, alpha;
//    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
//        red = green = blue = 0.0;
//        alpha = CGColorGetAlpha(color.CGColor);
//    }
//
//    CGFloat white, tintWhite;
//    if ([color getWhite:&white alpha:nil] && white < 0.5 && alpha > 0.0) {
//        tintWhite = 1.0;
//    } else {
//        tintWhite = 0.0;
//    }
//    self.checkmarkView.tintColor = [UIColor colorWithWhite:tintWhite alpha:0.54];
}

#pragma mark - Selected

- (void)setSelected:(BOOL)selected
{
    if (_selected == selected) {
        // No change.
        return;
    }
    
    _selected = selected;
    
    // Update checkmark view visibility.
    self.checkmarkView.hidden = !selected;
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        self.shapeLayer.strokeColor = UIColor.opaqueSeparatorColor.CGColor;
    }
}

@end
