//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTHalfModalPresentationController.h"

#import "PTHalfModalScrollView.h"
#import "PTTouchForwardingView.h"

#include <tgmath.h>

@interface PTHalfModalPresentationController () <UIScrollViewDelegate>

@property (nonatomic, strong) PTTouchForwardingView *touchForwardingView;

@property (nonatomic, strong) UIView *dimmingView;

@end

@implementation PTHalfModalPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if (self) {
        _dimsBackgroundView = NO;
        _cornerRadius = 10;
        _grabberHidden = NO;
        
        _scrollView = [[PTHalfModalScrollView alloc] init];
        _scrollView.delegate = self;
        
        // Match corner radii.
        _scrollView.cornerRadius = _cornerRadius;
        _scrollView.grabberHidden = _grabberHidden;
        
        // Debugging.
//        _scrollView.contentView.layer.borderWidth = 2.0;
//        _scrollView.contentView.layer.borderColor = UIColor.blueColor.CGColor;
        
        _touchForwardingView = [[PTTouchForwardingView alloc] init];
        
        // Dimming view.
        _dimmingView = [[UIView alloc] init];
        _dimmingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        _dimmingView.alpha = 0.0;
        
        _dimmingView.hidden = !_dimsBackgroundView;
        
        // Tap gesture recognizer for dimmed area.
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapRecognizer addTarget:self action:@selector(handleDismissalTap:)];
        
        [_dimmingView addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (BOOL)shouldRemovePresentersView
{
    // Presented content does not cover the presenting view controller's content.
    return NO;
}

#pragma mark - Presentation

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    
    [self addViewsForPresentation];
    
    self.scrollView.presenting = YES;
    
    self.dimmingView.alpha = 0.0;
    
    // Set up presentation animations.
    if (self.presentedViewController.transitionCoordinator) {
        [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // Fade in the dimming view.
            self.dimmingView.alpha = 1.0;
        } completion:nil];
    } else {
        self.dimmingView.alpha = 1.0;
    }
    
//    [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//
//        [self.scrollView layoutIfNeeded];
//
//        CGRect bounds = self.scrollView.bounds;
//        CGSize contentSize = self.scrollView.contentSize;
//
//        CGPoint newContentOffset = self.scrollView.contentOffset;
//
//        newContentOffset.y = contentSize.height - CGRectGetHeight(bounds);
//
//        self.scrollView.contentOffset = newContentOffset;
//
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//
//    }];
}

- (void)addViewsForPresentation
{
    // Add a touch forwarding view behind all other presented views.
    self.touchForwardingView.frame = self.containerView.bounds;
    self.touchForwardingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
    self.touchForwardingView.passthroughViews = @[
        self.presentingViewController.view,
    ];
    
    [self.containerView insertSubview:self.touchForwardingView atIndex:0];
    
    // Add a dimming view behind all other presented views.
    self.dimmingView.frame = self.touchForwardingView.bounds;
    self.dimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.touchForwardingView addSubview:self.dimmingView];
    
    // Initial preferredContentHeight is half the container view's height.
    self.scrollView.preferredContentHeight = CGRectGetHeight(self.containerView.bounds) / 2.0;
  
    self.scrollView.presentedViewController = self.presentedViewController;
        
    // NOTE: scrollView's frame will be set separately as part of the presentation.
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Register for keyboard notifications.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)removeViewsForPresentation
{
    [self.touchForwardingView removeFromSuperview];
    [self.scrollView removeFromSuperview];
    
    // Deregister for keyboard notifications.
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)presentationTransitionDidEnd:(BOOL)completed
{
    [super presentationTransitionDidEnd:completed];
    
    if (!completed) {
        // Presentation was cancelled.
        [self removeViewsForPresentation];
    } else {
        // Presentation completed.
        self.scrollView.presenting = NO;
    }
}

- (UIView *)presentedView
{
    return self.scrollView;
}

- (CGRect)frameOfPresentedViewInContainerView
{
    CGRect containerBounds = self.containerView.bounds;
    
    if (@available(iOS 11.0, *)) {
        // Inset top edge of container bounds by its safe area insets.
        UIEdgeInsets topInset = UIEdgeInsetsMake(self.containerView.safeAreaInsets.top, 0, 0, 0);
        containerBounds = UIEdgeInsetsInsetRect(containerBounds, topInset);
    }
    
    // Presented view width fits the smaller dimension, height fills container.
    CGSize size = CGSizeMake(fmin(CGRectGetWidth(containerBounds), CGRectGetHeight(containerBounds)),
                             CGRectGetHeight(containerBounds));
    
    // Center horizontally in container view, aligned to top of container.
    CGPoint origin = CGPointMake(fmax(0, (CGRectGetWidth(containerBounds) - size.width) / 2.0),
                                 CGRectGetMinY(containerBounds));
    
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

#pragma mark - Dismissal

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];
    
    if (self.presentedViewController.transitionCoordinator) {
        [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // Fade the dimming view back out.
            self.dimmingView.alpha = 0.0;
        } completion:nil];
    } else {
        self.dimmingView.alpha = 0.0;
    }
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    [super dismissalTransitionDidEnd:completed];
    
    if (completed) {
        // Dismissal was successful.
        [self removeViewsForPresentation];
    } else {
        // Dismissal was cancelled.
    }
}

- (void)handleDismissalTap:(UIGestureRecognizer *)recognizer
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Layout

//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
//{
//    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        // Update scroll view frame for rotation.
//        self.scrollView.frame = [self frameOfPresentedViewInContainerView];
//
//        // Update content offset to expose entire scroll view content area.
//        CGRect bounds = self.scrollView.bounds;
//        CGSize contentSize = self.scrollView.contentSize;
//
//        CGPoint contentOffset = self.scrollView.contentOffset;
//        contentOffset.y = contentSize.height - CGRectGetHeight(bounds);
//        self.scrollView.contentOffset = contentOffset;
//    } completion:nil];
//}

- (void)preferredContentSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container
{
    [super preferredContentSizeDidChangeForChildContentContainer:container];
    
    if (container == self.presentedViewController) {
        [self presentedViewControllerPreferredContentSizeDidChange];
    }
}

- (void)presentedViewControllerPreferredContentSizeDidChange
{
    CGSize preferredContentSize = self.presentedViewController.preferredContentSize;
    if (CGSizeEqualToSize(preferredContentSize, CGSizeZero)) {
        return;
    }
    
    CGFloat height = preferredContentSize.height;
    
    if (@available(iOS 11.0, *)) {
        // Add the vertical safe area insets to the preferred content height.
        // NOTE: The bottom safe area inset must *not* be accounted for in the incoming preferredContentSize.
        const UIEdgeInsets safeAreaInsets = self.scrollView.safeAreaInsets;
        height += (safeAreaInsets.top + safeAreaInsets.bottom);
        
        // Add the presented view controller's additional safe area insets.
        // These are added for the grabber at the top of the drawer.
        const UIEdgeInsets additionalInsets = self.presentedViewController.additionalSafeAreaInsets;
        height += (additionalInsets.top + additionalInsets.bottom);
    }
    
    if (self.scrollView.presenting) {
        self.scrollView.preferredContentHeight = height;
    } else {
        CGRect bounds = self.scrollView.bounds;
        CGSize contentSize = self.scrollView.contentSize;
        CGPoint contentOffset = self.scrollView.contentOffset;
        
        // Update content offset if the content is aligned with the bottom of the scroll view.
        BOOL needsContentOffsetUpdate = NO;
        if (contentOffset.y >= (contentSize.height - CGRectGetHeight(bounds))) {
            // Content is aligned with bottom of scroll view.
            needsContentOffsetUpdate = YES;
        }
        
        // Animate the change in preferred content height and content offset.
        [self.scrollView.superview layoutIfNeeded];
        
        self.scrollView.preferredContentHeight = height;
        
        [UIView animateWithDuration:0.35 delay:0.0 options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
            [self.scrollView.superview layoutIfNeeded];
            
            if (needsContentOffsetUpdate) {
                CGSize newContentSize = self.scrollView.contentSize;
                
                // Don't update contentOffset when new contentSize height is smaller than before,
                // since the height change alone will cause the contentOffset to be adjusted.
                if (newContentSize.height > contentSize.height) {
                    CGPoint contentOffset = self.scrollView.contentOffset;
                    contentOffset.y += (newContentSize.height - contentSize.height);
                    self.scrollView.contentOffset = contentOffset;
                }
            }
        } completion:nil];
    }
}

- (void)containerViewWillLayoutSubviews
{
    [super containerViewWillLayoutSubviews];
}

- (void)containerViewDidLayoutSubviews
{
    [super containerViewDidLayoutSubviews];
}

#pragma mark - Properties

- (NSArray<UIView *> *)passthroughViews
{
    return self.touchForwardingView.passthroughViews;
}

- (void)setPassthroughViews:(NSArray<UIView *> *)passthroughViews
{
    self.touchForwardingView.passthroughViews = passthroughViews;
}

- (void)setDimsBackgroundView:(BOOL)dimsBackgroundView
{
    _dimsBackgroundView = dimsBackgroundView;
    
    self.dimmingView.hidden = !dimsBackgroundView;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        // No change.
        return;
    }
    
    _cornerRadius = cornerRadius;
    
    self.scrollView.cornerRadius = cornerRadius;
}

- (void)setGrabberHidden:(BOOL)grabberHidden
{
    if (_grabberHidden == grabberHidden) {
        // No change.
        return;
    }
    
    _grabberHidden = grabberHidden;
    
    self.scrollView.grabberHidden = grabberHidden;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{

}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGRect bounds = self.scrollView.bounds;
    
    const CGFloat dismissThresholdDistance = 44.0 * 2;
    CGFloat dismissThresholdContentOffset = dismissThresholdDistance - CGRectGetHeight(bounds);
    if (@available(iOS 11.0, *)) {
        dismissThresholdContentOffset += self.scrollView.safeAreaInsets.bottom;
    }
    
    if (targetContentOffset->y < 0 && targetContentOffset->y <= dismissThresholdContentOffset) {
        PTLog(@"Dismissing view controller");
    
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    CGRect keyboardFrameEnd = CGRectZero;
    id value = userInfo[UIKeyboardFrameEndUserInfoKey];
    if ([value isKindOfClass:[NSValue class]]) {
        keyboardFrameEnd = ((NSValue *)value).CGRectValue;
    }
    
    // Add bottom content inset for keyboard frame.
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = CGRectGetHeight(keyboardFrameEnd);
    self.scrollView.contentInset = contentInset;
    
    CGRect bounds = self.scrollView.bounds;
    CGSize contentSize = self.scrollView.contentSize;
    
    // Use the new bottom content inset to allow us to scroll "down", keeping the scroll view
    // content visible.
    CGPoint contentOffset = self.scrollView.contentOffset;
    CGFloat minimumContentOffset = (contentSize.height - CGRectGetHeight(bounds)) + contentInset.bottom;
    if (contentOffset.y < minimumContentOffset) {
        contentOffset.y = minimumContentOffset;
    }
    self.scrollView.contentOffset = contentOffset;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    // Remove bottom content inset for keyboard frame.
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom = 0;
    self.scrollView.contentInset = contentInset;
}

@end
