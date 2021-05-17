//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (PTHexString)

+ (UIColor *)pt_colorWithHexString:(NSString *)hexString;
+ (nullable NSString *)pt_hexStringFromColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIColor, PTHexString)
PT_IMPORT_CATEGORY(UIColor, PTHexString)
