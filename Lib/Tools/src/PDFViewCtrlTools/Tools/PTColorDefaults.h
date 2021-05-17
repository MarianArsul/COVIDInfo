//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/AnnotTypes.h>
#import <Tools/PTMeasurementScale.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>

// annotation attributes
#define ATTRIBUTE_STROKE_COLOR      @"Color"
#define ATTRIBUTE_TEXT_COLOR        @"TextColor"
#define ATTRIBUTE_FILL_COLOR        @"FillColor"
#define ATTRIBUTE_OPACITY           @"Opacity"
#define ATTRIBUTE_BORDER_THICKNESS  @"BorderThickness"
#define ATTRIBUTE_FREETEXT_SIZE     @"FreeTextSize"
#define ATTRIBUTE_FREETEXT_FONT     @"FreeTextFont"
#define ATTRIBUTE_MEASUREMENT_SCALE  @"MeasurementScale"

NS_ASSUME_NONNULL_BEGIN

/**
 * Used to persist annotion properties to user defaults so that the next annotation
 * of that type that is created can have the same properties.
 */
@interface PTColorDefaults : NSObject

/**
 * Sets the default `UIColor` for a given annotation type and attribute.
 *
 * @param type The type of annotation.
 *
 * @param attribute The annotation attribute. Arbitrary strings may be used to define
 * attributes. Standard attributes are defined in the header as `ATTRIBUTE_STROKE_COLOR`,
 * `ATTRIBUTE_FILL_COLOR`, `ATTRIBUTE_OPACITY`, `ATTRIBUTE_BORDER_THICKNESS` and
 * `ATTRIBUTE_FREETEXT_SIZE`.
 *
 * @param mode The color post processing mode.
 *
 *
 */
+(void)setDefaultColor:(UIColor*)color forAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute colorPostProcessMode:(PTColorPostProcessMode)mode;

/**
 * Gets the `UIColor` for a given annotation type and attribute.
 *
 * @param type The type of annotation.
 *
 * @param attribute The annotation attribute. Arbitrary strings may be used to define
 * attributes. Standard attributes are defined in the header as `ATTRIBUTE_STROKE_COLOR`,
 * `ATTRIBUTE_FILL_COLOR`, `ATTRIBUTE_OPACITY`, `ATTRIBUTE_BORDER_THICKNESS` and
 * `ATTRIBUTE_FREETEXT_SIZE`.
 *
 * @param mode The color post processing mode.
 *
 * @return The `PTColorPt`.
 *
 */
+(UIColor*)defaultColorForAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute colorPostProcessMode:(PTColorPostProcessMode)mode;


/**
 * Gets the `PTColorPt` for a given annotation type and attribute.
 *
 * @param type The type of annotation.
 *
 * @param attribute The annotation attribute. Arbitrary strings may be used to define
 * attributes. Standard attributes are defined in the header as `ATTRIBUTE_STROKE_COLOR`,
 * `ATTRIBUTE_FILL_COLOR`, `ATTRIBUTE_OPACITY`, `ATTRIBUTE_BORDER_THICKNESS` and
 * `ATTRIBUTE_FREETEXT_SIZE`.
 *
 * @param mode The color post processing mode.
 *
 * @return The `PTColorPt`.
 *
 */
+(PTColorPt*)defaultColorPtForAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute colorPostProcessMode:(PTColorPostProcessMode)mode;


/**
 * Gets the number of color components for an attribute of an annotation type
 *
 * @param type The type of annotaiton.
 *
 * @param attribute The annotation attribute. Arbitrary strings may be used to define
 * attributes. Standard attributes are defined in the header as `ATTRIBUTE_STROKE_COLOR`,
 * `ATTRIBUTE_FILL_COLOR`, `ATTRIBUTE_OPACITY`, A`TTRIBUTE_BORDER_THICKNESS` and
 * `ATTRIBUTE_FREETEXT_SIZE`.
 *
 * @return The number of components: 0 or 3.
 */
+(int)numCompsInColorPtForAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute;


/**
 * Gets the default opacity for an annotaiton of type `type`.
 *
 * @param opacity The opacity of the annotation, from 0. (fully transparant) to 1. (fully opaque).
 *
 * @param type The type of annotaiton.
 */
+(void)setDefaultOpacity:(double)opacity forAnnotType:(PTExtendedAnnotType)type;

/**
 * Sets the default opacity for an annotaiton of type `type`.
 *
 * @param type The type of annotaiton.
 *
 * @return The opacity of the annotation, from 0. (fully transparant) to 1. (fully opaque).
 */
+(double)defaultOpacityForAnnotType:(PTExtendedAnnotType)type;

/**
 * Sets the default border thickness for an annotaiton of type `type`.
 *
 * @param thickness The thickness of the border in points.
 *
 * @param type The type of annotaiton.
 */
+(void)setDefaultBorderThickness:(double)thickness forAnnotType:(PTExtendedAnnotType)type;

/**
 * Gets the default border thickness for an annotaiton of type `type`.
 *
 * @param type The type of annotaiton.
 *
 * @return The border thickness in points.
 */
+(double)defaultBorderThicknessForAnnotType:(PTExtendedAnnotType)type;

/**
 * Set the font size for a free text annotation.
 *
 * @param size The size of the font in points.
 */
+(void)setDefaultFreeTextSize:(double)size;

/**
 * The font size for free text annotations. If one has not been previous set with
 * `setDefaultFreeTextSize:` it will return 16.0.
 *
 * @return A font size.
 */
+(double)defaultFreeTextSize;

/**
* Set the font name for a free text annotation. This must be the postscript font name,
* which is returned via `myUIFontDescriptor.postscriptName` or `myUIFont.fontName`.
*
* @param fontName The name of the font.
*/
+(void)setDefaultFreeTextFontName:(nullable NSString*)fontName;

/**
* The font name for free text annotations. If one has not been previous set with
* `setDefaultFreeTextFontName:` it will return Helvetica.
*
* @return The name of the font.
*/
+(NSString*)defaultFreeTextFontName;


/**
 * Sets the default scale and precision for a ruler, perimeter, or area annotation.
 *
 * @param measurementScale The `PTMeasurementScale` containing the scale and precision information.
 */
+(void)setDefaultMeasurementScale:(PTMeasurementScale *)measurementScale forAnnotType:(PTExtendedAnnotType)type;

/**
 * The default scale and precision for a ruler, perimeter, or area annotation.
 *
 * @return A a `PTMeasurementScale`.
 */
+(PTMeasurementScale *)defaultMeasurementScaleForAnnotType:(PTExtendedAnnotType)type;

/**
 * Converts a `UIColor` to a `PTColorPt`
 *
 * @param uiColor The `UIColor` to be converted
 *
 * @return A `PTColorPt` that represents the same color as the input `uiColor`
 */
+(PTColorPt*)colorPtFromUIColor:(UIColor*)uiColor;

/**
 * Gets the number of `PTColorPt` components for a given `UIColor`
 *
 * @param color The `UIColor` to examine
 *
 * @return The number of `PTColorPt` components: 0 or 3.
 */
+ (int)numCompsInColorPtForUIColor:(UIColor *)color;

/**
 * Converts a 'PTColorPT` to a `UIColor`
 *
 * @param colorpt The `PTColorPt` to be converted
 *
 * @param compNum The number of colorants (tint components) used in the color point
 *
 * @return A `UIColor` that represents the same color as the input `colorpt`
 */
+(nullable UIColor*)uiColorFromColorPt:(PTColorPt*)colorpt compNum:(int)compNum;

@end

NS_ASSUME_NONNULL_END
