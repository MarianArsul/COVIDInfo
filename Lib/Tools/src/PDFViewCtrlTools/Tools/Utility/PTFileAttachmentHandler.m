//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFileAttachmentHandler.h"

#import "PTErrors.h"

@implementation PTFileAttachmentHandler

- (NSURL *)destinationForExportedFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc error:(NSError * _Nullable *)error
{
    NSString *fileName = nil;
    
    BOOL hasReadLock = NO;
    @try {
        [doc LockRead];
        hasReadLock = YES;
        
        // Check for a valid file attachment annotation.
        if (![fileAttachment IsValid]) {
            if (error) {
                *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                          @{
                            NSLocalizedDescriptionKey: @"Failed to determine export destination for file attachment",
                            NSLocalizedFailureReasonErrorKey: @"File attachment is invalid",
                            }];
            }
            return nil;
        }
        
        PTFileSpec *fileSpec = [fileAttachment GetFileSpec];
        
        // Check for a valid file spec.
        if (![fileSpec IsValid]) {
            if (error) {
                *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                          @{
                            NSLocalizedDescriptionKey: @"Failed to determine export destination for file attachment",
                            NSLocalizedFailureReasonErrorKey: @"FileSpec of file attachment is invalid",
                            }];
            }
            return nil;
        }
        
        // Get file name from the file path, if available.
        NSString *filePath = [fileSpec GetFilePath];
        if (!filePath) {
            // Without a file path, there is no way to know the type of the file to open it.
            if (error) {
                *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                          @{
                            NSLocalizedDescriptionKey: @"Failed to determine export destination for file attachment",
                            NSLocalizedFailureReasonErrorKey: @"Could not determine the file attachment's file name",
                            }];
            }
            return nil;
        }
        fileName = filePath.lastPathComponent;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        
        if (error) {
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                      @{
                        NSLocalizedDescriptionKey: @"Failed to determine export destination for file attachment",
                        NSLocalizedFailureReasonErrorKey: @"Could not determine the file attachment's file name",
                        NSUnderlyingErrorKey: exception.pt_error,
                        }];
        }
        return nil;
    }
    @finally {
        if (hasReadLock) {
            [doc UnlockRead];
        }
    }
    
    if (!fileName) {
        if (error) {
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                      @{
                        NSLocalizedDescriptionKey: @"Failed to determine export destination for file attachment",
                        NSLocalizedFailureReasonErrorKey: @"Could not determine the file attachment's file name",
                        }];
        }
        return nil;
    }
    
    // Create a temporary cache file for the exported file attachment.
    NSError *cacheError = nil;
    NSURL *cachesDirectory = [NSFileManager.defaultManager URLForDirectory:NSCachesDirectory
                                                                  inDomain:NSUserDomainMask
                                                         appropriateForURL:nil
                                                                    create:YES
                                                                     error:&cacheError];
    if (!cachesDirectory) {
        if (error) {
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                      @{
                        NSLocalizedDescriptionKey: @"Failed to determine export destination for file attachment",
                        NSLocalizedFailureReasonErrorKey: @"Failed to get directory for exported file attachment",
                        NSUnderlyingErrorKey: cacheError,
                        }];
        }
        return nil;
    }
    
    NSString *fileDisplayName = fileName.stringByDeletingPathExtension;
    NSString *pathExtension = fileName.pathExtension;
    NSUInteger copyNumber = 1;
    
    NSURL *exportedURL = [cachesDirectory URLByAppendingPathComponent:fileName];
    
    while ([NSFileManager.defaultManager fileExistsAtPath:exportedURL.path isDirectory:nil]) {
        exportedURL = [cachesDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%lu).%@",
                                                                    fileDisplayName, (unsigned long)copyNumber, pathExtension]];
        copyNumber++;
    }
    
    return exportedURL;
}

- (void)handleExportFailureForFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc withError:(NSError *)error
{
    // Notify delegate of export failure.
    if ([self.delegate respondsToSelector:@selector(fileAttachmentHandler:didFailToExportFileAttachment:fromPDFDoc:withError:)]) {
        [self.delegate fileAttachmentHandler:self didFailToExportFileAttachment:fileAttachment fromPDFDoc:doc withError:error];
    }
}

- (void)handleExportSuccessForFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc toURL:(NSURL *)exportedURL
{
    // Notify delegate of export success.
    if ([self.delegate respondsToSelector:@selector(fileAttachmentHandler:didExportFileAttachment:fromPDFDoc:toURL:)]) {
        [self.delegate fileAttachmentHandler:self didExportFileAttachment:fileAttachment fromPDFDoc:doc toURL:exportedURL];
    }
}

#pragma mark - Export public API

- (void)exportFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc
{
    // Get the destination URL for the exported file attachment.
    NSError *exportError = nil;
    NSURL *exportedURL = [self destinationForExportedFileAttachment:fileAttachment fromPDFDoc:doc error:&exportError];
    if (!exportedURL) {
        // Could not determine destination URL.
        NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                          @{
                            NSLocalizedDescriptionKey : @"Failed to export file attachment",
                            NSLocalizedFailureReasonErrorKey : @"Could not determine the exported URL location",
                            NSUnderlyingErrorKey: exportError,
                            }];

        [self handleExportFailureForFileAttachment:fileAttachment fromPDFDoc:doc withError:error];
        return;
    }
    
    BOOL exported = NO;
    NSError *error = nil;
    
    // Export the file attachment to the destination URL.
    BOOL hasReadLock = NO;
    @try {
        [doc LockRead];
        hasReadLock = YES;
        
        // Actually export the file attachment.
        exported = [fileAttachment Export:exportedURL.path];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);

        // Failed to export file attachment.
        exported = NO;
        error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                 @{
                   NSLocalizedDescriptionKey: @"Failed to export file attachment",
                   NSLocalizedFailureReasonErrorKey: @"Error while exporting the file attachment",
                   NSUnderlyingErrorKey: exception.pt_error,
                   }];
    }
    @finally {
        if (hasReadLock) {
            [doc UnlockRead];
        }
    }
    
    if (!exported) {
        // Failed to export file attachment.
        if (!error) {
            error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                     @{
                       NSLocalizedDescriptionKey: @"Failed to export file attachment",
                       NSLocalizedFailureReasonErrorKey: @"An unknown error has occurred",
                       NSURLErrorKey: exportedURL,
                       }];
        }
        [self handleExportFailureForFileAttachment:fileAttachment fromPDFDoc:doc withError:error];
    } else {
        [self handleExportSuccessForFileAttachment:fileAttachment fromPDFDoc:doc toURL:exportedURL];
    }
}

@end
