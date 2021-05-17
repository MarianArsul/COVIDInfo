//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------
#import <Tools/ToolsDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL
@interface PTTimer : NSObject

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(nullable SEL)selector userInfo:(nullable id)userInfo repeats:(BOOL)repeats;

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block;

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(nullable SEL)selector userInfo:(nullable id)userInfo repeats:(BOOL)repeats NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTimeInterval:(NSTimeInterval)interval target:(id)target repeats:(BOOL)repeats block:(void (^)(NSTimer *))block NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) NSTimer *timer;

- (void)invalidate;

@property (nonatomic, readonly, assign, getter=isValid) BOOL valid;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
