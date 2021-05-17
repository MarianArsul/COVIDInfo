//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import "PTKeyValueObservedChange.h"
#import "PTKeyValueObservation.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTKeyValueObservation, PTKeyValueObservedChange;

@interface NSObject (PTKeyValueObserving)

// Add observer to receiver, calling the specified method on observer when changes occur.

- (void)pt_addObserver:(NSObject *)observer selector:(SEL)selector forKeyPath:(NSString *)keyPath;
- (void)pt_addObserver:(NSObject *)observer selector:(SEL)selector forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options;

// Add block as observer to receiver, calling the specified block when changes occur.

- (PTKeyValueObservation *)pt_addObserverForKeyPath:(NSString *)keyPath usingBlock:(void (^)(PTKeyValueObservedChange *change))block;
- (PTKeyValueObservation *)pt_addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(void (^)(PTKeyValueObservedChange *change))block;

// Add receiver as an observer to the specified object, calling the specified method on receiver when changes occur.

- (void)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath selector:(SEL)selector;
- (void)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath selector:(SEL)selector options:(NSKeyValueObservingOptions)options;

// Add block as observer to the specified object, calling the specified block when changes occur.

- (PTKeyValueObservation *)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath usingBlock:(void (^)(PTKeyValueObservedChange *change))block;
- (PTKeyValueObservation *)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(void (^)(PTKeyValueObservedChange *change))block;

// Remove all observations on <observer> with self as the object.

- (void)pt_removeObserver:(NSObject *)observer;

// Remove all observations on <observer> with self as the object and <keyPath> as the key path.

- (void)pt_removeObserver:(NSObject *)observer forKeyPath:(nullable NSString *)keyPath;

#pragma mark - Observations

// List of all the receiver's observations.
@property (nonatomic, copy, nullable, setter=pt_setObservations:) NSArray<PTKeyValueObservation *> *pt_observations;

// Removes all observations on the specified object from the receiver.
- (void)pt_removeObservationsForObject:(NSObject *)object;

// Removes all observations on the specified object and keypath from the receiver.
- (void)pt_removeObservationsForObject:(NSObject *)object keyPath:(nullable NSString *)keyPath;

// Removes all observations from the receiver.
- (void)pt_removeAllObservations;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSObject, PTKeyValueObserving)
PT_IMPORT_CATEGORY(NSObject, PTKeyValueObserving)
