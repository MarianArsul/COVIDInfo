//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The `PTOverrides` class is used to register overridden subclasses of classes defined in the Tools
 * library. Once a class conforming to the `PTOverridable` protocol has been "overridden", whenever an
 * instance of the original class would be created the subclass is used instead.
 */
@interface PTOverrides : NSObject

/**
 * Override the given class with a subclass.
 *
 * @param cls the class to override, conforming to the `PTOverridable` protocol
 *
 * @param subclass the subclass to use in place of the `cls`
 */
+ (void)overrideClass:(Class)cls withClass:(Class)subclass;

/**
 * Returns the overridden subclass for the given class, if one has been registered.
 *
 * @param cls the original class
 *
 * @return the overridden subclass, or `Nil` if one has not been registered
 */
+ (nullable Class)overriddenClassForClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
