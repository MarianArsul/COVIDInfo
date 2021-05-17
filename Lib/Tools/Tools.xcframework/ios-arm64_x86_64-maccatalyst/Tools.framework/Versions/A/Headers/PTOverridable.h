//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class conforming to the `PTOverridable` protocol can be overridden with a subclass, registered
 * with the `PTOverrides` class. Once registered, the provided subclass will be used instead of the
 * original class wherever an instance is created.
 */
@protocol PTOverridable <NSObject>
@optional

/**
 * Returns a new instance of the receiving class, or a subclass if the receiving class has been
 * overridden.
 *
 * @return a new instance of the receiving class or a subclass
 */
+ (instancetype)allocOverridden;

@end

NS_ASSUME_NONNULL_END
