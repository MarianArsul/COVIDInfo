//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCloudCreate.h"

#import "PTPolylineCreateSubclass.h"

#import "PTAnnotStyleDraw.h"

#import "CGContext+PTAdditions.h"
#import "CGGeometry+PTAdditions.h"

#import <tgmath.h>

@implementation PTCloudCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        _borderEffectIntensity = 2.0;
    }
    return self;
}

#pragma mark - Annotation saving

- (PTPolyLine *)createPolylineWithDoc:(PTPDFDoc *)doc pagePoints:(NSArray<PTPDFPoint *> *)pagePoints
{
    PTPolyLine *poly = [super createPolylineWithDoc:doc pagePoints:pagePoints];
    [poly SetBorderEffect:e_ptCloudy];
    
    [poly SetBorderEffectIntensity:self.borderEffectIntensity];
    
    return poly;
}

#pragma mark - Polygon Utilities

- (Class)annotClass
{
    return [PTPolygon class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeCloudy;
}

#pragma mark - Drawing

- (void)drawPolylineWithRect:(CGRect)rect points:(NSArray<NSValue *> *)points
{
    [PTAnnotStyleDraw drawCloudWithRect:rect
                                 points:points
                        borderIntensity:self.borderEffectIntensity
                                   zoom:[self.pdfViewCtrl GetZoom]];
}

- (void)endDrawPolylineWithRect:(CGRect)rect atPoint:(CGPoint)point withPoints:(NSArray<NSValue *> *)points
{
    [super endDrawPolylineWithRect:rect atPoint:point withPoints:points];
}

- (double)setupContext:(CGContextRef)currentContext
{
    double thickness = [super setupContext:currentContext];
    
    CGContextSetLineCap(currentContext, kCGLineCapRound);
    CGContextSetLineJoin(currentContext, kCGLineJoinRound);
    
    return thickness;
}

@end
