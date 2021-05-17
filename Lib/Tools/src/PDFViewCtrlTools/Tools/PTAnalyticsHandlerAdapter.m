//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnalyticsHandlerAdapter.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation PTAnalyticsHandlerAdapter
#pragma clang diagnostic pop

static id _INSTANCE;

+ (instancetype) getInstance
{
    if (!_INSTANCE) {
        _INSTANCE = [[self alloc] init];
		
    }
    return _INSTANCE;
}

+ (void) setInstance:(PTAnalyticsHandlerAdapter *)value
{
    _INSTANCE = value;
}

- (BOOL) sendCustomEventWithTag:(NSString *)tag
{
    //NSLog(@"PTAnalyticsHandlerAdapter: %@", tag);
    return false;
}

- (BOOL) logException:(NSException *)exception withExtraData:(NSDictionary *)extraData
{
	assert(false);
	@throw [[NSException alloc] initWithName:@"Invalid" reason:@"Use a concrete class" userInfo:nil];
}

- (void)setUserIdentifier:(NSString *)identifier
{
	assert(false);
	@throw [[NSException alloc] initWithName:@"Invalid" reason:@"Use a concrete class" userInfo:nil];
}

-(void)initializeHandler
{
	assert(false);
	@throw [[NSException alloc] initWithName:@"Invalid" reason:@"Use a concrete class" userInfo:nil];
}

@end

