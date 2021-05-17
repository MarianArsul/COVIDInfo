//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsMacros.h"

#import <Foundation/Foundation.h>


PT_LOCAL const BOOL PT_ToolsMacCatalyst;

#define PT_PROPERTY_ATTRIBUTE_TYPE "T"
#define PT_PROPERTY_ATTRIBUTE_IVAR "V"
#define PT_PROPERTY_ATTRIBUTE_WEAK "W"

// full name: <prefix>_<id>_<suffix>
#define pt_cleanupBlockNameFull_(prefix, id, suffix) \
    PT_PASTE(prefix, PT_PASTE(_, PT_PASTE(id, PT_PASTE(_, suffix))))

#define pt_cleanupBlockName_ pt_cleanupBlockNameFull_(pt_cleanupBlock, __LINE__, __COUNTER__)

#define cleanup(x) \
__unused __strong pt_cleanupBlock pt_cleanupBlockName_ PT_CLEANUP(pt_executeCleanupBlock) = ^{(x);};

NS_ASSUME_NONNULL_BEGIN

typedef void (^pt_cleanupBlock)(void);

PT_LOCAL void pt_executeCleanupBlock(__strong pt_cleanupBlock _Nonnull * _Nonnull block);

PT_LOCAL BOOL PT_SelectorEqualToSelector(SEL lhs, SEL rhs);

__attribute__((annotate("returns_localized_nsstring")))
PT_LOCAL NSString *PT_LocalizationNotNeeded(NSString *s);

NS_ASSUME_NONNULL_END
