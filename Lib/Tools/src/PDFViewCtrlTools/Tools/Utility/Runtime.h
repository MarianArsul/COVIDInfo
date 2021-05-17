//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"

#import <Foundation/Foundation.h>

#include <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL Class _Nullable pt_getClassForTypeEncoding(const char *typeEncoding);

PT_LOCAL Class _Nullable pt_property_getClass(objc_property_t property);

/**
 * Search for an ivar on the given class with the standard KVC names:
 * _<key>, _is<Key>, <key>, or is<Key>
 */
PT_LOCAL Ivar _Nullable pt_class_findKeyValueCodingIvar(Class cls, const char *key);

/**
 * Returns the backing ivar for the specified property on the given class. The property's synthesized
 * ivar is used if available, otherwise the standard KVC search pattern is used to find the ivar.
 */
PT_LOCAL Ivar _Nullable pt_class_getPropertyIvar(Class cls, objc_property_t property);

/**
 * Returns the value of the specified ivar on the given object. The value is returned by reference
 * and must be cast to the appropriate (pointer) type and then dereferenced. For example, an `int`
 * ivar would be accessed as follows:
 * @code
 * int value = *((int *)pt_object_getIvarValue(object, ivar));
 * @endcode
 */
PT_LOCAL void *pt_object_getIvarValue(id object, Ivar ivar);

/**
 * Sets the value of the specified ivar on the given object. The value must be passed by reference.
 * For example, an ivar would be accessed as follows:
 * @code
 * pt_object_setIvarValue(object, ivar, &value, sizeof(value));
 * @endcode
 */
PT_LOCAL void pt_object_setIvarValue(id object, Ivar ivar, void *value, size_t size);

NS_ASSUME_NONNULL_END
