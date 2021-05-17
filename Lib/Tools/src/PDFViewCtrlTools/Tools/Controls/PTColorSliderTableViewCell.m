//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTColorSliderTableViewCell.h"
#import "UIColor+PTHexString.h"

@interface PTColorSliderTableViewCell ()
@property (nonatomic, strong) UIView *hueBGView;
@property (nonatomic, strong) UIView *lightnessBGView;
@property (nonatomic, strong) UIImageView *hueGradientView;
@property (nonatomic, strong) UIImageView *lightnessGradientView;
@property (nonatomic, strong) NSArray *lightnessGradient;
@property (nonatomic, strong) UIColor *hueColor;
@property (nonatomic) CGFloat hue;
@property (nonatomic) CGFloat lightness;
@property (nonatomic) CGFloat saturation;
@property (nonatomic) CGFloat brightness;
@property (nonatomic) CGFloat alpha;
@end


@implementation PTColorSliderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withColor:(nonnull UIColor *)color
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    _color = color;
    
    NSMutableArray *hues = [[NSMutableArray alloc] init];
    for (int i = 0; i<360; i++) {
        UIColor *iColor = [UIColor colorWithHue:(CGFloat)i/360.0 saturation:1 brightness:1 alpha:1];
        [hues addObject:(id)iColor.CGColor];
    }
    NSArray *hueColors = [[NSArray alloc] initWithArray:hues];
    
    [_color getHue:&_hue saturation:&_saturation brightness:&_brightness alpha:&_alpha];
    // conversion from: https://gist.github.com/kaishin/8934076
    _lightness = (2 - _saturation) * _brightness / 2;
    
    _hueColor = [UIColor colorWithHue:_hue saturation:1.0f brightness:1.0f alpha:1.0f];
    _lightnessGradient = @[(id)[UIColor blackColor].CGColor, (id)_hueColor.CGColor, (id)[UIColor whiteColor].CGColor];
    
    _hueBGView = [[UIView alloc] init];
    _hueBGView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _lightnessBGView = [[UIView alloc] init];
    _lightnessBGView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _hueGradientView = [[UIImageView alloc] initWithImage:[ [self gradientImageWithBounds:self.bounds colors:hueColors] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch]];
    _hueGradientView.translatesAutoresizingMaskIntoConstraints = NO;

    _lightnessGradientView = [[UIImageView alloc] initWithImage:[ [self gradientImageWithBounds:self.bounds colors:_lightnessGradient] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch]];
    _lightnessGradientView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _hueGradientView.layer.masksToBounds = YES;
    _hueGradientView.userInteractionEnabled = YES;
    _hueGradientView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _hueGradientView.layer.borderWidth = 1;

    _lightnessGradientView.layer.masksToBounds = YES;
    _lightnessGradientView.userInteractionEnabled = YES;
    _lightnessGradientView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _lightnessGradientView.layer.borderWidth = 1;

    [self.contentView addSubview:_hueBGView];
    [self.contentView addSubview:_lightnessBGView];

    [NSLayoutConstraint activateConstraints:
     @[[_hueBGView.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor multiplier:0.5],
       [_hueBGView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
       [_hueBGView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
       [_hueBGView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor]
       ]];
    [NSLayoutConstraint activateConstraints:
     @[[_lightnessBGView.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor multiplier:0.5],
       [_lightnessBGView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
       [_lightnessBGView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
       [_lightnessBGView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor]
       ]];

    [_hueBGView addSubview:_hueGradientView];
    [_lightnessBGView addSubview:_lightnessGradientView];

    [NSLayoutConstraint activateConstraints:
     @[[_hueGradientView.heightAnchor constraintEqualToAnchor:_hueGradientView.superview.heightAnchor multiplier:0.3f],
       [_hueGradientView.centerYAnchor constraintEqualToAnchor:_hueGradientView.superview.centerYAnchor],
       [_hueGradientView.centerXAnchor constraintEqualToAnchor:_hueGradientView.superview.centerXAnchor],
       [_hueGradientView.widthAnchor constraintEqualToAnchor:_hueGradientView.superview.widthAnchor multiplier:0.8f]
       ]];
    [NSLayoutConstraint activateConstraints:
     @[[_lightnessGradientView.heightAnchor constraintEqualToAnchor:_lightnessGradientView.superview.heightAnchor multiplier:0.3f],
       [_lightnessGradientView.centerYAnchor constraintEqualToAnchor:_lightnessGradientView.superview.centerYAnchor],
       [_lightnessGradientView.centerXAnchor constraintEqualToAnchor:_lightnessGradientView.superview.centerXAnchor],
       [_lightnessGradientView.widthAnchor constraintEqualToAnchor:_lightnessGradientView.superview.widthAnchor multiplier:0.8f]
       ]];
    
    _hueSlider = [[UISlider alloc] init];
    [_hueSlider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_hueSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_hueSlider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    _hueSlider.minimumTrackTintColor = [UIColor clearColor];
    _hueSlider.maximumTrackTintColor = [UIColor clearColor];
    _hueSlider.translatesAutoresizingMaskIntoConstraints = NO;
    _hueSlider.value = _hue;
    _hueSlider.thumbTintColor = _hueColor;
    [_hueBGView addSubview:_hueSlider];
    
    [NSLayoutConstraint activateConstraints:
     @[[_hueSlider.centerYAnchor constraintEqualToAnchor:_hueGradientView.centerYAnchor],
       [_hueSlider.centerXAnchor constraintEqualToAnchor:_hueGradientView.centerXAnchor],
       [_hueSlider.widthAnchor constraintEqualToAnchor:_hueGradientView.widthAnchor]
       ]];
    
    _lightnessSlider = [[UISlider alloc] init];
    [_lightnessSlider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_lightnessSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_lightnessSlider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    _lightnessSlider.minimumTrackTintColor = [UIColor clearColor];
    _lightnessSlider.maximumTrackTintColor = [UIColor clearColor];
    _lightnessSlider.translatesAutoresizingMaskIntoConstraints = NO;
    _lightnessSlider.value = _lightness;
    [_lightnessBGView addSubview:_lightnessSlider];
    
    [NSLayoutConstraint activateConstraints:
     @[[_lightnessSlider.centerYAnchor constraintEqualToAnchor:_lightnessGradientView.centerYAnchor],
       [_lightnessSlider.centerXAnchor constraintEqualToAnchor:_lightnessGradientView.centerXAnchor],
       [_lightnessSlider.widthAnchor constraintEqualToAnchor:_lightnessGradientView.widthAnchor]
       ]];
    self.hidden = YES;
    
    return self;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [self initWithStyle:style reuseIdentifier:reuseIdentifier withColor:[UIColor pt_colorWithHexString:@"#AA0000"]];
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    _hueSlider.hidden = hidden;
    _lightnessSlider.hidden = hidden;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    // Update gradient view corner radius
    _hueGradientView.layer.cornerRadius = _hueGradientView.bounds.size.height*0.5f;
    _lightnessGradientView.layer.cornerRadius = _lightnessGradientView.bounds.size.height*0.5f;
}

- (UIImage *)gradientImageWithBounds:(CGRect)bounds colors:(NSArray *)colors
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = bounds;
    gradientLayer.colors = colors;
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)drawGradients{
    self.lightnessGradientView.image = [[self gradientImageWithBounds:self.bounds colors:self.lightnessGradient] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
}

#pragma mark - UISlider action methods

- (void)sliderTouchDown:(UISlider*)slider
{
}

- (void)sliderValueChanged:(UISlider*)slider
{
    if (slider == self.hueSlider) {
        self.hue = slider.value;
        [self setHueColor:[UIColor colorWithHue:slider.value saturation:1.0f brightness:1.0f alpha:1.0f]];
        slider.thumbTintColor = self.hueColor;
    } else if (slider == self.lightnessSlider) {
        self.lightness = slider.value;
        [self setSaturation:1.0f-2*MAX(0.0f, slider.value-0.5f)];
        [self setBrightness:MIN(1.0f, 2.0f*slider.value)];
    }
    [self setLightnessGradient:@[(id)[UIColor blackColor].CGColor, (id)self.hueColor.CGColor, (id)[UIColor whiteColor].CGColor]];
    [self drawGradients];
    [self setColor:[UIColor colorWithHue:self.hue saturation:self.saturation brightness:self.brightness alpha:self.alpha]];
    
    if ([self.delegate respondsToSelector:@selector(colorSliderTableViewCell:colorChanged:)]) {
        [self.delegate colorSliderTableViewCell:self colorChanged:self.color];
    }
}

- (void)sliderTouchUp:(UISlider*)slider
{
}

@end
