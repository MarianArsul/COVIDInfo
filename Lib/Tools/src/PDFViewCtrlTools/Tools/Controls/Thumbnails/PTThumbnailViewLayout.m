//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTThumbnailViewLayout.h"

const CGFloat PTThumbnailViewLayoutDefaultSpacing = 10.0;

@implementation PTThumbnailViewLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        self.minimumLineSpacing = PTThumbnailViewLayoutDefaultSpacing;
        self.minimumInteritemSpacing = PTThumbnailViewLayoutDefaultSpacing;
        
        self.sectionInset = UIEdgeInsetsMake(PTThumbnailViewLayoutDefaultSpacing, PTThumbnailViewLayoutDefaultSpacing,
                                             PTThumbnailViewLayoutDefaultSpacing, PTThumbnailViewLayoutDefaultSpacing);
    }
    return self;
}

#pragma mark - UICollectionViewFlowLayout methods

- (UICollectionViewLayoutAttributes *)layoutAttributesForInteractivelyMovingItemAtIndexPath:(NSIndexPath *)indexPath withTargetPosition:(CGPoint)position
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForInteractivelyMovingItemAtIndexPath:indexPath withTargetPosition:position];
    
    attributes.alpha = 0.7;
    attributes.transform = CGAffineTransformMakeScale(1.25, 1.25);
    
    return attributes;
}

// NOTE: Use UICollectionFlowLayout's implementation for sticky header support.
// Otherwise, always need to return YES.
//- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
//{
//    CGRect oldBounds = self.collectionView.bounds;
//
//    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
//        return (CGRectGetWidth(oldBounds) != CGRectGetWidth(newBounds));
//    } else {
//        return (CGRectGetHeight(oldBounds) != CGRectGetHeight(newBounds));
//    }
//}

@end
