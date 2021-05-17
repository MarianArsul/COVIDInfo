//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <PDFNet/PDFNet.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDate (NSDate)

@property (nonatomic, readonly, nullable) NSDate *NSDateValue;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTDate, NSDate)
PT_IMPORT_CATEGORY(PTDate, NSDate)
