//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCoordinatedDocument.h"

#import "ToolsDefines.h"
#import "PTErrors.h"

@interface PTCoordinatedDocument()

@property (nonatomic, strong) NSDate* lastSaveDate;
@property (nonatomic, assign) BOOL isValid;

@end

@implementation PTCoordinatedDocument

-(void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    NSAssert(self.fileURL, @"Must have a fileURL");
    
    self.isValid = NO;
    
    if( !self.fileURL )
    {
        completionHandler(NO);
        return;
    }
    
    [super openWithCompletionHandler:^(BOOL success) {
        
        if( success == NO)
        {
            completionHandler(NO);
            return;
        }

        NSURL *filePathURL = [self.fileURL isFileReferenceURL] ? self.fileURL.filePathURL : self.fileURL;
        NSString *filePath = filePathURL.path;
        
        if (!self.pdfDoc) {
            @try {

                self.pdfDoc = [[PTPDFDoc alloc] initWithFilepath:filePath];

                // triggers an exception if the document is corrupt and could not be successfully repaired.
                // IMPORTANT: This can also throw for password-protected documents!
                //(void)[self.pdfDoc GetPageCount];
            }
            @catch (NSException *exception) {

                if(completionHandler)
                {
                    completionHandler(NO);
                    return;
                }

            }
        }
        self.isValid = YES;
        completionHandler(YES);
        
    }];

}

- (void)setPdfDoc:(PTPDFDoc *)pdfDoc
{
    if( _pdfDoc != pdfDoc )
    {
        _pdfDoc = pdfDoc;
        [self.delegate coordinatedDocumentDidChange:self];
    }
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError **)outError
{

    
    NSURL *filePathURL = [url isFileReferenceURL] ? url.filePathURL : url;
    NSString *filePath = filePathURL.path;
    
    PTPDFDoc *doc = nil;
    @try {
        doc = [[PTPDFDoc alloc] initWithFilepath:filePath];
        
        // Triggers an exception if the document is corrupt and could not be successfully repaired.
        // IMPORTANT: This can also throw for password-protected documents!
        //(void)[doc GetPageCount];
    }
    @catch (NSException *exception) {
        if (outError) {
            *outError = [exception pt_errorWithExtraUserInfo:@{NSURLErrorKey: url}];
        }
        return NO;
    }
    self.pdfDoc = doc;
    
    // Get the file modification date.
    NSDictionary<NSFileAttributeKey, id> *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:nil];
    NSDate *fileModificationDate = [attributes fileModificationDate];
    
    self.lastSaveDate = fileModificationDate;
    
    return YES;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)error {
    
    // Contents must be an NSData object.
    if (![contents isKindOfClass:[NSData class]]) {
        *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:0];
        return NO;
    }
    
    // Load document from contents.
    NSData *data = (NSData *)contents;
    @try {
        self.pdfDoc = [[PTPDFDoc alloc] initWithBuf:data buf_size:data.length];
    }
    @catch (NSException *exception) {
        self.pdfDoc = nil;
        
        if (error) {
            *error = exception.pt_error;
        }
        
        return NO;
    }
    
    return YES;
}

-(void)presentedItemDidChange
{
    [super presentedItemDidChange];

    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.fileURL.path error:nil];
    
    NSDate *fileModificationDate = [attributes fileModificationDate];
    
    if( [self.lastSaveDate isEqualToDate:fileModificationDate] )
    {
        return;
    }

    self.lastSaveDate = fileModificationDate;
    
    [self.delegate coordinatedDocumentDidChange:self];
    
}


-(void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    // There appears to be an Apple bug where the item at newURL is not present yet.
    // The doc therefore can't be updated, and saving will fail.
    // The document should be closed.
    // This even occurs when a file is open, and another app moves it
    [self.delegate coordinatedDocument:self presentedItemDidMoveToURL:newURL];
    
    self.isValid = NO;
    
    [super presentedItemDidMoveToURL:newURL];
    
}

-(BOOL)writeContents:(id)contents andAttributes:(NSDictionary *)additionalFileAttributes safelyToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation error:(NSError * _Nullable __autoreleasing *)outError
{
    // NOT calling `super` as per documentation:
    // "If you override this method, you should not invoke the superclass implementation."
    
    // HOWEVER the header in iOS 13.2 states:
    // Because it does several different things, and because the things are likely to change in future releases of iOS, it's probably not a good idea to override this method without invoking super.
    //
    // ¯\_(ツ)_/¯
    
    // When entering the background, writeContents:andAttributes... will *always* be called if there are unsaved changes, even if we
    // don't want it to (automatic saving is off).
    if( [self.delegate respondsToSelector:@selector(coordinatedDocumentShouldSave:)])
    {
        BOOL shouldSave = [self.delegate coordinatedDocumentShouldSave:self];
        
        if( shouldSave == NO )
        {
            // We did not save, but in this case return that we did, because otherwise the document will
            // generate a state changed event saying that the save failed, and there is no reliable way to
            // distinguish between "failing" for this reason or a valid reason.
            return YES;
        }
    }
    
    if( !self.isValid )
    {
        if (outError) {
            NSDictionary<NSErrorUserInfoKey, id> *userInfo;
            if (!userInfo) {
                userInfo = @{
                             NSLocalizedDescriptionKey : @"Error",
                             NSLocalizedFailureReasonErrorKey : @"Document invalid",
                             };
            }
            
            *outError = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:userInfo];
        }
        return NO;
    }
    
    // Convert file reference URL to path-based URL if necessary.
    NSURL *tempFilePathUrl = [url isFileReferenceURL] ? url.filePathURL : url;
    NSString *tempFilePath = tempFilePathUrl.path;
    
    // PDFNet saves to disk
    BOOL shouldUnlock = false;
    @try {
        [self.pdfDoc Lock];
        shouldUnlock = true;

        // Save a copy of PDFDoc to specified file path.
        [self.pdfDoc SaveToFile:url.path flags:e_ptincremental];
        
    } @catch (NSException *exception) {
        if (outError) {
            *outError = exception.pt_error;
        }
        if( shouldUnlock )
        {
            [self.pdfDoc Unlock];
        }
        
        return NO;
    }
    
    @try
    {
        if( shouldUnlock )
        {
            [self.pdfDoc Unlock];
        }
    } @catch (NSException *exception) {
        NSLog(@"Could not unlock doc.");
    }

    
    // caller will copy from temp location to original location
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tempFilePath error:nil];
    self.lastSaveDate = [attributes fileModificationDate];
    
    return YES;
}

-(void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    self.pdfDoc = nil;
    self.lastSaveDate = nil;
    [super closeWithCompletionHandler:completionHandler];
}

// This method does not get called when the app goes to the background.
// Maybe that's not considered an "autosave"?
- (void)autosaveWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    if( [self.delegate respondsToSelector:@selector(coordinatedDocumentShouldAutoSave:)] )
    {
        BOOL shouldSave = [self.delegate coordinatedDocumentShouldAutoSave:self];
        
        if( shouldSave )
        {
            [super autosaveWithCompletionHandler:completionHandler];
            return;
        }
    }
    
    completionHandler(NO);
        
}

- (BOOL)hasUnsavedChanges
{

    if (self.pdfDoc) {
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfDoc LockRead];
            shouldUnlock = YES;
            
            BOOL modified = [self.pdfDoc IsModified];

            return modified;
        }
        @catch (NSException *exception) {
            return NO;
        }
        @finally {
            if (shouldUnlock) {
                [self.pdfDoc UnlockRead];
            }
        }
    } else {
        return [super hasUnsavedChanges];
    }
}

-(void)revertToContentsOfURL:(NSURL *)url completionHandler:(void (^)(BOOL))completionHandler
{

    [super revertToContentsOfURL:url completionHandler:completionHandler];
    
}

-(void)dealloc
{

}

@end
