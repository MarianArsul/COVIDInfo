//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPanelViewController.h"

#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

static const CGFloat PTPanelViewController_panelWidth = 320; // pts.

static const NSTimeInterval PTPanelViewController_showHideDuration = 0.25; // seconds.

@interface PTPanelViewController ()
{
    NSUInteger _activeLeadingPanelTransitionCount;
}

@property (nonatomic, strong) UIView *contentContainerView;

@property (nonatomic, strong) UIView *leadingContainerView;
@property (nonatomic, strong) UIView *trailingContainerView;

@property (nonatomic, strong) UIView *leadingShadowView;
@property (nonatomic, strong) UIView *trailingShadowView;

@property (nonatomic, assign) BOOL viewConstraintsLoaded;

@property (nonatomic, strong, nullable) NSLayoutConstraint *leadingPanelConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *leadingPanelBottomConstraint;

@property (nonatomic, strong, nullable) NSLayoutConstraint *trailingPanelWidthConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *trailingPanelConstraint;

@end

NS_ASSUME_NONNULL_END

@implementation PTPanelViewController

- (instancetype)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self) {
        _leadingPanelHidden = YES;
        _trailingPanelHidden = YES;
        
        _panelEnabled = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Content container view.
    self.contentContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.contentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentContainerView.accessibilityIdentifier = PT_SELF_KEY(contentContainerView);
    
    [self.view addSubview:self.contentContainerView];
    
    // Leading container view.
    self.leadingContainerView = [[UIView alloc] init];
    self.leadingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.leadingContainerView.accessibilityIdentifier = PT_SELF_KEY(leadingContainerView);
    
    [self.view addSubview:self.leadingContainerView];
    
//    self.leadingContainerView.hidden = YES;
    
    // Leading shadow view.
    self.leadingShadowView = [[UIView alloc] init];
    self.leadingShadowView.translatesAutoresizingMaskIntoConstraints = NO;
    self.leadingShadowView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    self.leadingShadowView.accessibilityIdentifier = PT_SELF_KEY(leadingShadowView);
    
    [self.leadingContainerView addSubview:self.leadingShadowView];
    
    // Trailing container view.
    self.trailingContainerView = [[UIView alloc] init];
    self.trailingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.trailingContainerView.accessibilityIdentifier = PT_SELF_KEY(trailingContainerView);
    
    [self.view addSubview:self.trailingContainerView];
    
    self.trailingContainerView.hidden = YES;
    
    // Trailing shadow view.
    self.trailingShadowView = [[UIView alloc] init];
    self.trailingShadowView.translatesAutoresizingMaskIntoConstraints = NO;
    self.trailingShadowView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    self.trailingShadowView.accessibilityIdentifier = PT_SELF_KEY(trailingShadowView);
    
    // Schedule constraints set up.
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Constraints

- (void)loadViewConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.contentContainerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.contentContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.leadingContainerView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [self.leadingContainerView.trailingAnchor constraintEqualToAnchor:self.contentContainerView.leadingAnchor],
        [self.leadingContainerView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor],
        
        [self.trailingContainerView.leadingAnchor constraintEqualToAnchor:self.contentContainerView.trailingAnchor],
        [self.trailingContainerView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
        [self.trailingContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.trailingContainerView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor],
        
        [self.leadingShadowView.leadingAnchor constraintEqualToAnchor:self.leadingContainerView.trailingAnchor],
        [self.leadingShadowView.topAnchor constraintEqualToAnchor:self.leadingContainerView.topAnchor],
        [self.leadingShadowView.widthAnchor constraintEqualToConstant:(1 / UIScreen.mainScreen.nativeScale)],
        [self.leadingShadowView.bottomAnchor constraintEqualToAnchor:self.leadingContainerView.bottomAnchor],
    ]];
    
    // Content view width tries to match total width.
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.contentContainerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
    ] withPriority:UILayoutPriorityDefaultHigh];
    
    // Panel width constraint needs to be able to be broken (eg. window resized too small).
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.leadingContainerView.widthAnchor constraintEqualToConstant:PTPanelViewController_panelWidth],
    ] withPriority: /* Not *quite* required. */ (UILayoutPriorityRequired - 1)];
}

- (void)updateLeadingConstraint
{
    if (self.leadingPanelConstraint) {
        self.leadingPanelConstraint.active = NO;
    }
    
    if ([self isLeadingPanelHidden]) {
        self.leadingPanelConstraint = [self.leadingContainerView.trailingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
    } else {
        self.leadingPanelConstraint = [self.leadingContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
    }
    
    self.leadingPanelConstraint.identifier = @"leading-panel-constraint";
    
    self.leadingPanelConstraint.active = YES;
}

- (void)updateViewConstraints
{
    if (!self.viewConstraintsLoaded) {
        [self loadViewConstraints];
        
        self.viewConstraintsLoaded = YES;
    }

    [self updateLeadingConstraint];
    
    if (self.leadingPanelBottomConstraint) {
        self.leadingPanelBottomConstraint.active = NO;
    }
    self.leadingPanelBottomConstraint =
    [self.leadingContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-(self.additionalPanelSafeAreaInsets.bottom)];

    self.leadingPanelBottomConstraint.active = YES;
        
    self.trailingPanelWidthConstraint.active = ![self isTrailingPanelHidden];
        
    // Call super implementation as final step.
    [super updateViewConstraints];
}

#pragma mark - Layout

- (void)setAdditionalPanelSafeAreaInsets:(UIEdgeInsets)insets
{
    _additionalPanelSafeAreaInsets = insets;
    
    if (@available(iOS 11.0, *)) {
        [self.view setNeedsUpdateConstraints];
    }
}

#pragma mark - Content view controller

- (void)setContentViewController:(UIViewController *)contentViewController
{
    if (_contentViewController) {
        [self detachViewController:_contentViewController];
    }
    
    _contentViewController = contentViewController;
    
    if (contentViewController) {
        [self attachViewController:contentViewController toContainerView:self.contentContainerView];
    }
}

#pragma mark - Leading view controller

- (void)showLeadingViewController:(UIViewController *)viewController
{
    [self showLeadingViewController:viewController animated:NO];
}

- (void)showLeadingViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.leadingViewController) {
        [self detachViewController:self.leadingViewController];
    }

    self.leadingViewController = viewController;
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad &&
        self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
        [self isPanelEnabled]) {
        [self attachViewController:viewController toContainerView:self.leadingContainerView];
        
        [self setLeadingPanelHidden:NO animated:animated];
    } else {
        [self presentViewController:viewController animated:animated completion:nil];
    }
}

- (void)dismissLeadingViewController
{
    [self dismissLeadingViewControllerAnimated:NO];
    
    if (self.leadingViewController) {
        [self detachViewController:self.leadingViewController];
    }
}

- (void)dismissLeadingViewControllerAnimated:(BOOL)animated
{
    if (!self.leadingViewController) {
        // No view controller to dismiss.
        return;
    }
    
    if (self.leadingViewController.parentViewController == self) {
        // View controller is docked.
        [self setLeadingPanelHidden:YES animated:animated];
    } else {
        if (self.leadingViewController.presentingViewController) {
            [self.leadingViewController dismissViewControllerAnimated:animated completion:nil];
        }
    }
}

#pragma mark - Trailing view controller

- (void)showTrailingViewController:(UIViewController *)viewController
{
    [self showTrailingViewController:viewController animated:NO];
}

- (void)showTrailingViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.trailingViewController = viewController;
}

- (void)setTrailingViewController:(UIViewController *)trailingViewController
{
    if (_trailingViewController) {
        [self detachViewController:_trailingViewController];
    }
    
    _trailingViewController = trailingViewController;
    
    if (trailingViewController) {
        [self attachViewController:trailingViewController toContainerView:self.trailingContainerView];
    }
    
    self.trailingPanelHidden = (trailingViewController == nil);
}

#pragma mark - View controller "attachment"

- (void)attachViewController:(UIViewController *)viewController toContainerView:(UIView *)containerView
{
    [self addChildViewController:viewController];
    
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [containerView addSubview:viewController.view];
    
    [NSLayoutConstraint activateConstraints:@[
        [viewController.view.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [viewController.view.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [viewController.view.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [viewController.view.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
    ]];
    
    [viewController didMoveToParentViewController:self];
}

- (void)detachViewController:(UIViewController *)viewController
{
    if (viewController.parentViewController != self) {
        return;
    }
    
    [viewController willMoveToParentViewController:nil];
    
    [viewController.view removeFromSuperview];
    
    // Re-enable the view's autoresizingMask
    viewController.view.translatesAutoresizingMaskIntoConstraints = YES;
    
    [viewController removeFromParentViewController];
}

#pragma mark Hidden

- (void)setLeadingPanelHidden:(BOOL)hidden
{
    [self setLeadingPanelHidden:hidden animated:NO];
}

- (void)setLeadingPanelHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_leadingPanelHidden == hidden) {
        // No change.
        return;
    }
    
    if (animated) {
        [self.view.superview layoutIfNeeded];

        if (_activeLeadingPanelTransitionCount == 0) {
            if ([self.contentViewController conformsToProtocol:@protocol(PTPanelContentContainer)]) {
                [((id<PTPanelContentContainer>)self.contentViewController) panelWillTransition];
            }
        }
    }
    
    if (self.leadingViewController) {
        
//        if (hidden) {
//            [self.leadingViewController.view removeFromSuperview];
//        } else {
            [self.leadingContainerView addSubview:self.leadingViewController.view];
//        }
    }
    
    _leadingPanelHidden = hidden;
    
    [self.view setNeedsUpdateConstraints];
    
    if (animated) {
        [UIView animateWithDuration:PTPanelViewController_showHideDuration animations:^{
            [self.view.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
            self->_activeLeadingPanelTransitionCount--;
            
            if (self->_activeLeadingPanelTransitionCount == 0) {
                if ([self.contentViewController conformsToProtocol:@protocol(PTPanelContentContainer)]) {
                    [((id<PTPanelContentContainer>)self.contentViewController) panelDidTransition];
                }
                
                // Notify delegate.
                if (!hidden) {
                    if ([self.delegate respondsToSelector:@selector(panelViewController:didShowLeadingViewController:)]) {
                        [self.delegate panelViewController:self didShowLeadingViewController:self.leadingViewController];
                    }
                } else {
                    if ([self.delegate respondsToSelector:@selector(panelViewController:didDismissLeadingViewController:)]) {
                        [self.delegate panelViewController:self didDismissLeadingViewController:self.leadingViewController];
                    }
                    
                    [self detachViewController:self.leadingViewController];
                }
            }
        }];
        
        _activeLeadingPanelTransitionCount++;
    } else {
        // Notify delegate.
        if (!hidden) {
            if ([self.delegate respondsToSelector:@selector(panelViewController:didShowLeadingViewController:)]) {
                [self.delegate panelViewController:self didShowLeadingViewController:self.leadingViewController];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(panelViewController:didDismissLeadingViewController:)]) {
                [self.delegate panelViewController:self didDismissLeadingViewController:self.leadingViewController];
            }
            
            [self detachViewController:self.leadingViewController];
        }
    }
}

- (void)setTrailingPanelHidden:(BOOL)hidden
{
    if (_trailingPanelHidden == hidden) {
        // No change.
        return;
    }
    
    _trailingPanelHidden = hidden;
    
    if (self.trailingViewController) {
        if (hidden) {
            [self.trailingViewController.view removeFromSuperview];
        } else {
            [self.trailingContainerView addSubview:self.trailingViewController.view];
        }
    }
    
    self.trailingContainerView.hidden = hidden;
    
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Adaptivity

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    // Don't adapt when:
    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad || // non-iPad (no panel)
        newCollection.horizontalSizeClass == self.traitCollection.horizontalSizeClass || // no change
        ![self isPanelEnabled]) { // panel disabled
        return;
    }
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([context isCancelled]) {
            return;
        }
                
        if (!self.leadingViewController) {
            return;
        }
        
        [self adaptLeadingViewControllerForTraitCollection:self.traitCollection];
    }];
}

- (void)adaptLeadingViewControllerForTraitCollection:(UITraitCollection *)traitCollection
{
    // Dismiss the leading view controller when the trait collection changes.
    [self dismissLeadingViewController];
}

@end
