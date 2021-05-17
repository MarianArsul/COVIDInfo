//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolImages.h"

#import "PTToolsUtil.h"

@implementation PTAnnotationImageLayer

- (instancetype)initWithStyleKey:(PTAnnotStyleKey)styleKey imageNames:(NSArray<NSString *> *)imageNames
{
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    for (NSString *imageName in imageNames) {
        UIImage *image = ([PTToolsUtil toolImageNamed:imageName] ?:
                          [UIImage imageNamed:imageName]);
        if (image) {
            [images addObject:image];
        }
    }
    return [self initWithStyleKey:styleKey images:images];
}

- (instancetype)initWithStyleKey:(PTAnnotStyleKey)styleKey images:(NSArray<UIImage *> *)images
{
    self = [super init];
    if (self) {
        _styleKey = [styleKey copy];
        _images = [images copy];
    }
    return self;
}

@end

NS_ASSUME_NONNULL_BEGIN

@interface PTToolImages ()

@end

NS_ASSUME_NONNULL_END

@implementation PTToolImages

+ (nullable NSString *)imageNameForAnnotationType:(PTExtendedAnnotType)annotationType
{
    switch (annotationType) {
        case PTExtendedAnnotTypeText:
            return @"Annotation/Comment/Icon";
        case PTExtendedAnnotTypeLine:
            return @"Annotation/Line/Icon";
        case PTExtendedAnnotTypeSquare:
            return @"Annotation/Square/Icon";
        case PTExtendedAnnotTypeCircle:
            return @"Annotation/Circle/Icon";
        case PTExtendedAnnotTypeUnderline:
            return @"Annotation/Underline/Icon";
        case PTExtendedAnnotTypeStrikeOut:
            return @"Annotation/StrikeOut/Icon";
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypePencilDrawing:
            return @"Annotation/Ink/Icon";
        case PTExtendedAnnotTypeHighlight:
            return @"Annotation/Highlight/Icon";
        case PTExtendedAnnotTypeFreeText:
            return @"Annotation/FreeText/Icon";
        case PTExtendedAnnotTypeImageStamp:
            return @"Annotation/Image/Icon";
        case PTExtendedAnnotTypeArrow:
            return @"Annotation/Arrow/Icon";
        case PTExtendedAnnotTypeSquiggly:
            return @"Annotation/Squiggly/Icon";
        case PTExtendedAnnotTypePolyline:
            return @"Annotation/Polyline/Icon";
        case PTExtendedAnnotTypePolygon:
            return @"Annotation/Polygon/Icon";
        case PTExtendedAnnotTypeCloudy:
            return @"Annotation/Cloud/Icon";
        case PTExtendedAnnotTypeSignature:
            return @"Annotation/Signature/Icon";
        case PTExtendedAnnotTypeStamp:
            return @"Annotation/Stamp/Icon";
        case PTExtendedAnnotTypeFileAttachment:
            return @"Annotation/FileAttachment/Icon";
        case PTExtendedAnnotTypeCaret:
            return @"Annotation/Caret/Icon";
        case PTExtendedAnnotTypeRedact:
            return @"Annotation/RedactionArea/Icon";
        case PTExtendedAnnotTypeRuler:
            return @"Annotation/Distance/Icon";
        case PTExtendedAnnotTypePerimeter:
            return @"Annotation/Perimeter/Icon";
        case PTExtendedAnnotTypeArea:
            return @"Annotation/AreaRectangle/Icon";
        case PTExtendedAnnotTypeFreehandHighlight:
            return @"Annotation/FreeHighlight/Icon";
        case PTExtendedAnnotTypeCallout:
            return @"Annotation/Callout/Icon";
            
        // Annotation types without images:
        case PTExtendedAnnotTypeLink:
        case PTExtendedAnnotTypePopup:
        case PTExtendedAnnotTypeSound:
        case PTExtendedAnnotTypeMovie:
        case PTExtendedAnnotTypeWidget:
        case PTExtendedAnnotTypeScreen:
        case PTExtendedAnnotTypePrinterMark:
        case PTExtendedAnnotTypeTrapNet:
        case PTExtendedAnnotTypeWatermark:
        case PTExtendedAnnotType3D:
        case PTExtendedAnnotTypeProjection:
        case PTExtendedAnnotTypeRichMedia:
        case PTExtendedAnnotTypeUnknown:
            return nil;
    }
    
    // NOTE: There is no default case in the switch above to ensure that each annotation type is
    // handled and newly added types are not missed.
    
    return nil;
}

+ (NSArray<PTAnnotationImageLayer *> *)imageLayersForAnnotationType:(PTExtendedAnnotType)annotationType
{
    switch (annotationType) {
//        case PTExtendedAnnotTypeText:
//            return @[
//                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
//                    @"Annotation/Comment/Fill",
//                ]],
//                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
//                    @"Annotation/Comment/Stroke",
//                ]],
//            ];
        case PTExtendedAnnotTypeSquare:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
                    @"Annotation/Square/Fill",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/Square/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeCircle:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
                    @"Annotation/Circle/Fill",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/Circle/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeUnderline:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:nil imageNames:@[
                    @"Annotation/Underline/Letter",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/Underline/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeStrikeOut:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:nil imageNames:@[
                    @"Annotation/StrikeOut/Letter",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/StrikeOut/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeInk:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:nil imageNames:@[
                    @"Annotation/Ink/Pen",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyColor imageNames:@[
                    @"Annotation/Ink/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeHighlight:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:nil imageNames:@[
                    @"Annotation/Highlight/Cursor",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyColor imageNames:@[
                    @"Annotation/Highlight/Fill",
                ]],
            ];
        case PTExtendedAnnotTypeSquiggly:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:nil imageNames:@[
                    @"Annotation/Squiggly/Letter",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyColor imageNames:@[
                    @"Annotation/Squiggly/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypePolygon:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
                    @"Annotation/Polygon/Fill",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/Polygon/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeCloudy:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
                    @"Annotation/Cloud/Fill",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/Cloud/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeSignature:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:nil imageNames:@[
                    @"Annotation/Signature/Line",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/Signature/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeRedact:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
                    @"Annotation/RedactionArea/Fill",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/RedactionArea/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeArea:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
                    @"Annotation/AreaRectangle/Fill",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/AreaRectangle/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeFreehandHighlight:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:nil imageNames:@[
                    @"Annotation/FreeHighlight/Highlighter",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/FreeHighlight/Stroke",
                ]],
            ];
        case PTExtendedAnnotTypeCallout:
            return @[
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyFillColor imageNames:@[
                    @"Annotation/Callout/Fill",
                ]],
                [[PTAnnotationImageLayer alloc] initWithStyleKey:PTAnnotStyleKeyStrokeColor imageNames:@[
                    @"Annotation/Callout/Stroke",
                    @"Annotation/Callout/Arrow",
                ]],
            ];

        default:
            return nil;
    }
    
    return nil;
}

+ (UIImage *)imageForAnnotationType:(PTExtendedAnnotType)annotationType
{
    if (annotationType == PTExtendedAnnotTypePencilDrawing) {
        if (@available(iOS 13.1, *)) {
            UIImageConfiguration *configuration = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium];
            return [UIImage systemImageNamed:@"pencil.tip.crop.circle"
                           withConfiguration:configuration];
        }
    }
    
    // Get the name of the image for the annotation type.
    NSString *imageName = [self imageNameForAnnotationType:annotationType];
    if (!imageName) {
        // Image name not found.
        return nil;
    }
    
    return [PTToolsUtil toolImageNamed:imageName];
}

@end
