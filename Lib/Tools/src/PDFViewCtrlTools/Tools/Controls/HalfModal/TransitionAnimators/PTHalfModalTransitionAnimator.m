//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTHalfModalTransitionAnimator.h"

#import "PTHalfModalPresentationController.h"

// Matches the system presentation animation duration.
static const CGFloat PTHalfModalTransitionAnimationDuration = 0.5;

// Transition Animation Reference:
// https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html#//apple_ref/doc/uid/TP40007457-CH16-SW1

@implementation PTHalfModalTransitionAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
    UIView *containerView = transitionContext.containerView;
    
    CGRect containerFrame = containerView.frame;
    
    CGRect fromViewInitialFrame = [transitionContext initialFrameForViewController:fromVC];
    CGRect fromViewFinalFrame = [transitionContext finalFrameForViewController:fromVC];
    CGRect toViewInitialFrame = CGRectZero;
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];
    
    PTHalfModalScrollView *scrollView = nil;
    
    if ([self isPresenting]) {
        // Get the presented half-modal scroll view.
        if ([toView isKindOfClass:[PTHalfModalScrollView class]]) {
            scrollView = (PTHalfModalScrollView *)toView;
        }
//        else {
//            PTLog(@"Half-modal scroll view not found, using default presentation transition animation");
//        }
        
        toViewInitialFrame = toViewFinalFrame;
        toViewInitialFrame.origin.y = CGRectGetMaxY(containerFrame);
        
        [containerView addSubview:toView];
        
        // Set presented view's initial frame.
        toView.frame = toViewInitialFrame;
    } else {
        // Get the presented half-modal scroll view.
        if ([fromView isKindOfClass:[PTHalfModalScrollView class]]) {
            scrollView = (PTHalfModalScrollView *)fromView;
        } else {
            PTLog(@"Half-modal scroll view not found, using default dismissal transition animation");
            
            fromViewFinalFrame = fromViewInitialFrame;
            fromViewFinalFrame.origin.y = CGRectGetMaxY(containerFrame);
        }

//        fromViewFinalFrame = fromViewInitialFrame;
//        fromViewFinalFrame.origin.y = CGRectGetMaxY(containerFrame);
    }
    
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:500 initialSpringVelocity:0 options:options animations:^{
        if ([self isPresenting]) {
            // Animate the presented view into position.
            toView.frame = toViewFinalFrame;
        } else {
            // Animate the dismissed view offscreen.
            if (scrollView) {
                scrollView.drawerHeight = 0;
            } else {
                fromView.frame = fromViewFinalFrame;
            }
        }
    } completion:^(BOOL finished) {
        BOOL success = !transitionContext.transitionWasCancelled;
        
        // After a failed presentation or successful dismissal, remove the view.
        if ([self isPresenting] && !success) {
            [toView removeFromSuperview];
        }
        else if (![self isPresenting] && success) {
            [fromView removeFromSuperview];
        }
        
        // Notify UIKit that the transition has finished.
        [transitionContext completeTransition:success];
    }];
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return PTHalfModalTransitionAnimationDuration;
}

@end
