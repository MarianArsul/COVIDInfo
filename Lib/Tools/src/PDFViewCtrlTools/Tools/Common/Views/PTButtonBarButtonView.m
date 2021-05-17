//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTButtonBarButtonView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTButtonBarButtonView ()

@property (nonatomic, strong) CALayer *buttonMaskLayer;

@end

NS_ASSUME_NONNULL_END

@implementation PTButtonBarButtonView

- (instancetype)initWithFrame:(CGRect)frame
{
    UIButton *button = PT_createButton();
    self = [super initWithView:button];
    if (self) {
        _button = button;
        
        // Round button corners and clip to round-bounds.
        // NOTE: The UIButton's imageView draws its background outside the button's bounds, so we
        // need to clip the button's content to control the appearance.
        _buttonMaskLayer = [CALayer layer];
        _buttonMaskLayer.backgroundColor = UIColor.whiteColor.CGColor;
        _buttonMaskLayer.cornerRadius = 4.0;
        _button.layer.mask = _buttonMaskLayer;
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateButtonMaskLayer];
}

- (void)updateButtonMaskLayer
{
    const CGFloat cornerRadius = self.buttonMaskLayer.cornerRadius;
    
    // Mask the button's content around the image view, with an outset equal to the layer's
    // corner radius.
    self.buttonMaskLayer.frame = CGRectInset(self.button.imageView.frame,
                                             -cornerRadius, -cornerRadius);
}

#pragma mark - Button

static UIButton *PT_createButton(void)
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // Increase the button's horizontal content compression resistance priority to counteract
    // the "widthMinimizingConstraint" on the view.
    // (ie. try to keep the view as small as possible, but respect the button's width)
    [button setContentCompressionResistancePriority:(UILayoutPriorityDefaultHigh + 10)
                                            forAxis:UILayoutConstraintAxisHorizontal];
    
    if (@available(iOS 13.0, *)) {
        button.showsLargeContentViewer = YES;
    }
    
    return button;
}

- (UIButton *)button
{
    if (!_button) {
        _button = PT_createButton();
    }
    return _button;
}

@end
