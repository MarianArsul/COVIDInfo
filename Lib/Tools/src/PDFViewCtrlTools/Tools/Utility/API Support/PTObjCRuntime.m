//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTObjCRuntime.h"

#import <objc/runtime.h>

#if TARGET_OS_MACCATALYST
const BOOL PT_ToolsMacCatalyst = YES;
#else
const BOOL PT_ToolsMacCatalyst = NO;
#endif

void pt_executeCleanupBlock(__strong pt_cleanupBlock *block)
{
    NSCParameterAssert(block != nil);
    
    (*block)();
}

BOOL PT_SelectorEqualToSelector(SEL lhs, SEL rhs)
{
    return sel_isEqual(lhs, rhs);
}

NSString *PT_LocalizationNotNeeded(NSString *s)
{
    return s;
}
