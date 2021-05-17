//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTImageCropTool.h"

#import "PTCropView.h"
#import "PTToolsUtil.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTImageCropTool ()

@property (nonatomic, strong, nullable) PTCropView *appearanceView;
@property (nonatomic, strong, nullable) UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END

@implementation PTImageCropTool

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        // Allow this tool (view) to get touch events. This is required to expand the crop view's
        // touchable area out 22 pts, via hitTest and pointInside.
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        self.frame = self.superview.bounds;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addAppearance];
        [self updateAppearance];
    } else {
        [self removeAppearance];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    const CGFloat touchAdjustment = 44.0 / 2;
    const CGRect cropHitRect = CGRectInset(self.appearanceView.frame,
                                           -touchAdjustment, -touchAdjustment);
    if (CGRectContainsPoint(cropHitRect, point)) {
        return YES;
    }
    return [super pointInside:point withEvent:event];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    const CGFloat touchAdjustment = 44.0 / 2;
    const CGRect cropHitRect = CGRectInset(self.appearanceView.frame,
                                           -touchAdjustment, -touchAdjustment);
    if (CGRectContainsPoint(cropHitRect, point)) {
        return self.appearanceView;
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - Appearance

- (void)addAppearance
{
    // Crop view.
    self.appearanceView = [[PTCropView alloc] init];
    
    [self.appearanceView.panGestureRecognizer addTarget:self
                                                 action:@selector(handlePanGesture:)];
    
    [self addSubview:self.appearanceView];
    
    // Image view.
    self.imageView = [[UIImageView alloc] initWithFrame:self.appearanceView.contentView.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.appearanceView.contentView addSubview:self.imageView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [self.pdfViewCtrl HideAnnotation:self.currentAnnotation];
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation
                                 page_num:self.annotationPageNumber];

    });
}

- (void)removeAppearance
{
    [self.appearanceView removeFromSuperview];
    self.appearanceView = nil;
    
    [self.pdfViewCtrl ShowAnnotation:self.currentAnnotation];
    [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation
                             page_num:self.annotationPageNumber];
}

- (void)updateAppearance
{
    if (![self.currentAnnotation IsValid]) {
        return;
    }
        
    __block CGRect annotRect = CGRectNull;
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        
        PTPage *page = [doc GetPage:self.annotationPageNumber];
        if (![page IsValid]) {
            return;
        }
        
        const PTRotate viewRotation = self.pdfViewCtrl.rotation;
        const PTRotate pageRotation = [page GetRotation];
        const int annotRotationAngle = [self.currentAnnotation GetRotation]; // multiple of 90 degrees
        const PTRotate annotRotation = (annotRotationAngle / 90) % 4;
        const PTRotate rotation = (viewRotation + pageRotation + annotRotation) % 4;
        
        self.imageView.transform = CGAffineTransformMakeRotation((rotation * 90.0) * (M_PI / 180.0));
        
        UIImage *image = [self imageForAnnotation:self.currentAnnotation];
        
        self.imageView.image = image;
        
        PTPDFRect *annotRectScreen = [self.pdfViewCtrl GetScreenRectForAnnot:self.currentAnnotation
                                                                    page_num:self.annotationPageNumber];
        
        annotRect = [self PDFRectScreen2CGRectScreen:annotRectScreen
                                          PageNumber:self.annotationPageNumber];
        
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    if (!CGRectIsNull(annotRect)) {
        CGRect appearanceRect = CGRectOffset(annotRect,
                                             [self.pdfViewCtrl GetHScrollPos],
                                             [self.pdfViewCtrl GetVScrollPos]);
        
        self.appearanceView.frame = appearanceRect;
    }
}

- (void)showCropMenu
{
    UIMenuController *menu = UIMenuController.sharedMenuController;
    
    menu.menuItems = @[
        [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Crop",
                                                            @"Save the cropped image")
                                   action:@selector(cropAnnotation)],
        [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Cancel",
                                                            @"Cancel cropping image")
                                   action:@selector(cancelCropping)],
    ];
    
    CGRect cropBounds = [self.pdfViewCtrl convertRect:self.appearanceView.cropBounds
                                             fromView:self.appearanceView];
    
    [self showSelectionMenu:cropBounds animated:YES];
}

#pragma mark - Actions

- (void)cropAnnotation
{
    __block PTRotate rotation = e_pt0;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        PTPage *page = [doc GetPage:self.annotationPageNumber];
        if (![page IsValid]) {
            return;
        }
        
        const PTRotate viewRotation = self.pdfViewCtrl.rotation;
        const PTRotate pageRotation = [page GetRotation];
        const int annotRotationAngle = [self.currentAnnotation GetRotation]; // multiple of 90 degrees
        const PTRotate annotRotation = (annotRotationAngle / 90) % 4;
        rotation = (viewRotation + pageRotation + annotRotation) % 4;
    } error:nil];
    
    UIImage *croppedImage = [self croppedImageForImage:self.imageView.image
                                            viewBounds:self.appearanceView.bounds
                                             cropInset:self.appearanceView.cropInset
                                              rotation:rotation];
    
    const CGRect cropBounds = self.appearanceView.cropBounds;
    
    __block BOOL success = YES;
    NSError *error = nil;
    [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        // Get the PNG data for the cropped image.
        // NOTE: For images with a soft mask image, this does not give correct PNG data if the
        // UIImage is initially composed of an RGB image with an alpha mask. Unless the masked image
        // is drawn into a new bitmap, the resulting PNG will have a green tint to the left side
        // where the scaled alpha channel is (incorrectly) applied.
        NSData *imageData = UIImagePNGRepresentation(croppedImage);
        
        NSAssert(imageData != nil,
                 @"Failed to get PNG representation for cropped image");
        if (!imageData) {
            success = NO;
            return;
        }
        
        // Create the PTImage from the PNG data. This will automatically take care of extracting the
        // PNG alpha channel into a separate soft mask image and leaving the RGB data in the parent.
        PTObjSet *hintSet = [[PTObjSet alloc] init];
        PTObj *encoderHints = [hintSet CreateArray];
        [encoderHints PushBackName:@"PNG"];
        
        PTImage *image = [PTImage CreateWithDataSimple:[doc GetSDFDoc]
                                                   buf:imageData
                                              buf_size:imageData.length
                                         encoder_hints:encoderHints];
        
        // Write the image into a new appearance.
        PTElementWriter *writer = [[PTElementWriter alloc] init];
        [writer WriterBeginWithSDFDoc:[doc GetSDFDoc] compress:YES];
        
        PTElementBuilder *builder = [[PTElementBuilder alloc] init];
        PTElement *element = [builder CreateImageWithCornerAndScale:image
                                                                  x:0
                                                                  y:0
                                                             hscale:[image GetImageWidth]
                                                             vscale:[image GetImageHeight]];
        [writer WritePlacedElement:element];

        PTObj *newAppearance = [writer End];
        
        // Ensure the appearance's bounding box is set to the image element's bounds.
        PTPDFRect *bbox = [element GetBBox];
        [bbox Normalize];
        [newAppearance PutRect:@"BBox" x1:[bbox GetX1] y1:[bbox GetY1] x2:[bbox GetX2] y2:[bbox GetY2]];

        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        [self.currentAnnotation SetAppearance:newAppearance annot_state:e_ptnormal app_state:nil];
        
        // Update the annotation's rect, converting the crop bounds to screen (PDFViewCtrl)
        // coordinates and then to page coordinates.
        const CGRect annotScreenRect = [self.pdfViewCtrl convertRect:cropBounds
                                                            fromView:self.appearanceView];
        PTPDFRect *annotPageRect = [self.pdfViewCtrl CGRectScreen2PDFRectPage:annotScreenRect
                                                                   PageNumber:self.annotationPageNumber];
        [annotPageRect Normalize];
        
        [self.currentAnnotation SetRect:annotPageRect];
    } error:&error];
    if (error) {
        NSLog(@"Error cropping image: %@", error);
    }

    // Raise annotation-modified event on success.
    if (success) {
        [self annotationModified:self.currentAnnotation
                    onPageNumber:self.annotationPageNumber];
    }
    
    // Switch back to default tool class.
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

- (void)cancelCropping
{
    // Switch back to default tool class.
    [self.toolManager createSwitchToolEvent:self.defaultClass];
}

#pragma mark - Image conversion

- (nullable UIImage *)imageForAnnotation:(PTAnnot *)annot
{
    if (![annot IsValid]) {
        return nil;
    }
    
    // Get the annot's appearance stream.
    PTObj *appearance = [annot GetAppearance:e_ptnormal app_state:nil];
    if (![appearance IsValid] || [appearance GetType] != e_ptstream) {
        return nil;
    }
    
    // Find the first image element in the appearance stream.
    PTElementReader *reader = [[PTElementReader alloc] init];
    [reader ReaderBeginWithSDFObj:appearance resource_dict:nil ocg_context:nil];
    
    PTElement *imageElement = nil;
    for (PTElement *element = [reader Next]; element; element = [reader Next]) {
        if ([element GetType] == e_ptimage) {
            imageElement = element;
            break;
        }
    }
    if (!imageElement) {
        return nil;
    }
    
    // Create a PDF image from the element's form XObject.
    PTObj *xobject = [imageElement GetXObject];
    if (![xobject IsValid]) {
        return nil;
    }
    
    PTImage *image = [[PTImage alloc] initWithImage_xobject:xobject];
    if (![image IsValid]) {
        return nil;
    }
    
    // Extract image dimensions and pixel format information.
    const int imageWidth = [image GetImageWidth];
    const int imageHeight = [image GetImageHeight];
    const int componentNum = [image GetComponentNum];
    const int bitsPerComponent = [image GetBitsPerComponent];
    
    // Match the image rendering intent.
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    switch ([image GetImageRenderingIntent]) {
        case e_ptabsolute_colorimetric:
            intent = kCGRenderingIntentAbsoluteColorimetric;
            break;
        case e_ptrelative_colorimetric:
            intent = kCGRenderingIntentRelativeColorimetric;
            break;
        case e_ptsaturation:
            intent = kCGRenderingIntentSaturation;
            break;
        case e_ptperceptual:
            intent = kCGRenderingIntentPerceptual;
            break;
    }
    
    const int bitsPerPixel = componentNum * bitsPerComponent;
    const int bytesPerRow = componentNum * imageWidth;
    
    // The image should not have an alpha channel.
    const CGBitmapInfo bitmapInfo = (kCGImageAlphaNone | kCGBitmapByteOrder32Big);
    
    // Read the raw image data.
    PTFilter *imageFilter = [image GetImageData];
    const int imageDataSize = [image GetImageDataSize];
    
    PTFilterReader *imageFilterReader = [[PTFilterReader alloc] initWithFilter:imageFilter];
    NSData *imageData = [imageFilterReader Read:imageDataSize];
    
    // Create a Core Graphics image from the PDF image.
    CGDataProviderRef imageDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imageRef = CGImageCreate(imageWidth,
                                        imageHeight,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpace,
                                        bitmapInfo,
                                        imageDataProvider,
                                        nil, // decode array
                                        NO, // shouldInterpolate
                                        intent);
    
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(imageDataProvider);
    
    CGImageRef outputImageRef = imageRef;
    
    // Check if the PDF image has a soft mask image for transparency.
    PTImage *softMaskImage = [self softMaskImageForImage:image];
    if ([softMaskImage IsValid]) {
        // Create a Core Graphics image from the image's soft mask image.
        // The parent image is required to provide the dimensions for the soft mask image in the
        // case that a matte color was used to pre-multiply the image's data.
        CGImageRef imageMaskRef = [self CGImageMaskFromSoftMaskImage:softMaskImage
                                                   withParentImage:image];
        if (imageMaskRef) {
            // Create a new Core Graphics image with the soft mask image applied to the parent (RGB)
            // image.
            outputImageRef = CGImageCreateWithMask(imageRef, imageMaskRef);
            
            // imageMaskRef is autoreleased.
            CGImageRelease(imageRef);
        }
    }
    
    UIImage *outputImage = [UIImage imageWithCGImage:outputImageRef];
    CGImageRelease(outputImageRef);

    // Redraw the output image to get a non-masked image with pre-multiplied alpha.
    // IMPORTANT: If this step is not done, then the image's PNG data representation will be
    // incorrect (mask applied to only half the image with a strong green tint).
    UIImage *redrawnImage = [self redrawImage:outputImage];
    
    NSAssert(redrawnImage != nil,
             @"Failed to re-draw the output image in a bitmap image context");
    
    return redrawnImage;
}

- (nullable PTImage *)softMaskImageForImage:(PTImage *)image
{
    // Create a PDF image for the image's soft mask image.
    PTObj *softMaskObj = [image GetSoftMask];
    if (![softMaskObj IsValid]) {
        return nil;
    }
    return [[PTImage alloc] initWithImage_xobject:softMaskObj];
}

- (nullable CGImageRef)CGImageMaskFromSoftMaskImage:(PTImage *)softMaskImage withParentImage:(PTImage *)parentImage
{
    if (![softMaskImage IsValid]) {
        return nil;
    }

    // Check if the soft mask image specifies a matte color.
    PTObj *softMaskImageObj = [softMaskImage GetSDFObj];
    const BOOL mattePresent = [[softMaskImageObj FindObj:@"Matte"] IsValid];
    
    int width = 0;
    int height = 0;
    if (mattePresent) {
        // Use the parent image's dimensions.
        width = [parentImage GetImageWidth];
        height = [parentImage GetImageHeight];
    } else {
        width = [softMaskImage GetImageWidth];
        height = [softMaskImage GetImageHeight];
    }
    
    PTColorSpace *colorSpace = [softMaskImage GetImageColorSpace];
    NSAssert([colorSpace GetType] == e_ptdevice_gray,
             @"The color space for soft mask images must be DeviceGray");
    
    // Extract soft mask image pixel format information.
    const int componentNum = [colorSpace GetComponentNum];
    const int bitsPerComponent = [softMaskImage GetBitsPerComponent];
    
    const int bitsPerPixel = componentNum * bitsPerComponent;
    const int bytesPerRow = componentNum * width;
    
    const CGBitmapInfo bitmapInfo = (kCGImageAlphaNone | kCGBitmapByteOrder32Big);

    // Read the raw image data.
    PTFilter *imageFilter = [softMaskImage GetImageData];
    const int imageDataSize = [softMaskImage GetImageDataSize];
    
    PTFilterReader *imageFilterReader = [[PTFilterReader alloc] initWithFilter:imageFilter];
    NSData *imageData = [imageFilterReader Read:imageDataSize];

    // Create a Core Graphics image from the PDF soft mask image.
    CGDataProviderRef imageDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceGray();
    
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        space,
                                        bitmapInfo,
                                        imageDataProvider,
                                        NULL, // decode
                                        false, // shouldInterpolate
                                        kCGRenderingIntentDefault);
    
    CGColorSpaceRelease(space);
    CGDataProviderRelease(imageDataProvider);

    return (CGImageRef)CFAutorelease(imageRef);
}

- (nullable UIImage *)redrawImage:(UIImage *)image
{
    NSParameterAssert(image);
    
    // Draw the specified image in a new image context to correct any image mask and/or orientation.
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero];
    UIImage *bitmapContextImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return bitmapContextImage;
}

static UIEdgeInsets PT_rotateEdgesInsets(UIEdgeInsets insets, PTRotate rotation)
{
    switch (rotation) {
        case e_pt0:
            return insets;
        case e_pt90:
            return UIEdgeInsetsMake(insets.left, insets.bottom, insets.right, insets.top);
        case e_pt180:
            return UIEdgeInsetsMake(insets.bottom, insets.right, insets.top, insets.left);
        case e_pt270:
            return UIEdgeInsetsMake(insets.right, insets.top, insets.left, insets.bottom);
    }
    return insets;
}

- (UIImage *)croppedImageForImage:(UIImage *)image viewBounds:(CGRect)viewBounds cropInset:(UIEdgeInsets)cropInset rotation:(PTRotate)rotation
{
    const CGFloat radians = (rotation * 90) * (M_PI / 180.0);
    const CGRect rotatedViewBounds = CGRectApplyAffineTransform(viewBounds,
                                                                CGAffineTransformMakeRotation(radians));
    // Calculate the scale between the image and view.
    const CGFloat scale = fmax(image.size.width / CGRectGetWidth(rotatedViewBounds),
                               image.size.height / CGRectGetHeight(rotatedViewBounds));
    
    // Scale the cropInset to handle images larger than shown-on-screen size.
    UIEdgeInsets imageCropInset = PT_rotateEdgesInsets(cropInset, (4 - rotation));
    imageCropInset.top *= scale;
    imageCropInset.left *= scale;
    imageCropInset.bottom *= scale;
    imageCropInset.right *= scale;
    
    // Inset the image bounds by the specified amount.
    const CGRect imageBounds = CGRectMake(0, 0,
                                        image.size.width, image.size.height);
    const CGRect imageCropBounds = UIEdgeInsetsInsetRect(imageBounds,
                                                         imageCropInset);
    
    // Crop the image to the calculated rect.
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage,
                                                              imageCropBounds);
    
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef];
    CGImageRelease(croppedImageRef);
    
    return croppedImage;
}

#pragma mark - PTTool

- (BOOL)onSwitchToolEvent:(id)userData
{
    if (userData) {
        // Switch to default tool class.
        if ([userData isEqual:self.defaultClass]) {
            return NO;
        }
    }
    
    return [super onSwitchToolEvent:userData];
}

- (void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl *)pdfViewCtrl
{
    [super pdfViewCtrlOnLayoutChanged:pdfViewCtrl];
    
    [self updateAppearance];
}

#pragma mark - Gestures

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.view != self.appearanceView) {
        return;
    }
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            // Hide the selection menu while resizing the crop area.
            [self hideMenu];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            // Show the selection menu when no longer resizing the crop area.
            [self showCropMenu];
        }
            break;
        default:
            break;
    }
}

@end
