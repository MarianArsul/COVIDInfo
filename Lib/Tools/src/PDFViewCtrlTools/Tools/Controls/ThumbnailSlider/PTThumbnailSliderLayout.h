//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL NSString * const PTThumbnailSliderFloatingItemKind;

@class PTThumbnailSliderLayout;

@protocol PTThumbnailSliderLayoutDelegate <UICollectionViewDelegate>
@optional

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (nullable NSIndexPath *)collectionView:(UICollectionView *)collectionView indexPathForFloatingItemInLayout:(UICollectionViewLayout *)collectionViewLayout;

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForFloatingItemAtIndexPath:(NSIndexPath *)indexPath;

- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout locationForFloatingItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface PTThumbnailSliderLayout : UICollectionViewLayout

@property (nonatomic) CGSize itemSize;

@property (nonatomic) CGFloat spacing;

@property (nonatomic) CGFloat magnification;

@property (nonatomic) CGPoint touchLocation;

@property (nonatomic) CGRect contentBounds;

- (nullable UICollectionViewLayoutAttributes *)unadjustedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
