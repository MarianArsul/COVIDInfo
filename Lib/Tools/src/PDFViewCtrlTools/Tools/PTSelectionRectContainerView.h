//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTSelectionRectView.h>
#import <Tools/PTResizeWidgetView.h>
#import <Tools/PTRotateWidgetView.h>
#import <Tools/PTAnnotEditTool.h>

#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

/// The location of a `PTRotateWidgetView` rotation handle around the edge of a rectangle.
typedef NS_ENUM(NSInteger, PTRotateHandleLocation) {
    /// The top side
    PTRotateHandleLocationTop,
    /// The left side
    PTRotateHandleLocationLeft,
    /// The bottom side
    PTRotateHandleLocationBottom,
    /// The right side
    PTRotateHandleLocationRight
};

@class PTSelectionRectView;
@class PTAnnotEditTool;

/**
 * A transparent container view for the shaded `PTSelectionRectView` and the resize widgets.
 */
@interface PTSelectionRectContainerView : UIView

/** @name Properties
 */
#pragma mark - Properties

/**
 * The shaded rectangle that is overlayed onto the selected annotation.
 */
@property (readonly, nonatomic, strong) PTSelectionRectView* selectionRectView;

/**
 * The rectangle that covers the group of annotations
 */
@property (readonly, nonatomic, strong) UIView* groupSelectionRectView;


/**
 * The rectangle that draws the line between control resize widgets
 */
@property (readonly, nonatomic, strong) UIView* borderView;

/**
 * The PTPDFViewCtrl that the selection is on.
 */
@property (nonatomic, weak) PTPDFViewCtrl* pdfViewCtrl;

/** @name Resize Widget Visibility
 */
#pragma mark - Resize Widget Visibility

/**
 * When true, only displays corner resize handles. Default is `false`.
 */
@property (nonatomic, assign) BOOL displaysOnlyCornerResizeHandles;

/**
 * Hides all of the resize widgets.
 */
-(void)hideResizeWidgetViews;

/**
 * Shows all of the resize widgets.
 */
-(void)showResizeWidgetViews;

/**
 * Shows the North-East and South-West resize widgets (for lines/arrows).
 */
-(void)showNESWWidgetViews;

/**
 * Shows the North-West and South-East resize widgets (for lines/arrows).
 */
-(void)showNWSEWidgetViews;

/**
 * Used to set the view's frame to match the selected annotation's frame.
 *
 * @param frame The view's new frame.
 */
-(void)setFrameFromAnnot:(CGRect)frame;

/** @name Stamp Rotation
 */
#pragma mark - Annotation rotation specific

/**
 The rotation handle used for annotation rotating.
 */
@property (nonatomic, strong, nullable) PTRotateWidgetView *rotationHandle;

/**
 * Used to set the location of the rotation handle.
 *
 * @param location The location of the rotation handle.
 */
-(void)setRotationHandleLocation:(PTRotateHandleLocation)location;

/** @name FreeText editing
 */
#pragma mark - FreeText annotation specific

/**
 The text view used for free text annotation editing.
 */
@property (nonatomic, strong, nullable) UITextView *textView;

/**
 * Scales the text size of a free text annotation that's being edited for the current
 * zoom.
 */
-(void)setEditTextSizeForZoom:(double)zoom forFontSize:(int)size;

/**
 * Adds a UITextView to the selection rectangle for PTFreeText annotation editing.
 */
-(void)useTextViewWithText:(nullable NSString*)text withAlignment:(int)alignment atZoom:(double)zoom forFontSize:(int)size withFontName:(NSString*)fontName withFrame:(CGRect)frame withDelegate:(id<UITextViewDelegate>)delegateView;

/**
 * Saves any changes made to a PTFreeText back to the PTPDFDoc.
 *
 * @param annot The annotation that is selected.
 */
-(void)setAnnotationContents:(PTAnnot*)annot;


/** @name Line/Arrow editing specific
 */
#pragma mark - Line/Arrow editing specific

/**
 * Shows the selection rect. For use when editing line and arrow annotations, where the selection
 * rectangle is not shown when the annotation is not being moved, and has a different appearance than
 * other annotation types.
 */
-(void)showSelectionRect;

/**
 * Hides the selection rect. For use when editing line and arrow annotations, where the selection
 * rectangle is not shown when the annotation is not being moved, and has a different appearance than
 * other annotation types.
 */
-(void)hideSelectionRect;

/**
 * Sets the annot type that is selected. Used to determine the appearance of the child `PTSelectionRectView`.
 *
 * @param annot The annotation that is selected.
 */
-(void)setAnnot:(nullable PTAnnot *)annot;

/**
 * Refreshes the live representation of the annotation's appearance.
 */
-(void)refreshLiveAppearance;

/**
* Removes the live representation of the annotation's appearance.
*/
-(void)removeLiveAppearance;

/**
 * Instantiates a new PTSelectionRectContainerView object.
 *
 * @param pdfViewCtrl The PTPDFViewCtrl instance that this view uses.
 *
 * @param annot The annotation that this view will be shown over.
 *
 * @param tool The current tool.
 */
-(instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl forAnnot:(nullable PTAnnot*)annot withAnnotEditTool:(PTAnnotEditTool*)tool NS_DESIGNATED_INITIALIZER;


-(instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;


-(instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


-(instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
