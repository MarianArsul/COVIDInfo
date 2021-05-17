//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolGroupToolbar.h"

#import "PTFadingScrollView.h"
#import "PTToolbarContentView.h"
#import "PTToolGroupDefaultsViewController.h"
#import "PTToolBarButtonItem.h"
#import "PTAnnotationStyleManager.h"
#import "PTPopoverNavigationController.h"

#import "PTPanTool.h"
#import "PTCreateToolBase.h"
#import "PTFreeTextCreate.h"
#import "PTFreehandCreate.h"
#import "PTFreeHandHighlightCreate.h"
#import "PTSmartPen.h"

#import "PTToolsUtil.h"
#import "PTKeyValueObserving.h"

#import "NSArray+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "UIView+PTAdditions.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTToolGroupToolbar () <PTAnnotationStylePresetsViewDelegate>

@property (nonatomic, readonly, weak, nullable) PTToolManager *toolManager;

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, strong) PTFadingScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentContainerView;

@property (nonatomic, strong) PTToolbarContentView *leadingContentView;
@property (nonatomic, strong) PTToolbarContentView *scrollContentView;
@property (nonatomic, strong) PTToolbarContentView *trailingContentView;

@property (nonatomic) UIView *leadingSeparatorView;
@property (nonatomic) UIView *trailingSeparatorView;

@property (nonatomic, strong) PTToolbarContentView *editContentView;
@property (nonatomic, assign) NSUInteger activeEditViewTransitionCount;

@property (nonatomic, strong) UIView *shadowView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@property (nonatomic, strong, nullable) NSArray<NSLayoutConstraint *> *presetsToolbarHiddenConstraints;
@property (nonatomic, assign) NSUInteger activePresetsToolbarTransitionCount;

@property (nonatomic) BOOL alwaysShowPresetsView;
@property (nonatomic) UILabel *presetsEmptyView;

@end

NS_ASSUME_NONNULL_END

@implementation PTToolGroupToolbar

+ (void)load
{
    // Customize default appearance.
    PTToolGroupToolbar *appearance = [PTToolGroupToolbar appearance];
    
    // Default backgroundColor.
    if (@available(iOS 13.0, *)) {
        appearance.backgroundColor = UIColor.secondarySystemBackgroundColor;
    } else {
        appearance.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    }
    
    // Default itemTintColor.
    if (@available(iOS 13.0, *)) {
        appearance.itemTintColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            switch (traitCollection.userInterfaceStyle) {
                case UIUserInterfaceStyleDark:
                    return UIColor.whiteColor;
                case UIUserInterfaceStyleLight:
                default:
                    return UIColor.darkGrayColor;
            }
        }];
    } else {
        appearance.itemTintColor = UIColor.darkGrayColor;
    }
}

- (void)PTToolGroupToolbar_commonInit
{
    // Set default horizontal layout margins.
    // NOTE: Vertical layout margins can cause a layout feedback loop.
    self.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8);
    
    _presetsToolbarHidden = YES;
    _presetsViewHidden = YES;
    _editViewHidden = YES;
    
    _alwaysShowPresetsView = YES;
     
    // Stack view.
    _stackView = ({
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 10;
        
        stackView.preservesSuperviewLayoutMargins = YES;
        
        (stackView);
    });
    [self addSubview:_stackView];
    
    // Leading content view.
    _leadingContentView = ({
        PTToolbarContentView *contentView = [[PTToolbarContentView alloc] init];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 11.0, *)) {
            contentView.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0, 8, 0, 0);
        } else {
            contentView.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 0);
        }
        contentView.preservesSuperviewLayoutMargins = YES;
        
        (contentView);
    });
    _leadingContentView.accessibilityIdentifier = PT_SELF_KEY(leadingContentView);
    [_stackView addArrangedSubview:_leadingContentView];
    
    // Hide by default.
    _leadingContentView.hidden = YES;
    
    // Leading separator view.
    _leadingSeparatorView = ({
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIView *separator = [[UIView alloc] init];
        separator.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 13.0, *)) {
            separator.backgroundColor = UIColor.separatorColor;
        } else {
            separator.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        }
        
        [view addSubview:separator];
        
        [NSLayoutConstraint activateConstraints:@[
            [separator.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
            [separator.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
            [separator.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
            [separator.widthAnchor constraintEqualToConstant:1],
            [separator.heightAnchor constraintLessThanOrEqualToAnchor:view.heightAnchor],
        ]];
        
        [NSLayoutConstraint pt_activateConstraints:@[
            [separator.heightAnchor constraintEqualToConstant:24],
        ] withPriority:UILayoutPriorityDefaultHigh];
        
        (view);
    });
    [_stackView addArrangedSubview:_leadingSeparatorView];
    
    _leadingSeparatorView.hidden = YES;
    
    // Scroll view.
    _scrollView = ({
        PTFadingScrollView *scrollView = [[PTFadingScrollView alloc] init];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        
        scrollView.layoutMargins = UIEdgeInsetsZero;
        scrollView.preservesSuperviewLayoutMargins = YES;
        
        (scrollView);
    });
    _scrollView.accessibilityIdentifier = PT_SELF_KEY(scrollView);
    [_stackView addArrangedSubview:_scrollView];
    
    _scrollContentContainerView = ({
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.layoutMargins = UIEdgeInsetsZero;
        view.preservesSuperviewLayoutMargins = YES;
        
        (view);
    });
    _scrollContentContainerView.accessibilityIdentifier = PT_SELF_KEY(scrollContentContainerView);
    [_scrollView addSubview:_scrollContentContainerView];
    
    _scrollContentView = ({
        PTToolbarContentView *contentView = [[PTToolbarContentView alloc] init];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;

        contentView.stackView.distribution = UIStackViewDistributionEqualSpacing;

        contentView.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8);
        contentView.preservesSuperviewLayoutMargins = YES;
        
        (contentView);
    });
    _scrollContentView.accessibilityIdentifier = PT_SELF_KEY(scrollContentView);
    [_scrollContentContainerView addSubview:_scrollContentView];
    
    // Trailing separator view.
    _trailingSeparatorView = ({
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIView *separator = [[UIView alloc] init];
        separator.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 13.0, *)) {
            separator.backgroundColor = UIColor.separatorColor;
        } else {
            separator.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        }
        
        [view addSubview:separator];
        
        [NSLayoutConstraint activateConstraints:@[
            [separator.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
            [separator.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
            [separator.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
            [separator.widthAnchor constraintEqualToConstant:1],
            [separator.heightAnchor constraintLessThanOrEqualToAnchor:view.heightAnchor],
        ]];
        
        [NSLayoutConstraint pt_activateConstraints:@[
            [separator.heightAnchor constraintEqualToConstant:24],
        ] withPriority:UILayoutPriorityDefaultHigh];
        
        (view);
    });
    [_stackView addArrangedSubview:_trailingSeparatorView];
    
    _trailingSeparatorView.hidden = YES;
    
    // Presets view.
    _presetsView = ({
        PTAnnotationStylePresetsView *view = [[PTAnnotationStylePresetsView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.delegate = self;
        
        // Provide default presets to ensure view has a non-empty layout.
        // Necessary for "always show presets view".
        view.presets = [PTAnnotationStyleManager.defaultManager stylePresetsForAnnotationType:PTExtendedAnnotTypeSquare];
        
        (view);
    });
    [_stackView addArrangedSubview:_presetsView];
    
    _presetsView.hidden = _presetsViewHidden;
    
    _presetsEmptyView = ({
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        label.font = [UIFont systemFontOfSize:UIFont.systemFontSize];
        
        label.textColor = UIColor.systemGrayColor;
        
        label.text = PTLocalizedString(@"No Presets",
                                       @"No Presets label");
        
        (label);
    });
    [_presetsView addSubview:_presetsEmptyView];
    
    if (_alwaysShowPresetsView) {
        _presetsEmptyView.hidden = NO;
    } else {
        _presetsEmptyView.hidden = YES;
    }
    
    // Trailing content view.
    _trailingContentView = ({
        PTToolbarContentView *contentView = [[PTToolbarContentView alloc] init];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 11.0, *)) {
            contentView.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0, 0, 0, 8);
        } else {
            contentView.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 8);
        }
        contentView.preservesSuperviewLayoutMargins = YES;
        
        (contentView);
    });
    _trailingContentView.accessibilityIdentifier = PT_SELF_KEY(trailingContentView);
    [_stackView addArrangedSubview:_trailingContentView];
    
    // Hide by default.
    _trailingContentView.hidden = YES;
    
    // Edit view.
    _editContentView = ({
        PTToolbarContentView *contentView = [[PTToolbarContentView alloc] init];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        contentView.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8);
        contentView.preservesSuperviewLayoutMargins = YES;
        
        (contentView);
    });
    _editContentView.accessibilityIdentifier = PT_SELF_KEY(editContentView);
    [self addSubview:_editContentView];
    
    _editContentView.hidden = _editViewHidden;
    _editContentView.alpha = (_editViewHidden) ? 0.0 : 1.0;
        
    UIBarButtonItem *editDoneButtonItem = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        
        [button setTitle:PTLocalizedString(@"Done",
                                           @"Done button title")
                forState:UIControlStateNormal];
        
        button.titleLabel.font = [UIFont boldSystemFontOfSize:UIFont.buttonFontSize];
        
        [button addTarget:self
                   action:@selector(commitAnnotation:)
         forControlEvents:UIControlEventPrimaryActionTriggered];

        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
        
        item.image = [button imageForState:UIControlStateNormal];
        item.title = [button titleForState:UIControlStateNormal];
        
        (item);
    });
    _editContentView.items = @[
        editDoneButtonItem,
        [UIBarButtonItem pt_flexibleSpaceItem],
    ];

    // Shadow view.
    _shadowView = [[UIView alloc] init];
    _shadowView.translatesAutoresizingMaskIntoConstraints = NO;

    if (@available(iOS 13.0, *)) {
        _shadowView.backgroundColor = UIColor.opaqueSeparatorColor;
    } else {
        _shadowView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    }

    [self addSubview:_shadowView];
    
    _presetsToolbarEnabled = YES;
    _presetsToolbarHidden = YES;
    
    [self setContentHuggingPriority:UILayoutPriorityDefaultHigh
                            forAxis:UILayoutConstraintAxisVertical];
    [self setContentCompressionResistancePriority:(UILayoutPriorityDefaultHigh + 1)
                                          forAxis:UILayoutConstraintAxisVertical];
    
    // Add large content viewer interaction to this view.
    // NOTE: If an interaction is added for each button, it is not possible to view more than
    // one different item in the large content viewer during the same (long-press) gesture.
    if (@available(iOS 13.0, *)) {
        [self addInteraction:[[UILargeContentViewerInteraction alloc] init]];
    }
}

- (instancetype)initWithToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    // Fill screen width by default.
    // NOTE: A layout feedback loop can occur without this default size.
    const CGFloat width = CGRectGetWidth(UIScreen.mainScreen.bounds);
    self = [self initWithFrame:CGRectMake(0, 0, width, 44.0)];
    if (self) {
        _toolGroupManager = toolGroupManager;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTToolGroupToolbar_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTToolGroupToolbar_commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self pt_removeAllObservations];
}

#pragma mark - Constraints

- (void)loadConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        
        // NOTE: A layout feedback loop can occur without this constraint.
        [self.heightAnchor constraintEqualToConstant:44.0],
        
        [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        
        // Pin the container view's edges to the scroll view's interior edges.
        [self.scrollContentContainerView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.scrollContentContainerView.leftAnchor constraintEqualToAnchor:self.scrollView.leftAnchor],
        [self.scrollContentContainerView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.scrollContentContainerView.rightAnchor constraintEqualToAnchor:self.scrollView.rightAnchor],
        // Container view width is at least as large as the scroll view's frame.
        [self.scrollContentContainerView.widthAnchor constraintGreaterThanOrEqualToAnchor:self.scrollView.widthAnchor],
        
        // Center content view horizontally in container view, filling the entire height.
        [self.scrollContentView.leadingAnchor constraintEqualToAnchor:self.scrollContentContainerView.leadingAnchor],
        [self.scrollContentView.topAnchor constraintEqualToAnchor:self.scrollContentContainerView.topAnchor],
        [self.scrollContentView.bottomAnchor constraintEqualToAnchor:self.scrollContentContainerView.bottomAnchor],
        
        // Content view width is at most as large as the container view. This is required for alignment
        // when the content view does not fill the container view.
        [self.scrollContentView.widthAnchor constraintLessThanOrEqualToAnchor:self.scrollContentContainerView.widthAnchor],
        
        // Container view fills the scroll view vertically.
        [self.scrollContentContainerView.heightAnchor constraintEqualToAnchor:self.scrollView.heightAnchor],
        
        [self.presetsEmptyView.centerXAnchor constraintEqualToAnchor:self.presetsView.centerXAnchor],
        [self.presetsEmptyView.centerYAnchor constraintEqualToAnchor:self.presetsView.centerYAnchor],
        [self.presetsEmptyView.widthAnchor constraintLessThanOrEqualToAnchor:self.presetsView.widthAnchor],
        [self.presetsEmptyView.heightAnchor constraintLessThanOrEqualToAnchor:self.presetsView.heightAnchor],
        
        [self.editContentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.editContentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.editContentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.editContentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        
        [self.shadowView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.shadowView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.shadowView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.shadowView.heightAnchor constraintEqualToConstant:(1 / UIScreen.mainScreen.nativeScale)],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        // Make the leading/trailing views as small as possible.
        // Required by the <= width constraints.
        [self.leadingContentView.widthAnchor constraintEqualToConstant:0],
        [self.trailingContentView.widthAnchor constraintEqualToConstant:0],
    ] withPriority:UILayoutPriorityDefaultLow];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        // Make the container view as small as possible. Required by the >= width constraint.
        [self.scrollContentContainerView.widthAnchor constraintEqualToConstant:0],
        [self.scrollContentContainerView.heightAnchor constraintEqualToConstant:0],

        // Make the content view as small as possible. Required by the <= width constraint.
        [self.scrollContentView.widthAnchor constraintEqualToConstant:0],
        [self.scrollContentView.heightAnchor constraintEqualToConstant:0],
        
        // Make the empty presets view as small as possible. Required by the <= width constraint.
        [self.presetsEmptyView.widthAnchor constraintEqualToConstant:0],
        [self.presetsEmptyView.heightAnchor constraintEqualToConstant:0],
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
    return CGSizeMake(UIViewNoIntrinsicMetric, 44.0);
}

#pragma mark - Lifecycle

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        self.toolGroupManager.enabled = YES;
        [self updateItemsForToolGroupManager:self.toolGroupManager];
        
        [self beginObservingToolGroupManager:self.toolGroupManager];
        
        // Show presets toolbar if necessary.
        [self updatePresetsToolbar];
    } else {
        // Since the presets toolbar is attached to a different view we need to
        // manually remove/detach the toolbar.
        [self setPresetsToolbarHidden:YES animated:YES];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (!self.window) {
        self.toolGroupManager.enabled = NO;

        [self endObservingToolGroupManager:self.toolGroupManager];
    }
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    // The following items' tint color use the normal inherited tint color
    // of this view, not t heir direct superview's (which could be a non-"button" color).
    NSArray<UIBarButtonItem *> *items = @[
        self.toolGroupManager.editGroupButtonItem,
        self.toolGroupManager.addFavoriteToolButtonItem,
    ];
    for (UIBarButtonItem *item in items) {
        item.tintColor = self.tintColor;
        item.customView.tintColor = self.tintColor;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updatePresetsForTraitCollection:self.traitCollection];
}

- (void)updatePresetsForTraitCollection:(UITraitCollection *)traitCollection
{
    const BOOL presetsHidden = (([self isPresetsViewHidden]
                                 || [self.presetsView.contentView isHidden]) &&
                                [self isPresetsToolbarHidden]);
    
    switch (traitCollection.horizontalSizeClass) {
        case UIUserInterfaceSizeClassCompact:
        case UIUserInterfaceSizeClassUnspecified:
            self.presetsViewHidden = YES;
            self.presetsToolbarHidden = presetsHidden;
            break;
        case UIUserInterfaceSizeClassRegular:
            self.presetsToolbarHidden = YES;
            if (self.alwaysShowPresetsView) {
                self.presetsViewHidden = NO;
                self.presetsView.contentView.hidden = presetsHidden;
                self.presetsEmptyView.hidden = !presetsHidden;
            } else {
                self.presetsViewHidden = presetsHidden;
                self.presetsEmptyView.hidden = YES;
            }
            break;
    }
}

- (void)setNeedsLayout
{
    [super setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

#pragma mark - Content view

- (void)scrollContentViewIfNeededForTool:(PTTool *)tool
{
    PTToolBarButtonItem *matchingToolItem = nil;
    
    for (UIBarButtonItem *item in self.items) {
        if ([item isKindOfClass:[PTToolBarButtonItem class]]) {
            PTToolBarButtonItem *toolItem = (PTToolBarButtonItem *)item;
            
            if ([toolItem.toolClass isEqual:[tool class]] &&
                ((tool.identifier.length == 0)
                 || [toolItem.identifier isEqual:tool.identifier])) {
                matchingToolItem = toolItem;
                break;
            }
        }
    }
    
    if (!matchingToolItem || !matchingToolItem.customView) {
        return;
    }
    
    UIView *toolItemView = matchingToolItem.customView;
    CGRect toolItemRect = [self.scrollView convertRect:toolItemView.bounds
                                              fromView:toolItemView];
    
    const CGRect scrollViewPort = [self.scrollView convertRect:self.scrollView.frame
                                                      fromView:self.scrollView.superview];
    const CGRect insetScrollViewPort = UIEdgeInsetsInsetRect(scrollViewPort,
                                                             self.scrollView.fadingInsets);
    
    if (CGRectGetMinX(toolItemRect) < CGRectGetMinX(insetScrollViewPort)) {
        toolItemRect.origin.x -= CGRectGetMinX(insetScrollViewPort) - CGRectGetMinX(toolItemRect);
    }
    else if (CGRectGetMaxX(toolItemRect) > CGRectGetMaxX(insetScrollViewPort)) {
        toolItemRect.origin.x += CGRectGetMaxX(toolItemRect) - CGRectGetMaxX(insetScrollViewPort);
    }
    if (CGRectGetMinY(toolItemRect) < CGRectGetMinY(insetScrollViewPort)) {
        toolItemRect.origin.y -= CGRectGetMinY(insetScrollViewPort) - CGRectGetMinY(toolItemRect);
    }
    else if (CGRectGetMaxY(toolItemRect) > CGRectGetMaxY(insetScrollViewPort)) {
        toolItemRect.origin.y += CGRectGetMaxY(toolItemRect) - CGRectGetMaxY(insetScrollViewPort);
    }
    
    [self.scrollView scrollRectToVisible:toolItemRect animated:YES];
}

#pragma mark - Items

- (void)setItems:(NSArray<UIBarButtonItem *> *)items
{
    NSArray<UIBarButtonItem *> *previousItems = _items;
    if (previousItems &&
        [items isEqualToArray:previousItems]) {
        // No change.
        return;
    }
    
    _items = [items copy]; // @property (copy) semantics.
    
    self.scrollContentView.items = items;
}

- (void)setLeadingItems:(NSArray<UIBarButtonItem *> *)leadingItems
{
    NSArray<UIBarButtonItem *> *previousLeadingItems = _leadingItems;
    if (previousLeadingItems &&
        [leadingItems isEqualToArray:previousLeadingItems]) {
        // No change.
        return;
    }
    
    _leadingItems = [leadingItems copy]; // @property (copy) semantics.

    self.leadingContentView.items = leadingItems;
    self.leadingContentView.hidden = (leadingItems.count == 0);
    self.leadingSeparatorView.hidden = self.leadingContentView.hidden;
}

- (void)setTrailingItems:(NSArray<UIBarButtonItem *> *)trailingItems
{
    NSArray<UIBarButtonItem *> *previousTrailingItems = _trailingItems;
    if (previousTrailingItems &&
        [trailingItems isEqualToArray:previousTrailingItems]) {
        // No change.
        return;
    }
    
    _trailingItems = [trailingItems copy]; // @property (copy) semantics.
    
    self.trailingContentView.items = trailingItems;
    self.trailingContentView.hidden = (trailingItems.count == 0);
    self.trailingSeparatorView.hidden = self.trailingContentView.hidden;
}

#pragma mark - Item tint color

- (void)setItemTintColor:(UIColor *)itemTintColor
{
    _itemTintColor = itemTintColor;
    
    self.scrollContentView.tintColor = itemTintColor;
}

#pragma mark - Annotation mode manager

- (void)setToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    PTToolGroupManager *previousToolGroupManager = _toolGroupManager;
    _toolGroupManager = toolGroupManager;
    
    if (self.window) {
        if (previousToolGroupManager) {
            [self endObservingToolGroupManager:previousToolGroupManager];
        }
        if (toolGroupManager) {
            [self beginObservingToolGroupManager:toolGroupManager];
        }
    }
    
    self.presetsToolbar.toolManager = toolGroupManager.toolManager;
}

- (void)updateItemsForToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    PTToolGroup *selectedGroup = toolGroupManager.selectedGroup;
    NSMutableArray<UIBarButtonItem *> *items = [selectedGroup.barButtonItems mutableCopy];
    
    if (toolGroupManager.toolManager) {
        // Filter out disabled annotation tool items.
        items = [[items pt_objectsPassingTest:^BOOL(UIBarButtonItem *item, NSUInteger index, BOOL *stop) {
            if ([item isKindOfClass:[PTToolBarButtonItem class]]) {
                PTToolBarButtonItem *toolItem = (PTToolBarButtonItem *)item;
                
                // Only creation tools, which return YES from +createsAnnotation, should be checked.
                Class toolClass = toolItem.toolClass;
                if ([toolClass isSubclassOfClass:[PTTool class]]
                    && [toolClass createsAnnotation]) {
                    const PTExtendedAnnotType annotType = [toolClass annotType];
                    
                    if (![toolGroupManager.toolManager canCreateExtendedAnnotType:annotType]) {
                        return NO;
                    }
                }
            }
            return YES;
        }] mutableCopy];
    }
    
    if (toolGroupManager &&
        selectedGroup != toolGroupManager.viewItemGroup) {
        // Add the "Add Tool" item for favorite groups.
        if ([selectedGroup isFavorite]) {
            UIBarButtonItem *favoriteItem = toolGroupManager.addFavoriteToolButtonItem;
            if ([favoriteItem.customView isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)favoriteItem.customView;
                if (items.count > 0) {
                    [button setTitle:nil forState:UIControlStateNormal];
                } else {
                    [button setTitle:favoriteItem.title forState:UIControlStateNormal];
                }
            }
            [items addObject:favoriteItem];
        } else if ([toolGroupManager isEditingEnabled]){
            // Add the edit-group item to the end.
            [items addObjectsFromArray:@[
                toolGroupManager.editGroupButtonItem,
            ]];
        }
    }
    
    self.items = [items copy];
    
    [self updateTrailingItemsForToolGroupManager:toolGroupManager];
}

- (void)updateTrailingItemsForToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    NSMutableArray<UIBarButtonItem *> *trailingItems = [NSMutableArray array];
    if ([toolGroupManager.undoManager isUndoRegistrationEnabled]) {
        [trailingItems addObjectsFromArray:@[
            toolGroupManager.undoButtonItem,
            toolGroupManager.redoButtonItem,
        ]];
    }
    self.trailingItems = [trailingItems copy];
}

#pragma mark Notifications

- (void)beginObservingToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    if (!toolGroupManager) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self
               selector:@selector(toolGroupDidChange:)
                   name:PTToolGroupDidChangeNotification
                 object:toolGroupManager];
    
    [self pt_observeObject:toolGroupManager
                forKeyPath:PT_KEY(toolGroupManager, editingEnabled)
                  selector:@selector(toolGroupEditingEnabledDidChange:)];
    
    [self pt_observeObject:toolGroupManager
                forKeyPath:PT_KEY(toolGroupManager, annotStylePresets)
                  selector:@selector(annotationStylePresetsDidChange:)];
    
    [self pt_observeObject:toolGroupManager
                forKeyPath:PT_KEY_PATH(toolGroupManager, selectedGroup.barButtonItems)
                  selector:@selector(selectedGroupItemsDidChange:)
                   options:(NSKeyValueObservingOptionOld |
                            NSKeyValueObservingOptionNew)];
    
    [self beginObservingToolManager:toolGroupManager.toolManager];
}

- (void)endObservingToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    if (!toolGroupManager) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self
                      name:PTToolGroupDidChangeNotification
                    object:toolGroupManager];
    
    [self pt_removeObservationsForObject:toolGroupManager
                                 keyPath:PT_KEY(toolGroupManager, editingEnabled)];
    
    [self pt_removeObservationsForObject:toolGroupManager
                                 keyPath:PT_KEY(toolGroupManager, annotStylePresets)];
    
    [self pt_removeObservationsForObject:toolGroupManager
                                 keyPath:PT_KEY_PATH(toolGroupManager, selectedGroup.barButtonItems)];
    
    [self endObservingToolManager:toolGroupManager.toolManager];
}

- (void)toolGroupDidChange:(NSNotification *)notification
{
    if (notification.object != self.toolGroupManager) {
        return;
    }
    
    [self updateItemsForToolGroupManager:self.toolGroupManager];
    
    // Scroll to beginning when mode changes.
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

- (void)toolGroupEditingEnabledDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.toolGroupManager) {
        return;
    }

    [self updateItemsForToolGroupManager:self.toolGroupManager];
}

- (void)annotationStylePresetsDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.toolGroupManager) {
        return;
    }
    
    [self updatePresetsToolbar];
}

- (void)selectedGroupItemsDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.toolGroupManager) {
        return;
    }
    
    if (change.oldValue || change.newValue) {
        if ([change.oldValue isEqual:change.newValue]) {
            // No change.
            return;
        }
    }
    
    [self updateItemsForToolGroupManager:self.toolGroupManager];
}

#pragma mark - Tool manager

- (PTToolManager *)toolManager
{
    return self.toolGroupManager.toolManager;
}

- (void)beginObservingToolManager:(PTToolManager *)toolManager
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(toolManagerToolDidChange:)
                   name:PTToolManagerToolDidChangeNotification
                 object:toolManager];
    [center addObserver:self
               selector:@selector(toolManagerAnnotationOptionsDidChange:)
                   name:PTToolManagerAnnotationOptionsDidChangeNotification
                 object:toolManager];
}

- (void)endObservingToolManager:(PTToolManager *)toolManager
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center removeObserver:self
                      name:PTToolManagerToolDidChangeNotification
                    object:toolManager];
    [center removeObserver:self
                      name:PTToolManagerAnnotationOptionsDidChangeNotification
                    object:toolManager];
}

#pragma mark Notifications

- (void)toolManagerToolDidChange:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self updateTrailingItemsForToolGroupManager:self.toolGroupManager];
    [self scrollContentViewIfNeededForTool:self.toolManager.tool];
    [self updatePresetsToolbar];
    [self updateEditView];
}

- (void)toolManagerAnnotationOptionsDidChange:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }

    [self updateItemsForToolGroupManager:self.toolGroupManager];
}

#pragma mark - Presenting view controller

- (nullable UIViewController *)viewControllerForPresentations
{
    if ([self.delegate respondsToSelector:@selector(viewControllerForPresentationsFromToolGroupToolbar:)]) {
        return [self.delegate viewControllerForPresentationsFromToolGroupToolbar:self];
    }

    return nil;
}

- (nullable UIView *)viewForOverlays
{
    if ([self.delegate respondsToSelector:@selector(viewForOverlaysFromToolGroupToolbar:)]) {
        return [self.delegate viewForOverlaysFromToolGroupToolbar:self];
    }

    return [self viewControllerForPresentations].view;
}

#pragma mark - Annotation style presets toolbar

@synthesize presetsToolbar = _presetsToolbar;

- (PTAnnotStyleToolbar *)presetsToolbar
{
    if (!_presetsToolbar) {
        _presetsToolbar = [[PTAnnotStyleToolbar alloc] initWithFrame:UIScreen.mainScreen.bounds];
        _presetsToolbar.delegate = self;
        
        _presetsToolbar.toolManager = self.toolManager;
    }
    return _presetsToolbar;
}

- (void)updatePresetsToolbar
{
    PTTool *tool = self.toolManager.tool;
    
    BOOL presetsToolbarHidden = (([self isPresetsViewHidden]
                                  || [self.presetsView.contentView isHidden]) &&
                                 [self isPresetsToolbarHidden]);
    
    // Don't update toolbar state with a non-creation tool,
    // other than the pan tool.
    // When in continuous tool group, don't update the toolbar state, as
    // the next tool should be a creation tool.
    // This prevents the toolbar from being hidden when a newly created
    // annotation is selected (by PTAnnotEditTool, etc.).
    if ([tool isKindOfClass:[PTPanTool class]] ||
        tool.createsAnnotation ||
        tool.backToPanToolAfterUse) {
        // Show the annotation style presets toolbar for tools that have editable styles.
        presetsToolbarHidden = !tool.canEditStyle;
    }
    
    PTAnnotationStylePresetsGroup *presets = nil;
    
    // Update annotation style presets when visible.
    if (!presetsToolbarHidden) {
        if ([tool isKindOfClass:[PTSmartPen class]]) {
            presets = ((PTSmartPen *)tool).annotationStylePresets;
        } else {
            presets = self.toolGroupManager.annotStylePresets;
        }
        
        self.presetsToolbar.annotStylePresets = presets;
    }
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        if (!presetsToolbarHidden) {
            self.presetsView.presets = presets;
        }
        if (self.alwaysShowPresetsView) {
            [self setPresetsViewHidden:NO animated:YES];
            self.presetsView.contentView.hidden = presetsToolbarHidden;
            self.presetsEmptyView.hidden = !presetsToolbarHidden;
        } else {
            [self setPresetsViewHidden:presetsToolbarHidden animated:YES];
            self.presetsEmptyView.hidden = YES;
        }
        [self setPresetsToolbarHidden:YES animated:YES];
    } else {
        [self setPresetsViewHidden:YES animated:YES];
        [self setPresetsToolbarHidden:presetsToolbarHidden animated:YES];
    }
}

- (void)attachPresetsToolbar
{
    if (self.presetsToolbar.superview) {
        // Already attached.
        return;
    }
        
    UIView *view = [self viewForOverlays];
    if (!view) {
        UIViewController *viewController = self.pt_viewController;
        
        // Use the view controller's navigationController, if available.
        if (![viewController isKindOfClass:[UINavigationController class]] &&
            viewController.navigationController) {
            viewController = viewController.navigationController;
        }
        view = viewController.view;
    }
    
    NSAssert(view != nil,
             @"Failed to get view for attaching presets toolbar");
    
    self.presetsToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    
    [view addSubview:self.presetsToolbar];

    [self loadPresetsToolbarConstraints];
}

- (void)loadPresetsToolbarConstraints
{
    UIView *superview = self.presetsToolbar.superview;
    NSAssert(superview != nil, @"Presets toolbar must have a superview");
    if (!superview) {
        return;
    }
    
    self.presetsToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Onscreen/offscreen constraints.
    [NSLayoutConstraint activateConstraints:@[
        [self.presetsToolbar.leftAnchor constraintEqualToAnchor:superview.leftAnchor],
        [self.presetsToolbar.rightAnchor constraintEqualToAnchor:superview.rightAnchor],
        /* Use PTAnnotStyleToolbar intrinsic height. */
    ]];
    
    // Onscreen constraints, non-required to allow hidden constraint(s) to
    // take precendence.
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.presetsToolbar.bottomAnchor constraintEqualToAnchor:superview.layoutMarginsGuide.bottomAnchor],
    ] withPriority:UILayoutPriorityDefaultLow];
    
    // Offscreen constraints, take precendence over onscreen constraints.
    self.presetsToolbarHiddenConstraints = @[
        [self.presetsToolbar.topAnchor constraintEqualToAnchor:superview.bottomAnchor],
    ];
    
    // Activate offscreen constraints if necessary.
    if ([self isPresetsToolbarHidden]) {
        [NSLayoutConstraint activateConstraints:self.presetsToolbarHiddenConstraints];
    }
}

- (void)detachPresetsToolbar
{
    if (!self.presetsToolbar.superview) {
        // Already detached.
        return;
    }
    
    [self.presetsToolbar removeFromSuperview];
    
    self.presetsToolbarHiddenConstraints = nil;
}

#pragma mark presetsToolbarEnabled

- (void)setPresetsToolbarEnabled:(BOOL)enabled
{
    _presetsToolbarEnabled = enabled;
    
    if (!enabled) {
        self.presetsToolbarHidden = YES;
    }
}

#pragma mark presetsToolbarHidden

- (void)setPresetsToolbarHidden:(BOOL)hidden
{
    [self setPresetsToolbarHidden:hidden animated:NO];
}

- (void)setPresetsToolbarHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (![self isPresetsToolbarEnabled] && !hidden) {
        // Presets toolbar is disabled.
        return;
    }
    
    if (_presetsToolbarHidden == hidden) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_SELF_KEY(presetsToolbarHidden)];
    
    if (self.activePresetsToolbarTransitionCount == 0) {
        // Animation pre-amble.
        if (hidden) {
            // No pre-amble.
        } else {
            [self attachPresetsToolbar];
        }
    }
    
    _presetsToolbarHidden = hidden;
    
    [self.presetsToolbar.superview layoutIfNeeded];
    
    const NSTimeInterval duration = (animated) ? UINavigationControllerHideShowBarDuration : 0;
    const UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        if (hidden) {
            [NSLayoutConstraint activateConstraints:self.presetsToolbarHiddenConstraints];
        } else {
            [NSLayoutConstraint deactivateConstraints:self.presetsToolbarHiddenConstraints];
        }
        
        [self.presetsToolbar.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.activePresetsToolbarTransitionCount--;
        
        if (self.activePresetsToolbarTransitionCount == 0) {
            // Animation post-amble.
            if ([self isPresetsToolbarHidden]) {
                [self detachPresetsToolbar];
            } else {
                // No post-amble.
            }
        }
    }];
    
    self.activePresetsToolbarTransitionCount++;
    
    [self didChangeValueForKey:PT_SELF_KEY(presetsToolbarHidden)];
}

+ (BOOL)automaticallyNotifiesObserversOfPresetsToolbarHidden
{
    // Manually inform observers of changes.
    return NO;
}

#pragma mark - Presets view

- (void)setPresetsViewHidden:(BOOL)hidden
{
    [self setPresetsViewHidden:hidden animated:NO];
}

- (void)setPresetsViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self willChangeValueForKey:PT_SELF_KEY(presetsViewHidden)];
    
    _presetsViewHidden = hidden;
        
//    const NSTimeInterval duration = (animated) ? 0.5 : 0.0;
//    
//    [UIView animateWithDuration:duration delay:0 options:0 animations:^{
        self.presetsView.hidden = hidden;
//    } completion:^(BOOL finished) {
//
//    }];
    
    [self didChangeValueForKey:PT_SELF_KEY(presetsViewHidden)];
}

+ (BOOL)automaticallyNotifiesObserversOfPresetsViewHidden
{
    return NO;
}

- (void)showStylePickerForAnnotStyle:(PTAnnotStyle *)annotStyle fromSender:(id)sender
{
    [self dismissStylePicker];
    
    PTTool *tool = self.toolManager.tool;
    
    if ([tool isKindOfClass:[PTSmartPen class]]) {
        [((PTSmartPen *)tool) editAnnotationStyle:sender];
        return;
    }
    
    // Commit freehand ink annotations before editing style.
    if (tool.identifier
        && [tool isKindOfClass:[PTFreeHandCreate class]]
        && ![tool isKindOfClass:[PTFreeHandHighlightCreate class]]) {
        PTFreeHandCreate *freehandTool = (PTFreeHandCreate *)tool;
        
        [freehandTool commitAnnotation];
    }
    
    PTAnnotStyleViewController *stylePicker = [[PTAnnotStyleViewController alloc] initWithToolManager:self.toolManager
                                                                    annotStyle:annotStyle];
    stylePicker.delegate = self;
    
    PTPopoverNavigationController *navigationController = [[PTPopoverNavigationController allocOverridden] initWithRootViewController:stylePicker];
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
        navigationController.presentationManager.popoverBarButtonItem = barButtonItem;
    } else if ([sender isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)sender;
        navigationController.presentationManager.popoverSourceView = view;
    }
    
    
    [self.pt_viewController presentViewController:navigationController
                                         animated:YES
                                       completion:nil];
    
    self.stylePicker = stylePicker;
}

- (void)dismissStylePicker
{
    if (self.stylePicker) {
        [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
        self.stylePicker = nil;
    }
}

#pragma mark - <PTAnnotStyleViewControllerDelegate>

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didChangeStyle:(PTAnnotStyle *)annotStyle
{
    if (annotStyleViewController != self.stylePicker) {
        return;
    }
    
    [annotStyle setCurrentValuesAsDefaults];
}

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didCommitStyle:(PTAnnotStyle *)annotStyle
{
    if (annotStyleViewController != self.stylePicker) {
        return;
    }
    
    [annotStyle setCurrentValuesAsDefaults];
    
    [self dismissStylePicker];
}

#pragma mark - <PTAnnotationStylePresetsViewDelegate>

- (void)presetsView:(PTAnnotationStylePresetsView *)presetsView editPresetForStyle:(PTAnnotStyle *)style fromView:(UIView *)view
{
    if (presetsView != self.presetsView) {
        return;
    }
    
    [self showStylePickerForAnnotStyle:style fromSender:view];
}

#pragma mark - Edit view

- (void)setEditViewHidden:(BOOL)hidden
{
    [self setEditViewHidden:hidden animated:NO];
}

- (void)setEditViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (hidden == _editViewHidden) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_SELF_KEY(editViewHidden)];
    
    if (self.activeEditViewTransitionCount == 0) {
        // Animation pre-amble.
        if (hidden) {
            self.scrollContentContainerView.hidden = NO;
            self.scrollContentContainerView.alpha = 0.0;
        } else {
            self.editContentView.hidden = NO;
            self.editContentView.alpha = 0.0;
        }
    }
    
    _editViewHidden = hidden;
        
    const NSTimeInterval duration = (animated) ? 0.25 : 0;
    const UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.editContentView.alpha = (hidden) ? 0.0 : 1.0;
        self.scrollContentContainerView.alpha = (hidden) ? 1.0 : 0.0;
    } completion:^(BOOL finished) {
        self.activeEditViewTransitionCount--;
        
        if (self.activeEditViewTransitionCount == 0) {
            // Animation post-amble.
            if ([self isEditViewHidden]) {
                self.editContentView.hidden = YES;
            } else {
                self.scrollContentContainerView.hidden = YES;
            }
        }
    }];
    
    self.activeEditViewTransitionCount++;
    
    [self didChangeValueForKey:PT_SELF_KEY(editViewHidden)];
}

+ (BOOL)automaticallyNotifiesObserversOfEditViewHidden
{
    return NO;
}

- (void)commitAnnotation:(id)sender
{
    PTTool *tool = self.toolManager.tool;
    
    
    if ([tool respondsToSelector:@selector(commitAnnotation)]) {
        [tool performSelector:@selector(commitAnnotation)];
    }
    
    // Try to select the recently created annotation.
    PTAnnot *annotation = tool.currentAnnotation;
    const unsigned int pageNumber = tool.annotationPageNumber;
    
    BOOL selected = NO;
    if ((annotation && pageNumber > 0) &&
        self.toolManager.selectAnnotationAfterCreation) {
        selected = [self.toolManager selectAnnotation:annotation
                                         onPageNumber:pageNumber];
    }
    
    if (!selected) {
        [self.toolManager changeTool:[PTPanTool class]];
    }
}

#pragma mark - Edit view

- (void)updateEditView
{
    PTTool *tool = self.toolManager.tool;
    
    BOOL editViewHidden = YES;
    
    if ([tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)tool;
        
        editViewHidden = !createTool.requiresEditSupport;
    }
    
//    // Don't update button/toolbar states with a non-creation tool (other than the pan tool).
//    if (![tool isKindOfClass:[PTPanTool class]] && !tool.createsAnnotation) {
//        // When in continuous tool group, don't update the button/toolbar states. The next tool
//        // should be a creation tool.
//        // This prevents the selected tool from being deselected when a newly created annotation is
//        // selected (PTAnnotEditTool).
//        if (!tool.backToPanToolAfterUse) {
//            return;
//        }
//    }
    
    [self setEditViewHidden:editViewHidden animated:YES];
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    if (bar == self.presetsToolbar) {
        return UIBarPositionBottom;
    }
    
    return UIBarPositionBottom;
}

@end
