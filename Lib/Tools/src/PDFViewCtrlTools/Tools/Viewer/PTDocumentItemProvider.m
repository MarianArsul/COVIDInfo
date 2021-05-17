//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentItemProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentItemProvider ()

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentItemProvider

+ (NSURL *)placeholderURLForPDFDoc:(PTPDFDoc *)pdfDoc
{
    NSString *filename = nil;
    
    BOOL shouldUnlock = NO;
    @try {
        [pdfDoc LockRead];
        shouldUnlock = YES;
        
        NSString *fullFilename = [pdfDoc GetFileName];
        if (fullFilename.length > 0) {
            filename = fullFilename.lastPathComponent;
        }
    }
    @catch (NSException *exception) {
        filename = nil;
    }
    @finally {
        if (shouldUnlock) {
            [pdfDoc UnlockRead];
        }
    }
    
    if (filename.length == 0) {
        filename = @"Untitled.pdf";
    }
    
    if (![filename.pathExtension compare:@"pdf" options:NSCaseInsensitiveSearch]) {
        NSString *displayName = [filename stringByDeletingPathExtension];
        filename = [displayName stringByAppendingPathExtension:@"pdf"];
    }
    
    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory()
                                              isDirectory:YES];
    
    return [temporaryDirectoryURL URLByAppendingPathComponent:filename];
}

- (instancetype)initWithPDFDoc:(PTPDFDoc *)pdfDoc
{
    NSURL *placeholderURL = [PTDocumentItemProvider placeholderURLForPDFDoc:pdfDoc];
    self = [super initWithPlaceholderItem:placeholderURL];
    if (self) {
        _pdfDoc = pdfDoc;
    }
    return self;
}

- (instancetype)initWithDocumentURL:(NSURL *)documentURL
{
    return [self initWithDocumentURL:documentURL password:nil];
}

- (instancetype)initWithDocumentURL:(NSURL *)documentURL password:(NSString *)password
{
    NSParameterAssert([documentURL isFileURL]);
    
    self = [super initWithPlaceholderItem:documentURL];
    if (self) {
        _documentURL = documentURL;
        _password = [password copy];
    }
    return self;
}

- (id)item
{
    if (self.activityType == UIActivityTypePrint) {
        return [self preparedDocumentURL];
    }
    
    return self.documentURL;
}

- (NSURL *)destinationURLForPreparedDocument
{
    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory()
                                              isDirectory:YES];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.pdf",
                          [NSUUID UUID].UUIDString];
    
    return [temporaryDirectoryURL URLByAppendingPathComponent:fileName];
}

- (NSURL *)preparedDocumentURL
{
    PTPDFDoc *pdfDoc = nil;
    if (self.pdfDoc) {
        pdfDoc = self.pdfDoc;
    }
    else if (self.documentURL) {
        pdfDoc = [[PTPDFDoc alloc] initWithFilepath:self.documentURL.path];
        @try {
            NSString *password = self.password ?: @"";
            const BOOL unlocked = [pdfDoc InitStdSecurityHandler:password];
            if (!unlocked) {
                return nil;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
            return nil;
        }
    } else {
        return nil;
    }
    
    NSURL *destinationURL = [self destinationURLForPreparedDocument];
    NSAssert(destinationURL != nil,
             @"Failed to create destination URL for prepared document.");
    
    @try {
        PTPDFDoc *tempDoc = [[PTPDFDoc alloc] init];
        
        [pdfDoc Lock];
        [tempDoc InsertPages:1
                     src_doc:pdfDoc
                  start_page:1
                    end_page:[pdfDoc GetPageCount]
                        flag:e_ptinsert_none];
        [pdfDoc Unlock];
        
        [tempDoc RemoveSecurity];
        [tempDoc FlattenAnnotations:NO /* forms_only */];
        [tempDoc SaveToFile:destinationURL.path flags:0];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        return nil;
    }
    
    return destinationURL;
}

@end
