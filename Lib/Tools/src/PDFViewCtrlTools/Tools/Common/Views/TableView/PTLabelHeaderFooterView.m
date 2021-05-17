//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTLabelHeaderFooterView.h"

#import "NSLayoutConstraint+PTPriority.h"
#import "UIFont+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTLabelHeaderFooterView ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTLabelHeaderFooterView

@dynamic textLabel;
@dynamic detailTextLabel;

- (void)PTLabelHeaderFooterView_commonInit
{
    _stackView = ({
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        
        (stackView);
    });
    [self.contentView addSubview:_stackView];
    
    _label = [[UILabel alloc] init];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    
    _label.font = [UIFont pt_boldPreferredFontForTextStyle:UIFontTextStyleBody];
    _label.textAlignment = NSTextAlignmentCenter;
    
    [_stackView addArrangedSubview:_label];
    
    _detailLabel = [[UILabel alloc] init];
    _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
    _detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _detailLabel.textAlignment = NSTextAlignmentCenter;
    
    [_stackView addArrangedSubview:_detailLabel];
    
    // Schedule constraints load.
    [self setNeedsUpdateConstraints];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self PTLabelHeaderFooterView_commonInit];
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
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
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

@end
