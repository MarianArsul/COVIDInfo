//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"

#import <PDFNet/PDFNet.h>
#import <Tools/PTReflowViewController.h>
#import "Tools/PTToolManager.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTReflowManager;

@protocol PTReflowManagerDelegate <NSObject>
@optional

- (void)reflowManager:(PTReflowManager *)reflowManager didBeginRequestForPageNumber:(int)pageNumber;

- (void)reflowManager:(PTReflowManager *)reflowManager didReceiveResult:(NSURL *)reflowFile forPageNumber:(int)pageNumber;

- (void)reflowManager:(PTReflowManager *)reflowManager requestCancelledForPageNumber:(int)pageNumber;

- (void)reflowManager:(PTReflowManager *)reflowManager requestFailedForPageNumber:(int)pageNumber;

@end

// Handles local (in-memory) caching of reflow results
@interface PTReflowManager : NSObject

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak, nullable) id<PTReflowManagerDelegate> delegate;

/**
* Overrides the font to use for reflowed content.
*
* If this property is nil, the default PDF font will be used.
*
* Warning: If the original PDF has incorrect unicode, changing the font will render the PDF
* unreadable, so use of this property in the general case is not recommended.
*
* @note This property only has effect when `reflowMode` is set to `PTReflowModeTextAndRawImages`.
*
*/
@property (nonatomic, copy) NSString* fontOverrideName;

@property (nonatomic, assign) PTReflowMode reflowMode;

- (void)requestReflowForPageNumber:(int)pageNumber;

- (void)cancelRequestForPageNumber:(int)pageNumber;

- (void)cancelAllRequests;

- (void)clearCache;

- (int)pageNumberForReflowFile:(NSURL *)reflowFile;



PT_INIT_UNAVAILABLE

@end

NS_ASSUME_NONNULL_END
