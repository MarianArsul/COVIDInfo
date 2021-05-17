//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTMeasurementInfo : NSObject

@property (nonatomic, assign) double factor;
@property (nonatomic, nullable, copy) NSString* unit;
@property (nonatomic, nullable, copy) NSString* decimalSymbol;
@property (nonatomic, nullable, copy) NSString* thousandSymbol;
@property (nonatomic, nullable, copy) NSString* display;
@property (nonatomic, assign) int precision;
@property (nonatomic, nullable, copy) NSString* unitPrefix;
@property (nonatomic, nullable, copy) NSString* unitSuffix;
@property (nonatomic, nullable, copy) NSString* unitPosition;

@end

NS_ASSUME_NONNULL_END
