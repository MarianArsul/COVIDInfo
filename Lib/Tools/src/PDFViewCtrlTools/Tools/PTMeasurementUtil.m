//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTMeasurementUtil.h"

#import "AnnotTypes.h"
#import "PTRulerCreate.h"
#import "PTPolylineCreate.h"
#import "PTLineAnnot+PTAdditions.h"
#import "PTPolyLine+PTAdditions.h"
#import "PTPolygon+PTAdditions.h"

#pragma mark - Keys
static NSString * const kMeasure = @"Measure";

static NSString * const kScale = @"scale";
static NSString * const kAxis = @"axis";
static NSString * const kDistance = @"distance";
static NSString * const kArea = @"area";

#pragma mark - Supported Units
static NSString * const uPT = @"pt";
static NSString * const uIN = @"in";
static NSString * const uMM = @"mm";
static NSString * const uCM = @"cm";
static NSString * const uM  = @"m";
static NSString * const uKM = @"km";
static NSString * const uFT = @"ft";
static NSString * const uYD = @"yd";
static NSString * const uMI = @"mi";
static NSString * const uNMI = @"nmi";

static NSString * const kDefaultUnit = @"in";
static int const kDefaultPrecision = 100;

@implementation PTMeasurementUtil

#pragma mark - Measurement Info

+ (PTMeasurement *)getDefaultMeasurementData{
    PTMeasurementInfo *axisInfo = [[PTMeasurementInfo alloc] init];
    [axisInfo setUnit:kDefaultUnit];
    [axisInfo setFactor:[self getUnitsPerInch:kDefaultUnit]/72.0f];
    [axisInfo setDecimalSymbol:@"."];
    [axisInfo setThousandSymbol:@","];
    [axisInfo setDisplay:@"D"];
    [axisInfo setPrecision:kDefaultPrecision];
    [axisInfo setUnitPrefix:@""];
    [axisInfo setUnitSuffix:@""];
    [axisInfo setUnitPosition:@"S"];
    
    PTMeasurementInfo *distanceInfo = [[PTMeasurementInfo alloc] init];
    [distanceInfo setFactor:1];
    [distanceInfo setUnit:kDefaultUnit];
    [distanceInfo setDecimalSymbol:@"."];
    [distanceInfo setThousandSymbol:@","];
    [distanceInfo setDisplay:@"D"];
    [distanceInfo setPrecision:kDefaultPrecision];
    [distanceInfo setUnitPrefix:@""];
    [distanceInfo setUnitSuffix:@""];
    [distanceInfo setUnitPosition:@"S"];
    
    PTMeasurementInfo *areaInfo = [[PTMeasurementInfo alloc] init];
    [areaInfo setFactor:1];
    [areaInfo setUnit:@"sq in"];
    [areaInfo setDecimalSymbol:@"."];
    [areaInfo setThousandSymbol:@","];
    [areaInfo setDisplay:@"D"];
    [areaInfo setPrecision:kDefaultPrecision];
    [areaInfo setUnitPrefix:@""];
    [areaInfo setUnitSuffix:@""];
    [areaInfo setUnitPosition:@"S"];
    
    NSString *scale = [NSString stringWithFormat:@"%.0f %@ = %.0f %@", 1.0f, kDefaultUnit, 1.0f, kDefaultUnit];

    PTMeasurement *measurement = [[PTMeasurement alloc] init];
    measurement.scale = scale;
    measurement.axis = axisInfo;
    measurement.distance = distanceInfo;
    measurement.area = areaInfo;
    measurement.type = PTMeasurementTypeDistance;
    
    return measurement;
}

+ (PTMeasurement *)getAnnotMeasurementData:(PTAnnot *)annot{
    @try {
        if (annot == nil || !annot.IsValid) {
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:@"Annotation is invalid"
                                         userInfo:nil];
            return nil;
        }
        
        PTMeasurementType type = PTMeasurementTypeDistance;
        switch ([annot extendedAnnotType]) {
            case PTExtendedAnnotTypeRuler:
                break;
            case PTExtendedAnnotTypePerimeter:
                break;
            case PTExtendedAnnotTypeArea:
                type = PTMeasurementTypeArea;
                break;
            default:
                return nil;
        }
        PTObj *obj = [annot GetSDFObj];
        PTObj *annotMeasurementObject = [obj FindObj:kMeasure];
        
        
        NSString *scale;
        PTObj *scaleObj = [annotMeasurementObject FindObj:[self getScaleKey]];
        
        if (annotMeasurementObject == nil || scaleObj == nil) {
            return nil;
        }
        
        if (scaleObj != nil && scaleObj.IsString) {
            scale = scaleObj.GetAsPDFText;
        }
        
        PTObj *axisArray = [annotMeasurementObject FindObj:[self getAxisKey]];
        PTMeasurementInfo *axisInfo = [self getInfoFromArrayObj:axisArray];
        
        PTObj *distanceArray = [annotMeasurementObject FindObj:[self getDistanceKey]];
        PTMeasurementInfo *distanceInfo = [self getInfoFromArrayObj:distanceArray];
        
        PTObj *areaArray = [annotMeasurementObject FindObj:[self getAreaKey]];
        PTMeasurementInfo *areaInfo = [self getInfoFromArrayObj:areaArray];
        
        PTMeasurement *measurement = [[PTMeasurement alloc] init];
        measurement.scale = scale;
        measurement.axis = axisInfo;
        measurement.distance = distanceInfo;
        measurement.area = areaInfo;
        measurement.type = type;
        
        return measurement;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
}

+ (PTMeasurementScale *)getMeasurementScaleFromAnnot:(PTAnnot *)annot{
    PTMeasurement *measurement = [PTMeasurementUtil getAnnotMeasurementData:annot];
    PTMeasurementScale *measurementScale = [self getMeasurementScaleFromMeasurement:measurement];
    return measurementScale;
}

+ (PTMeasurementScale *)getMeasurementScaleFromMeasurement:(PTMeasurement *)measurement{
    PTMeasurementScale *measurementScale = [[PTMeasurementScale alloc] init];
    measurementScale.baseUnit = measurement.axis.unit;
    measurementScale.translateValue = measurement.type == PTMeasurementTypeDistance ? measurement.distance.factor : measurement.area.factor;
    measurementScale.translateUnit = measurement.type == PTMeasurementTypeDistance ? measurement.distance.unit : measurement.area.unit;
    measurementScale.precision = measurement.type == PTMeasurementTypeDistance ? measurement.distance.precision : measurement.area.precision;
    measurementScale.baseValue = ( measurementScale.translateValue * [PTMeasurementUtil getUnitsPerInch:measurementScale.baseUnit] ) / ( measurement.axis.factor * 72.0f);
    return measurementScale;
}

+ (void)setAnnotMeasurementData:(PTAnnot *)annot withMeasurement:(PTMeasurement *)measurement{
    @try {
        if (annot == nil || !annot.IsValid) {
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:@"Annotation is invalid"
                                         userInfo:nil];
            return;
        }
        NSString *it;

        if ([annot extendedAnnotType] == PTExtendedAnnotTypeRuler) {
            it = @"LineDimension";
        } else if ([annot extendedAnnotType] == PTExtendedAnnotTypePerimeter) {
            it = @"PolyLineDimension";
        } else if ([annot extendedAnnotType] == PTExtendedAnnotTypeArea) {
            it = @"PolygonDimension";
        }
        
        NSString *scale  = measurement.scale;
        PTMeasurementInfo *axisInfo = measurement.axis;
        PTMeasurementInfo *distanceInfo = measurement.distance;
        PTMeasurementInfo *areaInfo = measurement.area;
        
        if (scale == nil || axisInfo == nil || distanceInfo == nil || areaInfo == nil) {
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:@"Unable to read measurement information"
                                         userInfo:nil];
            return;
        }
        
        PTObj *obj = [annot GetSDFObj];
        
        [obj PutName:@"IT" name:it];
        
        PTObj *annotMeasurementObject = [obj PutDict:kMeasure];
        [annotMeasurementObject PutName:[self getTypeKey] name:kMeasure];
        [annotMeasurementObject PutString:[self getScaleKey] value:scale];
        
        PTObj *axisArray = [annotMeasurementObject PutArray:[self getAxisKey]];
        PTObj *distanceArray = [annotMeasurementObject PutArray:[self getDistanceKey]];
        PTObj *areaArray = [annotMeasurementObject PutArray:[self getAreaKey]];

        PTObj *axis = [axisArray PushBackDict];
        [PTMeasurementUtil setObjFromMeasurementInfo:axis axisInfo:axisInfo withArray:axisArray];

        PTObj *distance = [distanceArray PushBackDict];
        [PTMeasurementUtil setObjFromMeasurementInfo:distance axisInfo:distanceInfo withArray:distanceArray];

        PTObj *area = [areaArray PushBackDict];
        [PTMeasurementUtil setObjFromMeasurementInfo:area axisInfo:areaInfo withArray:areaArray];

        [PTMeasurementUtil setContentsForAnnot:annot];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
}

+ (void)setAnnotMeasurementData:(PTAnnot *)annot fromMeasurementScale:(PTMeasurementScale *)measurementScale{
    PTMeasurement *measurement = [PTMeasurementUtil getAnnotMeasurementData:annot];
    if (measurement == nil) {
        measurement = [PTMeasurementUtil getDefaultMeasurementData];
    }
    PTMeasurementInfo *axis = measurement.axis;
    double factor = ( measurementScale.translateValue * [PTMeasurementUtil getUnitsPerInch:measurementScale.baseUnit] ) / ( measurementScale.baseValue * 72.0f);
    [axis setFactor:factor];
    [axis setUnit:measurementScale.baseUnit];
    
    PTMeasurementInfo *dimension = [[PTMeasurementInfo alloc] init];
    
    if ([annot extendedAnnotType] == PTExtendedAnnotTypeRuler || [annot extendedAnnotType] == PTExtendedAnnotTypePerimeter) {
        dimension = measurement.distance;
        measurement.type = PTMeasurementTypeDistance;
    } else if ([annot extendedAnnotType] == PTExtendedAnnotTypeArea ) {
        measurement.type = PTMeasurementTypeArea;
        dimension = measurement.area;
    }
    
    [dimension setFactor:measurementScale.translateValue];
    [dimension setUnit:measurementScale.translateUnit];
    [dimension setPrecision:measurementScale.precision];
    measurement.axis = axis;

    if ([annot extendedAnnotType] == PTExtendedAnnotTypeRuler || [annot extendedAnnotType] == PTExtendedAnnotTypePerimeter) {
        measurement.distance = dimension;
    } else if ([annot extendedAnnotType] == PTExtendedAnnotTypeArea ) {
        measurement.area = dimension;
    }
    
    // Ignore 'sq ' part of unit for area measurements
    NSString *mTranslateUnit = [measurementScale.translateUnit componentsSeparatedByString:@" "].lastObject;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    measurement.scale = [NSString stringWithFormat:@"%@ %@ = %@ %@", [numberFormatter stringFromNumber:[NSNumber numberWithDouble:measurementScale.baseValue]], measurementScale.baseUnit, [numberFormatter stringFromNumber:[NSNumber numberWithDouble:measurementScale.translateValue]], mTranslateUnit];
    [PTMeasurementUtil setAnnotMeasurementData:annot withMeasurement:measurement];
}

+ (void)setObjFromMeasurementInfo:(PTObj *)axisObj axisInfo:(PTMeasurementInfo *)axisInfo withArray:(PTObj *)array{
    [axisObj PutNumber:[self getFactorKey] value:axisInfo.factor];

    if (axisInfo.precision) {
        [axisObj PutNumber:[self getPrecisionKey] value:axisInfo.precision];
    }
    if (axisInfo.display != nil) {
        [axisObj PutName:[self getDisplayKey] name:axisInfo.display];
    }
    if (axisInfo.decimalSymbol != nil) {
        [axisObj PutString:[self getDecimalSymbolKey] value:axisInfo.decimalSymbol];
    }
    if (axisInfo.thousandSymbol != nil) {
        [axisObj PutString:[self getThousandSymbolKey] value:axisInfo.thousandSymbol];
    }
    if (axisInfo.unitSuffix != nil) {
        [axisObj PutString:[self getUnitSuffixKey] value:axisInfo.unitSuffix];
    }
    [axisObj PutString:[self getUnitKey] value:axisInfo.unit];
    if (axisInfo.unitPrefix != nil) {
        [axisObj PutString:[self getUnitPrefixKey] value:axisInfo.unitPrefix];
    }
    if (axisInfo.unitPrefix != nil) {
        [axisObj PutName:[self getUnitPositionKey] name:axisInfo.unitPosition];
    }
}

+ (PTMeasurementInfo *)getInfoFromArrayObj:(PTObj *)obj {
    PTMeasurementInfo *info = [[PTMeasurementInfo alloc] init];
    if (obj != nil && obj.IsArray && obj.Size > 0) {
        PTObj *area = [obj GetAt:0];
        if (area != nil && area.IsDict) {
            PTObj *factor = [area FindObj:[PTMeasurementUtil getFactorKey]];
            if (factor != nil && factor.IsNumber) {
                [info setFactor:factor.GetNumber];
            }
            PTObj *precision = [area FindObj:[PTMeasurementUtil getPrecisionKey]];
            if (precision != nil && precision.IsNumber) {
                [info setPrecision:precision.GetNumber];
            }
            PTObj *display = [area FindObj:[PTMeasurementUtil getDisplayKey]];
            if (display != nil && display.IsName) {
                [info setDisplay:display.GetName];
            }
            PTObj *decimalSymbol = [area FindObj:[PTMeasurementUtil getDecimalSymbolKey]];
            if (decimalSymbol != nil && decimalSymbol.IsString) {
                [info setDecimalSymbol:decimalSymbol.GetAsPDFText];
            }
            PTObj *thousandSymbol = [area FindObj:[PTMeasurementUtil getThousandSymbolKey]];
            if (thousandSymbol != nil && thousandSymbol.IsString) {
                [info setThousandSymbol:thousandSymbol.GetAsPDFText];
            }
            PTObj *unitSuffix = [area FindObj:[PTMeasurementUtil getUnitSuffixKey]];
            if (unitSuffix != nil && unitSuffix.IsString) {
                NSString *suffix = unitSuffix.GetAsPDFText ? unitSuffix.GetAsPDFText : @"";
                [info setUnitSuffix:suffix];
            }
            PTObj *unit = [area FindObj:[PTMeasurementUtil getUnitKey]];
            if (unit != nil && unit.IsString) {
                [info setUnit:unit.GetAsPDFText];
            }
            PTObj *unitPrefix = [area FindObj:[PTMeasurementUtil getUnitPrefixKey]];
            if (unitPrefix != nil && unitPrefix.IsString) {
                NSString *prefix = unitPrefix.GetAsPDFText ? unitPrefix.GetAsPDFText : @"";
                [info setUnitPrefix:prefix];
            }
            PTObj *unitPosition = [area FindObj:[PTMeasurementUtil getUnitPositionKey]];
            if (unitPosition != nil && unitPosition.IsName) {
                [info setUnitPosition:unitPosition.GetName];
            }
        }
    }
    return info;
}

+ (void)setContentsForAnnot:(PTAnnot *)annot{
    if (annot == nil || !annot.IsValid) {
        return;
    }
    
    PTObj *obj = [annot GetSDFObj];
    PTObj *annotMeasurementObject = [obj FindObj:kMeasure];

    // If the annotation doesn't contain measurement info yet, write the defaults to it
    if (annotMeasurementObject == nil) {
        [PTMeasurementUtil setAnnotMeasurementData:annot withMeasurement:[self getDefaultMeasurementData]];
    }
    
    PTObj *axisArray = [annotMeasurementObject FindObj:[self getAxisKey]];
    PTMeasurementInfo *axisInfo = [self getInfoFromArrayObj:axisArray];

    PTObj *distanceArray = [annotMeasurementObject FindObj:[self getDistanceKey]];
    PTMeasurementInfo *distanceInfo = [self getInfoFromArrayObj:distanceArray];

    PTObj *areaArray = [annotMeasurementObject FindObj:[self getAreaKey]];
    PTMeasurementInfo *areaInfo = [self getInfoFromArrayObj:areaArray];

    NSString *value = @"";
    double annotSize;
    // Get the measurement value and format the string. Write it to the annotation
    switch ([annot extendedAnnotType]) {
        case PTExtendedAnnotTypeRuler:
        {
            PTLineAnnot *line = [[PTLineAnnot alloc] initWithAnn:annot];
            annotSize = line.length;
            annotSize = annotSize * axisInfo.factor;
            value = [self getMeasurementText:annotSize forMeasurementInfo:distanceInfo];
        }
            break;
        case PTExtendedAnnotTypePerimeter:
        {
            PTPolyLine *polyline = [[PTPolyLine alloc] initWithAnn:annot];
            annotSize = polyline.perimeter;
            annotSize = annotSize * axisInfo.factor;
            value = [self getMeasurementText:annotSize forMeasurementInfo:distanceInfo];
        }
            break;
        case PTExtendedAnnotTypeArea:
        {
            PTPolygon *polygon = [[PTPolygon alloc] initWithAnn:annot];
            annotSize = polygon.area;
            annotSize = annotSize * axisInfo.factor * axisInfo.factor;
            value = [self getMeasurementText:annotSize forMeasurementInfo:areaInfo];
            break;
        }
        default:
            return;
    }
    [annot SetContents:value];
}

#pragma mark - Measurement Conversion

+ (double)getUnitsPerInch:(NSString *)unit{
    // If this is an area measurement then we need to ignore the 'sq ' unit prefix.
    NSString *mTranslateUnit = [unit componentsSeparatedByString:@" "].lastObject;
    NSDictionary *unitsPerInch = @{
                                   uPT:@72.0f,
                                   uIN:@1.0f,
                                   uMM:@25.4f,
                                   uCM:@2.54f,
                                   uM:@0.0254f,
                                   uKM:@0.0000254f,
                                   uFT:@(1.0f/12.0f),
                                   uYD:@(1.0f/36.0f),
                                   uMI:@(1.0f/63360.0f),
                                   uNMI:@(1.0f/72913.385826772f)
                                   };
    return [unitsPerInch[mTranslateUnit] doubleValue];
}

#pragma mark - Measurement Display

+ (NSString *)getMeasurementText:(double)value forMeasurementInfo:(PTMeasurementInfo *)measurementInfo{
    
    NSString *display = measurementInfo.display;
    NSString *thousandSymbol = measurementInfo.thousandSymbol;
    NSString *decimalSymbol = measurementInfo.decimalSymbol;
    NSString *unit = measurementInfo.unit;
    int precision = measurementInfo.precision;

    // Calculate number of digits in precision integer
    int nDigits = 0;
    do {
        precision /= 10;
        nDigits++;
    } while (precision > 0);
    
    precision = measurementInfo.precision;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setGroupingSeparator:thousandSymbol];
    [numberFormatter setGroupingSize:3];
    [numberFormatter setUsesGroupingSeparator:YES];
    [numberFormatter setDecimalSeparator:decimalSymbol];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    NSString *fraction = @"";
    
    if ([display isEqualToString:@"D"]) {
        [numberFormatter setMinimumFractionDigits:nDigits-1];
        [numberFormatter setMaximumFractionDigits:nDigits-1];
    } else if ([display isEqualToString:@"F"]) {
        [numberFormatter setMaximumFractionDigits:0];
        //NSString *numberString = [NSString stringWithFormat:@"%f", value];
        //numberString = [numberString componentsSeparatedByString:@"."].lastObject;
        double numerator = round(((int)value % 1) * precision);
        fraction = [NSString stringWithFormat:@" %f/%i", numerator, precision];
    } else if ([display isEqualToString:@"T"]) {
        [numberFormatter setMaximumFractionDigits:0];
    } else if ([display isEqualToString:@"R"]) {
        [numberFormatter setRoundingMode:NSNumberFormatterRoundUp];
    }

    NSString *result = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
    result = [NSString stringWithFormat:@"%@%@ %@", result, fraction, unit];
    
    return result;
}

+ (NSArray *)realWorldUnits
{
    return  [[NSArray alloc] initWithObjects:
             uPT,
             uIN,
             uMM,
             uCM,
             uM,
             uKM,
             uFT,
             uYD,
             uMI,
             uNMI,
             nil];
}

#pragma mark - Key Map

+ (NSString *) getTypeKey{
  return @"Type";
}

+ (NSString *) getScaleKey{
  return @"R";
}

+ (NSString *) getAxisKey{
  return @"X";
}

+ (NSString *) getDistanceKey{
  return @"D";
}

+ (NSString *) getAreaKey{
  return @"A";
}

+ (NSString *) getUnitKey{
  return @"U";
}

+ (NSString *) getFactorKey{
  return @"C";
}

+ (NSString *) getDecimalSymbolKey{
  return @"RD";
}

+ (NSString *) getThousandSymbolKey{
  return @"RT";
}

+ (NSString *) getPrecisionKey{
  return @"D";
}

+ (NSString *) getDisplayKey{
  return @"F";
}

+ (NSString *) getUnitPrefixKey{
  return @"PS";
}

+ (NSString *) getUnitSuffixKey{
  return @"SS";
}

+ (NSString *) getUnitPositionKey{
  return @"O";
}

@end
