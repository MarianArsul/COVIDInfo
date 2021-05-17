//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTDocumentBaseViewController.h"

#import "PTForwardingNavigationItem.h"
#import "PTKeyValueObserving.h"
#import "PTPanelViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTDocumentViewControllerToolbarDelegate <NSObject>
@required

/**
 * Informs the delegate that the document view controller will show one of its toolbars.
 */
- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController willShowToolbar:(UIToolbar *)toolbar;

/**
 * Informs the delegate that the document view controller showed one of its toolbars.
 */
- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController didShowToolbar:(UIToolbar *)toolbar;

/**
 * Informs the delegate that the document view controller will hide one of its toolbars.
 */
- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController willHideToolbar:(UIToolbar *)toolbar;

/**
 * Informs the delegate that the document view controller hid one of its toolbars.
 */
- (void)documentViewController:(PTDocumentBaseViewController *)documentViewController didHideToolbar:(UIToolbar *)toolbar;

- (BOOL)documentViewControllerShouldHideNavigationBar:(PTDocumentBaseViewController *)documentViewController;

/**
 * Informs the delegate that the document view controller will hide the navigation bar.
 */
- (void)documentViewControllerWillHideNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated;

/**
 * Informs the delegate that the document view controller hid the navigation bar.
 */
- (void)documentViewControllerDidHideNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated;

/**
 * Informs the delegate that the document view controller will show the navigation bar.
 */
- (void)documentViewControllerWillShowNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated;

/**
 * Informs the delegate that the document view controller showed the navigation bar.
 */
- (void)documentViewControllerDidShowNavigationBar:(PTDocumentBaseViewController *)documentViewController animated:(BOOL)animated;

- (BOOL)documentViewController:(PTDocumentBaseViewController *)documentViewController shouldOpenExportedFileAttachmentAtURL:(NSURL *)exportedURL;

- (BOOL)documentViewController:(PTDocumentBaseViewController *)documentViewController shouldOpenFileURL:(NSURL *)fileURL;

@end

@interface PTDocumentBaseViewController ()

@property (nonatomic, strong, nullable) NSURL *documentURL;

@property (nonatomic, strong, nullable) NSURL *localDocumentURL;

@property (nonatomic, readwrite) PTForwardingNavigationItem *navigationItem;

- (void)loadViewConstraints NS_REQUIRES_SUPER;

- (void)loadItems;

- (void)updateItemsForTraitCollection:(UITraitCollection *)traitCollection animated:(BOOL)animated;

@property (nonatomic, strong) PTPanelViewController *panelViewController;

@property (nonatomic) UIEdgeInsets childViewControllerAdditionalSafeAreaInsets NS_AVAILABLE_IOS(11.0);
- (void)updateChildViewControllerAdditionalSafeAreaInsets NS_AVAILABLE_IOS(11.0);

@property (nonatomic, weak, nullable) id<PTDocumentViewControllerToolbarDelegate> toolbarDelegate;

- (void)toolsSettingsDidChange:(PTKeyValueObservedChange *)change;

- (void)restartAutomaticControlHidingTimerIfNeeded;

- (void)PT_setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)PT_setSystemBarsHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)PT_applicationWillEnterForeground:(NSNotification *)notification;
- (void)PT_applicationDidBecomeActive:(NSNotification *)notification;
- (void)PT_applicationDidEnterBackground:(NSNotification *)notification;
- (void)PT_applicationWillResignActive:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
