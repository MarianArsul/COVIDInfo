//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"

#import <Foundation/Foundation.h>

/**
 * Visibility
 */

#define PT_LOCAL PT_EXTERN __attribute__((visibility("hidden")))

/**
 * Preprocessor
 */

#define PT_STRINGIFY__(x) # x
#define PT_STRINGIFY(x) PT_STRINGIFY__(x)
#define PT_NS_STRINGIFY(x) @PT_STRINGIFY(x)

#define PT_PASTE__(x, y) x ## y
#define PT_PASTE(x, y) PT_PASTE__(x, y)

/*
 * Arrays
 */

#define PT_C_ARRAY_SIZE(array) (sizeof(array) / sizeof((array)[0]))

/**
 * Bitmasks
 */

#define PT_BITMASK_SET(x, mask) ((x) |= (mask))
#define PT_BITMASK_CLEAR(x, mask) ((x) &= (~(mask)))
#define PT_BITMASK_TOGGLE(x, mask) ((x) ^= (mask))
#define PT_BITMASK_CHECK(x, mask) (((x) & (mask)) == (mask))
#define PT_BITMASK_CHECK_ANY(x, mask) ((x) & (mask))

/**
 * Constructors and destructors
 */

#define PT_CONSTRUCTOR __attribute__((constructor))

#define PT_CONSTRUCTOR_PRIORITY(priority) __attribute__((constructor(priority)))

#define PT_DESTRUCTOR __attribute__((destructor))

#define PT_DESTRUCTOR_PRIORITY(priority) __attribute__((destructor(priority)))

/**
 * Variable cleanup (on scope-exit)
 */

#if __has_attribute(cleanup)
    #define PT_CLEANUP(function) __attribute__((cleanup(function)))
#else
    #define PT_CLEANUP(function)
#endif

#define clear(x) ((free(x)), (x = NULL))

/**
 * Property key paths
 */

#ifdef DEBUG
    #define PT_KEY(object, key) ((void)(NO && ((void)((object).key), NO)), PT_NS_STRINGIFY(key))
#else
    #define PT_KEY(object, key) PT_NS_STRINGIFY(key)
#endif /* DEBUG */

#define PT_KEY_PATH(object, keyPath) PT_KEY(object, keyPath)

#define PT_SELF_KEY(keyPath) PT_KEY(self, keyPath)
#define PT_SELF_KEY_PATH(keyPath) PT_SELF_KEY(keyPath)

#define PT_CLASS_KEY(cls, key) PT_KEY((cls *)nil, key)
#define PT_CLASS_KEY_PATH(cls, keyPath) PT_CLASS_KEY(cls, keyPath)

#define PT_PROTOCOL_KEY(protocol, key) PT_KEY((id<protocol>)nil, key)
#define PT_PROTOCOL_KEY_PATH(protocol, keyPath) PT_PROTOCOL_KEY(protocol, keyPath)

/**
 * Logging
 */

#define PT_NSStringFromBOOL(b) ((b) ? @"YES" : @"NO")

#ifdef DEBUG
    #define PTLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
    #define PTLog(format, ...) (void)0
#endif

#ifdef DEBUG
    #define PrivateLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
    #define PrivateLog(format, ...) (void)0
#endif

/**
 * Diagnostics
 */

#define PT_CLANG_DIAGNOSTIC_PUSH _Pragma(PT_STRINGIFY(clang diagnostic push))
#define PT_CLANG_DIAGNOSTIC_IGNORE(warning) _Pragma(PT_STRINGIFY(clang diagnostic ignored warning))
#define PT_CLANG_DIAGNOSTIC_POP _Pragma(PT_STRINGIFY(clang diagnostic pop))

/**
 * Warnings
 */

#define PT_WARNING_NAME(warning) "-W" warning

#define PT_IGNORE_WARNINGS_BEGIN(warning) \
    PT_CLANG_DIAGNOSTIC_PUSH \
    PT_CLANG_DIAGNOSTIC_IGNORE(PT_WARNING_NAME(warning))

#define PT_IGNORE_WARNINGS_END PT_CLANG_DIAGNOSTIC_POP

/**
 * guard control statement
 */

#define guard(expression) if ((expression)) {}

/**
 * Miscellaneous attributes.
 */

#if __has_attribute(pure)
    #define PT_PURE __attribute__((pure))
#else
    #define PT_PURE
#endif
