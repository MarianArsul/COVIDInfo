//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, PTAssociatedObjectAttributes) {
    PTAssociatedObjectNonatomicAttribute NS_SWIFT_NAME(nonatomic) = 1 << 0,
    PTAssociatedObjectRetainAttribute NS_SWIFT_NAME(retain) = 1 << 1,
    PTAssociatedObjectCopyAttribute NS_SWIFT_NAME(copy) = 1 << 2,
};

@interface NSObject (PTAdditions)

- (nullable id)pt_castAsKindOfClass:(Class)cls;

- (nullable id)pt_castAsMemberOfClass:(Class)cls;

+ (nullable instancetype)pt_castAsKindFromObject:(nullable id)object;

+ (nullable instancetype)pt_castAsMemberFromObject:(nullable id)object;

/**
 * Returns the names of all properties whose class is a subclass of, or identical to, a given class.
 *
 * @param aClass A class object
 *
 * @return the names of all properties whose class is a subclass of, or identical to, `aClass`
 */
+ (NSSet<NSString *> *)pt_propertyNamesForKindOfClass:(Class)aClass;

- (void)pt_changeValueForKey:(NSString *)key withBlock:(void (NS_NOESCAPE ^)(void))block;

- (void)pt_setAssociatedObject:(id)associatedObject withAttributes:(PTAssociatedObjectAttributes)attributes forKey:(NSString *)key;
- (nullable id)pt_associatedObjectForKey:(NSString *)key;
- (void)pt_removeAssociatedObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSObject, PTAdditions)
PT_IMPORT_CATEGORY(NSObject, PTAdditions)
