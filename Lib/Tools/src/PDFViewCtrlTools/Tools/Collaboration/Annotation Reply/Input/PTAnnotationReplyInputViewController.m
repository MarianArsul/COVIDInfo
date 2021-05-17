//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationReplyInputViewController.h"

#import "PTFrameObservingAccessoryView.h"

#import "UIViewController+PTAdditions.h"

#include <tgmath.h>

@interface PTAnnotationReplyInputViewController () <PTAnnotationReplyInputViewDelegate, PTFrameObservingAccessoryViewDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *inputContainerView;

@property (nonatomic, strong) PTFrameObservingAccessoryView *keyboardFrameObservingView;

@property (nonatomic, strong) UILayoutGuide *spacer;
@property (nonatomic, strong) NSLayoutConstraint *spacerHeightConstraint;

@property (nonatomic) CGFloat keyboardHeightAdjustment;

@property (nonatomic, assign) BOOL viewConstraintsLoaded;

@end

@implementation PTAnnotationReplyInputViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.containerView];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.containerView.bounds];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.containerView addSubview:toolbar];
    
    self.inputContainerView = [[UIView alloc] initWithFrame:self.containerView.bounds];
    self.inputContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.inputContainerView.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    self.inputContainerView.preservesSuperviewLayoutMargins = YES;
    
    [self.containerView addSubview:self.inputContainerView];
    
    self.inputView = [[PTAnnotationReplyInputView alloc] init];
    self.inputView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.inputView.delegate = self;
    
    [self.inputContainerView addSubview:self.inputView];
    
    self.keyboardFrameObservingView = [[PTFrameObservingAccessoryView alloc] initWithFrame:self.containerView.frame];
    self.keyboardFrameObservingView.delegate = self;
    
    self.spacer = [[UILayoutGuide alloc] init];
    self.spacer.identifier = @"Bottom spacer";
    [self.view addLayoutGuide:self.spacer];
    
    self.spacerHeightConstraint =
    [self.spacer.heightAnchor constraintEqualToConstant:0.0];
    
    // Schedule constraints set up.
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Constraints

- (void)loadViewConstraints
{
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       // Constrain containerView to "top" of view controller root view.
       // (Bottom is constrained by the spacer layout guide).
       [self.containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.containerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       /* Use containerView intrinsic height. */
       
       // Constrain inputView within the inputContainerView layout margins.
       [self.inputView.leadingAnchor constraintEqualToAnchor:self.inputContainerView.layoutMarginsGuide.leadingAnchor],
       [self.inputView.topAnchor constraintEqualToAnchor:self.inputContainerView.layoutMarginsGuide.topAnchor],
       [self.inputView.trailingAnchor constraintEqualToAnchor:self.inputContainerView.layoutMarginsGuide.trailingAnchor],
       [self.inputView.bottomAnchor constraintEqualToAnchor:self.inputContainerView.layoutMarginsGuide.bottomAnchor],
       /* Use inputView intrinsic height. */
       
       // Constrain spacer layout guide below containerView.
       [self.spacer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.spacer.topAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
       [self.spacer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [self.spacer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
       (self.spacerHeightConstraint),
       ]];
}

- (void)updateViewConstraints
{
    if (!self.viewConstraintsLoaded) {
        [self loadViewConstraints];
        
        // View constraints are loaded.
        self.viewConstraintsLoaded = YES;
    }
    
    // Call super implementation as final step.
    [super updateViewConstraints];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Update the height of the accessory view.
    self.keyboardFrameObservingView.height = CGRectGetHeight(self.containerView.frame);
}

#pragma mark - View appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateInputAccessoryView];
    
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    
    [self deregisterForKeyboardNotifications];
}

#pragma mark - <UIContentContainer>

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Update (add/remove) the input accessory view when the size transition is complete.
        // NOTE: The timing doesn't work if this is done in the trait collection change methods
        // (-willTransitionToTraitCollection:withTransitionCoordinator: and -traitCollectionDidChange:).
        [self updateInputAccessoryView];
    }];
}

#pragma mark - Views

- (PTAnnotationReplyInputView *)inputView
{
    [self loadViewIfNeeded];
    
    NSAssert(_inputView != nil,
             @"Failed to load inputView");
    
    return _inputView;
}

- (void)updateInputAccessoryView
{
    BOOL changed = NO;
    
    if ([self pt_isInPopover]) {
        // The frame-observing input accessory view is not needed for popover presentations.
        if (self.inputView.textView.inputAccessoryView) {
            // Remove the input accessory view.
            self.inputView.textView.inputAccessoryView = nil;

            // Input accessory view was changed.
            changed = YES;
        }
    } else {
        // The frame-observing input accessory view is required for non-popover presentations.
        if (!self.inputView.textView.inputAccessoryView) {
            // Add the input accessory view.
            self.inputView.textView.inputAccessoryView = self.keyboardFrameObservingView;
            self.keyboardFrameObservingView.height = CGRectGetHeight(self.containerView.frame);
            
            // Input accessory view was changed.
            changed = YES;
        }
    }
    
    // There is an issue with UIKit not noticing the inputAccessoryView change when the keyboard is
    // shown and we are transitioning to a non-popover presentation. The text view must end editing
    // (and hide the keyboard) when there is a change to its inputAccessoryView.
    if (changed) {
        [self.view endEditing:YES];
    }
}

#pragma mark - <PTAnnotationReplyInputViewDelegate>

- (void)annotationReplyInputView:(PTAnnotationReplyInputView *)annotationReplyInputView didSubmitText:(NSString *)text
{
    // Notify delegate of submission.
    if ([self.delegate respondsToSelector:@selector(annotationReplyInputViewController:didSubmitText:)]) {
        [self.delegate annotationReplyInputViewController:self didSubmitText:text];
    }
}

#pragma mark - Keyboard

#pragma mark Notifications

- (void)registerForKeyboardNotifications
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillChangeFrameWithNotification:)
                                               name:UIKeyboardWillChangeFrameNotification
                                             object:nil];
}

- (void)deregisterForKeyboardNotifications
{
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIKeyboardWillChangeFrameNotification
                                                object:nil];
}

- (void)keyboardWillChangeFrameWithNotification:(NSNotification *)notification
{
    // Do not adjust for the keyboard when in popover.
    if ([self pt_isInPopover]) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    
    // Check if keyboard notification is for the current app.
    BOOL isLocal = ((NSNumber *)userInfo[UIKeyboardIsLocalUserInfoKey]).boolValue;
    if (!isLocal) {
        return;
    }
    
    // Check that keyboard's frame can be converted to superview coordinates.
    UIView *superview = self.view.superview;
    if (!superview) {
        return;
    }
    CGRect superviewBounds = superview.bounds;
    
    // Check the intersection of the superview and keyboard frames.
    CGRect keyboardFrameEnd = ((NSValue *)userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;
    keyboardFrameEnd = [superview convertRect:keyboardFrameEnd fromView:nil];
    CGRect intersection = CGRectIntersection(superviewBounds, keyboardFrameEnd);
    if (CGRectIsNull(intersection)) {
        // Superview does not intersect with keyboard frame.
        // Reset bottom offset.
        self.keyboardHeightAdjustment = 0.0;
    } else {
        CGFloat keyboardHeightAdjustment = CGRectGetHeight(intersection);
        // Remove input accessory view height from keyboard height.
        if (self.keyboardFrameObservingView.window) {
            keyboardHeightAdjustment -= self.keyboardFrameObservingView.height;
        }
        self.keyboardHeightAdjustment = fmax(0, keyboardHeightAdjustment);
    }
    self.spacerHeightConstraint.constant = self.keyboardHeightAdjustment;
    
    double duration = ((NSNumber *)userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
    
    UIViewAnimationOptions options = 0;
    
    // Animation curve.
    UIViewAnimationCurve animationCurve = ((NSNumber *)userInfo[UIKeyboardAnimationCurveUserInfoKey]).unsignedIntegerValue;
    options |= (animationCurve << 16); // Convert UIViewAnimationCurve to UIViewAnimationOptionCurve*.
    
    [self.view.superview layoutIfNeeded];
    
//    self.spacerHeightConstraint.constant = self.keyboardHeightAdjustment;
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        [self.view.superview layoutIfNeeded];
    } completion:nil];
}

#pragma mark - <PTFrameObservingAccessoryViewDelegate>

- (void)frameObservingAccessoryView:(PTFrameObservingAccessoryView *)frameObservingAccessoryView frameDidChange:(CGRect)frame
{
    if ([self pt_isInPopover]) {
        return;
    }
    
    CGFloat spacerHeight = 0.0;
    
    // Adjust spacer height constraint for accessory view.
    // Skip when accessory view is offscreen or keyboard has been hidden.
    CGRect keyboardWindowBounds = self.keyboardFrameObservingView.window.bounds;
    if (CGRectIntersectsRect(frame, keyboardWindowBounds) &&
        self.keyboardHeightAdjustment > 0) {
        CGRect localFrame = [self.view convertRect:frame fromView:nil];
        CGRect viewBounds = self.view.bounds;
        
        self.spacerHeightConstraint.constant = (CGRectGetMaxY(viewBounds) - CGRectGetMaxY(localFrame));
    }
    
    if (spacerHeight == 0.0) {
        return;
    }
    
    self.spacerHeightConstraint.constant = spacerHeight;
}

@end
