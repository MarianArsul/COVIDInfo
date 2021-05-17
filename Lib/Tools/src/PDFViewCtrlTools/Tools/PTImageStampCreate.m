//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTImageStampCreate.h"

#import "PTToolsUtil.h"

#import "UIView+PTAdditions.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface PTImageStampCreate () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, strong, nullable) PTPDFPoint *touchPtPage;
@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTImageStampCreate

@dynamic isPencilTouch;

- (Class)annotClass
{
    return [PTRubberStamp class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeImageStamp;
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
    self.touchPtPage = [self.pdfViewCtrl ConvScreenPtToPagePt:[[PTPDFPoint alloc] initWithPx:self.endPoint.x py:self.endPoint.y] page_num:_pageNumber];
    
    [self chooseImageSource];

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
        self.touchPtPage = [self.pdfViewCtrl ConvScreenPtToPagePt:[[PTPDFPoint alloc] initWithPx:self.endPoint.x py:self.endPoint.y] page_num:_pageNumber];

        [self chooseImageSource];
        
        // Handled (stay in current tool).
        return YES;
    }
}

- (void)stampImage:(UIImage *)image atPoint:(CGPoint)point
{
    BOOL hasWriteLock = NO;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        hasWriteLock = YES;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];

        _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:point.x y:point.y];
        
        PTPage* page = [doc GetPage:self.pageNumber];

        PTPDFRect* stampRect = [[PTPDFRect alloc] initWithX1:0 y1:0 x2:image.size.width y2:image.size.height];
        double maxWidth = 300;
        double maxHeight = 300;
        
        PTRotate ctrlRotation = [self.pdfViewCtrl GetRotation];
        PTRotate pageRotation = [page GetRotation];
        PTRotate viewRotation = ((pageRotation + ctrlRotation) % 4);

        PTPDFRect* pageCropBox = [page GetCropBox];
        
        if ([pageCropBox Width] < maxWidth)
        {
            maxWidth = [pageCropBox Width];
        }
        if ([pageCropBox Height] < maxHeight)
        {
            maxHeight = [pageCropBox Height];
        }
        
        if (viewRotation == e_pt90 || viewRotation == e_pt270) {
            // Swap width and height if visible page is rotated 90 or 270 degrees
            maxWidth = maxWidth + maxHeight;
            maxHeight = maxWidth - maxHeight;
            maxWidth = maxWidth - maxHeight;
        }

        CGFloat scaleFactor = MIN(maxWidth / [stampRect Width], maxHeight / [stampRect Height]);
        CGFloat stampWidth = [stampRect Width] * scaleFactor;
        CGFloat stampHeight = [stampRect Height] * scaleFactor;
        
        if (ctrlRotation == e_pt90 || ctrlRotation == e_pt270) {
            // Swap width and height if pdfViewCtrl is rotated 90 or 270 degrees
            stampWidth = stampWidth + stampHeight;
            stampHeight = stampWidth - stampHeight;
            stampWidth = stampWidth - stampHeight;
        }

        PTStamper* stamper = [[PTStamper alloc] initWithSize_type:e_ptabsolute_size a:stampWidth b:stampHeight];
        [stamper SetAlignment:e_pthorizontal_left vertical_alignment:e_ptvertical_bottom];
        [stamper SetAsAnnotation:YES];
        
        // Account for page rotation in the page-space touch point
        PTMatrix2D *mtx = [page GetDefaultMatrix:NO box_type:e_ptcrop angle:0];

        self.touchPtPage = [self.pdfViewCtrl ConvScreenPtToPagePt:[[PTPDFPoint alloc] initWithPx:point.x py:point.y] page_num:self.pageNumber];
        self.touchPtPage = [mtx Mult:self.touchPtPage];
        
        CGFloat xPos = [self.touchPtPage getX] - (stampWidth / 2);
        CGFloat yPos = [self.touchPtPage getY] - (stampHeight / 2);

        double pageWidth = [[page GetCropBox] Width];
        if (xPos > pageWidth - stampWidth)
        {
            xPos = pageWidth - stampWidth;
        }
        if (xPos < 0)
        {
            xPos = 0;
        }
        double pageHeight = [[page GetCropBox] Height];
        if (yPos > pageHeight - stampHeight)
        {
            yPos = pageHeight - stampHeight;
        }
        if (yPos < 0)
        {
            yPos = 0;
        }
        
        [stamper SetPosition:xPos vertical_distance:yPos use_percentage:NO];
        
        PTPageSet* pageSet = [[PTPageSet alloc] initWithOne_page:self.pageNumber];
        
        NSData* data = UIImagePNGRepresentation(image);
        
        PTObjSet* hintSet = [[PTObjSet alloc] init];
        PTObj* encoderHints = [hintSet CreateArray];

        NSString *compressionAlgorithm = @"Flate";
        NSInteger compressionQuality = 5;
        [encoderHints PushBackName:compressionAlgorithm];
        if ([compressionAlgorithm isEqualToString:@"Flate"]) {
            [encoderHints PushBackName:@"Level"];
            [encoderHints PushBackNumber:compressionQuality];
        }

        PTImage* stampImage = [PTImage CreateWithDataSimple:[doc GetSDFDoc] buf:data buf_size:data.length encoder_hints:encoderHints];

        // Rotate stamp based on the pdfViewCtrl's rotation
        PTRotate stampRotation = (4 - viewRotation) % 4; // 0 = 0, 90 = 1; 180 = 2, and 270 = 3
        [stamper SetRotation:stampRotation * 90.0];
        [stamper StampImage:doc src_img:stampImage dest_pages:pageSet];
        
        int numAnnots = [page GetNumAnnots];
        
        assert(numAnnots > 0);
        
        PTAnnot* annot = [page GetAnnot:numAnnots - 1];
        PTObj* obj = [annot GetSDFObj];
        [obj PutString:PTImageStampAnnotationIdentifier value:@""];
        [obj PutNumber:PTImageStampAnnotationRotationDegreeIdentifier value:0.0];

        // Set up to transfer to PTAnnotEditTool
        self.currentAnnotation = annot;
        [self.currentAnnotation RefreshAppearance];
        
        self.annotationPageNumber = self.pageNumber;
        
        [self.pdfViewCtrl UpdateWithAnnot:annot page_num:self.pageNumber];
        
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

-(UIImage*)correctForRotation:(UIImage*)src
{
    UIGraphicsBeginImageContext(src.size);
    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    UIImage* img =  UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void)chooseImageSource
{
    // Show an action sheet to select the image source.
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:PTLocalizedString(@"Add Image",
                                                                                                       @"Add Image action sheet title")
                                                                             message:PTLocalizedString(@"Select an image source:",
                                                                                                       @"Add Image action sheet message")
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    // "Camera" action - only shown if available.
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [alertController addAction:[UIAlertAction actionWithTitle:PTLocalizedString(@"Camera",
                                                                                    @"Camera action title")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    
    // "Photo Library" action - only shown if available (library is not empty).
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [alertController addAction:[UIAlertAction actionWithTitle:PTLocalizedString(@"Photo Library",
                                                                                    @"Photo Library action title")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }]];
    }
    
    // "Files" action.
    [alertController addAction:[UIAlertAction actionWithTitle:PTLocalizedString(@"Files",
                                                                                @"Files action title")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [self showDocumentPicker];
    }]];
    
    // "Cancel" action.
    [alertController addAction:[UIAlertAction actionWithTitle:PTLocalizedString(@"Cancel",
                                                                                @"Cancel action title")
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull action) {
        // Cancel button pressed, or tapped outside alert controller.
        [self.toolManager createSwitchToolEvent:self.defaultClass];
    }]];
    
    UIPopoverPresentationController *popoverController =  alertController.popoverPresentationController;
    popoverController.sourceView = self.pdfViewCtrl;
    popoverController.sourceRect = CGRectMake(self.endPoint.x, self.endPoint.y, 1, 1);
    
    [self.pt_viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    self.image = [self correctForRotation:info[UIImagePickerControllerOriginalImage]];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self stampImage:self.image atPoint:self.endPoint];
    // Trigger switch event to default class.
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    // Show an image picker for the specified source type (camera, photos library).
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;

    // Camera is shown fullscreen, photos as popover on iPad.
    if (sourceType != UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popController = imagePickerController.popoverPresentationController;
        popController.delegate = self;
        popController.sourceRect = CGRectMake(self.endPoint.x, self.endPoint.y, 1, 1);
        popController.sourceView = self.pdfViewCtrl;
    }
    
    [self.pt_viewController presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - <UIDocumentPickerDelegate>

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(nonnull NSArray<NSURL *> *)urls
{
    NSURL *url = urls.firstObject;
    if (url) {
        // UIDocumentPickerViewController returns security-scoped URLs, which could be outside the
        // app's sandbox.
        [url startAccessingSecurityScopedResource];
        
        UIImage *rawImage = [UIImage imageWithContentsOfFile:url.path];
        
        if (rawImage) {
            self.image = [self correctForRotation:rawImage];
            [self stampImage:self.image atPoint:self.endPoint];
        }
        
        [url stopAccessingSecurityScopedResource];
    }
    
    // Trigger switch event to default class.
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

- (void)showDocumentPicker
{
    // Show a document picker for image files.
    UIDocumentPickerViewController *controller = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(__bridge NSString *)kUTTypeImage] inMode:UIDocumentPickerModeOpen];
    controller.delegate = self;
    
    controller.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverController = controller.popoverPresentationController;
    popoverController.delegate = self;
    popoverController.sourceView = self.pdfViewCtrl;
    popoverController.sourceRect = CGRectMake(self.endPoint.x, self.endPoint.y, 1, 1);
    
    [self.pt_viewController presentViewController:controller animated:YES completion:nil];
}

#pragma mark - <UIAdaptivePresentationControllerDelegate>

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

@end
