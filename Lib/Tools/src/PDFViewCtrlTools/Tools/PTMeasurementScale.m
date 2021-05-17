//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTMeasurementScale.h"

#import "PTMeasurementUtil.h"

@implementation PTMeasurementScale

- (instancetype)init
{
    return [self initWithBaseValue:1.0f baseUnit:@"in" translateValue:1.0f translateUnit:@"in" precision:100];
}

- (instancetype)initWithBaseValue:(CGFloat)baseValue baseUnit:(NSString *)baseUnit translateValue:(CGFloat)translateValue translateUnit:(NSString *)translateUnit precision:(int)precision{
    self = [super init];
    if (self) {
        _baseValue = baseValue;
        _baseUnit = [baseUnit copy];
        _translateValue = translateValue;
        _translateUnit = [translateUnit copy];
        _precision = precision;
    }
    return self;
}

#pragma mark - <NSCoding>

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeDouble:self.baseValue forKey:PT_KEY(self, baseValue)];
    [coder encodeObject:self.baseUnit forKey:PT_KEY(self, baseUnit)];
    [coder encodeDouble:self.translateValue forKey:PT_KEY(self, translateValue)];
    [coder encodeObject:self.translateUnit forKey:PT_KEY(self, translateUnit)];
    [coder encodeInt:self.precision forKey:PT_KEY(self, precision)];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    if (self) {
        CGFloat baseValue = 1.0f;
        if ([coder containsValueForKey:PT_KEY(self, baseValue)]) {
            baseValue = [coder decodeDoubleForKey:PT_KEY(self, baseValue)];
        }
        
        NSString *baseUnit = @"in";
        if ([coder containsValueForKey:PT_KEY(self, baseUnit)]) {
            baseUnit = [coder decodeObjectForKey:PT_KEY(self, baseUnit)];
        }
        
        CGFloat translateValue = 1.0f;
        if ([coder containsValueForKey:PT_KEY(self, translateValue)]) {
            translateValue = [coder decodeDoubleForKey:PT_KEY(self, translateValue)];
        }
        
        NSString *translateUnit = @"in";
        if ([coder containsValueForKey:PT_KEY(self, translateUnit)]) {
            translateUnit = [coder decodeObjectForKey:PT_KEY(self, translateUnit)];
        }
        
        int precision = 100;
        if ([coder containsValueForKey:PT_KEY(self, precision)]) {
            precision = [coder decodeIntForKey:PT_KEY(self, precision)];
        }

        _baseValue = baseValue;
        _baseUnit = baseUnit;
        _translateValue = translateValue;
        _translateUnit = translateUnit;
        _precision = precision;
    }
    return self;
}

@end
