//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleSliderTableViewCell.h"

@interface PTAnnotStyleSliderTableViewCell ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic) BOOL constraintsLoaded;

@end

@implementation PTAnnotStyleSliderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Set up stack view container.
        _stackView = [[UIStackView alloc] init];
        _stackView.translatesAutoresizingMaskIntoConstraints = NO; // Must be done *before* adding to content view.
        
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.distribution = UIStackViewDistributionFill;
        _stackView.spacing = 10.0;
        
        _stackView.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8);
        _stackView.preservesSuperviewLayoutMargins = YES;
        _stackView.layoutMarginsRelativeArrangement = YES;
        
        [self.contentView addSubview:_stackView];
        
        // Label.
        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        
        _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _label.textAlignment = NSTextAlignmentNatural;
        _label.numberOfLines = 0;
        
        [_stackView addArrangedSubview:_label];
        
        // Slider.
        _slider = [[UISlider alloc] init];
        _slider.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_stackView addArrangedSubview:_slider];
        
        // Indicator.
        _indicator = [[UILabel alloc] init];
        _indicator.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Trailing text alignment.
        if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft) {
            _indicator.textAlignment = NSTextAlignmentLeft;
        } else {
            _indicator.textAlignment = NSTextAlignmentRight;
        }
        
        [_stackView addArrangedSubview:_indicator];
        
        // Respond to slider events.
        [_slider addTarget:self action:@selector(sliderTouchDown) forControlEvents:UIControlEventTouchDown];
        [_slider addTarget:self action:@selector(sliderValueChanged) forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self action:@selector(sliderTouchUp) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
        
        // Cell is not selectable.
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.stackView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
        [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.stackView.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor],
        
        [self.label.widthAnchor constraintEqualToConstant:100.0],
        
        [self.indicator.widthAnchor constraintEqualToConstant:60.0],
    ]];
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

#pragma mark - Configuration

- (void)configureWithItem:(PTAnnotStyleSliderTableViewItem *)item
{
    self.label.text = item.title;
    self.slider.minimumValue = item.minimumValue;
    self.slider.maximumValue = item.maximumValue;
    self.slider.value = item.value;
    
    self.indicator.text = item.indicatorText;
}

#pragma mark - UISlider action methods

- (void)sliderTouchDown
{
    if ([self.delegate respondsToSelector:@selector(styleSliderTableViewCellSliderBeganSliding:)]) {
        [self.delegate styleSliderTableViewCellSliderBeganSliding:self];
    }
}

- (void)sliderValueChanged
{
    if ([self.delegate respondsToSelector:@selector(styleSliderTableViewCell:sliderValueDidChange:)]) {
        [self.delegate styleSliderTableViewCell:self sliderValueDidChange:self.slider.value];
    }
}

- (void)sliderTouchUp
{
    if ([self.delegate respondsToSelector:@selector(styleSliderTableViewCellSliderEndedSliding:)]) {
        [self.delegate styleSliderTableViewCellSliderEndedSliding:self];
    }
}

@end
