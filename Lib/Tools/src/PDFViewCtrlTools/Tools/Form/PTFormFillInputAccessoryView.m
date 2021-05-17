//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFormFillInputAccessoryView.h"

#import "PTToolsUtil.h"

#import "UIBarButtonItem+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"

@implementation PTFormFillInputAccessoryView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        _toolbar = toolbar;
        toolbar.delegate = self;
        
        toolbar.items =
        @[
          // Previous button.
          [[UIBarButtonItem alloc] initWithImage:[PTToolsUtil toolImageNamed:@"search_prev.png"] style:UIBarButtonItemStylePlain target:self action:@selector(previous:)],
          
          [UIBarButtonItem pt_fixedSpaceItemWithWidth:16],
          
          // Next button.
          [[UIBarButtonItem alloc] initWithImage:[PTToolsUtil toolImageNamed:@"search_next.png"] style:UIBarButtonItemStylePlain target:self action:@selector(next:)],
          
          [UIBarButtonItem pt_flexibleSpaceItem],
          
          // Done button.
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)],
          ];
        
        [self addSubview:toolbar];
        
        // Necessary to force the UIView inputAccessoryView handling to actually consider the vertical
        // Auto Layout constraints instead of using a constant height for this view (via a
        // "_UIKBAutolayoutHeightConstraint" constraint, with height == 0).
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [toolbar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
           [toolbar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
           [toolbar.topAnchor constraintEqualToAnchor:self.topAnchor],
           // The toolbar is above the view's bottom layout margin (handles safe area inset adjustments
           // when the virtual keyboard is not actually shown).
           [toolbar.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
           // Ensure view is tall enough to contain the toolbar.
           [self.heightAnchor constraintGreaterThanOrEqualToAnchor:toolbar.heightAnchor],
           ]];
        
        [NSLayoutConstraint pt_activateConstraints:
         @[
           // (Weakly) constrain the view to match its toolbar's height (required for a fully
           // unambiguous layout).
           [self.heightAnchor constraintEqualToAnchor:toolbar.heightAnchor],
           ] withPriority:UILayoutPriorityDefaultLow /* "weak" constraint(s). */];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    // Necessary to force the inputAccessoryView to be properly sized according to its internal
    // Auto Layout constraints. Actual value is not important.
    // https://stackoverflow.com/a/46510833/8828439
    return CGSizeZero;
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Toolbar button actions

- (void)previous:(UIBarButtonItem *)item
{
    if ([self.delegate respondsToSelector:@selector(formFillInputAccessoryView:didPressPreviousButtonItem:)]) {
        [self.delegate formFillInputAccessoryView:self didPressPreviousButtonItem:item];
    }
}

- (void)next:(UIBarButtonItem *)item
{
    if ([self.delegate respondsToSelector:@selector(formFillInputAccessoryView:didPressNextButtonItem:)]) {
        [self.delegate formFillInputAccessoryView:self didPressNextButtonItem:item];
    }
}

- (void)done:(UIBarButtonItem *)item
{
    if ([self.delegate respondsToSelector:@selector(formFillInputAccessoryView:didPressDoneButtonItem:)]) {
        [self.delegate formFillInputAccessoryView:self didPressDoneButtonItem:item];
    }
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionBottom;
}

@end
