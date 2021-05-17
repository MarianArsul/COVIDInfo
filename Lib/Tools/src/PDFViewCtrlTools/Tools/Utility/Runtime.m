//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "Runtime.h"

Class pt_getClassForTypeEncoding(const char *typeEncoding)
{
    if (!typeEncoding) {
        return Nil;
    }
    
    const size_t typeLength = strlen(typeEncoding);
    
    // Check that the type encoding is for an object (id) and (possibly) contains the class name.
    // Examples of possible object type encodings are:
    //  @ : `id`
    //  @"NSObject" : `NSObject *`
    //  @"NSObject<NSCoding>" : `NSObject<NSCoding> *`
    //  @"NSObject<NSCoding><NSCopying>" : `NSObject<NSCoding, NSCopying> *`
    //  @"<NSObject>" : `id<NSObject>`
    //  @"<NSCoding><NSCopying>" : `id<NSCoding, NSCopying>`
    ///
    const char *objectTypeEncoding = @encode(id);
    const size_t objectTypeLength = strlen(objectTypeEncoding);
    if (strncmp(typeEncoding, objectTypeEncoding, objectTypeLength) != 0
        || typeLength <= objectTypeLength) {
        return Nil;
    }
    
    const char *objectTypeInformation = typeEncoding + objectTypeLength;
    
    // Check that the (non-empty) name is enclosed in quotes (").
    const char *leadingQuote = strchr(objectTypeInformation, '"');
    const char *trailingQuote = strrchr(objectTypeInformation, '"');
    
    if (!leadingQuote || !trailingQuote || (trailingQuote - leadingQuote) <= 1) {
        return Nil;
    }
    
    // Trim the leading and trailing quotes from the class name.
    const size_t trimmedLength = trailingQuote - leadingQuote;
    char trimmedName[trimmedLength];
    
    strncpy(trimmedName, leadingQuote + 1, trimmedLength - 1);
    trimmedName[trimmedLength - 1] = '\0';
    
    char *className = trimmedName;
    size_t classLength = trimmedLength - 1;
    
    // Check for protocols (<...>) in the type encoding.
    const char *openingAngleBracket = strchr(className, '<');
    const char *closingAngleBracket = strrchr(className, '>');
    
    if (openingAngleBracket && closingAngleBracket && (closingAngleBracket - openingAngleBracket) > 0) {
        // Strip protocols from name and update class name length.
        classLength = openingAngleBracket - className;
        if (classLength > 0) {
            className[classLength - 1] = '\0';
        } else {
            className[0] = '\0';
        }
    }
    
    if (classLength > 0) {
        return objc_getClass(className);
    }
    
    // No class name found.
    return Nil;
}

Class pt_property_getClass(objc_property_t property)
{
    char *typeEncoding = property_copyAttributeValue(property, PT_PROPERTY_ATTRIBUTE_TYPE);
    cleanup({
        free(typeEncoding);
    })
    
    return pt_getClassForTypeEncoding(typeEncoding);
}

Ivar _Nullable pt_class_findKeyValueCodingIvar(Class cls, const char *key)
{
    Ivar ivar = nil;
    
    char *ivarName = NULL;
    cleanup({
        free(ivarName);
    })
    
    // Check for _<key>
    asprintf(&ivarName, "_%s", key);
    ivar = class_getInstanceVariable(cls, ivarName);
    if (ivar) {
        return ivar;
    }
    
    clear(ivarName);
    
    // Capitalize <key> => <Key>
    char *capitalizedKey = strdup(key);
    if (capitalizedKey && isalpha(capitalizedKey[0])) {
        capitalizedKey[0] = toupper(capitalizedKey[0]);
    }
    cleanup({
        free(capitalizedKey);
    })
    
    // Check for _is<Key>
    asprintf(&ivarName, "_is%s", capitalizedKey);
    ivar = class_getInstanceVariable(cls, ivarName);
    if (ivar) {
        return ivar;
    }
    
    clear(ivarName);
    
    // Check for <key>
    ivar = class_getInstanceVariable(cls, key);
    if (ivar) {
        return ivar;
    }
    
    // Check for is<Key>
    asprintf(&ivarName, "is%s", capitalizedKey);
    ivar = class_getInstanceVariable(cls, ivarName);
    if (ivar) {
        return ivar;
    }
    
    clear(ivarName);
    
    // No ivar found.
    return nil;
}

Ivar _Nullable pt_class_getPropertyIvar(Class cls, objc_property_t property)
{
    char *ivarName = property_copyAttributeValue(property, PT_PROPERTY_ATTRIBUTE_IVAR);
    if (ivarName) {
        Ivar ivar = class_getInstanceVariable(cls, ivarName);
        free(ivarName);
        return ivar;
    }
    
    const char *propertyName = property_getName(property);
    
    return pt_class_findKeyValueCodingIvar(cls, propertyName);
}

void *pt_object_getIvarValue(id object, Ivar ivar)
{
    NSCParameterAssert(object != nil);
    
    const ptrdiff_t ivarOffset = ivar_getOffset(ivar);
    
#ifdef DEBUG
    const size_t instanceSize = class_getInstanceSize([object class]);
    NSCAssert(ivarOffset <= instanceSize,
              @"ivar offset %td must be less than size of object %zd for object %@",
              ivarOffset, instanceSize, object);
#endif
    
    void *objectPtr = (__bridge void *)(object);
    return (objectPtr + ivarOffset);
}

void pt_object_setIvarValue(id object, Ivar ivar, void *value, size_t size)
{
    NSCParameterAssert(object != nil);
    NSCParameterAssert(value != nil);
    NSCAssert(size > 0, @"size must be greater than zero");
    
    const ptrdiff_t ivarOffset = ivar_getOffset(ivar);
    
#ifdef DEBUG
    const size_t instanceSize = class_getInstanceSize([object class]);
    NSCAssert((ivarOffset + size) <= instanceSize,
              @"ivar offset %td + size %zd must be less than size of object %zd for object %@",
              ivarOffset, size, instanceSize, object);
#endif
    
    void *objectPtr = (__bridge void *)(object);
    void *ivarPtr = (objectPtr + ivarOffset);
    
    memcpy(ivarPtr, value, size);
}
