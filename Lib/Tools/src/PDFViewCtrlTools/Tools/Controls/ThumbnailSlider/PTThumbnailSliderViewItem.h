//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTThumbnailSliderViewItem : NSObject

- (instancetype)initWithPageNumber:(int)pageNumber size:(CGSize)size;

@property (nonatomic) int pageNumber;

@property (nonatomic, assign) CGSize size;

@property (nonatomic, strong, nullable) UIImage *image;

@end

NS_ASSUME_NONNULL_END
