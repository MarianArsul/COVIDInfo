//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentTabBarFlowLayout.h"

@implementation PTDocumentTabBarFlowLayout

// Allow horizontal movement only.
- (UICollectionViewLayoutAttributes *)layoutAttributesForInteractivelyMovingItemAtIndexPath:(NSIndexPath *)indexPath withTargetPosition:(CGPoint)position
{
    UICollectionViewLayoutAttributes *movingAttributes = [super layoutAttributesForInteractivelyMovingItemAtIndexPath:indexPath withTargetPosition:position];
    
    // Get item's existing layout attributes.
    UICollectionViewLayoutAttributes *normalAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
    
    // Keep the item's existing y-coordinate.
    movingAttributes.center = CGPointMake(movingAttributes.center.x, normalAttributes.center.y);
    
    return movingAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

@end
