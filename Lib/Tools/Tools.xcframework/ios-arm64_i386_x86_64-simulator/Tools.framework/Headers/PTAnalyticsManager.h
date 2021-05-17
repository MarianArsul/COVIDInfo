//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Classes conforming to the `PTAnalyticsHandler` protocol receive analytics events when registered
 * with a `PTAnalyticsManager` instance.
 */
@protocol PTAnalyticsHandler <NSObject>
@optional

/**
 * Call in catch blocks so that the analytics handler can log exceptions.
 */
- (BOOL)logException:(NSException *)exception withExtraData:(nullable NSDictionary<id, id> *)extraData;

/**
 * Call to send custom events with the analytics handler.
 */
- (BOOL)sendCustomEventWithTag:(NSString *)tag;

@end

/**
 * The `PTAnalyticsManager` class dispatches analytics events to registered handlers conforming to
 * the `PTAnalyticsHandler` protocol. Each event sent to an analytics manager is dispatched to all
 * registered handlers capable of handling the event.
 */
@interface PTAnalyticsManager : NSObject <PTAnalyticsHandler>

/**
 * The default analytics manager.
 */
@property (nonatomic, class, readonly, strong) PTAnalyticsManager *defaultManager;

/**
 * The currently registered analytics handlers.
 */
@property (nonatomic, copy) NSArray<id<PTAnalyticsHandler>> *handlers;

/**
 * Registers an analytics handler with the manager.
 *
 * @param handler the analytics handler to register
 */
- (void)addHandler:(id<PTAnalyticsHandler>)handler;

/**
 * Removes an analytics handler previously registered with the manager.
 *
 * @param handler the analytics handler to remove
 */
- (void)removeHandler:(id<PTAnalyticsHandler>)handler;

@end

#pragma mark - Exception logging convenience

/**
 * Use the default `PTAnalyticsManager` to log the given exception.
 *
 * @param exception the exception to log
 *
 * @param extraData extra information to pass along with the exception
 */
PT_EXPORT void PTLogException(NSException *exception, NSDictionary<id, id> * _Nullable extraData);

NS_ASSUME_NONNULL_END
