//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#import "PTMeasurement.h"
#import "PTMeasurementScale.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTMeasurementUtil : NSObject

#pragma mark - Measurement Info

+ (PTMeasurement *) getDefaultMeasurementData;

+ (PTMeasurement *) getAnnotMeasurementData:(PTAnnot *)annot;

+ (PTMeasurementScale *) getMeasurementScaleFromAnnot:(PTAnnot *)annot;

+ (PTMeasurementScale *) getMeasurementScaleFromMeasurement:(PTMeasurement *)measurement;

+ (void)setAnnotMeasurementData:(PTAnnot *)annot withMeasurement:(PTMeasurement *)measurement;

+ (void)setAnnotMeasurementData:(PTAnnot *)annot fromMeasurementScale:(PTMeasurementScale *)measurementScale;

+ (void)setContentsForAnnot:(PTAnnot *)annot;

#pragma mark - Measurement Conversion
+ (double)getUnitsPerInch:(NSString *)unit;

#pragma mark - Measurement Display

+ (NSString *) getMeasurementText:(double)value forMeasurementInfo:(PTMeasurementInfo *)measurementInfo;

@property (nonatomic, class, strong, readonly) NSArray *realWorldUnits;

#pragma mark - Key Map

+ (NSString *) getTypeKey;

+ (NSString *) getScaleKey;

+ (NSString *) getAxisKey;

+ (NSString *) getDistanceKey;

+ (NSString *) getAreaKey;

+ (NSString *) getUnitKey;

+ (NSString *) getFactorKey;

+ (NSString *) getDecimalSymbolKey;

+ (NSString *) getThousandSymbolKey;

+ (NSString *) getPrecisionKey;

+ (NSString *) getDisplayKey;

+ (NSString *) getUnitPrefixKey;

+ (NSString *) getUnitSuffixKey;

+ (NSString *) getUnitPositionKey;

@end

NS_ASSUME_NONNULL_END
