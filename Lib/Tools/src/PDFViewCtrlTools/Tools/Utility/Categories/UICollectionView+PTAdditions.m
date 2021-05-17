//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UICollectionView+PTAdditions.h"

@implementation UICollectionView (PTAdditions)

- (void)pt_scrollItemToVisible:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    UICollectionViewLayoutAttributes *layoutAttributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    
    if (layoutAttributes) {
        [self scrollRectToVisible:layoutAttributes.frame animated:animated];
    } else {
        [self scrollToItemAtIndexPath:indexPath
                     atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                             animated:animated];
    }
}

- (void)pt_performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL finished))completion animated:(BOOL)animated
{
    if (animated) {
        [self performBatchUpdates:updates completion:completion];
    } else {
        // Disable animations created inside updates.
        [UIView performWithoutAnimation:updates];
        if (completion) {
            completion(YES);
        }
    }
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UICollectionView, PTAdditions)
