//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/AnnotTypes.h>
#import <Tools/PTNoteEditController.h>
#import <Tools/PTOverridable.h>
#import <Tools/PTToolManager.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * These constants are used to control how close to an annotation a user needs to tap
 * before it's considered hit. (Very thin lines are otherwise too hard to hit.)
 */
#define GET_ANNOT_AT_DISTANCE_THRESHOLD 22
#define GET_ANNOT_AT_MINIMUM_LINE_WEIGHT 10

@class PTTool;
@class PTToolManager;

@protocol PTToolEvents, PTToolOptionsDelegate;

/**
 * The PTToolSwitching protocol allows the adopting tool-class to specify the next tool to use
 * if this tool does not completely handle an event.
 */
@protocol PTToolSwitching <PTPDFViewCtrlToolDelegate>

/**
 * The tool manager that is used as an interface for the PTToolManagerDelegate methods.
 */
@property (nonatomic, weak) PTToolManager *toolManager;

/**
 * A string that will be used to set the author field of annotations that are created.
 */
@property (nonatomic, copy) NSString *annotationAuthor;

/**
 * Indicates if the tool can be used to create an annotation.
 *
 * The default value is `NO`.
 */
@property (nonatomic, readonly) BOOL createsAnnotation;

/**
 * The PTPDFViewCtrl that the tool or tool manager references.
 */
@property (readonly, nonatomic, weak) PTPDFViewCtrl *pdfViewCtrl;

/**
 * Returns a newly initialized tool with the required pointer to the PTPDFViewCtrl on which it will operate.
 *
 * @param pdfViewCtrl a pointer to the PTPDFViewCtrl that the tool will operate.
 *
 * @return A newly initialized `tool` object.
 */
- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl;

/**
 * Returns the next tool to use if this tool did not completely handle an event.
 *
 * Tools receive events, listed as the optional selectors in this protocol, from a PTPDFViewCtrl. If a tool does not
 * finish handling an event (indicated by returning `NO` from one of the selectors that return a `BOOL`), then
 * getNextTool is used to instantiate a new tool that will continuning handling the event.
 *
 * @return a newly instantiated UIView that conforms to the PTToolSwitching protocol.
 */
- (instancetype)getNewTool;

/**
 * Receives a "custom" event dispatched by `-[PTToolManager createSwitchToolEvent:]`.
 *
 * This method gives the tool the opportunity to change to a new tool if it wishes to do so.
 *
 * @param userData Arbitrary data provided by the tool.
 *
 * @return `YES` if the tool has handled the event, `NO` if it should be passed to a new tool of a different type.
 */
- (BOOL)onSwitchToolEvent:(nullable id)userData;

@end

/**
 * The PTTool base class from which all stock tools derive. These tools implement the `PTToolSwitching`
 * protocol. For documentation on these methods, please see the protocol documentation,
 * available at http://www.pdftron.com
 */
@interface PTTool : UIView <PTOverridable, UIGestureRecognizerDelegate, PTToolSwitching, PTNoteEditControllerDelegate, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate>

#pragma mark - Properties
/** @name Properties
 */

/**
 The page number of the `currentAnnotation`.
 */
@property (nonatomic, assign) unsigned int annotationPageNumber;
 
/**
 The location of a long press within the coordinate system of the PTPDFViewCtrl (screen coordinates).
 */
@property (nonatomic, assign) CGPoint longPressPoint;

/**
 The tools have one active annotation at a time, which is pointed to by this property.
 */
@property (nonatomic, strong, nullable) PTAnnot* currentAnnotation;

/**
 * If YES, an annotation creation tool will switch back to the `defaultClass` tool,
 * typically the `PTPanTool`, after the annotation is created. If NO, the annotation
 * creation tool will remain active, so the next set of touches will create another
 * annotation.
 */
@property (nonatomic, assign) BOOL backToPanToolAfterUse;

/**
 * Class of tool to use when document is interacted with after
 * creating a tool. If backToPanToolAfterUse is YES, then this
 * will normally be the PTPanTool. Otherwise it will be the currently
 * used annotation creation tool.
 */
@property (nonatomic, assign) Class defaultClass;

/**
 * Class of tool to pass the event on to if the current tool if it
 * needs further processing.
 */
@property (nonatomic, assign, nullable) Class nextToolType;

/**
 * Class of previous tool that created the current tool.
 */
@property (nonatomic, strong, nullable) Class previousToolType;

/**
 * The PDFNet class that this tool creates.
 */
@property (nonatomic, readonly, strong) Class annotClass;

/**
 * The PDFNet annot type that this tool creates.
 */
@property (nonatomic, readonly, assign) PTExtendedAnnotType annotType;

/**
 * The PDFNet annot type that this tool creates.
*/
@property (nonatomic, class, readonly, assign) PTExtendedAnnotType annotType;

/**
 * Indicates if the tool type can be used to create an annotation.
 *
 * The default value is `NO`.
 */
@property (nonatomic, class, readonly) BOOL createsAnnotation;

/**
 * The image to display for this tool.
 *
 * The default implementation uses the annotation type from `annotType` to determine
 * which image to use. If the `annotType` is `PTExtendedAnnotTypeUnknown` then this
 * property is `nil`.
 *
 * This property can be overridden in a subclass to provide a custom value.
 */
@property (nonatomic, class, readonly, strong, nullable) UIImage *image;

/**
 * The localized name of this tool.
 *
 * The default implementation uses the annotation type from `annotType` to determine
 * the name to use. If the `annotType` is `PTExtendedAnnotTypeUnknown` then this
 * property is `nil`.
 *
 * This property can be overridden in a subclass to provide a custom value.
 */
@property (nonatomic, class, readonly, copy, nullable) NSString *localizedName;

/**
 * The identifier of this tool.
 */
@property (nonatomic, copy, nullable) NSString *identifier;

/**
 * Used to check if this tool can have its style modified.
 *
 * The default value is taken from the class-method `+[PTTool canEditStyle]`.
 */
@property (nonatomic, readonly, assign) BOOL canEditStyle;

/**
 * Used to check if this tool can have its style modified.
 *
 * The default value is `NO`.
 */
@property (nonatomic, class, readonly) BOOL canEditStyle;

/**
 * Tools can add a page number indicator to the `PTPDFViewCtrl`. This
 * boolean turns its visibility on and off.
 */
@property (nonatomic, assign) BOOL pageIndicatorIsVisible;

/**
 * Acrobat and Preview do not follow the PDF specification regarding
 * the ordering of quad points in a text markup annotation. Enable
 * this code for compatibility with those viewers.
 */
@property (nonatomic, assign) BOOL textMarkupAdobeHack;

/**
 * Used to track if the tool should forward the touch events
 * to the `PTPDFViewCtrl` for scrolling.
 */
@property (nonatomic, readonly, assign) BOOL allowScrolling;

/**
 * Used to track if the tool should allow the `PTPDFViewCtrl` to zoom.
 */
@property (nonatomic, assign) BOOL allowZoom;

#pragma mark - PTToolSwitching protocol implementation (General)
/** @name PTToolSwitching protocol implementation (General)
 */


- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl NS_DESIGNATED_INITIALIZER;

/**
 * Requests action object to be executed by the PTPDFViewCtrl. The action must
 * belong to the document currently displayed in the PTPDFViewCtrl.
 *
 * @param action_param The object that is to be executed.
 */
- (void)executeAction:(PTActionParameter*)action_param;

#pragma mark - Annotation events
/** @name Annotation events
 */

/**
 * Used to notify the tool manager that the tool has added an annotation.
*
 * @param annotation The annotation that was added.
 *
 * @param pageNumber The page number of the PDF that the annotation was added to.
 *
 */
- (void)annotationAdded:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
 * Used to notify the tool manager that the tool has modified an annotation.
 *
 * @param annotation The annotation that was modified.
 *
 * @param pageNumber The page number of the PDF that the annotation was modified on.
 */
- (void)annotationModified:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
* Used to notify the tool manager that the tool will modify an annotation.
*
* @param annotation The annotation that was modified.
*
* @param pageNumber The page number of the PDF that the annotation was modified on.
*/
- (void)willModifyAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
 * Used to notify the tool manager that the tool has removed an annotation.
 *
 * @param annotation The annotation that was removed.
 *
 * @param pageNumber The page number of the PDF that the annotation was removed from.
 */
- (void)annotationRemoved:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;


/**
* Used to notify the tool manager that the tool will remove an annotation.
*
* @param annotation The annotation that will be removed.
*
* @param pageNumber The page number of the PDF that the annotation will be removed from.
*/
- (void)willRemoveAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;


/**
 * Used to notify the tool manager that the tool has modified a form field's data.
 *
 * @param annotation The form field annotation's that had its data modified
 *
 * @param pageNumber The page number of the PDF that the form field annotation is on.
 */
- (void)formFieldDataModified:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
 * Used to allow the tool manager to control whether the tool should interact with the
 * form annotation on `pageNumber`.
 *
 * @param annotation The annotation that will be selected
 *
 * @param pageNumber The page number that the annotation is on.
 *
 * @return `YES` if the tool should continue to select the annotation; `NO` if not.
 */
-(BOOL)shouldInteractWithForm:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
 * Used to allow the tool manager to control whether the tool should select the
 * given annotation on `pageNumber`.
 *
 * @param annotation The annotation that will be activated
 *
 * @param pageNumber The page number that the annotation is on.
 *
 * @return `YES` if the tool should activate the form annotation; `NO` if not.
 */
-(BOOL)shouldSelectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
 * Used to notify the tool manager that the tool selected an annotation.
 *
 * @param annotation The annotation that was selected
 *
 * @param pageNumber The page number of the PDF that the annotation was selected on
 */
-(void)didSelectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
 * Used to allow the tool manager to control whether to show a menu controller
 * for the given annotation and page number.
 *
 * @param annotation The annotation that will be selected.
 *
 * @param pageNumber The page number that the annotation is on.
 *
 * @return `YES` if the tool should show the UIMenuController; `NO` if not.
 */
-(BOOL)shouldShowMenu:(UIMenuController *)menuController forAnnotation:(nullable PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber;

/**
 * Used to allow the tool manager to take over link handling. Links can either be annotations,
 * or detected as links by PDFNet via text pattern matching. One of the two first parameters
 * will have a value, the other will be `nil`.
 *
 * @see `-[PTPDFViewCtrl SetUrlExtraction:]`
 *
 * @param annotation The link annotation, if it exists, that will be handled. If there is not a link annotation, then `nil`.
 *
 * @param linkInfo If it exists, the text that was detected as matching the format of a link. `nil` otherwise.
 *
 * @param pageNumber The page number that the annotation or link is on.
 *
 * @return `YES` if the tool should handle the link; `NO` if not.
 */
- (BOOL)shouldHandleLinkAnnotation:(nullable PTAnnot *)annotation orLinkInfo:(nullable PTLinkInfo *)linkInfo onPageNumber:(unsigned long)pageNumber;

/**
 * Used to allow the tool manager to control handling of file attachment annotations.
 *
 * @param fileAttachment The file attachment.
 *
 * @param pageNumber The page number that the annotation is on.
 */
-(void)handleFileAttachment:(PTFileAttachment *)fileAttachment onPageNumber:(unsigned long)pageNumber;

#pragma mark - Shared by multiple tools
/** @name Shared by multiple tools
 */

/**
 * Call to edit the current annotation's note.
 */
- (void)editSelectedAnnotationNote;

/**
 * Will flatten the selected annoation(s).
 */
-(void)flattenAnnotations:(NSArray<PTAnnot *>*)annotations;

/**
 * Deletes the current annotation.
 */
- (void)deleteSelectedAnnotation;

/**
 * Call to keep the current tool's appearance on screen even after the tool is destroyed.
 * This prevents a possible annotation "flash" as the PDF under a newly created annotation
 * is re-rendered with the new annotation. The appearance is automatically removed when
 * the PDFViewCtrl finishes its next render (or when its layout changes).
 */
- (void)keepToolAppearanceOnScreen;

/**
 * Keeps a tool's appearance on screen using the provided imageView.
 * See `keepToolAppearanceOnScreen`.
 *
 * @param imageView The image view to temporarily keep on screen.
 */
-(void)keepToolAppearanceOnScreenWithImageView:(UIImageView*)imageView;

/**
 * Call to explicitly remove an tool appearances that have have been kept on screen by a call
 * too `keepToolAppearanceOnScreen`.
 */
- (void)removeAppearanceViews;

/**
 * Shows a `UIMenuController` with options relevant for the current tool.
 */
- (void)showSelectionMenu:(CGRect)targetRect animated:(BOOL)animated;

/**
 * Shows a `UIMenuController` with options relevant for the current tool.
 */
- (void)showSelectionMenu:(CGRect)targetRect;

/**
 * Hides the `UIMenuController`.
 */
- (void)hideMenu;

#pragma mark - Helper methods
/** @name Helper methods
 */

/**
 * Computes the PDF page box in screen (PTPDFViewCtrl) coordinates.
 *
 * @param pageNumber the page number
 *
 * @return the page box in screen points.
 */
-(nullable PTPDFRect*)pageBoxInScreenPtsForPageNumber:(int)pageNumber;

/**
 * Returns the union of two rectangles
 */
+ (PTPDFRect*)GetRectUnion:(PTPDFRect*)rect1 Rect2:(PTPDFRect*)rect2;


/**
 * Converts a point in screen (`PTPDFViewCtrl`) coordinates to a PDF page
 * coordinate.
 */
-(CGPoint)convertScreenPtToPagePt:(CGPoint)screenPoint onPageNumber:(int)pageNumber;

/**
 * Converts a point in screen (`PTPDFViewCtrl`) coordinates to a PDF page
 * coordinate.
 */
- (void)ConvertScreenPtToPagePtX:(CGFloat*)x Y:(CGFloat*)y PageNumber:(int)pageNumber;

/**
 * Converts a point in page coordinates to screen (`PTPDFViewCtrl`) coordinates.
 */
- (void)ConvertPagePtToScreenPtX:(CGFloat*)x Y:(CGFloat*)y PageNumber:(int)pageNumber;

/**
 * Converts a point in page coordinates to screen (`PTPDFViewCtrl`) coordinates.
 */
-(CGPoint)convertPagePtToScreenPt:(CGPoint)pagePoint onPageNumber:(int)pageNumber;

/**
 * Converts a `PTPDFRect` in PDF page coordinates to a `CGRect` in screen
 * (`PTPDFViewCtrl`) coordinates.
 */
-(CGRect)PDFRectPage2CGRectScreen:(PTPDFRect*)r PageNumber:(int)pageNumber;

/**
 * Converts a `PTPDFRect` in screen (`PTPDFViewCtrl`) coordinates to a `CGRect`
 * in screen (`PTPDFViewCtrl`) coordinates.
 */
-(CGRect)PDFRectScreen2CGRectScreen:(PTPDFRect*)r PageNumber:(int)pageNumber;

/**
 * Converts a `CGRect` in screen (`PTPDFViewCtrl`) coordinates to a `PTPDFRect` in
 * PDF page coordinates.
 */
-(PTPDFRect *)CGRectScreen2PDFRectPage:(CGRect)screenRect PageNumber:(int)pageNumber;

#pragma mark - Non-designated initializers
/** @name PTToolSwitching protocol implementation (Non-designated initializers)
 */


-(instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;


-(instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


-(instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
