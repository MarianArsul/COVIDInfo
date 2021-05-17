//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTColorSliderTableViewCell;

@protocol PTColorSliderTableViewCellDelegate <NSObject>

- (void)colorSliderTableViewCell:(PTColorSliderTableViewCell *)cell colorChanged:(UIColor *)color;

@end


@interface PTColorSliderTableViewCell : UITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withColor:(UIColor *)color;

@property (nonatomic, weak, nullable) id<PTColorSliderTableViewCellDelegate> delegate;
@property (nonatomic, strong) UISlider *hueSlider;
@property (nonatomic, strong) UISlider *lightnessSlider;
@property (nonatomic, strong) UIColor *color;

@end

NS_ASSUME_NONNULL_END
