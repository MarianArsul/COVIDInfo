//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTTool.h>
#import <Tools/PTSelectionRectContainerView.h>
#import <Tools/PTAnnotStyleViewController.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotEditTool;
@class PTSelectionRectContainerView;

/**
 * The `PTAnnotEditToolDelegate` protocol allows the adopting class to respond to messages sent by the
 * `PTAnnotEditTool` class.
 */
@protocol PTAnnotEditToolDelegate <NSObject>

@optional

/**
 * Notifies the delegate that editing of a free text annotation has begun.
 */
- (void)annotEditTool:(PTAnnotEditTool *)annotEditTool didBeginEditingFreeText:(PTFreeText *)annot withTextView:(UITextView *)textView;

/**
 * Allows the delegate to control if an annotation's appearance should be rendered as a vector or a bitmap when selected. If the delegate method is not implemented, all annotations that can be rendered as vectors will be.
 *
 * @param annotEditTool The annot edit tool.
 *
 * @param annot The annotation that will be rendered.
 *
 * @param pageNumber The page number of the annotation.
 *
 * @note Only certain annotation types can be rendered with vector appearances.
 */
- (BOOL)annotEditTool:(PTAnnotEditTool *)annotEditTool shouldRenderAnnotationAsVector:(PTAnnot *)annot onPageNumber:(unsigned long)pageNumber;

@end

/**
 * The PTAnnotEditTool is used to change the properties, position and size of annotations.
 * It also handles link annotations.
 */
@interface PTAnnotEditTool : PTTool <UIPopoverPresentationControllerDelegate, UITextViewDelegate, PTAnnotStyleViewControllerDelegate>

/**
 The transparent parent view that holds the shaded annotation selection rectangle and resize handles.
 */
@property (nonatomic, readonly, strong) PTSelectionRectContainerView* selectionRectContainerView;

/**
 * When the user is resizing the annotation, the resize handle that is currently in use.
 */
@property (readonly, nonatomic, weak) UIView* touchedSelectWidget;

/**
 * When true, only corner resize handles are available, and the aspect ratio will be maintained.
 * Default is true for stamp and signatures annotations, false for others.
 */
@property (nonatomic, assign) BOOL maintainAspectRatio;

/**
 * When enabled, a visual guide is shown while resizing an annotation to indicate the
 * line along which the annotation's original aspect ratio is maintained.
 *
 * This property is enabled by default.
 */
@property (nonatomic, assign, getter=isAspectRatioGuideEnabled) BOOL aspectRatioGuideEnabled;

/**
 * The minimum size that annotations can be resized to, expressed in page space.
 * The default value is 0.
 */
@property (nonatomic, assign) CGFloat minimumAnnotationSize;

/**
 * The maximum size that annotations can be resized to, expressed in page space.
 * By default, there is no maximum size limit.
 */
@property (nonatomic, assign) CGFloat maximumAnnotationSize;

/**
 * The `PTAnnotEditTool`'s delegate object.
 */
@property (nonatomic, weak, nullable) id<PTAnnotEditToolDelegate> delegate;

/**
 * Selects the specified annotation.
 *
 * @param annotation the annotation to select
 *
 * @param pageNumber the page number of the annotation
 *
 * @return `YES` if the annotation was selected, `NO` otherwise.
 */
- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber;

/**
 * An array of selected annotations.
 */
@property (nonatomic, copy) NSArray<PTAnnot *> *selectedAnnotations;

/**
 * Sets the annotation's border thickness.
 */
-(void)setAnnotationBorder:(float)thickness;

/**
 * Selects the annotation where the user tapped or long pressed. If it is a link, the link
 * will be followed.
 */
-(BOOL)makeNewAnnotationSelection:(UIGestureRecognizer*)gestureRecognizer;

/**
 * Deselects the currently selected annotation `currentAnnotation`.
 */
-(void)deselectAnnotation;

/**
 * Sets the `currentAnnotation`'s opacity.
 */
-(void)setAnnotationOpacity:(double)opacity;

// used by PTTextMarkupEditTool

/**
 * Allows the user to set the `currentAnnotation`'s stroke color.
 */
-(void)editSelectedAnnotationStrokeColor;

/**
 * Allows the user to set the `currentAnnotation`'s border thickness.
 */
-(void)editSelectedAnnotationBorder;

/**
 * Allows the user to set the `currentAnnotation`'s opacity.
 */
-(void)editSelectedAnnotationOpacity;

/**
 * Edits the currently selected `PTFreeText` annotation's contents.
 */
- (void)editSelectedAnnotationFreeText;

/**
 * Allows the user to edit the `currentAnnotation`'s style.
 */
-(void)editSelectedAnnotationStyle;

/**
 * Commits the user-selected style for the `currentAnnotation`.
 */
-(void)commitSelectedAnnotationStyle;

#pragma mark - Helper methods
/** @name Helper methods
 */

/**
 * Bounds a point in screen space to the current page's crop box.
 *
 * @param point a point in screen space
 *
 * @return a point in screen space, guaranteed to be within the page.
 */
- (CGPoint)boundPointToPage:(CGPoint)point;

/**
 * Ensures that a rect in page space is within the page it's on.
 *
 * @param pageRect the rect in page space
 *
 * @param pageNumber the page number
 *
 * @return the new rectangle, guaranteed to be within the page.
 */
- (PTPDFRect *)boundPageRect:(PTPDFRect *)pageRect toPage:(int)pageNumber;

/**
 * Ensures that a new rect's position lies within the page it's on.
 *
 * @param annotRect the annotation's proposed new rectangle.
 *
 * @param resizing if the annotation was changed via a resize (as opposed to a move)
 *
 * @return the new rectangle, guaranteed to be within the page.
 */
- (CGRect)boundRectToPage:(CGRect)annotRect isResizing:(BOOL)resizing;

#pragma mark - Subclassing

/**
 * The frame for editing the currently selected free text annotation, in the
 * `selectionRectContainerView`'s local coordinate system.
 */
- (CGRect)frameForEditingFreeTextAnnotation;

@end

NS_ASSUME_NONNULL_END
