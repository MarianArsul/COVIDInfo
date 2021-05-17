//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "PTMeasurementInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PTMeasurementType) {
    PTMeasurementTypeDistance,
    PTMeasurementTypeArea
};

@interface PTMeasurement : NSObject

@property (nonatomic) PTMeasurementType type;
@property (nonatomic, strong) NSString *scale;
@property (nonatomic, strong) PTMeasurementInfo *axis;
@property (nonatomic, strong) PTMeasurementInfo *distance;
@property (nonatomic, strong) PTMeasurementInfo *area;

@end

NS_ASSUME_NONNULL_END
