//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTPanelViewController;

@protocol PTPanelViewControllerDelegate <NSObject>
@optional

- (void)panelViewController:(PTPanelViewController *)panelViewController didShowLeadingViewController:(UIViewController *)viewController;

- (void)panelViewController:(PTPanelViewController *)panelViewController didDismissLeadingViewController:(UIViewController *)viewController;

@end

@protocol PTPanelContentContainer <NSObject>
@required

- (void)panelWillTransition;

- (void)panelDidTransition;

@end

@interface PTPanelViewController : UIViewController

@property (nonatomic, assign, getter=isPanelEnabled) BOOL panelEnabled;

@property (nonatomic, weak, nullable) id<PTPanelViewControllerDelegate> delegate;

@property (nonatomic, strong, nullable) UIViewController *contentViewController;

@property (nonatomic, assign, getter=isLeadingPanelHidden) BOOL leadingPanelHidden;
@property (nonatomic, assign, getter=isTrailingPanelHidden) BOOL trailingPanelHidden;

@property (nonatomic, assign) UIEdgeInsets additionalPanelSafeAreaInsets;

#pragma mark - Leading view controller

@property (nonatomic, strong, nullable) UIViewController *leadingViewController;

- (void)showLeadingViewController:(UIViewController *)viewController;
- (void)showLeadingViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)dismissLeadingViewController;
- (void)dismissLeadingViewControllerAnimated:(BOOL)animated;

#pragma mark - Trailing view controller

@property (nonatomic, strong, nullable) UIViewController *trailingViewController;

- (void)showTrailingViewController:(UIViewController *)viewController;
- (void)showTrailingViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
