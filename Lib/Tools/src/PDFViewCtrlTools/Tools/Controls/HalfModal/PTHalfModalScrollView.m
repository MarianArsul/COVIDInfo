//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTHalfModalScrollView.h"

#import "PTToolsUtil.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTHalfModalScrollView ()

@property (nonatomic, strong) UIView *backgroundContainer;
@property (nonatomic, strong) UIView *shadowView;

@property (nonatomic, strong) CAShapeLayer *contentMaskLayer;
@property (nonatomic, strong) CAShapeLayer *backgroundMaskLayer;

@property (nonatomic, assign) BOOL needsContentViewConstraints;
@property (nonatomic, strong) NSLayoutConstraint *preferredContentHeightConstraint;

@property (nonatomic, assign) CGFloat presentingContentHeight;

@end

NS_ASSUME_NONNULL_END

@implementation PTHalfModalScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        const CGRect bounds = self.bounds;
        
        // Do not show the horizontal or vertical scroll bars because the scroll view is an
        // implementation detail.
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;

        // Disable scroll-to-top when tapping the status bar, which would immediately hide the
        // content area.
        self.scrollsToTop = NO;
        
        // Decelerate faster after a (with velocity) drag ends.
        self.decelerationRate = UIScrollViewDecelerationRateFast;

        // No scroll view background color to allow content underneath to be seen.
        self.backgroundColor = nil;
        
        // Background container view fills entire scroll view content area.
        _backgroundContainer = [[UIView alloc] initWithFrame:bounds];
        _backgroundContainer.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                                 UIViewAutoresizingFlexibleHeight);
                
        [self addSubview:_backgroundContainer];
        
        // Visual effect view background (default).
        _backgroundView = [[self class] createDefaultBackgroundView];
        _backgroundView.frame = _backgroundContainer.bounds;
        _backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
        
        [_backgroundContainer addSubview:_backgroundView];
        
        // Content view fills the entire scroll view content area.
        _contentView = [[UIView alloc] initWithFrame:bounds];
        
        [self addSubview:_contentView];
        
        // Grabber view attaches to the top edge of the content view.
        _grabber = [[PTGrabberView alloc] init];
        _grabber.translatesAutoresizingMaskIntoConstraints = NO;
        
        _grabberHidden = NO;
        _grabber.hidden = _grabberHidden;
        
        [self addSubview:_grabber];
        
        // Content mask layer for rounded corners.
        _contentMaskLayer = [[CAShapeLayer alloc] init];
        _contentMaskLayer.frame = _contentView.layer.bounds;
        _contentMaskLayer.fillColor = UIColor.whiteColor.CGColor; // Only used for alpha-masking.
        _contentMaskLayer.backgroundColor = nil;
        // NOTE: mask layer path will be set after layout.
        
        _contentView.layer.mask = _contentMaskLayer;
        
        // Background mask layer for rounded corners.
        _backgroundMaskLayer = [[CAShapeLayer alloc] init];
        _backgroundMaskLayer.frame = _backgroundContainer.layer.bounds;
        _backgroundMaskLayer.fillColor = UIColor.whiteColor.CGColor; // Only used for alpha-masking.
        _backgroundMaskLayer.backgroundColor = nil;
        // NOTE: mask layer path will be set after layout.

        _backgroundContainer.layer.mask = _backgroundMaskLayer;
        
        // Shadow view underneath background view.
        _shadowView = [[UIView alloc] initWithFrame:_backgroundContainer.frame];
        _shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _shadowView.layer.shadowColor = UIColor.blackColor.CGColor;
        _shadowView.layer.shadowOpacity = 0.1;
        _shadowView.layer.shadowRadius = 3.0;
        _shadowView.layer.shadowOffset = CGSizeMake(0.0, -3.0);
        
        [self insertSubview:_shadowView belowSubview:_backgroundContainer];
        
        _cornerRadius = 10;
        
        _preferredContentHeightConstraint = [_contentView.heightAnchor constraintEqualToConstant:0.0];
        _preferredContentHeightConstraint.priority = UILayoutPriorityDefaultHigh;
        _preferredContentHeightConstraint.identifier = PT_KEY(self, preferredContentHeightConstraint);
        
        // Schedule constraints setup.
        [self setNeedsUpdateConstraints];
        _needsContentViewConstraints = YES;
        
        [self.panGestureRecognizer addTarget:self action:@selector(handlePanGesture:)];
    }
    return self;
}

#pragma mark - Constraints

- (void)updateConstraints
{
    if (self.needsContentViewConstraints) {
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:@[
            // Anchor content view to (interior) edges of scroll view.
            [self.contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            
            // Anchor content view width to (exterior) scroll view width.
            [self.contentView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
            // Content view height must fit inside (exterior) scroll view height.
            [self.contentView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor],
            
            (self.preferredContentHeightConstraint),
            
            [self.grabber.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [self.grabber.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            /* Use PTGrabberView intrinsic width and height. */
        ]];
        
        // Content view constraints are added.
        self.needsContentViewConstraints = NO;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    CGFloat scrollViewHeight = CGRectGetHeight(bounds);
    
    CGFloat contentHeight = self.contentSize.height;
    
//    NSLog(@"layoutSubviews: content height = %f", contentHeight);
    
    UIEdgeInsets currentInset = self.contentInset;
    if (@available(iOS 11.0, *)) {
        currentInset = self.adjustedContentInset;
    }
    // Ensure top content inset is large enough to allow scrolling "up" (decreasing content offset)
    // to hide the entire content area.
    CGFloat targetTopInset = scrollViewHeight;
    if (currentInset.top != targetTopInset) {
        UIEdgeInsets newInset = self.contentInset;
        newInset.top = targetTopInset;
        self.contentInset = newInset;
    }

    if ([self isPresenting]) {
        // Check if the content area has changed size while presenting.
        if (contentHeight != self.presentingContentHeight) {
            CGPoint contentOffset = self.contentOffset;

            // Ensure content area is fully visible while presenting.
            // The content offset should place the bottom of the content area at the bottom of the
            // scroll view.
            CGFloat targetContentOffset = contentHeight - scrollViewHeight;
            if (contentOffset.y < targetContentOffset) {
                contentOffset.y = targetContentOffset;
                self.contentOffset = contentOffset;
            }
            
            // Record the current content height while presenting.
            self.presentingContentHeight = contentHeight;
        }
    }
    
    // Adjust the background view height to extend to bottom of scroll view bounds.
    // If this is not done, scrolling "down" past the edge of the content area will expose
    // the content underneath.
    CGRect backgroundViewFrame = self.backgroundContainer.frame;
    CGFloat backgroundViewMaxY = CGRectGetMaxY(backgroundViewFrame);
    CGFloat scrollViewMaxY = CGRectGetMaxY(bounds);
    
    CGFloat backgroundHeightAdjustment = scrollViewMaxY - backgroundViewMaxY;
    if (backgroundHeightAdjustment > 0) {
        backgroundViewFrame.size.height += backgroundHeightAdjustment;
        self.backgroundContainer.frame = backgroundViewFrame;
    }
    
    [self updateMaskLayers];
    
    [self updateAdditionalSafeAreaInsets];
}

- (void)updateMaskLayers
{
    // Round the top left and right corners.
    UIRectCorner corners = UIRectCornerTopLeft | UIRectCornerTopRight;
    CGSize cornerRadii = CGSizeMake(self.cornerRadius, self.cornerRadius);
    
    // Update content mask layer.
    self.contentMaskLayer.frame = self.contentView.layer.bounds;

    UIBezierPath *contentPath = [UIBezierPath bezierPathWithRoundedRect:self.contentMaskLayer.bounds
                                                      byRoundingCorners:corners
                                                            cornerRadii:cornerRadii];
    self.contentMaskLayer.path = contentPath.CGPath;
    
    // Update background mask layer.
    self.backgroundMaskLayer.frame = self.backgroundContainer.layer.bounds;
    
    UIBezierPath *backgroundPath = [UIBezierPath bezierPathWithRoundedRect:self.backgroundMaskLayer.bounds
                                                         byRoundingCorners:corners
                                                               cornerRadii:cornerRadii];
    self.backgroundMaskLayer.path = backgroundPath.CGPath;
    
    [self updateShadow];
}

- (void)updateShadow
{
    // Update shadow path from background mask layer.
    self.shadowView.layer.shadowPath = self.backgroundMaskLayer.path;
}

- (void)updateAdditionalSafeAreaInsets
{
    if (!self.presentedViewController) {
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        const CGFloat grabberHeight = ([self isGrabberHidden]) ? 0 : CGRectGetHeight(self.grabber.frame);
        const UIEdgeInsets grabberInsets = UIEdgeInsetsMake(grabberHeight, 0, 0, 0);
        
        const UIEdgeInsets currentInsets = self.presentedViewController.additionalSafeAreaInsets;
        
        if (!UIEdgeInsetsEqualToEdgeInsets(currentInsets, grabberInsets)) {
            self.presentedViewController.additionalSafeAreaInsets = grabberInsets;
        }
    }
}

#pragma mark - Background view

- (void)setBackgroundView:(UIView *)backgroundView
{
    UIView * const previousBackgroundView = _backgroundView;
    if (previousBackgroundView) {
        [previousBackgroundView removeFromSuperview];
    }
    
    if (!backgroundView) {
        backgroundView = [[self class] createDefaultBackgroundView];
    }
    
    NSAssert(backgroundView != nil, @"Background view cannot be nil");
    
    _backgroundView = backgroundView;
    
    [self.backgroundContainer addSubview:backgroundView];
    
    backgroundView.frame = self.backgroundContainer.bounds;
    backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight);
}

+ (UIView *)createDefaultBackgroundView
{
    if (@available(iOS 13.0, *)) {
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterial];
        return [[UIVisualEffectView alloc] initWithEffect:effect];
    } else {
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
        UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        
        UIView *tintView = [[UIView alloc] initWithFrame:visualEffectView.bounds];
        tintView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
        
        tintView.backgroundColor = UIColor.whiteColor;
        tintView.alpha = 0.5;
        
        [visualEffectView addSubview:tintView];
                
        return visualEffectView;
    }
}

#pragma mark - UIView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Only accept events over the background view.
    return [self.backgroundContainer pointInside:[self convertPoint:point toView:self.backgroundContainer]
                                       withEvent:event];
}

#pragma mark - Gesture recognizer actions

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint velocity = [gestureRecognizer velocityInView:self];
    
    if (velocity.y < 0) { // Scrolling down.
        CGFloat maximumAllowedContentOffset = 0;
        if (@available(iOS 11.0, *)) {
            // Avoid top safe area inset.
            maximumAllowedContentOffset -= self.safeAreaInsets.top;
        }

        // Allow scrolling "up" to hide bottom content inset (from keyboard handling).
        maximumAllowedContentOffset += self.contentInset.bottom;
        
        CGPoint contentOffset = self.contentOffset;
        
        if (contentOffset.y > maximumAllowedContentOffset) {
            CGFloat adjustment = maximumAllowedContentOffset - contentOffset.y;

            // Adjust gesture recognizer translation.
            CGPoint translation = [gestureRecognizer translationInView:self];
            translation.y -= adjustment;
            [gestureRecognizer setTranslation:translation inView:self];
            
            // Adjust content offset.
            contentOffset.y += adjustment;
            self.contentOffset = contentOffset;
        }
    }
}

#pragma mark - Presented view controller

- (void)setPresentedViewController:(UIViewController *)presentedViewController
{
    if (_presentedViewController) {
        [_presentedViewController.view removeFromSuperview];
    }
    
    _presentedViewController = presentedViewController;
    
    if (presentedViewController) {
        // Add presentedViewController view to content view.
        UIView *presentedView = presentedViewController.view;
        presentedView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:presentedView];
        
        [NSLayoutConstraint activateConstraints:@[
            [presentedView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [presentedView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [presentedView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [presentedView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        ]];
    }
}

#pragma mark - Drawer height

- (CGFloat)drawerHeight
{
    return fmin(0, CGRectGetHeight(self.bounds) + self.contentOffset.y);
}

- (void)setDrawerHeight:(CGFloat)drawerHeight
{
    CGPoint contentOffset = self.contentOffset;
    
    contentOffset.y = drawerHeight - CGRectGetHeight(self.bounds);
    
    self.contentOffset = contentOffset;
}

#pragma mark - Corner radius

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        // No change.
        return;
    }
    
    _cornerRadius = cornerRadius;
    
    // Mask layers need to be updated.
    [self.layer setNeedsLayout];
}

#pragma mark - grabbedHidden

- (void)setGrabberHidden:(BOOL)grabberHidden
{
    _grabberHidden = grabberHidden;
    
    self.grabber.hidden = grabberHidden;
    
    [self setNeedsLayout];
}

#pragma mark - preferredContentHeight

- (CGFloat)preferredContentHeight
{
    return self.preferredContentHeightConstraint.constant;
}

- (void)setPreferredContentHeight:(CGFloat)preferredContentHeight
{
    if (self.preferredContentHeightConstraint.constant == preferredContentHeight) {
        // No change.
        return;
    }
    
    self.preferredContentHeightConstraint.constant = preferredContentHeight;
}

@end
