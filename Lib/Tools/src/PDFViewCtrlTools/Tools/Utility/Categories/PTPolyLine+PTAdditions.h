//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTPolyLine (PTAdditions)

@property (nonatomic, readonly) double perimeter;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTPolyLine, PTAdditions)
PT_IMPORT_CATEGORY(PTPolyLine, PTAdditions)
