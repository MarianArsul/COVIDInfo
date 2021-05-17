//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (PTAdditions)

@property (nonatomic, readonly) UIEdgeInsets pt_effectiveContentInset;

@property (nonatomic, readonly) BOOL pt_isScrollBouncing;

@property (nonatomic, readonly) BOOL pt_isScrollBouncingTop;
@property (nonatomic, readonly) BOOL pt_isScrollBouncingLeft;
@property (nonatomic, readonly) BOOL pt_isScrollBouncingBottom;
@property (nonatomic, readonly) BOOL pt_isScrollBouncingRight;

@property (nonatomic, assign, setter=pt_setExtendedContentInset:) UIEdgeInsets pt_extendedContentInset NS_DEPRECATED_IOS(7_0, 11_0);

@property (nonatomic, assign, setter=pt_setExtendedScrollIndicatorInsets:) UIEdgeInsets pt_extendedScrollIndicatorInsets NS_DEPRECATED_IOS(7_0, 11_0);

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIScrollView, PTAdditions)
PT_IMPORT_CATEGORY(UIScrollView, PTAdditions)
