//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTabbedDocumentViewController.h"
#import "PTTabbedDocumentViewControllerPrivate.h"

#import "PTToolsUtil.h"
#import "PTKeyValueObserving.h"
#import "PTDocumentTabManager.h"
#import "PTDocumentHeaderView.h"
#import "PTDocumentBaseViewControllerPrivate.h"
#import "PTDocumentController.h"
#import "PTForwardingNavigationItem.h"
#import "PTDocumentTabTableViewController.h"

#import "UIViewController+PTAdditions.h"
#import "UINavigationBar+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"
#import "NSObject+PTAdditions.h"

#include <tgmath.h>

#define UIViewInheritParentAnimationDuration 0

@interface PTTabbedDocumentViewController () <PTDocumentTabTableViewControllerDelegate, PTDocumentViewControllerToolbarDelegate, UIViewControllerRestoration>
{
    BOOL _needsUpdateContentContainerConstraints;
}

#pragma mark Subviews

@property (nonatomic) PTDocumentHeaderView *headerContainerView;

@property (nonatomic, readwrite, strong) PTDocumentTabBar *tabBar;

@property (nonatomic, strong) UIView *contentContainerView;

// Content container constraint for extended layouts.
// This constraint is active only when the content container should extend under the
// navigation bar, header, tab bar, etc. The edgesForExtendedLayout property of the
// selected document view controller and the navigation controller's navigation bar
// translucency are used to determine whether the content container should be extended.
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentContainerExtendedLayoutConstraint;

// Content container constraints for non-extended layouts.
@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *contentContainerConstraints;

#pragma mark Layout

@property (nonatomic, assign) UIEdgeInsets additionalChildViewControllerSafeAreaInsets API_AVAILABLE(ios(11.0));

@property (nonatomic, assign) BOOL viewConstraintsLoaded;

@property (nonatomic, getter=isNavigationBarTransitioning) BOOL navigationBarTransitioning;

#pragma mark Header

@property (nonatomic, assign, getter=isHeaderHidden) BOOL headerHidden;
- (void)setHeaderHidden:(BOOL)hidden animated:(BOOL)animated;

@property (nonatomic, assign) NSUInteger activeHeaderTransitionCount;

#pragma mark Animation

@property (nonatomic, assign) NSUInteger activeTabBarTransitionCount;

#pragma mark View controllers

@property (nonatomic, readonly, copy, nullable) NSArray<PTDocumentBaseViewController *> *viewControllers;

@property (nonatomic, assign, getter=isTransitioningViewControllers) BOOL transitioningViewControllers;

#pragma mark State persistence

@property (nonatomic, readonly, copy) NSString *modelRestorationIdentifier;

#pragma mark Other

@property (nonatomic, readonly, assign) NSUInteger effectiveMaximumTabCount;

@end

@implementation PTTabbedDocumentViewController

- (void)PTTabbedDocumentViewController_commonInit
{
    _viewControllerClass = [PTDocumentController class];
    
    _tabsEnabled = YES;
    _maximumTabCount = NSUIntegerMax;
    
    _tabManager = [[PTDocumentTabManager alloc] init];
    
    [self pt_observeObject:_tabManager
                forKeyPath:PT_CLASS_KEY(PTDocumentTabManager, items)
                  selector:@selector(PT_tabManagerTabsChange:)
                   options:(// Receive "willChange" events.
                            NSKeyValueObservingOptionPrior |
                            // Include old value in change dictionary.
                            NSKeyValueObservingOptionOld)];
    
    [self pt_observeObject:_tabManager
                forKeyPath:PT_CLASS_KEY(PTDocumentTabManager, selectedItem)
                  selector:@selector(PT_tabManagerSelectedTabDidChange:)
                   options:(NSKeyValueObservingOptionOld)];
    
    _additionalChildViewControllerSafeAreaInsets = UIEdgeInsetsZero;
    
    _needsUpdateContentContainerConstraints = YES;
}

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self PTTabbedDocumentViewController_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTTabbedDocumentViewController_commonInit];
    }
    return self;
}

- (void)dealloc
{
    // Remove all key-value observations.
    [self pt_removeAllObservations];
}

#pragma mark - View controller lifecycle

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    
    if (parent) {
        // Will be added to parent view controller.
    } else {
        // Will be removed from parent view controller.
        [self.selectedViewController stopAutomaticControlHidingTimer];
    }
}

#pragma mark - View lifecycle

// NOTE: Do not call super implementation.
- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    // Set standard root view resizing mask.
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Create container view for child view controller.
    self.contentContainerView = [[UIView alloc] init];
    self.contentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.contentContainerView.accessibilityIdentifier = PT_SELF_KEY(contentContainerView);
    
    [self.view addSubview:self.contentContainerView];
    
    // Create container view for PTDocumentTabItem.headerViews.
    self.headerContainerView = [[PTDocumentHeaderView alloc] init];
    self.headerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.headerContainerView.preservesSuperviewLayoutMargins = YES;
    if (@available(iOS 11.0, *)) {
        self.headerContainerView.insetsLayoutMarginsFromSafeArea = NO;
    }
    
    self.headerContainerView.accessibilityIdentifier = PT_SELF_KEY(headerContainerView);
    
    [self.view addSubview:self.headerContainerView];
    
    // Create document tab bar.
    self.tabBar = [[PTDocumentTabBar alloc] init];
    self.tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.tabBar.tabManager = self.tabManager;
    
    self.tabBar.accessibilityIdentifier = PT_SELF_KEY(tabBar);
    
    [self.view addSubview:self.tabBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        // Do nothing.
    } else {
        PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
        self.automaticallyAdjustsScrollViewInsets = NO;
        PT_IGNORE_WARNINGS_END
    }
    
    self.view.backgroundColor = [UIColor colorWithWhite:(180.0 / 255) alpha:1.0];
        
    self.tabBar.backgroundView = [[UIToolbar alloc] init];
    UIColor *tabBarBGColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    if (@available(iOS 11.0, *)) {
        tabBarBGColor = [UIColor colorNamed:@"tabBarBGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
    }
    ((UIToolbar*)self.tabBar.backgroundView).barTintColor = tabBarBGColor;
    
    // Schedule view constraints update.
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Constraints

- (void)loadViewConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        // The top of the content container is at/below the top of the view...
        [self.contentContainerView.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.topAnchor],
        // ... spans the view horizontally...
        [self.contentContainerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.contentContainerView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        // ... and is attached to the bottom of the view.
        [self.contentContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        // Attach header container view to the top of the view controller.
        [self.headerContainerView.topAnchor constraintEqualToAnchor:self.pt_safeTopAnchor],
        [self.headerContainerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.headerContainerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
        
        // The tab bar is attached to the bottom of the header container...
        [self.tabBar.topAnchor constraintEqualToAnchor:self.headerContainerView.bottomAnchor],
        // ... spans the view horizontally...
        [self.tabBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.tabBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        // ... and is contained within the view's bottom edge.
        [self.tabBar.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor],
        /* Use PTDocumentTabBar intrinsic height. */
    ]];
    
    // Top of content container is attached to the top of the view, for extended layout.
    self.contentContainerExtendedLayoutConstraint = [self.contentContainerView.topAnchor constraintEqualToAnchor:self.view.topAnchor];
    
    [self updateContentContainerExtendedLayout];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.headerContainerView.heightAnchor constraintEqualToConstant:0],
    ] withPriority:UILayoutPriorityFittingSizeLevel];
}

#pragma mark Content container constraints

- (void)setNeedsUpdateContentContainerConstraints
{
    _needsUpdateContentContainerConstraints = YES;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateContentContainerConstraints
{
    if (self.contentContainerConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.contentContainerConstraints];
        self.contentContainerConstraints = nil;
    }
    
    NSLayoutYAxisAnchor *anchor = nil;
    if ([self isTabBarHidden]) {
        if ([self isHeaderHidden] &&
            [self.navigationController isNavigationBarHidden]) {
            // Header container and navigation bar are hidden.
            // Attach content container to top of view.
            anchor = self.view.topAnchor;
        } else {
            // Attach content container to bottom of header container.
            // NOTE: The header container's height is dynamic and when empty its height
            // is zero.
            anchor = self.headerContainerView.bottomAnchor;
        }
    } else {
        // Attach content container to bottom of tab bar.
        anchor = self.tabBar.bottomAnchor;
    }
    NSAssert(anchor != nil,
             @"Y-axis layout anchor must not be null");
    
    self.contentContainerConstraints = [NSLayoutConstraint pt_constraints:@[
        // Top of content container is (weakly) attached to bottom of the anchor.
        [self.contentContainerView.topAnchor constraintEqualToAnchor:anchor],
    ] withPriority:UILayoutPriorityDefaultHigh];
    
    if (self.contentContainerConstraints) {
        [NSLayoutConstraint activateConstraints:self.contentContainerConstraints];
    }
    
    [self updateContentContainerExtendedLayout];
}

- (void)updateContentContainerExtendedLayout
{
    NSAssert(self.contentContainerExtendedLayoutConstraint != nil,
             @"Content container extended layout constraint is not loaded");
    
    UIViewController *viewController = self.selectedViewController ?: self;
    
    BOOL isExtendedLayout = NO;
    
    const UIRectEdge extendedLayoutEdges = viewController.edgesForExtendedLayout;
    
    const BOOL areBarsOpaque = ![self.navigationController.navigationBar isTranslucent];
    if (areBarsOpaque) {
        if (viewController.extendedLayoutIncludesOpaqueBars) {
            // Extended layout - check edges.
            isExtendedLayout = PT_BITMASK_CHECK(extendedLayoutEdges, UIRectEdgeTop);
        }
    } else { // The bars are translucent/not opaque.
        // Extended layout - check edges.
        isExtendedLayout = PT_BITMASK_CHECK(extendedLayoutEdges, UIRectEdgeTop);
    }
    
    self.contentContainerExtendedLayoutConstraint.active = isExtendedLayout;
}

- (void)updateViewConstraints
{
    if (!self.viewConstraintsLoaded) {
        [self loadViewConstraints];
        
        // View constraints are set up.
        self.viewConstraintsLoaded = YES;
    }
    if (_needsUpdateContentContainerConstraints) {
        _needsUpdateContentContainerConstraints = NO;
        
        [self updateContentContainerConstraints];
    }
    // Call super implementation as final step.
    [super updateViewConstraints];
}

#pragma mark - Layout

- (void)setEdgesForExtendedLayout:(UIRectEdge)edgesForExtendedLayout
{
    [super setEdgesForExtendedLayout:edgesForExtendedLayout];
    
    [self setNeedsUpdateContentContainerConstraints];
}

- (void)setExtendedLayoutIncludesOpaqueBars:(BOOL)extendedLayoutIncludesOpaqueBars
{
    [super setExtendedLayoutIncludesOpaqueBars:extendedLayoutIncludesOpaqueBars];
    
    [self setNeedsUpdateContentContainerConstraints];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (@available(iOS 11, *)) {
        [self updateChildViewControllerAdditionalSafeAreaInsets];
    }
}

#pragma mark - View appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setNeedsUpdateContentContainerConstraints];
    
//    [self restoreModel];
    [self.tabBar reloadItems];
    self.tabBar.selectedIndex = self.selectedIndex;
    
    [self updateTabBar];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (@available(iOS 11, *)) {
        [self updateChildViewControllerAdditionalSafeAreaInsets];
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:UIApplication.sharedApplication];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self
                      name:UIApplicationDidEnterBackgroundNotification
                    object:UIApplication.sharedApplication];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self.tabManager saveItems];
    
    [self removeInactiveViewControllers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self removeInactiveViewControllers];
}

- (void)removeInactiveViewControllers
{
    // Remove offscreen view controllers.
    PTDocumentBaseViewController *selectedViewController = self.selectedViewController;
    
    for (PTDocumentTabItem *tab in self.tabManager.items) {
        PTDocumentBaseViewController *viewController = tab.viewController;
        if (!viewController || viewController == selectedViewController) {
            continue;
        }
        
        // Remove child view controller.
        [self PT_removeDocumentViewController:viewController];
    }
}

#pragma mark - State preservation/restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSMutableArray<PTDocumentBaseViewController *> *persistableViewControllers = [NSMutableArray array];
    for (PTDocumentBaseViewController *viewController in self.viewControllers) {
        if (viewController.restorationIdentifier) {
            [persistableViewControllers addObject:viewController];
        }
    }
    [coder encodeObject:persistableViewControllers forKey:@"tabs"];
    
    [super encodeRestorableStateWithCoder:coder];
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder
{
    return nil;
}

#pragma mark - Child view controllers

#pragma mark Safe area

- (void)updateChildViewControllerAdditionalSafeAreaInsets API_AVAILABLE(ios(11.0))
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    if (![self isHeaderHidden] &&
        CGRectIntersectsRect(self.headerContainerView.frame,
                             self.contentContainerView.frame)) {
        insets.top += CGRectGetHeight(self.headerContainerView.bounds);
    }
    
    if (![self isTabBarHidden] &&
        CGRectIntersectsRect(self.tabBar.frame,
                             self.contentContainerView.frame)) {
        insets.top += CGRectGetHeight(self.tabBar.bounds);
    }
    
    self.additionalChildViewControllerSafeAreaInsets = insets;
}

- (void)setAdditionalChildViewControllerSafeAreaInsets:(UIEdgeInsets)additionalChildSafeAreaInsets
{
    _additionalChildViewControllerSafeAreaInsets = additionalChildSafeAreaInsets;
    
    for (UIViewController *viewController in self.viewControllers) {
        const UIEdgeInsets currentInsets = viewController.additionalSafeAreaInsets;
        if (UIEdgeInsetsEqualToEdgeInsets(currentInsets, additionalChildSafeAreaInsets)) {
            continue;
        }
        viewController.additionalSafeAreaInsets = additionalChildSafeAreaInsets;
    }
}

#pragma mark - Status bar

- (UIViewController *)childViewControllerForStatusBarHidden
{
    // Selected view controller controls status bar hidden/unhidden state.
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    // Selected view controller controls status bar style.
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForScreenEdgesDeferringSystemGestures
{
    // Selected view controller controls screen edge gesture deferring.
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden
{
    // Selected view controller controls home indicator auto-hiding.
    return self.selectedViewController;
}

#pragma mark - Tab settings

- (void)setTabsEnabled:(BOOL)tabsEnabled
{
    if (_tabsEnabled == tabsEnabled) {
        // No change.
        return;
    }
    
    _tabsEnabled = tabsEnabled;
    
    if (!tabsEnabled) {
        // Trim tabs list.
        [self adjustTabs];
    }
    
    // Hide tab bar when tabs are disabled.
    BOOL hideTabBar = !tabsEnabled;
    
    // Hide tab bar only when currently shown.
    if (hideTabBar && self.tabBarHidden != hideTabBar) {
         [self setTabBarHidden:YES animated:NO];
    }
    else if (!hideTabBar &&
             !self.navigationController.navigationBarHidden &&
             [self shouldShowTabBar]) {
        [self setTabBarHidden:NO animated:NO];
    }
}

- (void)setMaximumTabCount:(NSUInteger)maximumTabCount
{
    if (maximumTabCount < 1) {
        PTLog(@"Maximum tab count must be greater than zero");
        return;
    }
    
    if ((!self.tabsEnabled && maximumTabCount > 1) ||
        _maximumTabCount == maximumTabCount) {
        return;
    }
    
    _maximumTabCount = maximumTabCount;
    
    if (self.tabManager.items.count <= maximumTabCount) {
        return;
    }
    
    // Adjust tabs.
    [self adjustTabs];
}

- (NSUInteger)effectiveMaximumTabCount
{
    return (self.tabsEnabled) ? self.maximumTabCount : 1;
}

- (void)adjustTabs
{
    NSMutableArray<PTDocumentTabItem *> *items = [self.tabManager.items mutableCopy];
    NSArray<PTDocumentTabItem *> *itemsToKeep = nil;
    if (self.tabManager.selectedItem) {
        itemsToKeep = @[self.tabManager.selectedItem];
    }
    
    NSArray<PTDocumentTabItem *> *removedItems = [self trimItems:items
                                                     itemsToKeep:itemsToKeep
                                                       withLimit:self.effectiveMaximumTabCount];
    if (removedItems.count < 1) {
        // No adjustment necessary.
        return;
    }
    
    for (PTDocumentTabItem *item in removedItems) {
        PTDocumentBaseViewController *viewController = item.viewController;
        if (!viewController) {
            continue;
        }
        
        // Remove child view controller.
        [self PT_removeDocumentViewController:viewController];
        
        [self.tabManager removeItem:item];
    }
        
    [self.tabBar reloadItems]; // legit use
    self.tabBar.selectedIndex = self.selectedIndex;
}

- (NSArray *)trimItems:(NSMutableArray *)items itemsToKeep:(NSArray *)itemsToKeep withLimit:(NSUInteger)limit
{
    NSAssert(itemsToKeep.count <= limit,
             @"Cannot keep more items than specified limit");
 
    NSUInteger itemCount = items.count;

    if (itemCount <= limit) {
        return nil;
    }
    
    NSMutableArray *itemsToRemove = [NSMutableArray array];
    
    for (id item in items) {
        if (![itemsToKeep containsObject:item]) {
            [itemsToRemove addObject:item];
            
            // Check if enough items have been removed.
            if ((itemCount - itemsToRemove.count) <= limit) {
                break;
            }
        }
    }
    
    [items removeObjectsInArray:itemsToRemove];
    
    return [itemsToRemove copy];
}

#pragma mark - Header view

#pragma mark Hidden

- (void)setHeaderHidden:(BOOL)hidden
{
    [self setHeaderHidden:hidden animated:NO];
}

- (void)setHeaderHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_headerHidden == hidden) {
        // No change.
        return;
    }

    [self willChangeValueForKey:PT_SELF_KEY(headerHidden)];

    // Animation pre-amble:
    if (self.activeHeaderTransitionCount == 0) {
        if (hidden) {
            // No pre-amble.
        } else {
            // Show header in preparation for animation.
            self.headerContainerView.hidden = NO;
        }
    }
    
    // NOTE: We do not perform the normal layout update before animating, since we actually want to
    // animate the pending layout update(s) (usually due to the navigation bar showing/hiding).

    _headerHidden = hidden;
    
    [self setNeedsUpdateContentContainerConstraints];
    
    const NSTimeInterval duration = ((animated) ?
                                     UINavigationControllerHideShowBarDuration :
                                     UIViewInheritParentAnimationDuration);
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);

    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        // Animate layout changes.
        [self.view layoutIfNeeded];

        // Animate header alpha: requires UIViewAnimationOptionBeginFromCurrentState.
        if (hidden &&
            [self isNavigationBarTransitioning] &&
            CGRectIntersectsRect(self.view.bounds, self.headerContainerView.frame)) {
            self.headerContainerView.alpha = 0.0;
        } else {
            self.headerContainerView.alpha = 1.0;
        }
    } completion:^(BOOL finished) {
        self.activeHeaderTransitionCount--;

        // Animation post-amble:
        if (self.activeHeaderTransitionCount == 0) {
            // Check state at time of completion.
            if ([self isHeaderHidden]) {
                // Hide header.
                self.headerContainerView.hidden = YES;
            } else {
                // No post-amble.
            }
        }
    }];

    self.activeHeaderTransitionCount++;

    [self didChangeValueForKey:PT_SELF_KEY(headerHidden)];
}

+ (BOOL)automaticallyNotifiesObserversOfHeaderHidden
{
    return NO;
}

#pragma mark - Tab bar

- (PTDocumentTabBar *)tabBar
{
    if (!_tabBar) {
        [self loadViewIfNeeded];
    }
    return _tabBar;
}

- (void)setTabBarHidden:(BOOL)hidden
{
    if (_tabBarHidden == hidden) {
        // No change.
        return;
    }
    
    // Animation pre-amble:
    if (self.activeTabBarTransitionCount == 0) {
        if (hidden) {
            // No pre-amble.
        } else {
            // Show tab bar in preparation for animation.
            self.tabBar.hidden = NO;
        }
    }
    
    // NOTE: We do not perform the normal layout update before animating, since we actually want to
    // animate the pending layout update(s) (usually due to the navigation bar showing/hiding).
    
    _tabBarHidden = hidden;
    
    [self setNeedsUpdateContentContainerConstraints];
    
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    
    [UIView animateWithDuration:UIViewInheritParentAnimationDuration delay:0 options:options animations:^{
        // Animate layout changes.
        [self.view layoutIfNeeded];
        
        // Animate tab bar alpha: requires UIViewAnimationOptionBeginFromCurrentState.
        if (hidden && CGRectIntersectsRect(self.view.bounds, self.tabBar.frame)) {
            self.tabBar.alpha = 0.0;
        } else {
            self.tabBar.alpha = 1.0;
        }
    } completion:^(BOOL finished) {
        self.activeTabBarTransitionCount--;
        
        // Animation post-amble:
        if (self.activeTabBarTransitionCount == 0) {
            // Check state at time of completion.
            if ([self isTabBarHidden]) {
                // Hide tab bar.
                self.tabBar.hidden = YES;
            } else {
                // No post-amble.
            }
        }
    }];
    
    self.activeTabBarTransitionCount++;
    
    if (@available(iOS 11, *)) {
        [self updateChildViewControllerAdditionalSafeAreaInsets];
    }
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    const NSTimeInterval duration = (animated) ? UINavigationControllerHideShowBarDuration : 0;
    [UIView animateWithDuration:duration animations:^{
        self.tabBarHidden = hidden;
    }];
}

- (BOOL)shouldShowTabBar
{
    return [self shouldShowTabBarForTraitCollection:self.traitCollection];
}

- (BOOL)shouldShowTabBarForTraitCollection:(UITraitCollection *)traitCollection
{
    if (!self.tabsEnabled || [self.navigationController isNavigationBarHidden]) {
        return NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(tabbedDocumentViewController:
                                                    shouldHideTabBarForTraitCollection:)]) {
        return ![self.delegate tabbedDocumentViewController:self
                         shouldHideTabBarForTraitCollection:traitCollection];
    } else {
        return (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular);
    }
}

- (void)updateTabBar
{
    [self updateTabBarForTraitCollection:self.traitCollection];
}

- (void)updateTabBarForTraitCollection:(UITraitCollection *)traitCollection
{
    if ([self shouldShowTabBarForTraitCollection:traitCollection]) {
        [self setTabBarHidden:NO animated:NO];
    } else {
        [self setTabBarHidden:YES animated:NO];
    }
}

- (void)showTabsList:(id)sender
{
    PTDocumentTabTableViewController *tabList = [[PTDocumentTabTableViewController alloc] init];
    tabList.delegate = self;
    
    tabList.tabManager = self.tabManager;
            
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tabList];
    
    UIBarButtonItem *barButtonItem = [UIBarButtonItem pt_castAsKindFromObject:sender];
    UIView *sourceView = [UIView pt_castAsKindFromObject:sender];
    
    if (barButtonItem || sourceView) {
        nav.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popover = nav.popoverPresentationController;
        
        if (barButtonItem) {
            popover.barButtonItem = barButtonItem;
        } else {
            popover.sourceView = sourceView;
        }
    }
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateTabBar];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark - <PTDocumentTabTableViewControllerDelegate>

- (void)documentTabViewController:(PTDocumentTabTableViewController *)documentTabViewController didSelectTabAtIndex:(NSInteger)tabIndex
{
    self.selectedIndex = tabIndex;
    
    [documentTabViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Tabs

- (nullable PTDocumentTabItem *)tabItemForSourceURL:(NSURL *)url
{
    for (PTDocumentTabItem *tab in self.tabManager.items) {
        if ([tab.sourceURL isEqual:url]) {
            return tab;
        }
    }
    return nil;
}

- (nullable PTDocumentTabItem *)tabItemForDocumentURL:(NSURL *)url
{
    for (PTDocumentTabItem *tab in self.tabManager.items) {
        if ([tab.documentURL isEqual:url]) {
            return tab;
        }
    }
    return nil;
}

- (NSUInteger)indexForDocumentURL:(NSURL *)url
{
    if (!url) {
        return NSNotFound;
    }
    
    __block NSUInteger foundIndex = NSNotFound;
    [self.tabManager.items enumerateObjectsUsingBlock:^(PTDocumentTabItem *tab, NSUInteger index, BOOL *stop) {
        if ([tab.documentURL isEqual:url]) {
            foundIndex = index;
            *stop = YES;
        }
    }];
    return foundIndex;
}

- (NSUInteger)indexForViewController:(PTDocumentBaseViewController *)viewController
{
    if (!viewController) {
        return NSNotFound;
    }
    
    __block NSUInteger foundIndex = NSNotFound;
    [self.tabManager.items enumerateObjectsUsingBlock:^(PTDocumentTabItem *tab, NSUInteger index, BOOL *stop) {
        if (tab.viewController == viewController) {
            foundIndex = index;
            *stop = YES;
        }
    }];
    return foundIndex;
}

- (void)addTabWithURL:(NSURL *)url selected:(BOOL)selected
{
    [self addTabWithURL:url password:nil selected:selected];
}

- (void)addTabWithURL:(NSURL *)url password:(NSString *)password selected:(BOOL)selected
{
    [self insertTabWithURL:url password:password atIndex:self.tabManager.items.count selected:selected];
}

- (void)insertTabWithURL:(NSURL *)url atIndex:(NSUInteger)index selected:(BOOL)selected
{
    [self insertTabWithURL:url password:nil atIndex:index selected:selected];
}

- (void)insertTabWithURL:(NSURL *)url password:(NSString *)password atIndex:(NSUInteger)index selected:(BOOL)selected
{
    // Need access to the security scoped resource before anything else is done.
    if ([url isFileURL]) {
        BOOL success = [url startAccessingSecurityScopedResource];
        if (!success) {
            PTLog(@"Failed to access security scoped resource with URL: %@", url);
        }
    }
    
    // Find the existing tab for this URL. Only search by the documentURL of the tabs.
    // NOTE: If we searched by the sourceURL of the tabs as well then for non-file URLs or non-PDF
    // documents, which need to be converted, we would re-use the previously converted document.
    // We instead want to re-download or re-convert these document types.
    PTDocumentTabItem *item = [self tabItemForDocumentURL:url];
    if (!item) {
        item = [[PTDocumentTabItem alloc] init];
        item.sourceURL = url;
    }
    
    if (!item.viewController) {
        PTDocumentBaseViewController *viewController = [self createDocumentViewControllerForURL:url];
        viewController.documentTabItem = item;
        item.viewController = viewController;
                
        if ([self.delegate respondsToSelector:@selector(tabbedDocumentViewController:willAddDocumentViewController:)]) {
            [self.delegate tabbedDocumentViewController:self willAddDocumentViewController:viewController];
        }
        
        // Add as child view controller.
        [self PT_addDocumentViewController:viewController];

        [viewController openDocumentWithURL:url password:password];
        
        
    }
    
    if (![self.tabManager.items containsObject:item]) {
        if (self.viewIfLoaded.window) {
            // Update tabs via the tab bar when the view is added to the window to animate the change.
            [self.tabBar.collectionView performBatchUpdates:^{
                // Update data source.
                [self.tabManager addItem:item];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                
                [self.tabBar.collectionView insertItemsAtIndexPaths:@[indexPath]];
            } completion:nil];
        } else {
            // Note: the tab bar will be updated when the view is added to the window.
            [self.tabManager addItem:item];
        }
    }
    
    if (selected) {
        self.tabManager.selectedItem = item;
    }
    
    // Adjust tabs for maximumTabCount and tabsEnabled.
    // MUST be done after (optionally) selecting the new URL.
    [self adjustTabs];
    
    
    return;
}

- (void)removeTabWithURL:(NSURL *)url
{
    const NSUInteger index = [self indexForDocumentURL:url];
    [self removeTabAtIndex:index];
}

- (void)removeTabForViewController:(PTDocumentBaseViewController *)viewController
{
    const NSUInteger index = [self indexForViewController:viewController];
    [self removeTabAtIndex:index];
}

- (void)removeTabAtIndex:(NSUInteger)index
{
    if (index > self.tabManager.items.count) {
        // Invalid index.
        return;
    }

    [self.tabBar removeTabAtIndex:index animated:NO];
}

- (NSArray<NSURL *> *)tabURLs
{
    NSMutableArray<NSURL *> *tabURLs = [NSMutableArray array];
    for (PTDocumentTabItem *tab in self.tabManager.items) {
        if (tab.documentURL) {
            [tabURLs addObject:tab.documentURL];
        }
        else if (tab.sourceURL) {
            [tabURLs addObject:tab.documentURL];
        }
    }
    return [tabURLs copy];
}

- (void)PT_tabManagerTabsChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.tabManager) {
        return;
    }
    
    switch (change.kind) {
        case NSKeyValueChangeSetting:
            break;
        case NSKeyValueChangeInsertion:
            if ([self.tabManager isMoving]) {
                return;
            }
            break;
        case NSKeyValueChangeReplacement:
            break;
        case NSKeyValueChangeRemoval:
        {
            if ([self.tabManager isMoving]) {
                return;
            }
            
            const NSUInteger index = change.indexes.firstIndex;
            
            if ([change isPrior]) {
                if ([self.delegate respondsToSelector:@selector(tabbedDocumentViewController:willRemoveTabAtIndex:)]) {
                    [self.delegate tabbedDocumentViewController:self willRemoveTabAtIndex:index];
                }
            } else {
                NSArray<PTDocumentTabItem *> *removedTabs = change.oldValue;
                
                PTDocumentTabItem *removedTab = removedTabs.firstObject;
                PTDocumentBaseViewController *viewController = removedTab.viewController;
                if (viewController) {
                    // Remove child view controller.
                    [self PT_removeDocumentViewController:viewController];
                }
            }
        }
            break;
    }
    
    if (![change isPrior]) {
        [self.tabManager saveItems];
    }
}

#pragma mark - View controllers

- (void)setViewControllerClass:(Class)cls
{
    if (cls) {
        if (![cls isSubclassOfClass:[PTDocumentBaseViewController class]]) {
            NSString *reason = [NSString stringWithFormat:@"%@ is not a subclass of %@",
                                cls, [PTDocumentBaseViewController class]];
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:reason
                                         userInfo:nil];
            return;
        }
        _viewControllerClass = cls;
    } else {
        _viewControllerClass = [PTDocumentController class];
    }
}

- (PTDocumentBaseViewController *)createDocumentViewControllerForURL:(NSURL *)url
{
    PTDocumentBaseViewController *viewController = nil;
    
    if ([self.delegate respondsToSelector:@selector(tabbedDocumentViewController:
                                                    createViewControllerForDocumentAtURL:)]) {
        viewController = [self.delegate tabbedDocumentViewController:self
                                createViewControllerForDocumentAtURL:url];
    } else {
        viewController = [[[self viewControllerClass] allocOverridden] init];
    }
    
    if (!viewController.restorationIdentifier) {
        viewController.restorationIdentifier = @"documentViewController";
    }
    if (!viewController.restorationClass) {
        viewController.restorationClass = [self class];
    }
    
    return viewController;
}

- (PTDocumentBaseViewController *)documentViewControllerAtIndex:(NSUInteger)index
{
    if (index >= self.tabManager.items.count) {
        // Invalid index.
        return nil;
    }

    // Get the document view controller for the index, if it is loaded.
    return self.tabManager.items[index].viewController;
}

- (NSArray<PTDocumentBaseViewController *> *)viewControllers
{
    NSMutableArray<PTDocumentBaseViewController *> *viewControllers = [NSMutableArray array];
    for (PTDocumentTabItem *tab in self.tabManager.items) {
        if (tab.viewController) {
            [viewControllers addObject:tab.viewController];
        }
    }
    return [viewControllers copy];
}

- (void)transitionFromViewController:(PTDocumentBaseViewController *)fromViewController toViewController:(PTDocumentBaseViewController *)toViewController animated:(BOOL)animated
{
    
    [self loadViewIfNeeded];
    
    // Begin transitioning.
    self.transitioningViewControllers = YES;
    
    const BOOL manuallyForwardAppearanceMethods = ![self shouldAutomaticallyForwardAppearanceMethods];
    
    BOOL isTransitioningFrom = NO;
    // Remove old view controller view if loaded and attached to the view hierarchy.
    if ([fromViewController.viewIfLoaded isDescendantOfView:self.contentContainerView]) {
        // Manually forward appearance methods to ensure correct order of disappear/appear.
        if (manuallyForwardAppearanceMethods) {
            [fromViewController beginAppearanceTransition:NO
                                                 animated:animated];
        }
        isTransitioningFrom = YES;
    }
    
    BOOL isTransitioningTo = NO;
    if (toViewController) {
        // Manually forward appearance methods to ensure correct order of disappear/appear.
        if (manuallyForwardAppearanceMethods) {
            [toViewController beginAppearanceTransition:YES
                                               animated:animated];
        }
        isTransitioningTo = YES;
    }
    
    // Transition to the target view controller's header view.
    UIView *headerView = toViewController.documentTabItem.headerView;
    [self.headerContainerView transitionToView:headerView
                                      animated:animated];
    
    if (isTransitioningFrom) {
        [fromViewController.view removeFromSuperview];
    }
    
    if (isTransitioningTo) {
        UIView *toView = toViewController.view;
        
        // Child view expands to fill entire content view.
        toView.frame = self.contentContainerView.bounds;
        toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentContainerView addSubview:toView];
        
        self.edgesForExtendedLayout = toViewController.edgesForExtendedLayout;
        self.extendedLayoutIncludesOpaqueBars = toViewController.extendedLayoutIncludesOpaqueBars;
    }
    
    // Manually forward appearance methods to ensure correct order of disappear/appear.
    if (manuallyForwardAppearanceMethods) {
        [fromViewController endAppearanceTransition];
        [toViewController endAppearanceTransition];
    }
    
    // End transitioning.
    self.transitioningViewControllers = NO;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    // Don't forward appearance methods while transitioning with a window.
    return !([self isTransitioningViewControllers] && self.viewIfLoaded.window);
}

- (void)PT_addDocumentViewController:(PTDocumentBaseViewController *)documentViewController
{
    if (!documentViewController.parentViewController) {
        // View controller containment.
        [self addChildViewController:documentViewController];
        [documentViewController didMoveToParentViewController:self];
        
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserver:self
                   selector:@selector(documentViewControllerDidOpenDocument:)
                       name:PTDocumentViewControllerDidOpenDocumentNotification
                     object:documentViewController];
    }
}

- (void)documentViewControllerDidOpenDocument:(NSNotification *)notification
{
    PTDocumentBaseViewController *viewController = notification.object;
    if (!viewController || ![self.viewControllers containsObject:viewController]) {
        return;
    }
    
    // The document tab item of the view controller may have changed and require saving.
    [self.tabManager saveItems];
}

- (void)PT_removeDocumentViewController:(PTDocumentBaseViewController *)documentViewController
{
    // Remove child view controller.
    [documentViewController willMoveToParentViewController:nil];
    [documentViewController.viewIfLoaded removeFromSuperview];
    [documentViewController removeFromParentViewController];
}

#pragma mark - Selection

- (void)PT_tabManagerSelectedTabDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.tabManager) {
        return;
    }
    
    if ([self.tabManager isMoving]) {
        return;
    }
    
    PTDocumentTabItem *previousTab = !([change.oldValue isEqual:[NSNull null]]) ? change.oldValue : nil;
    PTDocumentTabItem *selectedItem = self.tabManager.selectedItem;
    if (previousTab == selectedItem) {
        return;
    }
    
    PTDocumentBaseViewController *viewController = selectedItem.viewController;
    
    if (!viewController && selectedItem) {
        [self openDocumentWithURL:(selectedItem.documentURL ?: selectedItem.sourceURL)];
        
        viewController = selectedItem.viewController;
    }
    
    PTDocumentBaseViewController *previousViewController = previousTab.viewController;
    previousViewController.toolbarDelegate = nil;
    [previousViewController.navigationItem setForwardingTargetItem:nil animated:NO];
    
    // Transition to the new view controller.
    [self transitionFromViewController:previousViewController
                      toViewController:viewController
                              animated:YES];
    
    // NOTE: viewController is nil when last tab is closing.
    viewController.toolbarDelegate = self;
    [viewController.navigationItem setForwardingTargetItem:self.navigationItem animated:NO];
    self.toolbarItems = viewController.toolbarItems;
    
    if (self.tabBar.window) {
        self.tabBar.selectedIndex = self.selectedIndex;
    }
    
    // Update status bar appearance.
    [self setNeedsStatusBarAppearanceUpdate];
    if (@available(iOS 11.0, *)) {
        // Update system-gesture-deferring screen edges.
        [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
        // Update home indicator auto-hiding.
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
    
    [self.tabManager saveItems];
}

- (NSUInteger)selectedIndex
{
    return self.tabManager.selectedIndex;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (selectedIndex >= self.tabManager.items.count) {
        // Invalid index;
        return;
    }
    
    self.tabManager.selectedIndex = selectedIndex;
}

// The selectedIndex property is derived from selectedURL.
+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedIndex
{
    return [NSSet setWithObject:PT_CLASS_KEY(PTTabbedDocumentViewController, selectedURL)];
}

- (NSUInteger)nextSelectedIndex
{
    return [self nextSelectedIndexForIndex:self.selectedIndex];
}

- (NSUInteger)nextSelectedIndexForIndex:(NSUInteger)index
{
    if (index == NSNotFound) {
        return NSNotFound;
    }
    
    const NSUInteger tabsCount = self.tabManager.items.count;
    
    if (tabsCount < 2) {
        // No other tabs to select.
        return NSNotFound;
    }
    
    if (index < tabsCount - 1) {
        return index + 1;
    } else {
        return index - 1;
    }
}

- (PTDocumentBaseViewController *)selectedViewController
{
    return self.tabManager.selectedItem.viewController;
}

- (NSURL *)selectedURL
{
    PTDocumentTabItem *tab = self.tabManager.selectedItem;
    return tab.documentURL ?: tab.sourceURL;
}

#pragma mark - State persistence

- (void)setRestorationIdentifier:(NSString *)restorationIdentifier
{
    NSString *previousRestorationIdentifier = self.restorationIdentifier;
    
    [super setRestorationIdentifier:restorationIdentifier];
    
    if (!previousRestorationIdentifier ||
        ![restorationIdentifier isEqualToString:previousRestorationIdentifier]) {
        [self restoreModel];
    }
}

- (NSString *)modelRestorationIdentifier
{
    NSString *restorationIdentifier = self.restorationIdentifier;
    if (!restorationIdentifier) {
        restorationIdentifier = [NSBundle bundleForClass:[PTTabbedDocumentViewController class]].bundleIdentifier;
    }
    if (!restorationIdentifier) {
        restorationIdentifier = @"PTCurrentDocumentTabs";
    }
    
    return restorationIdentifier;
}

#pragma mark Preservation

- (void)persistModel
{
    // Save list of document bookmarks.
    NSArray<NSData *> *bookmarks = [self bookmarksForURLs:self.tabURLs];
    if (bookmarks.count == 0) {
        // Clear previously saved values.
        [NSUserDefaults.standardUserDefaults removeObjectForKey:self.modelRestorationIdentifier];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:self.modelRestorationIdentifier];
}

- (NSArray<NSData *> *)bookmarksForURLs:(NSArray<NSURL *> *)urls
{
    NSMutableArray<NSData *> *bookmarks = [NSMutableArray array];
    for (NSURL *url in urls) {
        NSURLBookmarkCreationOptions options = NSURLBookmarkCreationSuitableForBookmarkFile;
        NSError *error = nil;
        
        NSData *bookmark = [url bookmarkDataWithOptions:options includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
        //NSAssert(bookmark, @"Bookmark should not be Nil");
        if (!bookmark) {
            PTLog(@"Failed to create bookmark data for URL \"%@\": %@", url, error);
            continue;
        } else {

        }
        
        [bookmarks addObject:bookmark];
    }

    return [bookmarks copy];
}

#pragma mark Restoration

- (void)restoreModel
{
    NSArray<NSData *> *bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:self.modelRestorationIdentifier];

    NSArray<NSURL *> *urls = [self URLsForBookmarks:bookmarks];

    for (NSURL *url in urls) {
        //optionally print out what URLs were restored

        (void)url;
    }
    
    if (urls.count == 0) {
        
    }

    // short circut setter because no need to persist what we're restoring.
//    _tabURLs = [urls copy];
}

- (NSArray<NSURL *> *)URLsForBookmarks:(NSArray<NSData *> *)bookmarks
{
    // Avoid duplicate URLs.
    NSMutableOrderedSet<NSURL *> *urls = [NSMutableOrderedSet orderedSet];

    for (NSData *bookmark in bookmarks) {
        BOOL bookmarkIsStale = NO;
        NSError *error = nil;
        
        // NSURLBookmarkResolutionWithSecurityScope unavailable and not needed on iOS
        NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&bookmarkIsStale error:&error];

//        NSAssert(bookmarkIsStale == false, @"Need to handle stale bookmark");
        
        if (!url) {
            PTLog(@"Failed to resolve URL bookmark data: %@", error);
            continue;
        }
        
        
        // renew: https://stackoverflow.com/questions/23954662/what-is-the-correct-way-to-handle-stale-nsurl-bookmarks
        
        if ([url isFileURL]) {
            BOOL success = [url startAccessingSecurityScopedResource];
            if (!success) {
                PTLog(@"Failed to access security scoped resource with URL: %@", url);
                continue;
            }
        }
        
        // Standardize and resolve symlinks in URL.
//        url = url.URLByStandardizingPath.URLByResolvingSymlinksInPath;
        
        [urls addObject:url];
    }

    return ((NSOrderedSet<NSURL *> *)[urls copy]).array;
}

#pragma mark - Document opening

- (void)openDocumentWithURL:(NSURL *)url
{
    [self openDocumentWithURL:url password:nil];
}

- (void)openDocumentWithURL:(NSURL *)url password:(NSString *)password
{
    [self addTabWithURL:url password:password selected:YES];
}

#pragma mark - <PTDocumentViewControllerToolbarDelegate>

#pragma mark Toolbar

- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController willShowToolbar:(UIToolbar *)toolbar
{
    // Hide document tab bar.
    if (self.tabsEnabled) {
        [self setTabBarHidden:YES animated:YES];
    }
    
    if (@available(iOS 11, *)) {
        [self updateChildViewControllerAdditionalSafeAreaInsets];
    }
}

- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController didShowToolbar:(UIToolbar *)toolbar
{
    
    
    return;
}

- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController willHideToolbar:(UIToolbar *)toolbar
{
    // Show document tab bar.
    if (self.tabsEnabled && [self shouldShowTabBar]) {
        [self setTabBarHidden:NO animated:YES];
    }
    
    if (@available(iOS 11, *)) {
        [self updateChildViewControllerAdditionalSafeAreaInsets];
    }
}

- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController didHideToolbar:(UIToolbar *)toolbar
{
    

    return;
}

#pragma mark Navigation bar

- (BOOL)documentViewControllerShouldHideNavigationBar:(PTDocumentBaseViewController *)documentViewController
{
    if ([self.tabBar isInteractivelyMoving]) {
        return NO;
    }
    
    return YES;
}

- (void)documentViewControllerWillHideNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated
{
    self.navigationBarTransitioning = YES;
}

- (void)documentViewControllerDidHideNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated
{
    [self setHeaderHidden:YES animated:animated];
    [self setTabBarHidden:YES animated:animated];
    
    self.navigationBarTransitioning = NO;
}

- (void)documentViewControllerWillShowNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated
{
    self.navigationBarTransitioning = YES;
}

- (void)documentViewControllerDidShowNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated
{
    [self setHeaderHidden:NO animated:animated];
    if ([self shouldShowTabBar]) {
        [self setTabBarHidden:NO animated:animated];
    }
    
    self.navigationBarTransitioning = NO;
}

- (BOOL)documentViewController:(PTDocumentBaseViewController *)documentViewController shouldOpenExportedFileAttachmentAtURL:(NSURL *)exportedURL
{
    PTLog(@"Tabbed viewer will handle opening exported file attachment at URL %@", exportedURL);
    
    // Open exported file attachment in new tab.
    [self addTabWithURL:exportedURL selected:YES];
    
    // Tabbed viewer handles opening file attachments.
    return NO;
}

- (BOOL)documentViewController:(PTDocumentBaseViewController *)documentViewController shouldOpenFileURL:(NSURL *)fileURL
{
    PTLog(@"Tabbed viewer will handle opening file at URL %@", fileURL);

    // NOTE: the async dispatch is necessary to avoid issues with read-locks in other places.
    dispatch_async(dispatch_get_main_queue(), ^{
        // Open exported file in new tab.
        [self addTabWithURL:fileURL selected:YES];
    });
    
    // Tabbed viewer handles opening files.
    return NO;
}

#pragma mark - <PTDocumentTabBarDataSource>

- (BOOL)documentTabBar:(PTDocumentTabBar *)tabBar canMoveItemAtIndex:(NSUInteger)index
{
    // Multiple items are required for movement.
    return (self.tabManager.items.count > 1 && self.tabManager.selectedIndex == index);
}

@end

@implementation PTTabbedDocumentViewController (Private)

- (void)transitionFromHeaderView:(UIView *)oldHeaderView toHeaderView:(UIView *)newHeaderView forTab:(PTDocumentTabItem *)tab animated:(BOOL)animated
{
    if (tab == self.tabManager.selectedItem) {
        [self.headerContainerView transitionToView:newHeaderView
                                          animated:animated];
    }
}

@end
