//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTThumbnailSliderViewItem.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTThumbnailSliderViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign, getter=isNightModeEnabled) BOOL nightModeEnabled;

- (void)configureWithItem:(PTThumbnailSliderViewItem *)item;

@end

NS_ASSUME_NONNULL_END
