//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTRubberStampManager.h"
#import "PTToolsUtil.h"
#import "UIColor+PTHexString.h"

NSString * const PTRubberStampKeyText = @"TEXT";
NSString * const PTRubberStampKeyTextBelow = @"TEXT_BELOW";
NSString * const PTRubberStampKeyFillColorStart = @"FILL_COLOR_START";
NSString * const PTRubberStampKeyFillColorEnd = @"FILL_COLOR_END";
NSString * const PTRubberStampKeyTextColor = @"TEXT_COLOR";
NSString * const PTRubberStampKeyBorderColor = @"BORDER_COLOR";
NSString * const PTRubberStampKeyFillOpacity = @"FILL_OPACITY";
NSString * const PTRubberStampKeyPointingLeft = @"POINTING_LEFT";
NSString * const PTRubberStampKeyPointingRight = @"POINTING_RIGHT";

@implementation PTRubberStampManager

+ (UIColor *)lightRedStartColor{
    return [UIColor pt_colorWithHexString:@"FAEBE8"];
}
+ (UIColor *)lightRedEndColor{
    return [UIColor pt_colorWithHexString:@"FFC9C9"];
}
+ (UIColor *)lightRedTextColor{
    return [UIColor pt_colorWithHexString:@"9C0E04"];
}
+ (UIColor *)lightRedBorderColor{
    return [UIColor pt_colorWithHexString:@"9C0E04"];
}

+ (UIColor *)darkRedStartColor{
    return [UIColor pt_colorWithHexString:@"DA7A67"];
}
+ (UIColor *)darkRedEndColor{
    return [UIColor pt_colorWithHexString:@"D5624B"];
}
+ (UIColor *)darkRedTextColor{
    return [UIColor pt_colorWithHexString:@"2A0f09"];
}
+ (UIColor *)darkRedBorderColor{
    return [UIColor pt_colorWithHexString:@"6E0005"];
}

+ (UIColor *)lightGreenStartColor{
    return [UIColor pt_colorWithHexString:@"F4F8EE"];
}
+ (UIColor *)lightGreenEndColor{
    return [UIColor pt_colorWithHexString:@"D4E0CC"];
}
+ (UIColor *)lightGreenTextColor{
    return [UIColor pt_colorWithHexString:@"267F00"];
}
+ (UIColor *)lightGreenBorderColor{
    return [UIColor pt_colorWithHexString:@"2E4B11"];
}

+ (UIColor *)lightBlueStartColor{
    return [UIColor pt_colorWithHexString:@"EFF3FA"];
}
+ (UIColor *)lightBlueEndColor{
    return [UIColor pt_colorWithHexString:@"A6BDE5"];
}
+ (UIColor *)lightBlueTextColor{
    return [UIColor pt_colorWithHexString:@"2E3090"];
}
+ (UIColor *)lightBlueBorderColor{
    return [UIColor pt_colorWithHexString:@"2E3090"];
}

+ (UIColor *)yellowStartColor{
    return [UIColor pt_colorWithHexString:@"FBF7AA"];
}
+ (UIColor *)yellowEndColor{
    return [UIColor pt_colorWithHexString:@"E5DA09"];
}
+ (UIColor *)yellowTextColor{
    return [UIColor pt_colorWithHexString:@"3f3C02"];
}
+ (UIColor *)yellowBorderColor{
    return [UIColor pt_colorWithHexString:@"D0AD2E"];
}

+ (UIColor *)purpleStartColor{
    return [UIColor pt_colorWithHexString:@"C6BEE6"];
}
+ (UIColor *)purpleEndColor{
    return [UIColor pt_colorWithHexString:@"8878CA"];
}
+ (UIColor *)purpleTextColor{
    return [UIColor pt_colorWithHexString:@"18122f"];
}
+ (UIColor *)purpleBorderColor{
    return [UIColor pt_colorWithHexString:@"413282"];
}

- (NSUInteger)numberOfStandardStamps
{
    return self.standardStampOptions.count;
}

- (NSArray<PTCustomStampOption *> *)standardStampOptions{
    if (!_standardStampOptions) {
        _standardStampOptions = @[
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"APPROVED",@"APPROVED stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightGreenStartColor
                                           bgColorEnd:PTRubberStampManager.lightGreenEndColor
                                            textColor:PTRubberStampManager.lightGreenTextColor
                                          borderColor:PTRubberStampManager.lightGreenBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight:NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"AS IS", @"AS IS stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"COMPLETED", @"COMPLETED stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightGreenStartColor
                                           bgColorEnd:PTRubberStampManager.lightGreenEndColor
                                            textColor:PTRubberStampManager.lightGreenTextColor
                                          borderColor:PTRubberStampManager.lightGreenBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"CONFIDENTIAL", @"CONFIDENTIAL stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"DEPARTMENTAL", @"DEPARTMENTAL stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"DRAFT", @"DRAFT stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"EXPERIMENTAL", @"EXPERIMENTAL stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"EXPIRED", @"EXPIRED stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightRedStartColor
                                           bgColorEnd:PTRubberStampManager.lightRedEndColor
                                            textColor:PTRubberStampManager.lightRedTextColor
                                          borderColor:PTRubberStampManager.lightRedBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"FINAL", @"FINAL stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightGreenStartColor
                                           bgColorEnd:PTRubberStampManager.lightGreenEndColor
                                            textColor:PTRubberStampManager.lightGreenTextColor
                                          borderColor:PTRubberStampManager.lightGreenBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"FOR COMMENT", @"FOR COMMENT stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"FOR PUBLIC RELEASE", @"FOR PUBLIC RELEASE stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"INFORMATION ONLY", @"INFORMATION ONLY stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"NOT APPROVED", @"NOT APPROVED stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightRedStartColor
                                           bgColorEnd:PTRubberStampManager.lightRedEndColor
                                            textColor:PTRubberStampManager.lightRedTextColor
                                          borderColor:PTRubberStampManager.lightRedBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"NOT FOR PUBLIC RELEASE", @"NOT FOR PUBLIC RELEASE stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"PRELIMINARY RESULTS", @"PRELIMINARY RESULTS stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"SOLD", @"SOLD stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"TOP SECRET", @"TOP SECRET stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightBlueStartColor
                                           bgColorEnd:PTRubberStampManager.lightBlueEndColor
                                            textColor:PTRubberStampManager.lightBlueTextColor
                                          borderColor:PTRubberStampManager.lightBlueBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"VOID", @"VOID stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.lightRedStartColor
                                           bgColorEnd:PTRubberStampManager.lightRedEndColor
                                            textColor:PTRubberStampManager.lightRedTextColor
                                          borderColor:PTRubberStampManager.lightRedBorderColor
                                          fillOpacity:.85
                                         pointingLeft:NO
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"SIGN HERE", @"SIGN HERE stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.darkRedStartColor
                                           bgColorEnd:PTRubberStampManager.darkRedEndColor
                                            textColor:PTRubberStampManager.darkRedTextColor
                                          borderColor:PTRubberStampManager.darkRedBorderColor
                                          fillOpacity:1
                                         pointingLeft:YES
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"WITNESS", @"WITNESS stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.yellowStartColor
                                           bgColorEnd:PTRubberStampManager.yellowEndColor
                                            textColor:PTRubberStampManager.yellowTextColor
                                          borderColor:PTRubberStampManager.yellowBorderColor
                                          fillOpacity:1
                                         pointingLeft:YES
                                        pointingRight: NO],
            [[PTCustomStampOption alloc] initWithText:PTLocalizedString(@"INITIAL HERE", @"INITIAL HERE stamp text")
                                           secondText:@""
                                         bgColorStart:PTRubberStampManager.purpleStartColor
                                           bgColorEnd:PTRubberStampManager.purpleEndColor
                                            textColor:PTRubberStampManager.purpleTextColor
                                          borderColor:PTRubberStampManager.purpleBorderColor
                                          fillOpacity:1
                                         pointingLeft:YES
                                        pointingRight: NO]
       ];
    }
    return _standardStampOptions;
}

+ (UIImage *)getBitMapForStampWithHeight:(double)height width:(double)width option:(PTCustomStampOption *)stampOption
{
    PTObjSet *objSet = [[PTObjSet alloc] init];
    PTObj *stampObj = [objSet CreateDict];
    [stampOption configureStampObject:stampObj];

    PTPDFDoc *tempDoc;
    PTPDFDraw *pdfDraw;
    BOOL shouldUnlock = false;
    @try {
        tempDoc = [[PTPDFDoc alloc] init];
        [tempDoc Lock];
        shouldUnlock = true;
        [tempDoc InitSecurityHandler];

        PTPDFRect* pageRect = [[PTPDFRect alloc] initWithX1:0 y1:0 x2:width y2:height];
        PTPage *page = [tempDoc PageCreate:pageRect];
        [tempDoc PagePushBack:page];

        PTRubberStamp *stamp = [PTRubberStamp CreateCustom:[tempDoc GetSDFDoc] pos:pageRect form_xobject:stampObj];
        PTPDFRect *stampRect = [stamp GetRect];

        if ([stampRect Width] == 0 || [stampRect Height] == 0) {
            NSString *reason = @"Invalid stamp size: width or height is 0.";
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:reason
                                         userInfo:nil];
        }

        if ([stampRect Width] > width || [stampRect Height] > height) {
            CGFloat scaleFactor = MIN(width / [stampRect Width], height / [stampRect Height]);
            CGFloat stampWidth = [stampRect Width] * scaleFactor;
            CGFloat stampHeight = [stampRect Height] * scaleFactor;
            [pageRect SetX2:stampWidth];
            [pageRect SetY2:stampHeight];
            [stamp Resize:pageRect];
        }
        [page AnnotPushBack:stamp];
        [page SetCropBox:pageRect];

        double dpi = 72*[[UIScreen mainScreen] scale];
        pdfDraw = [[PTPDFDraw alloc] initWithDpi:dpi];
        [pdfDraw SetPageTransparent:YES];
        [pdfDraw SetAntiAliasing:YES];

        PTBitmapInfo* bitmapInfoObject = [pdfDraw GetBitmap:page pix_fmt:e_ptbgra demult:NO];
        
        NSData* data = [bitmapInfoObject GetBuffer];
        
        UIImage* image = [PTRubberStampManager imageFromRawBGRAData:data width:[bitmapInfoObject getWidth] height:[bitmapInfoObject getHeight]];

        return image;
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@\n%@\n%@", exception.name, exception.reason, exception.description);
    } @finally {
        if (shouldUnlock) {
            [tempDoc Unlock];
        }
        [tempDoc Close];
    }
    return nil;
}

+(UIImage*)imageFromRawBGRAData:(NSData*)data width:(int)width height:(int)height
{
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    const int bitsPerComponent = 8;
    const int bitsPerPixel = 4 * bitsPerComponent;
    const int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);

    CGDataProviderRelease(provider);
    double screenScale = [[UIScreen mainScreen] scale];

    UIImage *myImage = [UIImage imageWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];

    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);

    return myImage;
}

@end
