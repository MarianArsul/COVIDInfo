//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTPDFViewCtrl;

/**
 * The loupe that is used during text selection.
 */
@interface PTMagnifierView : UIView

/**
 * The view that is being magnified.
 */
@property (readonly, nonatomic, strong) UIView *viewToMagnify;

/**
 * The designated initializer
 *
 * @param viewToMagnify The view that will appear magnified in the loupe.
 */
- (instancetype)initWithViewToMagnify:(UIView*)viewToMagnify NS_DESIGNATED_INITIALIZER;

/**
 * Sets the point of viewToMagnify to magnify, and the location to display the loupe.
 *
 * @param magnifyPoint The point to magnify.
 *
 * @param touchPoint The point to sit the loupe next to.
 */ 
- (void)setMagnifyPoint:(CGPoint)magnifyPoint TouchPoint:(CGPoint)touchPoint;


- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
