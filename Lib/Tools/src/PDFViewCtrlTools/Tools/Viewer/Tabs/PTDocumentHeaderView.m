//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentHeaderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentHeaderView ()
{
    BOOL _needsUpdateContentViewConstraints;
}

@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *contentViewConstraints;

@property (nonatomic, weak, nullable) UIView *transitioningFromView;
@property (nonatomic, getter=isTransitioningFromViewHidden) BOOL transitioningFromViewHidden;

@property (nonatomic, weak, nullable) UIView *transitioningToView;
@property (nonatomic, getter=isTransitioningToViewHidden) BOOL transitioningToViewHidden;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
    }
    return self;
}

#pragma mark - Constraints

- (void)updateContentViewConstraints
{
    if (self.contentViewConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.contentViewConstraints];
        self.contentViewConstraints = nil;
    }
    
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray array];
    
    if (self.transitioningFromView || self.transitioningToView) {
        if (self.transitioningFromView) {
            const BOOL hidden = [self isTransitioningFromViewHidden];
            [constraints addObjectsFromArray:[self PT_constrainContentView:self.transitioningFromView
                                                                    hidden:hidden]];
        }
        if (self.transitioningToView) {
            const BOOL hidden = [self isTransitioningToViewHidden];
            [constraints addObjectsFromArray:[self PT_constrainContentView:self.transitioningToView
                                                                    hidden:hidden]];
        }
    } else if (self.contentView) {
        [constraints addObjectsFromArray:[self PT_constrainContentView:self.contentView
                                                                hidden:NO]];
    }
    
    if (constraints.count > 0) {
        [NSLayoutConstraint activateConstraints:constraints];
        self.contentViewConstraints = constraints;
    }
}

- (NSArray<NSLayoutConstraint *> *)PT_constrainContentView:(UIView *)contentView hidden:(BOOL)hidden
{
    if (hidden) {
        return @[
            [contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
            [contentView.bottomAnchor constraintEqualToAnchor:self.topAnchor],
            [contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        ];
    } else {
        return @[
            [contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
            [contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
            /* Use contentView intrinsic width and height. */
        ];
    }
}

- (void)updateConstraints
{
    if ([self needsUpdateContentViewConstraints]) {
        [self updateContentViewConstraints];
        
        _needsUpdateContentViewConstraints = NO;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (BOOL)needsUpdateContentViewConstraints
{
    return _needsUpdateContentViewConstraints;
}

- (void)setNeedsUpdateContentViewConstraints
{
    _needsUpdateContentViewConstraints = YES;
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
    
    [self.superview setNeedsUpdateConstraints];
    [self.superview setNeedsLayout];
}

#pragma mark - Content view transitioning

- (void)transitionToView:(UIView *)toView animated:(BOOL)animated
{
    if (toView == self.contentView) {
        return;
    }
    
    UIView *fromView = self.contentView;
    self.contentView = toView;
    
    if (self.window) {
        if (fromView && toView) {
            // Transitioning between views.
            [self PT_transitionFromView:fromView toView:toView animated:animated];
        } else if (fromView) {
            // Transitioning to empty view.
            [self PT_transitionFromView:fromView animated:animated];
        } else if (toView) {
            // Transitioning from empty view.
            [self PT_transitionToView:toView animated:animated];
        }
    } else {
        if (fromView) {
            [fromView removeFromSuperview];
        }
        if (toView) {
            toView.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:toView];
            [self setNeedsUpdateContentViewConstraints];
        }
    }
}

- (NSTimeInterval)transitionDuration
{
    return UINavigationControllerHideShowBarDuration;
}

- (void)PT_transitionFromView:(UIView *)fromView toView:(UIView *)toView animated:(BOOL)animated
{
    self.transitioningFromView = fromView;
    self.transitioningToView = toView;
    
    BOOL toViewNeedsInitialAlpha = NO;
    if (![toView isDescendantOfView:self]) {
        toView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:toView];
        
        toViewNeedsInitialAlpha = YES;
    }
    
    // From-view & to-view are both "unhidden" (onscreen) for an expanded layout.
    self.transitioningFromViewHidden = NO;
    self.transitioningToViewHidden = NO;
    [self setNeedsUpdateContentViewConstraints];
    [self layoutIfNeeded];
    
    const NSTimeInterval duration = (animated) ? [self transitionDuration] : 0.0;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    
    // In order to fade in the to-view, the initial alpha value of 0.0 needs to be set
    // in an animation block so that the subsequent animation sees the initial value,
    // which requires at least one run loop cycle to propagate.
    [UIView animateWithDuration:0.0 delay:0.0 options:options animations:^{
        if (toViewNeedsInitialAlpha) {
            toView.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            toView.alpha = 1.0;
        } completion:^(BOOL finished) {
            if (fromView != self.contentView) {
                [fromView removeFromSuperview];
            }
            // Clear transitioning views.
            if (fromView == self.transitioningFromView) {
                self.transitioningFromView = nil;
            }
            if (toView == self.transitioningToView) {
                self.transitioningToView = nil;
            }
        }];
    }];
}

- (void)PT_transitionFromView:(UIView *)fromView animated:(BOOL)animated
{
    self.transitioningFromView = fromView;
    
    // Clear pending layout updates.
    [self.superview layoutIfNeeded];
    
    // From-view becomes "hidden" (offscreen) for a collapsed layout.
    self.transitioningFromViewHidden = YES;
    [self setNeedsUpdateContentViewConstraints];
    
    const NSTimeInterval duration = (animated) ? [self transitionDuration] : 0.0;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        if ([self needsUpdateContentViewConstraints]) {
            [self.superview layoutIfNeeded];
        }
    } completion:^(BOOL finished) {
        if (fromView != self.contentView) {
            [fromView removeFromSuperview];
        }
        // Clear transitioning views.
        if (fromView == self.transitioningFromView) {
            self.transitioningFromView = nil;
        }
    }];
}

- (void)PT_transitionToView:(UIView *)toView animated:(BOOL)animated
{
    self.transitioningToView = toView;
    
    toView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:toView];
    
    // To-view starts "hidden" (offscreen) for a collapsed layout.
    self.transitioningToViewHidden = YES;
    [self setNeedsUpdateContentViewConstraints];

    // Clear pending layout updates.
    [self.superview layoutIfNeeded];
    
    // To-view becomes "unhidden" (onscreen) for an expanded layout.
    self.transitioningToViewHidden = NO;
    [self setNeedsUpdateContentViewConstraints];
    
    const NSTimeInterval duration = (animated) ? [self transitionDuration] : 0.0;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        if ([self needsUpdateContentViewConstraints]) {
            [self.superview layoutIfNeeded];
        }
    } completion:^(BOOL finished) {
        // Clear transitioning views.
        if (toView == self.transitioningToView) {
            self.transitioningToView = nil;
        }
    }];
}

@end
