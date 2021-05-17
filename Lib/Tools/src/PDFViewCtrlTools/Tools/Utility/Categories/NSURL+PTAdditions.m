//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSURL+PTAdditions.h"

NSString * const PTNSURLHTTPScheme = @"http";

NSString * const PTNSURLHTTPSScheme = @"https";

@implementation NSURL (PTAdditions)

- (BOOL)pt_isHTTPURL
{
    return [self.scheme.lowercaseString isEqualToString:PTNSURLHTTPScheme];
}

- (BOOL)pt_isHTTPSURL
{
    return [self.scheme.lowercaseString isEqualToString:PTNSURLHTTPSScheme];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSURL, PTAdditions)
