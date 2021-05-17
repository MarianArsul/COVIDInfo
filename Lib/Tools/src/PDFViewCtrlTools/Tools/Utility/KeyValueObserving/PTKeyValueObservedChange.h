//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTKeyValueObservedChange : NSObject

- (instancetype)initWithObject:(nullable id)object keyPath:(nullable NSString *)keyPath change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong, nullable) id object;
@property (nonatomic, readonly, copy, nullable) NSString *keyPath;
@property (nonatomic, readonly, copy, nullable) NSDictionary<NSKeyValueChangeKey, id> *change;

#pragma mark - Convenience

@property (nonatomic, readonly, assign) NSKeyValueChange kind;

@property (nonatomic, readonly, strong, nullable) id oldValue;
@property (nonatomic, readonly, strong, nullable) id NS_RETURNS_NOT_RETAINED newValue;

@property (nonatomic, readonly, copy, nullable) NSIndexSet *indexes;

@property (nonatomic, readonly, assign, getter=isPrior) BOOL prior;

@end

NS_ASSUME_NONNULL_END
