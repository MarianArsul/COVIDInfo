//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSLayoutConstraint+PTPriority.h"

@implementation NSLayoutConstraint (PTPriority)

+ (NSArray<NSLayoutConstraint *> *)pt_constraints:(NSArray<NSLayoutConstraint *> *)constraints withPriority:(UILayoutPriority)priority
{
    for (NSLayoutConstraint *constraint in constraints) {
        constraint.priority = priority;
    }
    return constraints;
}

+ (void)pt_activateConstraints:(NSArray<NSLayoutConstraint *> *)constraints withPriority:(UILayoutPriority)priority
{
    [self activateConstraints:[self pt_constraints:constraints
                                      withPriority:priority]];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSLayoutConstraint, PTPriority)
