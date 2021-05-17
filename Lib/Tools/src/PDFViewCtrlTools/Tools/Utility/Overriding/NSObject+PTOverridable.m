//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSObject+PTOverridable.h"

#import "ToolsDefines.h"
#import "PTOverridable.h"
#import "PTOverrides.h"

@implementation NSObject (PTOverridable)

+ (instancetype)allocOverridden
{
    // Check if this class conforms to the PTOverridable protocol.
    if (![self conformsToProtocol:@protocol(PTOverridable)]) {
        PTLog(@"Class \"%@\" is not overridable", NSStringFromClass(self));
        return [self alloc];
    }
    
    // Get the overridden subclass for this class.
    Class overriddenClass = [PTOverrides overriddenClassForClass:self];
    if (overriddenClass) {
        return [overriddenClass alloc];
    }
    
    // Create an instance of this class normally.
    return [self alloc];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSObject, PTOverridable)
