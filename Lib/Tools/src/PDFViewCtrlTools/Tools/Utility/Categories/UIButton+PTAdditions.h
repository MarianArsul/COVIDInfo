//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (PTAdditions)

- (void)pt_setInsetsForContentPadding:(UIEdgeInsets)contentPadding imageTitleSpacing:(CGFloat)imageTitleSpacing;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIButton, PTAdditions)
PT_IMPORT_CATEGORY(UIButton, PTAdditions)
