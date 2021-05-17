//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PTReflowContentState) {
    PTReflowContentStateIdle,
    PTReflowContentStateLoading,
    PTReflowContentStateComplete,
};

typedef NS_ENUM(NSUInteger, PTReflowContentNavigationDirection) {
    PTReflowContentNavigationDirectionForward,
    PTReflowContentNavigationDirectionReverse,
};

@class PTReflowPageContentViewController;

@protocol PTReflowPageContentViewControllerDelegate <NSObject>
@optional

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didSelectFileURL:(NSURL *)fileURL;

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController handleTap:(UITapGestureRecognizer *)gestureRecognizer;

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didBeginScale:(CGFloat)scale;

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didChangeScale:(CGFloat)scale;

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didEndScale:(CGFloat)scale;

- (void)reflowContentViewControllerDidCancelScale:(PTReflowPageContentViewController *)pageContentViewController;

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController changePageWithDirection:(PTReflowContentNavigationDirection)direction;

@end

@interface PTReflowPageContentViewController : UIViewController

@property (nonatomic, strong) UIColor* backgroundColor;

@property (nonatomic, strong, readonly) WKWebView *webView;

@property (nonatomic, assign) int pageNumber;

// Default state is idle.
@property (nonatomic, assign) PTReflowContentState state;

@property (nonatomic, weak, nullable) id<PTReflowPageContentViewControllerDelegate> delegate;

// Default value is 1.0.
@property (nonatomic, assign) CGFloat scale;

// Default is NO.
@property (nonatomic, assign) BOOL turnPageOnTap;

- (void)loadURL:(NSURL *)requestedURL;

-(void)refreshWebview;

PT_INIT_WITH_NIB_NAME_BUNDLE_UNAVAILABLE
PT_INIT_WITH_CODER_UNAVAILABLE

@end

NS_ASSUME_NONNULL_END
