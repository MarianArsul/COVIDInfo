//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTPolygon (PTAdditions)

@property (nonatomic, readonly) double area;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTPolygon, PTAdditions)
PT_IMPORT_CATEGORY(PTPolygon, PTAdditions)
