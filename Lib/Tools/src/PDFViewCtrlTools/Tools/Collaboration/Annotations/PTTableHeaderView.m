//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTableHeaderView.h"

#import "PTToolsUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTTableHeaderView ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTTableHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _stackView = [[UIStackView alloc] init];
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.distribution = UIStackViewDistributionEqualSpacing;
        _stackView.spacing = 10.0;
        
        _stackView.layoutMargins = UIEdgeInsetsMake(_stackView.spacing, _stackView.spacing,
                                                    _stackView.spacing, _stackView.spacing);
        _stackView.preservesSuperviewLayoutMargins = YES;
        _stackView.layoutMarginsRelativeArrangement = YES;

        [self addSubview:_stackView];
        
        _sortButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _sortButton.translatesAutoresizingMaskIntoConstraints = NO;
                
        UIImage *image = [PTToolsUtil toolImageNamed:@"ic_arrow_drop_down_black_24dp"];
        [_sortButton setImage:image forState:UIControlStateNormal];
        
        _sortButton.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        
        [_sortButton addTarget:self
                        action:@selector(changeSortMode:)
              forControlEvents:UIControlEventPrimaryActionTriggered];
        
        [_stackView addArrangedSubview:_sortButton];
        
        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
       [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
       [self.stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
       [self.stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
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

#pragma mark - Button actions

- (void)changeSortMode:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(tableHeaderViewShowSort:)]) {
        [self.delegate tableHeaderViewShowSort:self];
    }
}

@end
