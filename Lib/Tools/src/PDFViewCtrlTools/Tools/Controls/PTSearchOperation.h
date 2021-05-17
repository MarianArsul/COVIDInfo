//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The PTExtendedSearchResult class encapsulates a single `PTSearchResult` and an
 * array of page rects representing the search result's position on the page.
 */
@interface PTExtendedSearchResult : NSObject
@property (nonatomic) PTSearchResult *result;
@property (nonatomic) NSMutableArray<PTPDFRect *> *rects;
@end

@class PTSearchOperation;

@protocol PTSearchOperationDelegate <NSObject>
@required

-(void)ptSearchOperationFinished:(PTSearchOperation*)ptOperation;

@end

@interface PTSearchOperation : NSOperation

-(id)initWithData:(id)dataDictionary delegate:(id<PTSearchOperationDelegate>)delegate;

@property (nonatomic, weak, nullable) id<PTSearchOperationDelegate> delegate;

@property  (nonatomic, strong) NSDictionary *mainDataDictionary;
//@property  (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<PTSearchResult *> *> *results;
@property  (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<PTExtendedSearchResult *> *> *results;


@end

NS_ASSUME_NONNULL_END
