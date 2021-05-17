//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFileAttachmentCreate.h"

#import "UIView+PTAdditions.h"

#import <MobileCoreServices/MobileCoreServices.h>

static const int PTFileAttachmentCreate_iconWidth = 14;
static const int PTFileAttachmentCreate_iconHeight = 34;

@interface PTFileAttachmentCreate () <UIDocumentPickerDelegate>

@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTFileAttachmentCreate

@dynamic isPencilTouch;

//- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
//{
//    self = [super initWithPDFViewCtrl:pdfViewCtrl];
//    if (self) {
//
//    }
//    return self;
//}

- (Class)annotClass
{
    return [PTFileAttachment class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeFileAttachment;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    
    if( !(self.isPencilTouch == YES || self.toolManager.annotationsCreatedWithPencilOnly == NO) )
    {
        return YES;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.pdfViewCtrl];
    
    int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:touchPoint.x y:touchPoint.y];
    if (pageNumber < 1) {
        return YES;
    }
    // Save page number for touch point.
    _pageNumber = pageNumber;
    self.endPoint = touchPoint;
    
    [self showDocumentPicker];
    
    // Tap handled.
    return YES;
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    if (userData && userData == self.defaultClass) {
        // Switch to default tool class.
        self.nextToolType = self.defaultClass;
        return NO;
    } else {
        // Coming from long-press in PanTool.
        self.endPoint = self.longPressPoint;
        _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.endPoint.x y:self.endPoint.y];
        
        [self showDocumentPicker];
        
        // Handled (stay in current tool).
        return YES;
    }
}

- (void)showDocumentPicker
{
    // Show document picker for all file types.
    NSArray<NSString *> *documentTypes = @[(__bridge NSString *)kUTTypeContent];
    
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    
    // Disable multi-selection.
    if (@available(iOS 11.0, *)) {
        documentPicker.allowsMultipleSelection = NO;
    }
    
    [self.pt_viewController presentViewController:documentPicker animated:YES completion:nil];
}

- (void)createAttachmentWithFileURL:(NSURL *)url
{
    if (!url || self.pageNumber < 1) {
        return;
    }
    
    BOOL hasWriteLock = NO;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        hasWriteLock = YES;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        PTPage *page = [doc GetPage:self.pageNumber];
        if (![page IsValid]) {
            return;
        }
        
        CGPoint pagePoint = [self convertScreenPtToPagePt:self.endPoint onPageNumber:self.pageNumber];

        PTPDFRect *annotRect = [[PTPDFRect alloc] initWithX1:pagePoint.x y1:pagePoint.y
                                                          x2:pagePoint.x+PTFileAttachmentCreate_iconWidth y2:pagePoint.y+PTFileAttachmentCreate_iconHeight];
        [annotRect Normalize];
        
        PTFileAttachment *fileAttachment = [PTFileAttachment CreateFileAttchWithPath:[doc GetSDFDoc]
                                                                                 pos:annotRect
                                                                                path:url.path
                                                                           icon_name:e_ptPaperclip];
        // Only store file name in annotation.
        [fileAttachment SetContents:url.lastPathComponent];
        
        [fileAttachment RefreshAppearance];
        
        // Set annotation author on annotation.
        if (self.annotationAuthor.length > 0) {
            [fileAttachment SetTitle:self.annotationAuthor];
        }
        
        [page AnnotPushBack:fileAttachment];

        self.currentAnnotation = fileAttachment;
        self.annotationPageNumber = self.pageNumber;
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (hasWriteLock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    
    if (self.currentAnnotation && self.annotationPageNumber > 0) {
        [self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    }
}

- (void)didPickDocumentAtURL:(NSURL *)url
{
    if ([url isFileURL]) {
        [self createAttachmentWithFileURL:url.filePathURL];
    }
    
    // Trigger switch event to default class.
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

#pragma mark - <UIDocumentPickerDelegate>

PT_IGNORE_WARNINGS_BEGIN("deprecated-implementations")
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    [self didPickDocumentAtURL:url];
}
PT_IGNORE_WARNINGS_END

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    [self didPickDocumentAtURL:urls.firstObject];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    // Trigger switch event to default class.
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

@end
