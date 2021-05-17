//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSObject+PTAdditions.h"

#import "Runtime.h"

@implementation NSObject (PTAdditions)

- (id)pt_castAsKindOfClass:(Class)cls
{
    return [cls pt_castAsKindFromObject:self];
}

- (id)pt_castAsMemberOfClass:(Class)cls
{
    return [cls pt_castAsMemberFromObject:self];
}

+ (nullable instancetype)pt_castAsKindFromObject:(nullable id)object
{
    if ([object isKindOfClass:self]) {
        return object;
    }
    return nil;
}

+ (nullable instancetype)pt_castAsMemberFromObject:(nullable id)object
{
    if ([object isMemberOfClass:self]) {
        return object;
    }
    return nil;
}

#pragma mark - Property names

+ (void)pt_enumeratePropertiesForClass:(Class)cls usingBlock:(void (^)(objc_property_t property, BOOL *stop))block
{
    BOOL stop = NO;
    
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    
    cleanup({
        free(properties);
    })
    
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        
        block(property, &stop);
        
        if (stop) {
            break;
        }
    }
}

+ (NSDictionary<NSString *, Class> *)pt_generateLocalPropertyClassesForClass:(Class)cls
{
    NSMutableDictionary<NSString *, Class> *mutableClasses = [NSMutableDictionary dictionary];
    
    [self pt_enumeratePropertiesForClass:cls usingBlock:^(objc_property_t property, BOOL *stop) {
        NSString *key = [NSString stringWithUTF8String:property_getName(property)];
        
        Class propertyClass = pt_property_getClass(property);
        if (propertyClass) {
            mutableClasses[key] = propertyClass;
        }
    }];
    
    return [mutableClasses copy];
}

static void * NSObject_pt_LocalPropertyClassesKey = &NSObject_pt_LocalPropertyClassesKey;

+ (NSDictionary<NSString *, Class> *)pt_localPropertyClassesForClass:(Class)cls
{
    if ([cls isEqual:[NSObject class]]) {
        return nil;
    }
    
    // Check for cached property classes.
    NSDictionary<NSString *, Class> *cachedClasses = objc_getAssociatedObject(cls, NSObject_pt_LocalPropertyClassesKey);
    if (cachedClasses) {
        return cachedClasses;
    }
    
    // Generate property classes.
    NSDictionary<NSString *, Class> *classes = [self pt_generateLocalPropertyClassesForClass:cls];
    
    // Cache property classes.
    objc_setAssociatedObject(cls, NSObject_pt_LocalPropertyClassesKey, classes, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    return classes;
}

+ (NSSet<NSString *> *)pt_propertyNamesForKindOfClass:(Class)aClass
{
    // Collect the classes to query, with the least derived class first.
    // This is done to support subclasses who override properties from their superclass with a different
    // type.
    NSMutableArray<Class> *mutableClassesToQuery = [NSMutableArray array];
    for (Class cls = self; ![cls isEqual:[NSObject class]]; cls = [cls superclass]) {
        [mutableClassesToQuery insertObject:cls atIndex:0];
    }
    NSArray<Class> *classesToQuery = [mutableClassesToQuery copy];
    
    NSMutableSet<NSString *> *allNames = [NSMutableSet set];
    
    for (Class cls in classesToQuery) {
        NSDictionary<NSString *, Class> *classes = [self pt_localPropertyClassesForClass:cls];
        
        [classes enumerateKeysAndObjectsUsingBlock:^(NSString *key, Class class, BOOL *stop) {
            if ([class isSubclassOfClass:aClass]) {
                [allNames addObject:key];
            }
        }];
    }
    
    return [allNames copy];
}

- (void)pt_changeValueForKey:(NSString *)key withBlock:(void (NS_NOESCAPE ^)(void))block
{
    if (!block) {
        return;
    }
    
    [self willChangeValueForKey:key];
    
    block();
    
    [self didChangeValueForKey:key];
}

#pragma mark - Associated objects

static void * const pt_NSObject_keyMapTable = (void *)&pt_NSObject_keyMapTable;

- (nullable NSMapTable *)pt_keyMapTable
{
    return objc_getAssociatedObject(self, pt_NSObject_keyMapTable);
}

- (NSMapTable *)pt_createKeyMapTable
{
    NSMapTable *keyMapTable = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsCopyIn |
                                                                  NSPointerFunctionsObjectPersonality)
                                                    valueOptions:(NSPointerFunctionsMallocMemory |
                                                                  NSPointerFunctionsOpaquePersonality)];
    objc_setAssociatedObject(self,
                             pt_NSObject_keyMapTable,
                             keyMapTable,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return keyMapTable;
}

- (nullable void *)pt_pointerKeyValueForKey:(NSString *)key createIfAbsent:(BOOL)createIfAbsent
{
    NSMapTable *keyMapTable = [self pt_keyMapTable];
    if (!keyMapTable && !createIfAbsent) {
        return NULL;
    }
    void *pointerKey = NULL;
    if (keyMapTable) {
        pointerKey = NSMapGet(keyMapTable, (__bridge const void *)key);
    }
    if (!pointerKey && createIfAbsent) {
        if (!keyMapTable) {
            keyMapTable = [self pt_createKeyMapTable];
        }
        NSAssert(keyMapTable != nil, @"Key map-table must be nonnull");
        
        pointerKey = malloc(sizeof(pointerKey));
        if (!pointerKey) {
            return NULL;
        }
        
        NSMapInsert(keyMapTable, (__bridge const void *)key, pointerKey);
    }
    return pointerKey;
}

static objc_AssociationPolicy pt_associationPolicyFromAttributes(PTAssociatedObjectAttributes attributes)
{
    if (PT_BITMASK_CHECK(attributes, PTAssociatedObjectNonatomicAttribute)) {
        if (PT_BITMASK_CHECK(attributes, PTAssociatedObjectCopyAttribute)) {
            return OBJC_ASSOCIATION_COPY_NONATOMIC;
        } else {
            return OBJC_ASSOCIATION_RETAIN_NONATOMIC;
        }
    } else {
        if (PT_BITMASK_CHECK(attributes, PTAssociatedObjectCopyAttribute)) {
            return OBJC_ASSOCIATION_COPY;
        } else {
            return OBJC_ASSOCIATION_RETAIN;
        }
    }
}

- (void)pt_setAssociatedObject:(id)associatedObject withAttributes:(PTAssociatedObjectAttributes)attributes forKey:(NSString *)key
{
    if (!associatedObject) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Cannot set null associated object"
                                     userInfo:nil];
        return;
    }
    if (!key) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Cannot set associated object with null key"
                                     userInfo:nil];
        return;
    }
    
    void * const pointerKey = [self pt_pointerKeyValueForKey:key
                                              createIfAbsent:YES];
    if (!pointerKey) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Could not set associated object"
                                     userInfo:nil];
    }
    
    // Get the association policy described by the associated object attributes.
    const objc_AssociationPolicy associationPolicy = pt_associationPolicyFromAttributes(attributes);
    
    objc_setAssociatedObject(self,
                             pointerKey,
                             associatedObject,
                             associationPolicy);
}

- (nullable id)pt_associatedObjectForKey:(NSString *)key
{
    if (!key) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Cannot get associated object with null key"
                                     userInfo:nil];
        return nil;
    }
    
    void * const pointerKey = [self pt_pointerKeyValueForKey:key
                                              createIfAbsent:NO];
    if (!pointerKey) {
        // Key is not registered in the mapping, so no associated object can be set.
        return nil;
    }
    
    return objc_getAssociatedObject(self, pointerKey);
}

- (void)pt_removeAssociatedObjectForKey:(NSString *)key
{
    if (!key) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Cannot remove associated object with null key"
                                     userInfo:nil];
        return;
    }
    
    void * const pointerKey = [self pt_pointerKeyValueForKey:key
                                              createIfAbsent:NO];
    if (!pointerKey) {
        // Key is not registered in the mapping, so no associated object can be set.
        // (ie. nothing to remove)
        return;
    }

    objc_setAssociatedObject(self,
                             pointerKey,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSObject, PTAdditions)
