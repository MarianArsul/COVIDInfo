//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTToolManager.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTToolManager;

/**
 * The `PTUndoRedoManager` class is responsible for managing the undo/redo chain of a `PTPDFViewCtrl`
 * and the `NSUndoManager` of its `toolManager`.
 */
@interface PTUndoRedoManager : NSObject

/**
 * Initializes a new `PTUndoRedoManager` instance with the given tool manager.
 *
 * @param toolManager the tool manager
 *
 * @return an initialized `PTUndoRedoManager` instance
 */
- (instancetype)initWithToolManager:(PTToolManager *)toolManager NS_DESIGNATED_INITIALIZER;

/**
 * The `PTToolManager` associated with the undo-redo manager.
 */
@property (nonatomic, readonly, weak, nullable) PTToolManager *toolManager;

/**
 * Whether the undo-redo manager is enabled and updates the undo/redo state. The value of this
 * property is derived from the `PTPDFViewCtrl.isUndoRedoEnabled` property of its tool manager's
 * `pdfViewCtrl`.
 */
@property (nonatomic, readonly, assign, getter=isEnabled) BOOL enabled;

/**
 * Undo the last action.
 */
- (void)undo;

/**
 * Redo the last undo.
 */
- (void)redo;

/**
 * Creates a new state at the top of the undo/redo chain by taking a snapshot.
 *
 * @param actionInfo meta-data to be attached to this new state.
 */
- (void)takeUndoSnapshot:(NSString *)actionInfo;


- (instancetype)init NS_UNAVAILABLE;

@end

/**
 * Undo-able annotations events.
 */
@interface PTUndoRedoManager (PTAnnotationChanges)

/**
 * Used to notify the undo-redo manager that an annotation has been added.
 *
 * @param annotation The annotation that was added.
 *
 * @param pageNumber The page number of the PDF that the annotation was added to.
 */
- (void)annotationAdded:(PTAnnot *)annotation onPageNumber:(int)pageNumber;

/**
 * Used to notify the undo-redo manager that an annotation has been modified
 *
 * @param annotation The annotation that was modified.
 *
 * @param pageNumber The page number of the PDF that the annotation was modified on.
 */
- (void)annotationModified:(PTAnnot *)annotation onPageNumber:(int)pageNumber;

/**
 * Used to notify the undo-redo manager that an annotation has been removed.
 *
 * @param annotation The annotation that was removed.
 *
 * @param pageNumber The page number of the PDF that the annotation was removed from.
 */
- (void)annotationRemoved:(PTAnnot *)annotation onPageNumber:(int)pageNumber;

/**
 * Used to notify the undo-redo manager that the data of a form field has been modified.
 *
 * @param annotation The form field annotation that has modified data.
 *
 * @param pageNumber The page number of the PDF that the form field annotation is on.
 */
- (void)formFieldDataModified:(PTAnnot *)annotation onPageNumber:(int)pageNumber;

@end

/**
 * Undo-able page events.
 */
@interface PTUndoRedoManager (PTPageChanges)

/**
 * Used to notify the undo-redo manager manager that a page has been added.
 *
 * @param pageNumber The page number of the page that was added.
 */
- (void)pageAddedAtPageNumber:(int)pageNumber;

/**
 Used to notify the undo-redo manager manager that a page has been moved.
 *
 * @param oldPageNumber The old page number of the page.
 * @param newPageNumber The new page number of the page.
 */
- (void)pageMovedFromPageNumber:(int)oldPageNumber toPageNumber:(int)newPageNumber;

/**
 * Used to notify the undo-redo manager that a page has been removed.
 *
 * @param pageNumber The page number of the page that was removed.
 */
- (void)pageRemovedForPageNumber:(int)pageNumber;

@end

/**
 * Undo-able page content events.
 */
@interface PTUndoRedoManager (PTPageContentChanges)

/**
* Used to notify the undo-redo manager that a page's content has changed.
*
* @param pageNumber The page number of the page that had its content changed.
*/
- (void)pageContentModifiedOnPageNumber:(int)pageNumber;

@end

NS_ASSUME_NONNULL_END
