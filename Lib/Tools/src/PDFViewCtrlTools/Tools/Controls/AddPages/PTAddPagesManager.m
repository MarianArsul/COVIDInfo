//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <AVFoundation/AVFoundation.h>
#import "PTAddPagesManager.h"
#import "ToolsConfig.h"
#import "PTPageTemplateViewController.h"

#import "UIColor+PTHexString.h"
#import "UIColor+PTEquality.h"

@interface PTAddPagesManager () <PTPageTemplateViewControllerDelegate>

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, strong) PTPageTemplateViewController *pageTemplateViewController;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIDocumentPickerViewController *documentPickerViewController;

@property (nonatomic, copy, nullable) NSString *documentPassword;

@end

@implementation PTAddPagesManager

#pragma mark - Initializers

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [super init];
    if (self) {
        _toolManager = toolManager;
        _pdfViewCtrl = toolManager.pdfViewCtrl;
        _pageNumber = _pdfViewCtrl.GetCurrentPage;
    }
    return self;
}

#pragma mark - View Controllers

- (PTPageTemplateViewController *)pageTemplateViewController{
    if (!_pageTemplateViewController) {
        _pageTemplateViewController = [[PTPageTemplateViewController alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
        _pageTemplateViewController.delegate = self;
    }
    return _pageTemplateViewController;
}

- (UIImagePickerController *)imagePickerController{
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
    }
    return _imagePickerController;
}

- (UIDocumentPickerViewController *)documentPickerViewController{
    if (!_documentPickerViewController) {
        _documentPickerViewController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.adobe.pdf"] inMode:UIDocumentPickerModeImport];
        _documentPickerViewController.delegate = self;
    }
    return _documentPickerViewController;
}

#pragma mark - Actions

-(void)showPageTemplateViewController
{
    NSMutableDictionary<NSString* ,NSValue *> *pageSizes = [self.pageTemplateViewController.pageSizes mutableCopy];
    NSString *prevPageSizeString = PTLocalizedString(@"Previous Page", @"Current document previous page type string");
    CGSize pageSize = [self getPageSizeInInches:self.pageNumber];
    [pageSizes setValue:[NSValue valueWithCGSize:pageSize] forKey:prevPageSizeString];
    [self.pageTemplateViewController setPageSizes:[pageSizes copy]];
    [self.pageTemplateViewController setDefaultPageSize:prevPageSizeString];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.pageTemplateViewController];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self.presentingViewController presentViewController:nav animated:YES completion:nil];
    }];
}

- (void)showDocumentPickerViewController
{
    self.documentPickerViewController.modalPresentationStyle = UIModalPresentationPopover;
    if (self.barButtonItem) {
        self.documentPickerViewController.popoverPresentationController.barButtonItem = self.barButtonItem;
    }else if (_sourceView){
        self.documentPickerViewController.popoverPresentationController.sourceView = self.sourceView;
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self.presentingViewController presentViewController:self.documentPickerViewController animated:YES completion:nil];
    }];
}

- (void)showImagePickerController
{
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
    if (self.barButtonItem) {
        self.imagePickerController.popoverPresentationController.barButtonItem = self.barButtonItem;
    }else if (self.sourceView){
        self.imagePickerController.popoverPresentationController.sourceView = self.sourceView;
    }
    if (self.presentingViewController.presentedViewController) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [self.presentingViewController presentViewController:self.imagePickerController animated:YES completion:nil];
        }];
    }else{
        [self.presentingViewController presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

-(void)showCamera{
    __block BOOL shouldShowCamera = NO;
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                shouldShowCamera = granted;
                if (shouldShowCamera) {
                    [self presentCamera];
                    return;
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            shouldShowCamera = YES;
            [self presentCamera];
            return;
        }
        default:
            break;
    }

    if (!shouldShowCamera) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:PTLocalizedString(@"Camera access is not authorized for this app", @"")
                                              message:PTLocalizedString(@"Camera access can be enabled in Settings", @"")
                                              preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Cancel", @"")
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

        UIAlertAction *goToSettingsAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Settings", @"")
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * _Nonnull action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([UIApplication.sharedApplication canOpenURL:settingsURL]) {
                [UIApplication.sharedApplication openURL:settingsURL options:[NSDictionary dictionary] completionHandler:nil];
            }
        }];

        [alertController addAction:cancelAction];
        [alertController addAction:goToSettingsAction];
        if (self.presentingViewController.presentedViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
            }];
        }else{
            [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
        }
    }
}

-(void)presentCamera{
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    self.imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;

    dispatch_async( dispatch_get_main_queue(), ^{
        if (self.presentingViewController.presentedViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [self.presentingViewController presentViewController:self.imagePickerController animated:YES completion:nil];
            }];
        }else{
            [self.presentingViewController presentViewController:self.imagePickerController animated:YES completion:nil];
        }
    });
}

#pragma mark - Delegate Methods

- (void)pageTemplateViewControllerDidCancel:(PTPageTemplateViewController *)pageTemplateViewController
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pageTemplateViewController:(PTPageTemplateViewController *)pageTemplateViewController createdDoc:(PTPDFDoc *)newDoc
{
    self.pageNumber = pageTemplateViewController.pageNumber;
    [self addPagesFromDoc:newDoc];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    NSURL *docURL = urls.firstObject;
    PTPDFDoc *pickedDoc = [[PTPDFDoc alloc] initWithFilepath:docURL.path];
    [self addPagesFromDoc:pickedDoc];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        // correct for rotation
        UIGraphicsBeginImageContext(image.size);
        [image drawAtPoint:CGPointMake(0, 0)];
        image =  UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self addImageAsPage:image];
    }];
}

#pragma mark - Adding Pages

-(void)addPagesFromDoc:(PTPDFDoc*)srcDoc
{
    if (![srcDoc InitSecurityHandler]){
        if ( !self.documentPassword || ![srcDoc InitStdSecurityHandler:self.documentPassword]) {
            NSLog(@"document locked!");
            [self unlockNewDoc:srcDoc];
            return;
        }
    }
    PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        int addPageIdx = self.pageNumber;
        [doc InsertPages:addPageIdx+1 src_doc:srcDoc start_page:1 end_page:[srcDoc GetPageCount] flag:e_ptinsert_none];
        for (int n = 0; n < [srcDoc GetPageCount]; n++) {
            int pageNumber = addPageIdx+1+n;
            [self.toolManager pageAddedForPageNumber:pageNumber];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    [self.pdfViewCtrl UpdatePageLayout];
    [self.pdfViewCtrl SetCurrentPage:self.pageNumber+1];
}

- (void)addImageAsPage:(UIImage *)image
{
    CGSize imageSize = image.size;
    CGSize maxSize = [self getPageSizeInInches:self.pageNumber];
    maxSize = CGSizeMake(maxSize.width*72, maxSize.height*72);
    PTPDFDoc *newDoc = [[PTPDFDoc alloc] init];
    BOOL shouldUnlock = NO;
    @try
    {
        [newDoc Lock];
        shouldUnlock = YES;
        CGFloat maxDimension = MAX(maxSize.width, maxSize.height);
        CGFloat scaleFactor = MAX(imageSize.width, imageSize.height)/maxDimension;
        
        if (scaleFactor > 1) {
            imageSize.width/=scaleFactor;
            imageSize.height/=scaleFactor;
            UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
            [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            image = newImage;
        }
        
        NSData* data = UIImageJPEGRepresentation(image, 0.7);
        PTObjSet* hintSet = [[PTObjSet alloc] init];
        PTObj* encoderHints = [hintSet CreateArray];
        
        NSString *compressionAlgorithm = @"JPEG";
        NSInteger compressionQuality = 60;
        [encoderHints PushBackName:compressionAlgorithm];
        [encoderHints PushBackName:@"Quality"];
        [encoderHints PushBackNumber:compressionQuality];
        PTImage* stampImage = [PTImage CreateWithDataSimple:[newDoc GetSDFDoc] buf:data buf_size:data.length encoder_hints:encoderHints];
        
        PTStamper* stamper = [[PTStamper alloc] initWithSize_type:e_ptrelative_scale a:1.0 b:1.0];
        [stamper SetAlignment:e_pthorizontal_left vertical_alignment:e_ptvertical_bottom];
        [stamper SetPosition:0 vertical_distance:0 use_percentage:YES];
        [stamper SetAsAnnotation:NO];
        [stamper SetAsBackground:YES];
        
        PTPDFRect *newRect = [[PTPDFRect alloc] initWithX1:0 y1:0 x2:imageSize.width y2:imageSize.height];
        PTPage* newPage = [newDoc PageCreate:newRect];
        [newDoc PageInsert:[newDoc GetPageIterator:1] page:newPage];
        PTPageSet* pageSet = [[PTPageSet alloc] initWithOne_page:1];
        [stamper StampImage:newDoc src_img:stampImage dest_pages:pageSet];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [newDoc Unlock];
        }
    }
    [self addPagesFromDoc:newDoc];
}

#pragma mark - Helpers

-(CGSize)getPageSizeInInches:(int)pageNumber{
    PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
    BOOL shouldUnlock = NO;
    CGSize pageSize;
    int refPageNumber = MAX(pageNumber, 1);
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        PTPage* refPage = [doc GetPage:refPageNumber];
        pageSize = CGSizeMake([refPage GetCropBox].Width/72.0, [refPage GetCropBox].Height/72.0);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    return pageSize;
}

-(void)unlockNewDoc:(PTPDFDoc*)doc
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:PTLocalizedString(@"Document is Encrypted", @"")
                                          message:PTLocalizedString(@"Please enter the password to add pages from this document", @"")
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Cancel", @"")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
    }];
    
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK", @"")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        NSString* newPassword = alertController.textFields.firstObject.text;
        self.documentPassword = newPassword;
        BOOL unlocked = NO;
        @try {
            unlocked = [doc InitStdSecurityHandler:self.documentPassword];
        }
        @catch (NSException *exception) {
            PTLog(@"Exception: %@ reason: %@", exception.name, exception.reason);
        }
        if (unlocked) {
            [self addPagesFromDoc:doc];
        } else {
            [self unlockNewDoc:doc];
        }
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:addAction];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = PTLocalizedString(@"Password", @"Encrypted document password");
        textField.secureTextEntry = YES;
    }];
    [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Blank Doc Creation

+ (UIColor *)whitePageColor{
    return [UIColor pt_colorWithHexString:@"#FFFFFF"];
}

+ (UIColor *)yellowPageColor
{
    return [UIColor pt_colorWithHexString:@"#FFFF99"];
}

+ (UIColor *)blueprintPageColor
{
    return [UIColor pt_colorWithHexString:@"#001484"];
}

+ (PTPDFDoc *)createDocWithTemplate:(PTPageTemplateStyle)pageTemplate pageSize:(CGSize)pageSize backgroundColor:(UIColor *)backgroundColor pageCount:(int)pageCount portrait:(BOOL)portrait
{
    PTPDFDoc *newDoc;
    double width =  pageSize.width;
    double height = pageSize.height;
    BOOL flipDimensions = (portrait && width > height) || (!portrait && width < height);
    if (flipDimensions) {
        width = width + height;
        height = width - height;
        width = width - height;
    }
    CGFloat red,green,blue;
    [backgroundColor getRed:&red green:&green blue:&blue alpha:nil];
    BOOL isBlueprint = [backgroundColor pt_isEqualToColor:PTAddPagesManager.blueprintPageColor];
    double lineShade = isBlueprint ? 0.85 : 0.35;
    double marginRed = 1.0;
    double marginGreen = 0.5;
    double marginBlue = 0.5;
    
    switch (pageTemplate) {
        case PTPageTemplateStyleBlank: // Blank
            newDoc = [PTPDFDocGenerator GenerateBlankPaperDoc:width height:height background_red:red background_green:green background_blue:blue];
            break;
        case PTPageTemplateStyleLined:{ // Lined
            double leftMarginR = [backgroundColor pt_isEqualToColor:PTAddPagesManager.whitePageColor] ? marginRed : lineShade*0.7;
            double leftMarginG = [backgroundColor pt_isEqualToColor:PTAddPagesManager.whitePageColor] ? marginGreen : lineShade*0.7;
            double leftMarginB = [backgroundColor pt_isEqualToColor:PTAddPagesManager.whitePageColor] ? marginBlue : lineShade*0.7;
            
            double rightMarginR = [backgroundColor pt_isEqualToColor:PTAddPagesManager.whitePageColor] ? marginRed : lineShade*0.45;
            double rightMarginG = [backgroundColor pt_isEqualToColor:PTAddPagesManager.whitePageColor] ? marginGreen*1.6 : lineShade*0.45;
            double rightMarginB = [backgroundColor pt_isEqualToColor:PTAddPagesManager.whitePageColor] ? marginBlue*1.6 : lineShade*0.45;
            newDoc = [PTPDFDocGenerator GenerateLinedPaperDoc:width height:height line_spacing:0.25 line_thickness:0.45 red:lineShade green:lineShade blue:lineShade left_margin_distance:1.2 left_margin_red:leftMarginR left_margin_green:leftMarginG left_margin_blue:leftMarginB right_margin_red:rightMarginR right_margin_green:rightMarginG right_margin_blue:rightMarginB background_red:red background_green:green background_blue:blue top_margin_distance:0.85 bottom_margin_distance:0.35];
            break;
        }
        case PTPageTemplateStyleGrid:
            newDoc = [PTPDFDocGenerator GenerateGridPaperDoc:width height:height grid_spacing:0.25 line_thickness:0.45 red:lineShade green:lineShade blue:lineShade background_red:red background_green:green background_blue:blue];
            break;
        case PTPageTemplateStyleGraph:
            newDoc = [PTPDFDocGenerator GenerateGraphPaperDoc:width height:height grid_spacing:0.25 line_thickness:0.45 weighted_line_thickness:1.7 weighted_line_freq:5 red:lineShade green:lineShade blue:lineShade background_red:red background_green:green background_blue:blue];
            break;
        case PTPageTemplateStyleMusic:
            newDoc = [PTPDFDocGenerator GenerateMusicPaperDoc:width height:height margin:0.5 staves:10 linespace_size_pts:6.5 line_thickness:0.25 red:lineShade green:lineShade blue:lineShade background_red:red background_green:green background_blue:blue];
            break;
        case PTPageTemplateStyleDotted:
            newDoc = [PTPDFDocGenerator GenerateDottedPaperDoc:width height:height dot_spacing:0.25 dot_size:2.0 red:lineShade green:lineShade blue:lineShade background_red:red background_green:green background_blue:blue];
            break;
        case PTPageTemplateStyleIsometricDotted:
            newDoc = [PTPDFDocGenerator GenerateIsometricDottedPaperDoc:width height:height dot_spacing:0.25 dot_size:2.0 red:lineShade green:lineShade blue:lineShade background_red:red background_green:green background_blue:blue];
            break;
        default:
            newDoc = [PTPDFDocGenerator GenerateBlankPaperDoc:width height:height background_red:red background_green:green background_blue:blue];
            break;
    }
    BOOL shouldUnlock = NO;
    @try {
        [newDoc Lock];
        shouldUnlock = YES;
        for (int i = 0; i < pageCount-1; i++) {
            PTPage *page = [newDoc GetPage:1];
            [newDoc PagePushBack:page];
        }
    }@catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [newDoc Unlock];
        }
    }
    return newDoc;
}

@end
