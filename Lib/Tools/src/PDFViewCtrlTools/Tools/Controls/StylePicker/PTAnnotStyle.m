//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyle.h"
#import "PTMeasurementUtil.h"
#import "PTColorDefaults.h"
#import "PTToolManager.h"
#import "PTFreeTextCreate.h"

#import "PTAutoCoding.h"

static NSString * const kAnnotStylePDFTronThicknessKey = @"pdftron_thickness";

#pragma mark - AnnotStyleKey definitions

PTAnnotStyleKey const PTAnnotStyleKeyColor = @"AnnotStyleKeyColor";
PTAnnotStyleKey const PTAnnotStyleKeyStrokeColor = @"AnnotStyleKeyStrokeColor";
PTAnnotStyleKey const PTAnnotStyleKeyFillColor = @"AnnotStyleKeyFillColor";
PTAnnotStyleKey const PTAnnotStyleKeyTextColor = @"AnnotStyleKeyTextColor";

PTAnnotStyleKey const PTAnnotStyleKeyThickness = @"AnnotStyleKeyThickness";
PTAnnotStyleKey const PTAnnotStyleKeyOpacity = @"AnnotStyleKeyOpacity";
PTAnnotStyleKey const PTAnnotStyleKeyTextSize = @"AnnotStyleKeyTextSize";
PTAnnotStyleKey const PTAnnotStyleKeyScale = @"AnnotStyleKeyScale";
PTAnnotStyleKey const PTAnnotStyleKeyPrecision = @"AnnotStyleKeyPrecision";
PTAnnotStyleKey const PTAnnotStyleKeySnapping = @"AnnotStyleKeySnapping";
PTAnnotStyleKey const PTAnnotStyleKeyFont = @"AnnotStyleKeyFont";

PTAnnotStyleKey const PTAnnotStyleKeyLabel = @"AnnotStyleKeyLabel";

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStyle ()

// Redeclare as read-write internally.
@property (nonatomic, copy, readwrite) NSArray<PTAnnotStyleKey> *availableStyleKeys;
@property (nonatomic, weak) PTPDFDoc* pdfDoc;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotStyle

- (void)PTAnnotStyle_commonInit
{
    _saveValuesAsDefaults = YES;
}

- (instancetype)initWithAnnotType:(PTExtendedAnnotType)annotType
{
    self = [super init];
    if (self) {
        [self PTAnnotStyle_commonInit];
        
        _annotType = annotType;
        
        [self configure];
    }
    return self;
}

- (instancetype)initWithAnnot:(PTAnnot *)annot
{
    return [self initWithAnnot:annot onPDFDoc:nil];
}

- (instancetype)initWithAnnot:(PTAnnot *)annot onPDFDoc:(PTPDFDoc *)pdfDoc
{
    self = [super init];
    if (self) {
        [self PTAnnotStyle_commonInit];
        
        _annotType = annot.extendedAnnotType;
        _annot = annot;
        
        _pdfDoc = pdfDoc;
        
        [self configure];
    }
    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        [self PTAnnotStyle_commonInit];

        [PTAutoCoding autoUnarchiveObject:self withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [PTAutoCoding autoArchiveObject:self withCoder:coder];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    PTAnnotStyle *style = [[PTAnnotStyle allocOverridden] initWithAnnotType:self.annotType];
    
    
    NSArray<NSString *> *keys = @[
        PT_SELF_KEY(availableStyleKeys),
        PT_SELF_KEY(strokeColor),
        PT_SELF_KEY(fillColor),
        PT_SELF_KEY(textColor),
        PT_SELF_KEY(thickness),
        PT_SELF_KEY(opacity),
        PT_SELF_KEY(textSize),
        PT_SELF_KEY(label),
        PT_SELF_KEY(measurementScale),
        PT_SELF_KEY(snappingEnabled),
        PT_SELF_KEY(saveValuesAsDefaults),
    ];
    for (NSString *key in keys) {
        [style setValue:[self valueForKey:key] forKey:key];
    }
    
    return style;
}

#pragma mark - Annotation loading

- (void)configure
{
    switch (self.annotType) {
        case PTExtendedAnnotTypeText:
            break;
        case PTExtendedAnnotTypeLink:
            break;
        case PTExtendedAnnotTypeFreeText:
        case PTExtendedAnnotTypeCallout:
            [self configureFreeText];
            break;
        case PTExtendedAnnotTypeLine:
        case PTExtendedAnnotTypeArrow:
            [self configureFreeHand];
            break;
        case PTExtendedAnnotTypeRuler:
        case PTExtendedAnnotTypePerimeter:
            [self configureLengthMeasure];
            break;
        case PTExtendedAnnotTypeArea:
            [self configureAreaMeasure];
            break;
        case PTExtendedAnnotTypeSquare:
            [self configureMarkup];
            break;
        case PTExtendedAnnotTypeCircle:
            [self configureMarkup];
            break;
        case PTExtendedAnnotTypePolygon:
        case PTExtendedAnnotTypeCloudy:
            [self configureMarkup];
            break;
        case PTExtendedAnnotTypePolyline:
            [self configureFreeHand];
            break;
        case PTExtendedAnnotTypeHighlight:
            [self configureHighlight];
            break;
        case PTExtendedAnnotTypeUnderline:
            [self configureTextAnnot];
            break;
        case PTExtendedAnnotTypeSquiggly:
            [self configureTextAnnot];
            break;
        case PTExtendedAnnotTypeStrikeOut:
            [self configureTextAnnot];
            break;
        case PTExtendedAnnotTypeStamp:
        case PTExtendedAnnotTypeImageStamp:
        case PTExtendedAnnotTypeSignature:
            break;
        case PTExtendedAnnotTypeCaret:
            break;
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypeFreehandHighlight:
            [self configureFreeHand];
            break;
        case PTExtendedAnnotTypePopup:
            break;
        case PTExtendedAnnotTypeFileAttachment:
            break;
        case PTExtendedAnnotTypeSound:
            break;
        case PTExtendedAnnotTypeMovie:
            break;
        case PTExtendedAnnotTypeWidget:
            break;
        case PTExtendedAnnotTypeScreen:
            break;
        case PTExtendedAnnotTypePrinterMark:
            break;
        case PTExtendedAnnotTypeTrapNet:
            break;
        case PTExtendedAnnotTypeWatermark:
            break;
        case PTExtendedAnnotType3D:
            break;
        case PTExtendedAnnotTypeRedact:
            [self configureRedaction];
            break;
        case PTExtendedAnnotTypeProjection:
            break;
        case PTExtendedAnnotTypeRichMedia:
            break;
        case PTExtendedAnnotTypePencilDrawing:
            break;
        case PTExtendedAnnotTypeUnknown:
            break;
    }
}

- (void)configureFreeText
{
    if (@available(iOS 13.0, *)) {
        self.availableStyleKeys =
        @[
          PTAnnotStyleKeyTextColor,
          PTAnnotStyleKeyStrokeColor,
          PTAnnotStyleKeyFont,
          PTAnnotStyleKeyThickness,
          PTAnnotStyleKeyTextSize,
          PTAnnotStyleKeyOpacity,
          ];
    } else {
        self.availableStyleKeys =
        @[
          PTAnnotStyleKeyTextColor,
          PTAnnotStyleKeyStrokeColor,
          PTAnnotStyleKeyThickness,
          PTAnnotStyleKeyTextSize,
          PTAnnotStyleKeyOpacity,
          ];
    }


    if ([self.annot IsValid]) {
        PTFreeText *freeText = [[PTFreeText alloc] initWithAnn:self.annot];

        [self loadTextColorWithFreeText:freeText];
        [self loadBorderColorWithFreeText:freeText];
        [self loadThickness];
        [self loadTextSizeWithFreeText:freeText];
        [self loadOpacityWithMarkup:freeText];
        [self loadFontNameWithFreeText:freeText];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultTextColor];
        [self loadDefaultBorderColor];
        [self loadDefaultThickness];
        [self loadDefaultTextSize];
        [self loadDefaultOpacity];
        [self loadDefaultFont];
    }
}

- (void)configureFreeHand
{
    self.availableStyleKeys =
    @[
      PTAnnotStyleKeyColor,
      PTAnnotStyleKeyThickness,
      PTAnnotStyleKeyOpacity,
      ];

    if ([self.annot IsValid]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.annot];

        [self loadStrokeColor];
        [self loadThickness];
        [self loadOpacityWithMarkup:markup];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultStrokeColor];
        [self loadDefaultThickness];
        [self loadDefaultOpacity];
    }
}

- (void)configureMarkup
{
    self.availableStyleKeys =
    @[
      PTAnnotStyleKeyStrokeColor,
      PTAnnotStyleKeyFillColor,
      PTAnnotStyleKeyThickness,
      PTAnnotStyleKeyOpacity,
      ];

    if ([self.annot IsValid]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.annot];

        [self loadStrokeColor];
        [self loadFillColorWithMarkup:markup];
        [self loadThickness];
        [self loadOpacityWithMarkup:markup];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultStrokeColor];
        [self loadDefaultFillColor];
        [self loadDefaultThickness];
        [self loadDefaultOpacity];
    }
}

- (void)configureHighlight
{
    self.availableStyleKeys =
    @[
      PTAnnotStyleKeyColor,
      PTAnnotStyleKeyOpacity,
      ];

    if ([self.annot IsValid]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.annot];

        [self loadStrokeColor];
        [self loadOpacityWithMarkup:markup];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultStrokeColor];
        [self loadDefaultOpacity];
    }
}

- (void)configureTextAnnot
{
    self.availableStyleKeys =
    @[
      PTAnnotStyleKeyColor,
      PTAnnotStyleKeyThickness,
      PTAnnotStyleKeyOpacity,
      ];

    if ([self.annot IsValid]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.annot];

        [self loadStrokeColor];
        [self loadThickness];
        [self loadOpacityWithMarkup:markup];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultStrokeColor];
        [self loadDefaultThickness];
        [self loadDefaultOpacity];
        [self loadDefaultFont];
    }
}

- (void)configureRedaction
{
    self.availableStyleKeys =
    @[
      PTAnnotStyleKeyStrokeColor,
      PTAnnotStyleKeyFillColor,
      PTAnnotStyleKeyThickness,
      PTAnnotStyleKeyOpacity,
      PTAnnotStyleKeyLabel,
      ];

    if ([self.annot IsValid]) {
        PTRedactionAnnot *redaction = [[PTRedactionAnnot alloc] initWithAnn:self.annot];

        [self loadStrokeColor];
        [self loadFillColorWithMarkup:redaction];
        [self loadThickness];
        [self loadOpacityWithMarkup:redaction];
        [self loadOverlayTextWithRedaction:redaction];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultStrokeColor];
        [self loadDefaultFillColor];
        [self loadDefaultThickness];
        [self loadDefaultOpacity];
        [self loadDefaultOverlayText];
    }
}

- (void)configureLengthMeasure
{
    self.availableStyleKeys =
    @[
      PTAnnotStyleKeyColor,
      PTAnnotStyleKeyThickness,
      PTAnnotStyleKeyOpacity,
      PTAnnotStyleKeyScale,
      PTAnnotStyleKeyPrecision,
      PTAnnotStyleKeySnapping,
      ];

    if ([self.annot IsValid]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.annot];

        [self loadStrokeColor];
        [self loadThickness];
        [self loadOpacityWithMarkup:markup];
        [self loadMeasurementData];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultStrokeColor];
        [self loadDefaultThickness];
        [self loadDefaultOpacity];
        [self loadDefaultMeasurementData];
    }
}

- (void)configureAreaMeasure
{
    self.availableStyleKeys =
    @[
      PTAnnotStyleKeyStrokeColor,
      PTAnnotStyleKeyFillColor,
      PTAnnotStyleKeyThickness,
      PTAnnotStyleKeyOpacity,
      PTAnnotStyleKeyScale,
      PTAnnotStyleKeyPrecision,
      PTAnnotStyleKeySnapping
      ];

    if ([self.annot IsValid]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.annot];

        [self loadStrokeColor];
        [self loadFillColorWithMarkup:markup];
        [self loadThickness];
        [self loadOpacityWithMarkup:markup];
        [self loadMeasurementData];
    } else {
        // Load defaults for annotation type.
        [self loadDefaultStrokeColor];
        [self loadDefaultFillColor];
        [self loadDefaultThickness];
        [self loadDefaultOpacity];
        [self loadDefaultMeasurementData];
    }
}

#pragma mark - Annotation saving

- (void)saveChanges
{
    [self applyToAnnotation:self.annot doc:self.pdfDoc];
    
    if (self.saveValuesAsDefaults) {
        [self setCurrentValuesAsDefaults];
    }
}

- (void)applyToAnnotation:(PTAnnot *)annotation
{
    [self applyToAnnotation:annotation doc:nil];
}

- (void)applyToAnnotation:(PTAnnot *)annotation doc:(nullable PTPDFDoc *)doc
{
    if (![annotation IsValid]) {
        return;
    }
    

    
    const PTExtendedAnnotType annotType = annotation.extendedAnnotType;
    switch (annotType) {
        case PTExtendedAnnotTypeText:
            break;
        case PTExtendedAnnotTypeLink:
            break;
        case PTExtendedAnnotTypeFreeText:
        case PTExtendedAnnotTypeCallout:
            if( doc == Nil && self.pdfDoc)
            {
                doc = self.pdfDoc;
            }
            NSAssert(doc, @"doc cannot be nil");
            [self saveFreeText:annotation doc:doc];
            break;
        case PTExtendedAnnotTypeLine:
        case PTExtendedAnnotTypeArrow:
            [self saveFreeHand:annotation];
            break;
        case PTExtendedAnnotTypeRuler:
        case PTExtendedAnnotTypePerimeter:
            [self saveFreeHand:annotation];
            [self saveMeasurement:annotation];
            break;
        case PTExtendedAnnotTypeSquare:
            [self saveMarkup:annotation];
            break;
        case PTExtendedAnnotTypeCircle:
            [self saveMarkup:annotation];
            break;
        case PTExtendedAnnotTypePolygon:
        case PTExtendedAnnotTypeCloudy:
            [self saveMarkup:annotation];
            break;
        case PTExtendedAnnotTypeArea:
            [self saveMarkup:annotation];
            [self saveMeasurement:annotation];
            break;
        case PTExtendedAnnotTypePolyline:
            [self saveFreeHand:annotation];
            break;
        case PTExtendedAnnotTypeHighlight:
            [self saveHighlight:annotation];
            break;
        case PTExtendedAnnotTypeUnderline:
            [self saveTextAnnot:annotation];
            break;
        case PTExtendedAnnotTypeSquiggly:
            [self saveTextAnnot:annotation];
            break;
        case PTExtendedAnnotTypeStrikeOut:
            [self saveTextAnnot:annotation];
            break;
        case PTExtendedAnnotTypeStamp:
        case PTExtendedAnnotTypeImageStamp:
        case PTExtendedAnnotTypeSignature:
            break;
        case PTExtendedAnnotTypeCaret:
            break;
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypeFreehandHighlight:
            [self saveFreeHand:annotation];
            break;
        case PTExtendedAnnotTypePopup:
            break;
        case PTExtendedAnnotTypeFileAttachment:
            break;
        case PTExtendedAnnotTypeSound:
            break;
        case PTExtendedAnnotTypeMovie:
            break;
        case PTExtendedAnnotTypeWidget:
            break;
        case PTExtendedAnnotTypeScreen:
            break;
        case PTExtendedAnnotTypePrinterMark:
            break;
        case PTExtendedAnnotTypeTrapNet:
            break;
        case PTExtendedAnnotTypeWatermark:
            break;
        case PTExtendedAnnotType3D:
            break;
        case PTExtendedAnnotTypeRedact:
            [self saveRedaction:annotation];
            break;
        case PTExtendedAnnotTypeProjection:
            break;
        case PTExtendedAnnotTypeRichMedia:
            break;
        case PTExtendedAnnotTypePencilDrawing:
            break;
        case PTExtendedAnnotTypeUnknown:
            break;
    }
    
    if (annotType != PTExtendedAnnotTypeFreeText) {
        [annotation RefreshAppearance];
    }
}

- (void)saveFreeText:(PTAnnot *)annot doc:(PTPDFDoc *)doc
{
    PTFreeText *freeText = [[PTFreeText alloc] initWithAnn:annot];
    
    
    
    [self saveTextColorForFreeText:freeText];
    [self saveBorderColorForFreeText:freeText];
    [self saveThicknessForAnnot:freeText];
    [self saveTextFontWithFreeText:freeText onDoc:doc];
    [self saveTextSizeWithFreeText:freeText];
    [self saveOpacityForMarkup:freeText];
    
    if (freeText.extendedAnnotType == PTExtendedAnnotTypeFreeText) {
        [PTFreeTextCreate refreshAppearanceForAnnot:freeText onDoc:doc];
    }
}

- (void)saveFreeHand:(PTAnnot *)annot
{
    PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];
    
    [self saveStrokeColorForAnnot:markup];
    [self saveThicknessForAnnot:markup];
    [self saveOpacityForMarkup:markup];
}

- (void)saveMarkup:(PTAnnot *)annot
{
    PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];

    [self saveStrokeColorForAnnot:markup];
    [self saveFillColorForMarkup:markup];
    [self saveThicknessForAnnot:markup];
    [self saveOpacityForMarkup:markup];
}

- (void)saveHighlight:(PTAnnot *)annot
{
    PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];

    [self saveStrokeColorForAnnot:markup];
    [self saveOpacityForMarkup:markup];
}

- (void)saveTextAnnot:(PTAnnot *)annot
{
    PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];

    [self saveStrokeColorForAnnot:markup];
    [self saveThicknessForAnnot:markup];
    [self saveOpacityForMarkup:markup];
}

- (void)saveRedaction:(PTAnnot *)annot
{
    PTRedactionAnnot *redaction = [[PTRedactionAnnot alloc] initWithAnn:annot];
    
    [self saveStrokeColorForAnnot:redaction];
    [self saveFillColorForMarkup:redaction];
    [self saveOpacityForMarkup:redaction];
    [self saveOverlayTextForRedaction:redaction];
}

- (void)saveMeasurement:(PTAnnot *)annot
{
    [PTMeasurementUtil setAnnotMeasurementData:annot fromMeasurementScale:self.measurementScale];
}

- (void)setCurrentValuesAsDefaults
{
    PTExtendedAnnotType annotType = self.annotType;

    for (PTAnnotStyleKey key in self.availableStyleKeys) {
        if ([key isEqualToString:PTAnnotStyleKeyColor]) {
            [PTColorDefaults setDefaultColor:self.color
                              forAnnotType:annotType
                                 attribute:ATTRIBUTE_STROKE_COLOR
                      colorPostProcessMode:e_ptpostprocess_none];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyStrokeColor]) {
            [PTColorDefaults setDefaultColor:self.strokeColor
                              forAnnotType:annotType
                                 attribute:ATTRIBUTE_STROKE_COLOR
                      colorPostProcessMode:e_ptpostprocess_none];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyFillColor]) {
            [PTColorDefaults setDefaultColor:self.fillColor
                              forAnnotType:annotType
                                 attribute:ATTRIBUTE_FILL_COLOR
                      colorPostProcessMode:e_ptpostprocess_none];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyTextColor]) {
            [PTColorDefaults setDefaultColor:self.textColor
                              forAnnotType:annotType
                                 attribute:ATTRIBUTE_TEXT_COLOR
                      colorPostProcessMode:e_ptpostprocess_none];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyThickness]) {
            [PTColorDefaults setDefaultBorderThickness:self.thickness forAnnotType:annotType];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyOpacity]) {
            [PTColorDefaults setDefaultOpacity:self.opacity forAnnotType:annotType];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyTextSize]) {
            [PTColorDefaults setDefaultFreeTextSize:self.textSize];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyFont]) {
            [PTColorDefaults setDefaultFreeTextFontName:self.fontName];
        }
        else if ([key isEqualToString:PTAnnotStyleKeyScale] || [key isEqualToString:PTAnnotStyleKeyPrecision]) {
            [PTColorDefaults setDefaultMeasurementScale:self.measurementScale forAnnotType:annotType];
        }
    }
}

#pragma mark - Annotation property loading

- (void)loadDefaultTextColor
{
    self.textColor = [PTColorDefaults defaultColorForAnnotType:self.annotType
                                                   attribute:ATTRIBUTE_TEXT_COLOR
                                        colorPostProcessMode:e_ptpostprocess_none];
}

- (void)loadTextColorWithFreeText:(PTFreeText *)freeText
{
    self.textColor = [PTColorDefaults uiColorFromColorPt:[freeText GetTextColor]
                                               compNum:[freeText GetTextColorCompNum]];
}

- (void)loadDefaultTextSize
{
    self.textSize = [PTColorDefaults defaultFreeTextSize];
}

- (void)loadTextSizeWithFreeText:(PTFreeText *)freeText
{
    self.textSize = [freeText GetFontSize];
}

- (void)loadDefaultStrokeColor
{
    self.strokeColor = [PTColorDefaults defaultColorForAnnotType:self.annotType
                                                     attribute:ATTRIBUTE_STROKE_COLOR
                                          colorPostProcessMode:e_ptpostprocess_none];
}

- (void)loadStrokeColor
{
    const int compNum = [self.annot GetColorCompNum];
    if (compNum > 0) {
        self.strokeColor = [PTColorDefaults uiColorFromColorPt:[self.annot GetColorAsRGB] compNum:3];
    } else {
        self.strokeColor = UIColor.clearColor;
    }
}

- (void)loadDefaultFillColor
{
    self.fillColor = [PTColorDefaults defaultColorForAnnotType:self.annotType
                                                   attribute:ATTRIBUTE_FILL_COLOR
                                        colorPostProcessMode:e_ptpostprocess_none];
}

- (void)loadFillColorWithMarkup:(PTMarkup *)markup
{
    self.fillColor = [PTColorDefaults uiColorFromColorPt:[markup GetInteriorColor]
                                               compNum:[markup GetInteriorColorCompNum]];
}

- (void)loadBorderColorWithFreeText:(PTFreeText *)freeText
{
    self.strokeColor = [PTColorDefaults uiColorFromColorPt:[freeText GetLineColor]
                                                 compNum:[freeText GetLineColorCompNum]];
}

- (void)loadDefaultBorderColor
{
    self.strokeColor = [PTColorDefaults defaultColorForAnnotType:self.annotType
                                                     attribute:ATTRIBUTE_STROKE_COLOR
                                          colorPostProcessMode:e_ptpostprocess_none];
}

- (void)loadDefaultThickness
{
    self.thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];
}

- (void)loadThickness
{
    BOOL hasStoredThickness = NO;
    
    if (self.annot.extendedAnnotType == PTExtendedAnnotTypeFreeText) {
        NSAssert(self.strokeColor != nil,
                 @"strokeColor must be loaded before thickness");
        
        if (CGColorGetAlpha(self.strokeColor.CGColor) == 0.0) {
            // Restore stored thickness from SDFObj.
            PTObj *obj = [self.annot GetSDFObj];
            PTObj *thicknessObj = [obj FindObj:kAnnotStylePDFTronThicknessKey];
            if ([thicknessObj IsValid] && [thicknessObj IsNumber]) {
                self.thickness = [thicknessObj GetNumber];
                hasStoredThickness = YES;
            }
        }
    }
    
    if (!hasStoredThickness) {
        PTBorderStyle *borderStyle = [self.annot GetBorderStyle];
        self.thickness = [borderStyle GetWidth];
    }
}

- (void)loadDefaultOpacity
{
    self.opacity = [PTColorDefaults defaultOpacityForAnnotType:self.annotType];
}

- (void)loadDefaultFont
{
    NSString* fontName = [PTColorDefaults defaultFreeTextFontName];
    self.fontName = fontName;
}

- (void)loadOpacityWithMarkup:(PTMarkup *)markup
{
    self.opacity = [markup GetOpacity];
}

-(void)loadFontNameWithFreeText:(PTFreeText*)freeText
{
    self.fontName = [freeText getFontName];
}

- (void)loadDefaultOverlayText
{
    self.label = nil;
}

- (void)loadOverlayTextWithRedaction:(PTRedactionAnnot *)redaction
{
    self.label = [redaction GetOverlayText];
}

- (void)loadDefaultMeasurementData
{
    self.measurementScale = [PTColorDefaults defaultMeasurementScaleForAnnotType:self.annotType];
}

- (void)loadMeasurementData
{
    self.measurementScale = [PTMeasurementUtil getMeasurementScaleFromAnnot:self.annot];
}

#pragma mark - Annotation property saving

- (void)saveTextColorForFreeText:(PTFreeText *)freeText
{
    PTColorPt *colorPt = [PTColorDefaults colorPtFromUIColor:self.textColor];
    int numComps = [PTColorDefaults numCompsInColorPtForUIColor:self.textColor];

    [freeText SetTextColor:colorPt col_comp:numComps];
}

- (void)saveStrokeColorForAnnot:(PTAnnot *)annot
{
    
    PTColorPt *colorPt = [PTColorDefaults colorPtFromUIColor:self.strokeColor];
    int numComps = [PTColorDefaults numCompsInColorPtForUIColor:self.strokeColor];
    
    [annot SetColor:colorPt numcomp:numComps];
}

- (void)saveFillColorForMarkup:(PTMarkup *)markup
{
    PTColorPt *colorPt = [PTColorDefaults colorPtFromUIColor:self.fillColor];
    int numComps = [PTColorDefaults numCompsInColorPtForUIColor:self.fillColor];

    [markup SetInteriorColor:colorPt CompNum:numComps];
}

- (void)saveBorderColorForFreeText:(PTFreeText *)freeText
{
    PTColorPt *colorPt = [PTColorDefaults colorPtFromUIColor:self.strokeColor];
    int numComps = [PTColorDefaults numCompsInColorPtForUIColor:self.strokeColor];

    [freeText SetLineColor:colorPt col_comp:numComps];
}

- (void)saveThicknessForAnnot:(PTAnnot *)annot
{
    const PTExtendedAnnotType annotType = annot.extendedAnnotType;
    
    CGFloat thickness = self.thickness;
    
    if (self.annotType == PTExtendedAnnotTypeFreeText) {
        if (CGColorGetAlpha(self.strokeColor.CGColor) == 0.0) {
            // Store original thickness in SDFObj and set thickness to 0.
            PTObj *obj = [annot GetSDFObj];
            if ([obj IsValid]) {
                [obj PutNumber:kAnnotStylePDFTronThicknessKey value:thickness];
            }
            thickness = 0;
        }
    }
    
    // Adjust ruler annotation text vertical offset.
    if (annotType == PTExtendedAnnotTypeRuler) {
        const double offset = thickness / 2;
        PTLineAnnot *line = [[PTLineAnnot alloc] initWithAnn:annot];
        [line SetTextVOffset:offset];
    }
    
    PTBorderStyle *borderStyle = [annot GetBorderStyle];
    [borderStyle SetWidth:thickness];
    [annot SetBorderStyle:borderStyle oldStyleOnly:NO];
}

- (void)saveOpacityForMarkup:(PTMarkup *)markup
{
    [markup SetOpacity:self.opacity];
}

- (void)saveTextSizeWithFreeText:(PTFreeText *)freeText
{
    [freeText SetFontSize:self.textSize];
}

- (void)saveTextFontWithFreeText:(PTFreeText *)freeText onDoc:(PTPDFDoc*)doc
{
    [freeText setFontWithName:self.fontName pdfDoc:doc];
}

- (void)saveOverlayTextForRedaction:(PTRedactionAnnot *)redaction
{
    NSString *label = self.label;
    if (!label) {
        label = @"";
    }
    [redaction SetOverlayText:label];
}

#pragma mark - Property accessors

// Synthesize annotType for when annot property is nil.
@synthesize annotType = _annotType;

- (PTExtendedAnnotType)annotType
{
    if (self.annot) {
        return self.annot.extendedAnnotType;
    }

    return _annotType;
}

- (UIColor *)color
{
    return _strokeColor;
}

- (void)setColor:(UIColor *)color
{
    
    if( [_strokeColor isEqual:color] )
    {
        // no change
        return;
    }
    
    _strokeColor = color;

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:colorDidChange:)]) {
        [self.delegate annotStyle:self colorDidChange:color];
    }
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingColor
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTAnnotStyle, strokeColor),
    ]];
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
    
    if( [_strokeColor isEqual:strokeColor] )
    {
        // no change
        return;
    }
    
    
    _strokeColor = strokeColor;
    
    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:strokeColorDidChange:)]) {
        [self.delegate annotStyle:self strokeColorDidChange:strokeColor];
    }
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingStrokeColor
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTAnnotStyle, color),
    ]];
}

- (void)setFillColor:(UIColor *)fillColor
{
    
    if( [_fillColor isEqual:fillColor] )
    {
        // no change
        return;
    }
    
    _fillColor = fillColor;

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:fillColorDidChange:)]) {
        [self.delegate annotStyle:self fillColorDidChange:fillColor];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    
    if( [_textColor isEqual:textColor] )
    {
        // no change
        return;
    }
    
    
    _textColor = textColor;

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:textColorDidChange:)]) {
        [self.delegate annotStyle:self textColorDidChange:textColor];
    }
}

- (void)setThickness:(CGFloat)thickness
{
    
    if( _thickness == thickness )
    {
        // no change
        return;
    }
    
    _thickness = thickness;

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:thicknessDidChange:)]) {
        [self.delegate annotStyle:self thicknessDidChange:thickness];
    }
}

- (void)setOpacity:(CGFloat)opacity
{
    if( _opacity == opacity )
    {
        // no change
        return;
    }
    
    _opacity = opacity;

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:opacityDidChange:)]) {
        [self.delegate annotStyle:self opacityDidChange:opacity];
    }
}

- (void)setTextSize:(CGFloat)textSize
{
    
    if( _textSize == textSize )
    {
        // no change
        return;
    }
    
    _textSize = textSize;

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:textSizeDidChange:)]) {
        [self.delegate annotStyle:self textSizeDidChange:textSize];
    }
}

-(void)setFontName:(NSString*)fontName
{
    if( [_fontName isEqualToString:fontName] )
    {
        // no change
        return;
    }
    
    _fontName = fontName;
    
    if ([self.delegate respondsToSelector:@selector(annotStyle:fontNameDidChange:)]) {
        [self.delegate annotStyle:self fontNameDidChange:fontName];
    }
}

- (void)setLabel:(NSString *)label
{
    if (label && [_label isEqualToString:label]) {
        // no change
        return;
    }
    
    _label = label;

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyle:labelDidChange:)]) {
        [self.delegate annotStyle:self labelDidChange:label];
    }
}

- (void)setMeasurementScale:(PTMeasurementScale *)measurementScale
{


//    if( [_measurementScale isEqual:measurementScale] )
//    {
//        // no change
//        return;
//    }
    
    _measurementScale = measurementScale;
    if ([self.delegate respondsToSelector:@selector(annotStyle:measurementScaleDidChange:)]) {
        [self.delegate annotStyle:self measurementScaleDidChange:measurementScale];
    }
}

- (void)setSnappingEnabled:(BOOL)snappingEnabled
{
    if( _snappingEnabled  == snappingEnabled )
    {
        // no change
        return;
    }
    
    _snappingEnabled = snappingEnabled;
    if ([self.delegate respondsToSelector:@selector(annotStyle:snappingToggled:)]) {
        [self.delegate annotStyle:self snappingToggled:snappingEnabled];
    }
}


- (NSString *)thicknessIndicatorString
{
    return [NSString stringWithFormat:@"%ld pt", (long) self.thickness];
}


- (NSString *)opacityIndicatorString
{
    return [NSString stringWithFormat:@"%ld%%", (long) (self.opacity * 100.0)];
}


- (NSString *)textSizeIndicatorString
{
    return [NSString stringWithFormat:@"%ld pt", (long) self.textSize];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [self isEqualToAnnotStyle:(PTAnnotStyle *)object];
}

- (BOOL)isEqualToAnnotStyle:(PTAnnotStyle *)annotStyle
{
    // Check object-typed properties.
    NSArray<NSString *> *objectPropertyKeys = @[
        PT_SELF_KEY(strokeColor),
        PT_SELF_KEY(fillColor),
        PT_SELF_KEY(textColor),
        PT_SELF_KEY(label),
        PT_SELF_KEY(measurementScale),
    ];
    
    for (NSString *objectPropertyKey in objectPropertyKeys) {
        id selfValue = [self valueForKey:objectPropertyKey];
        id otherValue = [annotStyle valueForKey:objectPropertyKey];
        
        if (selfValue == otherValue || [selfValue isEqual:otherValue]) {
            continue;
        } else {
            return NO;
        }
    }
    
    // Check primitive properties.
    return (self.annotType == annotStyle.annotType &&
            self.thickness == annotStyle.thickness &&
            self.opacity == annotStyle.opacity &&
            self.textSize == annotStyle.textSize &&
            self.snappingEnabled == annotStyle.snappingEnabled &&
            self.saveValuesAsDefaults == annotStyle.saveValuesAsDefaults);
}

@end
