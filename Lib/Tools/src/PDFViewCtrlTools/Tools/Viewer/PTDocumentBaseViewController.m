//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentBaseViewController.h"
#import "PTDocumentBaseViewControllerPrivate.h"

#import "PTThumbnailSliderViewController.h"
#import "PTOutlineViewController.h"
#import "PTAnnotationViewController.h"
#import "PTBookmarkViewController.h"
#import "PTPDFLayerViewController.h"
#import "PTNavigationListsViewController.h"
#import "PTSettingsViewController.h"

#import "PTAnnotationPasteboard.h"

#import "PTPanTool.h"
#import "PTAnnotEditTool.h"
#import "PTFormFillTool.h"
#import "PTAnnotSelectTool.h"
#import "PTTextMarkupEditTool.h"
#import "PTDigitalSignatureTool.h"
#import "PTRichMediaTool.h"

#import "PTFreeTextCreate.h"
#import "PTFreeHandCreate.h"
#import "PTTextHighlightCreate.h"
#import "PTFileAttachmentCreate.h"
#import "PTPencilDrawingCreate.h"
#import "PTRectangleCreate.h"
#import "PTEllipseCreate.h"
#import "PTLineCreate.h"
#import "PTArrowCreate.h"
#import "PTPolygonCreate.h"
#import "PTStickyNoteCreate.h"
#import "PTTextUnderlineCreate.h"
#import "PTTextStrikeoutCreate.h"

#import <PencilKit/PencilKit.h>

#import "PTAnalyticsManager.h"
#import "PTErrors.h"
#import "PTTimer.h"
#import "PTToolsUtil.h"
#import "UTTypes.h"
#import "PTFileAttachmentHandler.h"
#import "PTHalfModalPresentationController.h"
#import "PTPDFViewCtrlAdditions.h"
#import "PTPDFViewCtrlViewController.h"
#import "PTSelectableBarButtonItem.h"
#import "PTDocumentViewSettingsManager.h"
#import "PTDocumentItemProvider.h"

#import "UIViewController+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"
#import "NSHTTPURLResponse+PTAdditions.h"
#import "NSURL+PTAdditions.h"
#import "NSObject+PTOverridable.h"
#import "UIDocumentInteractionController+PTAdditions.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "CGGeometry+PTAdditions.h"
#import "PTToolsSettingsManager.h"
#import "PTKeyValueObserving.h"
#import "PTColorDefaults.h"

#import "PTToolsSettingsViewController.h"

#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#include <tgmath.h>


NS_ASSUME_NONNULL_BEGIN

const NSTimeInterval PTDocumentViewControllerSaveDocumentInterval = 30.0; // seconds

const NSTimeInterval PTDocumentViewControllerHideControlsInterval = 5.0; // seconds

#pragma mark - Notifications

const NSNotificationName PTDocumentViewControllerDidOpenDocumentNotification = @"PTDocumentViewControllerDidOpenDocumentNotification";

const NSNotificationName PTDocumentViewControllerDidDissmissShareActivityNotification = @"PTDocumentViewControllerDidDissmissShareActivityNotification";

const NSNotificationName PTDocumentViewControllerDidDissapearNotification = @"PTDocumentViewControllerDidDissapearNotification";


@interface PTDocumentBaseViewController() <PTFileAttachmentHandlerDelegate, PTPrintDelegate, PTPanelViewControllerDelegate, UIPopoverPresentationControllerDelegate, UIDocumentInteractionControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) BOOL constraintsLoaded;

@property (nonatomic) BOOL itemsLoaded;
@property (nonatomic, getter=isLoadingItems) BOOL loadingItems;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<UIBarButtonItem *> *> *adaptiveToolbarItems;
@property (nonatomic, getter=isUpdatingToolbarItems) BOOL updatingToolbarItems;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<UIBarButtonItem *> *> *adaptiveMoreItems;
@property (nonatomic, getter=isUpdatingMoreItems) BOOL updatingMoreItems;

@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *panelConstraints;
@property (nonatomic, assign) BOOL needsPanelConstraintsUpdate;

@property (nonatomic, assign) BOOL applicationStateActive;
@property (nonatomic, assign) BOOL saveRequested;

@property (nonatomic, strong) PTMappedFile* sepiaColourLookupMap;

#pragma mark Annotation toolbar

@property (nonatomic, strong, nullable) NSLayoutConstraint *annotationToolbarOnscreenConstraint;

#pragma mark Thumbnail slider

@property (nonatomic, strong, nullable) NSLayoutConstraint *thumbnailSliderOnscreenConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *thumbnailSliderOffscreenConstraint;

#pragma mark Page indicator

@property (nonatomic, assign) NSUInteger activePageIndicatorTransitionCount;

#pragma mark Modal view controllers

@property (nonatomic, strong, nullable) UIDocumentInteractionController *documentInteraction;
@property (nonatomic, assign, getter=isDocumentInteractionLoading) BOOL documentInteractionLoading;

#pragma mark Reflow control

#pragma mark Progress spinner

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign, getter=isActivityIndicatorHidden) BOOL activityIndicatorHidden;

#pragma mark Downloader

@property (nonatomic, strong) NSURL *cacheFile;

#pragma mark Bars

// Redeclare UIViewController.prefersStatusBarHidden as readwrite (and synthesize).
@property (nonatomic, readwrite) BOOL prefersStatusBarHidden;

@property (nonatomic, strong, nullable) PTTimer *automaticControlHidingTimer;

@property (nonatomic, strong, nullable) PTPrint *printer;
@property (nonatomic, strong, nullable) PTTimer *automaticDocumentSavingTimer;

@property (nonatomic, strong, nullable) PTTimer *lastPageReadTimer;

// Redeclare properties as readwrite internally.
@property (nonatomic, readwrite, strong, nullable) PTCoordinatedDocument *coordinatedDocument;

#pragma mark State

@property (nonatomic, assign) BOOL documentIsInValidState;
@property (nonatomic, strong, nullable) NSData *bookmarkedUrl;
@property (nonatomic, assign) BOOL documentIsPasswordLocked;
@property (nonatomic, assign) BOOL documentIsEncrypted;
@property (nonatomic, copy, nullable) NSString *documentPassword;
@property (nonatomic, strong) NSDate* resignedActiveDate;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundSaveId;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentBaseViewController

#pragma mark - Private document opening and closing

#pragma mark Local documents

- (void)PT_setCoordinatedDocument:(PTCoordinatedDocument *)coordinatedDocument password:(nullable NSString *)password completionHandler:(nullable void (^)(NSError * _Nullable error))completionHandler
{
    NSAssert([NSThread isMainThread], @"Must be called on the main thread");
    NSAssert(coordinatedDocument, @"Wrapper should not be null");
    NSAssert(coordinatedDocument.fileURL, @"Wrapper must have a fileURL");
    
    // Ensure that document is not already open.
    if ((coordinatedDocument.documentState & UIDocumentStateClosed) != UIDocumentStateClosed) {
        //document is already open
        NSAssert(false, @"Wrapper should not already be open");
    }
    
    // Close existing document.
    [self closeDocumentWithCompletionHandler:^(BOOL success) {
        // Ignore success flag.
        
        // Deregister for coordinated document state changes.
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UIDocumentStateChangedNotification
                                                    object:self.coordinatedDocument];
        self.coordinatedDocument.delegate = nil;
        self.coordinatedDocument = nil;
        
        // Open incoming document.
        [coordinatedDocument openWithCompletionHandler:^(BOOL success) {
            if (!success) {
                if (completionHandler) {
                    NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                                      @{
                                        NSLocalizedDescriptionKey : @"Document was not opened",
                                        NSLocalizedFailureReasonErrorKey : @"Unknown error",
                                        NSURLErrorKey: coordinatedDocument.fileURL,
                                        }];
                    
                    completionHandler(error);
                }
                return;
            }
            
            // Set the current coordinated document.
            self.coordinatedDocument = coordinatedDocument;
            self.coordinatedDocument.delegate = self;
            
            self.localDocumentURL = coordinatedDocument.fileURL;
            
            // Register for notifications on document.
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(documentStateChanged:)
                                                       name:UIDocumentStateChangedNotification
                                                     object:self.coordinatedDocument];
            
            // Generate bookmark data for the file path URL.
            NSURL *filePathURL = coordinatedDocument.fileURL.filePathURL;
            
            NSError *error;
            self.bookmarkedUrl = [filePathURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:nil relativeToURL:filePathURL.absoluteURL error:&error];
            
            NSAssert(error == nil, @"Error assigning self.bookmarkedUrl: %@", error.localizedDescription);
            NSAssert(self.bookmarkedUrl, @"bookmarkedUrl should not be nil");
            
            // Check if the document is locked with a password.
            self.documentIsPasswordLocked = NO;
            NSString *passwordString = (password ?: @""); // Ensure non-null password.
            BOOL shouldUnlock = NO;
            @try {
                [coordinatedDocument.pdfDoc LockRead];
                shouldUnlock = YES;
                
                self.documentIsPasswordLocked = ![coordinatedDocument.pdfDoc InitStdSecurityHandler:passwordString];
                self.documentIsEncrypted = self.documentIsPasswordLocked;
            }
            @catch (NSException *exception) {
                NSLog(@"Exception: %@, %@", exception.name, exception.reason);
                
                // Failed to open document.
                NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                    NSLocalizedDescriptionKey : @"Document was not opened",
                    NSLocalizedFailureReasonErrorKey : @"Unknown error",
                    NSURLErrorKey: coordinatedDocument.fileURL,
                    NSUnderlyingErrorKey: exception.pt_error,
                }];
                if (completionHandler) {
                    completionHandler(error);
                }
                return;
            }
            @finally {
                if (shouldUnlock) {
                    @try {
                        [coordinatedDocument.pdfDoc UnlockRead];
                    }
                    @catch (NSException *exception) {
                        // Ignored.
                    }
                }
            }
            
            if (!self.documentIsPasswordLocked) {
                // Actually set the PDFDoc on the PDFViewCtrl.
                NSError *error = nil;
                BOOL success = [self PT_setPDFDoc:coordinatedDocument.pdfDoc error:&error];
                if (!success) {
                    // Failed to set the PDFDoc.
                    if (completionHandler) {
                        completionHandler(error);
                    }
                    return;
                }
            }
            else if (!([self isBeingPresented] || [self isBeingDismissed]) && self.viewIfLoaded.window) {
                // Present unlock UI if possible.
                [self unlockDocument];
            }
            
            self.activityIndicatorHidden = YES;
            
            // Successfully opened the document.
            if (completionHandler) {
                completionHandler(nil /* success */);
            }
            return;
        }];
    }];
}

/**
 * Internal method to actually set the PDFDoc on the PDFViewCtrl and restore some saved data (the
 * last used page number) if available.
 *
 * @note The caller is responsible for closing the document in case of an error, if applicable.
 */
- (BOOL)PT_setPDFDoc:(PTPDFDoc *)doc error:(NSError * _Nullable *)error
{
    self.documentIsInValidState = YES;
    
    @try {
        [self.pdfViewCtrl SetDoc:doc];
    }
    @catch (NSException *exception) {
        // Failed to set the PDFDoc.
        if (error) {
            *error = exception.pt_error;
        }
        return NO;
    }
    
    // Set up tool manager.
    [self.toolManager setTool:[[PTPanTool alloc] initWithPDFViewCtrl:self.pdfViewCtrl]];
    self.toolManager.tool.annotationAuthor = [NSUserDefaults.standardUserDefaults stringForKey:@"annotation_author"];
    
    int pageNumber = 1;
    
    
    NSString *filePath = self.documentURL.path;
    
    if( filePath == nil)
    {
        filePath = self.coordinatedDocument.fileURL.path;
    }
    
    if (filePath.length > 0) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        pageNumber = [PTDocumentViewSettingsManager.sharedManager lastReadPageNumberForDocumentAtURL:fileURL];
    }
    
    // Have we opened this before? Find out and go to what page we were on.
    if( [NSUserDefaults.standardUserDefaults objectForKey:@"gotoLastPage"] == nil ||
       [NSUserDefaults.standardUserDefaults boolForKey:@"gotoLastPage"] )
    {
        [self.pdfViewCtrl SetCurrentPage:pageNumber];
    }
    
    [self updateViewMode];

    return YES;
}

- (void)PT_openPDFDocumentWithCoordinatedDocument:(PTCoordinatedDocument *)coordinatedDocument password:(NSString *)password
{
    [self PT_setCoordinatedDocument:coordinatedDocument password:password completionHandler:^(NSError *error) {
        if (error) {
            // Close document on error.
            [self closeDocumentWithCompletionHandler:^(__unused BOOL success) {
                [self handleDocumentOpeningFailureWithError:error];
            }];
            return;
        }
        
        if (self.viewIfLoaded.window) {
            // Ensure that the PDFViewCtrl has the correct safe area insets.
            // NOTE: Avoid doing this when the view controller is not attached to a window
            // since that can cause the layout to break in this class and/or elsewhere.
            
            BOOL controlsHidden = [self controlsHidden];
            
            [self PT_setControlsHidden:YES animated:NO];
            [self PT_setControlsHidden:NO animated:NO];
            
            if( controlsHidden )
            {
                [self PT_setControlsHidden:YES animated:NO];
            }
        }
        
        // Handle successful document opening.
        [self didOpenDocument];
        
        [NSNotificationCenter.defaultCenter postNotificationName:PTDocumentViewControllerDidOpenDocumentNotification
                                                          object:self
                                                        userInfo:Nil];
        
    }];
}

- (void)PT_openDocumentWithFileURL:(NSURL *)fileURL password:(NSString *)password
{
    NSParameterAssert([fileURL isFileURL]);
    
    // Create a coordinated document first, to give us access to the file resource.
    PTCoordinatedDocument *coordinatedDocument = [[PTCoordinatedDocument alloc] initWithFileURL:fileURL];
    
    NSString *type = PTUTTypeForURL(fileURL);
    CFStringRef typeRef = (__bridge CFStringRef)type;
    
    // .pdf
    if (UTTypeConformsTo(typeRef, kUTTypePDF)) {
        [self PT_openPDFDocumentWithCoordinatedDocument:coordinatedDocument password:password];
    }
    // internal conversion
    // images, .md, .doc(x), .pptx, .xlsx
    else if (PTUTTypeConformsToAny(typeRef, @[
        // Office.
        @"com.microsoft.word.doc", // .doc
        @"org.openxmlformats.wordprocessingml.document", // .docx
        @"org.openxmlformats.wordprocessingml.document.macroenabled", // .docx
        @"com.microsoft.powerpoint.ppt", // .ppt
        @"org.openxmlformats.presentationml.presentation", // .pptx
        @"org.openxmlformats.spreadsheetml.sheet", // .xlsx
        @"com.microsoft.excel.xls", //.xls
        
        // Markdown.
        (__bridge NSString *)kPTUTTypeMarkdown, // .md
        
        // Images.
        (__bridge NSString *)kUTTypePNG,
        (__bridge NSString *)kUTTypeJPEG,
        (__bridge NSString *)kUTTypeBMP,
        (__bridge NSString *)kUTTypeGIF,
        (__bridge NSString *)kUTTypeJPEG2000,
        (__bridge NSString *)kUTTypeTIFF,
    ])) {
        // Set document URL if not already set (this file might have been downloaded from a remote location).
        if (!self.documentURL) {
            self.documentURL = fileURL;
        }
        
        [self closeDocumentWithCompletionHandler:^(BOOL success) {
            
            // Hang onto the coordinated document to maintain access to the security-scoped resource
            // for as long as the document is being converted. Once it has been converted (or conversion
            // failed) the coordinated document can be dropped.
            self.coordinatedDocument = coordinatedDocument;
            
            self.localDocumentURL = fileURL;
            
            // Perform the conversion (synchronously).
            @try {
                
                self.documentIsInValidState = YES;
                                
                PTDocumentConversion *conversion = [PTConvert StreamingPDFConversion:fileURL.path
                                                                             options:self.conversionOptions];
                [self.pdfViewCtrl openUniversalDocumentWithConversion:conversion];
                
                // Show spinner.
                self.activityIndicatorHidden = NO;
                
                // Set up tool manager.
                [self.toolManager changeTool:[PTPanTool class]];
                self.toolManager.readonly = YES;
                
                [self.pdfViewCtrl SetCurrentPage:1];
                
                [self updateViewMode];
                
            } @catch (NSException *exception) {
                // Handle failure.
                NSError *error = exception.pt_error;
                [self handleDocumentOpeningFailureWithError:error];
                return;
            }
        }];

//        // Single-shot conversion
//        // Create empty PDFDoc for conversion output.
//        PTPDFDoc *pdfDoc = [[PTPDFDoc alloc] init];
//        // Get the final destination for the converted output.
//        NSString *destinationPath = [self convertedDocumentDestinationPathFromUrl:fileURL];

//
//        // Create coordinated document for the destination.
//        coordinatedDocument = [[PTCoordinatedDocument alloc] initWithFileURL:[NSURL fileURLWithPath:destinationPath]];
//

//
//        // Save the PDFDoc with the converted output to the destination path.
//        @try {
//            [pdfDoc SaveToFile:destinationPath flags:0];
//        } @catch (NSException *exception) {
//            // Notify delegate of failure.
//            if ([self.delegate respondsToSelector:@selector(documentViewController:didFailToOpenDocumentWithError:)]) {
//                NSError *error = exception.pt_error;
//                [self.delegate documentViewController:self didFailToOpenDocumentWithError:error];
//            }
//            return;
//        }
//
//        // Open the converted file at the destination.
//        [self PT_openPDFDocumentWithCoordinatedDocument:coordinatedDocument password:nil];
    }
    else if (PTUTTypeConformsToAny(typeRef, @[
        (__bridge NSString *)kPTUTTypeXPS,
        (__bridge NSString *)kPTUTTypeXOD,
    ])) {
        // Close existing document.
        [self closeDocumentWithCompletionHandler:^(BOOL success) {
            
            self.documentURL = fileURL;

            // Show spinner.
            self.activityIndicatorHidden = NO;
            
            // Get the final destination for the converted output.
            NSString *destinationPath = [self convertedDocumentDestinationPathFromUrl:fileURL];
            
            // Perform single-shot conversion, on background thread.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                PTPDFDoc *doc = nil;
                NSError *convertError = nil;
                BOOL success = NO;
                
                @try {
                    doc = [[PTPDFDoc alloc] init];
                    
                    // Convert the file to PDF.
                    [PTConvert ToPdf:doc in_filename:coordinatedDocument.fileURL.path];
                    
                    // Save the PDFDoc with the converted output to the destination path.
                    [doc SaveToFile:destinationPath flags:0];
                    
                    // Conversion was successful.
                    success = YES;
                }
                @catch (NSException *exception) {
                    convertError = exception.pt_error;
                    success = NO;
                }
                
                // Switch back to the main thread to open the converted (PDF) file.
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        NSURL *outputURL = [NSURL fileURLWithPath:destinationPath];
                        [self PT_openDocumentWithFileURL:outputURL password:nil];
                    } else {
                        // Handle failure.
                        NSString *reason = [NSString stringWithFormat:@"Cannot open file at URL \"%@\"", fileURL];
                        
                        NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                            NSLocalizedDescriptionKey: @"Failed to convert file",
                            NSLocalizedFailureReasonErrorKey: reason,
                            NSURLErrorKey: fileURL,
                            NSUnderlyingErrorKey: convertError,
                        }];
                        
                        [self handleDocumentOpeningFailureWithError:error];
                        return;
                    }
                });
                
            });
        }];
        
        // Show spinner.
        self.activityIndicatorHidden = NO;
    }
    else if (UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"public.heic")) {
        // Close existing document.
        [self closeDocumentWithCompletionHandler:^(BOOL success) {
            
            self.documentURL = fileURL;
            
            // Show spinner.
            self.activityIndicatorHidden = NO;
            
            // Convert from HEIC to JPEG, on background thread.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imageData = nil;
                NSURL *outputURL = nil;
                BOOL success = NO;
                
                // Open the HEIC image and get its data as JPEG.
                UIImage *image = [UIImage imageWithContentsOfFile:coordinatedDocument.fileURL.path];
                if (image) {
                    imageData = UIImageJPEGRepresentation(image, 0.7);
                }
                if (imageData) {
                    // Write the JPEG image out to a temporary location.
                    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                    
                    NSString *outputFilename = [fileURL.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"jpeg"];
                    
                    outputURL = [temporaryDirectoryURL URLByAppendingPathComponent:outputFilename];
                    
                    success = [imageData writeToURL:outputURL atomically:NO];
                }
                
                // Switch back to the main thread to open the JPEG image (internal conversion).
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [self PT_openDocumentWithFileURL:outputURL password:nil];
                    } else {
                        // Handle failure.
                        NSString *reason = [NSString stringWithFormat:@"Cannot open file at URL \"%@\"", fileURL];
                        
                        NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                                          @{
                                              NSLocalizedDescriptionKey: @"Failed to open image file",
                                              NSLocalizedFailureReasonErrorKey: reason,
                                              NSURLErrorKey: fileURL,
                                          }];
                        
                        [self handleDocumentOpeningFailureWithError:error];
                        return;
                    }
                });
            });
        }];
        
        // Show spinner.
        self.activityIndicatorHidden = NO;
    }
    // .ppt, .xls, pages, keynote, numbers
    else // try a WKWebView
    {
        // Some of the UTIs the WKWebView supports:
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.microsoft.excel.xls") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.microsoft.powerpoint.ppt") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.page.pages") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.iwork.pages.pages") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.iwork.pages.template") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.iwork.keynote.key") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.keynote.key") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.numbers.numbers") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.iwork.numbers.numbers") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.iwork.numbers.template") ||
        // UTTypeConformsTo(typeRef, (__bridge CFStringRef)@"com.apple.iwork.pages.sffpages"))
        
        // Close existing document.
        [self closeDocumentWithCompletionHandler:^(BOOL success) {
            // Ignore success flag.
            
            self.documentURL = fileURL;
            
            // Show spinner.
            self.activityIndicatorHidden = NO;
            
            [PTConvert convertOfficeToPDFWithURL:coordinatedDocument.fileURL paperSize:CGSizeZero completion:^(NSString *pathToPDF) {
                // Retain the coordinated document in completion block to ensure if lives until the
                // conversion is complete.
                (void)coordinatedDocument;
                
                // Check for failure (no output file path).
                if (pathToPDF.length == 0) {
                    // this is probably an unsupported file type, but maybe this is a PDF after all?
                    [self PT_openPDFDocumentWithCoordinatedDocument:coordinatedDocument password:password];
                    return;
                }
                
                NSURL *urlToPDF = [NSURL fileURLWithPath:pathToPDF];
                
                // Get the final destination for the converted document.
                NSString *destinationPath = [self convertedDocumentDestinationPathFromUrl:fileURL];
                
                // Create new coordinated document with the final destination.
                NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
                PTCoordinatedDocument *destinationCoordinatedDocument = [[PTCoordinatedDocument alloc] initWithFileURL:destinationURL];
                
                NSError *error = nil;
                BOOL success = NO;
                
                // Remove 0-byte placeholder file at destination path.
                if ([NSFileManager.defaultManager fileExistsAtPath:destinationPath]) {
                    NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:destinationPath
                                                                                                  error:nil];
                    if (fileAttributes[NSFileSize] && fileAttributes.fileSize == 0) {
                        // Replace the empty file with the temporary file.
                        NSError *replaceError = nil;
                        BOOL replaceSuccess = [NSFileManager.defaultManager replaceItemAtURL:destinationURL
                                                                               withItemAtURL:urlToPDF
                                                                              backupItemName:nil
                                                                                     options:0
                                                                            resultingItemURL:nil
                                                                                       error:&replaceError];
                        if (!replaceSuccess) {
                            error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                                NSLocalizedDescriptionKey: @"Failed to save coverted document",
                                NSLocalizedFailureReasonErrorKey: @"The converted document could not be saved to the destination",
                                NSUnderlyingErrorKey: replaceError,
                            }];
                        }
                        success = replaceSuccess;
                    }
                    else { // Error: a non-empty file exists at the destination path.
                        success = NO;
                        
                        NSString *reason = [NSString stringWithFormat:@"There is already a non-empty document at the destination \"%@\"",
                                            destinationURL.path];
                        error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                            NSLocalizedDescriptionKey: @"Failed to save coverted document",
                            NSLocalizedFailureReasonErrorKey: reason,
                        }];
                    }
                }
                else {
                    // Move the temporary file to final destination.
                    NSError *moveError = nil;
                    BOOL moveSuccess = [NSFileManager.defaultManager moveItemAtURL:urlToPDF
                                                                             toURL:destinationURL
                                                                             error:&moveError];
                    if (!moveSuccess) {
                        error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                            NSLocalizedDescriptionKey: @"Failed to save coverted document",
                            NSLocalizedFailureReasonErrorKey: @"The converted document could not be moved to the destination",
                            NSUnderlyingErrorKey: moveError,
                        }];
                    }
                    success = moveSuccess;
                }
                
                if (!success) {
                    [self handleDocumentOpeningFailureWithError:error];
                    return;
                }
                
                // Open the converted PDF document.
                [self PT_openPDFDocumentWithCoordinatedDocument:destinationCoordinatedDocument password:nil];
            }];
        }];
                
        self.activityIndicatorHidden = NO;
    }
}

#pragma mark Remote documents

- (void)PT_openPDFDocumentWithHTTPURL:(NSURL *)httpURL password:(NSString *)password
{
    NSParameterAssert([httpURL pt_isHTTPURL] || [httpURL pt_isHTTPSURL]);
    
    // Use local cache file.
    
    {
        NSURL *cachesURL = [NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
        if (cachesURL) {
            
            //NSString *fileName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"pdf"];
            
            // use file name to facilitate partial and previously downloaded file usage
            NSString *fileName = httpURL.lastPathComponent;
            if (fileName.length == 0) {
                fileName = [NSUUID UUID].UUIDString;
            }
            
            if( [fileName.pathExtension isEqualToString:@"pdf"] == NO )
            {
                fileName = [fileName stringByAppendingPathExtension:@"pdf"];
            }
            if( fileName == Nil )
            {
                fileName = [NSUUID UUID].UUIDString;
            }
            
            self.cacheFile = [cachesURL URLByAppendingPathComponent:fileName];
        }
    }
    
    self.localDocumentURL = self.cacheFile;
    self.documentPassword = password;
    
    //pdf
    @try {
        [self.pdfViewCtrl OpenUrlAsync:httpURL.absoluteString WithPDFPassword:self.documentPassword WithCacheFile:self.cacheFile.path WithOptions:self.httpRequestOptions];
    } @catch (NSException *exception) {
        // Failed to open URL.
        NSError *error = [exception pt_errorWithExtraUserInfo:@{NSURLErrorKey: httpURL}];
        
        [self closeDocumentWithCompletionHandler:^(__unused BOOL success) {
            [self handleDocumentOpeningFailureWithError:error];
        }];
        return;
    }
    
    // Show spinner.
    self.activityIndicatorHidden = NO;
    
    // Set up tool manager.
    [self.toolManager changeTool:[PTPanTool class]];
    self.toolManager.readonly = YES;
    
    [self.pdfViewCtrl SetCurrentPage:1];
    
    [self updateViewMode];
}

- (void)PT_openUnknownDocumentWithHTTPURL:(NSURL *)httpURL password:(NSString *)password
{
    NSParameterAssert([httpURL pt_isHTTPURL] || [httpURL pt_isHTTPSURL]);

    // Download unknown document at HTTP URL.
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:httpURL];
    mutableRequest.HTTPMethod = @"GET";
    
    if (self.additionalHTTPHeaders) {
        // Apply additional HTTP headers.
        for (NSString *header in self.additionalHTTPHeaders) {
            NSString *value = self.additionalHTTPHeaders[header];
            
            [mutableRequest addValue:value forHTTPHeaderField:header];
        }
    }
    
    NSURLSessionDownloadTask *downloadTask = [NSURLSession.sharedSession downloadTaskWithRequest:[mutableRequest copy] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            // Dispatch back to main thread.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleDocumentOpeningFailureWithError:error];
            });
            return;
        }
        
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *)response;
        }
        
        // Check for 404 status.
        if (httpResponse && httpResponse.statusCode == 404) {
            NSString *failureReason = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
            
            NSError *notFoundError = [NSError errorWithDomain:PTErrorDomain code:httpResponse.statusCode userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to open document",
                NSLocalizedFailureReasonErrorKey: failureReason,
                NSURLErrorKey: httpURL,
            }];
            
            // Dispatch back to main thread.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleDownloadFailureWithError:notFoundError];
            });
            return;
        }
        
        // Determine the base filename (without leading path information) and extension.
        NSString *baseFilename = nil;
        NSString *extension = nil;
        
        
        if (httpResponse) {
            // Extract filename from Content Disposition header value.
            NSString *filename = httpResponse.pt_contentDispositionFilename;
            
            // Strip leading path information.
            if (filename.length > 0) {
                baseFilename = filename.lastPathComponent;
            }
        }
        
        if (baseFilename.length == 0) {
            baseFilename = httpURL.lastPathComponent;
        }
        
        // Check if the file has an extension to tell us the type of the downloaded file.
        extension = baseFilename.pathExtension;
        if (extension.length == 0) {
            // Determine the filename extension from the response MIME type (or Content-Type).
            NSString *mimeType = response.MIMEType;
            if (!mimeType && httpResponse) {
                // Get response "Content-Type" header field.
                id contentType = httpResponse.allHeaderFields[@"Content-Type"];
                if ([contentType isKindOfClass:[NSString class]]) {
                    mimeType = (NSString *)contentType;
                }
            }
            extension = PTFilenameExtensionForMIMEType(mimeType);
            if (extension) {
                // Append the filename extension to the filename.
                baseFilename = [baseFilename stringByAppendingPathExtension:extension];
            }
        }
        
        // Copy the temporary file to a final location.
        
        NSString *safeLocationString = [self getUniqueFileName:baseFilename atPath:[location.path stringByDeletingLastPathComponent]];
        NSURL *safeLocation = [NSURL fileURLWithPath:safeLocationString];
        
        NSError *fileCopyError = nil;
        [NSFileManager.defaultManager copyItemAtURL:location toURL:safeLocation error:&fileCopyError];
        
        // Dispatch back to main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!fileCopyError) {
                
                self.activityIndicatorHidden = YES;
                self.toolManager.readonly = NO;
                
                [self PT_openDocumentWithFileURL:safeLocation password:nil];
            } else {
                [self handleDocumentOpeningFailureWithError:fileCopyError];
            }
        });
    }];
    // Start task.
    [downloadTask resume];
    
    // Show spinner.
    self.activityIndicatorHidden = NO;
    
    // Set up tool manager.
    [self.toolManager changeTool:[PTPanTool class]];
    self.toolManager.readonly = YES;
    
    [self.pdfViewCtrl SetCurrentPage:1];
    
    [self updateViewMode];
}

- (void)PT_openDocumentWithHTTPURL:(NSURL *)httpURL password:(NSString *)password
{
    NSParameterAssert([httpURL pt_isHTTPURL] || [httpURL pt_isHTTPSURL]);
    
    // Close existing document.
    [self closeDocumentWithCompletionHandler:^(BOOL success) {
        // Ignore success flag.
        
        self.documentURL = httpURL;
        
        self.documentIsInValidState = YES;
        
        // Fetch the UTI for the given HTTP URL, possibly making a HEAD request if there is no
        // path extension information in the URL.
        PTFetchUTTypeForHTTPURL(httpURL, self.additionalHTTPHeaders, ^(NSString *type) {
            // .pdf
            if (UTTypeConformsTo((__bridge CFStringRef)type, kUTTypePDF)) {
                [self PT_openPDFDocumentWithHTTPURL:httpURL password:password];
            } else {
                // Manually download the document and try to open the local copy.
                [self PT_openUnknownDocumentWithHTTPURL:httpURL password:password];
            }
        });
    }];
}

#pragma mark - Document opening helpers

- (NSString *)getUniqueFileName:(NSString *)inputFileName atPath:(NSString *)newPath
{
    if( inputFileName == Nil )
    {
        inputFileName = [NSUUID UUID].UUIDString;
    }
    
    NSFileManager* fileManager = NSFileManager.defaultManager;
    
    NSString* combined = [newPath stringByAppendingPathComponent:inputFileName];

    NSString* ext = inputFileName.pathExtension;
    NSString* noExt = [combined stringByDeletingPathExtension];
    
    NSUInteger i = 1;
    
    combined = [noExt stringByAppendingPathExtension:ext];
    
    while ([fileManager fileExistsAtPath:combined])
    {
        combined = [noExt stringByAppendingFormat:@" %lu.%@", (unsigned long)i, ext];
        
        i++;
    }
    
    return [combined copy];
}

- (NSString *)convertedDocumentDestinationPathFromUrl:(nonnull NSURL *)url
{
    NSString *destinationPath = [self destinationURLforDocumentAtURL:url].path;
    
    
    
    
    
    if (destinationPath) {
        PTLog(@"Will save document to %@ as per delegate method.", destinationPath);
        return destinationPath;
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSFileManager* fileManager = NSFileManager.defaultManager;
    
    NSString* urlString = url.URLByDeletingLastPathComponent.path;
    
    if (![urlString hasSuffix:@"/"]) {
        urlString = [urlString stringByAppendingString:@"/"];
    }
    
    BOOL isWriteableDirectory = [fileManager isWritableFileAtPath:urlString];
    
    if( isWriteableDirectory && [urlString containsString:documentsDirectory] )
    {
        // somewhere in the documents directory

        
        destinationPath = [self getUniqueFileName:[url.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:@"pdf"] atPath:urlString];
        

    }
    else
    {
        // another app's sandbox, or iCloud

        
        destinationPath = [self getUniqueFileName:[[url.lastPathComponent stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"] atPath:documentsDirectory];
        

    }
    
    return destinationPath;
}

#pragma mark - Public document opening and closing

- (void)openDocumentWithURL:(NSURL *)url
{
    [self openDocumentWithURL:url password:nil];
}

- (void)openDocumentWithURL:(NSURL *)url password:(NSString *)password
{
    [self loadViewIfNeeded];
    
    // file:// URLs.
    if ([url isFileURL]) {
        [self PT_openDocumentWithFileURL:url password:password];
    }
    // http(s):// URLs.
    else if ([url pt_isHTTPURL] || [url pt_isHTTPSURL]) {
        [self PT_openDocumentWithHTTPURL:url password:password];
    }
    // Unsupported URL scheme: notify delegate of failure.
    else {
        NSString *reason = [NSString stringWithFormat:@"Cannot open URL with scheme \"%@\"", url.scheme];
        
        NSError *error = [NSError errorWithDomain:PTErrorDomain code:NSURLErrorUnsupportedURL userInfo:@{
            NSLocalizedDescriptionKey: @"Unsupported URL scheme",
            NSLocalizedFailureReasonErrorKey: reason,
            NSURLErrorKey: (url ?: [NSNull null]),
        }];
        
        [self handleDocumentOpeningFailureWithError:error];
    }
}

- (void)openDocumentWithPDFDoc:(PTPDFDoc *)document
{
    [self loadViewIfNeeded];
    // Close existing document.
    [self closeDocumentWithCompletionHandler:^(BOOL success) {
        // Ignore success flag.
        
        // Actually set the PDFDoc on the PDFViewCtrl.
        NSError *error = nil;
        if (![self PT_setPDFDoc:document error:&error]) {
            [self handleDocumentOpeningFailureWithError:error];
        } else {
            
            BOOL controlsHidden = [self controlsHidden];
            
            [self PT_setControlsHidden:YES animated:NO];
            [self PT_setControlsHidden:NO animated:NO];
            
            if( controlsHidden )
            {
                [self PT_setControlsHidden:YES animated:NO];
            }
            
            // Handle successful document opening.
            [self didOpenDocument];
            
            [NSNotificationCenter.defaultCenter postNotificationName:PTDocumentViewControllerDidOpenDocumentNotification
                                                              object:self
                                                            userInfo:Nil];
        }
    }];
}

- (void)closeDocumentWithCompletionHandler:(void (^)(BOOL success))completionHandler
{
    
    if( (self.coordinatedDocument.documentState & UIDocumentStateClosed) == UIDocumentStateClosed)
    {
        //document is already closed
        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    
    if( [[self.pdfViewCtrl GetDoc] HasDownloader] )
    {
        //Closing doc directly because in downloader
        [self.pdfViewCtrl CloseDoc];
        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    
    // Check if there is a document to close.
    if (![self.pdfViewCtrl GetDoc]) {
        // there is no document....
        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    
    [self.toolManager changeTool:[PTPanTool class]];
    
    // Save document before closing.
    [self saveDocument:e_ptincremental completionHandler:^(BOOL success) {
        // Close PDFViewCtrl.
        @try {
            [self.pdfViewCtrl CloseDoc];
        } @catch (NSException *exception) {
            PTLog(@"Exception: %@: reason: %@", exception.name, exception.reason);
        }
        
        // Actually close the document.
        if (self.coordinatedDocument) {
            [self.coordinatedDocument closeWithCompletionHandler:^(BOOL success) {
                if (completionHandler) {
                    completionHandler(success);
                }
            }];
        } else {
            if (completionHandler) {
                completionHandler(YES);
            }
        }
     }];
    
    self.activityIndicatorHidden = YES;
}

#pragma mark - Document property accessors

- (PTPDFDoc *)document
{
    @try {
        return [self.pdfViewCtrl GetDoc];
    }
    @catch (...) {
        // Ignore.
    }
    return nil;
}

-(PTHTTPRequestOptions*)httpRequestOptions
{
    if(_httpRequestOptions)
    {
        return _httpRequestOptions;
    }
    else
    {
        _httpRequestOptions = [[PTHTTPRequestOptions alloc] init];
        return _httpRequestOptions;
    }
}

- (void)setAdditionalHTTPHeaders:(NSDictionary<NSString *,NSString *> *)additionalHTTPHeaders
{
    _additionalHTTPHeaders = [additionalHTTPHeaders copy];
    
    if (additionalHTTPHeaders) {
        // Add additional headers to the HTTPRequestOptions object.
        for (NSString *header in additionalHTTPHeaders) {
            NSString *value = additionalHTTPHeaders[header];
            
            [self.httpRequestOptions AddHeader:header val:value];
        }
    }
}

- (PTConversionOptions *)conversionOptions
{
    if (!_conversionOptions) {
        _conversionOptions = [[PTConversionOptions alloc] initWithValue:@"{\"RemovePadding\": true}"];
    }
    return _conversionOptions;
}

- (void)setDocumentURL:(NSURL *)documentURL
{
    _documentURL = documentURL;
    
    self.documentTabItem.sourceURL = documentURL;
    
    // Reset local URL.
    self.localDocumentURL = nil;
}

@synthesize localDocumentURL = _localDocumentURL;

- (NSURL *)localDocumentURL
{
    if (_localDocumentURL) {
        return _localDocumentURL;
    }
    
    if ([self.documentURL isFileURL]) {
        return self.documentURL;
    }
    
    return nil;
}

- (void)setLocalDocumentURL:(NSURL *)localDocumentURL
{
    _localDocumentURL = localDocumentURL;
    
    self.documentTabItem.documentURL = localDocumentURL;
}

#pragma mark - <PTCoordinatedDocumentDelegate>


-(BOOL)coordinatedDocumentShouldSave:(PTCoordinatedDocument*)coordinatedDocument
{
    
    if( self.automaticallySavesDocument == NO && (self.saveRequested == NO || self.applicationStateActive == NO) )
    {
        // if automatic saving is off, and the save is triggered by iOS when moving to the background
        // (when a button press or similar save action would be impossible), then return NO.
        
        // if automatic saving is off, save only if explicitly requested
        return NO;
    }
    else
    {
        return YES;
    }
    
}

-(BOOL)coordinatedDocumentShouldAutoSave:(PTCoordinatedDocument*)coordinatedDocument
{
    return self.automaticallySavesDocument;
}

-(void)coordinatedDocument:(PTCoordinatedDocument*)coordinatedDocument presentedItemDidMoveToURL:(NSURL *)newURL
{
    if (@available(iOS 13.0, *)) {
        // File seems to usually exist for iOS 13.
        if ([NSFileManager.defaultManager fileExistsAtPath:newURL.path]) {
            return;
        }
    }
    
    // Although the document should in theory now be at a new URL, it does not seem to exist.
    if( newURL )
    {
        self.documentIsInValidState = YES;
        
        [self didBecomeInvalid];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.pdfViewCtrl CloseDoc];
        });
        return;
    }
}

-(void)coordinatedDocumentDidChange:(PTCoordinatedDocument*)coordinatedDocument
{
    if( coordinatedDocument.pdfDoc != Nil )
    {
        dispatch_async( dispatch_get_main_queue(), ^{
            [self syncPDFViewCtrlWithCoordinatedDoc];
        });
    }
}

#pragma mark - Application lifecycle notifications

- (void)PT_applicationWillEnterForeground:(NSNotification *)notification
{


    
    self.applicationStateActive = NO;
    
    
    if (@available(iOS 13.0, *)) {
        if ([PKToolPicker sharedToolPickerForWindow:self.view.window].isVisible) {
            [[PKToolPicker sharedToolPickerForWindow:self.view.window] setVisible:NO forFirstResponder:[[UIResponder alloc] init]];
        }
    }

    if( self.coordinatedDocument )
    {
        NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.coordinatedDocument.fileURL.path error:Nil];
        
        NSDate *fileModificationDate = [attributes fileModificationDate];
        
        if( [self.resignedActiveDate timeIntervalSinceReferenceDate] < [fileModificationDate timeIntervalSinceReferenceDate] )
        {
           [self refreshDocument];
        }
    }
}

- (void)PT_applicationDidBecomeActive:(NSNotification *)notification
{
    self.applicationStateActive = YES;
}

- (void)PT_applicationDidEnterBackground:(NSNotification *)notification
{

    
    self.applicationStateActive = NO;
    
    // shut down background rendering threads that can run into trouble when in the background.
    [self.pdfViewCtrl CancelRendering];
    
    // commits any annotation that is currently being created
       if ([self.toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
           [self.toolManager.tool performSelector:@selector(commitAnnotation)];
       }
       
       [self.toolManager changeTool:[PTPanTool class]];
       
       if (self.automaticallySavesDocument) {
           // Save the document in case the previously active tool modified the document before exiting.
           // NOTE: UIDocument checks for unsaved changes when entering the background, but the notification
           // delivery order is undefined (sometimes the changes would be saved automatically, or not).
           [self saveDocument:e_ptincremental completionHandler:^(BOOL success) {
               
               self.resignedActiveDate = [NSDate date];
               
               [UIApplication.sharedApplication endBackgroundTask:self.backgroundSaveId];

           }];
       } else {
           self.resignedActiveDate = [NSDate date];
           
           [UIApplication.sharedApplication endBackgroundTask:self.backgroundSaveId];
           

       }
    
    // Record what page this document is on.
    NSString *filePath = self.documentURL.path ?: self.coordinatedDocument.fileURL.path;
    if (self.document && filePath) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [PTDocumentViewSettingsManager.sharedManager setLastReadPageNumber:self.pdfViewCtrl.currentPage
                                                          forDocumentAtURL:fileURL];
    }
}

-(void)PT_applicationWillResignActive:(NSNotification *)notification
{

    
    self.applicationStateActive = NO;
    
    if( self.automaticallySavesDocument )
    {
        self.backgroundSaveId = [UIApplication.sharedApplication beginBackgroundTaskWithExpirationHandler:^{

            NSLog(@"Insufficient time to save.");
            
            [UIApplication.sharedApplication endBackgroundTask:self.backgroundSaveId];
        }];
    }
}

#pragma mark - UIDocumentStateChangedNotification

- (void)documentStateChanged:(NSNotification *)notification
{
    if (!self.coordinatedDocument) {
        return;
    }
    
    NSAssert(notification.object == self.coordinatedDocument,
             @"Coordinated document notification is not for the current document");
    
    if( notification.object != self.coordinatedDocument )
    {
        return;
    }
    
    UIDocumentState state = self.coordinatedDocument.documentState;
    
    // Print document state.
    NSString* stateString = @"";
    if (state == UIDocumentStateNormal) {
        stateString = @"UIDocumentStateNormal";
        self.documentIsInValidState = YES;
        if ( !self.toolManager.tool )
        {
            [self.toolManager changeTool:[PTPanTool class]];
        }
    }
    if (state & UIDocumentStateClosed) {
        stateString = [stateString stringByAppendingString:@", UIDocumentStateClosed"];
        self.documentIsInValidState = NO;
    }
    if (state & UIDocumentStateInConflict) {
        stateString = [stateString stringByAppendingString:@", UIDocumentStateInConflict"];
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:PTLocalizedString(@"Conflict", @"")
                                                                                 message:PTLocalizedString(@"This document is in conflict with an old version. The current version will be kept.", @"")
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK",@"")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self resolveDocumentConflict];
                                                         }];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        
        
    }
    if (state & UIDocumentStateSavingError) {
        stateString = [stateString stringByAppendingString:@", UIDocumentStateSavingError"];
        
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:PTLocalizedString(@"Saving error", @"")
                                                                                 message:PTLocalizedString(@"There was an error when trying to save the document.", @"")
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK",@"")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
    if (state & UIDocumentStateEditingDisabled) {
        stateString = [stateString stringByAppendingString:@", UIDocumentStateEditingDisabled"];
        self.documentIsInValidState = NO;
        self.toolManager.tool = nil;
    }
    if (state & UIDocumentStateProgressAvailable) {
        stateString = [stateString stringByAppendingString:@", UIDocumentStateProgressAvailable"];



    }
    

    
}

-(void)resolveDocumentConflict
{
    // To accept the current version, remove the other versions,
    // and resolve all the unresolved versions.
    
    NSError* error;
    
    [NSFileVersion removeOtherVersionsOfItemAtURL:self.coordinatedDocument.presentedItemURL.filePathURL error:&error];
    
    NSAssert(!error, @"error");
    
    NSArray<NSFileVersion *>* conflictingVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.coordinatedDocument.presentedItemURL.filePathURL];
    
    if( [conflictingVersions count] > 0 )
    {
        for( NSFileVersion* version in conflictingVersions )
        {
            version.resolved = YES;
        }
    }
}

#pragma mark - Refresh current document

// if coming back into forground, re-open from disk using bookmark stuff
// if coming from coordinated doc for???, call pdfviewctrl setdoc
// if coming from coordinated doc because call to open, call setdoc

-(void)syncPDFViewCtrlWithCoordinatedDoc
{
    if( self.coordinatedDocument.pdfDoc != Nil )
    {
        [self.toolManager changeTool:[PTPanTool class]];
        
        int pageNumber = [self.pdfViewCtrl GetCurrentPage];
        double hPos = [self.pdfViewCtrl GetHScrollPos];
        double vPos = [self.pdfViewCtrl GetVScrollPos];
        double scale = [self.pdfViewCtrl GetZoom];
        TrnZoomLimitMode zoomMode = [self.pdfViewCtrl GetZoomLimitMode];
        double zoomMin = [self.pdfViewCtrl GetZoomMinimumLimit];
        double zoomMax = [self.pdfViewCtrl GetZoomMaximumLimit];
        if( self.documentIsEncrypted && !self.documentIsPasswordLocked )
        {
            [self.coordinatedDocument.pdfDoc InitStdSecurityHandler:self.documentPassword];
            [self.pdfViewCtrl SetDoc:self.coordinatedDocument.pdfDoc];
            self.documentIsInValidState = YES;
            [self.pdfViewCtrl SetCurrentPage:pageNumber];
            [self.pdfViewCtrl SetZoom:scale];
            [self.pdfViewCtrl SetHScrollPos:hPos Animated:NO];
            [self.pdfViewCtrl SetVScrollPos:vPos Animated:NO];
            [self.pdfViewCtrl Update:YES];
        }
        else if( self.documentIsEncrypted && self.documentIsPasswordLocked )
        {
            [self unlockDocument];
        }
        else
        {
            [self.pdfViewCtrl SetDoc:self.coordinatedDocument.pdfDoc];
            self.documentIsInValidState = YES;
            [self.pdfViewCtrl SetCurrentPage:pageNumber];
            [self.pdfViewCtrl SetZoom:scale];
            [self.pdfViewCtrl SetHScrollPos:hPos Animated:NO];
            [self.pdfViewCtrl SetVScrollPos:vPos Animated:NO];
            [self.pdfViewCtrl SetZoomLimits:zoomMode Minimum:zoomMin Maxiumum:zoomMax];
            [self.pdfViewCtrl Update:YES];
        }
    }
}

-(void)refreshDocument
{
    if( !self.coordinatedDocument )
    {

        return;
    }
    

    NSURL* url;
    
    BOOL isStale;
    NSError* error;
    
    NSAssert(self.bookmarkedUrl, @"There needs to be a bookmark, yo");
    
    url = [NSURL URLByResolvingBookmarkData:self.bookmarkedUrl options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];

    NSAssert(isStale == NO, @"URL is stale");
    NSAssert(!error, @"There's an error refreshing the document");
    
    [self.undoManager removeAllActions];
    
    if( isStale || error )
    {

        url = self.coordinatedDocument.presentedItemURL;
    }
    
    @try
    {
        
        [self.coordinatedDocument openWithCompletionHandler:^(BOOL success) {
            if( success )
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self syncPDFViewCtrlWithCoordinatedDoc];
                });
            }
            else
            {
                PTLog(@"Could not open (refresh) document.");
            }
        }];
    }
    @catch (NSException *exception) {
        if( [NSThread isMainThread] )
        {
            [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            return;
        }
        else
        {
            dispatch_async( dispatch_get_main_queue(), ^{
                [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            });
            return;
        }
        
    }
    
    return;
}

#pragma mark - Initialization and helpers

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTDocumentBaseViewController_commonInit];
    }
    return self;
}

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self PTDocumentBaseViewController_commonInit];
    }
    return self;
}


- (void)PTDocumentBaseViewController_commonInit
{
    BOOL enabled = PTToolsSettingsManager.sharedManager.javascriptEnabled;
    [PTPDFNet EnableJavaScript:enabled];
    
    NSString* path = [[NSBundle bundleForClass:[PTPDFNet class]] pathForResource:@"cmyk" ofType:@"icc"];
    
    if( path && PTToolsSettingsManager.sharedManager.colorManagementEnabled )
    {
        [PTPDFNet SetColorManagement:e_ptlcms];
        [PTPDFNet SetDefaultDeviceCMYKProfile:path];
    }
    else
    {
        [PTPDFNet SetColorManagement:e_ptno_cms];
    }
   
    _pdfViewCtrl = [[PTPDFViewCtrl alloc] init];
    
    CGFloat defaultRGB = 216.0/255.0;
    UIColor *bgColor = [UIColor colorWithRed:defaultRGB green:defaultRGB blue:defaultRGB alpha:1.0];
    if (@available(iOS 11.0, *)) {
        bgColor = [UIColor colorNamed:@"viewCtrlBGColor"
                             inBundle:PTToolsUtil.toolsBundle
        compatibleWithTraitCollection:self.traitCollection];
    }
    self.pdfViewCtrl.backgroundColor = bgColor;
    
    [_pdfViewCtrl SetRenderedContentBufferSize:96];
    
    [_pdfViewCtrl SetImageSmoothing:NO];
    [_pdfViewCtrl SetOverprint:e_ptop_pdfx_on];

    [_pdfViewCtrl SetProgressiveRendering:YES withInitialDelay:0 withInterval:750];
    [_pdfViewCtrl SetPageViewMode:e_trn_fit_width];
    [_pdfViewCtrl SetPageRefViewMode:e_trn_zoom];

    [_pdfViewCtrl SetHighlightFields:YES];
    
    [_pdfViewCtrl SetUrlExtraction:YES];

    [_pdfViewCtrl SetZoomLimits:e_trn_zoom_limit_relative Minimum:1.0 Maxiumum:50.0];

    [_pdfViewCtrl SetupThumbnails:NO generate_at_runtime:YES use_disk_cache:YES thumb_max_side_length:1024 max_abs_cache_size:1024*1024*500 max_perc_cache_size:0.8];
    
    if (@available(iOS 11, *)) {
        _pdfViewCtrl.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    } else {
        PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
        self.automaticallyAdjustsScrollViewInsets = NO;
        PT_IGNORE_WARNINGS_END
    }
    
    #if TARGET_OS_MACCATALYST
    UIHoverGestureRecognizer *hover = [[UIHoverGestureRecognizer alloc] initWithTarget:self action:@selector(handleHover:)];
    [_pdfViewCtrl addGestureRecognizer:hover];

    _toolbarDefaultItemIdentifiers = @[self.navigationListsToolbarItem.itemIdentifier,
                                       self.thumbnailsToolbarItem.itemIdentifier,
                                       NSToolbarFlexibleSpaceItemIdentifier,
                                       self.searchToolbarItem.itemIdentifier,
                                       self.reflowToolbarItem.itemIdentifier];
    _toolbarAllowedItemIdentifiers = _toolbarDefaultItemIdentifiers;
    #endif
    
    _pdfViewCtrl.delegate = self;
    _applicationStateActive = YES;
    
    _toolManager = [[PTToolManager allocOverridden] initWithPDFViewCtrl:_pdfViewCtrl];
    
    if( PTToolsSettingsManager.sharedManager.applePencilDrawsInk )
    {
        if ([self.toolManager freehandUsesPencilKit]) {
            if (@available(iOS 13.1, *) ) {
                 _toolManager.pencilTool = [PTPencilDrawingCreate class];
            }
        } else {
             _toolManager.pencilTool = [PTFreeHandCreate class];
        }
    }
    else
    {
        _toolManager.pencilTool = Nil;
    }
    
    _pdfViewCtrl.toolDelegate = _toolManager;
    _toolManager.delegate = self;
    
    _toolManager.pageIndicatorEnabled = NO;
            
    _automaticallySavesDocument = !PT_ToolsMacCatalyst;
    _automaticDocumentSavingInterval = PTDocumentViewControllerSaveDocumentInterval;
    
    _pageFitsBetweenBars = YES;
    _changesPageOnTap = YES;
    
    _hidesControlsOnTap = !PT_ToolsMacCatalyst;
    _automaticallyHideToolbars = PTToolsSettingsManager.sharedManager.automaticallyHideToolbars;
    _automaticControlHidingDelay = PTDocumentViewControllerHideControlsInterval;
        
    _thumbnailSliderEnabled = NO;
    _thumbnailSliderHidden = !_thumbnailSliderEnabled;
    
    // Page indicator settings.
    _pageIndicatorEnabled = YES;
    _pageIndicatorShowsOnPageChange = YES;
    _pageIndicatorShowsWithControls = YES;
        
    _pageIndicatorHidden = YES;
    _reflowHidden = YES;
    
    _saveRequested = NO;
            
    _adaptiveToolbarItems = [NSMutableDictionary dictionary];
    _adaptiveMoreItems = [NSMutableDictionary dictionary];
        
    // monitor changes to settings
    
    NSArray<NSString*>* toolKeyPaths = @[PT_CLASS_KEY(PTToolsSettingsManager, selectAnnotationAfterCreation),
                                         PT_CLASS_KEY(PTToolsSettingsManager, pencilHighlightMultiplyBlendModeEnabled),
                                         PT_CLASS_KEY(PTToolsSettingsManager, pencilInteractionMode)
    ];
    
    for(NSString* keyPath in toolKeyPaths )
    {
        [self pt_observeObject:PTToolsSettingsManager.sharedManager forKeyPath:keyPath selector:@selector(toolManagerSettingDidChange:) options:NSKeyValueObservingOptionNew];
    }
    
    NSArray<NSString*>* docVCKeyPaths = @[PT_CLASS_KEY(PTToolsSettingsManager, automaticallyHideToolbars)];
    
    for(NSString* keyPath in docVCKeyPaths )
    {
        [self pt_observeObject:PTToolsSettingsManager.sharedManager forKeyPath:keyPath selector:@selector(documentViewControllerSettingDidChange:) options:NSKeyValueObservingOptionNew];
    }
    
    NSArray<NSString*>* otherKeyPaths = @[
        PT_CLASS_KEY(PTToolsSettingsManager, javascriptEnabled),
        PT_CLASS_KEY(PTToolsSettingsManager, applePencilDrawsInk),
        PT_CLASS_KEY(PTToolsSettingsManager, freehandUsesPencilKit),
        PT_CLASS_KEY(PTToolsSettingsManager, showInkInMainToolbar),
        PT_CLASS_KEY(PTToolsSettingsManager, colorManagementEnabled)
    ];
    
    for(NSString* keyPath in otherKeyPaths )
    {
        [self pt_observeObject:PTToolsSettingsManager.sharedManager forKeyPath:keyPath selector:@selector(toolsSettingsDidChange:) options:NSKeyValueObservingOptionNew];
    }
    

}

- (void)dealloc
{
    // Invalidate timers.
    [_automaticDocumentSavingTimer invalidate];
    [_automaticControlHidingTimer invalidate];
    [_lastPageReadTimer invalidate];
    
    [self.toolManager changeTool:[PTPanTool class]];
    
    _pdfViewCtrl.delegate = nil;
    _pdfViewCtrl.toolDelegate = nil;
    
    if ([_pdfViewCtrl GetDoc]) {
        [_pdfViewCtrl CancelAllThumbRequests];
        [_pdfViewCtrl CancelRendering];
        
        // The document should be saved before the control is deallocated
        // If it is not, something has gone wrong, and a backup copy is saved
        if([[_pdfViewCtrl GetDoc] IsModified] && ![[_pdfViewCtrl GetDoc] HasDownloader] && ![_pdfViewCtrl documentConversion] && _automaticallySavesDocument)
        {
            @try {
                [_pdfViewCtrl DocLock:YES];
           
                PTPDFDoc* emergencySave = [_pdfViewCtrl GetDoc];
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = paths[0];
                
                NSString* baseName;
                
                @try {
                    baseName = [emergencySave GetFileName].lastPathComponent.stringByDeletingPathExtension;
                } @catch (NSException *exception) {
                    baseName = @"Open PDF Document";
                }
                
                NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd-hh:mm:ss:SSS"];
                
                NSString *fileModificationDateString = [formatter stringFromDate:[NSDate date]];

                NSString* uniquePDFName = [baseName stringByAppendingString:[NSString stringWithFormat:@"-%@.pdf", fileModificationDateString]];
                
                NSString* newFile = [documentsDirectory stringByAppendingPathComponent:uniquePDFName];
                
                [emergencySave SaveToFile:newFile flags:e_ptincremental];
                
                NSString* localizedFormatString = PTLocalizedString(@"There was a problem saving your document. A backup copy was saved to %@", @"");
                
                NSLog(@"%@", [NSString stringWithFormat:localizedFormatString, uniquePDFName]);
                
            } @catch (NSException *exception) {
                
            } @finally {
                [_pdfViewCtrl DocUnlock];
            }
            
        }
        
        NSAssert(!([[_pdfViewCtrl GetDoc] IsModified] && ![[_pdfViewCtrl GetDoc] HasDownloader] && ![_pdfViewCtrl documentConversion] && _automaticallySavesDocument),
                 @"Document has unsaved changes in dealloc");
    }
    
    if (_coordinatedDocument) {
        [_coordinatedDocument closeWithCompletionHandler:^(BOOL success) {
            if (!success) {

            }
        }];
    }
    
    // Remove all annotation options observers.
    for (PTKeyValueObservation *observation in self.pt_observations) {
        [observation invalidate];
    }
    

}

- (void)updateViewMode
{
    PTDocumentViewSettingsManager *manager = PTDocumentViewSettingsManager.sharedManager;
    
    PTDocumentViewSettings *viewSettings;
    if (self.localDocumentURL) {
        viewSettings = [manager viewSettingsForDocumentAtURL:self.localDocumentURL];
    }
    
    if (!viewSettings) {
        viewSettings = manager.defaultViewSettings;
    }
    
    NSAssert(viewSettings != nil,
             @"Failed to get view settings for document");
        
    if(! [viewSettings isReflowEnabled] )
    {
        switch (viewSettings.pagePresentationMode) {
            case e_trn_single_page:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Single Page selected"];
                break;
            case e_trn_single_continuous:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Continuous selected"];
                break;
            case e_trn_facing:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Facing"];
                break;
            case e_trn_facing_continuous:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Facing Continuous"];
                break;
            case e_trn_facing_cover:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Cover Facing"];
                break;
            case e_trn_facing_continuous_cover:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Cover Facing Continuous"];
                break;
        }
    }
    self.pdfViewCtrl.pagePresentationMode = viewSettings.pagePresentationMode;
    
    if( viewSettings.colorPostProcessMode == e_ptpostprocess_gradient_map )
    {
        NSString* sepiaPath = [PTToolsUtil.toolsBundle pathForResource:@"sepia_mode_filter" ofType:@"png" inDirectory:@"Images"];
        self.sepiaColourLookupMap = [[PTMappedFile alloc] initWithFilename:sepiaPath];
        [self.pdfViewCtrl SetColorPostProcessMapFile:_sepiaColourLookupMap];
    }
    else
    {
        [self.pdfViewCtrl SetColorPostProcessMode:viewSettings.colorPostProcessMode];
    }
    
    // (Night mode does not yet support progressive rendering)
    const BOOL progressiveRenderingEnabled = (viewSettings.colorPostProcessMode == e_ptpostprocess_none);
    [self.pdfViewCtrl SetProgressiveRendering:!progressiveRenderingEnabled
                             withInitialDelay:0
                                 withInterval:750];
    [self.pdfViewCtrl Update:YES];
    
    while (self.pdfViewCtrl.rotation != viewSettings.pageRotation) {
        [self.pdfViewCtrl RotateClockwise];
    }
    
    // Always need to check if reflow should be shown/hidden.
    if ([viewSettings isReflowEnabled]) {
        [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Reader"];
        self.reflowHidden = YES;
        
        PTReflowMode currentReflowMode = -1;
        if( _reflowViewController )
        {
            currentReflowMode = _reflowViewController.reflowMode;
        }
        _reflowViewController = [[PTReflowViewController allocOverridden] initWithPDFViewCtrl:self.pdfViewCtrl];
        _reflowViewController.delegate = self;
        
        if( currentReflowMode >= 0 )
        {
            _reflowViewController.reflowMode = currentReflowMode;
        }
        
        _reflowViewController.turnPageOnTap = YES;
        
        _reflowViewController.scrollingDirection = [self reflowScrollingDirectionForPagePresentationMode:viewSettings.pagePresentationMode];
        
        self.reflowHidden = NO;
    } else {
        self.reflowHidden = YES;
    }
}

#pragma mark - PTToolsSettingsManager Observers

-(void)toolManagerSettingDidChange:(PTKeyValueObservedChange*)change
{
    [self.toolManager setValue:change.newValue forKey:change.keyPath];
}

-(void)documentViewControllerSettingDidChange:(PTKeyValueObservedChange*)change
{
    [self setValue:change.newValue forKey:change.keyPath];
}

-(void)toolsSettingsDidChange:(PTKeyValueObservedChange*)change
{
    if ([change.keyPath isEqualToString:PT_CLASS_KEY(PTToolsSettingsManager, javascriptEnabled)])
    {
        [PTPDFNet EnableJavaScript:[change.newValue boolValue]];
    }
    else if ([change.keyPath isEqualToString:PT_CLASS_KEY(PTToolsSettingsManager, colorManagementEnabled)])
    {
        NSString* path = [[NSBundle bundleForClass:[PTPDFNet class]] pathForResource:@"cmyk" ofType:@"icc"];
        if( path && [change.newValue boolValue] )
        {
            [PTPDFNet SetColorManagement:e_ptlcms];
            [PTPDFNet SetDefaultDeviceCMYKProfile:path];
        }
        else
        {
            [PTPDFNet SetColorManagement:e_ptno_cms];
        }
    }
    else if([change.keyPath isEqualToString:PT_CLASS_KEY(PTToolsSettingsManager, applePencilDrawsInk)])
    {
        if( [change.newValue boolValue] )
        {
            _toolManager.pencilTool = [PTFreeHandCreate class];
            if (@available(iOS 13.1, *) ) {
                if( self.toolManager.freehandUsesPencilKit )
                {
                     _toolManager.pencilTool = [PTPencilDrawingCreate class];
                }
            }
        }
        else
        {
            _toolManager.pencilTool = Nil;
        }
    }
    else if([change.keyPath isEqualToString:PT_CLASS_KEY(PTToolsSettingsManager, freehandUsesPencilKit)])
    {
        
        if (@available(iOS 13.1, *)) {
            self.toolManager.freehandUsesPencilKit = [change.newValue boolValue];
        }
        
        if( PTToolsSettingsManager.sharedManager.applePencilDrawsInk )
        {
            _toolManager.pencilTool = [PTFreeHandCreate class];
            if (@available(iOS 13.1, *) ) {
                if( self.toolManager.freehandUsesPencilKit )
                {
                     _toolManager.pencilTool = [PTPencilDrawingCreate class];
                }
            }
        }
        else
        {
            _toolManager.pencilTool = Nil;
        }
    }
}

#pragma mark - Component Configuration

- (void)setPageFitsBetweenBars:(BOOL)pageFitsBetweenBars
{
    _pageFitsBetweenBars = pageFitsBetweenBars;
    
    [self PT_updateEdgesForExtendedLayout];
    
    // Avoid accessing the thumbnailSliderController property until the view has been loaded.
    if ([self isViewLoaded]) {
        self.thumbnailSliderController.toolbar.translucent = !pageFitsBetweenBars;
    }
}

- (void)PT_updateEdgesForExtendedLayout
{
    UIRectEdge edgesForExtendedLayout = self.edgesForExtendedLayout;
    if (self.pageFitsBetweenBars) {
        PT_BITMASK_CLEAR(edgesForExtendedLayout, UIRectEdgeTop);
        PT_BITMASK_CLEAR(edgesForExtendedLayout, UIRectEdgeBottom);
    } else {
        PT_BITMASK_SET(edgesForExtendedLayout, UIRectEdgeTop);
        PT_BITMASK_SET(edgesForExtendedLayout, UIRectEdgeBottom);
    }
    self.edgesForExtendedLayout = edgesForExtendedLayout;
}

- (BOOL)isNightModeEnabled
{
    PTColorPostProcessMode currentMode = [self.pdfViewCtrl GetColorPostProcessMode];
    return (currentMode == e_ptpostprocess_night_mode);
}

- (void)setNightModeEnabled:(BOOL)enabled
{
    if ([self isNightModeEnabled] == enabled) {
        // No change.
        return;
    }
    
    PTColorPostProcessMode colorPostProcessMode = (enabled) ? e_ptpostprocess_night_mode : e_ptpostprocess_none;
    [self.pdfViewCtrl SetColorPostProcessMode:colorPostProcessMode];
    
    // (Night mode does not yet support progressive rendering)
    [self.pdfViewCtrl SetProgressiveRendering:!enabled withInitialDelay:0 withInterval:750];
    [self.pdfViewCtrl Update:YES];
}

- (BOOL)isBottomToolbarEnabled
{
    return [self isThumbnailSliderEnabled];
}

- (void)setBottomToolbarEnabled:(BOOL)enabled
{
    [self setThumbnailSliderEnabled:enabled];
}

- (void)setThumbnailSliderEnabled:(BOOL)enabled
{
    if (enabled == _thumbnailSliderEnabled) {
        // No change.
        return;
    }
    
    _thumbnailSliderEnabled = enabled;
    
    if (enabled) {
        // Only show thumbnail slider when permitted.
        if ([self shouldShowThumbnailSlider]) {
            [self showThumbnailSliderAnimated:NO];
        }
    } else {
        [self hideThumbnailSliderAnimated:NO];
    }
}

-(BOOL)isViewControllerInNavigationLists:(UIViewController*)viewController
{
    return [self.navigationListsViewController.listViewControllers containsObject:viewController];
}


// property implementations

-(BOOL)isAnnotationListHidden
{
    return [self isViewControllerInNavigationLists:self.navigationListsViewController.annotationViewController] == NO;
}

-(void)setAnnotationListHidden:(BOOL)annotationListHidden
{
    BOOL annotationListCurrentlyHidden = [self isAnnotationListHidden];
    
    if( annotationListHidden == annotationListCurrentlyHidden )
        return;
    
    UIViewController *listViewController = self.navigationListsViewController.annotationViewController;
    
    if( annotationListHidden == NO )
    {
        // add default annotation list
        [self.navigationListsViewController addListViewController:listViewController];
        
    }
    else
    {
        // remove default annotation list
        [self.navigationListsViewController removeListViewController:listViewController];
        
    }
}

-(BOOL)isOutlineListHidden
{
    return [self isViewControllerInNavigationLists:self.navigationListsViewController.outlineViewController] == NO;
}

-(void)setOutlineListHidden:(BOOL)outlineListHidden
{
    BOOL outlineListCurrentlyHidden = [self isOutlineListHidden];
    
    if( outlineListCurrentlyHidden == outlineListHidden )
        return;
    
    UIViewController *listViewController = self.navigationListsViewController.outlineViewController;
    
    if( outlineListHidden == NO)
    {
        // add default outline list
        [self.navigationListsViewController addListViewController:listViewController];
    }
    else
    {
        // remove default outline list
        [self.navigationListsViewController removeListViewController:listViewController];
    }
}

-(BOOL)isBookmarkListHidden
{
    return [self isViewControllerInNavigationLists:self.navigationListsViewController.bookmarkViewController] == NO;
}

-(void)setBookmarkListHidden:(BOOL)bookmarkListHidden
{
    BOOL bookmarkListCurrentlyHidden = [self isBookmarkListHidden];
    
    if( bookmarkListCurrentlyHidden == bookmarkListHidden )
        return;
    
    UIViewController *listViewController = self.navigationListsViewController.bookmarkViewController;
    
    if( bookmarkListHidden == NO)
    {
        // add default bookmark list
        [self.navigationListsViewController addListViewController:listViewController];
    }
    else
    {
        // remove default bookmark list
        [self.navigationListsViewController removeListViewController:listViewController];
    }
}

-(BOOL)isPDFLayerListHidden
{
    return [self isViewControllerInNavigationLists:self.navigationListsViewController.pdfLayerViewController] == NO;
}

-(void)setPdfLayerListHidden:(BOOL)pdfLayerListHidden
{
    BOOL pdfLayerListCurrentlyHidden = [self isPDFLayerListHidden];

    if( pdfLayerListCurrentlyHidden == pdfLayerListHidden )
        return;
    
    UIViewController *listViewController = self.navigationListsViewController.pdfLayerViewController;

    if( pdfLayerListHidden == NO)
    {
        // add default PDF layer list
        [self.navigationListsViewController addListViewController:listViewController];
    }
    else
    {
        // remove default PDF layer list
        [self.navigationListsViewController removeListViewController:listViewController];
    }
}

#pragma mark - UIViewController lifecycle

// NOTE: Do not call super implementation.
- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight);
    
    [self loadPanelViewController];
    
    [self loadPDFViewCtrl];
    
    [self loadActivityIndicator];
    
    [self loadThumbnailSlider];
    
    [self loadPageIndicator];        
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Apply pageFitsBetweenBars.
    [self PT_updateEdgesForExtendedLayout];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateNavigationListsButtonItemImage];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateItems:NO];
    [self updateNavigationListsButtonItemImage];
}

- (void)loadPanelViewController
{
    self.panelViewController = [[PTPanelViewController alloc] init];
    self.panelViewController.delegate = self;
    
    [self addChildViewController:self.panelViewController];
    
    [self.view addSubview:self.panelViewController.view];
     
    [self.panelViewController didMoveToParentViewController:self];
    
    self.needsPanelConstraintsUpdate = YES;
}

- (void)loadPDFViewCtrl
{
    PTPDFViewCtrlViewController *viewController = [[PTPDFViewCtrlViewController alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
    
    self.pdfViewCtrl.frame = self.view.bounds;
    self.pdfViewCtrl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.panelViewController.contentViewController = viewController;
}

- (void)loadActivityIndicator
{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [self.view addSubview:self.activityIndicator];
    UILabel* label = [[UILabel alloc] init];
    label.text = PTLocalizedString(@"Opening PDF...", @"Converting to PDF or downloading a PDF");
    label.textColor = UIColor.darkTextColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.activityIndicator addSubview:label];
    
    // Auto Layout.
    {
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
           [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
           [label.centerXAnchor constraintEqualToAnchor:self.activityIndicator.centerXAnchor],
           [label.topAnchor constraintEqualToAnchor:self.activityIndicator.bottomAnchor constant:10.0f ]
           ]];
    }
    
    // Hidden by default.
    self.activityIndicatorHidden = YES;
}

- (void)loadThumbnailSlider
{
    self.thumbnailSliderController = [[PTThumbnailSliderViewController allocOverridden] initWithToolManager:self.toolManager];
    self.thumbnailSliderController.delegate = self;
    
    [self addChildViewController:self.thumbnailSliderController];
    
    [self.view addSubview:self.thumbnailSliderController.view];

    // Auto Layout.
    {
        self.thumbnailSliderController.view.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Create and activate constraints between the child view controller and its container (this).
        if (@available(iOS 11.0, *)) {
            self.thumbnailSliderOnscreenConstraint = [self.thumbnailSliderController.view.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
                        
        } else {
            self.thumbnailSliderOnscreenConstraint = [self.thumbnailSliderController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
        }
        
        self.thumbnailSliderOffscreenConstraint = [self.thumbnailSliderController.view.topAnchor constraintEqualToAnchor:self.view.bottomAnchor];
                
        NSLayoutConstraint *defaultVisibilityConstraint = nil;
        if ([self isThumbnailSliderEnabled] && ![self isThumbnailSliderHidden]) {
            defaultVisibilityConstraint = self.thumbnailSliderOnscreenConstraint;
        } else {
            defaultVisibilityConstraint = self.thumbnailSliderOffscreenConstraint;
        }
        
        [NSLayoutConstraint activateConstraints:@[
            [self.thumbnailSliderController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.thumbnailSliderController.view.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
            defaultVisibilityConstraint,
        ]];
    }
    
    [self.thumbnailSliderController didMoveToParentViewController:self];
    
    //self.thumbnailSliderController.leadingToolbarItem = self.navigationListsButtonItem;
    //self.thumbnailSliderController.trailingToolbarItem = self.thumbnailsButtonItem;
    
    self.thumbnailSliderController.contentView = self.thumbnailSliderController.thumbnailSliderView;
    
    self.thumbnailSliderController.toolbar.translucent = !self.pageFitsBetweenBars;
}

-(void)PT_pagePresentationDidChangeWithNotification:(NSNotification *)notification
{
//    [self loadDocumentSlider];
}

- (void)loadPageIndicator
{
    self.pageIndicatorViewController = [[PTPageIndicatorViewController allocOverridden] initWithToolManager:self.toolManager];
    
    [self addChildViewController:self.pageIndicatorViewController];
    
    [self.view addSubview:self.pageIndicatorViewController.view];
    
    [self.pageIndicatorViewController didMoveToParentViewController:self];
    
    self.pageIndicatorViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *pageIndicatorView = self.pageIndicatorViewController.view;

    const CGFloat horizontalSpacing = 10.0;
    const CGFloat verticalSpacing = 8.0;
    
    [NSLayoutConstraint activateConstraints:@[
        [pageIndicatorView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.panelViewController.contentViewController.view.leadingAnchor
                                                                     constant:horizontalSpacing],
        
        [pageIndicatorView.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.layoutMarginsGuide.topAnchor
                                                                                     constant:verticalSpacing],
        /* Use intrinsic PTPageIndicatorViewController width. */
        /* Use intrinsic PTPageIndicatorViewController height. */
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [pageIndicatorView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
    ] withPriority:UILayoutPriorityDefaultHigh];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        // Optional constraint anchoring page indicator to the view's top.
        // Required for an unambiguous layout.
        [pageIndicatorView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
    ] withPriority:UILayoutPriorityDefaultLow];
    
    self.pageIndicatorViewController.view.hidden = [self isPageIndicatorHidden];
}

#pragma mark - Constraints

- (void)loadViewConstraints
{
    
}

- (void)updatePanelConstraints
{
    if (self.panelConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.panelConstraints];
        self.panelConstraints = nil;
    }
    
    UIView *panelView = self.panelViewController.view;
    panelView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.panelConstraints = @[
        [panelView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [panelView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [panelView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ];

    // Bottom edge constraint.
    if ([self.thumbnailSliderController.toolbar isTranslucent] || self.extendedLayoutIncludesOpaqueBars) {
        self.panelConstraints = [self.panelConstraints arrayByAddingObjectsFromArray:@[
            [panelView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
    } else {
        self.panelConstraints = [self.panelConstraints arrayByAddingObjectsFromArray:@[
            [panelView.bottomAnchor constraintEqualToAnchor:self.thumbnailSliderController.toolbar.topAnchor],
        ]];
    }
    
    [NSLayoutConstraint activateConstraints:self.panelConstraints];
}

- (void)updateViewConstraints
{
    if (!self.constraintsLoaded) {
        self.constraintsLoaded = YES;
        
        [self loadViewConstraints];
    }
    
    if (self.needsPanelConstraintsUpdate) {
        self.needsPanelConstraintsUpdate = NO;

        [self updatePanelConstraints];
    }
    
    // Call super implementation as final step.
    [super updateViewConstraints];
}

- (void)setNeedsPanelConstraintsUpdate:(BOOL)needsUpdate
{
    _needsPanelConstraintsUpdate = needsUpdate;
    
    if (needsUpdate) {
        [self.view setNeedsUpdateConstraints];
    }
}

- (void)unlockDocument
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:PTLocalizedString(@"Document is Encrypted", @"")
                                          message:PTLocalizedString(@"Please enter the password to view the document", @"")
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Cancel", @"")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
        //close tab?
        //add view?
        [self stopAutomaticControlHidingTimer];
    }];
    
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK", @"")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        NSString* newPassword = alertController.textFields.firstObject.text;
        self.documentPassword = newPassword;

        @try {
            self.documentIsPasswordLocked = ![self.coordinatedDocument.pdfDoc InitStdSecurityHandler:self.documentPassword];
        }
        @catch (NSException *exception) {
            PTLog(@"Exception: %@ reason: %@", exception.name, exception.reason);
            self.documentIsPasswordLocked = NO;
        }
        if( self.documentIsPasswordLocked == NO )
        {
            [self PT_setPDFDoc:self.coordinatedDocument.pdfDoc error:nil];
            [self restartAutomaticControlHidingTimerIfNeeded];
        }
        else {
            [self unlockDocument];
        }
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:addAction];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
         textField.placeholder = PTLocalizedString(@"Password", @"Encrypted document password");
         textField.secureTextEntry = YES;
     }];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (@available(iOS 11.0, *)) {
        [self updateChildViewControllerAdditionalSafeAreaInsets];
    }
}

- (void)updateChildViewControllerAdditionalSafeAreaInsets
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
        
    if (![self isThumbnailSliderHidden]) {
        insets.bottom = CGRectGetHeight(self.thumbnailSliderController.view.bounds);
    }
    
    if (![self isPageIndicatorHidden]) {
        CGRect viewBounds = self.view.bounds;
        const CGRect pageIndicatorFrame = self.pageIndicatorViewController.view.frame;
        
        if (@available(iOS 11.0, *)) {
            viewBounds = UIEdgeInsetsInsetRect(viewBounds, self.view.safeAreaInsets);
        }
        
        CGRect viewBoundsTopHalf = CGRectZero;
        CGRect viewBoundsBottomHalf = CGRectZero;
        
        // Split bounds into top and bottom halves.
        CGRectDivide(viewBounds, &viewBoundsTopHalf, &viewBoundsBottomHalf,
                     CGRectGetHeight(viewBounds) / 2, CGRectMinYEdge);
        
        // Adjust insets for page indicator in top or bottom half of view bounds.
        if (CGRectIntersectsRect(viewBoundsTopHalf, pageIndicatorFrame)) {
            const CGFloat pageIndicatorOffset = CGRectGetMaxY(pageIndicatorFrame) - CGRectGetMinY(viewBounds);
            
            insets.top = fmax(insets.top, pageIndicatorOffset);
        }
        else if (CGRectIntersectsRect(viewBoundsBottomHalf, pageIndicatorFrame)) {
            const CGFloat pageIndicatorOffset = CGRectGetMaxY(viewBounds) - CGRectGetMinY(pageIndicatorFrame);
            
            insets.bottom = fmax(insets.bottom, pageIndicatorOffset);
        }
    }
    
    if (!UIEdgeInsetsEqualToEdgeInsets(self.childViewControllerAdditionalSafeAreaInsets, insets)) {
        self.childViewControllerAdditionalSafeAreaInsets = insets;
    }
}

- (void)setChildViewControllerAdditionalSafeAreaInsets:(UIEdgeInsets)insets
{
    _childViewControllerAdditionalSafeAreaInsets = insets;
    
    if ([self.thumbnailSliderController.toolbar isTranslucent] || self.extendedLayoutIncludesOpaqueBars) {
        self.panelViewController.additionalPanelSafeAreaInsets = insets;
    }
    
    if (@available(iOS 11.0, *)) {
        self.reflowViewController.additionalSafeAreaInsets = insets;
    }
}

- (NSUInteger)maximumItemCount
{
    // The "standard" width for an image button item.
    const CGFloat standardItemWidth = 50;

    NSArray<UIBarButtonItem *> *leftBarButtonItems = self.navigationItem.leftBarButtonItems;
    CGFloat availableWidth = CGRectGetWidth(self.view.bounds);
    if (self.navigationController) {
        leftBarButtonItems = self.navigationController.navigationBar.topItem.leftBarButtonItems;
        availableWidth = CGRectGetWidth(self.navigationController.navigationBar.bounds);
    }
    
    // Calculate the total width of the left bar button items.
    CGFloat leftBarButtonItemsWidth = 0;
    for (UIBarButtonItem *item in leftBarButtonItems) {
        if (item.customView) {
            // Use customView's frame width.
            leftBarButtonItemsWidth += CGRectGetWidth(item.customView.frame);
        }
        else if (item.image) {
            // Use the "standard" width for an image button item.
            leftBarButtonItemsWidth += standardItemWidth;
        }
        else {
            // Use the title's width, at the standard font & size.
            NSString *title = item.title;
            CGSize titleSize = [title sizeWithAttributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:UIFont.systemFontSize],
            }];
            leftBarButtonItemsWidth += titleSize.width + (10 * 2);
        }
    }
    
    availableWidth = fmax(0, availableWidth - leftBarButtonItemsWidth);
    
    return (NSUInteger)(availableWidth / standardItemWidth);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reset UIAppearance properties when this view controller will be re-added to the window
    // (primarily when dismissing a fullscreen "share dialog").
    // This must be done before the view controller's view moves to the window in order for the
    // UIAppearance properties to be applied correctly.
    if (self.documentInteraction) {
        [self.documentInteraction pt_cleanupFromPresentation];
    }
    
    // Start with pan tool.
//    [self.toolManager changeTool:[PTPanTool class]];
    
    [self restartAutomaticDocumentSavingTimer];
    
    if (self.controlsHidden) {
        [self setControlsHidden:NO animated:NO];
    }
    self.prefersStatusBarHidden = self.controlsHidden;
        
    [self updateItems:NO];
    [self updateNavigationListsButtonItemImage];
            
    // Notifications.
    [self subscribeToApplicationNotifications];
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(PT_pagePresentationDidChangeWithNotification:)
                   name:PTPDFViewCtrlPagePresentationModeDidChangeNotification
                 object:self.pdfViewCtrl];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.documentTabItem.lastAccessedDate = [NSDate date];
    
    [self restartAutomaticControlHidingTimerIfNeeded];
    
    // Present unlock UI if necessary.
    if (self.documentIsPasswordLocked) {
        [self unlockDocument];
    }
    
    ((PTSelectableBarButtonItem*)self.readerModeButtonItem).selected = self.reflowViewController.parentViewController != nil;
    
    [self becomeFirstResponder];
    
    #if TARGET_OS_MACCATALYST
    [[UIMenuSystem mainSystem] setNeedsRebuild];
    if (self.navigationController) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
    #endif
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self.presentedViewController.presentationController isKindOfClass:[PTHalfModalPresentationController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:animated completion:nil];
    }
    
    // Notifications.
    [self unsubscribeFromApplicationNotifications];
    
    [self stopAutomaticControlHidingTimer];
    
    if ([self.toolManager.tool isKindOfClass:[PTRichMediaTool class]]) {
        [self.toolManager changeTool:[PTPanTool class]];
    }
    
    [self.pdfViewCtrl CancelAllThumbRequests];
    [self.pdfViewCtrl CancelRendering];
    
    // Record what page this document is on.
    NSString *filePath = self.documentURL.path ?: self.coordinatedDocument.fileURL.path;
    if (self.document && filePath) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [PTDocumentViewSettingsManager.sharedManager setLastReadPageNumber:self.pdfViewCtrl.currentPage
                                                          forDocumentAtURL:fileURL];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
        
    [self stopAutomaticDocumentSavingTimer];
    
    if (self.automaticallySavesDocument) {
        // Auto-save (but not close) the document.
        
        if ([self.toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
            [self.toolManager.tool performSelector:@selector(commitAnnotation)];
        }
        
        [self saveDocument:e_ptincremental completionHandler:^(BOOL success) {
            // retain self so that we don't die during save
            (void)self;
        }];
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:PTDocumentViewControllerDidDissapearNotification
                                                      object:self
                                                    userInfo:nil];
    
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    
    if (!parent) {
        // Being removed from parent view controller.
        [self stopAutomaticControlHidingTimer];
    }
    
    PTTabbedDocumentViewController *tabbedDocumentViewController = self.tabbedDocumentViewController;
    
    if ([parent isKindOfClass:[PTTabbedDocumentViewController class]]
        || tabbedDocumentViewController) {
        // Derived property tabbedDocumentViewController property will change.
        [self willChangeValueForKey:PT_SELF_KEY(tabbedDocumentViewController)];
        
        if (tabbedDocumentViewController) {
            [self pt_removeObservationsForObject:tabbedDocumentViewController
                                         keyPath:PT_KEY(tabbedDocumentViewController, tabsEnabled)];
        }
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    if ([parent isKindOfClass:[PTTabbedDocumentViewController class]]) {
        // Derived property tabbedDocumentViewController property did change.
        [self didChangeValueForKey:PT_SELF_KEY(tabbedDocumentViewController)];
        
        PTTabbedDocumentViewController *tabbedDocumentViewController = (PTTabbedDocumentViewController *)parent;
        
        [self pt_observeObject:tabbedDocumentViewController
                    forKeyPath:PT_KEY(tabbedDocumentViewController, tabsEnabled)
                      selector:@selector(tabbedDocumentViewControllerTabsEnabledDidChange:)];
    }
}

- (PTTabbedDocumentViewController *)tabbedDocumentViewController
{
    if ([self.parentViewController isKindOfClass:[PTTabbedDocumentViewController class]]) {
        return (PTTabbedDocumentViewController *)self.parentViewController;
    }
    return nil;
}

- (void)tabbedDocumentViewControllerTabsEnabledDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.tabbedDocumentViewController) {
        return;
    }
    
    [self updateItems:YES];
}

#pragma mark - Navigation item

@synthesize navigationItem = _navigationItem;

- (PTForwardingNavigationItem *)navigationItem
{
    if (!_navigationItem) {
        _navigationItem = [[PTForwardingNavigationItem alloc] init];
        _navigationItem.traitCollection = self.traitCollection;
    }
    
    [self loadItemsIfNeeded];
    
    return _navigationItem;
}

- (void)loadItemsIfNeeded
{
    if (!self.itemsLoaded) {
        self.itemsLoaded = YES;
        
        self.loadingItems = YES;
        [self loadItems];
        self.loadingItems = NO;
    }
}

- (void)loadItems
{
    
}

#pragma mark - Updating items

- (void)updateItems:(BOOL)animated
{
    [self updateItemsForTraitCollection:self.traitCollection animated:animated];
}

- (void)updateItemsForTraitCollection:(UITraitCollection *)traitCollection animated:(BOOL)animated
{
    // NOTE: It is necessary to update the navigation item *before* the toolbar items,
    // otherwise the toolbar items can become invisible (views not added to the toolbar)
    // because they are still displayed in the navigation bar.
    self.navigationItem.traitCollection = traitCollection;
    
    [self updateToolbarItemsForTraitCollection:traitCollection animated:animated];
    [self updateMoreItemsForTraitCollection:traitCollection animated:animated];
}

#pragma mark - Toolbar items

@dynamic toolbarItems;

- (NSArray<__kindof UIBarButtonItem *> *)toolbarItems
{
    [self loadItemsIfNeeded];
    
    return [super toolbarItems];
}

- (void)setToolbarItems:(NSArray<UIBarButtonItem *> *)toolbarItems animated:(BOOL)animated
{
    if (![self isUpdatingToolbarItems]) {
        // The toolbar items are being set explicitly.
        // Set items for all size classes.
        [self PT_setToolbarItems:toolbarItems
                    forSizeClass:UIUserInterfaceSizeClassCompact];
        [self PT_setToolbarItems:toolbarItems
                    forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    
    [super setToolbarItems:toolbarItems animated:animated];
    
    // Forward toolbar items to parent view controller.
    if (self.parentViewController &&
        (self.navigationItem.forwardingTargetItem == self.parentViewController.navigationItem)) {
        [self.parentViewController setToolbarItems:toolbarItems
                                          animated:animated];
    }
}

- (NSArray<UIBarButtonItem *> *)toolbarItemsForSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    [self loadItemsIfNeeded];
    
    return self.adaptiveToolbarItems[@(sizeClass)];
}

- (void)setToolbarItems:(NSArray<UIBarButtonItem *> *)toolbarItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass animated:(BOOL)animated
{
    if (sizeClass == UIUserInterfaceSizeClassUnspecified) {
        return;
    }
    
    const BOOL wasUpdatingToolbarItems = [self isUpdatingToolbarItems];
    self.updatingToolbarItems = YES;
    
    NSArray<UIBarButtonItem *> *items = [toolbarItems copy];
    [self PT_setToolbarItems:items forSizeClass:sizeClass];
    
    if (sizeClass == self.traitCollection.horizontalSizeClass) {
        [self setToolbarItems:items animated:animated];
    }
    
    self.updatingToolbarItems = wasUpdatingToolbarItems;
}

- (void)PT_setToolbarItems:(NSArray<UIBarButtonItem *> *)toolbarItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    if (toolbarItems) {
        self.adaptiveToolbarItems[@(sizeClass)] = toolbarItems;
    } else {
        [self.adaptiveToolbarItems removeObjectForKey:@(sizeClass)];
    }
}

#pragma mark Updating

- (void)updateToolbarItems:(BOOL)animated
{
    [self updateToolbarItemsForTraitCollection:self.traitCollection
                                      animated:animated];
}

- (void)updateToolbarItemsForTraitCollection:(UITraitCollection *)traitCollection animated:(BOOL)animated
{
    const BOOL wasUpdatingToolbarItems = [self isUpdatingToolbarItems];
    self.updatingToolbarItems = YES;
    
    const UIUserInterfaceSizeClass sizeClass = traitCollection.horizontalSizeClass;
    
    // Toolbar items.
    NSArray<UIBarButtonItem *> *toolbarItems = [self toolbarItemsForSizeClass:sizeClass];
    
    // Hide toolbar when empty.
    // NOTE: Must be done before setting the toolbarItems, otherwise the hidden
    // toolbar (with zero size) will break the items' internal Auto Layout constraints.
    const BOOL toolbarHidden = (toolbarItems.count == 0);
    [self.navigationController setToolbarHidden:toolbarHidden
                                       animated:animated];
    
    [self setToolbarItems:[toolbarItems copy]
                 animated:animated];
    
    self.updatingToolbarItems = wasUpdatingToolbarItems;
}

#pragma mark - More items

@synthesize moreItems = _moreItems;

- (NSArray<UIBarButtonItem *> *)moreItems
{
    [self loadItemsIfNeeded];
    
    return _moreItems;
}

- (void)setMoreItems:(NSArray<UIBarButtonItem *> *)moreItems
{
    NSArray<UIBarButtonItem *> *items = [moreItems copy];
    
    if (![self isUpdatingMoreItems]) {
        // The more items are being set explicitly.
        // Set items for all size classes.
        [self PT_setMoreItems:items
                 forSizeClass:UIUserInterfaceSizeClassCompact];
        [self PT_setMoreItems:items
                 forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    if (@available(iOS 14.0, *)) {
        NSMutableArray<UIMenuElement*> *menuElements = [NSMutableArray array];
        for (UIBarButtonItem *item in items) {
            UIAction *menuAction = [UIAction actionWithTitle:item.title image:item.image identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                [UIApplication.sharedApplication sendAction:item.action to:item.target from:self.moreItemsButtonItem forEvent:nil];
            }];
            [menuElements addObject:menuAction];
        }
        self.moreItemsButtonItem.menu = [UIMenu menuWithChildren:menuElements];
    }
    _moreItems = items;
}

- (NSArray<UIBarButtonItem *> *)moreItemsForSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    [self loadItemsIfNeeded];
    
    return self.adaptiveMoreItems[@(sizeClass)];
}

- (void)setMoreItems:(NSArray<UIBarButtonItem *> *)moreItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    if (sizeClass == UIUserInterfaceSizeClassUnspecified) {
        return;
    }
    
    const BOOL wasUpdatingMoreItems = [self isUpdatingMoreItems];
    self.updatingMoreItems = YES;
    
    NSArray<UIBarButtonItem *> *items = [moreItems copy];
    [self PT_setMoreItems:items forSizeClass:sizeClass];
    
    if (sizeClass == self.traitCollection.horizontalSizeClass) {
        [self setMoreItems:items];
    }
    
    self.updatingMoreItems = wasUpdatingMoreItems;
}

- (void)PT_setMoreItems:(NSArray<UIBarButtonItem *> *)moreItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    if (moreItems) {
        self.adaptiveMoreItems[@(sizeClass)] = moreItems;
    } else {
        [self.adaptiveMoreItems removeObjectForKey:@(sizeClass)];
    }
}

#pragma mark Updating

- (void)updateMoreItems:(BOOL)animated
{
    [self updateMoreItemsForTraitCollection:self.traitCollection animated:animated];
}

- (void)updateMoreItemsForTraitCollection:(UITraitCollection *)traitCollection animated:(BOOL)animated
{
    const BOOL wasUpdatingMoreItems = [self isUpdatingMoreItems];
    self.updatingMoreItems = YES;
    
    const UIUserInterfaceSizeClass sizeClass = traitCollection.horizontalSizeClass;

    NSArray<UIBarButtonItem *> *moreItems = [self moreItemsForSizeClass:sizeClass];
    
    [self setMoreItems:moreItems];
    
    self.updatingMoreItems = wasUpdatingMoreItems;
}

#pragma mark - View controller presentation

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    [self hideViewControllersWithCompletion:^{
        if ([viewControllerToPresent isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navVC = (UINavigationController*)viewControllerToPresent;
            if ([navVC.topViewController conformsToProtocol:@protocol(PTToolManagerViewControllerPresentation)]) {
                UIViewController<PTToolManagerViewControllerPresentation> *topViewController = (UIViewController<PTToolManagerViewControllerPresentation> *)navVC.topViewController;
                if ([topViewController respondsToSelector:@selector(prefersNavigationBarHidden)]){
                    if ([topViewController prefersNavigationBarHidden]){
                        [self setControlsHidden:YES animated:flag];
                    }
                }
            }
            if ([navVC.topViewController isKindOfClass:[PTTextSearchViewController class]]) {
                PTTextSearchViewController *searchController = (PTTextSearchViewController *)navVC.topViewController;
                if (!searchController.delegate) {
                    searchController.delegate = self;
                }
            }
        }
        [super presentViewController:viewControllerToPresent animated:flag completion:completion];
    }];
}

#pragma mark - UIApplication notifications

- (void)subscribeToApplicationNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(PT_applicationWillEnterForeground:)
                   name:UIApplicationWillEnterForegroundNotification
                 object:UIApplication.sharedApplication];
    
    [center addObserver:self
               selector:@selector(PT_applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:UIApplication.sharedApplication];
    
    [center addObserver:self
               selector:@selector(PT_applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:UIApplication.sharedApplication];
    
    [center addObserver:self
               selector:@selector(PT_applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification object:UIApplication.sharedApplication];
}

- (void)unsubscribeFromApplicationNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center removeObserver:self
                      name:UIApplicationWillEnterForegroundNotification
                    object:UIApplication.sharedApplication];
    
    [center removeObserver:self
                      name:UIApplicationWillResignActiveNotification
                    object:UIApplication.sharedApplication];
    
    [center removeObserver:self
                      name:UIApplicationDidEnterBackgroundNotification
                    object:UIApplication.sharedApplication];
    
    [center removeObserver:self
                      name:UIApplicationDidBecomeActiveNotification
                    object:UIApplication.sharedApplication];
}

#pragma mark - undoManager

- (NSUndoManager *)undoManager
{
    // Use the tool manager's undo manager (which tracks document level undo/redo-able actions).
    // NOTE: The tool manager is not part of the responder chain so its undo manager would not be
    // used otherwise.
    return self.toolManager.undoManager;
}

#pragma mark - PTPDFViewCtrlDelegate callbacks

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl gotThumbAsync:(int)page_num thumbImage:(UIImage *)image
{
    if (!image) { return; }
    if (self.thumbnailsViewController && self.thumbnailsViewController.presentingViewController) {
        [self.thumbnailsViewController setThumbnail:image forPage:page_num];
    }
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidScroll:(UIScrollView *)scrollView
{
    [self restartAutomaticControlHidingTimerIfNeeded];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidScroll:(UIScrollView *)scrollView
{
    [self restartAutomaticControlHidingTimerIfNeeded];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
    if (newPageNumber == 0) {
        return;
    }
    
    // Show indicator if allowed.
    if (self.pageIndicatorShowsOnPageChange) {
        [self setPageIndicatorHidden:NO animated:YES];
    }
    
    [self restartAutomaticControlHidingTimerIfNeeded];
    
//    NSString *filePath = self.documentUrl.path;
//
//    if( filePath == nil)
//    {
//        filePath = self.coordinatedDocument.fileURL.path;
//    }
    
//    // Record what page this document is on
//    if(self.document && filePath && oldPageNumber != newPageNumber)
//    {
//        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
//        [PTDocumentViewSettingsManager.sharedManager setLastReadPageNumber:newPageNumber
//                                                          forDocumentAtURL:fileURL];
//    }
    [self startLastPageReadTimer];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewTap:(UITapGestureRecognizer *)gestureRecognizer
{
 
    
    BOOL shouldToggleControls = NO;
    
    if (self.document)
    {
        // if the menu is on screen, then they are (probably) trying to dismiss it, so don't process the tap
        if( [UIMenuController.sharedMenuController isMenuVisible] )
        {
            return;
        }
        
        PTTool *tool = self.toolManager.tool;

        // If they are not in the pan tool, or just switched to it, don't process tap.
        if (![tool isKindOfClass:[PTPanTool class]]) {
            return;
        }
        else if ([tool.previousToolType isSubclassOfClass:[PTAnnotEditTool class]]
                 || [tool.previousToolType isEqual:[PTTextMarkupEditTool class]]) {
            // Reset the previous tool type.
            tool.previousToolType = nil;
            return;
        }

        PTAnnot *annotation;

        @try {
            // If they are clicking an annotation, we don't want to process this
            [self.pdfViewCtrl DocLockRead];
            CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
            annotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:22 minimumLineWeight:10];
        }
        @catch (NSException *exception) {
            //[[AnalyticsHandler getInstance] logException:exception withExtraData:nil];
            // something is wrong with the annotation, it may not be selected properly
        }
        @finally {
            [self.pdfViewCtrl DocUnlockRead];
        }

        if ([annotation IsValid]) { return; }

        // Okay... Lets zoom or turn pages
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {

            // Determine what hot-zone we have tapped
            float x = [gestureRecognizer locationInView:self.pdfViewCtrl].x / self.pdfViewCtrl.bounds.size.width;
            BOOL allowTapTurn = (self.pdfViewCtrl.pagePresentationMode == e_trn_single_page);
            int currentPage = [self.pdfViewCtrl GetCurrentPage];
        
            // Go back page or forward a page
            if (allowTapTurn && self.changesPageOnTap) {
                if (x < 1.0f/7.0f) {
                    if (currentPage > 1) {
                        int newPage = currentPage - 1;
                        if (newPage < 1) { newPage = 1; }

                        [self.pdfViewCtrl SetCurrentPage:newPage];
                    }
                } else if (x > 6.0f/7.0f) {
                    if (currentPage < [self.document GetPageCount]) {
                        int newPage = currentPage + 1;
                        if (newPage > [self.document GetPageCount]) { newPage = [self.document GetPageCount]; }

                        [self.pdfViewCtrl SetCurrentPage:newPage];
                    }
                } else {
                    shouldToggleControls = YES;
                }
            } else {
                shouldToggleControls = YES;
            }
        }
    }
    else
    {
        shouldToggleControls = YES;
    }
    
    if (shouldToggleControls && self.hidesControlsOnTap) {
        
        // do this _after_ the tools code has a chance to process the event without changing the view positions
        dispatch_async( dispatch_get_main_queue(), ^{
            [self setControlsHidden:!self.controlsHidden animated:YES];
        });
        
        
    }

    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl textSearchResult:(PTSelection *)selection
{
    UIColor* greenish = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.30];
    
    // check if no results found
    PTVectorQuadPoint* pt = [selection GetQuads];
    if ([pt isEmpty]) {
        PTLog(@"No results found");
    }
    
    // call even if no results to clear last highlight
    [self.pdfViewCtrl highlightSelection:selection withColor:greenish];
}

- (void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl *)pdfViewCtrl
{

}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onSetDoc:(PTPDFDoc *)doc
{
    
}

- (void)pdfViewCtrlDidCloseDoc:(PTPDFViewCtrl *)pdfViewCtrl
{
    
}

#pragma mark Download

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl downloadEventType:(PTDownloadedType)type pageNumber:(int)pageNum message:(NSString*)message
{
    
    switch (type) {
        case e_ptdownloadedtype_opened:
            
            break;
        case e_ptdownloadedtype_page:
            // Hide spinner.
            self.activityIndicatorHidden = YES;
            break;
        case e_ptdownloadedtype_finished:
            // Hide spinner.
            self.activityIndicatorHidden = YES;
            
            [self handleDownloadFinished];
            break;
        case e_ptdownloadedtype_failed:
            // Hide spinner.
            self.activityIndicatorHidden = YES;
            
            [self handleDownloadFailure:message];
            break;
        default:
            // Ignore event.
            break;
    }
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl downloadError:(NSException *)exception
{
    PTLog(@"Failed to download file: %@: %@", exception.name, exception.reason);
    
    [self handleDownloadFailureWithError:exception.pt_error];
}

- (void)handleDownloadFinished
{
    // Ensure that the local document URL (location of the downloaded/converted file) is set.
    if (!self.localDocumentURL) {
        return;
    }
    
    // Check if the cached file should be copied.
    const BOOL shouldExport = [self shouldExportCachedDocumentAtURL:self.documentURL];
    if (!shouldExport) {
        // Keep using the cached file and do not export it.
        PTLog(@"Cached document at %@ will not be exported", self.localDocumentURL);
    }
    
    NSString *destinationPath;
    
    NSURL *delegateUrl = nil;
    
    if( shouldExport )
    {
        // Ask the delegate for the final destination URL of the document.
        delegateUrl = [self destinationURLforDocumentAtURL:self.documentURL];
        
        if (delegateUrl) {
            // Ensure that a file URL was provided.
            NSAssert([delegateUrl isFileURL],
                     @"Destination URL must be a file URL: \"%@\" URL scheme found", delegateUrl.scheme);
            
            BOOL success = [delegateUrl startAccessingSecurityScopedResource];
            if (!success) {
                PTLog(@"Failed to access security scoped resource with URL: %@", delegateUrl);
            }
            
            destinationPath = delegateUrl.path;
        
            
            
            
            
            if (!destinationPath) {
                // Fail with error.
                NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                                  @{
                                    NSLocalizedDescriptionKey : @"Error",
                                    NSLocalizedFailureReasonErrorKey : @"Destination path cannot be nil",
                                    NSURLErrorKey: self.documentURL,
                                    }];
                
                [self handleDownloadFailureWithError:error];
                return;
            }
            
            PTLog(@"Will save document to %@ as per delegate method.", destinationPath);
        }
        else {
            // Place the document in the Documents directory.
            NSURL *documentsDirectoryURL = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
            
            NSString *baseFilename = self.documentURL.lastPathComponent;
            if (baseFilename.length == 0) {
                baseFilename = @"Untitled";
            }
            // Ensure file has "pdf" extension.
            baseFilename = [baseFilename.stringByDeletingPathExtension stringByAppendingPathExtension:@"pdf"];
            
            destinationPath = [self getUniqueFileName:baseFilename atPath:documentsDirectoryURL.path];
        }
    }
    else
    {
        destinationPath = self.localDocumentURL.path;
        
        // if this is a streaming conversion, not exported, save to temp dir.
        if (!UTTypeConformsTo((__bridge CFStringRef)PTUTTypeForURL(self.localDocumentURL), kUTTypePDF))
        {
            NSString* tmpDir = NSTemporaryDirectory();
            
            NSString *baseFilename = self.documentURL.lastPathComponent;
            if (baseFilename.length == 0) {
                baseFilename = @"Untitled";
            }
            // Ensure file has "pdf" extension.
            baseFilename = [baseFilename.stringByDeletingPathExtension stringByAppendingPathExtension:@"pdf"];
            
            destinationPath = [self getUniqueFileName:baseFilename atPath:tmpDir];
        }
    }
    
    // Copy cached file.
    NSURL *sourceURL = self.localDocumentURL;
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
    
    BOOL saveSuccess = NO;
    __block BOOL copySuccess = NO;
    
    if( [destinationURL isEqual:sourceURL] )
    {
        NSString* newName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"pdf"];
        
        NSFileManager* manager = NSFileManager.defaultManager;
        
        if( [manager fileExistsAtPath:[destinationURL URLByDeletingPathExtension].path isDirectory:nil] == NO )
        {
            NSError* error;
            BOOL worked = [manager createDirectoryAtURL:[destinationURL URLByDeletingPathExtension] withIntermediateDirectories:NO attributes:Nil error:&error];
            
            if( !worked )
            {
                NSLog(@"Error creating directory in caches: %@", error.description);
            }
        }
        
        destinationURL = [[destinationURL URLByDeletingPathExtension] URLByAppendingPathComponent:newName];
    }
    
    BOOL shouldUnlock = NO;
    @try {
        // locally opened convertable files
        if (!UTTypeConformsTo((__bridge CFStringRef)PTUTTypeForURL(sourceURL), kUTTypePDF)) {
            
            
            // save converted PDF somewhere
            
            [self.pdfViewCtrl DocLock:YES];
            shouldUnlock = YES;

            // Save the PDFViewCtrl's current document to the destination location.
            // NOTE: This requires the PDFTron write permission, but streaming http(s) documents
            // only requires the read permission.

            // Save the non-PDF document to the destination.
            NSError *saveError = nil;
            @try {
                [[self.pdfViewCtrl GetDoc] SaveToFile:destinationURL.path flags:0];
                saveSuccess = YES;
            } @catch (NSException *exception) {
                saveSuccess = NO;
                saveError = exception.pt_error;
            }

            if (!saveSuccess) {
                // Try to copy the source (cache) file directly to the destination in the case of a save
                // failure (No PDFTron write permission, etc.).
                // This can only be done if the source file is a PDF, which will not be the case for a
                // stream-converted file.
                //if (!UTTypeConformsTo((__bridge CFStringRef)PTUTTypeForURL(sourceURL), kUTTypePDF)) {
                // Fail: source file is not a PDF document.
                NSAssert(saveError != nil,
                         @"Saving converted document to destination failed, but save error is nil");

                NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                                  @{
                                    NSLocalizedDescriptionKey: @"Failed to save converted document to destination",
                                    NSLocalizedFailureReasonErrorKey:
                                        @"The converted document could not be saved to the destination URL",
                                    NSURLErrorKey: destinationURL,
                                    // Include underlying save error.
                                    NSUnderlyingErrorKey: saveError,
                                    }];

                [self handleDownloadFailureWithError:error];
                return;
            }
        }

    } @catch (NSException *exception) {
        [self handleDownloadFailureWithError:exception.pt_error];
        return;
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
        
        
    // Save the current page number.
    int currentPage = [self.pdfViewCtrl GetCurrentPage];
    TrnPagePresentationMode presentationMode = [self.pdfViewCtrl GetPagePresentationMode];
    double hPos = [self.pdfViewCtrl GetHScrollPos];
    double vPos = [self.pdfViewCtrl GetVScrollPos];
    double scale = [self.pdfViewCtrl GetZoom];

        
    [self closeDocumentWithCompletionHandler:^(BOOL success) {
        
            if (UTTypeConformsTo((__bridge CFStringRef)PTUTTypeForURL(sourceURL), kUTTypePDF))
            {
                // copy PDF source files. Files that have been converted to PDFs have already been
                // saved to destinationURL
                NSError *fileCopyError = nil;
                copySuccess = [NSFileManager.defaultManager copyItemAtURL:sourceURL toURL:destinationURL
                                                                    error:&fileCopyError];
                if (!copySuccess) {
                    NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                                      @{
                                        NSLocalizedDescriptionKey: @"Failed to save document to destination",
                                        NSLocalizedFailureReasonErrorKey: @"The file could not be copied to the destination URL",
                                        NSURLErrorKey: destinationURL,
                                        // Include underlying copy error.
                                        NSUnderlyingErrorKey: fileCopyError,
                                        }];

                    [self handleDownloadFailureWithError:error];
                    return;
                }
            }

        // Reopen doc to ensure successful saving.

            @try {

                PTCoordinatedDocument *newCoordinatedDocument = [[PTCoordinatedDocument alloc] initWithFileURL:destinationURL];
                

                [self PT_setCoordinatedDocument:newCoordinatedDocument password:self.documentPassword completionHandler:^(NSError *error) {
                    if (error) {
                        // Close document on error.
                        [self closeDocumentWithCompletionHandler:^(BOOL success) {
                            // Handle failure.
                            [self handleDocumentOpeningFailureWithError:error];
                        }];
                        return;
                    }
                    
                    // Restore current page number.
                    [self.pdfViewCtrl SetPagePresentationMode:presentationMode];
                    [self.pdfViewCtrl SetCurrentPage:currentPage];
                    [self.pdfViewCtrl SetZoom:scale];
                    [self.pdfViewCtrl SetHScrollPos:hPos Animated:NO];
                    [self.pdfViewCtrl SetVScrollPos:vPos Animated:NO];
                    
                    self.toolManager.readonly = NO;
                    
                    // Check if the cache file should be deleted.
                    const BOOL shouldDelete = [self shouldDeleteCachedDocumentAtURL:sourceURL];
                    
                    if (shouldDelete) {
                        // Delete the cache file now that the exported copy is open.
                        NSError *deleteFileError = nil;
                        BOOL deleteSuccess = [NSFileManager.defaultManager removeItemAtURL:sourceURL error:&deleteFileError];
                        if (!deleteSuccess) {
                            PTLog(@"Failed to delete cache file at URL \"%@\": %@", sourceURL, deleteFileError);
                        }
                    }
                    
                    BOOL controlsHidden = [self controlsHidden];
                    
                    [self PT_setControlsHidden:YES animated:NO];
                    [self PT_setControlsHidden:NO animated:NO];
                    
                    if( controlsHidden )
                    {
                        [self PT_setControlsHidden:YES animated:NO];
                    }
                    
                    // Handle successful document opening.
                    [self didOpenDocument];
                    
                    [NSNotificationCenter.defaultCenter postNotificationName:PTDocumentViewControllerDidOpenDocumentNotification
                                                                      object:self
                                                                    userInfo:Nil];
                    
                }];
            } @catch (NSException *exception) {
                NSLog(@"Exception: %@: reason: %@", exception.name, exception.reason);

                [self handleDownloadFailureWithError:exception.pt_error];
                return;
            }
        
    }];
}

- (void)handleDownloadFailureWithError:(NSError *)error
{
    self.documentIsInValidState = NO;
    
    // Enter invalid state.
    [self didBecomeInvalid];
    
    [self handleDocumentOpeningFailureWithError:error];
}

- (void)handleDownloadFailure:(NSString*)message
{
    NSError *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
        NSLocalizedDescriptionKey: @"Could not download file.",
        NSLocalizedFailureReasonErrorKey: @"An unknown error has occurred.",
    }];
    
    [self handleDownloadFailureWithError:error];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl javascriptCallback:(const char *)event_type json:(const char *)json
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidZoom:(UIScrollView *)scrollView
{
    
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    return YES;
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidZoom:(UIScrollView *)scrollView
{

}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    return YES;
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    
}

- (void)pdfViewCtrlOnRenderFinished:(PTPDFViewCtrl *)pdfViewCtrl
{
    
}

- (void)pdfViewCtrlTextSearchStart:(PTPDFViewCtrl *)pdfViewCtrl
{
    
}

#pragma mark - Controls

- (PTThumbnailSliderViewController *)thumbnailSliderController
{
    [self loadViewIfNeeded];
    
    NSAssert(_thumbnailSliderController, @"Thumbnail slider was not loaded");
    
    return _thumbnailSliderController;
}

- (PTPageIndicatorViewController *)pageIndicatorViewController
{
    [self loadViewIfNeeded];
    
    NSAssert(_pageIndicatorViewController, @"Page indicator view controller was not loaded");
    
    return _pageIndicatorViewController;
}

- (PTThumbnailsViewController *)thumbnailsViewController
{
    if (!_thumbnailsViewController) {
        _thumbnailsViewController = [[PTThumbnailsViewController allocOverridden] initWithToolManager:self.toolManager];
    }
    return _thumbnailsViewController;
}

- (PTTextSearchViewController *)textSearchViewController
{
    if(!_textSearchViewController){
        _textSearchViewController = [[PTTextSearchViewController allocOverridden] initWithPDFViewCtrl:self.pdfViewCtrl];
        _textSearchViewController.delegate = self;
    }
    return _textSearchViewController;
}

- (PTNavigationListsViewController *)navigationListsViewController
{
    if (!_navigationListsViewController) {
        PTNavigationListsViewController* navigationListsViewController = [[PTNavigationListsViewController allocOverridden] initWithToolManager:self.toolManager];
        
        navigationListsViewController.annotationViewController.delegate = self;
        navigationListsViewController.outlineViewController.delegate = self;
        navigationListsViewController.bookmarkViewController.delegate = self;
        navigationListsViewController.pdfLayerViewController.delegate = self;
        
        _navigationListsViewController = navigationListsViewController;
    }
    return _navigationListsViewController;
}

- (PTDocumentViewSettingsController *)settingsViewController
{
    if (!_settingsViewController) {
        _settingsViewController = [[PTDocumentViewSettingsController allocOverridden] initWithPDFViewCtrl:self.pdfViewCtrl];
        _settingsViewController.delegate = self;
    }
    return _settingsViewController;
}

- (PTReflowViewController *)reflowViewController
{
    if (!_reflowViewController) {
        _reflowViewController = [[PTReflowViewController allocOverridden] initWithPDFViewCtrl:self.pdfViewCtrl];
        _reflowViewController.delegate = self;
        
        _reflowViewController.turnPageOnTap = YES;
    }
    return _reflowViewController;
}

- (PTMoreItemsViewController *)moreItemsViewController
{
    if(!_moreItemsViewController){
        _moreItemsViewController = [[PTMoreItemsViewController allocOverridden] initWithToolManager:self.toolManager];
        _moreItemsViewController.items = self.moreItems;
    }
    return _moreItemsViewController;
}

- (PTAddPagesViewController *)addPagesViewController
{
    if (!_addPagesViewController) {
        _addPagesViewController = [[PTAddPagesViewController allocOverridden] initWithToolManager:self.toolManager];
    }
    return _addPagesViewController;
}

- (PTPanelViewController *)panelViewController
{
    if (!_panelViewController) {
        [self loadViewIfNeeded];
        
        NSAssert(_panelViewController, @"Panel view controller was not loaded");
    }
    return _panelViewController;
}

- (void)showNavigationLists
{
    [self showBookmarks:self.navigationListsButtonItem];
}

#pragma mark - Toolbar bar button callbacks

-(void)toggleReflow
{
    self.reflowHidden = !self.reflowHidden;
    #if TARGET_OS_MACCATALYST
    [self updateSelectedToolbarItem];
    #endif
    ((PTSelectableBarButtonItem*)self.readerModeButtonItem).selected = !self.reflowHidden;
}

- (void)showSearchViewController
{
    [self showSearchView:self.searchButtonItem];
}

- (void)showShareActions: (UIBarButtonItem*)barButtonItem
{
    [self openDocumentIn:barButtonItem];
}

-(void)showAppSettings:(UIBarButtonItem*)barButtonItem
{
    UITableViewStyle tableViewStyle;
    if( @available(iOS 13, *) )
    {
        tableViewStyle = UITableViewStyleInsetGrouped;
    }
    else
    {
        tableViewStyle = UITableViewStyleGrouped;
    }
    
    PTToolsSettingsViewController* settingsVC = [[PTToolsSettingsViewController allocOverridden] initWithStyle:tableViewStyle plistName:@"PTToolsSettings.plist"];
    
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:navigationController animated:YES completion:Nil];
        
    
}

-(void)showSettings: (UIBarButtonItem*)barButtonItem
{
    //[[AnalyticsHandler getInstance] sendCustomEventWithTag:@"[General] Settings selected"];
    
    [self hideViewControllers];
    
    PTDocumentViewSettings *settings = self.settingsViewController.settings;
    settings.pagePresentationMode = self.pdfViewCtrl.pagePresentationMode;
    settings.reflowEnabled = ![self isReflowHidden];
    settings.colorPostProcessMode = self.pdfViewCtrl.colorPostProcessMode;
    settings.pageRotation = self.pdfViewCtrl.rotation;
    
    self.settingsViewController.settings = settings;
    
    UIViewController *settingsController = self.settingsViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    
    // Show as popover.
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverController = navigationController.popoverPresentationController;
    popoverController.permittedArrowDirections = (UIPopoverArrowDirectionUp |
                                                  UIPopoverArrowDirectionDown);
    popoverController.barButtonItem = barButtonItem;
    
    [self presentViewController:navigationController animated:YES completion:^{
        if ([navigationController.presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
            UIPopoverPresentationController *popoverController = navigationController.popoverPresentationController;
            popoverController.passthroughViews = nil;
        }
    }];
}

- (void)showThumbnailsController
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.thumbnailsViewController];
    
    [self hideViewControllers];
    [self presentViewController:nav animated:YES completion:nil];
    
//    if (!self.panelViewController.leadingViewController) {
//        [self.panelViewController showLeadingViewController:nav];
//    } else {
//        self.panelViewController.leadingViewController = nil;
//    }
}

- (void)showThumbnails:(id)sender
{
    [self showThumbnailsController];
}

- (void)showBookmarks:(UIBarButtonItem *)sender
{
    if ([self.panelViewController isLeadingPanelHidden]) {
        [self.panelViewController showLeadingViewController:self.navigationListsViewController
                                                   animated:YES];
    } else {
        [self.panelViewController dismissLeadingViewControllerAnimated:YES];
    }
    
    if ([self.navigationListsButtonItem isKindOfClass:[PTSelectableBarButtonItem class]]) {
        ((PTSelectableBarButtonItem *)self.navigationListsButtonItem).selected = ![self.panelViewController isLeadingPanelHidden];
    }
}

- (void)showSearchView:(UIBarButtonItem *)sender
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.textSearchViewController];
    nav.modalPresentationStyle = UIModalPresentationCustom;

    [self hideViewControllersWithCompletion:^{
        
        [self setControlsHidden:YES animated:YES];

        if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:willShowToolbar:)]) {
            [self.toolbarDelegate documentViewController:self willShowToolbar:nav.toolbar];
        }
        [self presentViewController:nav animated:NO completion:nil];
    }];
}

- (void)undo:(id)sender
{
    [self.undoManager undo];
}

- (void)redo:(id)sender
{
    [self.undoManager redo];
}

- (void)showMoreItems:(id)sender
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.moreItemsViewController];
    nav.modalPresentationStyle = UIModalPresentationPopover;
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        nav.popoverPresentationController.barButtonItem = sender;
    }
    else if ([sender isKindOfClass:[UIView class]]) {
        nav.popoverPresentationController.sourceView = sender;
    }
    nav.popoverPresentationController.delegate = self;
    
    [self presentViewController:nav animated:YES completion:^{
        if ([nav.presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
            nav.popoverPresentationController.passthroughViews = nil;
        }
    }];
}

- (void)showAddPagesView:(UIBarButtonItem *)sender
{
//    if ([self.moreItemsViewController.items containsObject:self.addPagesButtonItem] && self.moreItemsViewController.navigationController != nil) {
//        [self.moreItemsViewController.navigationController pushViewController:self.addPagesViewController animated:YES];
//    }else{
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.addPagesViewController];
        nav.modalPresentationStyle = UIModalPresentationPopover;
        nav.popoverPresentationController.barButtonItem = sender;
        nav.popoverPresentationController.delegate = self;
        [self presentViewController:nav animated:YES completion:^{
            if ([nav.presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
                UIPopoverPresentationController *popoverController = nav.popoverPresentationController;
                popoverController.passthroughViews = nil;
            }
        }];
//    }
}

- (void)showExportOptions:(UIBarButtonItem *)sender
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:PTLocalizedString(@"Export Document", @"Export Document Action Sheet Title")
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Cancel", @"Cancel alert action title")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    UIAlertAction *exportCopyAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Export a Copy", @"Export a Copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveAndExportWithFlattening:NO];
    }];
    UIAlertAction *exportFlattenedAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Export a Flattened Copy", @"Export a Flattened Copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveAndExportWithFlattening:YES];
    }];
//    UIAlertAction *exportOptimizedAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Export an Optimized Copy", @"Export an Optimized Copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [self saveAndExportOptimizedCopy];
//    }];

    [alertController addAction:cancelAction];
    [alertController addAction:exportCopyAction];
    [alertController addAction:exportFlattenedAction];
//    [alertController addAction:exportOptimizedAction];
    alertController.popoverPresentationController.barButtonItem = sender;
    [self hideViewControllersWithCompletion:^{
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}

-(void)saveAndExportWithFlattening:(BOOL)flattening
{
    [self saveDocument:e_ptincremental completionHandler:^(BOOL success) {
        if( success )
        {
            [self exportDocWithFlattening:flattening];
        }
        else
        {
            NSLog(@"Could not save document for export.");
        }
    }];
}

-(void)saveAndExportOptimizedCopy
{
    [self saveDocument:e_ptincremental completionHandler:^(BOOL success) {
        if( success )
        {
            [self exportOptimizedCopy];
        }
        else
        {
            NSLog(@"Could not save document for export.");
        }
    }];
}

-(void)exportDocWithFlattening:(BOOL)flattening
{
    if ([self isDocumentInteractionLoading]) {
        // Already loading a document interaction controller.
        return;
    }
    NSURL *url = self.coordinatedDocument.fileURL ?: self.localDocumentURL;
    if (![url isFileURL]) {
        return;
    }

    NSString *activityTitle = flattening ? PTLocalizedString(@"Flattening", @"Flattening dialog text") : PTLocalizedString(@"Exporting", @"Exporting dialog text");
    [self showActivityAlertWithTitle:activityTitle];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL exportError = NO;
        
        NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:url.lastPathComponent];

        // Copy "main" doc to a temporary location.
        NSString *fileNameAddition = flattening ? @"-flattened" : @"-copy";
        NSString *path = [tempURL URLByDeletingPathExtension].path;
        path = [path stringByAppendingString:fileNameAddition];
        path = [path stringByAppendingPathExtension:tempURL.pathExtension];
        tempURL = [NSURL fileURLWithPath:path];
        if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
            NSError *error = nil;
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (!success) {
                PTLog(@"Failed to remove duplicate file \"%@\": %@", path, error);
            }
        }
        NSError *copyError = nil;
        BOOL copySuccess = [NSFileManager.defaultManager copyItemAtURL:url toURL:tempURL error:&copyError];
        if (!copySuccess) {
            exportError = YES;
            NSLog(@"Error exporting file: %@", copyError);
        }
        
        if( !exportError )
        {
            PTPDFDoc *exportedDoc = [[PTPDFDoc alloc] initWithFilepath:tempURL.path];
            PTSaveOptions saveOptions = flattening ? e_ptlinearized : e_ptremove_unused;
            if (flattening) {
                [exportedDoc FlattenAnnotations:NO];
            }
            BOOL shouldUnlock = NO;
            @try {
                [exportedDoc Lock];
                shouldUnlock = YES;
                [exportedDoc SaveToFile:tempURL.path flags:saveOptions];
            } @catch (NSException *exception) {
                exportError = YES;
                NSLog(@"Exception: %@, %@", exception.name, exception.reason);
            } @finally {
                if (shouldUnlock) {
                    [exportedDoc Unlock];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!exportError) {
                UIBarButtonItem *item = nil;
                if ([self.navigationItem.rightBarButtonItems containsObject:self.exportButtonItem]) {
                    item = self.exportButtonItem;
                } else {
                    item = self.moreItemsButtonItem;
                }

                [self hideViewControllersWithCompletion:^{
                    [self showActivityViewControllerForActivityItems:@[tempURL]
                                                   fromBarButtonItem:item];
                }];
            }
        });
    });
}

-(void)exportOptimizedCopy{
    if ([self isDocumentInteractionLoading]) {
        // Already loading a document interaction controller.
        return;
    }
    NSURL *url = self.coordinatedDocument.fileURL ?: self.localDocumentURL;
    if (![url isFileURL]) {
        return;
    }

    [self showActivityAlertWithTitle:PTLocalizedString(@"Optimizing", @"Optimizing dialog text")];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:url.lastPathComponent];

        // Copy "main" doc to a temporary location.
        NSString *path = [tempURL URLByDeletingPathExtension].path;
        path = [path stringByAppendingString:@"-optimized"];
        path = [path stringByAppendingPathExtension:tempURL.pathExtension];
        tempURL = [NSURL fileURLWithPath:path];
        if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
            NSError *error = nil;
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (!success) {
                PTLog(@"Failed to remove duplicate file \"%@\": %@", path, error);
            }
        }
        
        NSError *copyError = nil;
        
        BOOL exportError = NO;
        
        BOOL copySuccess = [NSFileManager.defaultManager copyItemAtURL:url toURL:tempURL error:&copyError];
        
        if (!copySuccess) {
            NSLog(@"Error exporting file: %@", copyError);
            exportError = YES;
        }
        
        PTPDFDoc *exportedDoc;
        
        if(! exportError )
        {
            @try
            {
                
                exportedDoc = [[PTPDFDoc alloc] initWithFilepath:tempURL.path];

                double colorMaxDPI = 225.0;
                double colorResampleDPI = 150.0;
                PTImageSettings *colorImageSettings = [[PTImageSettings alloc] init];
                [colorImageSettings SetDownsampleMode:e_ptds_default];
                [colorImageSettings SetCompressionMode:e_ptjpeg];
                [colorImageSettings SetQuality:8];
                [colorImageSettings SetImageDPI:colorMaxDPI resampling:colorResampleDPI];
                [colorImageSettings ForceRecompression:YES];

                PTMonoImageSettings *monoImageSettings = [[PTMonoImageSettings alloc] init];
                [monoImageSettings SetDownsampleMode:e_ptmn_default];
                [monoImageSettings SetCompressionMode:e_ptmn_jbig2];
                [monoImageSettings SetImageDPI:colorMaxDPI*2.0 resampling:colorResampleDPI*2.0];
                [monoImageSettings ForceRecompression:YES];

                PTOptimizerSettings *optimizerSettings = [[PTOptimizerSettings alloc] init];
                [optimizerSettings SetColorImageSettings:colorImageSettings];
                [optimizerSettings SetMonoImageSettings:monoImageSettings];
                [PTOptimizer Optimize: exportedDoc settings: optimizerSettings];
            }
            @catch (NSException *exception)
            {
                exportError = YES;
            }
        }

        BOOL shouldUnlock = NO;
        @try {
            [exportedDoc Lock];
            shouldUnlock = YES;
            [exportedDoc SaveToFile:tempURL.path flags:e_ptremove_unused];
        } @catch (NSException *exception) {
            exportError = YES;
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        } @finally {
            if (shouldUnlock) {
                [exportedDoc Unlock];
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideViewControllersWithCompletion:^{
                if (!exportError) {
                    UIBarButtonItem *item = nil;
                    if ([self.navigationItem.rightBarButtonItems containsObject:self.exportButtonItem]) {
                        item = self.exportButtonItem;
                    } else {
                        item = self.moreItemsButtonItem;
                    }
                    
                    [self showActivityViewControllerForActivityItems:@[tempURL]
                                                   fromBarButtonItem:item];
                }
            }];
        });
    });
}

-(void)showActivityAlertWithTitle:(NSString*)title{
    UIViewController *alertVC = [[UIViewController alloc] init];
    alertVC.modalPresentationStyle = UIModalPresentationPopover;

    UIActivityIndicatorViewStyle activityIndicatorStyle = UIActivityIndicatorViewStyleGray;
    if (@available(iOS 13.0, *)) {
        activityIndicatorStyle = UIActivityIndicatorViewStyleMedium;
    }
    UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:activityIndicatorStyle];
    activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [activityIndicator startAnimating];

    UILabel *activityLabel = [[UILabel alloc] init];
    activityLabel.font = [UIFont boldSystemFontOfSize:UIFont.systemFontSize];
    activityLabel.text = title;

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.distribution = UIStackViewDistributionFillEqually;
    [stackView addArrangedSubview:activityLabel];
    [stackView addArrangedSubview:activityIndicator];
    [alertVC.view addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
        [stackView.centerXAnchor constraintEqualToAnchor:alertVC.view.centerXAnchor],
        [stackView.centerYAnchor constraintEqualToAnchor:alertVC.view.centerYAnchor],
        [stackView.widthAnchor constraintEqualToAnchor:alertVC.view.widthAnchor],
        [stackView.heightAnchor constraintEqualToAnchor:alertVC.view.heightAnchor multiplier:0.8],
    ]];

    alertVC.popoverPresentationController.permittedArrowDirections = 0;
    alertVC.popoverPresentationController.sourceView = self.view;
    alertVC.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width*0.5, self.view.frame.size.height*0.5, 0, 0);
    alertVC.preferredContentSize = CGSizeMake(275,100);
    alertVC.popoverPresentationController.delegate = self;
    [alertVC setModalInPopover:YES];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}

- (void)searchViewControllerDidDismiss:(PTTextSearchViewController*)searchViewController {
    [self setControlsHidden:NO animated:YES];
    if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:willHideToolbar:)]) {
        [self.toolbarDelegate documentViewController:self willHideToolbar:searchViewController.navigationController.toolbar];
    }
}

#pragma mark - Thumbnail slider callbacks

- (void)thumbnailSliderViewInUse:(PTThumbnailSliderViewController *)thumbnailSliderViewController
{
    [self stopAutomaticControlHidingTimer];
}

- (void)thumbnailSliderViewNotInUse:(PTThumbnailSliderViewController *)thumbnailSliderViewController
{
    [self restartAutomaticControlHidingTimerIfNeeded];
}

#pragma mark - Outline view controller callbacks

- (void)outlineViewController:(PTOutlineViewController *)outlineViewController selectedBookmark:(NSDictionary *)aBookmark
{
    // Leave the full-screen view controller if tapped
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self hideViewControllers];
    }
}

- (void)outlineViewControllerDidCancel:(PTOutlineViewController *)outlineViewController
{
    [self hideViewControllers];
}

#pragma mark - Annotation view controller callbacks

- (void)annotationViewControllerDidCancel:(PTAnnotationViewController *)annotationViewController
{
    [self hideViewControllers];
}

- (void)annotationViewController:(PTAnnotationViewController *)annotationViewController selectedAnnotaion:(NSDictionary *)anAnnotation
{
    
        // Leave the full-screen view controller if tapped
    if (annotationViewController.view.frame.size.width == annotationViewController.view.window.bounds.size.width) {
        [self hideViewControllers];
    }
}

- (void)annotationViewController:(PTAnnotationViewController *)annotationViewController annotationRemoved:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{

}

#pragma mark - Bookmark view controller callbacks

- (void)bookmarkViewController:(PTBookmarkViewController *)bookmarkViewController didAddBookmark:(PTUserBookmark *)bookmark
{
    
}

- (void)bookmarkViewController:(PTBookmarkViewController *)bookmarkViewController didModifyBookmark:(PTUserBookmark *)bookmark
{

}

- (void)bookmarkViewController:(PTBookmarkViewController *)bookmarkViewController didRemoveBookmark:(PTUserBookmark *)bookmark
{
    
}

- (void)bookmarkViewController:(PTBookmarkViewController *)bookmarkViewController selectedBookmark:(PTUserBookmark *)bookmark
{
    
}

- (void)bookmarkViewControllerDidCancel:(PTBookmarkViewController *)bookmarkViewController
{
    [self hideViewControllers];
}

#pragma mark - PDF layer view controller callbacks

- (void)pdfLayerViewControllerDidCancel:(PTPDFLayerViewController *)pdfLayerViewController
{
    [self hideViewControllers];
}

#pragma mark - Reflow view controller callbacks

- (void)reflowController:(PTReflowViewController *)reflowController handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // Toggle controls.
    [self setControlsHidden:!self.controlsHidden animated:YES];
}

#pragma mark - <PTToolManagerDelegate>

- (void)toolManagerToolChanged:(PTToolManager *)toolManager
{
    if (@available(iOS 11.0, *)) {
        // Since the tool changed, we need to update the screen edges which should have deferred system
        // gestures (ie. if Tools gets first crack at gestures near the screen edges).
        [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
        
        // Update the home indicator auto-hiding behavior (depends on the current tool).
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
    
    // Uncomment the following code to show a dialog asking for an annotation author.
//    // Set up the annotation author.
//    NSString *annotationAuthor = [NSUserDefaults.standardUserDefaults stringForKey:@"annotation_author"];
//
//    if ((annotationAuthor.length == 0)
//        && tool.createsAnnotation && (tool.annotationAuthor.length == 0)
//        && ![tool isKindOfClass:[PTDigitalSignatureTool class]]) {
//
//        // there is no annotation author, check if we have asked them for one
//        BOOL alreadyAsked =  [NSUserDefaults.standardUserDefaults boolForKey:@"askedForAnnotAuthor"];
//
//        if (!alreadyAsked) {
//            [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"askedForAnnotAuthor"];
//
//            [self askForAnnotationAuthor];
//        }
//    }
}

-(void)toolManager:(PTToolManager *)toolManager willModifyAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    
}

-(void)toolManager:(PTToolManager*)toolManager willRemoveAnnotation:(nonnull PTAnnot *)annotation onPageNumber:(int)pageNumber
{

}

- (void)toolManager:(PTToolManager *)toolManager annotationAdded:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    
}

- (void)toolManager:(PTToolManager *)toolManager annotationModified:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    
}

- (void)toolManager:(PTToolManager *)toolManager annotationRemoved:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    
}

- (void)toolManager:(PTToolManager *)toolManager pageAddedForPageNumber:(int)pageNumber
{
    
}

- (void)toolManager:(PTToolManager *)toolManager pageMovedFromPageNumber:(int)oldPageNumber toPageNumber:(int)newPageNumber
{
    
}

- (void)toolManager:(PTToolManager *)toolManager pageRemovedForPageNumber:(int)pageNumber
{
    
}

- (void)toolManager:(PTToolManager *)toolManager didSelectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    
}

- (void)toolManager:(PTToolManager *)toolManager formFieldDataModified:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    
}

- (BOOL)toolManager:(PTToolManager *)toolManager handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // Not handled.
    return NO;
}

- (BOOL)toolManager:(PTToolManager *)toolManager handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // Not handled.
    return NO;
}

- (BOOL)toolManager:(PTToolManager *)toolManager handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    // Not handled.
    return NO;
}

- (BOOL)toolManager:(PTToolManager *)toolManager shouldHandleLinkAnnotation:(PTAnnot *)annotation orLinkInfo:(PTLinkInfo *)linkInfo onPageNumber:(unsigned long)pageNumber
{
    return YES;
}

- (void)toolManager:(PTToolManager *)toolManager handleFileAttachment:(PTFileAttachment *)fileAttachment onPageNumber:(unsigned long)pageNumber
{
    PTFileAttachmentHandler *handler = [[PTFileAttachmentHandler alloc] init];
    handler.delegate = self;
    
    @try {
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        [handler exportFileAttachment:fileAttachment fromPDFDoc:doc];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
}

- (BOOL)toolManager:(PTToolManager *)toolManager handleFileSelected:(NSString *)filePath
{
    if (filePath.length == 0) {
        return NO;
    }
    
    // Check for absolute path or relative path in current directory.
    NSURL *fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
    if (![NSFileManager.defaultManager fileExistsAtPath:fileURL.path]) {
        // File is not absolute or in the current directory.
        // Check if it is relative to the current document URL (local).
        if (!self.localDocumentURL) {
            return NO;
        }
        
        fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO relativeToURL:self.localDocumentURL];
        if (![NSFileManager.defaultManager fileExistsAtPath:fileURL.path]) {
            // File is not relative to the current document.
            return NO;
        }
    }
    
    BOOL shouldOpen = YES;
    
    // Ask delegate if the document view controller should open the file path.
    if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:shouldOpenFileURL:)]) {
        shouldOpen = [self.toolbarDelegate documentViewController:self shouldOpenFileURL:fileURL];
    }
    
    if (!shouldOpen) {
        // Handled by tabbed viewer.
        return YES;
    } else {
        // NOTE: the async dispatch is necessary to avoid issues with read-locks in other places.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self openDocumentWithURL:fileURL];
        });
        return YES;
    }
}

- (BOOL)toolManager:(PTToolManager *)toolManager shouldInteractWithForm:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    return YES;
}

- (BOOL)toolManager:(PTToolManager *)toolManager shouldSelectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    return YES;
}

- (BOOL)toolManager:(PTToolManager *)toolManager shouldShowMenu:(UIMenuController *)menuController forAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    return YES;
}

- (BOOL)toolManager:(PTToolManager *)toolManager shouldSwitchToTool:(PTTool *)tool
{
    return YES;
}

- (UIViewController *)viewControllerForToolManager:(PTToolManager *)toolManager
{
    return self;
}

#pragma mark Annotation author

- (void)setAnnotationAuthor:(NSString *)annotationAuthor
{
    [[NSUserDefaults standardUserDefaults] setObject:annotationAuthor forKey:@"annotation_author"];
    
    self.toolManager.annotationAuthor = annotationAuthor;
}

- (void)askForAnnotationAuthor
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:PTLocalizedString(@"Add Author", @"")
                                          message:PTLocalizedString(@"Add your name as an author to annotations you create. You can change this using the iOS Settings app.", @"")
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Skip", @"As in skip this step.")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setAnnotationAuthor:alertController.textFields.firstObject.text];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:addAction];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
         textField.placeholder = PTLocalizedString(@"Name", @"Person's Name");
     }];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - <PTFileAttachmentHandlerDelegate>

- (void)fileAttachmentHandler:(PTFileAttachmentHandler *)fileAttachmentHandler didExportFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc toURL:(NSURL *)exportedURL
{
    PTLog(@"Exported file attachment to URL: %@", exportedURL);
    
    BOOL shouldOpen = YES;
    
    // Ask delegate if the document view controller should open the exported file attachment.
    if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:shouldOpenExportedFileAttachmentAtURL:)]) {
        shouldOpen = [self.toolbarDelegate documentViewController:self shouldOpenExportedFileAttachmentAtURL:exportedURL];
    }
    
    if (shouldOpen) {
        self.documentInteraction = nil;
        self.documentInteractionLoading = YES;
        
        [self loadDocumentInteractionControllerForURL:exportedURL completion:^(UIDocumentInteractionController *controller) {
            self.documentInteractionLoading = NO;
            
            self.documentInteraction = controller;
            self.documentInteraction.delegate = self;
            
            [self.documentInteraction presentPreviewAnimated:YES];
        }];
    }
}

- (void)fileAttachmentHandler:(PTFileAttachmentHandler *)fileAttachmentHandler didFailToExportFileAttachment:(PTFileAttachment *)fileAttachment fromPDFDoc:(PTPDFDoc *)doc withError:(NSError *)error
{
    PTLog(@"Failed to export file attachment: %@", error);
}

#pragma mark - <PTPanelViewControllerDelegate>

- (void)panelViewController:(PTPanelViewController *)panelViewController didShowLeadingViewController:(UIViewController *)viewController
{
    if (viewController == self.navigationListsViewController) {
        if ([self.navigationListsButtonItem isKindOfClass:[PTSelectableBarButtonItem class]]) {
            ((PTSelectableBarButtonItem *)self.navigationListsButtonItem).selected = YES;
        }
    }
}

- (void)panelViewController:(PTPanelViewController *)panelViewController didDismissLeadingViewController:(UIViewController *)viewController
{
    if (viewController == self.navigationListsViewController) {
        if ([self.navigationListsButtonItem isKindOfClass:[PTSelectableBarButtonItem class]]) {
            ((PTSelectableBarButtonItem *)self.navigationListsButtonItem).selected = NO;
        }
    }
}

#pragma mark - Sharing callbacks

- (void)openDocumentIn:(UIBarButtonItem *)barButtonItem
{
    if ([self isDocumentInteractionLoading]) {
        // Already loading a document interaction controller.
        return;
    }
    
    [self hideViewControllers];
    
    NSURL *url = self.coordinatedDocument.fileURL ?: self.localDocumentURL;
    if (![url isFileURL]) {
        return;
    }
    
    if (self.pdfViewCtrl.externalAnnotManager) {
        NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:url.lastPathComponent];
        
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            
            PTPDFDoc *mainDoc = [self.pdfViewCtrl GetDoc];
            
            // Copy "main" doc to a temporary location.
            NSError *copyError = nil;
            BOOL copySuccess = [NSFileManager.defaultManager copyItemAtURL:url toURL:tempURL error:&copyError];
            if (!copySuccess) {
                NSLog(@"Error exporting file: %@", copyError);
            }
            
            PTPDFDoc *exportedDoc = [[PTPDFDoc alloc] initWithFilepath:tempURL.path];
            
            // Add internal annots from the main doc.
            PTFDFDoc *mainFDFDoc = [mainDoc FDFExtract:e_ptannots_only];
            [exportedDoc FDFUpdate:mainFDFDoc];
                        
            void *mainDocImpl = (void *)[[mainDoc GetSDFDoc] GetHandleInternal];
            
            // Find the TRN_SDFDoc handle for the "extra" doc, which contains all of the external
            // annots.
            void *extraDocImpl = NULL;
            
            const int pageCount = [self.pdfViewCtrl GetPageCount];
            for (int pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
                NSArray<PTAnnot *> *annots = [self.pdfViewCtrl GetAnnotationsOnPage:pageNumber];
                
                for (PTAnnot *annot in annots) {
                    if (![annot IsValid]) {
                        continue;
                    }
                    
                    PTObj *annotObj = [annot GetSDFObj];
                    if (![annotObj IsValid]) {
                        continue;
                    }
                    PTSDFDoc *annotDoc = [annotObj GetDoc];
                    
                    // Check if annot's doc isn't the main doc.
                    void *annotDocImpl = (void *)[annotDoc GetHandleInternal];
                    if (annotDocImpl != mainDocImpl) {
                        extraDocImpl = annotDocImpl;
                        break;
                    }
                }
                
                if (extraDocImpl != NULL) {
                    // Found the extra doc.
                    break;
                }
            }
                        
            if (extraDocImpl != NULL) {
                // Create a PDFDoc from the extra doc (SDFDoc) reference.
                PTSDFDoc *extraSDFDoc = [PTSDFDoc CreateInternal:(unsigned long long)extraDocImpl];
                [extraSDFDoc setSwigCMemOwn:NO]; // Not owned by ObjC.
                PTPDFDoc *extraDoc = [[PTPDFDoc alloc] initWithSdfdoc:extraSDFDoc];
                
                // Merge in the external annots into the exported doc.
                PTFDFDoc *fdfDoc = [extraDoc FDFExtract:e_ptannots_only];
                [exportedDoc FDFMerge:fdfDoc];
            }
            
            [exportedDoc SaveToFile:tempURL.path flags:0];

            [exportedDoc Close];
            exportedDoc = nil;
            
            // Share the exported document.
            url = tempURL;
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        }
        @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
    } else {
        [self saveDocument:e_ptincremental completionHandler:^(BOOL success) {
            if (success) {
                // Create an item provider for the document.
                // The provider is able to produce a printer-safe document if the print action is
                // selected.
                PTDocumentItemProvider *itemProvider = [[PTDocumentItemProvider alloc] initWithDocumentURL:url password:self.documentPassword];
                
                [self showActivityViewControllerForActivityItems:@[itemProvider]
                                               fromBarButtonItem:barButtonItem];
            }
            else {
                [self showErrorAlertFrom:self.pt_topmostPresentedViewController
                               withTitle:PTLocalizedString(@"Error",
                                                           @"Error alert title")
                                 message:PTLocalizedString(@"Document could not be shared",
                                                           @"Sharing failed message")];
            }
        }];
     }
    
     if( self.pdfViewCtrl.externalAnnotManager )
     {
        // Create an item provider for the document.
        // The provider is able to produce a printer-safe document if the print action is
        // selected.
        PTDocumentItemProvider *itemProvider = [[PTDocumentItemProvider alloc] initWithDocumentURL:url password:self.documentPassword];
        
        [self showActivityViewControllerForActivityItems:@[itemProvider]
                                       fromBarButtonItem:barButtonItem];
    }
}

- (void)showActivityViewControllerForActivityItems:(NSArray<id> *)activityItems fromBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    [self hideViewControllers];
    
    // Show an activity view controller for the activity items.
    self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    // Clear activityViewController property when dismissed.
    __weak __typeof__(self) weakSelf = self;
    self.activityViewController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        __strong __typeof__(weakSelf) self = weakSelf;
        if (self) {
            self.activityViewController = nil;
            
            [NSNotificationCenter.defaultCenter postNotificationName:PTDocumentViewControllerDidDissmissShareActivityNotification
                                                              object:self
                                                            userInfo:nil];
        }
    };
    
    // Show activity view controller as popover, when possible.
    self.activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popover = self.activityViewController.popoverPresentationController;
    popover.barButtonItem = barButtonItem;
    
    [self presentViewController:self.activityViewController animated:YES completion:nil];
}

- (void)loadDocumentInteractionControllerForURL:(NSURL *)url completion:(void (^)(UIDocumentInteractionController *controller))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Create controller for given URL.
        UIDocumentInteractionController *controller = [UIDocumentInteractionController interactionControllerWithURL:url];
        
        // Dispatch back to main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(controller);
            }
        });
    });
}

#pragma mark - <UIDocumentInteractionControllerDelegate>

- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller
{
    [controller pt_cleanupFromPresentation];
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (void)documentInteractionControllerWillPresentOptionsMenu:(UIDocumentInteractionController *)controller
{
    [controller pt_prepareForPresentation];
}

- (void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller
{
    [controller pt_prepareForPresentation];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    self.documentInteraction = nil;
    self.documentInteractionLoading = NO;
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    [controller pt_cleanupFromPresentation];

    self.documentInteraction = nil;
    self.documentInteractionLoading = NO;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    [controller pt_cleanupFromPresentation];
    
    self.documentInteraction = nil;
    self.documentInteractionLoading = NO;
}

#pragma mark - Email

static NSString *pt_getAppName()
{
    NSBundle *bundle = [NSBundle mainBundle];
    
    // Use bundle display name.
    NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName) {
        // Use bundle name.
        appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
    }
    
    return appName;
}

- (void)emailDocument: (UIBarButtonItem*)barButtonItem
{
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.mailComposeDelegate = self;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        composer.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    NSString *localizedFormat = PTLocalizedString(@"%@ Document - %@",
                                                  @"App and document name as email subject");
    NSString *subject = [NSString localizedStringWithFormat:localizedFormat, pt_getAppName(), [[self.document GetFileName] lastPathComponent]];
    
    [composer setSubject:subject];
    
    {
        NSString* defaultBody = [@"</br></br>" stringByAppendingString:[[NSUserDefaults standardUserDefaults] objectForKey:@"emailSignature"]];
        [composer setMessageBody:defaultBody isHTML:YES];
        
        [composer addAttachmentData:[NSData dataWithContentsOfFile:[self.document GetFileName]] mimeType:@"x-application/pdf" fileName:[[self.document GetFileName]lastPathComponent]];
        
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self presentViewController:composer animated:YES completion:nil];
        });
    }
}

- (void)printDocumentShortcut
{
    [self printDocument:self.shareButtonItem];
}

- (void)printDocument: (UIBarButtonItem*)barButtonItem
{
    [self hideViewControllers];
    
    self.printer = [[PTPrint alloc] init];
    
    [self.printer PrepareDocToPrint:self.document
                           Delegate:self
                           UserData:@{@"printer": self.printer,
                                      @"barButtonItem" : barButtonItem}];
}

- (void)PreparedToPrint:(NSString*)docFilePath UserData:(id)userData
{
    NSDictionary<NSString *, id> *dictionary = [userData isKindOfClass:[NSDictionary class]] ? (NSDictionary *)userData : nil;
    
    // Make sure we are the same printer object (if not, means we cancelled the print)
    if (self.printer != dictionary[@"printer"]) {
        return;
    }
    
    // We present ourselves as a full-screen panel on iPhone and as a popover on iPad
    UIBarButtonItem *barButtonItem = dictionary[@"barButtonItem"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.printer PrintDoc:docFilePath FromBarButtonItem:barButtonItem WithJobName:nil Animated:YES CompletionHandler:^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
            self.printer = nil;
            [self dismissViewControllerAnimated:NO completion:nil];
            if (error) {
                NSLog(@"Error: %@", error);
            }
        }];
    } else {
        [self hideViewControllers];
        if (self.view.window != nil)
            [self.printer PrintDoc:docFilePath FromBarButtonItem:barButtonItem WithJobName:nil Animated:YES CompletionHandler:^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
                self.printer = nil;
                if (error) {
                    NSLog(@"Error: %@", error);
                }
            }];
    }
}

#pragma mark - Mail compose view controller callbacks

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self hideViewControllers];
}

//#pragma mark - Search Document delegate
//// Currently unused
//
//// The search list was cancelled
//- (void)searchViewControllerCancelled:(SearchViewController *)searchViewController
//{
//    [self hideViewControllers];
//}
//
//// A search result in the search list was selected
//- (void)searchViewController:(SearchViewController *)searchViewController selectedResult:(NSDictionary *)aResult
//{
//    [self.pdfView SetCurrentPage:[[aResult objectForKey:@"pageNumber"] intValue]];
//
//    // Highlight the searched text
//    [self.document Lock];
//    [self.pdfView SelectWithHighlights:[aResult objectForKey:@"highlights"]];
//    PTSelection * selection = [self.pdfView GetSelection:self.pdfView.GetCurrentPage];
//    [self.pdfView highlightSelection:selection withColor:[[UIColor orangeColor] colorWithAlphaComponent:0.5]];
//    [self.document Unlock];
//
//    // Leave the full-screen view controller if tapped
//    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
//        [self hideViewControllers];
//    }
//}

#pragma mark - Utility

- (void)hideViewControllers
{
    [self hideViewControllersWithCompletion:nil];
}

- (void)hideViewControllersWithCompletion:(void (^ __nullable)(void))completion
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
            if (completion) {
                completion();
            }
        }];
    }
    else if (completion) {
        completion();
    }
    
    if (self.documentInteraction) {
        [self.documentInteraction dismissMenuAnimated:YES];
        self.documentInteraction = nil;
    }
}

-(void)showErrorAlertFrom:(UIViewController*)controller withTitle:(NSString*)title message:(NSString*)message
{
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK",@"")
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alertController addAction:okAction];
    
    [controller presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - System callbacks

@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;

- (BOOL)prefersStatusBarHidden
{
    return _prefersStatusBarHidden;
}

- (void)setPrefersStatusBarHidden:(BOOL)hidden
{
    _prefersStatusBarHidden = hidden;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    if (self.prefersStatusBarHidden && ![self.toolManager.tool isKindOfClass:[PTPanTool class]]) {
        // Defer handling of screen edge gestures while status bars are hidden.
        // This allows interaction with the document at the top & bottom of the screen.
        return (UIRectEdgeTop | UIRectEdgeBottom);
    } else {
        // Allow the system to handle screen edge gestures while status bars are shown.
        return UIRectEdgeNone;
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    if (self.prefersStatusBarHidden &&
        [self.toolManager.tool isKindOfClass:[PTPanTool class]]) {
        // Allow the home indicator to be hidden.
        return YES;
    } else {
        return NO;
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (void)didReceiveMemoryWarning
{
    [self.pdfViewCtrl PurgeMemory];
    [super didReceiveMemoryWarning];
}


#pragma mark - <PTDocumentViewSettingsControllerDelegate>

- (void)documentViewSettingsController:(PTDocumentViewSettingsController *)documentViewSettingsController didUpdateSettings:(PTDocumentViewSettings *)settings
{
    if (self.pdfViewCtrl.pagePresentationMode != settings.pagePresentationMode) {
        self.pdfViewCtrl.pagePresentationMode = settings.pagePresentationMode;
    }
    
    if ([self isReflowHidden] != ![settings isReflowEnabled]) {
        self.reflowHidden = ![settings isReflowEnabled];
    }
    else if (![self isReflowHidden]) {
        // Update reflow scrolling direction for the current page presentation mode.
        self.reflowViewController.scrollingDirection = [self reflowScrollingDirectionForPagePresentationMode:self.pdfViewCtrl.pagePresentationMode];
    }
    
    if (self.pdfViewCtrl.colorPostProcessMode != settings.colorPostProcessMode) {
        
        if( settings.colorPostProcessMode == e_ptpostprocess_gradient_map )
        {
            NSString* sepiaPath = [PTToolsUtil.toolsBundle pathForResource:@"sepia_mode_filter" ofType:@"png" inDirectory:@"Images"];

            _sepiaColourLookupMap = [[PTMappedFile alloc] initWithFilename:sepiaPath];

            [_pdfViewCtrl SetColorPostProcessMapFile:_sepiaColourLookupMap];
        }
        else
        {
            self.pdfViewCtrl.colorPostProcessMode = settings.colorPostProcessMode;
        }
    }
    
    while (self.pdfViewCtrl.rotation != settings.pageRotation) {
        [self.pdfViewCtrl RotateClockwise];
    }
    
    if (self.localDocumentURL) {
        [PTDocumentViewSettingsManager.sharedManager setViewSettings:settings
                                                    forDocumentAtURL:self.localDocumentURL];
    }
}

#pragma mark - Document saving

-(void)setDocumentIsInValidState:(BOOL)documentIsInValidState
{


    _documentIsInValidState = documentIsInValidState;

}

- (void)saveDocumentIfNotRendering:(NSTimer *)timer

{


    bool isRendering = false;
    isRendering = ![self.pdfViewCtrl IsFinishedRendering:NO];
    if( isRendering )
    {

        return;
    }
    else
    {
        [self saveDocument:e_ptincremental completionHandler:nil];
    }
}

- (void)saveDocument:(PTSaveOptions)saveOptions completionHandler:(void (^ __nullable)(BOOL success))completionHandler
{
    
    if( self.documentIsInValidState == NO )
    {

        if( completionHandler ) {
            completionHandler(NO);
        }
        return;
    }
    
    if ([self.toolManager isReadonly]) {

        if (completionHandler) {
            completionHandler(NO);
        }
        return;
    }
    
    BOOL isRendering = ![self.pdfViewCtrl IsFinishedRendering:NO];
    if (isRendering) {
        [self.pdfViewCtrl CancelRendering];
    }
    
    BOOL shouldSave = YES;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        shouldSave = ([self.document IsModified] && (self.localDocumentURL || self.coordinatedDocument));
        
        if( self.coordinatedDocument && self.documentIsInValidState )
        {
            NSAssert([self.document GetHandleInternal] == [self.coordinatedDocument.pdfDoc GetHandleInternal], @"Coordinated document must be document open in pdfviewctrl.");
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
        
        shouldSave = NO;
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    if (!shouldSave) {

        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    
    if (self.coordinatedDocument)
    {
        if( self.documentIsInValidState == NO )
        {

            if (completionHandler) {
                completionHandler(NO);
            }
        }
        else {

            
            
            self.saveRequested = YES;
            [self.coordinatedDocument saveToURL:self.coordinatedDocument.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                self.saveRequested = NO;
                if (completionHandler) {
                    completionHandler(success);
                }
            }];
        }
    }
    else
    {

        // Save PDFDoc directly.
        BOOL success = YES;
        
        @try {
            [self.pdfViewCtrl DocLock:YES];
            
            [self.document SaveToFile:self.localDocumentURL.path flags:saveOptions];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@", exception);
            
            success = NO;
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
        
        if (completionHandler) {
            completionHandler(success);
        }
    }
}

- (void)setAutomaticallySavesDocument:(BOOL)automaticallySavesDocument
{
    if (_automaticallySavesDocument == automaticallySavesDocument) {
        return;
    }
    
    _automaticallySavesDocument = automaticallySavesDocument;
    
    if (automaticallySavesDocument) {
        [self restartAutomaticDocumentSavingTimer];
    } else {
        [self stopAutomaticDocumentSavingTimer];
    }
}

#pragma mark Automatic document saving timer

- (void)setAutomaticDocumentSavingInterval:(NSTimeInterval)interval
{
    if (_automaticDocumentSavingInterval == interval) {
        return;
    }
    
    _automaticDocumentSavingInterval = interval;
    
    if( interval == DBL_MAX )
    {
        // not realistically necessary, but /shrug
        self.automaticDocumentSavingTimer = Nil;
    }
    else
    {
        // Restart timer with updated interval.
        [self restartAutomaticDocumentSavingTimer];
    }
}

- (void)restartAutomaticDocumentSavingTimer
{
    [self restartAutomaticDocumentSavingTimerWithInterval:self.automaticDocumentSavingInterval];
}

- (void)restartAutomaticDocumentSavingTimerWithInterval:(NSTimeInterval)interval
{
    if (!self.automaticallySavesDocument) {
        return;
    }
    
    // Stop previous timer.
    if (self.automaticDocumentSavingTimer) {
        [self stopAutomaticDocumentSavingTimer];
    }
    
    if (self.automaticDocumentSavingInterval != interval) {
        self.automaticDocumentSavingInterval = interval;
    }
    
    if( interval == DBL_MAX )
    {
        // not realistically necessary, but /shrug
        self.automaticDocumentSavingTimer = Nil;
    }
    else
    {
        self.automaticDocumentSavingTimer = [PTTimer scheduledTimerWithTimeInterval:interval
                                                                             target:self
                                                                           selector:@selector(saveDocumentIfNotRendering:)
                                                                           userInfo:nil
                                                                            repeats:YES];
    }
}

- (void)stopAutomaticDocumentSavingTimer
{
    [self.automaticDocumentSavingTimer invalidate];
    self.automaticDocumentSavingTimer = nil;
}

#pragma mark - Progress spinner

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator) {
        [self loadViewIfNeeded];
    }
    
    NSAssert(_activityIndicator, @"Activity indicator was not loaded");
    
    return _activityIndicator;
}

- (BOOL)isActivityIndicatorHidden
{
    return self.activityIndicator.hidden;
}

- (void)setActivityIndicatorHidden:(BOOL)hidden
{
    if (hidden == self.activityIndicator.hidden) {
        // No change.
        return;
    }
    
    if (hidden) {
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
    } else {
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
    }
}

#pragma mark - Bar button items

@synthesize readerModeButtonItem = _readerModeButtonItem;
@dynamic readerModeButtonHidden;

- (UIBarButtonItem *)readerModeButtonItem
{
    if (!_readerModeButtonItem) {
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"doc.plaintext" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_view_mode_reflow_black_24dp"];
        }
        
        _readerModeButtonItem = [[PTSelectableBarButtonItem alloc] initWithImage:image
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(toggleReflow)];
        
        _readerModeButtonItem.title = PTLocalizedString(@"Reader Mode",
                                                        @"Reader Mode button title");
    }
    return _readerModeButtonItem;
}

@synthesize searchButtonItem = _searchButtonItem;
@dynamic searchButtonHidden;

- (UIBarButtonItem *)searchButtonItem
{
    if (!_searchButtonItem) {
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        } else {
            image = [PTToolsUtil toolImageNamed:@"ic_search_black_24px"];
        }
        
        _searchButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showSearchView:)];
        
        _searchButtonItem.title = PTLocalizedString(@"Search", @"Search PDF");
    }
    return _searchButtonItem;
}

@synthesize shareButtonItem = _shareButtonItem;
@dynamic shareButtonHidden;

- (UIBarButtonItem *)shareButtonItem
{
    if (!_shareButtonItem) {
        
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_share_ios_black_24px"];
        }
        
        _shareButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(showShareActions:)];
        
        _shareButtonItem.title = PTLocalizedString(@"Share", @"The action sheet");
    }
    return _shareButtonItem;
}

@synthesize appSettingsButtonItem = _appSettingsButtonItem;
@dynamic appSettingsButtonHidden;

- (UIBarButtonItem *)appSettingsButtonItem
{
    if (!_appSettingsButtonItem) {
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"gear" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_viewing_mode_white_24dp"];
        }
        
        _appSettingsButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(showAppSettings:)];
        
        _appSettingsButtonItem.title = PTLocalizedString(@"App Settings",
                                                      @"View Settings button title");
    }

    return _appSettingsButtonItem;
}


@synthesize settingsButtonItem = _settingsButtonItem;
@dynamic viewerSettingsButtonHidden;

- (UIBarButtonItem *)settingsButtonItem
{
    if (!_settingsButtonItem) {
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"eyeglasses" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_viewing_mode_white_24dp"];
        }
        
        _settingsButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(showSettings:)];
        
        _settingsButtonItem.title = PTLocalizedString(@"View Settings",
                                                      @"View Settings button title");
    }

    return _settingsButtonItem;
}

#pragma mark Export

@synthesize exportButtonItem = _exportButtonItem;
@dynamic exportButtonHidden;

- (UIBarButtonItem *)exportButtonItem
{
    if (!_exportButtonItem) {
        UIImage *image;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"square.and.arrow.up.on.square" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_share_ios_black_24px"];
        }
        _exportButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showExportOptions:)];
        _exportButtonItem.title = PTLocalizedString(@"Export", @"Export PDF");
    }
    return _exportButtonItem;
}

#pragma mark Thumbnails (browser)

@synthesize thumbnailsButtonItem = _thumbnailsButtonItem;
@dynamic thumbnailBrowserButtonHidden;

- (UIBarButtonItem *)thumbnailsButtonItem
{
    if (!_thumbnailsButtonItem) {
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"square.grid.2x2" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_thumbnails_grid_black_24dp"];
        }
        
        _thumbnailsButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(showThumbnails:)];
        
        _thumbnailsButtonItem.title = PTLocalizedString(@"Thumbnails",
                                                        @"Thumbnails button title");
    }
    return _thumbnailsButtonItem;
}

#pragma mark Navigation lists

@synthesize navigationListsButtonItem = _navigationListsButtonItem;
@dynamic navigationListsButtonHidden;

- (UIBarButtonItem *)navigationListsButtonItem
{
    if (!_navigationListsButtonItem) {
        UIImage *image = [self navigationListsButtonItemImageForTraitCollection:self.traitCollection];

        _navigationListsButtonItem = [[PTSelectableBarButtonItem alloc] initWithImage:image
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:self
                                                                               action:@selector(showBookmarks:)];
        
        _navigationListsButtonItem.title = PTLocalizedString(@"Navigation Lists",
                                                             @"Navigation Lists button title");
    }
    return _navigationListsButtonItem;
}

- (UIImage *)navigationListsButtonItemImageForTraitCollection:(UITraitCollection *)traitCollection
{
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            return [UIImage systemImageNamed:@"sidebar.left" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]];
        }
        else {
            return [UIImage systemImageNamed:@"list.bullet.below.rectangle" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]];
        }
    } else {
        return [PTToolsUtil toolImageNamed:@"ic_list_black_24px"];
    }
}

- (void)updateNavigationListsButtonItemImage
{
    [self updateNavigationListsButtonItemImageForTraitCollection:self.traitCollection];
}

- (void)updateNavigationListsButtonItemImageForTraitCollection:(UITraitCollection *)traitCollection
{
    UIImage *image = [self navigationListsButtonItemImageForTraitCollection:traitCollection];
    self.navigationListsButtonItem.image = image;
}

@synthesize moreItemsButtonItem = _moreItemsButtonItem;
@dynamic moreItemsButtonHidden;

- (UIBarButtonItem *)moreItemsButtonItem
{
    if (!_moreItemsButtonItem) {
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"ellipsis.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_more_black_24px"];
        }
        
        _moreItemsButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showMoreItems:)];
        if (@available(iOS 14.0, *)) {
            // on iOS 14+ show the dropdown menu added in `setMoreItems:`
            _moreItemsButtonItem.action = nil;
        }
        _moreItemsButtonItem.title = PTLocalizedString(@"More",
                                                       @"More button title");
    }
    return _moreItemsButtonItem;
}

@synthesize addPagesButtonItem = _addPagesButtonItem;
@dynamic addPagesButtonHidden;

- (UIBarButtonItem *)addPagesButtonItem
{
    if (!_addPagesButtonItem) {
        UIImage *image;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"plus" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        } else {
            image = [PTToolsUtil toolImageNamed:@"ic_view_mode_single_black_24px"];
        }
        _addPagesButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showAddPagesView:)];
        _addPagesButtonItem.title = PTLocalizedString(@"Add Pages", @"Add pages button title");
    }
    return _addPagesButtonItem;
}

#pragma mark - Control visibility

@synthesize controlsHidden = _controlsHidden;

- (BOOL)controlsHidden
{
    if (self.navigationController) {
        return self.navigationController.navigationBarHidden;
    } else {
        return _controlsHidden;
    }
}

- (void)setControlsHidden:(BOOL)hidden
{
    [self PT_setControlsHidden:hidden animated:NO];
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self willChangeValueForKey:PT_SELF_KEY(controlsHidden)];
    
    [self PT_setControlsHidden:hidden animated:animated];
    
    [self didChangeValueForKey:PT_SELF_KEY(controlsHidden)];
}

- (BOOL)shouldHideSystemBars
{
    // Consult delegate.
    if ([self.toolbarDelegate respondsToSelector:@selector(documentViewControllerShouldHideNavigationBar:)]) {
        if (![self.toolbarDelegate documentViewControllerShouldHideNavigationBar:self]) {
            return NO;
        }
    }
    
    if (@available(iOS 13.1, *))
    {
        if( [self.toolManager.tool isKindOfClass:[PTPencilDrawingCreate class]] )
        {
            return NO;
        }
    }

    
    // Allow hiding system bars if no other toolbar or popup is onscreen.
    return (!(self.settingsViewController.viewIfLoaded.window) &&
            !(self.presentedViewController &&
              !([self.presentedViewController isBeingDismissed]
                || [self.presentedViewController isMovingFromParentViewController])) &&
            !self.documentInteraction &&
            !self.printer);
}

- (BOOL)shouldShowSystemBars
{
    return ([self.navigationController isNavigationBarHidden] &&
            !self.presentedViewController);
}

#pragma mark Private API

- (void)PT_setControlsHidden:(BOOL)hidden animated:(BOOL)animated
{
    BOOL shouldChange = NO;
    
    if (hidden) {
        if ([self shouldHideSystemBars]) {
            shouldChange = YES;
        } else {
            // Reschedule timer.
            [self restartAutomaticControlHidingTimerIfNeeded];
        }
    } else {
        if ([self shouldShowSystemBars]) {
            shouldChange = YES;
        }
    }
    
    if (shouldChange && !PT_ToolsMacCatalyst) {
        [self PT_setSystemBarsHidden:hidden animated:animated];
    }
    
    [self setThumbnailSliderHidden:hidden animated:animated];
    
    // Toggle page indicator if allowed.
    if (hidden || self.pageIndicatorShowsWithControls) {
        [self setPageIndicatorHidden:hidden animated:animated];
    }
}


- (void)PT_setSystemBarsHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (hidden) {
        if ([self.toolbarDelegate respondsToSelector:@selector(documentViewControllerWillHideNavigationBar:animated:)]) {
            [self.toolbarDelegate documentViewControllerWillHideNavigationBar:self animated:animated];
        }
    } else {
        if ([self.toolbarDelegate respondsToSelector:@selector(documentViewControllerWillShowNavigationBar:animated:)]) {
            [self.toolbarDelegate documentViewControllerWillShowNavigationBar:self animated:animated];
        }
        
    }
    
    [self.navigationController setNavigationBarHidden:hidden animated:animated];
    
    // Allow hiding toolbar, but only showing it when there are toolbar items.
    if (hidden || self.toolbarItems.count > 0) {
        [self.navigationController setToolbarHidden:hidden
                                           animated:animated];
    }
    
    _controlsHidden = hidden;
    
    const NSTimeInterval duration = (animated) ? UINavigationControllerHideShowBarDuration : 0;
    
    // Toggle status bar visibility.
    [UIView animateWithDuration:duration animations:^{
        self.prefersStatusBarHidden = hidden;
    }];
    
    if (hidden) {
        if ([self.toolbarDelegate respondsToSelector:@selector(documentViewControllerDidHideNavigationBar:animated:)]) {
            [self.toolbarDelegate documentViewControllerDidHideNavigationBar:self animated:animated];
        }
    } else {
        if ([self.toolbarDelegate respondsToSelector:@selector(documentViewControllerDidShowNavigationBar:animated:)]) {
            [self.toolbarDelegate documentViewControllerDidShowNavigationBar:self animated:animated];
        }
    }
}

#pragma mark - Navigation lists

- (void)setAlwaysShowNavigationListsAsModal:(BOOL)alwaysShowNavigationListsAsModal
{
    _alwaysShowNavigationListsAsModal = alwaysShowNavigationListsAsModal;
    
    self.panelViewController.panelEnabled = !alwaysShowNavigationListsAsModal;
}

#pragma mark - Thumbnail slider

- (void)setThumbnailSliderHidden:(BOOL)hidden
{
    [self PT_setThumbnailSliderHidden:hidden animated:NO];
}

- (void)setThumbnailSliderHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self willChangeValueForKey:PT_KEY(self, thumbnailSliderHidden)];
    
    [self PT_setThumbnailSliderHidden:hidden animated:animated];
    
    [self didChangeValueForKey:PT_KEY(self, thumbnailSliderHidden)];
}

// Manually notify observers of `thumbnailSliderHidden` property.
+ (BOOL)automaticallyNotifiesObserversOfThumbnailSliderHidden
{
    return NO;
}

- (BOOL)shouldHideThumbnailSlider
{
    
    
    // Disable hiding slider while in use.
    if ([self.thumbnailSliderController isTracking]) {
        return NO;
    }
    
    // Disable hiding while presenting a view controller.
    // NOTE: This will handle popovers anchored on the thumbnail slider.
    if (self.presentedViewController) {
        return NO;
    }
    
    return YES;
}

- (BOOL)shouldShowThumbnailSlider
{
    if (![self isThumbnailSliderEnabled] || self.presentedViewController) {
        return NO;
    }
    
    
    
//    int pageCount = [self.document GetPageCount];
    
//    // Don't show for fewer than 2 pages.
//    if (pageCount < 2) {
//        return NO;
//    }
    
    // Don't show in annotation mode.
    if (![self.toolManager.tool isKindOfClass:[PTPanTool class]]) {
        return NO;
    }
    
//    // Don't show for two pages in landscape.
//    NSString *mode = [[NSUserDefaults standardUserDefaults] objectForKey:@"viewMode"];
//    if ([mode isEqualToString:PTLocalizedString(@"Single Page", @"")]) {
//        float aspect = self.view.bounds.size.width / self.view.bounds.size.height;
//        if (aspect > 1.0f && pageCount == 2) {
//            return NO;
//        }
//    }
    
    return YES;
}

- (void)hideThumbnailSliderAnimated:(BOOL)animated
{
    if (animated) {
        [self.view layoutIfNeeded];
        
        // Switch constraints.
        self.thumbnailSliderOnscreenConstraint.active = NO;
        self.thumbnailSliderOffscreenConstraint.active = YES;
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.view layoutIfNeeded];
            self.thumbnailSliderController.view.alpha = 0.0;
        } completion:nil];
    } else {
        // Switch constraints.
        self.thumbnailSliderOnscreenConstraint.active = NO;
        self.thumbnailSliderOffscreenConstraint.active = YES;
        self.thumbnailSliderController.view.alpha = 0.0;
    }
}

- (void)showThumbnailSliderAnimated:(BOOL)animated
{
    if (animated) {
        [self.view layoutIfNeeded];
        // Switch constraints.
        self.thumbnailSliderOffscreenConstraint.active = NO;
        self.thumbnailSliderOnscreenConstraint.active = YES;
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.view layoutIfNeeded];
            self.thumbnailSliderController.view.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self restartAutomaticControlHidingTimerIfNeeded];
        }];
    } else {
        // Switch constraints.
        self.thumbnailSliderOffscreenConstraint.active = NO;
        self.thumbnailSliderOnscreenConstraint.active = YES;
        self.thumbnailSliderController.view.alpha = 1.0;
        [self restartAutomaticControlHidingTimerIfNeeded];
    }
}

#pragma mark Private API

- (void)PT_setThumbnailSliderHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (hidden) {
        if ([self shouldHideThumbnailSlider]) {
            _thumbnailSliderHidden = YES;

            [self hideThumbnailSliderAnimated:animated];
        }
    } else {
        if ([self shouldShowThumbnailSlider]) {
            _thumbnailSliderHidden = NO;

            [self showThumbnailSliderAnimated:animated];
        }
    }
}

#pragma mark Page Indicator visibility

- (void)setPageIndicatorEnabled:(BOOL)enabled
{
    if (_pageIndicatorEnabled == enabled) {
        // No change.
        return;
    }
    
    _pageIndicatorEnabled = enabled;
    
    // Hide page indicator if disabled.
    if (!enabled) {
        [self setPageIndicatorHidden:YES animated:NO];
    }
}

- (void)setPageIndicatorHidden:(BOOL)hidden
{
    [self setPageIndicatorHidden:hidden animated:NO];
}

- (void)setPageIndicatorHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_pageIndicatorHidden == hidden) {
        // No change.
        return;
    }
    
    if (!hidden && ![self isPageIndicatorEnabled]) {
        // Page indicator is disabled.
        return;
    }
    
    [self willChangeValueForKey:PT_KEY(self, pageIndicatorHidden)];
    
    _pageIndicatorHidden = hidden;
    
    // Animation pre-amble.
    if (self.activePageIndicatorTransitionCount == 0) {
        if (hidden) {
            // No pre-amble.
        } else {
            // Show page indicator view in preparation for animation.
            self.pageIndicatorViewController.view.hidden = NO;
        }
    }
    
    NSTimeInterval duration = (animated) ? UINavigationControllerHideShowBarDuration : 0.0;
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // Animate page indicator view alpha: requires UIViewAnimationOptionBeginFromCurrentState.
        if (hidden) {
            self.pageIndicatorViewController.view.alpha = 0.0;
        } else {
            self.pageIndicatorViewController.view.alpha = 1.0;
        }
    } completion:^(BOOL finished) {
        self.activePageIndicatorTransitionCount--;
        
        // Animation post-amble.
        if (self.activePageIndicatorTransitionCount == 0) {
            // Check state at time of completion.
            if (self.pageIndicatorHidden) {
                // Hide page indicator view.
                self.pageIndicatorViewController.view.hidden = YES;
            } else {
                // No post-amble.
            }
        }
    }];
    
    self.activePageIndicatorTransitionCount++;
    
    [self didChangeValueForKey:PT_KEY(self, pageIndicatorHidden)];
    
    if (@available(iOS 11.0, *)) {
        [self updateChildViewControllerAdditionalSafeAreaInsets];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfPageIndicatorHidden
{
    return NO;
}

#pragma mark - Reflow view controller

- (void)setReflowHidden:(BOOL)hidden
{
    if (hidden == _reflowHidden) {
        // No change.
        return;
    }
    
    _reflowHidden = hidden;
    
    if (hidden) {
        [self PT_hideReflowController];
        
        PTDocumentViewSettingsManager *manager = PTDocumentViewSettingsManager.sharedManager;
        
        PTDocumentViewSettings *viewSettings;
        if (self.localDocumentURL) {
            viewSettings = [manager viewSettingsForDocumentAtURL:self.localDocumentURL];
        }
        
        if (!viewSettings) {
            viewSettings = manager.defaultViewSettings;
        }
        
        switch (viewSettings.pagePresentationMode) {
            case e_trn_single_page:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Single Page selected"];
                break;
            case e_trn_single_continuous:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Continuous selected"];
                break;
            case e_trn_facing:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Facing"];
                break;
            case e_trn_facing_continuous:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Facing Continuous"];
                break;
            case e_trn_facing_cover:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Cover Facing"];
                break;
            case e_trn_facing_continuous_cover:
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Cover Facing Continuous"];
                break;
        }        
    } else {
        [self PT_showReflowController];
        
        [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Viewer] Reader"];
    }
}

- (PTReflowViewControllerScrollingDirection)reflowScrollingDirectionForPagePresentationMode:(TrnPagePresentationMode)pagePresentationMode
{
    if (PTPagePresentationModeIsContinuous(pagePresentationMode)) {
        return PTReflowViewControllerScrollingDirectionVertical;
    } else {
        return PTReflowViewControllerScrollingDirectionHorizontal;
    }
}

- (void)PT_showReflowController
{
    self.searchButtonItem.enabled = NO;
    ((PTSelectableBarButtonItem*)self.readerModeButtonItem).selected = YES;
    
    // Update reflow scrolling direction for the current page presentation mode.
    self.reflowViewController.scrollingDirection = [self reflowScrollingDirectionForPagePresentationMode:self.pdfViewCtrl.pagePresentationMode];
    
    if (self.reflowViewController.view.superview) {
        // Reflow control already added to container view controller.
        self.reflowViewController.view.hidden = NO;
        return;
    }
    
    UIViewController *parentViewController = self.panelViewController.contentViewController;
    
    // View controller containment.
    [parentViewController addChildViewController:self.reflowViewController];
    
    self.reflowViewController.view.frame = parentViewController.view.bounds;
    self.reflowViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [parentViewController.view insertSubview:self.reflowViewController.view aboveSubview:self.pdfViewCtrl];
    
    [self.reflowViewController didMoveToParentViewController:parentViewController];
}

- (void)PT_hideReflowController
{
    self.searchButtonItem.enabled = YES;
    ((PTSelectableBarButtonItem*)self.readerModeButtonItem).selected = NO;
    
    if (!self.reflowViewController.parentViewController) {
        // Reflow controller not shown.
        return;
    }
    
    NSString* lastViewMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastViewMode"];
    [[NSUserDefaults standardUserDefaults] setObject:lastViewMode forKey:@"viewMode"];
    
    [self.reflowViewController willMoveToParentViewController:nil];
    
    [self.reflowViewController.view removeFromSuperview];
    
    [self.reflowViewController removeFromParentViewController];
}

#pragma mark - Automatic control hiding timer

-(void)setAutomaticallyHidesControls:(BOOL)automaticallyHidesControls
{
    [self setAutomaticallyHideToolbars:automaticallyHidesControls];
}

-(BOOL)automaticallyHidesControls
{
    return self.automaticallyHideToolbars;
}

- (void)setAutomaticallyHideToolbars:(BOOL)automaticallyHideToolbars
{
    if (_automaticallyHideToolbars == automaticallyHideToolbars) {
        return;
    }
    
    _automaticallyHideToolbars = automaticallyHideToolbars;
    
    if (automaticallyHideToolbars) {
        [self restartAutomaticControlHidingTimerIfNeeded];
    }
}

- (void)restartAutomaticControlHidingTimerIfNeeded
{
    if (self.viewIfLoaded.window) {
        [self restartAutomaticControlHidingTimer];
    }
}

- (void)restartAutomaticControlHidingTimer
{
    [self restartAutomaticControlHidingTimerWithDelay:self.automaticControlHidingDelay];
}

- (void)restartAutomaticControlHidingTimerWithDelay:(NSTimeInterval)delay
{
    // Stop previous timer.
    if (self.automaticControlHidingTimer) {
        [self stopAutomaticControlHidingTimer];
    }
    
    if (self.automaticControlHidingDelay != delay) {
        self.automaticControlHidingDelay = delay;
    }
    
    self.automaticControlHidingTimer = [PTTimer scheduledTimerWithTimeInterval:delay
                                                                        target:self
                                                                      selector:@selector(hideControlsWithTimer:)
                                                                      userInfo:nil
                                                                       repeats:NO];
}

- (void)stopAutomaticControlHidingTimer
{
    [self.automaticControlHidingTimer invalidate];
    self.automaticControlHidingTimer = nil;
}

#pragma mark Timer firing target

- (void)hideControlsWithTimer:(NSTimer *)timer
{
    if (self.automaticControlHidingTimer.timer != timer) {
        // Timer has been rescheduled.
        return;
    }
    
    if ([self shouldHideControlsFromTimer:timer]) {
        [self setControlsHidden:YES animated:YES];
    }
    
    // Hide the page indicator when shown while the controls are hidden (ie. after the page changes),
    // otherwise the page indicator will never go away in "fullscreen mode".
    if (self.pageIndicatorShowsWithControls) {
        [self setPageIndicatorHidden:YES animated:YES];
    }
    
    self.automaticControlHidingTimer = nil;
}

- (BOOL)shouldHideControlsFromTimer:(NSTimer *)timer
{
    return self.automaticallyHideToolbars;
}

#pragma mark - Last page read timer

- (void)startLastPageReadTimer
{
    if (self.lastPageReadTimer) {
        return;
    }
    
    // Save the last page after a short delay. The timer will wait for the run loop to
    // become idle (no user interaction, scroll, etc. occurring) before firing.
    // This prevents the page from being saved too often when changing pages quickly.
    self.lastPageReadTimer = [PTTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(saveLastReadPage:) userInfo:nil repeats:NO];
}

- (void)stopLastPageReadTimer
{
    [self.lastPageReadTimer invalidate];
    self.lastPageReadTimer = nil;
}

// Save the current page as the "last-read page" in response to a timer.
- (void)saveLastReadPage:(NSTimer *)timer
{
    if (self.lastPageReadTimer.timer != timer) {
        return;
    }
    
    self.lastPageReadTimer = nil;
    
    // Avoid saving last page when detached from window.
    if (!self.viewIfLoaded.window) {
        return;
    }
    
    // Record what page this document is on.
    NSString *filePath = self.documentURL.path ?: self.coordinatedDocument.fileURL.path;
    if (self.document && filePath) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        PTDocumentViewSettingsManager *manager = PTDocumentViewSettingsManager.sharedManager;
        
        [manager setLastReadPageNumber:self.pdfViewCtrl.currentPage
                      forDocumentAtURL:fileURL];
    }
}

#pragma mark - Keyboard shortcuts

-(void)goToPreviousPage{
    int currentPage = [self.pdfViewCtrl GetCurrentPage];
    if (currentPage > 1) {
        int newPage = currentPage - 1;
        if (newPage < 1) { newPage = 1; }

        [self.pdfViewCtrl SetCurrentPage:newPage];
    }
}

-(void)goToNextPage{
    int currentPage = [self.pdfViewCtrl GetCurrentPage];
    if (currentPage < [self.document GetPageCount]) {
        int newPage = currentPage + 1;
        if (newPage > [self.document GetPageCount]) { newPage = [self.document GetPageCount]; }

        [self.pdfViewCtrl SetCurrentPage:newPage];
    }
}

-(void)formFieldNextOrPrevious:(UIKeyCommand*)sender
{
    if( [self.toolManager.tool isKindOfClass:[PTFormFillTool class]] )
    {
        PTFormFillTool* formFillTool = (PTFormFillTool*)self.toolManager.tool;
        
        if( sender.modifierFlags & UIKeyModifierShift)
        {
            [formFillTool moveToPreviousField];
        }
        else
        {
            [formFillTool moveToNextField];
        }
    }
}

-(void)navigateDocument:(UIKeyCommand*)sender{
    if (self.toolManager.tool.currentAnnotation != nil && [self.toolManager.tool isKindOfClass:[PTAnnotEditTool class]]) {
        [(PTAnnotEditTool *)self.toolManager.tool deselectAnnotation];
    }

    double pageHeight = [[self.pdfViewCtrl.GetDoc GetPage:self.pdfViewCtrl.GetCurrentPage] GetPageHeight:e_ptcrop] * self.pdfViewCtrl.GetZoom;

    // Go To Page
    if ([sender.input isEqualToString:@"G"]){
        [self.pageIndicatorViewController presentGoToPageController];
        return;
    }

    // Up/Down Arrows
    if ([sender.input isEqualToString:UIKeyInputDownArrow]){
        if (sender.modifierFlags == UIKeyModifierCommand) {
            [self.pdfViewCtrl GotoLastPage];
            return;
        }
        if (self.pdfViewCtrl.GetPagePresentationMode == e_trn_single_continuous) {
            [self.pdfViewCtrl SetVScrollPos:self.pdfViewCtrl.GetVScrollPos+(pageHeight*0.1) Animated:NO];
        } else{
            [self goToNextPage];
        }
        return;
    }else if ([sender.input isEqualToString:UIKeyInputUpArrow]){
        if (sender.modifierFlags == UIKeyModifierCommand) {
            [self.pdfViewCtrl GotoFirstPage];
            return;
        }
        if (self.pdfViewCtrl.GetPagePresentationMode == e_trn_single_continuous) {
            [self.pdfViewCtrl SetVScrollPos:self.pdfViewCtrl.GetVScrollPos-(pageHeight*0.1) Animated:NO];
        } else{
            [self goToPreviousPage];
        }
        return;
    }

    // Space
    if ([sender.input isEqualToString:@" "]){
        // Scroll in continuous mode
        if (self.pdfViewCtrl.GetPagePresentationMode == e_trn_single_continuous) {
            if (sender.modifierFlags == UIKeyModifierShift) {
                [self.pdfViewCtrl SetVScrollPos:self.pdfViewCtrl.GetVScrollPos-pageHeight Animated:NO];
                return;
            }
            [self.pdfViewCtrl SetVScrollPos:self.pdfViewCtrl.GetVScrollPos+pageHeight Animated:NO];
            return;
        }

        // Change page in non-continuous modes
        if (sender.modifierFlags == UIKeyModifierShift) {
            [self goToPreviousPage];
            return;
        }
        [self goToNextPage];
    }

    // Left/Right Arrows
    if ([sender.input isEqualToString:UIKeyInputRightArrow]) {
        if (sender.modifierFlags == UIKeyModifierCommand) {
            [self.pdfViewCtrl GotoLastPage];
            return;
        }
        [self goToNextPage];
        return;
    } else if ([sender.input isEqualToString:UIKeyInputLeftArrow]) {
        if (sender.modifierFlags == UIKeyModifierCommand) {
            [self.pdfViewCtrl GotoFirstPage];
            return;
        }
        [self goToPreviousPage];
    }
}

-(void)zoomDocument:(UIKeyCommand*)sender{
    double currentZoom = self.pdfViewCtrl.GetZoom;
    if ([sender.input isEqualToString:@"+"] || [sender.input isEqualToString:@"="]) {
        [self.pdfViewCtrl SetZoom:MIN(currentZoom*1.3, self.pdfViewCtrl.GetZoomMaximumLimit)];
    }else if ([sender.input isEqualToString:@"-"]) {
        [self.pdfViewCtrl SetZoom:MAX(currentZoom*0.7, self.pdfViewCtrl.GetZoomMinimumLimit)];
    }else if ([sender.input isEqualToString:@"0"]) {
        [self.pdfViewCtrl SetPageViewMode:[self.pdfViewCtrl GetPageRefViewMode]];
    }
}

-(void)setViewModeContinuous:(UIKeyCommand*)sender{
    [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_continuous];
}

-(void)setViewModeSinglePage:(UIKeyCommand*)sender{
    [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_page];
}

-(void)setViewModeFacing:(UIKeyCommand*)sender{
    [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing];
}

-(void)setViewMode:(UIKeyCommand*)sender{
    int number = [sender.input intValue];
    switch (number) {
        case 1:
            [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_continuous];
            break;
        case 2:
            [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_page];
            break;
        case 3:
            [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing];
            break;
        case 4:
            [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing_cover];
            break;
        default:
            break;
    }
}

-(void)rotatePages:(UIKeyCommand*)sender{
    if ([sender.input isEqualToString:@"L"]) {
        [self.pdfViewCtrl RotateCounterClockwise];
    }else{
        [self.pdfViewCtrl RotateClockwise];
    }
}

-(void)showNavigationListsKBShortcut:(UIKeyCommand*)sender{
    int number = [sender.input intValue];
    switch (number) {
        case 3:
            self.navigationListsViewController.selectedViewController = self.navigationListsViewController.outlineViewController;
            break;
        case 4:
            self.navigationListsViewController.selectedViewController = self.navigationListsViewController.annotationViewController;
            break;
        case 5:
            self.navigationListsViewController.selectedViewController = self.navigationListsViewController.bookmarkViewController;
            break;
        default:
            break;
    }
    [self showNavigationLists];
}

- (BOOL)canBecomeFirstResponder{
    return YES;
}

- (NSArray<UIKeyCommand *> *)keyCommands
{
    if( [self.toolManager.tool isKindOfClass:[PTFormFillTool class]] && ![self isFirstResponder] )
    {
        // editing a form field
        UIKeyCommand *tab = [UIKeyCommand keyCommandWithInput:@"\t" modifierFlags:0 action:@selector(formFieldNextOrPrevious:)];
        
        UIKeyCommand *tabBack = [UIKeyCommand keyCommandWithInput:@"\t" modifierFlags:UIKeyModifierShift action:@selector(formFieldNextOrPrevious:)];
        
        return @[tab, tabBack];
    }
    
    // Only handle key commands when view controller is first responder and pan tool is active.
    // (ie. disable when creating/editing freetext, filling forms, etc.)
    if (![self isFirstResponder] || ![self.toolManager.tool isKindOfClass:[PTPanTool class]]) {
        return nil;
    }
    
    // Features
    UIKeyCommand *textSearch = [UIKeyCommand keyCommandWithInput:@"F" modifierFlags:UIKeyModifierCommand action:@selector(showSearchViewController) discoverabilityTitle:PTLocalizedString(@"Search", @"Text Search keyboard shortcut title")];

    // Navigation
    UIKeyCommand *nextPage = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(navigateDocument:) discoverabilityTitle:PTLocalizedString(@"Next Page", @"Next Page keyboard shortcut title")];
    UIKeyCommand *nextPageSpc = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:0 action:@selector(navigateDocument:)];

    UIKeyCommand *prevPage = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(navigateDocument:) discoverabilityTitle:PTLocalizedString(@"Previous Page", @"Previous Page keyboard shortcut title")];
    UIKeyCommand *prevPageSpc = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:UIKeyModifierShift action:@selector(navigateDocument:)];

    UIKeyCommand *firstPage = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:UIKeyModifierCommand action:@selector(navigateDocument:) discoverabilityTitle:PTLocalizedString(@"First Page", @"First Page keyboard shortcut title")];
    UIKeyCommand *lastPage = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:UIKeyModifierCommand action:@selector(navigateDocument:) discoverabilityTitle:PTLocalizedString(@"Last Page", @"Last Page keyboard shortcut title")];

    UIKeyCommand *goToPage = [UIKeyCommand keyCommandWithInput:@"G" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate action:@selector(navigateDocument:) discoverabilityTitle:PTLocalizedString(@"Go to Page", @"Go to Page keyboard shortcut title")];

    // Scrolling
    UIKeyCommand *scrollUp = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(navigateDocument:)];
    UIKeyCommand *scrollDown = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(navigateDocument:)];
    UIKeyCommand *scrollToTop = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand action:@selector(navigateDocument:)];
    UIKeyCommand *scrollToBottom = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand action:@selector(navigateDocument:)];

    // Interaction
    //UIKeyCommand *deleteAnnotation = [UIKeyCommand keyCommandWithInput:@"\b" modifierFlags:0 action:@selector(deleteSelectedAnnotation) discoverabilityTitle:PTLocalizedString(@"Delete Annotation", @"Delete Annotation keyboard shortcut title")];

    // Document
    UIKeyCommand *printDocument = [UIKeyCommand keyCommandWithInput:@"P" modifierFlags:UIKeyModifierCommand action:@selector(printDocumentShortcut) discoverabilityTitle:PTLocalizedString(@"Print Document", @"Print Document keyboard shortcut title")];

    // Zoom
    UIKeyCommand *zoomIn = [UIKeyCommand keyCommandWithInput:@"+" modifierFlags:UIKeyModifierCommand action:@selector(zoomDocument:) discoverabilityTitle:PTLocalizedString(@"Zoom In", @"Zoom In keyboard shortcut title")];
    UIKeyCommand *zoomInAlt = [UIKeyCommand keyCommandWithInput:@"=" modifierFlags:UIKeyModifierCommand action:@selector(zoomDocument:)];
    UIKeyCommand *zoomOut = [UIKeyCommand keyCommandWithInput:@"-" modifierFlags:UIKeyModifierCommand action:@selector(zoomDocument:) discoverabilityTitle:PTLocalizedString(@"Zoom Out", @"Zoom Out keyboard shortcut title")];
    UIKeyCommand *resetZoom = [UIKeyCommand keyCommandWithInput:@"0" modifierFlags:UIKeyModifierCommand action:@selector(zoomDocument:) discoverabilityTitle:PTLocalizedString(@"Reset Zoom", @"Reset Zoom keyboard shortcut title")];

    // View Modes
    UIKeyCommand *viewContinuous = [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierCommand action:@selector(setViewMode:) discoverabilityTitle:PTLocalizedString(@"Continuous", @"Continuous view mode keyboard shortcut title")];
    UIKeyCommand *viewSingle = [UIKeyCommand keyCommandWithInput:@"2" modifierFlags:UIKeyModifierCommand action:@selector(setViewMode:) discoverabilityTitle:PTLocalizedString(@"Single Page", @"Single Page view mode keyboard shortcut title")];
    UIKeyCommand *viewFacing = [UIKeyCommand keyCommandWithInput:@"3" modifierFlags:UIKeyModifierCommand action:@selector(setViewMode:) discoverabilityTitle:PTLocalizedString(@"Facing", @"Facing view mode keyboard shortcut title")];
    UIKeyCommand *viewCoverFacing = [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(setViewMode:) discoverabilityTitle:PTLocalizedString(@"Cover Facing", @"Cover Facing view mode keyboard shortcut title")];

    // Rotation
    UIKeyCommand *rotateLeft = [UIKeyCommand keyCommandWithInput:@"L" modifierFlags:UIKeyModifierCommand action:@selector(rotatePages:) discoverabilityTitle:PTLocalizedString(@"Rotate Pages Counterclockwise", @"Rotate Pages Counterclockwise keyboard shortcut title")];
    UIKeyCommand *rotateRight = [UIKeyCommand keyCommandWithInput:@"R" modifierFlags:UIKeyModifierCommand action:@selector(rotatePages:) discoverabilityTitle:PTLocalizedString(@"Rotate Pages Clockwise", @"Rotate Pages Clockwise keyboard shortcut title")];

    // Show Thumbnails
    UIKeyCommand *showThumbnails = [UIKeyCommand keyCommandWithInput:@"6" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate action:@selector(showThumbnailsController) discoverabilityTitle:PTLocalizedString(@"Show Thumbnails", @"Show Thumbnails keyboard shortcut title")];

    // Show Navigation List
    UIKeyCommand *showOutline = [UIKeyCommand keyCommandWithInput:@"3" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate action:@selector(showNavigationListsKBShortcut:) discoverabilityTitle:PTLocalizedString(@"Show Outline", @"Show Outline keyboard shortcut title")];
    UIKeyCommand *showAnnotations = [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate action:@selector(showNavigationListsKBShortcut:) discoverabilityTitle:PTLocalizedString(@"Show Annotations", @"Show Annotations keyboard shortcut title")];
    UIKeyCommand *showBookmarks = [UIKeyCommand keyCommandWithInput:@"5" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate action:@selector(showNavigationListsKBShortcut:) discoverabilityTitle:PTLocalizedString(@"Show Bookmarks", @"Show Bookmarks keyboard shortcut title")];

    return @[textSearch,
             nextPage, nextPageSpc, prevPage, prevPageSpc, lastPage, firstPage,
             scrollUp, scrollDown, scrollToTop, scrollToBottom,
             goToPage,
             //deleteAnnotation,
             printDocument,
             zoomIn, zoomInAlt, zoomOut, resetZoom,
             viewContinuous, viewSingle, viewFacing, viewCoverFacing,
             rotateLeft, rotateRight,
             showThumbnails, showOutline, showAnnotations, showBookmarks];
}

#pragma mark - Catalyst

#if TARGET_OS_MACCATALYST

#pragma mark - Hover Gesture

-(void)handleHover:(UIHoverGestureRecognizer*)gestureRecognizer{
    if (!PT_ToolsMacCatalyst) {
        return;
    }
    BOOL shouldUnlock = NO;
    CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
    double x = (double)down.x;
    double y = (double)down.y;
    BOOL textUnderCursor = NO;
    BOOL annotUnderCursor = NO;
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        int pageNum = [self.pdfViewCtrl GetPageNumberFromScreenPt:x y: y];
        if (pageNum >0) {
            if ([self.pdfViewCtrl WereWordsPrepared:pageNum]) {
                textUnderCursor = [self.pdfViewCtrl IsThereTextInRect:x-1 y1:y-1 x2:x+1 y2:y+1];
            }else{
                [self.pdfViewCtrl PrepareWords:pageNum];
            }

            if ([self.pdfViewCtrl WereAnnotsForMousePrepared:pageNum]) {
                annotUnderCursor = ([self.pdfViewCtrl GetAnnotTypeUnder:x y:y] != e_ptUnknown);
            }else{
                [self.pdfViewCtrl PrepareAnnotsForMouse:pageNum distance_threshold:22 minimum_line_weight:10];
            }
        }
        #if TARGET_OS_MACCATALYST
        if (annotUnderCursor && !self.toolManager.tool.nextToolType){
            [[NSCursor pointingHandCursor] set];
        }else if (textUnderCursor && !self.toolManager.tool.nextToolType) {
            [[NSCursor IBeamCursor] set];
        }else{
            [[NSCursor arrowCursor] set];
        }
        if (([self.toolManager.tool createsAnnotation] || self.toolManager.tool.nextToolType) && ![self.toolManager.tool.annotClass isSubclassOfClass:[PTTextMarkup class]]) {
            [[NSCursor crosshairCursor] set];
        }
        #endif
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
}

-(NSToolbar*)macToolbar {
    if (!_macToolbar){
        _macToolbar = [[NSToolbar alloc] initWithIdentifier:@"Toolbar"];
        _macToolbar.delegate = self;
        _macToolbar.allowsUserCustomization = YES;
    }
    return _macToolbar;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if ([itemIdentifier isEqual:self.navigationListsToolbarItem.itemIdentifier]) {
        return self.navigationListsToolbarItem;
    }
    if ([itemIdentifier isEqual:self.thumbnailsToolbarItem.itemIdentifier]) {
        return self.thumbnailsToolbarItem;
    }
    if ([itemIdentifier isEqual:self.freehandToolbarItem.itemIdentifier]) {
        return self.freehandToolbarItem;
    }
    if ([itemIdentifier isEqual:self.searchToolbarItem.itemIdentifier]) {
        return self.searchToolbarItem;
    }
    if ([itemIdentifier isEqual:self.reflowToolbarItem.itemIdentifier]) {
        return self.reflowToolbarItem;
    }
    if ([itemIdentifier isEqual:self.annotationToolbarItem.itemIdentifier]) {
        return self.annotationToolbarItem;
    }
    NSToolbarItem *toolBarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    return toolBarItem;
}

- (void)setToolbarDefaultItemIdentifiers:(NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers
{
    if (_toolbarDefaultItemIdentifiers == toolbarDefaultItemIdentifiers) {
        return;
    }
    _toolbarDefaultItemIdentifiers = [toolbarDefaultItemIdentifiers copy];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return self.toolbarDefaultItemIdentifiers;
}

- (void)setToolbarAllowedItemIdentifiers:(NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers
{
    if (_toolbarAllowedItemIdentifiers == toolbarAllowedItemIdentifiers) {
        return;
    }
    _toolbarAllowedItemIdentifiers = [toolbarAllowedItemIdentifiers copy];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return self.toolbarAllowedItemIdentifiers;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return @[self.reflowToolbarItem.itemIdentifier];
}

-(void)updateSelectedToolbarItem{
    NSToolbarItemIdentifier selectedID = nil;
    if (!self.reflowHidden){
        selectedID = self.reflowToolbarItem.itemIdentifier;
    }
    [self.macToolbar setSelectedItemIdentifier:selectedID];
}

@synthesize navigationListsToolbarItem = _navigationListsToolbarItem;

- (NSToolbarItem *)navigationListsToolbarItem
{
    if (!_navigationListsToolbarItem) {
        _navigationListsToolbarItem = [self toolbarItemFromBarButtonItem:self.navigationListsButtonItem
                                                  withIdentifier:PTLocalizedString(@"Sidebar", @"Sidebar toolbar item identifier")];
    }
    return _navigationListsToolbarItem;
}

@synthesize thumbnailsToolbarItem = _thumbnailsToolbarItem;
- (NSToolbarItem *)thumbnailsToolbarItem
{
    if (!_thumbnailsToolbarItem) {
        _thumbnailsToolbarItem = [self toolbarItemFromBarButtonItem:self.thumbnailsButtonItem
                                                     withIdentifier:PTLocalizedString(@"Thumbnails", @"Thumbnails toolbar item identifier")];
    }
    return _thumbnailsToolbarItem;
}

@synthesize searchToolbarItem = _searchToolbarItem;
- (NSToolbarItem *)searchToolbarItem
{
    if (!_searchToolbarItem) {
        _searchToolbarItem = [self toolbarItemFromBarButtonItem:self.searchButtonItem
                                                 withIdentifier:PTLocalizedString(@"Search", @"Search toolbar item identifier")];
    }
    return _searchToolbarItem;
}

@synthesize reflowToolbarItem = _reflowToolbarItem;
- (NSToolbarItem *)reflowToolbarItem
{
    if (!_reflowToolbarItem) {
        _reflowToolbarItem = [self toolbarItemFromBarButtonItem:self.readerModeButtonItem withIdentifier:PTLocalizedString(@"Reflow", @"Reflow toolbar item identifier")];
    }
    return _reflowToolbarItem;
}



-(NSToolbarItem*)toolbarItemFromBarButtonItem:(UIBarButtonItem*)barButtonItem withIdentifier:(NSToolbarItemIdentifier)identifier
{
    NSToolbarItem *item = [NSToolbarItem itemWithItemIdentifier:identifier barButtonItem:barButtonItem];
    item.label = identifier;
    item.title = nil;
    return item;
}

- (void)validateCommand:(UICommand *)command
{
    NSString *selector = NSStringFromSelector(command.action);
    if ([selector isEqualToString:@"showDocOutline:"]) {
        command.state = self.navigationListsViewController.outlineViewController.viewIfLoaded.window != nil;
    }else if ([selector isEqualToString:@"toggleReflow"]) {
        command.state = !self.isReflowHidden;
    }else if ([selector isEqualToString:@"showAnnotationList:"]) {
        command.state = self.navigationListsViewController.annotationViewController.viewIfLoaded.window != nil;
    }else if ([selector isEqualToString:@"showBookmarkList:"]) {
        command.state = self.navigationListsViewController.bookmarkViewController.viewIfLoaded.window != nil;
    }else if ([selector isEqualToString:@"showDocThumbnails:"]) {
        command.state = self.thumbnailsViewController.viewIfLoaded.window != nil;
    }else if ([selector isEqualToString:@"setViewModeContinuous:"]) {
        command.state = self.pdfViewCtrl.pagePresentationMode == e_trn_single_continuous;
    }else if ([selector isEqualToString:@"setViewModeSinglePage:"]) {
        command.state = self.pdfViewCtrl.pagePresentationMode == e_trn_single_page;
    }else if ([selector isEqualToString:@"setViewModeFacing:"]) {
        command.state = self.pdfViewCtrl.pagePresentationMode == e_trn_facing;
    }else if ([selector isEqualToString:@"goToFirstPage:"]) {
        command.attributes = [self.pdfViewCtrl GetCurrentPage] > 1 ? 0 : UIMenuElementAttributesDisabled;
    }else if ([selector isEqualToString:@"goToLastPage:"]) {
        command.attributes = [self.pdfViewCtrl GetCurrentPage] < [self.pdfViewCtrl GetPageCount] ? 0 : UIMenuElementAttributesDisabled;
    }else if ([selector isEqualToString:@"goToPage:"]) {
        command.attributes = [self.pdfViewCtrl GetPageCount] > 1 ? 0 : UIMenuElementAttributesDisabled;
    }else if ([selector isEqualToString:@"setToolToHighlight:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeHighlight] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTTextHighlightCreate class]];
    }else if ([selector isEqualToString:@"setToolToUnderline:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeUnderline] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTTextUnderlineCreate class]];
    }else if ([selector isEqualToString:@"setToolToStrikethrough:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeStrikeOut] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTTextStrikeoutCreate class]];
    }else if ([selector isEqualToString:@"setToolToRectangle:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeSquare] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTRectangleCreate class]];
    }else if ([selector isEqualToString:@"setToolToEllipse:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeCircle] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTEllipseCreate class]];
    }else if ([selector isEqualToString:@"setToolToLine:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeLine] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTLineCreate class]];
    }else if ([selector isEqualToString:@"setToolToArrow:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeArrow] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTArrowCreate class]];
    }else if ([selector isEqualToString:@"setToolToPolygon:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypePolygon] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTPolygonCreate class]];
    }else if ([selector isEqualToString:@"setToolToPolyline:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypePolyline] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTPolylineCreate class]];
    }else if ([selector isEqualToString:@"setToolToFreeText:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeFreeText] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTFreeTextCreate class]];
    }else if ([selector isEqualToString:@"setToolToNote:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeText] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTStickyNoteCreate class]];
    }else if ([selector isEqualToString:@"setToolToSignature:"]) {
        command.attributes = [self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeSignature] ? 0 : UIMenuElementAttributesDisabled;
        command.state = [self.toolManager.tool isKindOfClass:[PTDigitalSignatureTool class]];
    }
}

#pragma mark - UIMenu Configuration

-(UIMenu*)editMenu
{
    UIKeyCommand* copy = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Copy", @"Copy menu item title") image:Nil action:@selector(copyCommand:) input:@"C" modifierFlags:UIKeyModifierCommand propertyList:Nil];
    UIKeyCommand* paste = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Paste", @"Paste menu item title") image:Nil action:@selector(pasteAnnotations:) input:@"V" modifierFlags:UIKeyModifierCommand propertyList:Nil];
    return [UIMenu menuWithTitle:PTLocalizedString(@"Edit", @"Edit menu title") image:Nil identifier:nil options:UIMenuOptionsDisplayInline children:@[copy, paste]];
}

-(UIMenu*)navigationListsMenu
{
    UIKeyCommand* showOutline = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Table of Contents", @"Table of Contents menu item title") image:Nil action:@selector(showDocOutline:) input:@"3" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate propertyList:Nil];
    UIKeyCommand* showAnnotations = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Annotations", @"Annotations menu item title") image:Nil action:@selector(showAnnotationList:) input:@"4" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate propertyList:Nil];
    UIKeyCommand* showBookmarks = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Bookmarks", @"Bookmarks menu item title") image:Nil action:@selector(showBookmarkList:) input:@"5" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate propertyList:Nil];
    UIKeyCommand* showThumbnails = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Thumbnails", @"Thumbnails menu item title") image:Nil action:@selector(showDocThumbnails:) input:@"6" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate propertyList:Nil];

    return [UIMenu menuWithTitle:PTLocalizedString(@"Navigation Lists", @"Navigation Lists menu title") image:Nil identifier:nil options:UIMenuOptionsDisplayInline children:@[showOutline, showAnnotations, showBookmarks, showThumbnails]];
}

- (UIMenu *)viewModesMenu
{
    UIKeyCommand* continuous = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Continuous Scroll", @"Continuous Scroll menu item title") image:Nil action:@selector(setViewModeContinuous:) input:@"1" modifierFlags:UIKeyModifierCommand propertyList:Nil];
    UIKeyCommand* singlePage = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Single Page", @"Single Page menu item title") image:Nil action:@selector(setViewModeSinglePage:) input:@"2" modifierFlags:UIKeyModifierCommand propertyList:Nil];
    UIKeyCommand* twoPages = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Two Pages", @"Two Pages menu item title") image:Nil action:@selector(setViewModeFacing:) input:@"3" modifierFlags:UIKeyModifierCommand propertyList:Nil];

    return [UIMenu menuWithTitle:PTLocalizedString(@"View Modes Menu", @"View Modes menu title") image:Nil identifier:nil options:UIMenuOptionsDisplayInline children:@[continuous, singlePage, twoPages]];
}

- (UIMenu *)additionalViewMenu
{
    UIKeyCommand* readerModeCmd = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Reader Mode", @"Reader Mode menu item title") image:Nil action:@selector(toggleReflow) input:@"R" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift propertyList:Nil];

    return [UIMenu menuWithTitle:PTLocalizedString(@"Additional View Menu", @"Additional View menu title") image:Nil identifier:nil options:UIMenuOptionsDisplayInline children:@[readerModeCmd]];
}

-(UIMenu*)navigateDocMenu
{
    UIKeyCommand* navUp = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Up", @"Up menu item title") image:Nil action:@selector(navigateDocUp:) input:UIKeyInputUpArrow modifierFlags:0 propertyList:Nil];
    UIKeyCommand* navDown = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Down", @"Down menu item title") image:Nil action:@selector(navigateDocDown:) input:UIKeyInputDownArrow modifierFlags:0 propertyList:Nil];
    UIKeyCommand* goToFirstPageCmd = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Go to First Page", @"Go to First Page menu item title") image:Nil action:@selector(goToFirstPage:) input:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand propertyList:Nil];
    UIKeyCommand* goToLastPageCmd = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Go to Last Page", @"Go to Last Page menu item title") image:Nil action:@selector(goToLastPage:) input:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand propertyList:Nil];
    UIKeyCommand* goToPageCmd = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Go to Page…", @"Go to Page menu item title") image:Nil action:@selector(goToPage:) input:@"G" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate propertyList:Nil];

    return [UIMenu menuWithTitle:PTLocalizedString(@"Go", @"Go menu title") children:@[navUp, navDown, goToFirstPageCmd, goToLastPageCmd, goToPageCmd]];
}

-(UIMenu*)annotateMenu
{
    UIKeyCommand* setHighlightTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Highlight Text", @"Highlight Text menu item title") image:Nil action:@selector(setToolToHighlight:) input:@"H" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIKeyCommand* setUnderlineTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Underline Text", @"Underline Text menu item title") image:Nil action:@selector(setToolToUnderline:) input:@"U" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIKeyCommand* setStrikethroughTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Strikethrough Text", @"Strikethrough Text menu item title") image:Nil action:@selector(setToolToStrikethrough:) input:@"S" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIMenu *textMarkupMenu = [UIMenu menuWithTitle:PTLocalizedString(@"Text Markup", @"Text Markup menu title") image:Nil identifier:nil options:UIMenuOptionsDisplayInline children:@[setHighlightTool, setUnderlineTool, setStrikethroughTool]];

    UIKeyCommand* setRectangleTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Rectangle", @"Rectangle create menu item title") image:Nil action:@selector(setToolToRectangle:) input:@"R" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIKeyCommand* setEllipseTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Ellipse", @"Ellipse create menu item title") image:Nil action:@selector(setToolToEllipse:) input:@"O" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIKeyCommand* setLineTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Line", @"Line create menu item title") image:Nil action:@selector(setToolToLine:) input:@"L" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIKeyCommand* setArrowTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Arrow", @"Arrow create menu item title") image:Nil action:@selector(setToolToArrow:) input:@"A" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UICommand *setPolygonTool = [UICommand commandWithTitle:PTLocalizedString(@"Polygon", @"Polygon create menu item title") image:nil action:@selector(setToolToPolygon:) propertyList:nil];
    UICommand *setPolylineTool = [UICommand commandWithTitle:PTLocalizedString(@"Polyline", @"Polyline create menu item title") image:nil action:@selector(setToolToPolyline:) propertyList:nil];
    UIMenu *shapesMenu = [UIMenu menuWithTitle:PTLocalizedString(@"Shapes", @"Shapes menu title") image:Nil identifier:nil options:UIMenuOptionsDisplayInline children:@[setRectangleTool, setEllipseTool, setLineTool, setArrowTool, setPolygonTool, setPolylineTool]];

    UIKeyCommand* setTextTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Text", @"Text create menu item title") image:Nil action:@selector(setToolToFreeText:) input:@"T" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIKeyCommand* setNoteTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Note", @"Note create menu item title") image:Nil action:@selector(setToolToNote:) input:@"N" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIKeyCommand* setSignatureTool = [UIKeyCommand commandWithTitle:PTLocalizedString(@"Signature", @"Signature create menu item title") image:Nil action:@selector(setToolToSignature:) input:@"X" modifierFlags:UIKeyModifierCommand|UIKeyModifierControl propertyList:Nil];
    UIMenu *additionalAnnotMenu = [UIMenu menuWithTitle:PTLocalizedString(@"More Annotations", @"More Annotations menu title") image:Nil identifier:nil options:UIMenuOptionsDisplayInline children:@[setTextTool, setNoteTool, setSignatureTool]];

    return [UIMenu menuWithTitle:PTLocalizedString(@"Annotate", @"Annotate menu title") children:@[textMarkupMenu, shapesMenu, additionalAnnotMenu]];
}

#pragma mark - Edit Menu Commands

-(void)copyCommand:(UIKeyCommand*)sender{
    if (self.toolManager.tool.currentAnnotation != nil && [self.toolManager.tool isKindOfClass:[PTAnnotEditTool class]]) {
        NSArray<PTAnnot *> *annotations = ((PTAnnotEditTool *)self.toolManager.tool).selectedAnnotations;
        if (annotations.count == 0) {
            return;
        }

        [PTAnnotationPasteboard.defaultPasteboard copyAnnotations:annotations
                                                  withPDFViewCtrl:self.pdfViewCtrl
                                                   fromPageNumber:self.pdfViewCtrl.currentPage
                                                       completion:^{
            NSLog(@"Annotations were copied");
        }];
    }else if ([self.toolManager.tool isKindOfClass:[PTTextSelectTool class]]) {
        PTTextSelectTool *textSelectTool = (PTTextSelectTool *)self.toolManager.tool;
        int page1 = textSelectTool.selectionStartPageNumber;
        int page2 = textSelectTool.selectionEndPageNumber;
        __block NSMutableString* totalSelection = [[NSMutableString alloc] init];
        NSError* error;

        [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {

            for(int page = page1; page <= page2; page++)
            {
                PTPage* p = [doc GetPage:page];

                if( ![p IsValid] )
                {
                    return;
                }

                assert([p IsValid]);

                PTSelection* selection = [self.pdfViewCtrl GetSelection:page];
                NSString* pageString = [selection GetAsUnicode];
                [totalSelection appendString:pageString];
            }
        }
        error:&error];

        NSAssert(error == nil, @"could not get text");

        if( error )
        {
            return;
        }

        [UIPasteboard generalPasteboard].string = [totalSelection copy];
    }
}

-(void)pasteAnnotations:(UIKeyCommand*)sender{
    int pageNumber = [self.pdfViewCtrl GetCurrentPage];
    if (pageNumber < 1) {
        return;
    }
    NSArray<PTAnnot *> *annotations = PTAnnotationPasteboard.defaultPasteboard.annotations;
    if (annotations == nil) {
        return;
    }
    PTPDFRect *annotRect = annotations.firstObject.GetRect;
    int sourcePageNumber = PTAnnotationPasteboard.defaultPasteboard.sourcePageNumber;
    PTPDFPoint *pagePoint = [[PTPDFPoint alloc] initWithPx:annotRect.GetX1+(0.5*annotRect.Width) py:annotRect.GetY2-(0.5*annotRect.Height)];
    if (pageNumber == sourcePageNumber) {
        [pagePoint setX:pagePoint.getX+20];
        [pagePoint setY:pagePoint.getY-20];
    }

    [PTAnnotationPasteboard.defaultPasteboard pasteAnnotationsOnPageNumber:pageNumber atPagePoint:pagePoint withToolManager:self.toolManager completion:^(NSArray<PTAnnot *> * _Nullable pastedAnnotations, NSError * _Nullable error) {
        if (pastedAnnotations.count == 0) {
            return;
        }
        if ([self.toolManager.tool isKindOfClass:[PTPanTool class]]) {
            // Select the pasted annotations.
            ((PTPanTool*)self.toolManager.tool).currentAnnotation = pastedAnnotations.firstObject;
            ((PTPanTool*)self.toolManager.tool).annotationPageNumber = pageNumber;
        }

        PTTool *tool = [self.toolManager changeTool:[PTAnnotEditTool class]];
        if ([tool isKindOfClass:[PTAnnotEditTool class]]) {
            PTAnnotEditTool *editTool = (PTAnnotEditTool *)tool;
            editTool.selectedAnnotations = pastedAnnotations;
            [editTool selectAnnotation:editTool.selectedAnnotations.firstObject onPageNumber:pageNumber];
        }
    }];
}

#pragma mark - Toggle View Menu Commands

-(void)showNavigationListViewController:(UIViewController*)listViewController
{
    if ([self.panelViewController isLeadingPanelHidden] ||
        self.navigationListsViewController.selectedViewController == listViewController) {
//        [self showBookmarks:nil];
    }
    self.navigationListsViewController.selectedViewController = listViewController;
}

-(void)showDocOutline:(UIKeyCommand*)sender
{
    [self showNavigationListViewController:self.navigationListsViewController.outlineViewController];
}

-(void)showAnnotationList:(UIKeyCommand*)sender
{
    [self showNavigationListViewController:self.navigationListsViewController.annotationViewController];
}

-(void)showBookmarkList:(UIKeyCommand*)sender
{
    [self showNavigationListViewController:self.navigationListsViewController.bookmarkViewController];
}

-(void)showDocThumbnails:(UIKeyCommand*)sender
{
    [self showDocThumbnails];
}

-(void)showDocThumbnails
{
    if (self.thumbnailsViewController.viewIfLoaded.window != nil) {
//        [self hideViewControllers];
    }else{
        [self showThumbnailsController];
    }
}
#pragma mark - Navigate Doc Menu Commands

-(void)navigateDocUp:(id)anyObject
{
    NSError *error;
    __block double pageHeight;

    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        pageHeight = [[self.pdfViewCtrl.GetDoc GetPage:self.pdfViewCtrl.GetCurrentPage] GetPageHeight:e_ptcrop] * self.pdfViewCtrl.GetZoom;
    } error:&error];
    if (error) {
        return;
    }
    @try{
        if (self.pdfViewCtrl.pagePresentationMode == e_trn_single_continuous) {
            [self.pdfViewCtrl SetVScrollPos:self.pdfViewCtrl.GetVScrollPos-(pageHeight*0.1) Animated:NO];
        }else{
            int currentPage = [self.pdfViewCtrl GetCurrentPage];
            if (currentPage > 1) {
                int newPage = MAX(currentPage - 1, 1);
                [self.pdfViewCtrl SetCurrentPage:newPage];
            }
        }
    }
    @catch (NSException *exception) {
        // ignore
    }
}

-(void)navigateDocDown:(id)anyObject
{
    NSError *error;
    __block double pageHeight;

    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        pageHeight = [[self.pdfViewCtrl.GetDoc GetPage:self.pdfViewCtrl.GetCurrentPage] GetPageHeight:e_ptcrop] * self.pdfViewCtrl.GetZoom;
    } error:&error];
    if (error) {
        return;
    }

    @try{
        if (self.pdfViewCtrl.pagePresentationMode == e_trn_single_continuous) {
            [self.pdfViewCtrl SetVScrollPos:self.pdfViewCtrl.GetVScrollPos+(pageHeight*0.1) Animated:NO];
        }else{
            int currentPage = [self.pdfViewCtrl GetCurrentPage];
            if (currentPage < [self.pdfViewCtrl GetPageCount]) {
                int newPage = MIN(currentPage + 1, [self.pdfViewCtrl GetPageCount]);
                [self.pdfViewCtrl SetCurrentPage:newPage];
            }
        }
    }
    @catch (NSException *exception) {
        // ignore
    }
}

-(void)goToFirstPage:(id)anyObject
{
    @try {
        [self.pdfViewCtrl GotoFirstPage];
    }
    @catch (NSException *exception) {
        // ignore
    }
}

-(void)goToLastPage:(id)anyObject
{
    @try {
        [self.pdfViewCtrl GotoLastPage];
    }
    @catch (NSException *exception) {
        // ignore
    }
}

-(void)goToPage:(id)anyObject
{
    [self.pageIndicatorViewController presentGoToPageController];
}

#pragma mark - Annotate  Menu Commands

-(void)setToolToHighlight:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeHighlight]) {
        return;
    }
    if ([self.toolManager.tool isKindOfClass:[PTTextSelectTool class]]) {
        [(PTTextSelectTool*)self.toolManager.tool createTextMarkupAnnot:PTExtendedAnnotTypeHighlight];
    }
    PTTextHighlightCreate* thc = (PTTextHighlightCreate*)[self.toolManager changeTool:[PTTextHighlightCreate class]];
    thc.backToPanToolAfterUse = NO;
}

-(void)setToolToUnderline:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeUnderline]) {
        return;
    }
    if ([self.toolManager.tool isKindOfClass:[PTTextSelectTool class]]) {
        [(PTTextSelectTool*)self.toolManager.tool createTextMarkupAnnot:PTExtendedAnnotTypeUnderline];
    }
    PTTextUnderlineCreate* tuc = (PTTextUnderlineCreate*)[self.toolManager changeTool:[PTTextUnderlineCreate class]];
    tuc.backToPanToolAfterUse = NO;
}

-(void)setToolToStrikethrough:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeStrikeOut]) {
        return;
    }
    if ([self.toolManager.tool isKindOfClass:[PTTextSelectTool class]]) {
        [(PTTextSelectTool*)self.toolManager.tool createTextMarkupAnnot:PTExtendedAnnotTypeStrikeOut];
    }
    PTTextStrikeoutCreate* tsc = (PTTextStrikeoutCreate*)[self.toolManager changeTool:[PTTextStrikeoutCreate class]];
    tsc.backToPanToolAfterUse = NO;
}

-(void)setToolToRectangle:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeSquare]) {
        return;
    }
    PTRectangleCreate* rc = (PTRectangleCreate*)[self.toolManager changeTool:[PTRectangleCreate class]];
    rc.backToPanToolAfterUse = NO;
}

-(void)setToolToEllipse:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeCircle]) {
        return;
    }
    PTEllipseCreate* ec = (PTEllipseCreate*)[self.toolManager changeTool:[PTEllipseCreate class]];
    ec.backToPanToolAfterUse = NO;
}

-(void)setToolToLine:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeLine]) {
        return;
    }
    PTLineCreate* lc = (PTLineCreate*)[self.toolManager changeTool:[PTLineCreate class]];
    lc.backToPanToolAfterUse = NO;
}

-(void)setToolToArrow:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeArrow]) {
        return;
    }
    PTArrowCreate* ac = (PTArrowCreate*)[self.toolManager changeTool:[PTArrowCreate class]];
    ac.backToPanToolAfterUse = NO;
}

-(void)setToolToPolygon:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypePolygon]) {
        return;
    }
    PTPolygonCreate* pgc = (PTPolygonCreate*)[self.toolManager changeTool:[PTPolygonCreate class]];
    pgc.backToPanToolAfterUse = NO;
}

-(void)setToolToPolyline:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypePolyline]) {
        return;
    }
    PTPolylineCreate* plc = (PTPolylineCreate*)[self.toolManager changeTool:[PTPolylineCreate class]];
    plc.backToPanToolAfterUse = NO;
}

-(void)setToolToFreeText:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeFreeText]) {
        return;
    }
    PTFreeTextCreate* ftc = (PTFreeTextCreate*)[self.toolManager changeTool:[PTFreeTextCreate class]];
    ftc.backToPanToolAfterUse = NO;
}

-(void)setToolToNote:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeText]) {
        return;
    }
    PTStickyNoteCreate* snc = (PTStickyNoteCreate*)[self.toolManager changeTool:[PTStickyNoteCreate class]];
    snc.backToPanToolAfterUse = NO;
}

-(void)setToolToSignature:(id)anyObject
{
    if (![self.toolManager canCreateExtendedAnnotType:PTExtendedAnnotTypeSignature]) {
        return;
    }
    PTDigitalSignatureTool* dst = (PTDigitalSignatureTool*)[self.toolManager changeTool:[PTDigitalSignatureTool class]];
    dst.backToPanToolAfterUse = NO;
}
#endif

@end

@implementation PTDocumentBaseViewController (SubclassingHooks)

- (void)didOpenDocument
{
    
}

- (void)handleDocumentOpeningFailureWithError:(NSError *)error
{
    
}

- (void)didBecomeInvalid
{
    
}

- (BOOL)shouldExportCachedDocumentAtURL:(NSURL *)cachedDocumentURL
{
    return YES;
}

- (NSURL *)destinationURLforDocumentAtURL:(NSURL *)url
{
    return nil;
}

- (BOOL)shouldDeleteCachedDocumentAtURL:(NSURL *)cachedDocumentURL
{
    return NO;
}

- (BOOL)shouldHideControls
{
    return [self shouldHideSystemBars];
}

- (BOOL)shouldShowControls
{
    return [self shouldShowSystemBars];
}

@end
