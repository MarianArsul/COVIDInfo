//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTPDFPoint (PTAdditions)

@property (nonatomic, readonly, assign) CGPoint CGPointValue;

+ (instancetype)pointWithCGPoint:(CGPoint)point;

- (instancetype)initWithCGPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTPDFPoint, PTAdditions)
PT_IMPORT_CATEGORY(PTPDFPoint, PTAdditions)
