//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTPDFViewCtrl (PTAdditions)

- (nullable NSString *)uniqueIDForAnnot:(PTAnnot *)annot;

- (nullable PTAnnot *)findAnnotWithUniqueID:(NSString *)uniqueID onPageNumber:(int)pageNumber;

- (void)flashAnnotation:(PTAnnot *)annot onPageNumber:(int)pageNumber;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTPDFViewCtrl, PTAdditions)
PT_IMPORT_CATEGORY(PTPDFViewCtrl, PTAdditions)
