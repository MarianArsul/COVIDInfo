//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTMeasurement.h"
#import "PTMeasurementUtil.h"

@implementation PTMeasurement

- (instancetype)init
{
    self = [super init];
    if (self) {
        _axis = [[PTMeasurementInfo alloc] init];
        _distance = [[PTMeasurementInfo alloc] init];
        _area = [[PTMeasurementInfo alloc] init];
        _type = PTMeasurementTypeDistance;
    }
    return self;
}

@end
