//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (PTOverridable)


// but it should really have a pt_ prefix...
+ (instancetype)allocOverridden;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSObject, PTOverridable)
PT_IMPORT_CATEGORY(NSObject, PTOverridable)
