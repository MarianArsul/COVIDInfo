//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTTableViewCell.h"
#import "PTAnnotStyleTableViewItem.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotStyleSliderTableViewCell;

@protocol PTAnnotStyleSliderTableViewCellDelegate <NSObject>

- (void)styleSliderTableViewCellSliderBeganSliding:(PTAnnotStyleSliderTableViewCell *)cell;

- (void)styleSliderTableViewCell:(PTAnnotStyleSliderTableViewCell *)cell sliderValueDidChange:(float)value;

- (void)styleSliderTableViewCellSliderEndedSliding:(PTAnnotStyleSliderTableViewCell *)cell;

@end

@interface PTAnnotStyleSliderTableViewCell : PTTableViewCell

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UISlider *slider;

@property (nonatomic, strong) UILabel *indicator;

@property (nonatomic, weak, nullable) id<PTAnnotStyleSliderTableViewCellDelegate> delegate;

- (void)configureWithItem:(PTAnnotStyleSliderTableViewItem *)item;

@end

NS_ASSUME_NONNULL_END
