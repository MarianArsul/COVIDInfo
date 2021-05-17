//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface NSString (PTTypedCopying)

- (NSString *)copy;

- (NSMutableString *)mutableCopy;

@end

@interface NSArray<ObjectType> (PTTypedCopying)

- (NSArray<ObjectType> *)copy;

- (NSMutableArray<ObjectType> *)mutableCopy;

@end

@interface NSSet<ObjectType> (PTTypedCopying)

- (NSSet<ObjectType> *)copy;

- (NSMutableSet<ObjectType> *)mutableCopy;

@end

@interface NSDictionary<KeyType, ObjectType> (PTTypedCopying)

- (NSDictionary<KeyType, ObjectType> *)copy;

- (NSMutableDictionary<KeyType, ObjectType> *)mutableCopy;

@end

@interface NSOrderedSet<ObjectType> (PTTypedCopying)

- (NSOrderedSet<ObjectType> *)copy;

- (NSMutableOrderedSet<ObjectType> *)mutableCopy;

@end

@interface NSHashTable<ObjectType> (PTTypedCopying)

- (NSHashTable<ObjectType> *)copy;

@end

@interface NSMapTable<KeyType, ObjectType> (PTTypedCopying)

- (NSMapTable <KeyType, ObjectType> *)copy;

@end
