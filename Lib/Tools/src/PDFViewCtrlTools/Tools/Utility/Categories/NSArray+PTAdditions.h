//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<ObjectType> (PTAdditions)

- (NSArray<ObjectType> *)pt_arrayByInsertingObject:(ObjectType)object atIndex:(NSInteger)index;

- (NSArray<ObjectType> *)pt_arrayByRemovingObject:(ObjectType)object;

- (NSArray<ObjectType> *)pt_arrayByRemovingObjectAtIndex:(NSUInteger)index;

- (NSArray<ObjectType> *)pt_arrayByReplacingObjectAtIndex:(NSUInteger)index withObject:(ObjectType)object;

- (NSArray<id> *)pt_mapObjectsWithBlock:(id _Nullable (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop))block;

- (NSArray<ObjectType> *)pt_objectsPassingTest:(BOOL (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop))predicate;

- (nullable ObjectType)pt_objectPassingTest:(BOOL (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop))predicate;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSArray, PTAdditions)
PT_IMPORT_CATEGORY(NSArray, PTAdditions)
