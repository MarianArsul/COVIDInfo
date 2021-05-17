//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSObject+PTKeyValueObserving.h"

#import <objc/runtime.h>

@implementation NSObject (PTKeyValueObserving)

#pragma mark - addObserver with selector

- (void)pt_addObserver:(NSObject *)observer selector:(SEL)selector forKeyPath:(NSString *)keyPath
{
    [self pt_addObserver:observer selector:selector forKeyPath:keyPath options:0];
}

- (void)pt_addObserver:(NSObject *)observer selector:(SEL)selector forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options
{
    PTKeyValueObservation *keyValueObservation = [[PTKeyValueObservation alloc] initWithObject:self
                                                                                       keyPath:keyPath
                                                                                       options:options
                                                                                      observer:observer
                                                                                      selector:selector];
    [observer pt_addObservation:keyValueObservation];
}

#pragma mark - addObserver with block

- (PTKeyValueObservation *)pt_addObserverForKeyPath:(NSString *)keyPath usingBlock:(void (^)(PTKeyValueObservedChange *))block
{
    return [self pt_addObserverForKeyPath:keyPath options:0 usingBlock:block];
}

- (PTKeyValueObservation *)pt_addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(void (^)(PTKeyValueObservedChange *))block
{
    PTKeyValueObservation *keyValueObservation = [[PTKeyValueObservation alloc] initWithObject:self
                                                                                       keyPath:keyPath
                                                                                       options:options
                                                                                         block:block];
    return keyValueObservation;
}

#pragma mark - observeObject with selector

- (void)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath selector:(SEL)selector
{
    [self pt_observeObject:object forKeyPath:keyPath selector:selector options:0];
}

- (void)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath selector:(SEL)selector options:(NSKeyValueObservingOptions)options
{
    PTKeyValueObservation *keyValueObservation = [[PTKeyValueObservation alloc] initWithObject:object
                                                                                       keyPath:keyPath
                                                                                       options:options
                                                                                      observer:self
                                                                                      selector:selector];
    [self pt_addObservation:keyValueObservation];
}

#pragma mark - observeObject with block

- (PTKeyValueObservation *)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath usingBlock:(void (^)(PTKeyValueObservedChange *))block
{
    return [self pt_observeObject:object forKeyPath:keyPath options:0 usingBlock:block];
}

- (PTKeyValueObservation *)pt_observeObject:(NSObject *)object forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(void (^)(PTKeyValueObservedChange *))block
{
    PTKeyValueObservation *keyValueObservation = [[PTKeyValueObservation alloc] initWithObject:object
                                                                                       keyPath:keyPath
                                                                                       options:options
                                                                                         block:block];
    return keyValueObservation;
}

#pragma mark - removeObserver

- (void)pt_removeObserver:(NSObject *)observer
{
    [self pt_removeObserver:observer forKeyPath:nil];
}

- (void)pt_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    [observer pt_removeObservationsForObject:self keyPath:keyPath];
}

#pragma mark - Observations

static void * const PTKeyValueObserving_observationsKey = (void *)&PTKeyValueObserving_observationsKey;

- (NSArray<PTKeyValueObservation *> *)pt_observations
{
    return objc_getAssociatedObject(self, PTKeyValueObserving_observationsKey);
}

- (void)pt_setObservations:(NSArray<PTKeyValueObservation *> *)observations
{
    objc_setAssociatedObject(self,
                             PTKeyValueObserving_observationsKey,
                             [observations copy],
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark Adding/removing observations

- (void)pt_addObservation:(PTKeyValueObservation *)observation
{
    NSMutableArray<PTKeyValueObservation *> *observations = [self.pt_observations mutableCopy];
    if (!observations) {
        observations = [NSMutableArray array];
    }
    [observations addObject:observation];
    
    self.pt_observations = observations;
}

- (void)pt_removeObservation:(PTKeyValueObservation *)observation
{
    [self pt_removeObservations:@[observation]];
}

- (void)pt_removeObservations:(NSArray<PTKeyValueObservation *> *)observations
{
    if (observations.count == 0) {
        return;
    }
    
    for (PTKeyValueObservation *observation in observations) {
        [observation invalidate];
    }
    
    NSMutableArray<PTKeyValueObservation *> *mutableObservations = [self.pt_observations mutableCopy];
    [mutableObservations removeObjectsInArray:observations];
    
    if (mutableObservations.count > 0) {
        self.pt_observations = mutableObservations;
    } else {
        self.pt_observations = nil;
    }
}

- (void)pt_removeObservationsForObject:(NSObject *)object
{
    [self pt_removeObservationsForObject:object keyPath:nil];
}

- (void)pt_removeObservationsForObject:(NSObject *)object keyPath:(NSString *)keyPath
{
    if (!object) {
        return;
    }
    
    NSMutableArray<PTKeyValueObservation *> *observationsToRemove = [NSMutableArray array];
    
    // Find all observations on the observer that match this object and (optionally) key path.
    NSArray<PTKeyValueObservation *> *observations = self.pt_observations;
    for (PTKeyValueObservation *observation in observations) {
        // Check for a matching observed object.
        if (object != observation.object) {
            continue;
        }
        // Check for a matching key path, if given.
        if (keyPath && ![keyPath isEqualToString:observation.keyPath]) {
            continue;
        }
        
        [observationsToRemove addObject:observation];
    }
    
    // Remove all the matching observations.
    [self pt_removeObservations:observationsToRemove];
}

- (void)pt_removeAllObservations
{
    [self pt_removeObservations:self.pt_observations];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSObject, PTKeyValueObserving)
