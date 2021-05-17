//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTKeyValueObservedChange.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTKeyValueObservation : NSObject

@property (nonatomic, readonly, unsafe_unretained, nullable) NSObject *object;
@property (nonatomic, readonly, copy) NSString *keyPath;
@property (nonatomic, readonly, assign) NSKeyValueObservingOptions options;

@property (nonatomic, readonly, weak, nullable) NSObject *observer;
@property (nonatomic, readonly, assign, nullable) SEL selector;

@property (nonatomic, readonly, copy, nullable) void (^block)(PTKeyValueObservedChange *change);

- (instancetype)initWithObject:(NSObject *)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options observer:(NSObject *)observer selector:(SEL)selector NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithObject:(NSObject *)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(PTKeyValueObservedChange *change))block NS_DESIGNATED_INITIALIZER;

- (void)invalidate;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
