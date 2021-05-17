//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (PTAdditions)

@property (nonatomic, readonly, strong, nullable) UIViewController *pt_outermostViewController;

@property (nonatomic, readonly, strong, nullable) UIViewController *pt_topmostPresentedViewController;

@property (nonatomic, readonly, getter=pt_isInPopover) BOOL pt_inPopover;

@property (nonatomic, readonly, strong) NSLayoutYAxisAnchor *pt_safeTopAnchor;

- (void)pt_addChildViewController:(UIViewController *)childController withBlock:(void (NS_NOESCAPE ^)(void))block;

- (void)pt_removeChildViewController:(UIViewController *)childController withBlock:(void (NS_NOESCAPE ^)(void))block;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIViewController, PTAdditions)
PT_IMPORT_CATEGORY(UIViewController, PTAdditions)
