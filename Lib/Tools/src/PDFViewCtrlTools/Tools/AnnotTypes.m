//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "AnnotTypes.h"

#import "PTToolsUtil.h"

#import "PTAnnot+PTExtendedAnnotType+Private.h"

#import <Foundation/Foundation.h>

NSString * const PTSignatureAnnotationIdentifier = @"pdftronSignatureStamp";
NSString * const PTImageStampAnnotationIdentifier = @"pdftronImageStamp";
NSString * const PTImageStampAnnotationRotationIdentifier = @"pdftronImageStampRotation";
NSString * const PTImageStampAnnotationRotationDegreeIdentifier = @"pdftronImageStampRotationDegree";

NSString * const PTPencilDrawingAnnotationIdentifier = @"pdftronPencilDrawingData";

#pragma mark - Extended annot name defines

// Define a PTExtendedAnnotName case, with the NSString-ified value of `name`.
#define PT_DEFINE_EXTENDED_ANNOT_NAME(name) \
const PTExtendedAnnotName PT_PASTE(PTExtendedAnnotName, name) = PT_NS_STRINGIFY(name)

// Basic annotation types:
PT_DEFINE_EXTENDED_ANNOT_NAME(Text);
PT_DEFINE_EXTENDED_ANNOT_NAME(Link);
PT_DEFINE_EXTENDED_ANNOT_NAME(FreeText);
PT_DEFINE_EXTENDED_ANNOT_NAME(Line);
PT_DEFINE_EXTENDED_ANNOT_NAME(Square);
PT_DEFINE_EXTENDED_ANNOT_NAME(Circle);
PT_DEFINE_EXTENDED_ANNOT_NAME(Polygon);
PT_DEFINE_EXTENDED_ANNOT_NAME(Polyline);
PT_DEFINE_EXTENDED_ANNOT_NAME(Highlight);
PT_DEFINE_EXTENDED_ANNOT_NAME(Underline);
PT_DEFINE_EXTENDED_ANNOT_NAME(Squiggly);
PT_DEFINE_EXTENDED_ANNOT_NAME(StrikeOut);
PT_DEFINE_EXTENDED_ANNOT_NAME(Stamp);
PT_DEFINE_EXTENDED_ANNOT_NAME(Caret);
PT_DEFINE_EXTENDED_ANNOT_NAME(Ink);
PT_DEFINE_EXTENDED_ANNOT_NAME(Popup);
PT_DEFINE_EXTENDED_ANNOT_NAME(FileAttachment);
PT_DEFINE_EXTENDED_ANNOT_NAME(Sound);
PT_DEFINE_EXTENDED_ANNOT_NAME(Movie);
PT_DEFINE_EXTENDED_ANNOT_NAME(Widget);
PT_DEFINE_EXTENDED_ANNOT_NAME(Screen);
PT_DEFINE_EXTENDED_ANNOT_NAME(PrinterMark);
PT_DEFINE_EXTENDED_ANNOT_NAME(TrapNet);
PT_DEFINE_EXTENDED_ANNOT_NAME(Watermark);
PT_DEFINE_EXTENDED_ANNOT_NAME(ThreeDimensional);
PT_DEFINE_EXTENDED_ANNOT_NAME(Redact);
PT_DEFINE_EXTENDED_ANNOT_NAME(Projection);
PT_DEFINE_EXTENDED_ANNOT_NAME(RichMedia);

// Custom annotation types:
PT_DEFINE_EXTENDED_ANNOT_NAME(Arrow);
PT_DEFINE_EXTENDED_ANNOT_NAME(Signature);
PT_DEFINE_EXTENDED_ANNOT_NAME(Cloudy);
PT_DEFINE_EXTENDED_ANNOT_NAME(Ruler);
PT_DEFINE_EXTENDED_ANNOT_NAME(Perimeter);
PT_DEFINE_EXTENDED_ANNOT_NAME(Area);
PT_DEFINE_EXTENDED_ANNOT_NAME(ImageStamp);
PT_DEFINE_EXTENDED_ANNOT_NAME(PencilDrawing);
PT_DEFINE_EXTENDED_ANNOT_NAME(FreehandHighlight);
PT_DEFINE_EXTENDED_ANNOT_NAME(Callout);

#undef PT_DEFINE_EXTENDED_ANNOT_NAME

#pragma mark - PTExtendedAnnotType & PTExtendedAnnotName mappings

PTExtendedAnnotType PTExtendedAnnotTypeFromName(PTExtendedAnnotName name)
{
    static NSDictionary<PTExtendedAnnotName, NSNumber *> *nameTypeMap;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nameTypeMap = @{
            // Basic annotation types:
            PTExtendedAnnotNameText : @(PTExtendedAnnotTypeText),
            PTExtendedAnnotNameLink : @(PTExtendedAnnotTypeLink),
            PTExtendedAnnotNameFreeText : @(PTExtendedAnnotTypeFreeText),
            PTExtendedAnnotNameLine : @(PTExtendedAnnotTypeLine),
            PTExtendedAnnotNameSquare : @(PTExtendedAnnotTypeSquare),
            PTExtendedAnnotNameCircle : @(PTExtendedAnnotTypeCircle),
            PTExtendedAnnotNamePolygon : @(PTExtendedAnnotTypePolygon),
            PTExtendedAnnotNamePolyline : @(PTExtendedAnnotTypePolyline),
            PTExtendedAnnotNameHighlight : @(PTExtendedAnnotTypeHighlight),
            PTExtendedAnnotNameUnderline : @(PTExtendedAnnotTypeUnderline),
            PTExtendedAnnotNameSquiggly : @(PTExtendedAnnotTypeSquiggly),
            PTExtendedAnnotNameStrikeOut : @(PTExtendedAnnotTypeStrikeOut),
            PTExtendedAnnotNameStamp : @(PTExtendedAnnotTypeStamp),
            PTExtendedAnnotNameCaret : @(PTExtendedAnnotTypeCaret),
            PTExtendedAnnotNameInk : @(PTExtendedAnnotTypeInk),
            PTExtendedAnnotNamePopup : @(PTExtendedAnnotTypePopup),
            PTExtendedAnnotNameFileAttachment : @(PTExtendedAnnotTypeFileAttachment),
            PTExtendedAnnotNameSound : @(PTExtendedAnnotTypeSound),
            PTExtendedAnnotNameMovie : @(PTExtendedAnnotTypeMovie),
            PTExtendedAnnotNameWidget : @(PTExtendedAnnotTypeWidget),
            PTExtendedAnnotNameScreen : @(PTExtendedAnnotTypeScreen),
            PTExtendedAnnotNamePrinterMark : @(PTExtendedAnnotTypePrinterMark),
            PTExtendedAnnotNameTrapNet : @(PTExtendedAnnotTypeTrapNet),
            PTExtendedAnnotNameWatermark : @(PTExtendedAnnotTypeWatermark),
            PTExtendedAnnotNameThreeDimensional : @(PTExtendedAnnotType3D),
            PTExtendedAnnotNameRedact : @(PTExtendedAnnotTypeRedact),
            PTExtendedAnnotNameProjection : @(PTExtendedAnnotTypeProjection),
            PTExtendedAnnotNameRichMedia : @(PTExtendedAnnotTypeRichMedia),
            
            // Custom annotation types:
            PTExtendedAnnotNameArrow : @(PTExtendedAnnotTypeArrow),
            PTExtendedAnnotNameSignature : @(PTExtendedAnnotTypeSignature),
            PTExtendedAnnotNameCloudy : @(PTExtendedAnnotTypeCloudy),
            PTExtendedAnnotNameRuler : @(PTExtendedAnnotTypeRuler),
            PTExtendedAnnotNamePerimeter : @(PTExtendedAnnotTypePerimeter),
            PTExtendedAnnotNameArea : @(PTExtendedAnnotTypeArea),
            PTExtendedAnnotNameImageStamp : @(PTExtendedAnnotTypeImageStamp),
            PTExtendedAnnotNamePencilDrawing : @(PTExtendedAnnotTypePencilDrawing),
            PTExtendedAnnotNameFreehandHighlight : @(PTExtendedAnnotTypeFreehandHighlight),
            PTExtendedAnnotNameCallout: @(PTExtendedAnnotTypeCallout),
        };
    });
    
    NSNumber *value = name ? nameTypeMap[name] : nil;
    if (!value) {
        return PTExtendedAnnotTypeUnknown;
    }
    
    return value.unsignedIntegerValue;
}

PTExtendedAnnotName PTExtendedAnnotNameFromType(PTExtendedAnnotType type)
{
    switch (type) {
        // Basic annotation types:
        case PTExtendedAnnotTypeText:
            return PTExtendedAnnotNameText;
        case PTExtendedAnnotTypeLink:
            return PTExtendedAnnotNameLink;
        case PTExtendedAnnotTypeFreeText:
            return PTExtendedAnnotNameFreeText;
        case PTExtendedAnnotTypeLine:
            return PTExtendedAnnotNameLine;
        case PTExtendedAnnotTypeSquare:
            return PTExtendedAnnotNameSquare;
        case PTExtendedAnnotTypeCircle:
            return PTExtendedAnnotNameCircle;
        case PTExtendedAnnotTypePolygon:
            return PTExtendedAnnotNamePolygon;
        case PTExtendedAnnotTypePolyline:
            return PTExtendedAnnotNamePolyline;
        case PTExtendedAnnotTypeHighlight:
            return PTExtendedAnnotNameHighlight;
        case PTExtendedAnnotTypeUnderline:
            return PTExtendedAnnotNameUnderline;
        case PTExtendedAnnotTypeSquiggly:
            return PTExtendedAnnotNameSquiggly;
        case PTExtendedAnnotTypeStrikeOut:
            return PTExtendedAnnotNameStrikeOut;
        case PTExtendedAnnotTypeStamp:
            return PTExtendedAnnotNameStamp;
        case PTExtendedAnnotTypeCaret:
            return PTExtendedAnnotNameCaret;
        case PTExtendedAnnotTypeInk:
            return PTExtendedAnnotNameInk;
        case PTExtendedAnnotTypePopup:
            return PTExtendedAnnotNamePopup;
        case PTExtendedAnnotTypeFileAttachment:
            return PTExtendedAnnotNameFileAttachment;
        case PTExtendedAnnotTypeSound:
            return PTExtendedAnnotNameSound;
        case PTExtendedAnnotTypeMovie:
            return PTExtendedAnnotNameMovie;
        case PTExtendedAnnotTypeWidget:
            return PTExtendedAnnotNameWidget;
        case PTExtendedAnnotTypeScreen:
            return PTExtendedAnnotNameScreen;
        case PTExtendedAnnotTypePrinterMark:
            return PTExtendedAnnotNamePrinterMark;
        case PTExtendedAnnotTypeTrapNet:
            return PTExtendedAnnotNameTrapNet;
        case PTExtendedAnnotTypeWatermark:
            return PTExtendedAnnotNameWatermark;
        case PTExtendedAnnotType3D:
            return PTExtendedAnnotNameThreeDimensional;
        case PTExtendedAnnotTypeRedact:
            return PTExtendedAnnotNameRedact;
        case PTExtendedAnnotTypeProjection:
            return PTExtendedAnnotNameProjection;
        case PTExtendedAnnotTypeRichMedia:
            return PTExtendedAnnotNameRichMedia;
            
        // Custom annotation types:
        case PTExtendedAnnotTypeArrow:
            return PTExtendedAnnotNameArrow;
        case PTExtendedAnnotTypeSignature:
            return PTExtendedAnnotNameSignature;
        case PTExtendedAnnotTypeCloudy:
            return PTExtendedAnnotNameCloudy;
        case PTExtendedAnnotTypeRuler:
            return PTExtendedAnnotNameRuler;
        case PTExtendedAnnotTypePerimeter:
            return PTExtendedAnnotNamePerimeter;
        case PTExtendedAnnotTypeArea:
            return PTExtendedAnnotNameArea;
        case PTExtendedAnnotTypeImageStamp:
            return PTExtendedAnnotNameImageStamp;
        case PTExtendedAnnotTypePencilDrawing:
            return PTExtendedAnnotNamePencilDrawing;
        case PTExtendedAnnotTypeFreehandHighlight:
            return PTExtendedAnnotNameFreehandHighlight;
        case PTExtendedAnnotTypeCallout:
            return PTExtendedAnnotNameCallout;

        case PTExtendedAnnotTypeUnknown:
        default:
            return nil;
    }
}

NSString *PTLocalizedAnnotationNameFromType(PTExtendedAnnotType type)
{
    switch (type) {
        // Basic annotation types:
        case PTExtendedAnnotTypeText:
            return PTLocalizedString(@"Note", @"Note annotation name");
            
        case PTExtendedAnnotTypeLink:
            return PTLocalizedString(@"Link", @"Link annotation name");
            
        case PTExtendedAnnotTypeFreeText:
            return PTLocalizedString(@"Text", @"FreeText annotation name");
            
        case PTExtendedAnnotTypeLine:
            return PTLocalizedString(@"Line", @"Line annotation name");
            
        case PTExtendedAnnotTypeSquare:
            return PTLocalizedString(@"Rectangle", @"Rectangle annotation name");
            
        case PTExtendedAnnotTypeCircle:
            return PTLocalizedString(@"Ellipse", @"Ellipse annotation name");
            
        case PTExtendedAnnotTypePolygon:
            return PTLocalizedString(@"Polygon", @"Polygon annotation name");
            
        case PTExtendedAnnotTypePolyline:
            return PTLocalizedString(@"Polyline", @"Polyline annotation name");
            
        case PTExtendedAnnotTypeHighlight:
            return PTLocalizedString(@"Highlight", @"Highlight annotation name");
            
        case PTExtendedAnnotTypeUnderline:
            return PTLocalizedString(@"Underline", @"Underline annotation name");
            
        case PTExtendedAnnotTypeSquiggly:
            return PTLocalizedString(@"Squiggly", @"Squiggly annotation name");
            
        case PTExtendedAnnotTypeStrikeOut:
            return PTLocalizedString(@"Strikeout", @"Strikeout annotation name");
            
        case PTExtendedAnnotTypeStamp:
            return PTLocalizedString(@"Stamp", @"Stamp annotation name");
            
        case PTExtendedAnnotTypeCaret:
            return PTLocalizedString(@"Caret", @"Caret annotation name");
            
        case PTExtendedAnnotTypeInk:
            return PTLocalizedString(@"Ink", @"Ink annotation name");
            
        case PTExtendedAnnotTypePopup:
            return PTLocalizedString(@"Popup", @"Popup annotation name");
            
        case PTExtendedAnnotTypeFileAttachment:
            return PTLocalizedString(@"File Attachment", @"File Attachment annotation name");
            
        case PTExtendedAnnotTypeSound:
            return PTLocalizedString(@"Sound", @"Sound annotation name");
            
        case PTExtendedAnnotTypeMovie:
            return PTLocalizedString(@"Movie", @"Movie annotation name");
            
        case PTExtendedAnnotTypeWidget:
            return PTLocalizedString(@"Widget", @"Widget annotation name");
            
        case PTExtendedAnnotTypeScreen:
            return PTLocalizedString(@"Screen", @"Screen annotation name");
            
        case PTExtendedAnnotTypePrinterMark:
            return PTLocalizedString(@"Printer Mark", @"Printer Mark annotation name");
            
        case PTExtendedAnnotTypeTrapNet:
            return PTLocalizedString(@"Trap Network", @"Trap Network annotation name");
            
        case PTExtendedAnnotTypeWatermark:
            return PTLocalizedString(@"Watermark", @"Watermark annotation name");
            
        case PTExtendedAnnotType3D:
            return PTLocalizedString(@"3D", @"3D annotation name");
            
        case PTExtendedAnnotTypeRedact:
            return PTLocalizedString(@"Redaction", @"Redaction annotation name");
            
        case PTExtendedAnnotTypeProjection:
            return PTLocalizedString(@"Projection", @"Project annotation name");
            
        case PTExtendedAnnotTypeRichMedia:
            return PTLocalizedString(@"Rich Media", @"Rich Media annotation name");
            
            // Custom annotation types:
        case PTExtendedAnnotTypeArrow:
            return PTLocalizedString(@"Arrow", @"Arrow annotation name");
            
        case PTExtendedAnnotTypeSignature:
            return PTLocalizedString(@"Signature", @"Signature annotation name");
            
        case PTExtendedAnnotTypeCloudy:
            return PTLocalizedString(@"Cloud", @"Cloud annotation name");
            
        case PTExtendedAnnotTypeRuler:
            return PTLocalizedString(@"Ruler", @"Ruler annotation name");
            
        case PTExtendedAnnotTypePerimeter:
            return PTLocalizedString(@"Perimeter", @"Perimeter annotation name");
            
        case PTExtendedAnnotTypeArea:
            return PTLocalizedString(@"Area", @"Area annotation name");
            
        case PTExtendedAnnotTypeImageStamp:
            return PTLocalizedString(@"Image Stamp", @"Image Stamp annotation name");
            
        case PTExtendedAnnotTypePencilDrawing:
            return PTLocalizedString(@"Pencil Drawing", @"Pencil Drawing annotation name");
            
        case PTExtendedAnnotTypeFreehandHighlight:
            return PTLocalizedString(@"Freehand Highlight", @"Freehand Highlight annotation name");
            
        case PTExtendedAnnotTypeCallout:
            return PTLocalizedString(@"Callout", @"Callout annotation name");
            
        case PTExtendedAnnotTypeUnknown:
            return nil;
    }
    // NOTE: There is no default case in the switch above to ensure that each annotation type is
    // handled and newly added types are not missed.
    
    return nil;
}
