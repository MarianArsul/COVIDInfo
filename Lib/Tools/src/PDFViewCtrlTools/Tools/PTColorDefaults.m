//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTColorDefaults.h"
#import "PTMeasurementUtil.h"

#ifndef PTClamp

#define PTClamp(x, lower, upper) \
    MAX((lower), MIN((x), (upper)))

#endif /* PTClamp */

@implementation PTColorDefaults

#pragma mark - Helpers

+(PTColorPt*)colorPtFromUIColor:(UIColor*)uiColor
{
    CGColorRef colorRef = uiColor.CGColor;
    
    // Check for transparent color.
    if (CGColorGetAlpha(colorRef) == 0.0) {
        return [[PTColorPt alloc] initWithX:0 y:0 z:0 w:0];
    }
    
    // Convert to RGB colorspace.
    CGFloat red, green, blue;
    BOOL success = [uiColor getRed:&red green:&green blue:&blue alpha:nil];
    if (success) {
        if (@available(iOS 10, *)) {
            // Convert colors in the extended sRGB color space to sRGB.
            red = PTClamp(red, 0, 1);
            green = PTClamp(green, 0, 1);
            blue = PTClamp(blue, 0, 1);
        }
        
        return [[PTColorPt alloc] initWithX:red y:green z:blue w:0];
    }
    
    // Fallback.
    const CGFloat *components = CGColorGetComponents(colorRef);
    
    switch (CGColorGetNumberOfComponents(colorRef)) {
        case (1):
            return [[PTColorPt alloc] initWithX:components[0] y:0 z:0 w:0];
        case (2):
            return [[PTColorPt alloc] initWithX:components[0] y:components[1] z:0 w:0];
        case (3):
            return [[PTColorPt alloc] initWithX:components[0] y:components[1] z:components[2] w:0];
        case (4):
            return [[PTColorPt alloc] initWithX:components[0] y:components[1] z:components[2] w:components[3]];
        default:
            return [[PTColorPt alloc] initWithX:0 y:0 z:0 w:0];
    }
}

+ (int)numCompsInColorPtForUIColor:(UIColor *)color
{
    CGColorRef colorRef = color.CGColor;
    
    // Check for transparent color.
    if (CGColorGetAlpha(colorRef) == 0.0) {
        return 0;
    }
    
    // Convert color to RGBA colorspace.
    CGFloat red, green, blue, alpha;
    BOOL success = [color getRed:&red green:&green blue:&blue alpha:&alpha];
    if (success) {
        return 3;
    }
    
    // Fallback.
    if (CGColorGetNumberOfComponents(colorRef) > 3) {
        return 3;
    }
    else {
        return 0;
    }
}

+(const CGFloat*)colorComponentsInUIColor:(UIColor*)uiColor
{
	CGColorRef chosenCGColor = uiColor.CGColor;
	return CGColorGetComponents(chosenCGColor);
}

+(UIColor*)uiColorFromColorPt:(PTColorPt*)colorpt compNum:(int)compNum
{
    if (compNum == 0) { // Transparent.
        return [UIColor clearColor];
    }
    
    PTColorSpace *colorSpace = nil;
    PTColorPt *rgbColorPt = nil;
    UIColor *uiColor = nil;
    
    switch (compNum) {
        case (1):
            colorSpace = [PTColorSpace CreateDeviceGray];
            break;
        case (3):
            // Already in RGB color space.
            rgbColorPt = colorpt;
            break;
        case (4):
            colorSpace = [PTColorSpace CreateDeviceCMYK];
            break;
        default:
            // Can't convert color.
            break;
    }
    
    if (colorSpace) {
        rgbColorPt = [colorSpace Convert2RGB:colorpt];
    }
    
    if (rgbColorPt) {
        uiColor = [UIColor colorWithRed:[rgbColorPt Get:0] green:[rgbColorPt Get:1] blue:[rgbColorPt Get:2] alpha:1.0];
    }
    
    return uiColor;
}

+(UIColor*)inverseUIColor:(UIColor*)color
{
	//return color;
	CGFloat r, g, b, a;
	[color getRed:&r green:&g blue:&b alpha:&a];
	return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

+(PTColorPt*)inverseColorPt:(PTColorPt*)colorpt
{
	//return colorpt;
	double x, y, z, w;
	x = 1.-[colorpt Get:0];
	y = 1.-[colorpt Get:1];
	z = 1.-[colorpt Get:2];
	w = 1.-[colorpt Get:3];
	
	return [[PTColorPt alloc] initWithX:x y:y z:z w:w];
}

+(NSString*)keyForAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute
{
    NSString* annotType = PTExtendedAnnotNameFromType(type);
    
    // If the PTExtendedAnnotName cannot be determined, set the key to a generic string
    if (!annotType) {
        annotType = @"markup";
    }
    return [annotType stringByAppendingString:attribute];
}

#pragma mark - Colors

+(void)setDefaultColor:(UIColor*)color forAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute colorPostProcessMode:(PTColorPostProcessMode)mode
{
	NSString* key = [self keyForAnnotType:type attribute:attribute];
	if( mode == e_ptpostprocess_invert)
		color = [self inverseUIColor:color];
	
	NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
	[[NSUserDefaults standardUserDefaults] setObject:colorData forKey:key];
}

+(UIColor*)defaultColorForAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute colorPostProcessMode:(PTColorPostProcessMode)mode
{
	NSString* key = [self keyForAnnotType:type attribute:attribute];
	NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	UIColor* returnColor;
	
	if( !colorData )
	{
        if( type == PTExtendedAnnotTypeHighlight ) {
			returnColor = [UIColor yellowColor];
        } else if ([attribute  isEqualToString:ATTRIBUTE_FILL_COLOR] ) {
			returnColor = [UIColor clearColor];
        } else if (type == PTExtendedAnnotTypeFreeText && [attribute  isEqualToString:ATTRIBUTE_STROKE_COLOR] ) {
            returnColor = [UIColor clearColor];
        } else {
			returnColor = [UIColor redColor];
        }
    } else {
        returnColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    }
	
    if( mode == e_ptpostprocess_invert ) {
		returnColor = [self inverseUIColor:returnColor];
    }
	
    return returnColor;
}

+(PTColorPt*)defaultColorPtForAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute colorPostProcessMode:(PTColorPostProcessMode)mode
{
	NSString* key = [self keyForAnnotType:type attribute:attribute];
	NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	PTColorPt* returnColor;
	
	if( !colorData )
	{
        if( type == PTExtendedAnnotTypeHighlight ) {
			returnColor = [self colorPtFromUIColor:[UIColor yellowColor]];
        } else if ([attribute  isEqualToString:ATTRIBUTE_FILL_COLOR] ) {
			returnColor =  [self colorPtFromUIColor:[UIColor clearColor]];
        } else if (type == PTExtendedAnnotTypeFreeText && [attribute  isEqualToString:ATTRIBUTE_STROKE_COLOR] ) {
            returnColor = [self colorPtFromUIColor:[UIColor clearColor]];
        } else {
			returnColor =  [self colorPtFromUIColor:[UIColor redColor]];
        }
    } else {
        returnColor = [self colorPtFromUIColor:[NSKeyedUnarchiver unarchiveObjectWithData:colorData]];
    }
    if( mode == e_ptpostprocess_invert ) {
		returnColor = [self inverseColorPt:returnColor];
    }
    
	return returnColor;
}

+(int)numCompsInColorPtForAnnotType:(PTExtendedAnnotType)type attribute:(NSString*)attribute
{
	// color mode is irrelevant, so fine to pass 0
	UIColor* color = [self defaultColorForAnnotType:type attribute:attribute colorPostProcessMode:0];
    
    return [self numCompsInColorPtForUIColor:color];
}

#pragma mark - Opacity

+(void)setDefaultOpacity:(double)opacity forAnnotType:(PTExtendedAnnotType)type
{
	NSString* key = [self keyForAnnotType:type attribute:ATTRIBUTE_OPACITY];
	[[NSUserDefaults standardUserDefaults] setDouble:opacity forKey:key];
}

+(double)defaultOpacityForAnnotType:(PTExtendedAnnotType)type
{
	NSString* key = [self keyForAnnotType:type attribute:ATTRIBUTE_OPACITY];
	
	if( ![[NSUserDefaults standardUserDefaults] objectForKey:key])
	{
		return 1.0f;
	}
	
	return [[NSUserDefaults standardUserDefaults] doubleForKey:key];
}

#pragma mark - Border Thickness

+(void)setDefaultBorderThickness:(double)thickness forAnnotType:(PTExtendedAnnotType)type
{
	NSString* key = [self keyForAnnotType:type attribute:ATTRIBUTE_BORDER_THICKNESS];
	[[NSUserDefaults standardUserDefaults] setDouble:thickness forKey:key];
}

+(double)defaultBorderThicknessForAnnotType:(PTExtendedAnnotType)type
{
	NSString* key = [self keyForAnnotType:type attribute:ATTRIBUTE_BORDER_THICKNESS];
	
	if( ![[NSUserDefaults standardUserDefaults] objectForKey:key])
	{
        switch (type) {
            case PTExtendedAnnotTypeFreehandHighlight:
                return 20;
            case PTExtendedAnnotTypeFreeText:
                return 0;
            default:
                return 1;
        }
	}
	
	return [[NSUserDefaults standardUserDefaults] doubleForKey:key];
}

#pragma mark - FreeText size

+(void)setDefaultFreeTextSize:(double)size
{
	NSString* key = [self keyForAnnotType:PTExtendedAnnotTypeFreeText attribute:ATTRIBUTE_FREETEXT_SIZE];
	[[NSUserDefaults standardUserDefaults] setDouble:size forKey:key];
}

+(double)defaultFreeTextSize
{
	NSString* key = [self keyForAnnotType:PTExtendedAnnotTypeFreeText attribute:ATTRIBUTE_FREETEXT_SIZE];
	
	if( ![[NSUserDefaults standardUserDefaults] doubleForKey:key])
	{
		return 16.0f;
	}
	
	return [[NSUserDefaults standardUserDefaults] doubleForKey:key];
}

#pragma mark - FreeText font

+(void)setDefaultFreeTextFontName:(NSString*)fontName
{
    NSString* key = [self keyForAnnotType:PTExtendedAnnotTypeFreeText attribute:ATTRIBUTE_FREETEXT_FONT];
    [[NSUserDefaults standardUserDefaults] setObject:fontName forKey:key];
}

+(NSString*)defaultFreeTextFontName
{
    NSString* key = [self keyForAnnotType:PTExtendedAnnotTypeFreeText attribute:ATTRIBUTE_FREETEXT_FONT];
    
    if( ![[NSUserDefaults standardUserDefaults] objectForKey:key])
    {
        return @"Helvetica";
    }
    
    return (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:key];
}

#pragma mark - Measurement info: Scale and Precision

+ (void)setDefaultMeasurementScale:(PTMeasurementScale *)measurementScale forAnnotType:(PTExtendedAnnotType)type
{
    NSString* key = [self keyForAnnotType:type attribute:ATTRIBUTE_MEASUREMENT_SCALE];
    NSData *measurementData = [NSKeyedArchiver archivedDataWithRootObject:measurementScale];
    [[NSUserDefaults standardUserDefaults] setObject:measurementData forKey:key];
}

+ (PTMeasurementScale *)defaultMeasurementScaleForAnnotType:(PTExtendedAnnotType)type{
    NSString* key = [self keyForAnnotType:type attribute:ATTRIBUTE_MEASUREMENT_SCALE];
    
    if( ![[NSUserDefaults standardUserDefaults] objectForKey:key])
    {
        PTMeasurement *defaultMeasurement = [PTMeasurementUtil getDefaultMeasurementData];
        if (type == PTExtendedAnnotTypeArea) {
            defaultMeasurement.type = PTMeasurementTypeArea;
        }
        PTMeasurementScale *ruler = [PTMeasurementUtil getMeasurementScaleFromMeasurement:defaultMeasurement];
        return ruler;
    }
    NSData *rulerData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    PTMeasurementScale *measurementScale = [NSKeyedUnarchiver unarchiveObjectWithData:rulerData];
    return measurementScale;
}

@end
