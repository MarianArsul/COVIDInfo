//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCalloutCreate.h"

#import "PTPDFPoint+PTAdditions.h"
#import "PTPDFRect+PTAdditions.h"

#include <tgmath.h>

#define PT_CALLOUT_ADJUSTMENT 40.0

NS_ASSUME_NONNULL_BEGIN

@interface PTCalloutCreate ()

@property (nonatomic, strong, nullable) PTPDFPoint *calloutStartPoint;

@property (nonatomic, strong, nullable) PTPDFPoint *calloutKneePoint;

@property (nonatomic, strong, nullable) PTPDFPoint *calloutEndPoint;

@end

NS_ASSUME_NONNULL_END

@implementation PTCalloutCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {

    }
    return self;
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeCallout;
}

#pragma mark - PTFreeTextCreate

- (void)commitAnnotation
{
    // Before committing the annotation, calculate the callout points.
    // These will be used during the commit-process to calculate the content rect, etc.
    
    const CGPoint startPagePoint = [self convertScreenPtToPagePt:self.longPressPoint
                                                    onPageNumber:self.annotationPageNumber];
    
    PTPDFRect *pageRect = [self annotationPageRect];
    
    self.calloutStartPoint = [PTPDFPoint pointWithCGPoint:startPagePoint];
    
    
    self.calloutKneePoint = [self calloutKneePointForStartPoint:self.calloutStartPoint
                                                       pageRect:pageRect];
    
    self.calloutEndPoint = [self calloutEndPointForStartPoint:self.calloutStartPoint
                                                    kneePoint:self.calloutKneePoint
                                                     pageRect:pageRect];
    
    // Call super implementation as final step.
    [super commitAnnotation];
}

- (PTFreeText *)createFreeText
{
    PTFreeText *freeText = [super createFreeText];
    
    // This is a free text callout annotation.
    [freeText SetIntentName:e_ptFreeTextCallout];
    
    return freeText;
}

// NOTE: Do *NOT* call super implementation.
- (void)setRectForFreeText:(PTFreeText *)freeText
{
    // Calculate the free text callout's content rect for the annotation's rect.
    PTPDFRect *pageRect = [self annotationPageRect];
    
    PTPDFRect *rect = [self calloutContentRectForStartPoint:self.calloutStartPoint
                                                  kneePoint:self.calloutKneePoint
                                                   endPoint:self.calloutEndPoint
                                                   pageRect:pageRect];
    [rect Normalize];

    [freeText Resize:rect];
}

- (void)setPropertiesForFreeText:(PTFreeText *)freeText
{
    [super setPropertiesForFreeText:freeText];
    
    // End the callout with an open arrow.
    [freeText SetEndingStyle:e_ptOpenArrow];
    
    // Set the pre-calculated callout points.
    [freeText SetCalloutLinePointsWithKneePoint:self.calloutStartPoint
                                             p2:self.calloutKneePoint
                                             p3:self.calloutEndPoint];
    
    // Calculate the free text callout's content rect.
    // The content rectangle specifies an inner region for the text to be displayed.
    PTPDFRect *rect = [self calloutContentRectForStartPoint:self.calloutStartPoint
                                                  kneePoint:self.calloutKneePoint
                                                   endPoint:self.calloutEndPoint
                                                   pageRect:[self annotationPageRect]];
    [rect Normalize];
    
    [freeText SetContentRect:rect];
}

#pragma mark - Callout calculations

- (nullable PTPDFRect *)annotationPageRect
{
    PTPDFRect *pageRect = nil;
    @try {
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        PTPage *page = [doc GetPage:self.annotationPageNumber];
        if (![page IsValid]) {
            return nil;
        }
        pageRect = [page GetCropBox];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        return nil;
    }
    [pageRect Normalize];
    
    return pageRect;
}

- (PTPDFPoint *)calloutKneePointForStartPoint:(PTPDFPoint *)startPoint pageRect:(PTPDFRect *)pageRect
{
    double x = 0;
    double y = 0;

    const double pageMidX = ([pageRect GetX1] + [pageRect GetX2]) / 2;
    const double pageMidY = ([pageRect GetY1] + [pageRect GetY2]) / 2;
    
    if ([startPoint getX] > pageMidX) {
        if ([startPoint getY] > pageMidY) {
            x = [startPoint getX] - PT_CALLOUT_ADJUSTMENT;
            y = [startPoint getY] - PT_CALLOUT_ADJUSTMENT;
        } else {
            x = [startPoint getX] - PT_CALLOUT_ADJUSTMENT;
            y = [startPoint getY] + PT_CALLOUT_ADJUSTMENT;
        }
    } else {
        if ([startPoint getY] > pageMidY) {
            x = [startPoint getX] + PT_CALLOUT_ADJUSTMENT;
            y = [startPoint getY] - PT_CALLOUT_ADJUSTMENT;
        } else {
            x = [startPoint getX] + PT_CALLOUT_ADJUSTMENT;
            y = [startPoint getY] + PT_CALLOUT_ADJUSTMENT;
        }
    }
    
    return [[PTPDFPoint alloc] initWithPx:x py:y];
}

- (PTPDFPoint *)calloutEndPointForStartPoint:(PTPDFPoint *)startPoint kneePoint:(PTPDFPoint *)kneePoint pageRect:(PTPDFRect *)pageRect
{
    double x = 0;
    if ([startPoint getX] > [kneePoint getX]) {
        x = fmin([kneePoint getX] - PT_CALLOUT_ADJUSTMENT,
                 [pageRect GetX2]);
    } else {
        x = fmax([kneePoint getX] + PT_CALLOUT_ADJUSTMENT,
                 [pageRect GetX1]);
    }
    const double y = [kneePoint getY];
    
    return [[PTPDFPoint alloc] initWithPx:x py:y];
}

- (PTPDFRect *)calloutContentRectForStartPoint:(PTPDFPoint *)startPoint kneePoint:(PTPDFPoint *)kneePoint endPoint:(PTPDFPoint *)endPoint pageRect:(PTPDFRect *)pageRect
{
    double x1 = 0;
    double x2 = 0;
    if ([endPoint getX] > [kneePoint getX]) {
        x1 = [endPoint getX];
        x2 = fmin(x1 + (PT_CALLOUT_ADJUSTMENT * 2), [pageRect GetX2]);
    } else {
        x1 = fmax([endPoint getX] - (PT_CALLOUT_ADJUSTMENT * 2), [pageRect GetX1]);
        x2 = [endPoint getX];
    }
    
    double y1 = fmax([endPoint getY] - (PT_CALLOUT_ADJUSTMENT / 2), [pageRect GetY1]);
    double y2 = fmin(y1 + PT_CALLOUT_ADJUSTMENT, [pageRect GetY2]);
    
    return [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
}

@end
