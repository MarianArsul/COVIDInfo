//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTLineAnnot (PTAdditions)

@property (nonatomic, readonly) double length;

// PTPolyLine API compatibility.

- (int)GetVertexCount;

- (PTPDFPoint *)GetVertex:(int)idx;
- (void)SetVertex:(int)idx pt:(PTPDFPoint *)pt;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTLineAnnot, PTAdditions)
PT_IMPORT_CATEGORY(PTLineAnnot, PTAdditions)
