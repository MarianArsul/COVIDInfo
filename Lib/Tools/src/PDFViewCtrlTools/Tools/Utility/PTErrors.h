//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"
#import "PTCategoryDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL NSErrorDomain const PTErrorDomain;

@interface NSException (PTError)

@property (nonatomic, readonly) NSError *pt_error;

- (NSError *)pt_errorWithExtraUserInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)extraUserInfo;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSException, PTError)
PT_IMPORT_CATEGORY(NSException, PTError)
