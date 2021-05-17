//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/AnnotTypes.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A PTMeasurementScale is used to describe a measurement's conversion factors.
 */
@interface PTMeasurementScale : NSObject <NSCoding>

/**
 * Initializes a new instance of the class.
 *
 * @param baseValue The base conversion value in document space.
 */
- (instancetype)initWithBaseValue:(CGFloat)baseValue baseUnit:(NSString *)baseUnit translateValue:(CGFloat)translateValue translateUnit:(NSString *)translateUnit precision:(int)precision NS_DESIGNATED_INITIALIZER;

/**
 * The base value of the conversion. This is in document space.
 */
@property (nonatomic) CGFloat baseValue;

/**
 * The units of the base value.
 */
@property (nonatomic, copy) NSString *baseUnit;

/**
 * The translation value of the conversion. This is in world space.
 */
@property (nonatomic) CGFloat translateValue;

/**
 * The units of the translation value.
 */
@property (nonatomic, copy) NSString *translateUnit;

/**
 * The precision with which to display the measurement.
 */
@property (nonatomic) int precision;


- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
