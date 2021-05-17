//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPDFTronUtil.h"

#import "PTToolsUtil.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation PTPDFTronUtil

+(NSString*)directoryToSaveTo
{
    return NSTemporaryDirectory();
}

+(void)showErrorAlertFrom:(UIViewController*)controller withTitle:(NSString*)title message:(NSString*)message
{
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK", @"")
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alertController addAction:okAction];
    
    [controller presentViewController:alertController animated:YES completion:nil];
}

+(UIImage*)correctForRotation:(UIImage*)src
{
    UIGraphicsBeginImageContext(src.size);
    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    UIImage* img =  UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+(NSData*)getNSDataFromUIImage:(UIImage*)image
{
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) malloc(height * width * 4 * sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    unsigned char *noAlpha = (unsigned char*) malloc(height * width * 3* sizeof(unsigned char));
    
    for(int pix = 0; pix < height * width * 4; pix += bytesPerPixel)
    {
        memcpy((noAlpha+pix/bytesPerPixel*3), (rawData+pix), 3);
    }
    
    NSData* data = [[NSData alloc] initWithBytesNoCopy:noAlpha length:height*width*3*sizeof(unsigned char) freeWhenDone:YES];
    
    free(rawData);
    
    return data;
}



//+(PTPDFDoc*)PTPDFDocFromURL:(NSURL *)url error:(NSError**)error
//{
//    NSString* type;
//
//    if( [url getResourceValue:&type forKey:NSURLTypeIdentifierKey error:error] )
//    {
//        if( UTTypeConformsTo((__bridge CFStringRef)(type), (__bridge CFStringRef)@"public.image") )
//        {
//            // url points to an image
//            UIImage* image = [UIImage imageWithContentsOfFile:[url path]];
//
//            PTPDFDoc* imageDoc;
//
//            imageDoc = [PTPDFTronUtil PTPDFDocFromImage:image];
//
//            return imageDoc;
//        }
//
//        else if( ![[[url path] pathExtension] isEqualToString:@"pdf"] )
//        {
//            // url points to something we might be able to convert to PDF
//            return [PTPDFTronUtil openNonPDFAsPDF:url error:error];
//        }
//    }
//
////    if( error )
////    {
////        return nil;
////    }
//
//    // url is a file path to a PDF document
//    if ([url isFileURL]) {
//
//        // Open the document
//        @try {
//            PTPDFDoc* pdfDoc;
//            pdfDoc = [[PTPDFDoc alloc] initWithFilepath:[url path]];
//            return pdfDoc;
//
//        }
//        @catch (NSException *exception) {
//
//        }
//    }
//
//    NSDictionary* userInfo = @{
//                               NSLocalizedDescriptionKey:PTLocalizedString(@"Unsupported File", @""),
//                               NSLocalizedFailureReasonErrorKey:PTLocalizedString(@"There was a problem opening the file.", @"")};
//
//    *error = [[NSError alloc] initWithDomain:@"com.pdftron" code:0 userInfo:userInfo];
//
//    return nil;
//
//
//}
//
//+(void)openNonPDFAsPDF:(NSURL *)url completion:(void(^)(PTPDFDoc* pdfDoc, NSError** error))completion
////+(PTPDFDoc*)openNonPDFAsPDF:(NSURL *)url error:(NSError**)error
//{
//    assert([url isFileURL]);
//
//    BOOL builtInConverter = [[[url path] pathExtension] isEqualToString:@"docx"] ||
//    [[[url path] pathExtension] isEqualToString:@"doc"] ||
//    [[[url path] pathExtension] isEqualToString:@"pptx"];
//    PTPDFDoc* pdfDoc = [[PTPDFDoc alloc] init];
//
//    // what gets executed after conversion, be it by iOS or PDFNet
//    PTPDFDoc* (^postConversionBlock)(NSString*) = ^PTPDFDoc*(NSString* pdfPath) {
//
//        NSError *error;
//        NSNumber* num;
//
//        [url getResourceValue:&num forKey:NSURLIsUbiquitousItemKey error:&error];
//
//        if(error)
//            NSLog(@"Error determining if file is iCloud: %@", error);
//
//        if( builtInConverter )
//        {
//            return pdfDoc;
//        }
//        else
//        {
//            NSString* saveDir = [PTPDFTronUtil directoryToSaveTo];
//            NSString* uniqueID = [NSUUID UUID].UUIDString;
//

//            NSString* newPath = [[saveDir stringByAppendingPathComponent:uniqueID] stringByAppendingPathExtension:@"pdf"];
//
//            [[NSFileManager defaultManager] moveItemAtPath:pdfPath toPath:newPath  error:&error];
//
//            return [[PTPDFDoc alloc] initWithFilepath:newPath];
//        }
//
//    };
//
//    if( builtInConverter )
//    {
//        // perform the conversion with no optional parameters
//        [PTConvert WordToPDF:pdfDoc in_filename:[url path] options:nil];
//        return postConversionBlock(nil);
//    }
//    else
//    {
//        __block PTPDFDoc* pdfDoc;
//        [PTConvert convertOfficeToPDF:[url path] paperSize:CGSizeZero completion:^(NSString* pdfPath){
//
//            pdfDoc = postConversionBlock(pdfPath);
//        }];
//
//        return pdfDoc;
//    }
//}

+(PTPDFDoc*)PTPDFDocFromImage:(UIImage*)image // inDirectory:(NSString*)dir withfileName:(NSString*)fileName
{
    PTPDFDoc* doc;
    UIImage* rotatedImage;
    @try {
        
        rotatedImage = [PTPDFTronUtil correctForRotation:image];
        
        NSData* data = [PTPDFTronUtil getNSDataFromUIImage:rotatedImage];

        // create new doc
        doc = [[PTPDFDoc alloc] init];
        PTElementBuilder* f = [[PTElementBuilder alloc] init];
        PTElementWriter* writer = [[PTElementWriter alloc] init];

        PTPage* page = [doc PageCreate:[[PTPDFRect alloc] initWithX1:0 y1:0 x2:rotatedImage.size.width y2:rotatedImage.size.height]];
        // Add image to the output file
        PTObj* obj = [[PTObj alloc] init];

        PTImage* trnImage = [PTImage CreateWithData:[doc GetSDFDoc] buf:data buf_size:data.length width:rotatedImage.size.width height:rotatedImage.size.height bpc:8 color_space:[PTColorSpace CreateDeviceRGB] encoder_hints:obj];
        //PTElement element = f.createImage(img, new Matrix2D(img.getImageWidth(), 0, 0, img.getImageHeight(), 0,0));

        PTElement* element = [f CreateImageWithMatrix:trnImage mtx:[[PTMatrix2D alloc] initWithA:rotatedImage.size.width b:0 c:0 d:rotatedImage.size.height h:0 v:0]];
        // Change page size
        //page.setMediaBox(new Rect(0, 0, img.getImageWidth(), img.getImageHeight()));
        [page SetCropBox:[[PTPDFRect alloc] initWithX1:0 y1:0 x2:rotatedImage.size.width y2:rotatedImage.size.height]];
        [writer Begin:page placement:e_ptoverlay page_coord_sys:YES compress:YES];
        [writer WritePlacedElement:element];
        [writer End];
        [doc PagePushBack:page];


//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//
//        if(!fileName )
//            fileName = @"Image.pdf";
//        else
//        {
//            fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
//        }
//
//        if(!dir)
//        {
//            NSString* currentFolder = [self getCurrentFilePath];
//            docPath = [currentFolder stringByAppendingPathComponent:fileName];
//        }
//        else
//            docPath = [dir stringByAppendingPathComponent:fileName];
//
//        unsigned int count = 1;
//
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//
//        NSString* base = [fileName stringByDeletingPathExtension];
//
//        while ([fileManager fileExistsAtPath:docPath isDirectory:nil]) {
//
//            fileName = [NSString stringWithFormat:@"%@ %u.pdf",base, count++];
//
//            if(!dir)
//                docPath = [documentsDirectory stringByAppendingPathComponent:fileName];
//            else
//                docPath = [dir stringByAppendingPathComponent:fileName];
//        }
//
//        [doc SaveToFile:docPath flags:0];
    }
    @catch (NSException *exception) {
        
    }

    return doc;
    
    //return docPath;
}

@end
