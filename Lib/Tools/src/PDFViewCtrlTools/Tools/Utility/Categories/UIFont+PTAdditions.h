//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (PTAdditions)

+ (instancetype)pt_preferredFontForTextStyle:(UIFontTextStyle)style weight:(UIFontWeight)weight;

+ (instancetype)pt_preferredFontForTextStyle:(UIFontTextStyle)style withTraits:(UIFontDescriptorSymbolicTraits)traits;

+ (instancetype)pt_boldPreferredFontForTextStyle:(UIFontTextStyle)style;
+ (instancetype)pt_italicPreferredFontForTextStyle:(UIFontTextStyle)style;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIFont, PTAdditions)
PT_IMPORT_CATEGORY(UIFont, PTAdditions)
