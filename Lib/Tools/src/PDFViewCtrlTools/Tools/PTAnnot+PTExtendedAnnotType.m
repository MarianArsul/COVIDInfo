//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "AnnotTypes.h"

#import "PTAnnot+PTExtendedAnnotType+Private.h"

#import <Foundation/Foundation.h>

@implementation PTAnnot (PTExtendedAnnotType)

+ (PTExtendedAnnotType)PT_extendedAnnotTypeForFreeTextWithAnnot:(PTAnnot *)annot
{
    NSAssert([annot GetType] == e_ptFreeText,
             @"Cannot determine freetext type for non-freetext annotation");

    PTFreeText *freeText = nil;
    if ([annot isKindOfClass:[PTFreeText class]]) {
        freeText = (PTFreeText *)annot;
    } else {
        freeText = [[PTFreeText alloc] initWithAnn:annot];
    }
    
    // Check the freetext annot's intent name.
    switch ([freeText GetIntentName]) {
        case e_ptFreeTextCallout:
            return PTExtendedAnnotTypeCallout;
        default:
            return PTExtendedAnnotTypeFreeText;
    }
}

+ (PTExtendedAnnotType)PT_extendedAnnotTypeForLineWithAnnot:(PTAnnot *)annot
{
    NSAssert([annot GetType] == e_ptLine, @"Cannot determine line type for non-line annotation");
    
    PTLineAnnot *line = [[PTLineAnnot alloc] initWithAnn:annot];
    
    PTObj *obj = [annot GetSDFObj];
    PTObj *annotMeasurementObject = [obj FindObj:@"Measure"];
    
    if ([line IsValid] && ([line GetEndStyle] == e_ptOpenArrow || [line GetStartStyle] == e_ptOpenArrow)) {
        return PTExtendedAnnotTypeArrow;
    } else if (annotMeasurementObject != nil) {
        return PTExtendedAnnotTypeRuler;
    } else {
        return PTExtendedAnnotTypeLine;
    }
}

+ (PTExtendedAnnotType)PT_extendedAnnotTypeForPolygonWithAnnot:(PTAnnot *)annot
{
    NSAssert([annot GetType] == e_ptPolygon, @"Cannot determine polygon type for non-polygon annotation");
    
    PTPolygon *polygon = [[PTPolygon alloc] initWithAnn:annot];
    
    PTObj *obj = [annot GetSDFObj];
    PTObj *annotMeasurementObject = [obj FindObj:@"Measure"];

    if ([polygon IsValid] && [polygon GetBorderEffect] == e_ptCloudy) {
        return PTExtendedAnnotTypeCloudy;
    } else if (annotMeasurementObject != nil) {
        return PTExtendedAnnotTypeArea;
    } else {
        return PTExtendedAnnotTypePolygon;
    }
}

+ (PTExtendedAnnotType)PT_extendedAnnotTypeForPolylineWithAnnot:(PTAnnot *)annot
{
    NSAssert([annot GetType] == e_ptPolyline, @"Cannot determine polygon type for non-polyline annotation");
    
    PTPolyLine *polyline = [[PTPolyLine alloc] initWithAnn:annot];
    
    PTObj *obj = [annot GetSDFObj];
    PTObj *annotMeasurementObject = [obj FindObj:@"Measure"];
    
    if ([polyline IsValid] && annotMeasurementObject != nil) {
        return PTExtendedAnnotTypePerimeter;
    } else {
        return PTExtendedAnnotTypePolyline;
    }
}

+ (PTExtendedAnnotType)PT_extendedAnnotTypeForStampWithAnnot:(PTAnnot *)annot
{
    PTObj *obj = [annot GetSDFObj];
    
    if ([obj IsValid] && [[obj FindObj:PTSignatureAnnotationIdentifier] IsValid]) {
        return PTExtendedAnnotTypeSignature;
    } else if (([obj IsValid] && ([[obj FindObj:PTPencilDrawingAnnotationIdentifier] IsValid]))
               || [annot GetCustomData:PTPencilDrawingAnnotationIdentifier]) {
        return PTExtendedAnnotTypePencilDrawing;
    } else if ([obj IsValid] && ([[obj FindObj:PTImageStampAnnotationIdentifier] IsValid] ||
                                 [[obj FindObj:PTImageStampAnnotationRotationIdentifier] IsValid] ||
                                 [[obj FindObj:PTImageStampAnnotationRotationDegreeIdentifier] IsValid])) {
        return PTExtendedAnnotTypeImageStamp;
    }else {
        return PTExtendedAnnotTypeStamp;
    }
}

+ (PTExtendedAnnotType)PT_extendedAnnotTypeForInkWithAnnot:(PTAnnot *)annot
{
    NSAssert([annot GetType] == e_ptInk, @"Cannot determine ink type for non-ink annotation");
    
    PTInk *ink = [[PTInk alloc] initWithAnn:annot];
    if ([ink GetHighlightIntent]) {
        return PTExtendedAnnotTypeFreehandHighlight;
    } else {
        return PTExtendedAnnotTypeInk;
    }
}

- (PTExtendedAnnotType)extendedAnnotType
{
    if (![self IsValid]) {
        return PTExtendedAnnotTypeUnknown;
    }
    
    PTAnnotType annotType = [self GetType];
    switch (annotType) {
        case e_ptText:
            return PTExtendedAnnotTypeText;
        case e_ptLink:
            return PTExtendedAnnotTypeLink;
        case e_ptFreeText:
            return [[self class] PT_extendedAnnotTypeForFreeTextWithAnnot:self];
        case e_ptLine:
            // Differentiate between lines and arrows.
            return [[self class] PT_extendedAnnotTypeForLineWithAnnot:self];
        case e_ptSquare:
            return PTExtendedAnnotTypeSquare;
        case e_ptCircle:
            return PTExtendedAnnotTypeCircle;
        case e_ptPolygon:
            // Differentiate between polygon and cloudy.
            return [[self class] PT_extendedAnnotTypeForPolygonWithAnnot:self];
        case e_ptPolyline:
            return [[self class] PT_extendedAnnotTypeForPolylineWithAnnot:self];
        case e_ptHighlight:
            return PTExtendedAnnotTypeHighlight;
        case e_ptUnderline:
            return PTExtendedAnnotTypeUnderline;
        case e_ptSquiggly:
            return PTExtendedAnnotTypeSquiggly;
        case e_ptStrikeOut:
            return PTExtendedAnnotTypeStrikeOut;
        case e_ptStamp:
            return [[self class] PT_extendedAnnotTypeForStampWithAnnot:self];
        case e_ptCaret:
            return PTExtendedAnnotTypeCaret;
        case e_ptInk:
            return [[self class] PT_extendedAnnotTypeForInkWithAnnot:self];
        case e_ptPopup:
            return PTExtendedAnnotTypePopup;
        case e_ptFileAttachment:
            return PTExtendedAnnotTypeFileAttachment;
        case e_ptSound:
            return PTExtendedAnnotTypeSound;
        case e_ptMovie:
            return PTExtendedAnnotTypeMovie;
        case e_ptWidget:
            return PTExtendedAnnotTypeWidget;
        case e_ptScreen:
            return PTExtendedAnnotTypeScreen;
        case e_ptPrinterMark:
            return PTExtendedAnnotTypePrinterMark;
        case e_ptTrapNet:
            return PTExtendedAnnotTypeTrapNet;
        case e_ptWatermark:
            return PTExtendedAnnotTypeWatermark;
        case e_pt3D:
            return PTExtendedAnnotType3D;
        case e_ptRedact:
            return PTExtendedAnnotTypeRedact;
        case e_ptProjection:
            return PTExtendedAnnotTypeProjection;
        case e_ptRichMedia:
            return PTExtendedAnnotTypeRichMedia;
        case e_ptUnknown:
        default:
            return PTExtendedAnnotTypeUnknown;
    }
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTAnnot, PTExtendedAnnotType)
