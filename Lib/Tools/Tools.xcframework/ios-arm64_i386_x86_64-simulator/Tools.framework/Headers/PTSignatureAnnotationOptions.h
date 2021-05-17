//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTAnnotationOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An object that contains options for signature annotations.
 */
@interface PTSignatureAnnotationOptions : PTAnnotationOptions

/**
 * Whether the annotation's appearance (strokes) can be edited. The default value is `NO`.
 */
@property (nonatomic, assign) BOOL canEditAppearance;

/**
 * If true, signature fields will be signed by placing a stamp on top of them rather than
 * changing the field's appearance. Default is `NO`.
 */
@property (nonatomic, assign) BOOL signSignatureFieldsWithStamps;

@end

NS_ASSUME_NONNULL_END
