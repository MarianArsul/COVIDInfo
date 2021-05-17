//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PTCoordinatedDocumentDelegate;

/**
 * A `UIDocument` subclass backed by a `PTPDFDoc` object.
 *
 * To instantiate a new `PTCoordinatedDocument`, use `initWithFileURL:`.
 */
@interface PTCoordinatedDocument : UIDocument

/**
 * The underlying PDF document. This property will be `nil` until the `UIDocument` is loaded.
 *
 * This property should not generally be set, except when the document may have been modified
 * by out outside process, and needs to be reloaded.
 *
 * To instantiate a new `PTCoordinatedDocument`, use `initWithFileURL:`.
 *
 */
@property (nonatomic, strong, nullable) PTPDFDoc *pdfDoc;

/**
 The delegate of the `PTCoordinatedDocument` object.
 */
@property (nonatomic, weak, nullable) id<PTCoordinatedDocumentDelegate> delegate;

@end

/**
 The methods declared by the `PTCoordinatedDocumentDelegate` protocol allow the adopting delegate
 to respond to messages from the `PTCoordinatedDocument` class.
 */
@protocol PTCoordinatedDocumentDelegate<NSObject>

/**
 *
 * Notifies the conforming object that the coordinated document changed.
 *
 * @param coordinatedDocument The `PTCoordinatedDocument` that changed.
 */
-(void)coordinatedDocumentDidChange:(PTCoordinatedDocument*)coordinatedDocument;

/**
 *
 * Notifies the conforming object that the coordinated document changed.
 *
 * @param coordinatedDocument The `PTCoordinatedDocument` that generated the event.
 *
 * @param newURL The url that the item was moved/renamed to.
 */
-(void)coordinatedDocument:(PTCoordinatedDocument*)coordinatedDocument presentedItemDidMoveToURL:(NSURL *)newURL;

/**
 *
 * Used to control if the document will be saved.
 *
 * @param coordinatedDocument The `PTCoordinatedDocument` that generated the event.
 *
 * @return YES to save; NO to not save.
 *
 */
-(BOOL)coordinatedDocumentShouldSave:(PTCoordinatedDocument*)coordinatedDocument;

/**
*
* Used to control if the document will be autosaved when such a save is triggered by iOS.
*
* @param coordinatedDocument The `PTCoordinatedDocument` that generated the event.
*
* @return YES to save; NO to not save.
*
*/
-(BOOL)coordinatedDocumentShouldAutoSave:(PTCoordinatedDocument*)coordinatedDocument;

@end

NS_ASSUME_NONNULL_END
