//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTPDFRect (PTAdditions)

@property (nonatomic, readonly, assign) CGRect CGRectValue;

+ (instancetype)rectFromCGRect:(CGRect)cgRect;

- (instancetype)initWithCGRect:(CGRect)cgRect;

+ (nullable PTPDFRect *)boundingBoxForPoints:(NSArray<PTPDFPoint *> *)points;

@property (nonatomic, readonly) NSArray<PTPDFPoint *> *points;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTPDFRect, PTAdditions)
PT_IMPORT_CATEGORY(PTPDFRect, PTAdditions)
