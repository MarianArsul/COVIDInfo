//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTTool.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This tool is used to fill PDF forms (AcroForms). This includes text boxes, check boxes,
 * radio buttons, drop downs, and more.
 *
 * Signatures fields are handled by the `PTDigitalSignatureTool`.
 */
@interface PTFormFillTool : PTTool

/**
 * Whether an `inputAccessoryView` is shown for text fields (single and multi-line). The default
 * value is `YES`.
 */
@property (nonatomic, assign) BOOL displaysInputAccessoryView;

/**
 * Whether the text in a single or multi-line text field is limited to fit within the field. When the
 * field is full, no more text can be added.
 *
 * The default value is `NO`.
 */
@property (nonatomic, assign) BOOL textFieldContentsFitBounds;

/**
 * Whether the `UITextView` shown for interactive editing of multi-line text fields will be used to
 * create the appearance of the form.
 *
 * The default value is `NO`.
 */
@property (nonatomic, assign) BOOL useTextViewAppearance;


/**
 * Advances the active form field to the next field.
 *
 * @return `true` if active field was successfully moved; `false` otherwise.
 */
-(BOOL)moveToNextField;

/**
 * Advances the active form field to the previous field.
 *
 * @return `true` if active field was successfully moved; `false` otherwise.
 */
-(BOOL)moveToPreviousField;

@end

NS_ASSUME_NONNULL_END
