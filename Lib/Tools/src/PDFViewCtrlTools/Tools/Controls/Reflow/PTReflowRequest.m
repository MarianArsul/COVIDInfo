//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTReflowRequest.h"

@implementation PTReflowRequest

static int requestNumber;

+ (instancetype)requestWithSender:(id)sender pageNumber:(int)pageNumber
{
    return [[self alloc] initWithSender:sender pageNumber:pageNumber];
}

- (instancetype)initWithSender:(id)sender pageNumber:(int)pageNumber
{
    self = [super init];
    if (self) {
        _sender = sender;
        _pageNumber = pageNumber;
        _requestNumber = requestNumber++;
    }
    return self;
}

@end
