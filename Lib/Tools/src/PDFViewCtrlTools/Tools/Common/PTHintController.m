//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTHintController.h"

#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

@interface PTHintView : UIView

@property (nonatomic, strong) UIVisualEffectView *effectView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIStackView *labelStackView;

@end

@interface PTHintView ()

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

@implementation PTHintView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 20.0;
        self.layer.masksToBounds = YES;

        self.layoutMargins = UIEdgeInsetsMake(15, 15, 15, 15);
        
        // Effect view.
        UIBlurEffectStyle blurEffectStyle = UIBlurEffectStyleExtraLight;
        if (@available(iOS 13.0, *)) {
            blurEffectStyle = UIBlurEffectStyleSystemMaterial;
        }
        _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurEffectStyle]];
        _effectView.frame = self.bounds;
        
        _effectView.layer.cornerRadius = 20.0;
        _effectView.layer.masksToBounds = YES;
        
        [self addSubview:_effectView];
        
        _labelStackView = [[UIStackView alloc] init];
        _labelStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _labelStackView.axis = UILayoutConstraintAxisVertical;
        _labelStackView.alignment = UIStackViewAlignmentCenter;
        _labelStackView.distribution = UIStackViewDistributionFill;
        _labelStackView.spacing = 5.0;
        
        [self addSubview:_labelStackView];
        
        // Title label.
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:UIFont.systemFontSize];
        
        _titleLabel.numberOfLines = 1;
        
        _titleLabel.alpha = 0.8;
        
        [_labelStackView addArrangedSubview:_titleLabel];
        
        // Message label.
        _messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.font = [UIFont systemFontOfSize:UIFont.smallSystemFontSize];
        
        _messageLabel.numberOfLines = 2;
        
        _messageLabel.alpha = 0.8;
        
        [_labelStackView addArrangedSubview:_messageLabel];
        
        // Schedule constraints load.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.effectView.translatesAutoresizingMaskIntoConstraints = NO;
    self.labelStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutGuide = self.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.effectView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.effectView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.effectView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.effectView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [self.labelStackView.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor],
        [self.labelStackView.topAnchor constraintEqualToAnchor:layoutGuide.topAnchor],
        [self.labelStackView.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor],
        [self.labelStackView.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor],
    ]];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        // Constraints are loaded.
        self.constraintsLoaded = YES;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

@end

@interface PTHintViewController : UIViewController

@property (nonatomic, strong) PTHintView *hintView;

@property (nonatomic, assign) CGRect targetRect;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *message;

@property (nonatomic, assign) BOOL constraintsLoaded;

@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *targetRectConstraints;

@property (nonatomic, readonly, assign) BOOL needsUpdateTargetRectConstraints;
- (void)setNeedsUpdateTargetRectConstraints;

@end

@implementation PTHintViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = nil;
    
    self.hintView = [[PTHintView alloc] init];
    self.hintView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.hintView];
    
    // Schedule constraints load.
    [self.view setNeedsUpdateConstraints];
}

- (PTHintView *)hintView
{
    if (!_hintView) {
        [self loadViewIfNeeded];
        
        NSAssert(_hintView != nil,
                 @"Hint view failed to load");
    }
    return _hintView;
}

#pragma mark - Constraints

- (void)loadViewConstraints
{
    self.hintView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.hintView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.layoutMarginsGuide.widthAnchor],
        [self.hintView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.layoutMarginsGuide.heightAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.hintView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.hintView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ] withPriority:UILayoutPriorityDefaultLow];
}

- (void)updateTargetRectConstraints
{
    if (self.targetRectConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.targetRectConstraints];
        self.targetRectConstraints = nil;
    }
    
    // Determine the hint view's compressed size.
    CGSize hintViewMinSize = [self.hintView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    CGRect topRect = CGRectZero;
    CGRect bottomRect = CGRectZero;
    
    
    CGRectDivide(self.view.bounds, &topRect, &bottomRect, CGRectGetMinY(self.targetRect), CGRectMinYEdge);
    if (!CGRectIsEmpty(bottomRect)) {
        bottomRect = CGRectOffset(bottomRect, 0, CGRectGetHeight(self.targetRect));
    }
    
    if (CGRectGetHeight(topRect) > CGRectGetHeight(bottomRect) &&
        CGRectGetHeight(topRect) >= hintViewMinSize.height) {
        
        CGFloat bottomOffset = CGRectGetMaxY(topRect);
        
        self.targetRectConstraints = @[
            [self.hintView.bottomAnchor constraintEqualToAnchor:self.view.topAnchor constant:bottomOffset],
        ];
    }
    else if (CGRectGetHeight(bottomRect) >= hintViewMinSize.height) {
        
        CGFloat topOffset = CGRectGetMinY(bottomRect);
        
        self.targetRectConstraints = @[
            [self.hintView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:topOffset]
        ];
    }
    else {
        
        return;
    }
    
    if (self.targetRectConstraints.count > 0) {
        [NSLayoutConstraint activateConstraints:self.targetRectConstraints];
    }
}

- (void)updateViewConstraints
{
    // Load view constraints if needed.
    if (!self.constraintsLoaded) {
        [self loadViewConstraints];
        
        self.constraintsLoaded = YES;
    }
    
    // Update target rect constraints.
    if ([self needsUpdateTargetRectConstraints]) {
        [self updateTargetRectConstraints];
        
        _needsUpdateTargetRectConstraints = NO;
    }
    
    // Call super implementation as final step.
    [super updateViewConstraints];
}

#pragma mark - Target rect

- (void)setTargetRect:(CGRect)targetRect
{
    if (CGRectEqualToRect(targetRect, _targetRect)) {
        // No change.
        return;
    }
    
    _targetRect = targetRect;
    
    [self setNeedsUpdateTargetRectConstraints];
}

- (void)setNeedsUpdateTargetRectConstraints
{
    if (self.needsUpdateTargetRectConstraints) {
        return;
    }
    
    _needsUpdateTargetRectConstraints = YES;
    
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Title & message

@dynamic title;

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    self.hintView.titleLabel.text = title;
}

- (void)setMessage:(NSString *)message
{
    _message = message;
    
    self.hintView.messageLabel.text = message;
}

@end

NS_ASSUME_NONNULL_BEGIN

@interface PTHintController () {
    NSUInteger _activeWindowTransitionCount;
}

@property (nonatomic, strong, nullable) UIWindow *window;
@property (nonatomic, strong) PTHintViewController *viewController;

@property (nonatomic, assign, getter=isWindowHidden) BOOL windowHidden;

@end

NS_ASSUME_NONNULL_END

@implementation PTHintController

static PTHintController *PTHintController_sharedHintController;

+ (PTHintController *)sharedHintController
{
    if (!PTHintController_sharedHintController) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            PTHintController_sharedHintController = [[PTHintController alloc] init];
        });
    }
    return PTHintController_sharedHintController;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _windowHidden = YES;
    }
    return self;
}

- (PTHintViewController *)viewController
{
    if (!_viewController) {
        _viewController = [[PTHintViewController alloc] init];
    }
    return _viewController;
}

- (void)loadWindowIfNeeded
{
    if (self.window) {
        return;
    }
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.windowLevel = UIWindowLevelAlert;
    
    self.window.userInteractionEnabled = NO;
    
    self.window.rootViewController = self.viewController;
}

- (void)showFromView:(UIView *)view rect:(CGRect)targetRect
{
    [self showWithTitle:self.title message:self.message fromView:view rect:targetRect];
}

- (void)showWithTitle:(NSString *)title message:(NSString *)message fromView:(UIView *)view rect:(CGRect)targetRect
{
    // View must be attached to a window for coordinate conversions.
    if (!view.window) {
        NSString *reason = [NSString stringWithFormat:@"Cannot show %@ for view %@ not attached to window",
                            NSStringFromClass([self class]), view];
        
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    [self loadWindowIfNeeded];
    
    if (view.window.screen != self.window.screen) {
        
        return;
    }
    
    self.viewController.title = title;
    self.viewController.message = message;
    
    CGRect sourceWindowTargetRect = [view convertRect:targetRect toView:nil];
    CGRect destWindowTargetRect = CGRectIntersection(sourceWindowTargetRect, self.window.bounds);
    if (!CGRectIsNull(destWindowTargetRect)) {
        // Intersection is non-empty.
        self.viewController.targetRect = [self.viewController.view convertRect:sourceWindowTargetRect
                                                                      fromView:nil];
    } else {
        // Intersection is empty.
    }
    
    [self setWindowHidden:NO animated:YES];
}

- (void)hide
{
    [self setWindowHidden:YES animated:YES];
}

#pragma mark - Title & message

- (NSString *)title
{
    return self.viewController.title;
}

- (void)setTitle:(NSString *)title
{
    self.viewController.title = title;
}

- (NSString *)message
{
    return self.viewController.message;
}

- (void)setMessage:(NSString *)message
{
    self.viewController.message = message;
}

#pragma mark - visible

- (BOOL)isVisible
{
    return ![self isWindowHidden];
}

#pragma mark - windowHidden

- (void)setWindowHidden:(BOOL)hidden
{
    [self setWindowHidden:hidden animated:NO];
}

- (void)setWindowHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (hidden == _windowHidden) {
        // No change.
        return;
    }
    
    _windowHidden = hidden;
    
    if (_activeWindowTransitionCount == 0) {
        // Animation pre-amble.
        if (hidden) {
            // No pre-amble.
        } else {
            self.window.hidden = NO;
        }
    }
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.window.alpha = (hidden) ? 0.0 : 1.0;
    } completion:^(BOOL finished) {
        self->_activeWindowTransitionCount--;
        
        if (self->_activeWindowTransitionCount == 0) {
            // Animation post-amble.
            if ([self isWindowHidden]) {
                self.window.hidden = YES;
            } else {
                // No post-amble.
            }
        }
    }];
    
    _activeWindowTransitionCount++;
}

@end
