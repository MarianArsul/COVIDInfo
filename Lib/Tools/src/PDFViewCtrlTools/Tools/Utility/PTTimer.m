//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTimer.h"

#include <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTTimer ()

@property (nonatomic, weak, nullable) id target;

// Either selector or block is nonnull.
@property (nonatomic, assign, nullable) SEL selector;
@property (nonatomic, copy, nullable) void (^block)(NSTimer *);

@end

NS_ASSUME_NONNULL_END

@implementation PTTimer

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    return [[PTTimer alloc] initWithTimeInterval:interval target:target selector:selector userInfo:userInfo repeats:repeats];
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target repeats:(BOOL)repeats block:(void (^)(NSTimer *))block
{
    return [[PTTimer alloc] initWithTimeInterval:interval target:target repeats:repeats block:block];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    self = [super init];
    if (self) {
        _target = target;
        _selector = selector;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timerFired:) userInfo:userInfo repeats:repeats];
        
        if (interval > 0.0) {
            _timer.tolerance = interval * 0.1;
        } else {
            _timer.tolerance = 0.1;
        }
    }
    return self;
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval target:(id)target repeats:(BOOL)repeats block:(void (^)(NSTimer *))block
{
    self = [super init];
    if (self) {
        _target = target;
        _block = block;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timerFired:) userInfo:nil repeats:repeats];
        
        if (interval > 0.0) {
            _timer.tolerance = interval * 0.1;
        } else {
            _timer.tolerance = 0.1;
        }
    }
    return self;
}

- (void)invalidate
{
    [self.timer invalidate];
}

- (BOOL)isValid
{
    return [self.timer isValid];
}

#pragma mark - Timer target

- (void)timerFired:(NSTimer *)timer
{
    if (self.target) {
        if (self.selector) {
            // Call selector on target.
            ((void (*)(id, SEL, NSTimer *))objc_msgSend)(self.target, self.selector, self.timer);
        } else if (self.block) {
            self.block(timer);
        }
    } else {
        [self.timer invalidate];
    }
}

@end
