//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSArray+PTAdditions.h"

@implementation NSArray (PTAdditions)

- (NSArray *)pt_arrayByInsertingObject:(id)object atIndex:(NSInteger)index
{
    NSMutableArray<id> *result = [self mutableCopy];
    [result insertObject:object atIndex:index];
    return [result copy];
}

- (NSArray<id> *)pt_arrayByRemovingObject:(id)object
{
    NSMutableArray<id> *result = [self mutableCopy];
    [result removeObject:object];
    return [result copy];
}

- (NSArray *)pt_arrayByRemovingObjectAtIndex:(NSUInteger)index
{
    NSMutableArray<id> *result = [self mutableCopy];
    [result removeObjectAtIndex:index];
    return [result copy];
}

- (NSArray *)pt_arrayByReplacingObjectAtIndex:(NSUInteger)index withObject:(id)object
{
    NSMutableArray<id> *result = [self mutableCopy];
    [result replaceObjectAtIndex:index withObject:object];
    return [result copy];
}

- (NSArray *)pt_mapObjectsWithBlock:(id (NS_NOESCAPE ^)(id, NSUInteger, BOOL *))block
{
    if (!block) {
        return nil;
    }
    
    NSMutableArray<id> *results = [NSMutableArray array];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id result = block(obj, idx, stop);
        if (result) {
            [results addObject:result];
        }
    }];
    
    // Return the correct type of array.
    return ([self isKindOfClass:[NSMutableArray class]]) ? results : [results copy];
}

- (NSArray *)pt_objectsPassingTest:(BOOL (NS_NOESCAPE ^)(id, NSUInteger, BOOL *))predicate
{
    return [self objectsAtIndexes:[self indexesOfObjectsPassingTest:predicate]];
}

- (id)pt_objectPassingTest:(BOOL (NS_NOESCAPE ^)(id _Nonnull, NSUInteger, BOOL * _Nonnull))predicate
{
    const NSUInteger index = [self indexOfObjectPassingTest:predicate];
    if (index != NSNotFound) {
        return self[index];
    }
    return nil;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSArray, PTAdditions)
