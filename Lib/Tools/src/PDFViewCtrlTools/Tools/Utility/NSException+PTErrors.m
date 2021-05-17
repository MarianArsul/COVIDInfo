//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTErrors.h"

NSErrorDomain const PTErrorDomain = @"PTErrorDomain";

@implementation NSException (PTAdditions)

- (NSError *)pt_error
{
    return [self pt_errorWithExtraUserInfo:nil];
}

- (NSError *)pt_errorWithExtraUserInfo:(NSDictionary<NSErrorUserInfoKey,id> *)extraUserInfo
{
    NSDictionary<NSErrorUserInfoKey, id> *userInfo = self.userInfo;
    if (!userInfo) {
        userInfo = @{
                     NSLocalizedDescriptionKey : self.name,
                     NSLocalizedFailureReasonErrorKey : self.reason,
                     };
    }
    
    if (extraUserInfo) {
        NSMutableDictionary<NSErrorUserInfoKey, id> *mutableUserInfo = [userInfo mutableCopy];
        [mutableUserInfo addEntriesFromDictionary:extraUserInfo];
        userInfo = [mutableUserInfo copy];
    }
    
    return [NSError errorWithDomain:PTErrorDomain code:0 userInfo:userInfo];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSException, PTError)
