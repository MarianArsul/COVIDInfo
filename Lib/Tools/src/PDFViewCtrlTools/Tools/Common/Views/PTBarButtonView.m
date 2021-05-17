//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBarButtonView.h"

#import "PTAutoCoding.h"
#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTBarButtonView ()
{
    BOOL _needsLoadConstraints;
}

@property (nonatomic, strong, nullable) NSLayoutConstraint *widthMinimizingConstraint;

@end

NS_ASSUME_NONNULL_END

@implementation PTBarButtonView

- (void)PTBarButtonView_commonInit
{
    // Badge indicator view.
    _badgeIndicatorView = [[PTBadgeIndicatorView alloc] init];
    _badgeIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_badgeIndicatorView];
    _badgeIndicatorView.hidden = YES;
    
    self.layoutMargins = UIEdgeInsetsMake(0, 10, 0, 10);
    if (@available(iOS 11.0, *)) {
        self.insetsLayoutMarginsFromSafeArea = NO;
    }
    
    _needsLoadConstraints = YES;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTBarButtonView_commonInit];
    }
    return self;
}

- (instancetype)initWithView:(UIView *)view
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self PTBarButtonView_commonInit];

        _view = view;
        
        if (view) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:view];
        }
    }
    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [PTAutoCoding autoUnarchiveObject:self
                                  ofClass:[PTBarButtonView class]
                                withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [PTAutoCoding autoArchiveObject:self
                            ofClass:[PTBarButtonView class]
                            forKeys:nil
                          withCoder:coder];
}

#pragma mark - Constraints

- (void)loadConstraints
{
    if (self.view) {
        // Constraint setup taken from _UIButtonBarButton & _UIModernBarButton.
        UILayoutGuide *layoutMarginsGuide = self.layoutMarginsGuide;
        
        [NSLayoutConstraint activateConstraints:@[
            [self.view.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor],
            [self.view.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor],
            
            [self.view.leadingAnchor constraintGreaterThanOrEqualToAnchor:layoutMarginsGuide.leadingAnchor],
            [self.view.trailingAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.trailingAnchor],
            
            [self.badgeIndicatorView.centerXAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.badgeIndicatorView.centerYAnchor constraintEqualToAnchor:self.view.topAnchor],
        ]];
        
        [NSLayoutConstraint pt_activateConstraints:@[
            // Center button in view.
            [self.view.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.view.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            
            // Match widths, with spacing on both sides.
            [self.view.widthAnchor constraintEqualToAnchor:layoutMarginsGuide.widthAnchor],
        ] withPriority:(UILayoutPriorityRequired - 1) /* 999 */];
    }
    
    if (!self.widthMinimizingConstraint) {
        // Horizontal constraint to keep view width as small as possible.
        self.widthMinimizingConstraint = [self.widthAnchor constraintEqualToConstant:0];
        self.widthMinimizingConstraint.identifier = PT_SELF_KEY(widthMinimizingConstraint);
        
        [NSLayoutConstraint pt_activateConstraints:@[
            self.widthMinimizingConstraint,
        ] withPriority:(UILayoutPriorityDefaultLow + 1)];
    }
}

- (void)updateConstraints
{
    if ([self needsLoadConstraints]) {
        [self loadConstraints];
        
        _needsLoadConstraints = NO;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (BOOL)needsLoadConstraints
{
    return _needsLoadConstraints;
}

- (void)setNeedsLoadConstraints
{
    _needsLoadConstraints = YES;
    [self setNeedsUpdateConstraints];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateLayoutMargins];
}

- (void)updateLayoutMargins
{
    // Check if the leading or trailing edge of the view is touching the superview.
    // When touching the superview, that edge does not get a "spacer".
    UIEdgeInsets layoutMargins = self.layoutMargins;
    
    if (round(CGRectGetMinX(self.frame)) == round(CGRectGetMinX(self.superview.bounds))) {
        // Touching leading end.
        layoutMargins.left = 0;
    }
    else {
        // Not touching leading end.
        layoutMargins.left = 10;
    }
    
    if (round(CGRectGetMaxX(self.frame)) == round(CGRectGetMaxX(self.superview.bounds))) {
        // Touching trailing end.
        layoutMargins.right = 0;
    }
    else {
        // Not touching trailing end.
        layoutMargins.right = 10;
    }
    
    if (!UIEdgeInsetsEqualToEdgeInsets(self.layoutMargins, layoutMargins)) {
        self.layoutMargins = layoutMargins;
    }
}

#pragma mark - View hierarchy

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        // Match the height of the superview's layoutMarginsGuide.
        // NOTE: This effectively makes the view 44pts high.
        [NSLayoutConstraint activateConstraints:@[
            [self.heightAnchor constraintEqualToAnchor:self.superview.layoutMarginsGuide.heightAnchor],
        ]];
    }
}

#pragma mark - Hit testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitTestView = [super hitTest:point withEvent:event];
    if (hitTestView == self && self.view) {
        hitTestView = self.view;
    }
    return hitTestView;
}

#pragma mark - View

- (void)setView:(UIView *)view
{
    UIView *previousView = _view;
    _view = view;
    
    if (previousView) {
        [previousView removeFromSuperview];
    }
    
    if (view) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        
        // Ensure badge indicator is above the view.
        [self bringSubviewToFront:self.badgeIndicatorView];
        
        [self setNeedsLoadConstraints];
    }
}

@end
