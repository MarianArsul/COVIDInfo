//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAutoCoding.h"

#import "Runtime.h"

#include <objc/runtime.h>

@implementation PTAutoCoding

+ (void)PT_encodeIvar:(Ivar)ivar ofObject:(id)object forProperty:(objc_property_t)property withCoder:(NSCoder *)coder
{
    NSParameterAssert(property != nil);
    
    NSString *key = [NSString stringWithUTF8String:property_getName(property)];
    NSAssert(key != nil, @"Cannot encode property ivar without a property name");
    
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (!typeEncoding) {
        // No type encoding information.
        return;
    }
    
    switch (typeEncoding[0]) {
        case _C_ID:
        {
            id value = object_getIvar(object, ivar);
            if (value) {
                // Only encode object values conforming to the NSCoding protocol.
                if ([value conformsToProtocol:@protocol(NSCoding)]) {
                    // Check if the property is weak. Weak properties should be conditionally
                    // encoded so that they are only actually serialized if the object value
                    // is unconditionally encoded at least once somewhere else in the archive.
                    char *weakAttributeValue = property_copyAttributeValue(property, PT_PROPERTY_ATTRIBUTE_WEAK);
                    if (weakAttributeValue) {
                        free(weakAttributeValue);
                        
                        // Conditionally encode weak property/ivar object values.
                        [coder encodeConditionalObject:value forKey:key];
                    } else {
                        // Unconditionally encode object value.
                        [coder encodeObject:value forKey:key];
                    }
                }
            }
        }
            break;
        case _C_CLASS:
        {
            Class value = object_getIvar(object, ivar);
            if (value) {
                [coder encodeObject:NSStringFromClass(value) forKey:key];
            }
        }
            break;
        case _C_SEL:
        {
            SEL value = *((SEL *)pt_object_getIvarValue(object, ivar));
            if (value) {
                [coder encodeObject:NSStringFromSelector(value) forKey:key];
            }
        }
            break;
        case _C_INT:
        {
            int value = *((int *)pt_object_getIvarValue(object, ivar));
            [coder encodeInt:value forKey:key];
        }
            break;
        case _C_BOOL:
        {
            BOOL value = *((BOOL *)pt_object_getIvarValue(object, ivar));
            [coder encodeBool:value forKey:key];
        }
            break;
        case _C_LNG_LNG:
        {
            long long value = *((long long *)pt_object_getIvarValue(object, ivar));
            switch (sizeof(value)) {
                case sizeof(int64_t):
                    [coder encodeInt64:value forKey:key];
                    break;
                case sizeof(int32_t):
                    [coder encodeInt32:value forKey:key];
                    break;
                default:
                    // Unknown size.
                    break;
            }
        }
            break;
        case _C_ULNG_LNG:
        {
            unsigned long long value = *((unsigned long long *)pt_object_getIvarValue(object, ivar));
            
            const uint8_t *bytes = (uint8_t *)&value;
            [coder encodeBytes:bytes length:sizeof(value) forKey:key];
        }
            break;
        case _C_DBL:
        {
            double value = *((double *)pt_object_getIvarValue(object, ivar));
            [coder encodeDouble:value forKey:key];
        }
            break;
        default:
            break;
    }
}

+ (void)PT_decodeIvar:(Ivar)ivar ofObject:(id)object forProperty:(objc_property_t)property withCoder:(NSCoder *)coder
{
    NSParameterAssert(property != nil);
    
    NSString *key = [NSString stringWithUTF8String:property_getName(property)];
    NSAssert(key != nil, @"Cannot encode property ivar without a property name");
    
    // Skip keys not present in coder.
    if (![coder containsValueForKey:key]) {
        return;
    }
    
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (!typeEncoding) {
        // No type encoding information.
        return;
    }
    
    switch (typeEncoding[0]) {
        case _C_ID:
        {
            id value = nil;
            Class cls = nil;
            if (coder.requiresSecureCoding) {
                cls = pt_getClassForTypeEncoding(typeEncoding);
            }
            if (cls) {
                value = [coder decodeObjectOfClass:cls forKey:key];
            } else {
                value = [coder decodeObjectForKey:key];
            }
            object_setIvar(object, ivar, value);
        }
            break;
        case _C_CLASS:
        {
            NSString *stringValue = [coder decodeObjectOfClass:[NSString class] forKey:key];
            Class value = NSClassFromString(stringValue);
            object_setIvar(object, ivar, value);
        }
            break;
        case _C_SEL:
        {
            SEL value = nil;
            id stringValue = [coder decodeObjectForKey:key];
            if ([stringValue isKindOfClass:[NSString class]]) {
                value = NSSelectorFromString((NSString *)stringValue);
            }
            pt_object_setIvarValue(object, ivar, &value, sizeof(value));
        }
            break;
        case _C_INT:
        {
            int value = [coder decodeIntForKey:key];
            pt_object_setIvarValue(object, ivar, &value, sizeof(value));
        }
            break;
        case _C_BOOL:
        {
            BOOL value = [coder decodeBoolForKey:key];
            pt_object_setIvarValue(object, ivar, &value, sizeof(value));
        }
            break;
        case _C_LNG_LNG:
        {
            long long value = 0;
            size_t size = sizeof(value);
            if (size == sizeof(int64_t)) {
                value = [coder decodeInt64ForKey:key];
            }
            else if (size == sizeof(int32_t)) {
                value = [coder decodeInt32ForKey:key];
            }
            else {
                // Unknown size.
                break;
            }
            pt_object_setIvarValue(object, ivar, &value, size);
        }
            break;
        case _C_ULNG_LNG:
        {
            unsigned long long value = 0;

            NSUInteger length = 0;
            const uint8_t *bytes = [coder decodeBytesForKey:key returnedLength:&length];
            
            // Ensure length of bytes is correct.
            if (length == sizeof(value)) {
                memcpy(&value, bytes, length);
                pt_object_setIvarValue(object, ivar, &value, sizeof(value));
            }
        }
            break;
        case _C_DBL:
        {
            double value = [coder decodeDoubleForKey:key];
            pt_object_setIvarValue(object, ivar, &value, sizeof(value));
        }
            break;
        default:
            break;
    }
}

+ (void)PT_enumeratePropertyIvarsForClass:(Class)cls usingBlock:(void (^)(objc_property_t property, Ivar ivar))block
{
    // Get the list of all properties for the class.
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    cleanup({
        free(properties);
    })
    
    for (unsigned int propertyIndex = 0; propertyIndex < propertyCount; propertyIndex++) {
        objc_property_t property = properties[propertyIndex];
        
        // Check if the property is backed by an ivar.
        Ivar ivar = pt_class_getPropertyIvar(cls, property);
        if (!ivar) {
            // No ivar found for the property.
            continue;
        }
        
        if (block) {
            block(property, ivar);
        }
    }
}

+ (void)autoArchiveObject:(id)object withCoder:(NSCoder *)coder
{
    // Walk up the object's class hierarchy, enumerating the list of (instance) properties at each level.
    for (Class cls = [object class]; cls && ![cls isEqual:[NSObject class]]; cls = [cls superclass]) {
        [self autoArchiveObject:object ofClass:cls forKeys:nil withCoder:coder];
    }
}

+ (void)autoArchiveObject:(id)object ofClass:(Class)cls forKeys:(NSArray<NSString *> *)keys withCoder:(NSCoder *)coder
{
    // Enumerate all properties backed by an ivar.
    [self PT_enumeratePropertyIvarsForClass:cls usingBlock:^(objc_property_t property, Ivar ivar) {
        if (keys) {
            // Check if this property should be encoded.
            NSString *key = [NSString stringWithUTF8String:property_getName(property)];
            if (key && ![keys containsObject:key]) {
                // Skip encoding this property.
                return;
            }
        }
        // Encode the ivar, with the property name as the key.
        [self PT_encodeIvar:ivar ofObject:object forProperty:property withCoder:coder];
    }];
}

+ (void)autoUnarchiveObject:(id)object withCoder:(NSCoder *)coder
{
    // Walk up the object's class hierarchy, enumerating the list of (instance) properties at each level.
    for (Class cls = [object class]; cls && ![cls isEqual:[NSObject class]]; cls = [cls superclass]) {
        [self autoUnarchiveObject:object ofClass:cls withCoder:coder];
    }
}

+ (void)autoUnarchiveObject:(id)object ofClass:(Class)cls withCoder:(NSCoder *)coder
{
    // Enumerate all properties backed by an ivar.
    [self PT_enumeratePropertyIvarsForClass:cls usingBlock:^(objc_property_t property, Ivar ivar) {
        // Decode the ivar, with the property name as the key.
        [self PT_decodeIvar:ivar ofObject:object forProperty:property withCoder:coder];
    }];
}

@end
