//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSLayoutConstraint (PTPriority)

+ (NSArray<NSLayoutConstraint *> *)pt_constraints:(NSArray<NSLayoutConstraint *> *)constraints withPriority:(UILayoutPriority)priority;

+ (void)pt_activateConstraints:(NSArray<NSLayoutConstraint *> *)constraints withPriority:(UILayoutPriority)priority;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSLayoutConstraint, PTPriority)
PT_IMPORT_CATEGORY(NSLayoutConstraint, PTPriority)
