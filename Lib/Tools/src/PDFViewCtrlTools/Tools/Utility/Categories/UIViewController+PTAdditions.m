//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIViewController+PTAdditions.h"

#import "PTToolsUtil.h"

@implementation UIViewController (PTAdditions)

- (UIViewController *)pt_outermostViewController
{
    // Find the outermost (parent) view controller of this view controller.
    UIViewController *outermostViewController = self;
    while (outermostViewController.parentViewController) {
        outermostViewController = outermostViewController.parentViewController;
    }
    
    return outermostViewController;
}

- (UIViewController *)pt_topmostPresentedViewController
{
    // Find the topmost presented view controller of this view controller.
    UIViewController *topmostPresentedViewController = self;
    while (topmostPresentedViewController.presentedViewController) {
        topmostPresentedViewController = topmostPresentedViewController.presentedViewController;
    }
    
    return topmostPresentedViewController;
}

- (BOOL)pt_isInPopover
{
    // Check if the view controller has been presented at all.
    if (!self.presentingViewController) {
        // View controller has not been presented.
        return NO;
    }
    
    // Find the outermost (parent) view controller that was presented.
    UIViewController *outermostViewController = self.pt_outermostViewController;
    
    // Check for a popover presentation controller first since it will only be created if the
    // modalPresentationStyle property is UIModalPresentationPopover.
    UIPopoverPresentationController *popoverPresentationController = outermostViewController.popoverPresentationController;
    if (!popoverPresentationController) {
        // Presented view controller does not have a popover presentation controller.
        return NO;
    }
    
    // Check that the presentation controller is actually the popover presentation controller.
    // If the presentation adapts to use a different presentation controller then the popover
    // presentation controller could still be non-nil (above).
    UIPresentationController *presentationController = outermostViewController.presentationController;
    if (presentationController != popoverPresentationController) {
        return NO;
    }
    
    return (popoverPresentationController.arrowDirection < UIPopoverArrowDirectionUnknown);
}

- (NSLayoutYAxisAnchor *)pt_safeTopAnchor
{
    if (@available(iOS 11, *)) {
        return self.view.safeAreaLayoutGuide.topAnchor;
    } else {
        PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
        return self.topLayoutGuide.bottomAnchor;
        PT_IGNORE_WARNINGS_END
    }
}

- (void)pt_addChildViewController:(UIViewController *)childController withBlock:(void (NS_NOESCAPE ^)(void))block
{
    [self addChildViewController:childController];
    
    if (block) {
        block();
    }
    
    [childController didMoveToParentViewController:self];
}

- (void)pt_removeChildViewController:(UIViewController *)childController withBlock:(void (NS_NOESCAPE ^)(void))block
{
    if (self != childController.parentViewController) {
        NSString *reason = [NSString stringWithFormat:@"childController %@ is not a child of %@",
                            childController, self];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    [childController willMoveToParentViewController:nil];
    
    if (block) {
        block();
    }
    
    if (([self isViewLoaded] && [childController isViewLoaded]) &&
        [childController.view isDescendantOfView:self.view]) {
        [childController.viewIfLoaded removeFromSuperview];
    }
    
    [childController removeFromParentViewController];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIViewController, PTAdditions)
