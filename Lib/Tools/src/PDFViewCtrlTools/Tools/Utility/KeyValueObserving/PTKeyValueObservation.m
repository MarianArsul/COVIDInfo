//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTKeyValueObservation.h"

#import "NSObject+PTKeyValueObserving.h"

#import <objc/message.h>

static void * const PTKeyValueObservation_context = (void *)&PTKeyValueObservation_context;

NS_ASSUME_NONNULL_BEGIN

@interface PTKeyValueObservation ()

// Redeclare as readwrite internally.
@property (nonatomic, readwrite, copy, nullable) void (^block)(PTKeyValueObservedChange *);
@property (nonatomic, readwrite, unsafe_unretained, nullable) NSObject *object;

@property (nonatomic, assign) NSUInteger selectorArgumentCount;

@end

NS_ASSUME_NONNULL_END

@implementation PTKeyValueObservation

- (instancetype)initWithObject:(NSObject *)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options observer:(NSObject *)observer selector:(SEL)selector
{
    self = [super init];
    if (self) {
        _object = object;
        _keyPath = [keyPath copy];
        _options = options;
        
        _observer = observer;
        _selector = selector;
        
        // Get the number of arguments for the given selector.
        NSMethodSignature *methodSignature = [observer methodSignatureForSelector:selector];
        NSUInteger numberOfArguments = methodSignature.numberOfArguments;
        
        NSAssert(numberOfArguments == 2 || numberOfArguments == 3,
                 @"Incorrect number of parameters in selector: \"%@\": found %lu parameters",
                 NSStringFromSelector(selector), (unsigned long)numberOfArguments);
        
        _selectorArgumentCount = numberOfArguments;
        
        // Start observing object.
        [object addObserver:self forKeyPath:keyPath options:options context:PTKeyValueObservation_context];
    }
    return self;
}

- (instancetype)initWithObject:(NSObject *)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void (^)(PTKeyValueObservedChange * _Nonnull))block
{
    self = [super init];
    if (self) {
        _object = object;
        _keyPath = [keyPath copy];
        _options = options;

        _block = block;
        
        // Start observing object.
        [object addObserver:self forKeyPath:keyPath options:options context:PTKeyValueObservation_context];
    }
    return self;
}

- (void)invalidate
{
    @try {
        [self.object removeObserver:self forKeyPath:self.keyPath context:PTKeyValueObservation_context];
    }
    @catch (NSException *exception) {
        // Ignored.
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }

    // Drop object reference.
    self.object = nil;
    
    // Release block reference.
    self.block = nil;
}

- (void)dealloc
{
    // Avoid using properties in dealloc.
//    @try {
//        [_object removeObserver:self forKeyPath:_keyPath context:PTKeyValueObserver_context];
//    }
//    @catch (NSException *exception) {
//        // Ignored.
//        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
//    }
}

#pragma mark - NSObject(NSKeyValueObserving)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    if (context != PTKeyValueObservation_context) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    PTKeyValueObservedChange *observedChange = [[PTKeyValueObservedChange alloc] initWithObject:object keyPath:keyPath change:change];
    
    // Call out to the observer or block.
    if (self.observer && self.selector) {
        // Call the observer's method with 2 or 5 arguments.
        if (self.selectorArgumentCount == 2) {
            // Arguments: self, _cmd
            ((void (*)(id, SEL))objc_msgSend)(self.observer, self.selector);
        } else if (self.selectorArgumentCount == 3)  {
            // Arguments: self, _cmd, keyPath, object, change
            ((void (*)(id, SEL, PTKeyValueObservedChange *))objc_msgSend)(self.observer, self.selector, observedChange);
        }
    }
    else if (self.block) {
        (self.block)(observedChange);
    }
    else {
        NSLog(@"Observation for key path %@ does not have a valid target or block", keyPath);
    }
}

@end
