//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolGroupIndicatorView.h"

#import "PTToolsUtil.h"

#import "NSLayoutConstraint+PTPriority.h"
#import "UIButton+PTAdditions.h"
#import "UIView+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTToolGroupIndicatorView ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, assign) BOOL constraintsLoaded;
@property (nonatomic) BOOL needsNavigationBarConstraints;

@end

NS_ASSUME_NONNULL_END

@implementation PTToolGroupIndicatorView

- (void)PTToolGroupView_commonInit
{
    _stackView = [[UIStackView alloc] init];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _stackView.axis = UILayoutConstraintAxisHorizontal;
    _stackView.alignment = UIStackViewAlignmentFill;
    _stackView.distribution = UIStackViewDistributionFill;
    
    [self addSubview:_stackView];
    
    _button = [UIButton buttonWithType:UIButtonTypeSystem];
    _button.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Image.
    UIImage *image = nil;
    if (@available(iOS 13.0, *)) {
        UIImageConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:12
                                                                                              weight:UIImageSymbolWeightBold];
        image = [UIImage systemImageNamed:@"chevron.down" withConfiguration:configuration];
    } else {
        image = [PTToolsUtil toolImageNamed:@"ic_arrow_drop_down_black_24dp"];
    }
    [_button setImage:image forState:UIControlStateNormal];
    
    _button.titleLabel.font = [UIFont boldSystemFontOfSize:UIFont.labelFontSize];
    
    // Force the image to appear on the right of the title.
    _button.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    
    // NOTE: the button's semanticContentAttribute must be set before insets.
    const CGFloat titleImageSpacing = 4.0;
    [_button pt_setInsetsForContentPadding:UIEdgeInsetsMake(0, 10, 0, 10)
                         imageTitleSpacing:titleImageSpacing];
        
    if (@available(iOS 13.0, *)) {
        _button.showsLargeContentViewer = YES;
        [_button addInteraction:[[UILargeContentViewerInteraction alloc] init]];
    }
    
    [_stackView addArrangedSubview:_button];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTToolGroupView_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTToolGroupView_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        // Pin stack view to superview vertically.
        [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        // Stack view is only as wide as necessary.
        [self.stackView.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        // Center stack view in superview.
        [self.stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    ] withPriority:UILayoutPriorityDefaultLow];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        // Stack view is as small as possible. Required by the <= width constraint.
        [self.stackView.widthAnchor constraintEqualToConstant:UILayoutFittingCompressedSize.width],
    ] withPriority:UILayoutPriorityFittingSizeLevel];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (CGSize)intrinsicContentSize
{
    // Required for use as a UINavigationItem.titleView.
    // Otherwise, the view will not adjust its width for the "intrinsic" intrinsicContentSize.
    return UILayoutFittingExpandedSize;
}

#pragma mark - Lifecycle

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    self.needsNavigationBarConstraints = YES;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        [self beginObservingToolGroupManager:self.toolGroupManager];
        
        if (self.needsNavigationBarConstraints) {
            // Center stack view in containing navigation bar.
            // This is necessary when the left and right bar button items in the navigation bar do
            // not take up the same amount of space. This view exands to fill all the available space
            // in the navigation bar, so centering the stack view within this view does not necessarily
            // center it in the navigation bar.
            UINavigationBar *navigationBar = [self pt_ancestorOfKindOfClass:[UINavigationBar class]];
            if (navigationBar) {
                // Constrain with a higher priority than the horizontal-centering constraint for the
                // stackView-view, in -loadConstraints, to ensure that this constraint takes precedence.
                [NSLayoutConstraint pt_activateConstraints:@[
                    [self.stackView.centerXAnchor constraintEqualToAnchor:navigationBar.centerXAnchor],
                ] withPriority:UILayoutPriorityDefaultHigh];
            }
            self.needsNavigationBarConstraints = NO;
        }
    } else {
        [self endObservingToolGroupManager:self.toolGroupManager];
    }
}

#pragma mark - Annotation mode manager

- (void)setToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    PTToolGroupManager *previousToolGroupManager = _toolGroupManager;
    
    _toolGroupManager = toolGroupManager;
    
    if (self.window) {
        [self endObservingToolGroupManager:previousToolGroupManager];
        [self beginObservingToolGroupManager:toolGroupManager];
    }
    
    [self updateTitle];
}

- (void)beginObservingToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    if (!toolGroupManager) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(selectedGroupDidChangeWithNotification:)
                                               name:PTToolGroupDidChangeNotification
                                             object:toolGroupManager];
}

- (void)endObservingToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    if (!toolGroupManager) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTToolGroupDidChangeNotification
                                                object:toolGroupManager];
}

- (void)selectedGroupDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolGroupManager) {
        return;
    }
    
    [self updateTitle];
}

- (void)updateTitle
{
    PTToolGroup *group = self.toolGroupManager.selectedGroup;
    
    [UIView performWithoutAnimation:^{
        [self.button setTitle:group.title
                     forState:UIControlStateNormal];
        [self.button layoutIfNeeded];
    }];
    
    if (@available(iOS 13.0, *)) {
        self.button.largeContentImage = group.image;
    }
}

@end
