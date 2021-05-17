//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTMoreItemsHeaderFooterView.h"

#import "PTToolsUtil.h"
#import "NSLayoutConstraint+PTPriority.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTMoreItemsHeaderFooterView ()

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTMoreItemsHeaderFooterView

- (void)PTMoreItemsHeaderFooterView_commonInit
{
//    self.layoutMargins = UIEdgeInsetsMake(10, 8, 10, 8);
//    self.preservesSuperviewLayoutMargins = YES;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    if (@available(iOS 11.0, *)) {
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
    } else {
        switch (button.effectiveUserInterfaceLayoutDirection) {
            case UIUserInterfaceLayoutDirectionLeftToRight:
                button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                break;
            case UIUserInterfaceLayoutDirectionRightToLeft:
                button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                break;
        }
    }
    
    [self.contentView addSubview:button];
    
    _button = button;
    
    // Schedule constraints load.
    [self setNeedsUpdateConstraints];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self PTMoreItemsHeaderFooterView_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.button.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutMarginsGuide = self.contentView.layoutMarginsGuide;
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.button.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor],
        [self.button.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor],
        [self.button.trailingAnchor constraintEqualToAnchor:layoutMarginsGuide.trailingAnchor],
        [self.button.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
    ] withPriority:(UILayoutPriorityRequired - 1)]; /* Not *quite* required, to allow for CGRectZero size. */
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
