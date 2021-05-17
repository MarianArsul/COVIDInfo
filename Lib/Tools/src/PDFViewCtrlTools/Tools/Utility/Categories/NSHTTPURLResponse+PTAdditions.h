//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSHTTPURLResponse (PTAdditions)

@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *pt_contentDispositionParameters;

@property (nonatomic, readonly, copy, nullable) NSString *pt_contentDispositionFilename;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSHTTPURLResponse, PTAdditions)
PT_IMPORT_CATEGORY(NSHTTPURLResponse, PTAdditions)
