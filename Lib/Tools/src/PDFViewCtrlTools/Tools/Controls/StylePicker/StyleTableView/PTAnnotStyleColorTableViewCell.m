//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleColorTableViewCell.h"

#import "PTColorIndicatorView.h"

@interface PTAnnotStyleColorTableViewCell ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, strong) PTColorIndicatorView *colorIndicatorView;

@property (nonatomic) BOOL constraintsLoaded;

@end

@implementation PTAnnotStyleColorTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        
        _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _label.numberOfLines = 0;
        
        [self.contentView addSubview:_label];
        
        _colorIndicatorView = [[PTColorIndicatorView alloc] init];
        _colorIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addSubview:_colorIndicatorView];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    UILayoutGuide *layoutMarginsGuide = self.contentView.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.label.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor],
        [self.label.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor],
        [self.label.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
        [self.label.trailingAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.trailingAnchor],
        
        [self.colorIndicatorView.centerYAnchor constraintEqualToAnchor:layoutMarginsGuide.centerYAnchor],
        [self.colorIndicatorView.leadingAnchor constraintEqualToAnchor:self.label.trailingAnchor],
        [self.colorIndicatorView.trailingAnchor constraintEqualToAnchor:layoutMarginsGuide.trailingAnchor],
        [self.colorIndicatorView.heightAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.heightAnchor],
    ]];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        // Constraints are loaded.
        self.constraintsLoaded = YES;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (void)configureWithItem:(PTAnnotStyleColorTableViewItem *)item
{
    self.label.text = item.title;
        
    self.colorIndicatorView.color = item.color;
}

@end
