//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTTool.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Creates a free text annotation.
 */
@interface PTFreeTextCreate: PTTool <UITextViewDelegate>

/**
 * The `UITextView` instance used for interactive text entry.
 */
@property (nonatomic, strong, nullable) UITextView *textView;

/**
 * Commits the free text annotation to the document.
 */
- (void)commitAnnotation;

/**
 * Creates a free text annotation from the tool's current state.
 *
 * @return a new `PTFreeText` instance for the current document
 */
- (PTFreeText *)createFreeText;

/**
 * Sets the rect of the free text annotation.
 *
 * @param freeText the free text annotation
 */
- (void)setRectForFreeText:(PTFreeText *)freeText;

/**
 * Applies the text color, border appearance, and other properties to the free text
 * annotation before it is committed.
 *
 * @param freeText the free text annotation
 */
- (void)setPropertiesForFreeText:(PTFreeText *)freeText;

/**
 Sets the rect for a `PTFreeText` annotation.
 
 @param freeText The `PTFreeText` object.
 @param rect The `PTPDFRect` representation of the associated `UITextView`.
 @param pdfViewCtrl The `PTPDFViewCtrl` object.
 @param isRTL A `BOOL` indicating whether the text is in a right-to-left language.
 */
+(void)setRectForFreeText:(PTFreeText*)freeText withRect:(PTPDFRect*)rect pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl isRTL:(BOOL)isRTL;

/**
 * Sets the free text appearance as is rendered by the iOS UI.
 *
 * The annotation's rotation will be rendered in accordance with its rotation flag.
 *
 * @param freeText The `PTFreeText` annotation that needs its appearance refreshed.
 *
 * @param doc The `PTPDFDoc` that the annotation is part of.
 *
 */
+(void)refreshAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc;


/**
 *
 * Creates a new appearance for a `PTFreeText` annotation that ensures it is facing up at the time of
 * creation.
 *
 * @param freeText The `PTFreeText` annotation that needs a new appearance.
 *
 * @param doc The `PTPDFDoc` that the annotation is part of.
 *
 * @param viewerRotation The current rotation of the `PTPDFViewCtrl`.
 *
 */
+(void)createAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc withViewerRotation:(PTRotate)viewerRotation;

@end

NS_ASSUME_NONNULL_END
