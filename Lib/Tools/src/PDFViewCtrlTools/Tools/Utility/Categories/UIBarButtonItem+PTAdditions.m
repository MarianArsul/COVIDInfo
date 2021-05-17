//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIBarButtonItem+PTAdditions.h"

#include <objc/runtime.h>

@implementation UIBarButtonItem (PTAdditions)

+ (instancetype)pt_fixedSpaceItemWithWidth:(CGFloat)width
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    item.width = width;
    
    objc_setAssociatedObject(item,
                             @selector(pt_isFixedSpaceItem),
                             @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return item;
}

+ (instancetype)pt_flexibleSpaceItem
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    objc_setAssociatedObject(item,
                             @selector(pt_isFlexibleSpaceItem),
                             @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return item;
}

- (BOOL)pt_isFixedSpaceItem
{
    id value = objc_getAssociatedObject(self, @selector(pt_isFixedSpaceItem));
    if ([value isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)value).boolValue;
    }
    return NO;
}

- (BOOL)pt_isFlexibleSpaceItem
{
    id value = objc_getAssociatedObject(self, @selector(pt_isFlexibleSpaceItem));
    if ([value isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)value).boolValue;
    }
    return NO;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIBarButtonItem, PTAdditions)
