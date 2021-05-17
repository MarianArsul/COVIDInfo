//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL NSString * const PTNSURLHTTPScheme;

PT_LOCAL NSString * const PTNSURLHTTPSScheme;

@interface NSURL (PTAdditions)

@property (nonatomic, readonly, getter=pt_isHTTPURL) BOOL pt_HTTPURL;

@property (nonatomic, readonly, getter=pt_isHTTPSURL) BOOL pt_HTTPSURL;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSURL, PTAdditions)
PT_IMPORT_CATEGORY(NSURL, PTAdditions)
