//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolGroupDefaultsTableViewCell.h"

#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTToolGroupDefaultsTableViewCell ()
{
    BOOL _needsSeparatorUpdate;
}

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTToolGroupDefaultsTableViewCell

- (void)PTToolbarUserDefaultTableViewCell_commonInit
{
    self.showsReorderControl = YES;
    
    // Stack view.
    _stackView = [[UIStackView alloc] init];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _stackView.axis = UILayoutConstraintAxisHorizontal;
    _stackView.alignment = UIStackViewAlignmentCenter;
    _stackView.distribution = UIStackViewDistributionFill;
    _stackView.spacing = 10.0;
    
    _stackView.layoutMargins = UIEdgeInsetsMake(0, 10, 0, 10);
    _stackView.preservesSuperviewLayoutMargins = YES;
    _stackView.layoutMarginsRelativeArrangement = YES;
    
    [self.contentView addSubview:_stackView];
    
    // Image view.
    _itemImageView = [[UIImageView alloc] init];
    _itemImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_itemImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                      forAxis:UILayoutConstraintAxisHorizontal];
    
    [_stackView addArrangedSubview:_itemImageView];
    
    // Label.
    _label = [[UILabel alloc] init];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    
    _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _label.numberOfLines = 0;
    
    // Allow the label to stretch beyond its intrinsic content size...
    [_label setContentHuggingPriority:UILayoutPriorityDefaultLow
                              forAxis:UILayoutConstraintAxisHorizontal];
    // and to weakly resist being compressed from its intrinsic content size.
    [_label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                            forAxis:UILayoutConstraintAxisHorizontal];
    
    [_stackView addArrangedSubview:_label];
    
    // Switch view.
    _switchView = [[UISwitch alloc] init];
    _switchView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_stackView addArrangedSubview:_switchView];
    
    // Separator view.
    _separatorView = [[UIView alloc] init];
    _separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (@available(iOS 13.0, *)) {
        _separatorView.backgroundColor = UIColor.separatorColor;
    } else {
        _separatorView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    }
    
    _separatorHidden = NO;
    if (!_separatorHidden) {
        [self.contentView addSubview:_separatorView];
        _needsSeparatorUpdate = YES;
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self PTToolbarUserDefaultTableViewCell_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.stackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.stackView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
    ] withPriority:UILayoutPriorityDefaultHigh];
}

- (void)loadSeparatorConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.separatorView.leadingAnchor],
        
        [self.separatorView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.separatorView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
        [self.separatorView.widthAnchor constraintEqualToConstant:(1 / UIScreen.mainScreen.nativeScale)],
    ]];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    
    if (_needsSeparatorUpdate) {
        [self loadSeparatorConstraints];
        
        _needsSeparatorUpdate = NO;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Layout

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    CGSize size = [super systemLayoutSizeFittingSize:targetSize
                       withHorizontalFittingPriority:horizontalFittingPriority
                             verticalFittingPriority:verticalFittingPriority];
    size.height = fmax(44.0, size.height);
    return size;
}

#pragma mark - Separator

- (void)setSeparatorHidden:(BOOL)hidden
{
    if (hidden == _separatorHidden) {
        // No change.
        return;
    }
    
    _separatorHidden = hidden;
    
    if (hidden) {
        [self.separatorView removeFromSuperview];
    } else {
        [self.contentView addSubview:self.separatorView];
        [self setNeedsSeparatorUpdate];
    }
}

- (void)setNeedsSeparatorUpdate
{
    _needsSeparatorUpdate = YES;
    [self setNeedsUpdateConstraints];
}

#pragma mark - Configuration

- (void)configureWithItem:(UIBarButtonItem *)item
{
    self.itemImageView.image = item.image;
    self.itemImageView.hidden = (item.image == nil);
    self.label.text = item.title;
}

@end
