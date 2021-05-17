//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPopoverNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTPopoverNavigationController ()

@end

NS_ASSUME_NONNULL_END

@implementation PTPopoverNavigationController

- (void)PTPopoverNavigationController_commonInit
{
    // Use half-modal presentation as default.
    _presentationManager = [[PTHalfModalPresentationManager alloc] init];
    
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = _presentationManager;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        [self PTPopoverNavigationController_commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (self) {
        [self PTPopoverNavigationController_commonInit];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTPopoverNavigationController_commonInit];
    }
    return self;
}

- (void)setModalPresentationStyle:(UIModalPresentationStyle)modalPresentationStyle
{
    [super setModalPresentationStyle:modalPresentationStyle];
    
    // Remove presentation manager when modal presentation style is changed.
    if (self.presentationManager == self.transitioningDelegate) {
        self.transitioningDelegate = nil;
        
        self.presentationManager = nil;
    }
}

#pragma mark - UINavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    
    const id<UIViewControllerTransitionCoordinator> coordinator = viewController.transitionCoordinator;
    if (coordinator) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // Update the navigation controller's preferredContentSize to match the pushed child
            // view controller's.
            // This is necessary when the child view controller has been pushed onto the navigation
            // stack previously and its preferredContentSize has not changed since then.
            [self updatePreferredContentSizeFromViewController:viewController];
        } completion:nil];
    } else {
        // Update the navigation controller's preferredContentSize to match the pushed child
        // view controller's.
        // This is necessary when the child view controller has been pushed onto the navigation
        // stack previously and its preferredContentSize has not changed since then.
        [self updatePreferredContentSizeFromViewController:viewController];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController * const poppedViewController = [super popViewControllerAnimated:animated];

    if (poppedViewController) {
        UIViewController * const topViewController = self.topViewController;
        
        const id<UIViewControllerTransitionCoordinator> coordinator = poppedViewController.transitionCoordinator;
        if (coordinator) {
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                // Update the navigation controller's preferredContentSize to match the top view controller's.
                // This is necessary when the top view controller's preferredContentSize does not
                // specify both dimensions (ie. 0 width or height) but the popped view controller's does.
                [self updatePreferredContentSizeFromViewController:topViewController];
            } completion:nil];
        } else {
            // Update the navigation controller's preferredContentSize to match the top view controller's.
            // This is necessary when the top view controller's preferredContentSize does not
            // specify both dimensions (ie. 0 width or height) but the popped view controller's does.
            [self updatePreferredContentSizeFromViewController:topViewController];
        }
    }
    
    return poppedViewController;
}

#pragma mark - <UIContentContainer>

- (void)updatePreferredContentSizeFromViewController:(UIViewController *)viewController
{
    const CGSize preferredContentSize = viewController.preferredContentSize;
    if (!CGSizeEqualToSize(preferredContentSize, CGSizeZero)) {
        // UINavigationController will automatically add the top and/or bottom safe area insets to
        // the passed in preferredContentSize, so they should not be included in the child content
        // container's size.
        // If there is a navigation-bar- and/or toolbar-sized space at the top or bottom of the
        // child view controller, it is possible that the safe area insets are being accounted for
        // more than once.
        self.preferredContentSize = preferredContentSize;
    }
}

// NOTE: Do *not* call super implementation. There is a bug in UINavigationController where its
// root view controller's preferredContentSize is used when a new view controller is being pushed
// onto the navigation stack.
- (void)preferredContentSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container
{
    // Ensure that the child content container is the top view controller, otherwise we are getting
    // a preferredContentSize change from another view controller on the navigation stack.
    if ([container isKindOfClass:[UIViewController class]] &&
        (container == self.topViewController)) {
        UIViewController * const viewController = (UIViewController *)container;
        [self updatePreferredContentSizeFromViewController:viewController];
    }
}

@end
