//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The PTDigSigView is used for creating signature path appearances. The view tracks
 * and saves user touches, drawing strokes with the specified color and thickness.
 */
@interface PTDigSigView : UIView

/**
 * The bounding rectangle exactly containing every drawn point.
 */
@property (nonatomic, assign) CGRect boundingRect;

/**
 * The stroke points, with differnt strokes separated by `CGPointZero` values.
 */
@property (strong, nonatomic, nullable) NSMutableArray<NSValue*>* points;

/**
 * The stroke color.
 */
@property (strong, nonatomic) UIColor* strokeColor;

/**
 * The stroke thickness.
 */
@property (assign, nonatomic) CGFloat strokeThickness;

/**
 * Returns a new instance of a PTDigSigView.
 */
-(instancetype)initWithFrame:(CGRect)frame withColour:(UIColor*)color withStrokeThickness:(CGFloat)thickness NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
