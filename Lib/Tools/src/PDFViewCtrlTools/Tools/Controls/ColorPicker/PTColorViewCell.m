//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTColorViewCell.h"

#import "PTToolsUtil.h"

static const CGFloat PT_cellBorderRadius = 1.0;
static const CGFloat PT_noColorLineWidth = 1.0;

static NSString * const PT_imageNameCheckmarkBlack = @"checkmark_black";

@interface PTColorViewCell ()

@property (nonatomic, strong) CAShapeLayer *noColorLayer;

@property (nonatomic, readonly) UIBezierPath *noColorPath;

@property (nonatomic) BOOL didSetupConstraints;

@end

@implementation PTColorViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [UIView performWithoutAnimation:^{
            self.contentView.layer.cornerRadius = CGRectGetWidth(self.contentView.bounds) / 2.0;
        }];

        UIImage *image = [UIImage imageNamed:PT_imageNameCheckmarkBlack
                                    inBundle:[PTToolsUtil toolsBundle]
               compatibleWithTraitCollection:self.traitCollection];
        
        // Render image as template (for tint color).
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        _checkmarkView = [[UIImageView alloc] initWithImage:image];
        [self.contentView addSubview:_checkmarkView];
        _checkmarkView.hidden = YES;
        
        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Update no-color layer's path after layout.
    if ([self.contentView.layer.sublayers containsObject:self.noColorLayer]) {
        self.noColorLayer.path = self.noColorPath.CGPath;
    }
    
    [UIView performWithoutAnimation:^{
        self.contentView.layer.cornerRadius = CGRectGetWidth(self.contentView.bounds) / 2.0;
    }];
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        self.checkmarkView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [self.checkmarkView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
           [self.checkmarkView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
           ]];
        
        // Constraints are set up.
        self.didSetupConstraints = YES;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.contentView.layer.borderWidth = 0.0;
    
    [self.noColorLayer removeFromSuperlayer];
    
    self.contentView.layer.masksToBounds = NO;
}

- (void)configureForColor:(UIColor *)color
{
    self.contentView.backgroundColor = color;
    
    CGFloat red, green, blue, alpha;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        red = green = blue = 0.0;
        alpha = CGColorGetAlpha(color.CGColor);
    }
    
    if ((red == green && green == blue) || alpha == 0.0) {
        // Draw border around grayscale / transparent colors.
        UIColor *borderColor = [UIColor lightGrayColor];
        if (@available(iOS 13.0, *)) {
            borderColor = [[UIColor colorNamed:@"UIFGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection] colorWithAlphaComponent:0.7];
        }
        self.contentView.layer.borderColor = borderColor.CGColor;
        self.contentView.layer.borderWidth = PT_cellBorderRadius;
        
        if (alpha == 0.0) {
            // Diagonal red line.
            self.noColorLayer.path = self.noColorPath.CGPath;
            
            [self.contentView.layer addSublayer:self.noColorLayer];
            
            // Clip sublayer corners.
            self.contentView.layer.masksToBounds = YES;
        }
    }
    
    // Adjust checkmark tint color for improved constrast.
    CGFloat white, tintWhite;
    if ([color getWhite:&white alpha:nil] && white < 0.5 && alpha > 0.0) {
        tintWhite = 1.0;
    } else {
        tintWhite = 0.0;
    }
    self.checkmarkView.tintColor = [UIColor colorWithWhite:tintWhite alpha:0.54];
    if (@available(iOS 13.0, *)) {
        // Transparent color cell needs to have contrasting checkmark in iOS 13 dark mode
        if (alpha == 0.0f) {
            self.checkmarkView.tintColor = [[UIColor colorNamed:@"UIFGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection] colorWithAlphaComponent:0.54];
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    UIColor *borderColor = [UIColor lightGrayColor];
    if (@available(iOS 13.0, *)) {
        borderColor = [[UIColor colorNamed:@"UIFGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection] colorWithAlphaComponent:0.7];
    }
    self.contentView.layer.borderColor = borderColor.CGColor;
}

#pragma mark - Property accessors

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    self.checkmarkView.hidden = !selected;
}

- (CAShapeLayer *)noColorLayer
{
    if (!_noColorLayer) {
        _noColorLayer = [CAShapeLayer layer];
        
        self.noColorLayer.strokeColor = [UIColor redColor].CGColor;
        self.noColorLayer.lineWidth = PT_noColorLineWidth;
    }
    return _noColorLayer;
}

- (UIBezierPath *)noColorPath
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGSize size = self.contentView.frame.size;
    
    [path moveToPoint:CGPointMake(size.width, 0.0)]; // Top right.
    [path addLineToPoint:CGPointMake(0.0, size.height)]; // Bottom left.
    
    return path;
}

@end
