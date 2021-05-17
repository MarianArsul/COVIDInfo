//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolbarContentView.h"

#import "NSLayoutConstraint+PTPriority.h"
#import "UIBarButtonItem+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTToolbarContentView ()

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTToolbarContentView

- (void)PTToolbarContentView_commonInit
{
    _stackView = ({
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 10;
                
        (stackView);
    });
    
    [self addSubview:_stackView];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTToolbarContentView_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutMarginsGuide = self.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
        [self.stackView.trailingAnchor constraintEqualToAnchor:layoutMarginsGuide.trailingAnchor],
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

#pragma mark - Items

- (void)setItems:(NSArray<UIBarButtonItem *> *)items
{
    _items = [items copy]; // @property (copy) semantics.
    
    [self updateItems];
}

- (void)updateItems
{
    for (UIView *subview in self.stackView.arrangedSubviews) {
        [subview removeFromSuperview];
    }
    
    NSLayoutDimension *flexibleSpaceEqualSize = nil;
    
    for (UIBarButtonItem *item in self.items) {
        UIView *view = item.customView;
        if (view) {
            [self.stackView addArrangedSubview:view];
        } else {
            if ([item pt_isFixedSpaceItem]) {
                view = [[UIView alloc] init];
                view.translatesAutoresizingMaskIntoConstraints = NO;
                
                [self.stackView addArrangedSubview:view];
                
                [NSLayoutConstraint pt_activateConstraints:@[
                    [view.widthAnchor constraintEqualToConstant:item.width],
                ] withPriority:UILayoutPriorityDefaultLow];
            } else if ([item pt_isFlexibleSpaceItem]) {
                view = [[UIView alloc] init];
                view.translatesAutoresizingMaskIntoConstraints = NO;
                
                [self.stackView addArrangedSubview:view];
                
                if (flexibleSpaceEqualSize) {
                    [NSLayoutConstraint pt_activateConstraints:@[
                        [view.widthAnchor constraintEqualToAnchor:flexibleSpaceEqualSize],
                    ] withPriority:650];
                } else {
                    [NSLayoutConstraint pt_activateConstraints:@[
                        [view.widthAnchor constraintEqualToAnchor:self.stackView.widthAnchor],
                    ] withPriority:UILayoutPriorityDefaultLow];
                    
                    flexibleSpaceEqualSize = view.widthAnchor;
                }
            } else {
                NSAssert(view != nil, NSInternalInconsistencyException);
            }
        }
    }
}

@end
