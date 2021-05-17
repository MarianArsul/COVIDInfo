//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTHalfModalPresentationManager.h"

#import "PTHalfModalPresentationController.h"
#import "PTHalfModalTransitionAnimator.h"

@implementation PTHalfModalPresentationManager

#pragma mark - <UIViewControllerTransitioningDelegate>

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    if (source.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
        && (self.popoverSourceView || self.popoverBarButtonItem)) {
        UIPopoverPresentationController *popover = [[UIPopoverPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
        if (self.popoverSourceView) {
            popover.sourceView = self.popoverSourceView;
            if (!CGRectIsEmpty(self.popoverSourceRect)) {
                popover.sourceRect = self.popoverSourceRect;
            }
        } else {
            popover.barButtonItem = self.popoverBarButtonItem;
        }
        popover.canOverlapSourceViewRect = YES;
        popover.delegate = self;
        return popover;
    }
    return [[PTHalfModalPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    PTHalfModalTransitionAnimator *animator = [[PTHalfModalTransitionAnimator alloc] init];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    PTHalfModalTransitionAnimator *animator = [[PTHalfModalTransitionAnimator alloc] init];
    animator.presenting = NO;
    return animator;
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end
