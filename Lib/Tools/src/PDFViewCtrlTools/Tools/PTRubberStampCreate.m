//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTRubberStampCreate.h"
#import "PTRubberStampManager.h"
#import "PTCustomStampOption.h"
#import "PTRubberStampViewController.h"
#import "UIColor+PTHexString.h"
#import "UIView+PTAdditions.h"

const PTStampType PTStampTypeCheckMark = @"FILL_CHECK";
const PTStampType PTStampTypeCrossMark = @"FILL_CROSS";
const PTStampType PTStampTypeDot = @"FILL_DOT";

@interface PTRubberStampCreate ()<PTRubberStampViewControllerDelegate>

@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTRubberStampCreate

@dynamic isPencilTouch;

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        _stampType = PTStampTypeCheckMark;
    }
    return self;
}

- (Class)annotClass
{
    return [PTRubberStamp class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeStamp;
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

    __block int pageNumber = 0;

    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:touchPoint.x y:touchPoint.y];
    } error:&error];

    if (error) {
        NSLog(@"Error: %@", error);
        return YES;
    }
    if (pageNumber < 1) {
        return YES;
    }

    // Save page number for touch point.
    _pageNumber = pageNumber;
    self.endPoint = touchPoint;
    [self showRubberStampViewController];
    // Tap handled.
    return YES;
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    if (userData &&
        (userData == self.defaultClass ||
        [(NSString*)userData isEqualToString:@"CloseAnnotationToolbar"])) {
        // Switch to default tool class.
        self.nextToolType = self.defaultClass;
        return NO;
    }else {
        // Coming from long-press in PanTool.
        self.endPoint = self.longPressPoint;
        _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.endPoint.x y:self.endPoint.y];
        [self showRubberStampViewController];
        // Handled (stay in current tool).
        return YES;
    }
}

-(void)showRubberStampViewController{
    PTRubberStampViewController* rubberStampController = [[PTRubberStampViewController allocOverridden] init];
    rubberStampController.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rubberStampController];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    nav.presentationController.delegate = self;
    [self.pt_viewController presentViewController:nav animated:YES completion:^{
        [nav.presentationController.presentedView.gestureRecognizers.firstObject setEnabled:NO];
    }];
}

-(void)createStampWithImage:(UIImage*)image
{
    if (image == nil ||
        image.size.width == 0 ||
        image.size.height == 0) {
        NSString *reason = image == nil ? @"Stamp image is undefined.": @"Invalid image size: width or height is 0.";
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }

    NSError *error = nil;

    [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {

        PTPage* page = [doc GetPage:self.pageNumber];

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

        CGFloat scaleFactor = MIN(maxWidth / image.size.width, maxHeight / image.size.height);
        if (image.size.width < maxWidth &&
            image.size.height < maxHeight) {
            scaleFactor = 1.0;
        }
        CGFloat stampWidth = image.size.width * scaleFactor;
        CGFloat stampHeight = image.size.height * scaleFactor;

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
        PTPDFPoint *touchPtPage = [self.pdfViewCtrl ConvScreenPtToPagePt:[[PTPDFPoint alloc] initWithPx:self.endPoint.x py:self.endPoint.y] page_num:_pageNumber];
        touchPtPage = [mtx Mult:touchPtPage];

        CGFloat xPos = [touchPtPage getX] - (stampWidth / 2);
        CGFloat yPos = [touchPtPage getY] - (stampHeight / 2);

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
        [encoderHints PushBackName:@"JPEG"];

        PTImage* stampImage = [PTImage CreateWithDataSimple:[doc GetSDFDoc] buf:data buf_size:data.length encoder_hints:encoderHints];

        // Rotate stamp based on the pdfViewCtrl's rotation
        PTRotate stampRotation = (4 - ctrlRotation) % 4; // 0 = 0, 90 = 1; 180 = 2, and 270 = 3
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
    } error:&error];

    if (error) {
        NSLog(@"Error: %@", error);
    }

    if (self.currentAnnotation && self.annotationPageNumber > 0) {
        [self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    }
}

-(void)createCustomStampWithOption:(PTCustomStampOption*)stampOption{
    PTObjSet *objSet = [[PTObjSet alloc] init];
    PTObj *stampObj = [objSet CreateDict];
    [stampOption configureStampObject:stampObj];

    BOOL hasWriteLock = NO;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        hasWriteLock = YES;
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];

        PTPage* page = [doc GetPage:self.pageNumber];
        PTPDFPoint *touchPtPage = [self.pdfViewCtrl ConvScreenPtToPagePt:[[PTPDFPoint alloc] initWithPx:self.endPoint.x py:self.endPoint.y] page_num:self.pageNumber];
        PTSDFDoc *sdfDoc = [doc GetSDFDoc];

        PTSDFDoc *tempDoc = [[PTSDFDoc alloc] init];
        PTPDFRect* tempRect = [[PTPDFRect alloc] init];

        PTRubberStamp *tempStamp = [PTRubberStamp CreateCustom:tempDoc pos:tempRect form_xobject:stampObj];
        PTPDFRect *annotRect = [tempStamp GetRect];
        double width = [annotRect Width];
        double height = [annotRect Height];
        PTPDFRect* pageRect = [[PTPDFRect alloc] initWithX1:touchPtPage.getX-width/2 y1:touchPtPage.getY-height/2 x2:touchPtPage.getX+width/2 y2:touchPtPage.getY+height/2];
        if (stampOption.pointingLeft && !stampOption.pointingRight) {
            pageRect = [[PTPDFRect alloc] initWithX1:touchPtPage.getX y1:touchPtPage.getY-height/2 x2:touchPtPage.getX+width y2:touchPtPage.getY+height/2];
        }else if (stampOption.pointingRight && !stampOption.pointingLeft){
                pageRect = [[PTPDFRect alloc] initWithX1:touchPtPage.getX-width y1:touchPtPage.getY-height/2 x2:touchPtPage.getX y2:touchPtPage.getY+height/2];
        }
        PTRubberStamp *rubberStamp = [PTRubberStamp CreateCustom:sdfDoc pos:pageRect form_xobject:stampObj];

        [page AnnotPushBack:rubberStamp];
        self.currentAnnotation = rubberStamp;

        [self.currentAnnotation RefreshAppearance];
        self.annotationPageNumber = self.pageNumber;
        [self.pdfViewCtrl UpdateWithAnnot:rubberStamp page_num:self.pageNumber];
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
    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

#pragma mark - PTRubberStampViewControllerDelegate

- (void)rubberStampController:(PTRubberStampViewController *)rubberStampController addStamp:(PTCustomStampOption*)stampOption
{
    [self createCustomStampWithOption:stampOption];
    [self.pt_viewController.presentedViewController dismissViewControllerAnimated:YES completion:Nil];
}

- (void)rubberStampControllerWasDismissed:(PTRubberStampViewController *)rubberStampController
{
    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

@end
