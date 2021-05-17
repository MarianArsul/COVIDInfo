//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTReflowManager.h"
#import "PTReflowRequest.h"
#import <objc/runtime.h>

@interface PTPageRect : NSObject

@property (nonatomic) int pageNumber;
@property (nonatomic, strong) PTPDFRect* rect;
@property (nonatomic, copy) NSString* imagePath;

-(instancetype)initWithPageNumber:(int)page andRect:(PTPDFRect*)rect;

@end

@implementation PTPageRect

-(instancetype)initWithPageNumber:(int)pageNumber andRect:(PTPDFRect*)rect
{
    
    self = [super init];
    if (self) {
        _pageNumber = pageNumber;
        _rect = rect;
    }
    return self;
    
}

@end

// PTReflowProcessor callback function prototype.
static void PTReflowManager_ReflowCallback(PTResultState state, const char *filePath, void *customData);

@interface PTReflowManager ()

@property (nonatomic, readonly, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURL *> *cachedFiles;

@property (nonatomic, assign) BOOL clearDiskCache;

@end

@implementation PTReflowManager

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super init];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        _cachedFiles = [NSMutableDictionary dictionary];
        _clearDiskCache = YES;
        @try {
            if (![PTReflowProcessor IsInitialized]) {
                // This also clears the reflow disk cache.
                [PTReflowProcessor Initialize];
                
                _clearDiskCache = YES;
                
                
            }
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
    }
    return self;
}

#pragma mark - Reflow file caching

- (nullable NSURL *)cachedFileForPageNumber:(int)pageNumber
{
    NSURL *cachedURL = self.cachedFiles[@(pageNumber)];
    
    return cachedURL;
}

- (void)setCachedFile:(nonnull NSURL *)cachedURL forPageNumber:(int)pageNumber
{
//    NSURL *existingFile = [self cachedFileForPageNumber:pageNumber];
    
    self.cachedFiles[@(pageNumber)] = cachedURL;
}

#pragma mark - Image stuff

-(void)removeLinksFromPage:(PTPage*)page thatOverlapWith:(PTPDFRect*)rect
{
    PTPDFRect* nothingRect = [[PTPDFRect alloc] init];
    PTAnnot* annot;
    PTPDFRect* bbox;
    
    int num_annots = [page GetNumAnnots];
    
    for (int i = num_annots-1; i >= 0; i--)
    {
        annot = [page GetAnnot: i];
        bbox = [annot GetRect];
        
        if( [nothingRect IntersectRect:rect rect2:bbox] )
        {
            [page AnnotRemoveWithAnnot:annot];
        }
    }
}

static void *PTReflowManager_PTPageDocReference = &PTReflowManager_PTPageDocReference;

-(PTPage*)WriteTextOverImage:(NSArray<PTPageRect*>*)pageRects
{
    PTElementBuilder *eb = [[PTElementBuilder alloc] init];        // ElementBuilder is used to build new Element objects
    PTElementWriter *writer = [[PTElementWriter alloc] init];    // ElementWriter is used to write Elements to the page
    
    PTElement *element;
    //PTElement *startelement;
    //PTGState *gstate;
    PTPDFDoc* realDoc = [self.pdfViewCtrl GetDoc];
    int imgNum = 1;
    int font_size = 6;
    PTPage* page;
    
    // overwrite
//    PTPDFDoc* doc = realDoc;//[[PTPDFDoc alloc] init];
//    page = [doc GetPage:[pageRects firstObject].pageNumber];
    
    // swap in
    PTPDFDoc* doc = [[PTPDFDoc alloc] init];
    
    // ensure docs are identifiably unqiue
    PTObj* idArray = [[doc GetTrailer] PutArray:@"ID"];
    
    NSString* uniqueFileId = [NSUUID UUID].UUIDString;
    [idArray PushBackText:uniqueFileId];
    [idArray PushBackText:uniqueFileId];
    
    PTPageSet* pageSet = [[PTPageSet alloc] initWithOne_page:[pageRects firstObject].pageNumber];
    [doc InsertPagesWithPageSet:0 src_doc:realDoc source_page_set:pageSet flag:e_ptinsert_none];
    page = [doc GetPage:1];
    
    // don't delete the doc that the page references until the page dies
    objc_setAssociatedObject(page,
                             PTReflowManager_PTPageDocReference,
                             doc,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    
    for (PTPageRect* pageRect in pageRects)
    {
        @autoreleasepool {
            
            [self removeLinksFromPage:page thatOverlapWith:pageRect.rect];
            
            PTPDFRect* rect = pageRect.rect;
            NSLog(@"On page %d", [page GetIndex]);
            
            //int cw = [page GetPageWidth:e_ptcrop];
            
            //heuristic based on current text extractor
            if( [rect Width] > [page GetPageWidth:e_ptcrop]/2*.95)
            {
                // prefer to associate images with text beside
                font_size = 3;
            }
            else
            {
                // prefer to associate images with above/below
                font_size = 8;
            }
            
            [writer WriterBeginWithPage: page placement: e_ptoverlay page_coord_sys: YES compress: YES resources:Nil];    // begin writing to this page
            
            [eb Reset: [[PTGState alloc] init]];            // Reset the GState to default
            
            // Begin writing a block of text
            element = [eb CreateTextBeginWithFont: [PTFont Create: [doc GetSDFDoc] type: e_pttimes_roman embed: NO] font_sz: font_size];
            [writer WriteElement: element];
            
            
            NSString* stringToWrite = [NSString stringWithFormat:@"reflowimaae%04d", imgNum++];
            element = [eb CreateTextRun:stringToWrite];

            
            
            PTPDFRect* bbbbox = [element GetBBox];
            double hScale = ABS([rect GetX2] - [rect GetX1])/ABS([bbbbox GetX2] - [bbbbox GetX1]);
            double vScale = ABS([rect GetY2] - [rect GetY1])/ABS([bbbbox GetY2] - [bbbbox GetY1]);

            
            vScale = MIN(vScale, 1.0);
            [element SetTextMatrix:hScale b: 0 c: 0 d:vScale h: [rect GetX1] v: [rect GetY1]+([rect GetY2]-[rect GetY1])-font_size];
            [writer WriteElement: element];


            
            if( self.reflowMode == PTReflowModeTextAndRawImages )
            {
                PTPDFRect* newbbBox = Nil;
                
                int ii;
                for(ii = 1; ii < 500; ii++)
                {

                        element = [eb CreateTextNewLineWithOffset:0 dy:-font_size];
                        [writer WriteElement: element];

                        stringToWrite = [NSString stringWithFormat:@"reflowimaae%04d", imgNum-1];

                        element = [eb CreateTextRun: stringToWrite];
                        [writer WriteElement: element];

                    newbbBox = [element GetBBox];
                    if( [newbbBox GetY1] < [rect GetY1]+font_size )
                    {
                        break;
                    }
                    
                }
            }

            // Finish the block of text
            [writer WriteElement: [eb CreateTextEnd]];
            
            [writer End];  // save changes to the current page
        }
    }

    
    return page;
}

//int image_counter_two;
//int exported_image_counter_two;

-(NSArray<PTPageRect*>*)ImageExtract:(PTElementReader*) reader forPage:(PTPage*)page withImageStartIndex:(int)startIndex
{
    
    PTElement *element;
    
    NSMutableArray<PTPageRect*>* imageRects = [[NSMutableArray alloc] init];
    
    PTPDFRect* pdfRectCropBox =  [page GetCropBox];
    //PTPDFRect* pdfVisibleBox = [page GetVisibleContentBox];
    int pageNumber = [page GetIndex];
    
    //int image_counter_two = startIndex;
    int exported_image_counter_two = startIndex;
    
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSError* error;
    [fileManager createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"reflow"]  withIntermediateDirectories:NO attributes:Nil error:&error];
    if( error )
    {
        if( [fileManager fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"reflow"] isDirectory:Nil] == NO )
        {
            return Nil;
        }
    }

    
    while ((element = [reader Next]) != NULL)
    {
        @autoreleasepool {

            switch ([element GetType])
            {
                case e_ptimage:
                case e_ptinline_image:
                {
                    //NSLog(@"--> Image: %d", ++image_counter_two);
                    NSLog(@"    Width: %d", [element GetImageWidth]);
                    NSLog(@"    Height: %d", [element GetImageHeight]);
                    NSLog(@"    BPC: %d", [element GetBitsPerComponent]);
                    
                    PTMatrix2D *ctm = [element GetCTM];
                    double x2=1, y2=1;
                    //double x1 =[ctm getM_h], y1 =[ctm getM_v];
                    PTPDFPoint* pt = [ctm Mult: [[PTPDFPoint alloc] initWithPx: x2 py: y2]];
                    //                    PTPDFPoint* pt2 = [ctm Mult: [[PTPDFPoint alloc] initWithPx: x1 py: y1]];
                    //
                    //                    double hh = [ctm getM_h];
                    //                    double vv = [ctm getM_v];
                    //
                    //                    double xx1 = [pt2 getX];
                    //                    double yy1 = [pt2 getY];
                    //                    double xx2 = [pt getX];
                    //                    double yy2 = [pt getY];
                    //
                    //                    NSLog(@"rav4 %d CTM:[%f, %f, %f, %f], [%f, %f]", image_counter_two, [ctm getM_a], [ctm getM_b], [ctm getM_c], [ctm getM_d], [ctm getM_v], [ctm getM_h]);
                    //                    NSLog(@"rav4 %d pt:  (%f, %f)", image_counter_two, xx2, yy2);
                    //                    NSLog(@"rav4 %d pt2: (%f, %f)", image_counter_two, xx1, yy1);
                    
                    
                    
                    //                    NSLog(@"%f %f %f %f", [pdfRectCropBox GetX1], [pdfRectCropBox GetY1], [pdfRectCropBox GetX2], [pdfRectCropBox GetY2]);
                    
                    //                    if( [ctm getM_d] < 0 )
                    //                    {
                    //
                    //                    }
                    //
                    //                    if( image_counter_two == 15 )
                    //                    {
                    //                        NSLog(@"here we are");
                    //                    }
                    
                    NSLog(@"    Coords: x1=%f, y1=%f, x2=%f, y2=%f", [ctm getM_h], [ctm getM_v], [pt getX], [pt getY]);
                    
                    PTPDFRect* rect = [[PTPDFRect alloc] initWithX1:[ctm getM_h] y1:[ctm getM_v] x2:[pt getX] y2:[pt getY]];
                    
                    [rect Normalize];
                    
//                    if( [rect Width] < 5 )
//                        continue;
                    
                    NSLog(@"rect rectA (%f, %f), (%f, %f)", [rect GetX1], [rect GetY1], [rect GetX2], [rect GetY2]);

                    
                    [rect SetX1:[rect GetX1]-[pdfRectCropBox GetX1]];
                    [rect SetX2:[rect GetX2]-[pdfRectCropBox GetX1]];
                    [rect SetY1:[rect GetY1]-[pdfRectCropBox GetY1]];
                    [rect SetY2:[rect GetY2]-[pdfRectCropBox GetY1]];

                    NSLog(@"rect rectB (%f, %f), (%f, %f)", [rect GetX1], [rect GetY1], [rect GetX2], [rect GetY2]);

                    [rect Normalize];

                    PTPDFRect* test1 = [element GetBBox];

                    [test1 Normalize];

                    NSLog(@"box test1 (%f, %f), (%f, %f)", [test1 GetX1], [test1 GetY1], [test1 GetX2], [test1 GetY2]);


                    PTPDFRect* newRect = [[PTPDFRect alloc] init];

                    if( [newRect IntersectRect:rect rect2:pdfRectCropBox] )
                    {
                        [rect SetX1:[newRect GetX1]];
                        [rect SetX2:[newRect GetX2]];
                        [rect SetY1:[newRect GetY1]];
                        [rect SetY2:[newRect GetY2]];
                    }
                    else
                    {
                        break;
                    }
                    
                    NSLog(@"rect rectC (%f, %f), (%f, %f)", [rect GetX1], [rect GetY1], [rect GetX2], [rect GetY2]);
                    
                    
                    PTPageRect* pageRect = [[PTPageRect alloc] initWithPageNumber:[page GetIndex] andRect:rect];
                    
                    
                    if ([element GetType] == e_ptimage)
                    {
                        PTImage *image = [[PTImage alloc] initWithImage_xobject: [element GetXObject]];
                        
                        PTMatrix2D* transform = [element GetCTM];
                        
                        if( [transform IsEquals:[PTMatrix2D IdentityMatrix]])
                        {
                            NSLog(@"Identity!");
                        }
                        else
                        {
                            NSLog(@"Not identity....");
                            double a = [transform getM_a];
                            double b = [transform getM_b];
                            double c = [transform getM_c];
                            double d = [transform getM_d];
                            
                            double v = [transform getM_v];
                            double h = [transform getM_h];
                            NSLog(@"[%f, %f, %f, %f], [%f, %f]", a, b, c, d, v, h);
                            
                        }
                        
                        
                        
                        
                        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"/reflow/image_extract_%d_%04d.png", pageNumber, ++exported_image_counter_two]];
                        
                        NSLog(@"Find your image at %@", path);
                        
                        pageRect.imagePath = path;
                        
                        [image ExportAsPngFile: path];

                        
                        [imageRects addObject:pageRect];
                    }
                    else
                    {
                        NSLog(@"Could not export element, is of type %d", [element GetType] );
                        NSLog(@"Could not export an inline image :saddavid:");
                        
    //                    int width = [element GetImageWidth];
    //                    int height = [element GetImageHeight];
    //                    int out_data_sz = width * height * 3;
    //
    //
    //                    PTFilter* reader = [element GetImageData];
    //
    //                    PTObjSet* hint_set = [[PTObjSet alloc] init];
    //                    PTObj* enc=[hint_set CreateArray];  // Initialize encoder 'hint' parameter
    //                    [enc PushBackName: @"RAW"];
    //
    //                    PTSDFDoc* doc = [[PTSDFDoc alloc] init];
    //                    PTImage* inlineImage = [PTImage CreateWithFilterDataSimple:doc image_data:reader encoder_hints:enc];
    //
    //                    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"image_extract_%d_%04d.png", pageNumber, ++exported_image_counter_two]];
    //
    //                    NSLog(@"Find your image at %@", path);
    //
    //                    pageRect.imagePath = path;
    //
    //                    [inlineImage ExportAsPngFile: path];
                        
                        
                    }
                    
                   
                    
                }
                    break;
                case e_ptform:        // Process form XObjects
                {
                    [reader FormBegin];
                    NSArray<PTPageRect*>* more = [self ImageExtract:reader forPage:page withImageStartIndex:exported_image_counter_two];
                    exported_image_counter_two += more.count;
                    [imageRects addObjectsFromArray:more];
                    [reader End];
                }
                    break;
                default:
                    break;
            }
        }
    }
    
    return [imageRects copy];
}

-(PTPage*)prepareImagesForPage:(int)pageNumber
{
    
    PTElementReader *reader = [[PTElementReader alloc] init];
    
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    NSMutableArray<PTPageRect*>* pageImageRects = [[NSMutableArray alloc] init];
    

    PTPage* page = [doc GetPage:pageNumber];
    [reader Begin: page];
    NSArray<PTPageRect*>* pageImageRectsForCurrentPage = [self ImageExtract:reader forPage:page withImageStartIndex:0];
    [pageImageRects addObjectsFromArray:pageImageRectsForCurrentPage];
    [reader End];

    if( pageImageRectsForCurrentPage.count == 0 )
    {
        return Nil;
    }
    else
    {
        return [self WriteTextOverImage:pageImageRects];
    }
}

#pragma mark - Reflow requests

- (void)requestReflowForPageNumber:(int)pageNumber
{
    // Check for cached reflow file.
    NSURL *cachedURL = [self cachedFileForPageNumber:pageNumber];
    if (cachedURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self PT_reflowCallbackReceivedForPageNumber:pageNumber withState:e_ptrs_success fileURL:cachedURL];
            
        });
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        __block PTPage *page = Nil;
        NSError* error;
        
        BOOL worked = [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
            // get images
            if( self.reflowMode == PTReflowModeTextAndRawImages )
            {
                page = [self prepareImagesForPage:pageNumber];
            }
        } error:&error];
        
        if( !worked )
        {
            NSLog(@"Error: %@", error);
            NSAssert(error == Nil, @"Error extracting images in reflow");
        }
        
        
        // Create new reflow request.
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            
            PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
            
            
            if( page == Nil )
            {
                page = [doc GetPage:pageNumber];
                if (![page IsValid]) {
                    return;
                }
            }

            PTReflowRequest<PTReflowManager *> *request = [PTReflowRequest requestWithSender:self pageNumber:pageNumber];
            
            // don't delete the page until the request dies
            request.page = page;
            
            @synchronized (self) {
                [PTReflowProcessor GetReflow:page proc:PTReflowManager_ReflowCallback custom_data:(void *)CFBridgingRetain(request)];
            }
            
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        } @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }

    });
    

        // Notify delegate.
        if ([self.delegate respondsToSelector:@selector(reflowManager:didBeginRequestForPageNumber:)]) {
            [self.delegate reflowManager:self didBeginRequestForPageNumber:pageNumber];
        }

}

- (void)cancelRequestForPageNumber:(int)pageNumber
{
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        PTPage *page = [doc GetPage:pageNumber];
        if (![page IsValid]) {
            return;
        }
        
        [PTReflowProcessor CancelRequest:page];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
}

- (void)cancelAllRequests
{
    @try {
        [PTReflowProcessor CancelAllRequests];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
}

- (void)clearCache
{
    if (self.clearDiskCache) {
        @try {
            @synchronized (self) {
                [PTReflowProcessor ClearCache];
            }
            

        } @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
    }
    
    // Clear local cache.
    [self.cachedFiles removeAllObjects];
}

// NOTE: reflow file should have already been checked to be for the correct document...
- (int)pageNumberForReflowFile:(NSURL *)reflowFile
{
    NSParameterAssert([reflowFile isFileURL]);
    
    // Check for file path URL.
    NSURL *filePathURL = reflowFile.filePathURL;
    if (!filePathURL) {
        return 0;
    }
    
    NSString *filePath = filePathURL.path;
    
    // A valid reflow file path should have at least 3 path components.
    if (filePath.pathComponents.count < 3) {
        return 0;
    }
    
    NSString *fileName = filePath.lastPathComponent;
    
    // Check for "html" file extension.
    if (![fileName.pathExtension.lowercaseString isEqualToString:@"html"]) {
        return 0;
    }
    
    // Scan for an unsigned int file display name.
    int intValue = 0; 
    NSScanner *scanner = [NSScanner scannerWithString:fileName.stringByDeletingPathExtension];
    if (![scanner scanInt:&intValue]) {
        return 0;
    }
    
    unsigned int objNum = intValue;
    
    return [self pageNumberForPageObjNum:objNum];
}

- (int)pageNumberForPageObjNum:(unsigned int)pageObjNum
{
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;

        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        int pageNumber = 1;
        for (PTPageIterator *iterator = [doc GetPageIterator:1]; [iterator HasNext]; [iterator Next], pageNumber++) {
            PTPage *page = [iterator Current];
            if (![page IsValid]) {
                continue;
            }
            
            unsigned int objNum = [[page GetSDFObj] GetObjNum];
            if (objNum == pageObjNum) {
                return pageNumber;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    // Page not found.
    return 0;
}

#pragma mark - Reflow request result handling

- (void)PT_reflowCallbackReceivedForPageNumber:(int)pageNumber withState:(PTResultState)state fileURL:(nullable NSURL *)fileURL
{
    switch (state) {
        case e_ptrs_failure:
            // Handle failure
            [self PT_requestFailedForPageNumber:pageNumber];
            break;
        case e_ptrs_cancel:
            // Handle cancel
            [self PT_requestCancelledForPageNumber:pageNumber];
            break;
        case e_ptrs_success:
            // Handle success
            [self PT_requestSucceddedForPageNumber:pageNumber fileURL:fileURL];
            break;
        default:
            NSLog(@"Received unexpected reflow result state: %d", state);
            break;
    }
}

- (void)PT_requestFailedForPageNumber:(int)pageNumber
{
    // Notify delegate of failed request.
    if ([self.delegate respondsToSelector:@selector(reflowManager:requestFailedForPageNumber:)]) {
        [self.delegate reflowManager:self requestFailedForPageNumber:pageNumber];
    }
}

- (void)PT_requestCancelledForPageNumber:(int)pageNumber
{
    // Notify delegate of cancelled request.
    if ([self.delegate respondsToSelector:@selector(reflowManager:requestCancelledForPageNumber:)]) {
        [self.delegate reflowManager:self requestCancelledForPageNumber:pageNumber];
    }
}


- (void)PT_requestSucceddedForPageNumber:(int)pageNumber fileURL:(nullable NSURL *)fileURL
{
    NSParameterAssert(fileURL != nil);
    
    NSString* postProcessModeAddition = @"";
    BOOL isDarkMode = ( [self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_night_mode || [self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_invert  );
    
    BOOL isSepiaMode = ( [self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_gradient_map );
    
    if( isDarkMode )
    {
        postProcessModeAddition = @"-webkit-filter: invert(100%) brightness(150%) contrast(90%); filter: invert(100%) brightness(150%) contrast(90%); } html { -webkit-filter: invert(90%); filter: invert(90%); margin: 0vw 5vw 0vw 5vw;}";
    }
    else if( isSepiaMode )
    {
        postProcessModeAddition = @"-webkit-filter: sepia(100%); filter: sepia(100%); } html { margin: 0vw 5vw 0vw 5vw;}";
    }
    // REFLOW IMAGE HTML MASSAGE
    if( ( self.reflowMode == PTReflowModeTextAndRawImages ) )
        {
        NSString* htmlStr = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:Nil];
        
            NSString* css = [NSString stringWithFormat:@"<style>img { padding: 0; margin: auto; display: block; max-height: 95vh; max-width: 100%%; %@ } html {margin: 0vw 5vw 0vw 5vw;} </style>", postProcessModeAddition];
        htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"</head>" withString:[NSString stringWithFormat:@"%@\n</head>",css]];

//            htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"<html>" withString:@"<html document.documentElement.style.webkitFilter = 'invert(100%)';>"];
        
        if( self.fontOverrideName )
        {
            for(int ii = 0; ii < 10000; ii++)
            {
                if( [htmlStr containsString:[NSString stringWithFormat:@"font-family:f%dgeneric;", ii]] == NO )
                {
                    break;
                }
                htmlStr = [htmlStr stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"font-family:f%dgeneric; ", ii]
                                                             withString:[NSString stringWithFormat:@"font-family:%@; ", self.fontOverrideName]];
            }
        }
        
        NSMutableSet* imageNumbersOnPage = [[NSMutableSet alloc] init];
        NSRange searchRange = NSMakeRange(0,htmlStr.length);
        NSRange foundRange;
        while (searchRange.location < htmlStr.length) {
            searchRange.length = htmlStr.length-searchRange.location;
            foundRange = [htmlStr rangeOfString:@"reflowimaae" options:0 range:searchRange];
            if (foundRange.location != NSNotFound) {
                // found substring
                searchRange.location = foundRange.location+foundRange.length;
                
                NSRange needleRange = NSMakeRange(searchRange.location, 4);
                NSString* num = [htmlStr substringWithRange:needleRange];
                [imageNumbersOnPage addObject:num];

            } else {
                // no more substrings to find
                break;
            }
        }
        

        
        for(NSNumber* num in imageNumbersOnPage)
        {
            @autoreleasepool {

                NSString* sourceFile = [NSString stringWithFormat:@"%@/reflow/image_extract_%d_%04d.png",NSTemporaryDirectory(),pageNumber, num.intValue];
                NSString* imageStringHTML = [NSString stringWithFormat:@"<img src=\"%@\" />", sourceFile];
                
                NSString* stringToReplaceWith = [NSString stringWithFormat:@"reflowimaae%04d", num.intValue];
                
                NSRange rangeOfFirstOccurance = [htmlStr rangeOfString:stringToReplaceWith];
                
                NSString* withImagesHtml;
                
                if (NSNotFound != rangeOfFirstOccurance.location) {
                    withImagesHtml = [htmlStr stringByReplacingCharactersInRange:rangeOfFirstOccurance withString:imageStringHTML];
                }
                else
                {
                    NSLog(@"Problem2!");
                    continue;
                }
                
                NSString* withoutFiller = [withImagesHtml stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"reflowimaae%04d", num.intValue] withString:@""];
                htmlStr = withoutFiller;
                
            }
        }
        
        if( [htmlStr containsString:@"imaae"] )
        {
            NSLog(@"Problem!");
        }
        
        [htmlStr writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:Nil];
            
    }
    
    
    // Add reflow file to local cache.
    [self setCachedFile:fileURL forPageNumber:pageNumber];
    
    // Notify delegate of successful request.
    if ([self.delegate respondsToSelector:@selector(reflowManager:didReceiveResult:forPageNumber:)]) {
        [self.delegate reflowManager:self didReceiveResult:fileURL forPageNumber:pageNumber];
    }
    
}

@end

#pragma mark - PTReflowProcessor callbacks

static void PTReflowManager_ReflowCallback(PTResultState state, const char *filePath, void *customData)
{
    @autoreleasepool {
        PTReflowRequest<PTReflowManager *> *request = (__bridge PTReflowRequest *)customData;
        
        CFRelease(customData);
        

        
        PTReflowManager *sender = request.sender;
        int pageNumber = request.pageNumber;
        
        if (!sender) {

            return;
        }
        
        if (pageNumber < 1) {

            return;
        }
        
        // Wrap (& copy) file path C-string.
        NSString *string = filePath ? [NSString stringWithUTF8String:filePath] : nil;
        NSURL *fileURL = string ? [NSURL fileURLWithPath:string isDirectory:NO] : nil;
        
        // Dispatch to main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender PT_reflowCallbackReceivedForPageNumber:pageNumber withState:state fileURL:fileURL];
        });
    }
}
