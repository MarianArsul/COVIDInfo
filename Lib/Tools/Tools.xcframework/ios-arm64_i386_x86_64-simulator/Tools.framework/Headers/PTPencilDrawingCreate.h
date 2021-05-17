//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTCreateToolBase.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Creates Apple Pencil drawing annotations.
 */
NS_CLASS_AVAILABLE_IOS(13_1) @interface PTPencilDrawingCreate : PTCreateToolBase

/**
* Adds the freehand annotation to the document.
*/
-(void)commitAnnotation;

/**
* Edit the annotation.
*/
-(void)editAnnotation:(PTAnnot*)annot onPage:(int)pageNumber;

/**
* Cancels editing of the current annotation.
*/
- (void)cancelEditingAnnotation;

/**
 * Set to `YES` if the `PKToolPicker` should be visible.
 */
@property (nonatomic, assign) BOOL shouldShowToolPicker;

@end

NS_ASSUME_NONNULL_END
