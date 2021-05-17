//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnalyticsManager.h"

#import "PTAnalyticsHandlerAdapter.h"

static PTAnalyticsManager *PTAnalyticsManager_defaultManager;

@implementation PTAnalyticsManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _handlers = @[];
    }
    return self;
}

- (void)addHandler:(id<PTAnalyticsHandler>)handler
{
    if ([self.handlers containsObject:handler]) {
        // Handler already added.
        return;
    }
    
    self.handlers = [self.handlers arrayByAddingObject:handler];
}

- (void)removeHandler:(id<PTAnalyticsHandler>)handler
{
    NSUInteger index = [self.handlers indexOfObject:handler];
    if (index == NSNotFound) {
        // Handler not registered.
        return;
    }
    
    NSMutableArray<id<PTAnalyticsHandler>> *mutableHandlers = [self.handlers mutableCopy];
    [mutableHandlers removeObjectAtIndex:index];
    self.handlers = [mutableHandlers copy];
}

#pragma mark - <PTAnalyticsHandler>

- (BOOL)logException:(NSException *)exception withExtraData:(NSDictionary<id,id> *)extraData
{
    // Return success if all handlers are successful.
    BOOL result = YES;

    // Send event to all handlers.
    for (id<PTAnalyticsHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(logException:withExtraData:)]) {
            result &= [handler logException:exception withExtraData:extraData];
        }
    }
    
    // Send event to deprecated analytics handler adapter.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    if (![[PTAnalyticsHandlerAdapter getInstance] isMemberOfClass:[PTAnalyticsHandlerAdapter class]]) {
        [[PTAnalyticsHandlerAdapter getInstance] logException:exception withExtraData:extraData];
    }
#pragma clang diagnostic pop

    return result;
}

- (BOOL)sendCustomEventWithTag:(NSString *)tag
{
    // Return success if all handlers are successful.
    BOOL result = YES;
    
    // Send event to all handlers.
    for (id<PTAnalyticsHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(sendCustomEventWithTag:)]) {
            result &= [handler sendCustomEventWithTag:tag];
        }
    }
    
    // Send event to deprecated analytics handler adapter.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    if (![[PTAnalyticsHandlerAdapter getInstance] isMemberOfClass:[PTAnalyticsHandlerAdapter class]]) {
        [[PTAnalyticsHandlerAdapter getInstance] sendCustomEventWithTag:tag];
    }
#pragma clang diagnostic pop
    
    return result;
}

#pragma mark - Default manager

+ (PTAnalyticsManager *)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PTAnalyticsManager_defaultManager = [[PTAnalyticsManager alloc] init];
    });
    
    return PTAnalyticsManager_defaultManager;
}

@end

#pragma mark - Exception logging convenience

void PTLogException(NSException *exception, NSDictionary *extraData)
{
    [PTAnalyticsManager.defaultManager logException:exception withExtraData:extraData];
}
