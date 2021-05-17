//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleSwitchTableViewCell.h"

@interface PTAnnotStyleSwitchTableViewCell ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic) BOOL didSetupConstraints;

@end

@implementation PTAnnotStyleSwitchTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentFill;
        _stackView.distribution = UIStackViewDistributionFillProportionally;
        _stackView.spacing = 10.0;

        _stackView.preservesSuperviewLayoutMargins = YES;
        _stackView.layoutMarginsRelativeArrangement = YES;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_stackView];

        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentNatural;
        [_stackView addArrangedSubview:_label];

        _snapSwitch = [[UISwitch alloc] init];
        [_snapSwitch addTarget:self action:@selector(snappingToggled:) forControlEvents:UIControlEventValueChanged];
        [_stackView addArrangedSubview:_snapSwitch];

        // Cell is not selectable.
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        // Schedule constraints update.
        [self setNeedsUpdateConstraints];

    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        // Perform setup of constraints.
        self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.snapSwitch.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:
         @[
           [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
           [self.stackView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
           [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
           [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
           [self.label.widthAnchor constraintEqualToConstant:100.0]
           ]];

        // Constraints are set up.
        self.didSetupConstraints = YES;
    }

    [super updateConstraints];
}

- (void)configureWithItem:(PTAnnotStyleSwitchTableViewItem *)item
{
    self.label.text = item.title;
    [self.snapSwitch setOn:item.snappingEnabled];
}

#pragma mark - Report Changes

- (void)snappingToggled:(UISwitch*)sender
{
    if ([self.delegate respondsToSelector:@selector(styleSwitchTableViewCell:snappingToggled:)]) {
        [self.delegate styleSwitchTableViewCell:self snappingToggled:self.snapSwitch.isOn];
    }
}

@end
