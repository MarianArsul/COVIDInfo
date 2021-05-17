//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "PTAnnotStyle.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStyleDraw : NSObject

+(BOOL)canVectorDrawWithAnnotType:(PTExtendedAnnotType)type;

+(UIImage*)getAnnotationAppearanceImage:(PTPDFDoc*)doc withAnnot:(PTAnnot*)annot onPageNumber:(int)pageNumber withDPI:(int)dpi forViewerRotation:(PTRotate)viewerRotation;
+(UIView*)getAnnotationVectorAppearanceView:(PTPDFDoc*)doc withAnnot:(PTAnnot*)annot andPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onPageNumber:(int)pageNumber;

+(void)drawIntoContext:(CGContextRef)context withStyle:(PTAnnotStyle*)annotStyle withCrop:(CGRect)rect atZoom:(double)zoom;

+ (void)drawCloudWithRect:(CGRect)rect points:(NSArray<NSValue *> *)points borderIntensity:(double)borderIntensity zoom:(double)zoom;

@end

NS_ASSUME_NONNULL_END
