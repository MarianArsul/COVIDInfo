//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentController.h"

#import "PTDocumentBaseViewControllerPrivate.h"

#import "PTToolGroupDefaultsViewController.h"
#import "PTDocumentHeaderView.h"
#import "PTHalfModalPresentationController.h"
#import "PTHalfModalPresentationManager.h"
#import "PTToolsUtil.h"

#import "NSArray+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "UIViewController+PTAdditions.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentController ()

#pragma mark Annotation mode toolbar

@property (nonatomic, strong) PTDocumentHeaderView *toolGroupToolbarContainer;
@property (nonatomic, getter=isToolGroupToolbarContainerHidden) BOOL toolGroupToolbarContainerHidden;
@property (nonatomic) NSUInteger toolGroupToolbarContainerActiveAnimationCount;

@property (nonatomic, nullable) NSLayoutConstraint *pageIndicatorToolbarConstraint;

@property (nonatomic, strong, nullable) PTHalfModalPresentationManager *presentationManager;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentController

- (void)PTDocumentController_commonInit
{
    _toolGroupsEnabled = YES;
    _toolGroupToolbarHidden = YES;
    
    _documentSliderEnabled = YES;
    
    _automaticallyShowsTabsButton = YES;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self PTDocumentController_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTDocumentController_commonInit];
    }
    return self;
}

#pragma mark - View

- (void)loadToolGroupToolbar
{
    // The container view used when the tool group toolbar is attached to this view controller
    // (when there is no tabbedViewController).
    self.toolGroupToolbarContainer = [[PTDocumentHeaderView alloc] init];
    self.toolGroupToolbarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.toolGroupToolbarContainer.preservesSuperviewLayoutMargins = YES;
    
    [self.view addSubview:self.toolGroupToolbarContainer];
}

- (void)loadView
{
    [super loadView];
    
    [self loadToolGroupToolbar];
    
    [self loadDocumentSlider];
    
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Constraints

- (void)loadViewConstraints
{
    [super loadViewConstraints];
    
    [NSLayoutConstraint activateConstraints:@[
        // Attach toolbar container view to the top of the view controller.
        [self.toolGroupToolbarContainer.topAnchor constraintEqualToAnchor:self.pt_safeTopAnchor],
        [self.toolGroupToolbarContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.toolGroupToolbarContainer.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.toolGroupToolbarContainer.heightAnchor constraintEqualToConstant:0],
    ] withPriority:UILayoutPriorityFittingSizeLevel];
    
    UIView *pageIndicatorView = self.pageIndicatorViewController.view;
    const CGFloat verticalSpacing = 8.0;
    
    self.pageIndicatorToolbarConstraint = ({
        [pageIndicatorView.topAnchor constraintGreaterThanOrEqualToAnchor:self.toolGroupToolbarContainer.bottomAnchor
                                                                 constant:verticalSpacing];
    });

    [NSLayoutConstraint pt_activateConstraints:@[
        self.pageIndicatorToolbarConstraint,
    ] withPriority:UILayoutPriorityDefaultHigh];
}

#pragma mark - Navigation item

@dynamic navigationItem;

#pragma mark - Items

- (void)loadItems
{
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    if ([self areToolGroupsEnabled]) {
        self.navigationItem.titleView = self.toolGroupIndicatorView;
    }
    
    // Compact size class:
    [self.navigationItem setLeftBarButtonItems:nil
                   forSizeClass:UIUserInterfaceSizeClassCompact
                       animated:NO];
    [self.navigationItem setRightBarButtonItems:@[
        self.moreItemsButtonItem,
        self.searchButtonItem,
    ] forSizeClass:UIUserInterfaceSizeClassCompact animated:NO];
    
    // Regular size class:
    [self.navigationItem setLeftBarButtonItems:@[
        [UIBarButtonItem pt_fixedSpaceItemWithWidth:16.0],
        self.navigationListsButtonItem,
        self.thumbnailsButtonItem,
    ] forSizeClass:UIUserInterfaceSizeClassRegular animated:NO];
    [self.navigationItem setRightBarButtonItems:@[
        self.moreItemsButtonItem,
        self.tabsButtonItem,
        self.readerModeButtonItem,
        self.searchButtonItem,
    ] forSizeClass:UIUserInterfaceSizeClassRegular animated:NO];
    
    [self setToolbarItems:@[
        self.navigationListsButtonItem,
        [UIBarButtonItem pt_flexibleSpaceItem],
        self.thumbnailsButtonItem,
        [UIBarButtonItem pt_flexibleSpaceItem],
        self.readerModeButtonItem,
        [UIBarButtonItem pt_flexibleSpaceItem],
        self.tabsButtonItem,
    ] forSizeClass:UIUserInterfaceSizeClassCompact animated:NO];
    
    self.moreItems = @[
        self.settingsButtonItem,
        self.appSettingsButtonItem,
        self.shareButtonItem,
        self.exportButtonItem,
        self.addPagesButtonItem,
    ];
    
    self.appSettingsButtonHidden = YES;
}

- (void)updateItemsForTraitCollection:(UITraitCollection *)traitCollection animated:(BOOL)animated
{
    [super updateItemsForTraitCollection:traitCollection animated:animated];
    
    [self updateTabsButton];
}

#pragma mark - Document tab

@synthesize tabsButtonItem = _tabsButtonItem;

- (UIBarButtonItem *)tabsButtonItem
{
    if (!_tabsButtonItem) {
        UIImage *image = nil;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"square.on.square"
                            withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        } else {
            image = [PTToolsUtil toolImageNamed:@"ic_round_filter_none_black_24pt"];
        }
        
        _tabsButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(showDocumentTabs:)];
        _tabsButtonItem.title = PTLocalizedString(@"Tabs",
                                                  @"Tabs button title");
    }
    return _tabsButtonItem;
}

- (void)showDocumentTabs:(id)sender
{
    if (!self.tabbedDocumentViewController) {
        return;
    }
    
    [self.tabbedDocumentViewController showTabsList:sender];
}

- (BOOL)shouldShowTabsButton
{
    if (!self.tabbedDocumentViewController.tabsEnabled) {
        return NO;
    }
    
    return self.automaticallyShowsTabsButton;
}

- (void)updateTabsButton
{
    if (!self.automaticallyShowsTabsButton) {
        return;
    }
    
    const BOOL hidden = !self.tabbedDocumentViewController.tabsEnabled;
    if (hidden == [self isBarButtonItemHidden:self.tabsButtonItem]) {
        return;
    }
    
    if (hidden) {
        [self removeBarButtonItem:self.tabsButtonItem];
    } else {
        [self addToolbarBarButtonItem:self.tabsButtonItem
                         forSizeClass:UIUserInterfaceSizeClassCompact];
        
        NSArray<UIBarButtonItem *> *items = [self.navigationItem rightBarButtonItemsForSizeClass:UIUserInterfaceSizeClassRegular];
        if (items) {
            const NSUInteger moreItemsButtonItemIndex = [items indexOfObject:self.moreItemsButtonItem];
            if (moreItemsButtonItemIndex != NSNotFound) {
                items = [items pt_arrayByInsertingObject:self.tabsButtonItem
                                                 atIndex:(moreItemsButtonItemIndex+1)];
            } else {
                items = [items arrayByAddingObject:self.tabsButtonItem];
            }
        } else {
            items = @[self.tabsButtonItem];
        }
        [self.navigationItem setRightBarButtonItems:items
                                       forSizeClass:UIUserInterfaceSizeClassRegular
                                           animated:NO];
    }
    [self ensureToolbarItemSpacing];
}

#pragma mark - More items

- (void)showMoreItems:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray<UIBarButtonItem *> *items = self.moreItems;
    
    for (UIBarButtonItem *item in items) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:item.title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [UIApplication.sharedApplication sendAction:item.action to:item.target from:sender forEvent:nil];
        }];
        [alertController addAction:action];
    }
    
    NSString *cancelTitle = PTLocalizedString(@"Cancel",
                                              @"Cancel button title");
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:nil]];
    
    UIPopoverPresentationController *popover = alertController.popoverPresentationController;
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        popover.barButtonItem = (UIBarButtonItem *)sender;
    }
    else if ([sender isKindOfClass:[UIView class]]) {
        popover.sourceView = (UIView *)sender;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Bar button item(s) manipulation

- (void)addLeftBarButtonItem:(UIBarButtonItem *)item forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *items = [self.navigationItem leftBarButtonItemsForSizeClass:sizeClass];
    if (items) {
        items = [items arrayByAddingObject:item];
    } else {
        items = @[item];
    }
    [self.navigationItem setLeftBarButtonItems:items
                                  forSizeClass:sizeClass
                                      animated:NO];
}

- (void)addRightBarButtonItem:(UIBarButtonItem *)item forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *items = [self.navigationItem rightBarButtonItemsForSizeClass:sizeClass];
    if (items) {
        items = [items arrayByAddingObject:item];
    } else {
        items = @[item];
    }
    [self.navigationItem setRightBarButtonItems:items
                                   forSizeClass:sizeClass
                                       animated:NO];
}

- (void)addToolbarBarButtonItem:(UIBarButtonItem *)item forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *items = [self toolbarItemsForSizeClass:sizeClass];
    if (items) {
        items = [items arrayByAddingObject:item];
    } else {
        items = @[item];
    }
    [self setToolbarItems:items forSizeClass:sizeClass animated:NO];
}

- (void)addMoreItemsBarButtonItem:(UIBarButtonItem *)item forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *items = [self moreItemsForSizeClass:sizeClass];
    if (items) {
        items = [items arrayByAddingObject:item];
    } else {
        items = @[item];
    }
    [self setMoreItems:items forSizeClass:sizeClass];
}

- (void)removeBarButtonItem:(UIBarButtonItem *)item
{
    [self removeBarButtonItem:item forSizeClass:UIUserInterfaceSizeClassCompact];
    [self removeBarButtonItem:item forSizeClass:UIUserInterfaceSizeClassRegular];
}

- (void)removeBarButtonItem:(UIBarButtonItem *)item forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *items = nil;
    NSUInteger itemIndex = NSNotFound;
    
    // Remove from left bar button items.
    items = [self.navigationItem leftBarButtonItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByRemovingObjectAtIndex:itemIndex];
        
        [self.navigationItem setLeftBarButtonItems:items
                                      forSizeClass:sizeClass
                                          animated:NO];
    }
    
    // Remove from right bar button items.
    items = [self.navigationItem rightBarButtonItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByRemovingObjectAtIndex:itemIndex];

        [self.navigationItem setRightBarButtonItems:items
                                       forSizeClass:sizeClass
                                           animated:NO];
    }
    
    // Remove from toolbar items.
    items = [self toolbarItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByRemovingObjectAtIndex:itemIndex];

        [self setToolbarItems:items
                 forSizeClass:sizeClass
                     animated:NO];
    }
    
    // Remove from more items.
    items = [self moreItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByRemovingObjectAtIndex:itemIndex];

        [self setMoreItems:items
              forSizeClass:sizeClass];
    }
}

- (void)replaceBarButtonItem:(UIBarButtonItem *)item withItem:(UIBarButtonItem *)replacementItem
{
    [self replaceBarButtonItem:item withItem:replacementItem forSizeClass:UIUserInterfaceSizeClassCompact];
    [self replaceBarButtonItem:item withItem:replacementItem forSizeClass:UIUserInterfaceSizeClassRegular];
}

- (void)replaceBarButtonItem:(UIBarButtonItem *)item withItem:(UIBarButtonItem *)replacementItem forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *items = nil;
    NSUInteger itemIndex = NSNotFound;
    
    // Replace item in left bar button items.
    items = [self.navigationItem leftBarButtonItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByReplacingObjectAtIndex:itemIndex
                                             withObject:replacementItem];
        
        [self.navigationItem setLeftBarButtonItems:items
                                      forSizeClass:sizeClass
                                          animated:NO];
    }
    
    // Replace item in right bar button items.
    items = [self.navigationItem rightBarButtonItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByReplacingObjectAtIndex:itemIndex
                                             withObject:replacementItem];

        [self.navigationItem setRightBarButtonItems:items
                                       forSizeClass:sizeClass
                                           animated:NO];
    }
    
    // Replace item in toolbar items.
    items = [self toolbarItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByReplacingObjectAtIndex:itemIndex
                                             withObject:replacementItem];

        [self setToolbarItems:items
                 forSizeClass:sizeClass
                     animated:NO];
    }
    
    // Replace item in more items.
    items = [self moreItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        items = [items pt_arrayByReplacingObjectAtIndex:itemIndex
                                             withObject:replacementItem];

        [self setMoreItems:items
              forSizeClass:sizeClass];
    }
}

- (BOOL)isBarButtonItemHidden:(UIBarButtonItem *)item
{
    return ([self isBarButtonItemHidden:item forSizeClass:UIUserInterfaceSizeClassCompact] &&
            [self isBarButtonItemHidden:item forSizeClass:UIUserInterfaceSizeClassRegular]);
}

- (BOOL)isBarButtonItemHidden:(UIBarButtonItem *)item forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *items = nil;
    NSUInteger itemIndex = NSNotFound;
    
    // Check for item in left bar button items.
    items = [self.navigationItem leftBarButtonItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        return NO;
    }
    
    // Check for item in right bar button items.
    items = [self.navigationItem rightBarButtonItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        return NO;
    }
    
    // Check for item in toolbar items.
    items = [self toolbarItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        return NO;
    }
    
    // Check for item in more items.
    items = [self moreItemsForSizeClass:sizeClass];
    itemIndex = [items indexOfObjectIdenticalTo:item];
    if (items && itemIndex != NSNotFound) {
        return NO;
    }
    
    return YES;
}

- (void)ensureToolbarItemSpacing
{
    [self ensureToolbarItemSpacingForSizeClass:UIUserInterfaceSizeClassCompact];
    [self ensureToolbarItemSpacingForSizeClass:UIUserInterfaceSizeClassRegular];
}

- (void)ensureToolbarItemSpacingForSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSArray<UIBarButtonItem *> *toolbarItems = [self toolbarItemsForSizeClass:sizeClass];
    if (toolbarItems.count > 0) {
        toolbarItems = [self ensureSpacingForItems:toolbarItems];
        [self setToolbarItems:toolbarItems forSizeClass:sizeClass animated:NO];
    }
}

- (NSArray<UIBarButtonItem *> *)ensureSpacingForItems:(NSArray<UIBarButtonItem *> *)items
{
    NSMutableArray<UIBarButtonItem *> *spacedItems = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger index, BOOL *stop) {
        if ([item pt_isFlexibleSpaceItem]) {
            return;
        }
        if (index > 0) {
            [spacedItems addObject:[UIBarButtonItem pt_flexibleSpaceItem]];
        }
        [spacedItems addObject:item];
    }];
    return [spacedItems copy];
}

#pragma mark - Bar button item hiding

#pragma mark readerModeButtonHidden

- (BOOL)isReaderModeButtonHidden
{
    return [self isBarButtonItemHidden:self.readerModeButtonItem];
}

- (void)setReaderModeButtonHidden:(BOOL)hidden
{
    if (hidden == [self isReaderModeButtonHidden]) {
        return;
    }
    
    if (hidden) {
        [self removeBarButtonItem:self.readerModeButtonItem];
    } else {
        [self addRightBarButtonItem:self.readerModeButtonItem
                       forSizeClass:UIUserInterfaceSizeClassRegular];
        [self addToolbarBarButtonItem:self.readerModeButtonItem
                         forSizeClass:UIUserInterfaceSizeClassCompact];
    }
    [self ensureToolbarItemSpacing];
}

#pragma mark appSettingsButtonHidden

- (BOOL)isAppSettingsButtonHidden
{
    return [self isBarButtonItemHidden:self.appSettingsButtonItem];
}

- (void)setAppSettingsButtonHidden:(BOOL)hidden
{
    if (hidden == [self isAppSettingsButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.appSettingsButtonItem];
    } else {
        [self addMoreItemsBarButtonItem:self.appSettingsButtonItem
                           forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addMoreItemsBarButtonItem:self.appSettingsButtonItem
                           forSizeClass:UIUserInterfaceSizeClassRegular];
    }
}


#pragma mark viewerSettingsButtonHidden

- (BOOL)isViewerSettingsButtonHidden
{
    return [self isBarButtonItemHidden:self.settingsButtonItem];
}

- (void)setViewerSettingsButtonHidden:(BOOL)hidden
{
    if (hidden == [self isViewerSettingsButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.settingsButtonItem];
    } else {
        [self addMoreItemsBarButtonItem:self.settingsButtonItem
                           forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addMoreItemsBarButtonItem:self.settingsButtonItem
                           forSizeClass:UIUserInterfaceSizeClassRegular];
    }
}

#pragma mark shareButtonHidden

- (BOOL)isShareButtonHidden
{
    return [self isBarButtonItemHidden:self.shareButtonItem];
}

- (void)setShareButtonHidden:(BOOL)hidden
{
    if (hidden == [self isShareButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.shareButtonItem];
    } else {
        [self addMoreItemsBarButtonItem:self.shareButtonItem
                           forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addMoreItemsBarButtonItem:self.shareButtonItem
                           forSizeClass:UIUserInterfaceSizeClassRegular];
    }
}

#pragma mark searchButtonHidden

- (BOOL)isSearchButtonHidden
{
    return [self isBarButtonItemHidden:self.searchButtonItem];
}

- (void)setSearchButtonHidden:(BOOL)hidden
{
    if (hidden == [self isSearchButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.searchButtonItem];
    } else {
        [self addRightBarButtonItem:self.searchButtonItem
                       forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addRightBarButtonItem:self.searchButtonItem
                       forSizeClass:UIUserInterfaceSizeClassRegular];
    }
}

#pragma mark exportButtonHidden

- (BOOL)isExportButtonHidden
{
    return [self isBarButtonItemHidden:self.exportButtonItem];
}

- (void)setExportButtonHidden:(BOOL)hidden
{
    if (hidden == [self isExportButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.exportButtonItem];
    } else {
        [self addMoreItemsBarButtonItem:self.exportButtonItem
                           forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addMoreItemsBarButtonItem:self.exportButtonItem
                           forSizeClass:UIUserInterfaceSizeClassRegular];
    }
}

#pragma mark moreItemsButtonHidden

- (BOOL)isMoreItemsButtonHidden
{
    return [self isBarButtonItemHidden:self.moreItemsButtonItem];
}

- (void)setMoreItemsButtonHidden:(BOOL)hidden
{
    if (hidden == [self isMoreItemsButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.moreItemsButtonItem];
    } else {
        [self addRightBarButtonItem:self.moreItemsButtonItem
                       forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addRightBarButtonItem:self.moreItemsButtonItem
                       forSizeClass:UIUserInterfaceSizeClassRegular];
    }
}

#pragma mark addPagesButtonHidden

- (BOOL)isAddPagesButtonHidden
{
    return [self isBarButtonItemHidden:self.addPagesButtonItem];
}

- (void)setAddPagesButtonHidden:(BOOL)hidden
{
    if (hidden == [self isAddPagesButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.addPagesButtonItem];
    } else {
        [self addMoreItemsBarButtonItem:self.addPagesButtonItem
                           forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addMoreItemsBarButtonItem:self.addPagesButtonItem
                           forSizeClass:UIUserInterfaceSizeClassRegular];
    }
}

#pragma mark thumbnailBrowserButtonHidden

- (BOOL)isThumbnailBrowserButtonHidden
{
    return [self isBarButtonItemHidden:self.thumbnailsButtonItem];
}

- (void)setThumbnailBrowserButtonHidden:(BOOL)hidden
{
    if (hidden == [self isThumbnailBrowserButtonHidden]) {
        return;
    }

    if (hidden) {
        [self removeBarButtonItem:self.thumbnailsButtonItem];
    } else {
        [self addToolbarBarButtonItem:self.thumbnailsButtonItem
                         forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addLeftBarButtonItem:self.thumbnailsButtonItem
                      forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    [self ensureToolbarItemSpacing];
}

#pragma mark navigationListsButtonHidden

- (BOOL)isNavigationListsButtonHidden
{
    return [self isBarButtonItemHidden:self.navigationListsButtonItem];
}

- (void)setNavigationListsButtonHidden:(BOOL)hidden
{
    if (hidden == [self isNavigationListsButtonHidden]) {
        return;
    }
    
    if (hidden) {
        [self removeBarButtonItem:self.navigationListsButtonItem];
    } else {
        [self addToolbarBarButtonItem:self.navigationListsButtonItem
                         forSizeClass:UIUserInterfaceSizeClassCompact];
        [self addLeftBarButtonItem:self.navigationListsButtonItem
                      forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    [self ensureToolbarItemSpacing];
}

#pragma mark - <UIContentContainer>

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Presets toolbar can be covered by the navigation controller's toolbar after rotation.
        if (![self.toolGroupToolbar isPresetsToolbarHidden]) {
            PTAnnotStyleToolbar *toolbar = self.toolGroupToolbar.presetsToolbar;
            [toolbar.superview bringSubviewToFront:toolbar];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // ...
    }];
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    // Presets toolbar can be covered by the navigation controller's toolbar after trait collection change.
    if (![self.toolGroupToolbar isPresetsToolbarHidden]) {
        PTAnnotStyleToolbar *toolbar = self.toolGroupToolbar.presetsToolbar;
        [toolbar.superview bringSubviewToFront:toolbar];
    }
}

#pragma mark - Layout

- (void)setChildViewControllerAdditionalSafeAreaInsets:(UIEdgeInsets)insets
{
    // Account for the tool group toolbar when it is attached to this view controller.
    if ([self.toolGroupToolbar isDescendantOfView:self.view]
        && ![self isToolGroupToolbarContainerHidden]) {
        const CGFloat toolbarHeight = CGRectGetHeight(self.toolGroupToolbarContainer.bounds);
        insets.top += fmax(insets.top, toolbarHeight);
        
        const UIEdgeInsets toolbarInsets = UIEdgeInsetsMake(toolbarHeight, 0, 0, 0);
        self.panelViewController.contentViewController.additionalSafeAreaInsets = toolbarInsets;
        self.documentSliderViewController.additionalSafeAreaInsets = toolbarInsets;
    } else {
        self.panelViewController.contentViewController.additionalSafeAreaInsets = UIEdgeInsetsZero;
        self.documentSliderViewController.additionalSafeAreaInsets = UIEdgeInsetsZero;
    }
    
    [super setChildViewControllerAdditionalSafeAreaInsets:insets];
}

#pragma mark - View controller containment

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    
    [self updateTabsButton];
}

#pragma mark - View appearance

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.toolGroupManager saveGroups];
}

#pragma mark - Annotation modes

- (void)setToolGroupsEnabled:(BOOL)enabled
{
    if (enabled == _toolGroupsEnabled) {
        // No change.
        return;
    }
    
    _toolGroupsEnabled = enabled;
    
    if (enabled) {
        if ([self shouldShowToolGroupToolbar]) {
            [self setToolGroupToolbarHidden:NO animated:NO];
        }
        
        if (self.navigationItem.titleView
            && self.navigationItem.titleView != self.toolGroupIndicatorView) {
            NSLog(@"Detected a custom UINavigationItem.titleView on %@, will not use %@: %@",
                  self, PT_SELF_KEY(toolGroupIndicatorView), self.navigationItem.titleView);
        } else {
            self.navigationItem.titleView = self.toolGroupIndicatorView;
        }
    } else {
        [self setToolGroupToolbarHidden:YES animated:NO];
        
        if (self.navigationItem.titleView == self.toolGroupIndicatorView) {
            self.navigationItem.titleView = nil;
        }
    }
}

#pragma mark Mode manager

@synthesize toolGroupManager = _toolGroupManager;

- (PTToolGroupManager *)toolGroupManager
{
    if (!_toolGroupManager) {
        _toolGroupManager = [[PTToolGroupManager alloc] initWithToolManager:self.toolManager];
        _toolGroupManager.delegate = self;
        
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserver:self
                   selector:@selector(toolGroupDidChange:)
                       name:PTToolGroupDidChangeNotification
                     object:_toolGroupManager];
    }
    return _toolGroupManager;
}

- (void)toolGroupDidChange:(NSNotification *)notification
{
    if (notification.object != self.toolGroupManager) {
        return;
    }
    
    const BOOL hidden = ![self shouldShowToolGroupToolbar];
    [self setToolGroupToolbarHidden:hidden animated:YES];
    
    [self restartAutomaticControlHidingTimerIfNeeded];
}

#pragma mark <PTToolGroupManagerDelegate>

- (void)toolGroupManager:(PTToolGroupManager *)toolGroupManager editItemsForGroup:(PTToolGroup *)group
{
    if (![group isEditable]) {
        return;
    }
    
    PTToolGroupDefaultsViewController *controller = [[PTToolGroupDefaultsViewController alloc] init];
    controller.toolGroupManager = self.toolGroupManager;
    
    NSString *localizedFormat = PTLocalizedString(@"Edit %@",
                                                  @"Edit tool group");
    controller.title = [NSString localizedStringWithFormat:localizedFormat,
                        group.title];
    
    NSMutableArray<PTToolGroup *> *itemGroups = [NSMutableArray array];
    
    // Group to be edited is the first object.
    [itemGroups addObject:group];
    
    if ([group isFavorite]) {
        for (PTToolGroup *additionalGroup in self.toolGroupManager.groups) {
            if (additionalGroup == group
                || additionalGroup.barButtonItems.count == 0
                || additionalGroup == self.toolGroupManager.pensItemGroup) {
                continue;
            }
            [itemGroups addObject:additionalGroup];
        }
    }
    controller.itemGroups = [itemGroups copy];
    
    // Use the same icon tint color as the mode toolbar.
    controller.iconTintColor = self.toolGroupToolbar.itemTintColor;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark Toolbar

@synthesize toolGroupToolbar = _toolGroupToolbar;

- (PTToolGroupToolbar *)toolGroupToolbar
{
    if (!_toolGroupToolbar) {
        PTToolGroupToolbar *toolbar = [[PTToolGroupToolbar alloc] initWithToolGroupManager:self.toolGroupManager];
        toolbar.delegate = self;
        
        toolbar.preservesSuperviewLayoutMargins = YES;
        
        // Observe changes to the presetsToolbarHidden property.
        [self pt_observeObject:toolbar
                    forKeyPath:PT_KEY(toolbar, presetsToolbarHidden)
                      selector:@selector(presetsToolbarHiddenChanged:)];
                
        _toolGroupToolbar = toolbar;
    }
    return _toolGroupToolbar;
}

- (void)presetsToolbarHiddenChanged:(PTKeyValueObservedChange *)change
{

//    if (change.object != self.toolGroupToolbar) {
//        return;
//    }
//    
//    if ([self.toolGroupToolbar isPresetsToolbarHidden]) {
//        if (self.toolbarItems.count > 0) {
//            [self.navigationController setToolbarHidden:NO
//                                               animated:YES];
//        }
//    } else {
//        [self.navigationController setToolbarHidden:YES
//                                           animated:YES];
//    }
}

#pragma mark Hidden

- (void)setToolGroupToolbarHidden:(BOOL)hidden
{
    [self setToolGroupToolbarHidden:hidden animated:NO];
}

- (void)setToolGroupToolbarHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self willChangeValueForKey:PT_SELF_KEY(toolGroupToolbarHidden)];
    
    _toolGroupToolbarHidden = hidden;
    
    // The view that will be transitioned to - nil means "empty view".
    UIView *transitionToView = (hidden) ? nil : self.toolGroupToolbar;
    
    if ([self toolGroupToolbarUsesHeaderView]) {
        [self.documentTabItem setHeaderView:transitionToView
                                   animated:animated];
    } else {
        [self.toolGroupToolbarContainer transitionToView:transitionToView
                                                     animated:animated];
        
        if (@available(iOS 11.0, *)) {
            [self updateChildViewControllerAdditionalSafeAreaInsets];
        }
    }
    
    [self didChangeValueForKey:PT_SELF_KEY(toolGroupToolbarHidden)];
}

+ (BOOL)automaticallyNotifiesObserversOfToolGroupToolbarHidden
{
    return NO;
}

- (BOOL)shouldShowToolGroupToolbar
{
    if (![self areToolGroupsEnabled]) {
        return NO;
    }
    
    PTToolGroupManager *modeManager = self.toolGroupManager;
    
    return (// Something other than the "View" mode is selected.
            (modeManager.selectedGroup != modeManager.viewItemGroup) &&
            // Reflow mode is hidden.
            ([self isReflowHidden]));
}

- (BOOL)toolGroupToolbarUsesHeaderView
{
    return (self.tabbedDocumentViewController != nil);
}

#pragma mark <PTToolGroupToolbarDelegate>

- (UIViewController *)viewControllerForPresentationsFromToolGroupToolbar:(PTToolGroupToolbar *)toolGroupToolbar
{
    return self;
}

- (UIView *)viewForOverlaysFromToolGroupToolbar:(PTToolGroupToolbar *)toolGroupToolbar
{
    if (self.navigationController) {
        return self.navigationController.view;
    }
    return self.view;
}

#pragma mark Toolbar container hidden

- (void)setToolGroupToolbarContainerHidden:(BOOL)hidden
{
    [self setToolGroupToolbarContainerHidden:hidden animated:NO];
}

- (void)setToolGroupToolbarContainerHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.toolGroupToolbarContainerActiveAnimationCount == 0) {
        if (!hidden) {
            self.toolGroupToolbarContainer.hidden = NO;
        }
    }
    
    _toolGroupToolbarContainerHidden = hidden;
    
    self.pageIndicatorToolbarConstraint.active = !hidden;
    
    const NSTimeInterval duration = (animated) ? UINavigationControllerHideShowBarDuration : 0.0;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        self.toolGroupToolbarContainer.alpha = (hidden) ? 0.0 : 1.0;
    } completion:^(BOOL finished) {
        self.toolGroupToolbarContainerActiveAnimationCount--;
        
        if (self.toolGroupToolbarContainerActiveAnimationCount == 0) {
            if ([self isToolGroupToolbarContainerHidden]) {
                self.toolGroupToolbarContainer.hidden = YES;
            }
        }
    }];
    self.toolGroupToolbarContainerActiveAnimationCount++;
}

#pragma mark Annotation mode indicator view

@synthesize toolGroupIndicatorView = _toolGroupIndicatorView;

- (PTToolGroupIndicatorView *)toolGroupIndicatorView
{
    if (!_toolGroupIndicatorView) {
        _toolGroupIndicatorView = [[PTToolGroupIndicatorView alloc] init];
        _toolGroupIndicatorView.toolGroupManager = self.toolGroupManager;
        
        [_toolGroupIndicatorView.button addTarget:self
                                       action:@selector(showToolGroups:)
                             forControlEvents:UIControlEventPrimaryActionTriggered];
    }
    return _toolGroupIndicatorView;
}

#pragma mark Annotation mode view controller

@synthesize toolGroupViewController = _toolGroupViewController;

- (PTToolGroupViewController *)toolGroupViewController
{
    if (!_toolGroupViewController) {
        _toolGroupViewController = [[PTToolGroupViewController alloc] init];
        _toolGroupViewController.toolGroupManager = self.toolGroupManager;
    }
    return _toolGroupViewController;
}

- (void)showToolGroups:(id)sender
{
    if (!self.presentationManager) {
        self.presentationManager = [[PTHalfModalPresentationManager alloc] init];
    }
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.toolGroupViewController];
    
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.transitioningDelegate = self.presentationManager;

    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        self.presentationManager.popoverBarButtonItem = (UIBarButtonItem *)sender;
    }
    else if ([sender isKindOfClass:[UIView class]]) {
        self.presentationManager.popoverSourceView = (UIView *)sender;
    }
    
    UIPresentationController *controller = nav.presentationController;
    if ([controller isKindOfClass:[PTHalfModalPresentationController class]]) {
        PTHalfModalPresentationController *halfModal = (PTHalfModalPresentationController *)controller;
        halfModal.dimsBackgroundView = YES;
    }
    
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Document slider

- (PTDocumentSliderViewController *)documentSliderViewController
{
    if (!_documentSliderViewController) {
        [self loadViewIfNeeded];
        
        NSAssert(_documentSliderViewController, @"Document slider was not loaded");
    }
    return _documentSliderViewController;
}

-(void)loadDocumentSlider
{
    NSAssert(_documentSliderViewController == nil,
             @"Document slider view controller is already loaded");
    
    self.documentSliderViewController = [[PTDocumentSliderViewController alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
    
    if ([self isDocumentSliderEnabled]) {
        [self PT_addDocumentSliderViewController];
    }
}

- (void)loadDocumentSliderConstraints
{
    UIView *sliderView = self.documentSliderViewController.view;
    
    sliderView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [sliderView.topAnchor constraintEqualToAnchor:self.pdfViewCtrl.topAnchor],
        [sliderView.leftAnchor constraintEqualToAnchor:self.pdfViewCtrl.leftAnchor],
        [sliderView.bottomAnchor constraintEqualToAnchor:self.pdfViewCtrl.bottomAnchor],
        [sliderView.rightAnchor constraintEqualToAnchor:self.pdfViewCtrl.rightAnchor],
    ]];
}

- (void)setDocumentSliderEnabled:(BOOL)enabled
{
    if (enabled == _documentSliderEnabled) {
        // No change.
        return;
    }
    
    _documentSliderEnabled = enabled;
    
    if (enabled) {
        [self PT_addDocumentSliderViewController];
    } else {
        [self PT_removeDocumentSliderViewController];
    }
}

- (void)PT_addDocumentSliderViewController
{
    if (self.documentSliderViewController.parentViewController == self) {
        // Already added.
        return;
    }
    
    [self addChildViewController:self.documentSliderViewController];
    
    [self.view addSubview:self.documentSliderViewController.view];
    
    [self.documentSliderViewController didMoveToParentViewController:self];
    
    [self loadDocumentSliderConstraints];
}

- (void)PT_removeDocumentSliderViewController
{
    if (!self.documentSliderViewController.parentViewController) {
        // Already removed.
        return;
    }
    
    NSAssert(self.documentSliderViewController.parentViewController == self,
             @"Child view controller %@ is not attached to %@: "
             @"parent view controller = %@",
             self.documentSliderViewController,
             self,
             self.documentSliderViewController.parentViewController);
    
    [self.documentSliderViewController willMoveToParentViewController:nil];
    
    [self.documentSliderViewController.view removeFromSuperview];
    
    [self.documentSliderViewController removeFromParentViewController];
}

#pragma mark - Reflow

- (void)setReflowHidden:(BOOL)hidden
{
    [super setReflowHidden:hidden];
    
    // Hide tool group toolbar in reflow mode.
    if (hidden) {
        if ([self shouldShowToolGroupToolbar]) {
            [self setToolGroupToolbarHidden:NO animated:YES];
        }
    } else {
        [self setToolGroupToolbarHidden:YES animated:YES];
    }
}

#pragma mark - Control hiding

- (void)PT_setSystemBarsHidden:(BOOL)hidden animated:(BOOL)animated
{
    [super PT_setSystemBarsHidden:hidden animated:animated];

    // Hide the entire tool group toolbar container if necessary.
    // The container is hidden instead of the toolbar itself because the toolbar's
    // layout tends to break and/or cause a layout feedback loop.
    if (![self toolGroupToolbarUsesHeaderView]) {
        [self setToolGroupToolbarContainerHidden:hidden animated:animated];
    }
    
    // Animate layout changes to this view controller's (root) view resulting from
    // hiding/showing the system bars and tool group toolbar (container).
    // NOTE: In order to animate the tool group toolbar's position, not just its
    // alpha via -setToolGroupToolbarContainerHidden:animated:, the animation must
    // be handled here in -setSystemBarsHidden:animated: instead of in the
    // -setControlsHidden:animated: method.
    const NSTimeInterval duration = (animated) ? UINavigationControllerHideShowBarDuration : 0.0;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (BOOL)shouldHideControlsFromTimer:(NSTimer *)timer
{
    if (![super shouldHideControlsFromTimer:timer]) {
        return NO;
    }
    
    // Don't hide bars when a non-"View" tool group is selected.
    if ([self areToolGroupsEnabled]) {
        PTToolGroupManager *modeManager = self.toolGroupManager;
        if (modeManager.selectedGroup != modeManager.viewItemGroup) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Application lifecycle

- (void)PT_applicationDidEnterBackground:(NSNotification *)notification
{
    [super PT_applicationDidEnterBackground:notification];
    [self.toolGroupManager saveGroups];
}

#pragma mark - SubclassingHooks

- (void)didOpenDocument
{
    if ([self.delegate respondsToSelector:@selector(documentControllerDidOpenDocument:)]) {
        [self.delegate documentControllerDidOpenDocument:self];
    }
}

- (void)handleDocumentOpeningFailureWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(documentController:
                                                    didFailToOpenDocumentWithError:)]) {
        [self.delegate documentController:self
                   didFailToOpenDocumentWithError:error];
    }
}

- (void)didBecomeInvalid
{
    if ([self.delegate respondsToSelector:@selector(documentControllerDidBecomeInvalid:)]) {
        [self.delegate documentControllerDidBecomeInvalid:self];
    }
}

- (BOOL)shouldExportCachedDocumentAtURL:(NSURL *)cachedDocumentURL
{
    if ([self.delegate respondsToSelector:@selector(documentController:
                                                    shouldExportCachedDocumentAtURL:)]) {
        return [self.delegate documentController:self
                         shouldExportCachedDocumentAtURL:cachedDocumentURL];
    }
    return YES;
}

- (NSURL *)destinationURLforDocumentAtURL:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(documentController:
                                                    destinationURLForDocumentAtURL:)]) {
        return [self.delegate documentController:self
                          destinationURLForDocumentAtURL:url];
    }
    return nil;
}

- (BOOL)shouldDeleteCachedDocumentAtURL:(NSURL *)cachedDocumentURL
{
    if ([self.delegate respondsToSelector:@selector(documentController:
                                                    shouldDeleteCachedDocumentAtURL:)]) {
        [self.delegate documentController:self
                  shouldDeleteCachedDocumentAtURL:cachedDocumentURL];
    }
    return NO;
}

@end
