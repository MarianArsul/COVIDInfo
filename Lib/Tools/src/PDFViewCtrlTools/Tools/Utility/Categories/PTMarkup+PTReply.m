//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTMarkup+PTReply.h"

#define PTMARKUP_ENTRY_IRT @"IRT"
#define PTMARKUP_ENTRY_RT @"RT"

@implementation PTMarkup (PTReply)

#pragma mark - Convenience

- (BOOL)isReply
{
    PTObj *obj = [self GetSDFObj];
    if (![obj IsValid]) {
        return NO;
    }
    
    // Check for the markup annotation's IRT ("in reply to") entry.
    PTObj *irtObj = [obj FindObj:PTMARKUP_ENTRY_IRT];
    if ([irtObj IsValid] && ([irtObj IsDict] || [irtObj IsString])) {
        
        // Check for the markup annotation's RT ("reply type") entry.
        PTObj *rtObj = [obj FindObj:PTMARKUP_ENTRY_RT];
        if ([rtObj IsValid] && [rtObj IsName]) {
            // Possible values: R, Group
            if ([[rtObj GetName] isEqualToString:@"Group"]) {
                return NO;
            }
            
            // Default reply type: R
            return YES;
        }
        
        // Default reply type: R
        return YES;
    }
    
    return NO;
}

- (BOOL)isInReplyToAnnot:(PTAnnot *)annot
{
    PTObj *obj = [self GetSDFObj];
    if (![obj IsValid]) {
        return NO;
    }
    
    PTObj *irtObj = [obj FindObj:PTMARKUP_ENTRY_IRT];
    if (![irtObj IsValid]) {
        return NO;
    }
    
    if ([irtObj IsDict]) {
        return [irtObj isEqualTo:[annot GetSDFObj]];
    }
    else if ([irtObj IsString]) {
        NSString *irtString = [irtObj GetAsPDFText];
        
        PTObj *uniqueIdObj = [annot GetUniqueID];
        if ([uniqueIdObj IsValid] && [uniqueIdObj IsString]) {
            return [irtString isEqualToString:[uniqueIdObj GetAsPDFText]];
        }
    }
    
    return NO;
}

#pragma mark - inReplyToAnnot

- (PTAnnot *)inReplyToAnnot
{
    PTObj *obj = [self GetSDFObj];
    if (![obj IsValid]) {
        return nil;
    }
    
    // Check for the markup annotation's IRT ("in reply to") entry.
    PTObj *irtObj = [obj FindObj:PTMARKUP_ENTRY_IRT];
    if ([irtObj IsValid] && [irtObj IsDict]) {
        return [[PTAnnot alloc] initWithD:irtObj];
    }
    
    return nil;
}

- (void)setInReplyToAnnot:(PTAnnot *)annot
{
    PTObj *obj = [self GetSDFObj];
    if (![self IsValid]) {
        return;
    }
    
    if (annot) {
        PTObj *annotObj = [annot GetSDFObj];
        if (![annot IsValid]) {
            return;
        }
        
        // Set IRT entry.
        [obj Put:PTMARKUP_ENTRY_IRT obj:annotObj];
    } else {
        // Remove existing IRT entry.
        [obj EraseDictElementWithKey:PTMARKUP_ENTRY_IRT];
    }
}

#pragma mark - inReplyToAnnotId

- (NSString *)inReplyToAnnotId
{
    PTObj *obj = [self GetSDFObj];
    if (![obj IsValid]) {
        return nil;
    }
    
    // Check for the markup annotation's IRT ("in reply to") entry.
    PTObj *irtObj = [obj FindObj:PTMARKUP_ENTRY_IRT];
    if ([irtObj IsValid] && [irtObj IsString]) {
        return [irtObj GetAsPDFText];
    }
    
    return nil;
}

- (void)setInReplyToAnnotId:(NSString *)annotId
{
    PTObj *obj = [self GetSDFObj];
    if (![self IsValid]) {
        return;
    }
    
    if (annotId.length > 0) {
        // Set IRT entry.
        [obj PutString:PTMARKUP_ENTRY_IRT value:annotId];
    } else {
        // Remove existing IRT entry.
        [obj EraseDictElementWithKey:PTMARKUP_ENTRY_IRT];
    }
}

#pragma mark - replyType

- (PTMarkupReplyType)replyType
{
    PTObj *obj = [self GetSDFObj];
    if (![obj IsValid]) {
        return PTMarkupReplyTypeNone;
    }
    
    // Check value of RT entry.
    PTObj *rtObj = [obj FindObj:PTMARKUP_ENTRY_RT];
    if ([rtObj IsValid] && [rtObj IsName]) {
        // Possible values: R, Group
        if ([[rtObj GetName] isEqualToString:@"Group"]) {
            return PTMarkupReplyTypeGroup;
        }
        
        // Default: Reply
        return PTMarkupReplyTypeReply;
    }
    
    // Default: Reply
    return PTMarkupReplyTypeReply;
}

- (void)setReplyType:(PTMarkupReplyType)replyType
{
    PTObj *obj = [self GetSDFObj];
    if (![obj IsValid]) {
        return;
    }

    switch (replyType) {
        case PTMarkupReplyTypeNone:
            // Remove existing RT entry.
            [obj EraseDictElementWithKey:PTMARKUP_ENTRY_RT];
            break;
        case PTMarkupReplyTypeReply:
            // Set RT entry to "reply" type.
            [obj PutName:PTMARKUP_ENTRY_RT name:@"R"];
            break;
        case PTMarkupReplyTypeGroup:
            // Set RT entry to "Group" type.
            [obj PutName:PTMARKUP_ENTRY_RT name:@"Group"];
            break;
        default:
        {
            // Throw invalid argument exception.
            NSString *reason = [NSString stringWithFormat:@"Unknown reply type: %lu", (unsigned long)replyType];
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:reason
                                         userInfo:nil];
            return;
        }
    }
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTMarkup, PTReply)
