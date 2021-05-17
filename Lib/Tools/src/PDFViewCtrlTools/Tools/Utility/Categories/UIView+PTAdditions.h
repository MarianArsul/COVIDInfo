//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (PTAdditions)

@property (nonatomic, readonly, strong, nullable) UIViewController *pt_containingViewController;

@property (nonatomic, readonly, strong, nullable) UIViewController *pt_viewController;

- (nullable __kindof UIView *)pt_ancestorOfKindOfClass:(Class)ancestorClass;

- (BOOL)pt_isDescendantOfKindOfView:(Class)viewClass;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIView, PTAdditions)
PT_IMPORT_CATEGORY(UIView, PTAdditions)
