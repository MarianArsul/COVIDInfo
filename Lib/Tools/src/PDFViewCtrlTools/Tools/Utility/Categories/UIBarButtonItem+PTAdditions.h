//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBarButtonItem (PTAdditions)

#pragma mark - Convenience

+ (instancetype)pt_fixedSpaceItemWithWidth:(CGFloat)width;
+ (instancetype)pt_flexibleSpaceItem;

@property (nonatomic, readonly, assign, getter=pt_isFixedSpaceItem) BOOL pt_fixedSpaceItem;
@property (nonatomic, readonly, assign, getter=pt_isFlexibleSpaceItem) BOOL pt_flexibleSpaceItem;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIBarButtonItem, PTAdditions)
PT_IMPORT_CATEGORY(UIBarButtonItem, PTAdditions)
