//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTFDFDoc (PTAdditions)

/**
 * The annotations inside the "Annots" entry of the FDF document.
 */
@property (nonatomic, readonly, copy, nullable) NSArray<PTAnnot *> *annots;

+ (nullable instancetype)createWithAnnot:(PTAnnot *)annot;

+ (nullable NSString *)XFDFStringFromAnnot:(PTAnnot *)annot;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTFDFDoc, PTAdditions)
PT_IMPORT_CATEGORY(PTFDFDoc, PTAdditions)
