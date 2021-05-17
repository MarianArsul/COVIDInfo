//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <PDFNet/PDFNet.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTFileAttachmentHandler;

/**
 * A set of methods that allow a conforming class to be notified about events from a `PTFileAttachmentHandler`
 * instance.
 */
@protocol PTFileAttachmentHandlerDelegate <NSObject>
@optional

/**
 * Tells the delegate that the file attachment annotation was successfully exported to the indicated location.
 *
 * @param fileAttachmentHandler the file attachment handler that called this method
 *
 * @param fileAttachment the file attachment annotation that was exported
 *
 * @param doc the PDF document containing the file attachment
 *
 * @param exportedURL the URL of the exported file attachment
 */
- (void)fileAttachmentHandler:(PTFileAttachmentHandler *)fileAttachmentHandler didExportFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc toURL:(NSURL *)exportedURL;

/**
 * Tells the delegate that the file attachment could not be exported from the PDF document.
 *
 * @param fileAttachmentHandler the file attachment handler that called this method
 *
 * @param fileAttachment the file attachment to be exported
 *
 * @param doc the PDF document containing the file attachment
 *
 * @param error an `NSError` indicating the reason that the file attachment could not be exported.
 */
- (void)fileAttachmentHandler:(PTFileAttachmentHandler *)fileAttachmentHandler didFailToExportFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc withError:(NSError *)error;

@end

/**
 * The `PTFileAttachmentHandler` class handles file attachment annotations. It can be used to export
 * file attachment annotations from a document.
 */
@interface PTFileAttachmentHandler : NSObject

/**
 * Exports the specified file attachment annotation from the given PDF document.
 *
 * @param fileAttachment the file attachment to be exported
 *
 * @param doc the PDF document containing the file attachment
 */
- (void)exportFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc;

/**
 * The delegate of the file attachment handler. The delegate must adopt the
 * `PTFileAttachmentHandlerDelegate` protocol.
 */
@property (nonatomic, weak, nullable) id<PTFileAttachmentHandlerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
