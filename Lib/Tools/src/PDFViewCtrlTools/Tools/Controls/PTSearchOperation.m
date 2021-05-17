//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSearchOperation.h"

@implementation PTExtendedSearchResult
@end

@implementation PTSearchOperation

//-(id)initWithData:(id)dataDictionary
- (id)initWithData:(id)dataDictionary delegate:(id<PTSearchOperationDelegate>)delegate
{
    if ((self = [super init]))
    {
        _mainDataDictionary = dataDictionary;
        _delegate = delegate;
        _results = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)main {
    PTTextSearch *textSearch = [[PTTextSearch alloc] init];
    
    PTPDFViewCtrl *pdfViewCtrl = [self.mainDataDictionary valueForKey:@"pdfViewCtrl"];
    NSString *searchString = [self.mainDataDictionary valueForKey:@"searchString"];
    @try {
        [pdfViewCtrl DocLockRead];
        unsigned int mode = [[self.mainDataDictionary valueForKey:@"mode"] intValue];
        [textSearch Begin:[pdfViewCtrl GetDoc] pattern:searchString mode:mode start_page:-1 end_page:-1];
        
        while (![self isCancelled]) {
            PTSearchResult *result = [textSearch Run];
            
            if ( [result IsFound] ) {
                PTHighlights *hlts = [result GetHighlights];
                [hlts Begin:[pdfViewCtrl GetDoc]];
                NSMutableArray *rects = [self pageRectsFromHighlights:hlts];

                PTExtendedSearchResult *extendedResult = [[PTExtendedSearchResult alloc] init];
                extendedResult.result = result;
                extendedResult.rects = rects;
                NSNumber *pageNumber = [NSNumber numberWithInteger:[result GetPageNumber]];
                NSMutableArray *key = [self.results objectForKey:pageNumber];
                if (key) {
                    [[self.results objectForKey:pageNumber] addObject:extendedResult];
                }else{
                    NSMutableArray *pageArray = [NSMutableArray arrayWithObject:extendedResult];
                    [self.results setObject:pageArray forKey:pageNumber];
                }
            }
            if( [result IsDocEnd] ){
                break;
            }
        }
    }
    @catch (NSException *exception) {
    }
    @finally {
        [pdfViewCtrl DocUnlockRead];
    }
    
    if (![self isCancelled]) {
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(ptSearchOperationFinished:) withObject:self waitUntilDone:NO];
    }
}

-(NSMutableArray*)pageRectsFromHighlights:(PTHighlights *)highlights
{
    NSMutableArray* quadsToReturn = [[NSMutableArray alloc] init];
    while ([highlights HasNext]) {
        PTVectorQuadPoint *quads = [highlights GetCurrentQuads];
        int i = 0;
        for ( ; i < [quads size]; ++i )
        {
            //assume each quad is an axis-aligned rectangle
            PTQuadPoint *q = [quads get: i];
            double x1 = MIN(MIN(MIN([[q getP1] getX], [[q getP2] getX]), [[q getP3] getX]), [[q getP4] getX]);
            double x2 = MAX(MAX(MAX([[q getP1] getX], [[q getP2] getX]), [[q getP3] getX]), [[q getP4] getX]);
            double y1 = MIN(MIN(MIN([[q getP1] getY], [[q getP2] getY]), [[q getP3] getY]), [[q getP4] getY]);
            double y2 = MAX(MAX(MAX([[q getP1] getY], [[q getP2] getY]), [[q getP3] getY]), [[q getP4] getY]);
            PTPDFRect * rect = [[PTPDFRect alloc] initWithX1: x1 y1: y1 x2: x2 y2: y2];
            [quadsToReturn addObject:rect];
        }
        [highlights Next];
    }
    return quadsToReturn;
}

@end
