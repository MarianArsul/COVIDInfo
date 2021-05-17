//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

/**
 * Visibility
 */

#ifdef __cplusplus
    #define PT_EXTERN extern "C"
#else
    #define PT_EXTERN extern
#endif

#define PT_EXPORT PT_EXTERN __attribute__((visibility("default")))

/**
 * Unavailability
 */

// PT_UNAVAILABLE_MSG(msg)

#if __has_attribute(unavailable)
    #if __has_extension(attribute_unavailable_with_message)
        #define PT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
    #else
        #define PT_UNAVAILABLE_MSG(msg) __attribute__((unavailable))
    #endif
#else
    #define PT_UNAVAILABLE_MSG(msg)
#endif

// PT_UNAVAILABLE

#define PT_UNAVAILABLE PT_UNAVAILABLE_MSG("")

#define PT_INIT_UNAVAILABLE \
- (instancetype)init PT_UNAVAILABLE; \
+ (instancetype)new PT_UNAVAILABLE;

#define PT_INIT_WITH_FRAME_UNAVAILABLE \
- (instancetype)initWithFrame:(CGRect)frame PT_UNAVAILABLE;

#define PT_INIT_WITH_CODER_UNAVAILABLE \
- (instancetype)initWithCoder:(NSCoder *)coder PT_UNAVAILABLE;

#define PT_INIT_WITH_NIB_NAME_BUNDLE_UNAVAILABLE \
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil PT_UNAVAILABLE;

/**
 * Deprecation
 */

#define PT_DEPRECATED_MSG(version, msg) \
DEPRECATED_MSG_ATTRIBUTE("Deprecated in PDFTron for iOS " #version ". " msg)

#define PT_DEPRECATED(version) PT_DEPRECATED_MSG(version, "")
