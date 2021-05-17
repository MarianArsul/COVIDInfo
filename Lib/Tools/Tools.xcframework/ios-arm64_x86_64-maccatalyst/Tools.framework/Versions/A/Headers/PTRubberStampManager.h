//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTCustomStampOption.h>
#import <Tools/PTOverridable.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

PT_EXPORT NSString * const PTRubberStampKeyText;
PT_EXPORT NSString * const PTRubberStampKeyTextBelow;
PT_EXPORT NSString * const PTRubberStampKeyFillColorStart;
PT_EXPORT NSString * const PTRubberStampKeyFillColorEnd;
PT_EXPORT NSString * const PTRubberStampKeyTextColor;
PT_EXPORT NSString * const PTRubberStampKeyBorderColor;
PT_EXPORT NSString * const PTRubberStampKeyFillOpacity;
PT_EXPORT NSString * const PTRubberStampKeyPointingLeft;
PT_EXPORT NSString * const PTRubberStampKeyPointingRight;

@interface PTRubberStampManager : NSObject<PTOverridable>

/**
 * The default light red gradient start color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightRedStartColor;

/**
 * The default light red gradient end color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightRedEndColor;

/**
 * The default light red text color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightRedTextColor;

/**
 * The default light red border color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightRedBorderColor;

/**
 * The default dark red gradient start color
 */
@property (nonatomic, class, strong, readonly) UIColor *darkRedStartColor;

/**
 * The default dark red gradient end color
 */
@property (nonatomic, class, strong, readonly) UIColor *darkRedEndColor;

/**
 * The default dark red text color
 */
@property (nonatomic, class, strong, readonly) UIColor *darkRedTextColor;

/**
 * The default dark red border color
 */
@property (nonatomic, class, strong, readonly) UIColor *darkRedBorderColor;

/**
 * The default light green gradient start color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightGreenStartColor;

/**
 * The default light green gradient end color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightGreenEndColor;

/**
 * The default light green gradient text color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightGreenTextColor;

/**
 * The default light green border color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightGreenBorderColor;

/**
 * The default light blue gradient start color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightBlueStartColor;

/**
 * The default light blue gradient end color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightBlueEndColor;

/**
 * The default light blue text color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightBlueTextColor;

/**
 * The default light blue border color
 */
@property (nonatomic, class, strong, readonly) UIColor *lightBlueBorderColor;

/**
 * The default yellow gradient start color
 */
@property (nonatomic, class, strong, readonly) UIColor *yellowStartColor;

/**
 * The default yellow gradient end color
 */
@property (nonatomic, class, strong, readonly) UIColor *yellowEndColor;

/**
 * The default yellow text color
 */
@property (nonatomic, class, strong, readonly) UIColor *yellowTextColor;

/**
 * The default yellow border color
 */
@property (nonatomic, class, strong, readonly) UIColor *yellowBorderColor;

/**
 * The default purple gradient start color
 */
@property (nonatomic, class, strong, readonly) UIColor *purpleStartColor;

/**
 * The default purple gradient end color
 */
@property (nonatomic, class, strong, readonly) UIColor *purpleEndColor;

/**
 * The default purple text color
 */
@property (nonatomic, class, strong, readonly) UIColor *purpleTextColor;

/**
 * The default purple border color
 */
@property (nonatomic, class, strong, readonly) UIColor *purpleBorderColor;

/**
 * Used to determine the number of standard stamps.
 *
 * @return the number of standard stamps.
 */
-(NSUInteger)numberOfStandardStamps;

/**
 * An array of standard rubber stamp appearances.
 * This should be an array of `PTCustomStampOption`s
 */
@property (nonatomic, copy, nullable) NSArray<PTCustomStampOption*> *standardStampOptions;

/**
 *
 * Returns an image of the stamp with a given `PTCustomStampOption` appearance.
 *
 * @param height The desired height of the output image.
 *
 * @param width The desired width of the output image.
 *
 * @param stampOption A `PTCustomStampOption` appearance object.
 *
 * @return A rasterized copy of the signature.
 *
 */
+(UIImage*)getBitMapForStampWithHeight:(double)height width:(double)width option:(PTCustomStampOption*)stampOption;

@end

NS_ASSUME_NONNULL_END
