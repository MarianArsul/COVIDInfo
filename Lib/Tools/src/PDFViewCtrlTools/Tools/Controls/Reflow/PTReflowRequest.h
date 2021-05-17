//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"
#import <PDFNet/PDFNet.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTReflowRequest<SenderType> : NSObject

@property (nonatomic, strong) SenderType sender;
@property (nonatomic, assign) int pageNumber;
@property (nonatomic, assign) int requestNumber;
@property (nonatomic, retain) PTPage* page;

+ (instancetype)requestWithSender:(SenderType)sender pageNumber:(int)pageNumber;

- (instancetype)initWithSender:(SenderType)sender pageNumber:(int)pageNumber NS_DESIGNATED_INITIALIZER;

PT_INIT_UNAVAILABLE

@end

NS_ASSUME_NONNULL_END
