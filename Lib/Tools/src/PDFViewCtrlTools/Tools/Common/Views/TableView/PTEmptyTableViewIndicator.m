//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTEmptyTableViewIndicator.h"

#import "NSLayoutConstraint+PTPriority.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTEmptyTableViewIndicator ()
{
    BOOL _constraintsLoaded;
    BOOL _needsUpdateAlignmentConstraints;
}

@property (nonatomic, strong) UIStackView *stackView;

@end

NS_ASSUME_NONNULL_END

@implementation PTEmptyTableViewIndicator

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _alignment = (PTEmptyTableViewAlignmentCenteredVertically |
                      PTEmptyTableViewAlignmentCenteredHorizontally);
        
        // Stack view.
        UIStackView * const stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 10;
        
        stackView.layoutMarginsRelativeArrangement = YES;
        stackView.layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
        stackView.preservesSuperviewLayoutMargins = YES;
        
        _stackView = stackView;
        
        // Label.
        UILabel * const label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        
        _label = label;
        
        // Image view.
        UIImageView * const imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _imageView = imageView;
        
        // View hierarchy.
        [self addSubview:stackView];
        [stackView addArrangedSubview:label];
        [stackView addArrangedSubview:imageView];
        
        _needsUpdateAlignmentConstraints = YES;
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    // Constrain stack view within bounds of view.
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor],
        [self.stackView.leftAnchor constraintGreaterThanOrEqualToAnchor:self.leftAnchor],
        [self.stackView.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor],
        [self.stackView.rightAnchor constraintLessThanOrEqualToAnchor:self.rightAnchor],
    ]];
    
    // Make stack view as small as possible.
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.stackView.widthAnchor constraintEqualToConstant:0],
        [self.stackView.heightAnchor constraintEqualToConstant:0],
    ] withPriority:UILayoutPriorityFittingSizeLevel];
}

- (void)updateAlignmentConstraints
{
    const PTEmptyTableViewAlignment alignment = self.alignment;
    
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];
    
    // Vertical alignment.
    if (PT_BITMASK_CHECK(alignment, PTEmptyTableViewAlignmentTop)) {
        [constraints addObjectsFromArray:@[
            [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        ]];
    } else if (PT_BITMASK_CHECK(alignment, PTEmptyTableViewAlignmentBottom)) {
        [constraints addObjectsFromArray:@[
            [self.stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
    } else { // PTEmptyTableViewAlignmentCenteredVertically
        [constraints addObjectsFromArray:@[
            [self.stackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    
    // Horizontal alignment.
    if (PT_BITMASK_CHECK(alignment, PTEmptyTableViewAlignmentLeft)) {
        [constraints addObjectsFromArray:@[
            [self.stackView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        ]];
    } else if (PT_BITMASK_CHECK(alignment, PTEmptyTableViewAlignmentRight)) {
        [constraints addObjectsFromArray:@[
            [self.stackView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        ]];
    } else if (PT_BITMASK_CHECK(alignment, PTEmptyTableViewAlignmentLeading)) {
        [constraints addObjectsFromArray:@[
            [self.stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        ]];
    } else if (PT_BITMASK_CHECK(alignment, PTEmptyTableViewAlignmentTrailing)) {
        [constraints addObjectsFromArray:@[
            [self.stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];
    } else { // PTEmptyTableViewAlignmentCenteredHorizontally
        [constraints addObjectsFromArray:@[
            [self.stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        ]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateConstraints
{
    if (!_constraintsLoaded) {
        _constraintsLoaded = YES;
        [self loadConstraints];
    }
    if (_needsUpdateAlignmentConstraints) {
        _needsUpdateAlignmentConstraints = NO;
        [self updateAlignmentConstraints];
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Alignment

- (void)setAlignment:(PTEmptyTableViewAlignment)alignment
{
    _alignment = alignment;
    
    _needsUpdateAlignmentConstraints = YES;
    [self setNeedsUpdateConstraints];
}

@end
