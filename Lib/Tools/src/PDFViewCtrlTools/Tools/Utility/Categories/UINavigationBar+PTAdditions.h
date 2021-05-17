//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationBar (PTAdditions)

@property (nonatomic, assign, getter=pt_isShadowHidden, setter=pt_setShadowHidden:) BOOL pt_shadowHidden;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UINavigationBar, PTAdditions)
PT_IMPORT_CATEGORY(UINavigationBar, PTAdditions)
