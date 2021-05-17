//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTThumbnailSliderLayout.h"

#import "CGGeometry+PTAdditions.h"

#include <tgmath.h>

NSString * const PTThumbnailSliderFloatingItemKind = @"FloatingItem";

@interface PTThumbnailSliderLayout ()

@property (nonatomic, copy, nullable) NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutAttributes;

@property (nonatomic, copy, nullable) NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *adjustedLayoutAttributes;

@property (nonatomic, strong, nullable) UICollectionViewLayoutAttributes *floatingItemLayoutAttributes;

@property (nonatomic, strong, nullable) UICollectionViewLayoutAttributes *floatingItemAdjustedLayoutAttributes;

@property (nonatomic, readonly, getter=isMagnifying) BOOL magnifying;

@property (nonatomic, copy, nullable) NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *previousAdjustedLayoutAttributes;

@property (nonatomic, readonly, copy, nullable) NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *effectiveLayoutAttributes;

@property (nonatomic, readonly, strong, nullable) UICollectionViewLayoutAttributes *effectiveFloatingItemLayoutAttributes;

@property (nonatomic, readonly, weak, nullable) id<PTThumbnailSliderLayoutDelegate> delegate;

@end

@implementation PTThumbnailSliderLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        _magnification = 2.0;
        
        _touchLocation = PTCGPointNull;
    }
    return self;
}

- (void)prepareLayout
{
    [super prepareLayout];
    
    self.layoutAttributes = nil;
    self.adjustedLayoutAttributes = nil;
    
    self.floatingItemLayoutAttributes = nil;
    self.floatingItemAdjustedLayoutAttributes = nil;
    
    [self layoutItems];
    [self layoutFloatingItem];
    
    if ([self isMagnifying]) {
        [self adjustLayoutForTouch];
        [self adjustFloatingItem];
    }
}

- (void)layoutItems
{
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *mutableLayoutAttributes = [NSMutableDictionary dictionary];
    
    CGRect collectionViewBounds = self.collectionView.bounds;
    
    CGFloat totalItemWidth = 0.0;
    
    const NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
        
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        attributes.center = PTCGRectGetCenter(collectionViewBounds);
        
        CGSize itemSize = [self sizeForItemAtIndexPath:indexPath];
        attributes.size = itemSize;
        
        totalItemWidth += itemSize.width;
        
        mutableLayoutAttributes[indexPath] = attributes;
    }
    
    NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutAttributes = [mutableLayoutAttributes copy];
    
    CGFloat totalInteritemSpacingWidth = ((itemCount > 0) ? itemCount - 1 : 0) * self.spacing;
    CGFloat totalWidth = totalItemWidth + totalInteritemSpacingWidth;
    
    NSIndexPath *previousIndexPath = nil;
    UICollectionViewLayoutAttributes *previousItemAttributes = nil;
    
    CGRect contentBounds = CGRectMake(fmax(0, CGRectGetWidth(collectionViewBounds) - totalWidth) / 2.0, 0,
                                      totalWidth, CGRectGetHeight(collectionViewBounds));
    
    for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
        UICollectionViewLayoutAttributes *attributes = layoutAttributes[indexPath];
        
        CGRect frame = attributes.frame;
        
        if (!previousIndexPath) { // First (left-most) item.
            frame.origin.x = CGRectGetMinX(contentBounds);
        } else {
            frame.origin.x = CGRectGetMaxX(previousItemAttributes.frame) + self.spacing;
        }
        
        attributes.frame = frame;
        
        previousIndexPath = indexPath;
        previousItemAttributes = attributes;
    }
    
    self.contentBounds = contentBounds;
    self.layoutAttributes = layoutAttributes;
}

- (void)layoutFloatingItem
{
    NSIndexPath *floatingItemIndexPath = [self indexPathForFloatingItem];
    if (!floatingItemIndexPath) {
        return;
    }
    
    UICollectionViewLayoutAttributes *floatingItemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:PTThumbnailSliderFloatingItemKind withIndexPath:floatingItemIndexPath];
    
    // Floating item size.
    CGSize floatingItemSize = [self sizeForFloatingItemAtIndexPath:floatingItemIndexPath];
    
    // Grow item slightly while maintaining aspect ratio.
    CGFloat aspectRatio = 1.0;
    if (!CGSizeEqualToSize(floatingItemSize, CGSizeZero)) {
        aspectRatio = floatingItemSize.width / floatingItemSize.height;
    }
    floatingItemSize.height += 8.0;
    floatingItemSize.width = floatingItemSize.height * aspectRatio;
    
    floatingItemAttributes.size = floatingItemSize;
    
    // Center
    CGPoint floatingItemCenter = [self locationForFloatingItemAtIndexPath:floatingItemIndexPath];
    if (PTCGPointIsNull(floatingItemCenter)) {
        floatingItemCenter = PTCGRectGetCenter(self.collectionView.bounds);
    }
    floatingItemAttributes.center = floatingItemCenter;
    
    // The floating item "floats" over all other items.
    floatingItemAttributes.zIndex = NSIntegerMax;
    
    self.floatingItemLayoutAttributes = floatingItemAttributes;
}

- (CGFloat)magnificationForLocation:(CGPoint)location
{
    CGFloat distanceFromTouch = self.touchLocation.x - location.x;
    
    // The distance at which the magnification "trails off".
    const CGFloat trailOffDistance = 250.0;
    
    CGFloat magnification = self.magnification * (1.0 - (fabs(distanceFromTouch) / trailOffDistance));

    return fmax(1.0, magnification);
}

- (void)adjustLayoutForTouch
{
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *adjustedLayoutAttributes = [NSMutableDictionary dictionaryWithCapacity:self.layoutAttributes.count];
    
    [self.layoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
        adjustedLayoutAttributes[indexPath] = [attributes copy];
    }];
    
    const NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    
    NSIndexPath *centerItemIndexPath = nil;
    
    CGFloat minDist = CGFLOAT_MAX;
    
    for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];

        UICollectionViewLayoutAttributes *attributes = self.layoutAttributes[indexPath];

        CGFloat itemDist = fabs(self.touchLocation.x - attributes.center.x);
        if (itemDist < minDist) {
            minDist = itemDist;
            centerItemIndexPath = indexPath;
        }
    }
    
    if (centerItemIndexPath) {
        UICollectionViewLayoutAttributes *centerItemAttributes = self.layoutAttributes[centerItemIndexPath];
        UICollectionViewLayoutAttributes *centerItemAdjustedAttributes = adjustedLayoutAttributes[centerItemIndexPath];

        CGFloat centerItemDist = self.touchLocation.x - centerItemAttributes.center.x;
        CGFloat centerItemScale = [self magnificationForLocation:centerItemAttributes.center];
        
        CGFloat maxShift = ((centerItemScale - 1.0) * centerItemAttributes.size.width) / 2.0;
        CGFloat centerItemShift = (centerItemDist / (centerItemAttributes.size.width / 2.0)) * maxShift;
        
//        NSLog(@"centerItem index: %d, dist: %f, scale: %f, shift: %f",
//              centerItemIndexPath.item, centerItemDist, centerItemScale, centerItemShift);
        
        // Adjust size by scale.
        CGSize centerItemSize = centerItemAttributes.size;
        centerItemSize.width *= centerItemScale;
        centerItemSize.height *= centerItemScale;
        
        centerItemAdjustedAttributes.size = centerItemSize;
        
        // Adjust center.
        CGPoint centerItemCenter = centerItemAttributes.center;
        centerItemCenter.x -= centerItemShift;
        centerItemCenter.y -= (centerItemAdjustedAttributes.size.height - centerItemAttributes.size.height) / 2.0;
        
        centerItemAdjustedAttributes.center = centerItemCenter;
        
        UICollectionViewLayoutAttributes *previousItemAttributes = centerItemAttributes;
        UICollectionViewLayoutAttributes *previousItemAdjustedAttributes = centerItemAdjustedAttributes;
        
        // Scale & shift items to the right of the center item.
        for (NSInteger itemIndex = centerItemIndexPath.item + 1; itemIndex < itemCount; itemIndex++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];

            UICollectionViewLayoutAttributes *attributes = self.layoutAttributes[indexPath];
            UICollectionViewLayoutAttributes *adjustedAttributes = adjustedLayoutAttributes[indexPath];
            
            // Calculate item scale.
            CGFloat itemScale = [self magnificationForLocation:attributes.center];

            if (itemScale == 1.0) {
                // Do not recalculate this item's layout attributes if the layout attributes for
                // "default" scale (1.0) have already been calculated.
                // This prevents the jiggle caused by recalculating slightly different positions for
                // default-scale items.
                UICollectionViewLayoutAttributes *previousAdjustedAttributes = self.previousAdjustedLayoutAttributes[indexPath];
                if (previousAdjustedAttributes) {
                    CGFloat previousScale = previousAdjustedAttributes.size.width / attributes.size.width;
                    if (previousScale == 1.0) {
                        // Use the precalculated layout attributes for this item.
                        adjustedLayoutAttributes[indexPath] = previousAdjustedAttributes;
                        continue;
                    }
                }
            }
            
            // Adjust size by scale.
            CGSize itemSize = attributes.size;
            itemSize.width *= itemScale;
            itemSize.height *= itemScale;
            
            adjustedAttributes.size = itemSize;
            
            CGPoint spacingCenter = CGPointMake(CGRectGetMaxX(previousItemAttributes.frame) + (self.spacing / 2.0),
                                                CGRectGetMidY(self.collectionView.bounds));
            
            // Adjust spacing.
            CGFloat spacingScale = [self magnificationForLocation:spacingCenter];
            
            CGFloat adjustedSpacing = self.spacing * spacingScale;
            
            // Adjust frame.
            CGRect frame = adjustedAttributes.frame;
            frame.origin.x = CGRectGetMaxX(previousItemAdjustedAttributes.frame) + adjustedSpacing;

            adjustedAttributes.frame = frame;
            
            CGPoint itemCenter = adjustedAttributes.center;
            itemCenter.y -= (adjustedAttributes.size.height - attributes.size.height) / 2.0;
            
            adjustedAttributes.center = itemCenter;
            
            previousItemAttributes = attributes;
            previousItemAdjustedAttributes = adjustedAttributes;
        }
        
        // Scale & shift items to the left of the center item.
        previousItemAttributes = centerItemAttributes;
        previousItemAdjustedAttributes = centerItemAdjustedAttributes;
        
        for (NSInteger itemIndex = centerItemIndexPath.item - 1; itemIndex >= 0; itemIndex--) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
            
            UICollectionViewLayoutAttributes *attributes = self.layoutAttributes[indexPath];
            UICollectionViewLayoutAttributes *adjustedAttributes = adjustedLayoutAttributes[indexPath];
            
            // Calculate item scale.
            CGFloat itemScale = [self magnificationForLocation:attributes.center];
            
            if (itemScale == 1.0) {
                // Do not recalculate this item's layout attributes if the layout attributes for
                // "default" scale (1.0) have already been calculated.
                // This prevents the jiggle caused by recalculating slightly different positions for
                // default-scale items.
                UICollectionViewLayoutAttributes *previousAdjustedAttributes = self.previousAdjustedLayoutAttributes[indexPath];
                if (previousAdjustedAttributes) {
                    CGFloat previousScale = previousAdjustedAttributes.size.width / attributes.size.width;
                    if (previousScale == 1.0) {
                        // Use the precalculated layout attributes for this item.
                        adjustedLayoutAttributes[indexPath] = previousAdjustedAttributes;
                        continue;
                    }
                }
            }
            
            // Adjust size by scale.
            CGSize itemSize = attributes.size;
            itemSize.width *= itemScale;
            itemSize.height *= itemScale;
            
            adjustedAttributes.size = itemSize;
            
            CGPoint spacingCenter = CGPointMake(CGRectGetMinX(previousItemAttributes.frame) - (self.spacing / 2.0),
                                                CGRectGetMidY(self.collectionView.bounds));
            
            // Adjust item spacing.
            CGFloat spacingScale = [self magnificationForLocation:spacingCenter];
            
            CGFloat adjustedSpacing = self.spacing * spacingScale;
            
            // Adjust frame.
            CGRect frame = adjustedAttributes.frame;
            frame.origin.x = CGRectGetMinX(previousItemAdjustedAttributes.frame) - adjustedSpacing - CGRectGetWidth(frame);
            
            adjustedAttributes.frame = frame;
            
            CGPoint itemCenter = adjustedAttributes.center;
            itemCenter.y -= (adjustedAttributes.size.height - attributes.size.height) / 2.0;
            
            adjustedAttributes.center = itemCenter;
            
            previousItemAttributes = attributes;
            previousItemAdjustedAttributes = adjustedAttributes;
        }
    }
    
    self.adjustedLayoutAttributes = adjustedLayoutAttributes;
}

- (void)adjustFloatingItem
{
    UICollectionViewLayoutAttributes *floatingItemAdjustedLayoutAttributes = [self.floatingItemLayoutAttributes copy];
    
    // Adjust size.
    // Use the "raw" size for the floating item because the unadjusted layout attributes could have
    // a different size (ie. resting size for floating item was adjusted).
    CGSize floatingItemSize = [self sizeForFloatingItemAtIndexPath:self.floatingItemLayoutAttributes.indexPath];
    
    CGSize adjustedFloatingItemSize = floatingItemSize;
    adjustedFloatingItemSize.width *= self.magnification;
    adjustedFloatingItemSize.height *= self.magnification;
    
    floatingItemAdjustedLayoutAttributes.size = adjustedFloatingItemSize;
    
    CGRect contentBounds = self.contentBounds;
    
    // Adjust center.
    CGPoint floatingItemCenter = self.floatingItemLayoutAttributes.center;
    // Bound floating item to content bounds.
    floatingItemCenter.x = fmax(CGRectGetMinX(contentBounds) + (floatingItemSize.width / 2.0),
                                fmin(self.touchLocation.x, CGRectGetMaxX(contentBounds) - (floatingItemSize.width / 2.0)));
    floatingItemCenter.y -= (adjustedFloatingItemSize.height - floatingItemSize.height) / 2.0;
    
    floatingItemAdjustedLayoutAttributes.center = floatingItemCenter;
    
    self.floatingItemAdjustedLayoutAttributes = floatingItemAdjustedLayoutAttributes;
}

- (CGSize)collectionViewContentSize
{
    return self.collectionView.bounds.size;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributesInRect = [NSMutableArray arrayWithCapacity:self.effectiveLayoutAttributes.count];
    
    // Add layout attributes for items inside the rect.
    for (NSIndexPath *indexPath in self.effectiveLayoutAttributes) {
        UICollectionViewLayoutAttributes *attributes = self.effectiveLayoutAttributes[indexPath];
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            [attributesInRect addObject:attributes];
        }
    }
    
    // Add layout attributes for the floating item.
    UICollectionViewLayoutAttributes *floatingItemLayoutAttributes = self.effectiveFloatingItemLayoutAttributes;
    if (floatingItemLayoutAttributes && CGRectIntersectsRect(rect, floatingItemLayoutAttributes.frame)) {
        [attributesInRect addObject:floatingItemLayoutAttributes];
    }

    return attributesInRect;
}

#pragma mark - Item layout attributes

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.effectiveLayoutAttributes[indexPath];
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (![self isMagnifying] && self.previousAdjustedLayoutAttributes) {
        return self.previousAdjustedLayoutAttributes[itemIndexPath];
    }
    
    // Use the item's normal layout attributes (disables fade in animation).
    return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    // Use the item's normal layout attributes (disables fade out animation).
    return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
}

#pragma mark - Supplementary view layout attributes

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    return self.effectiveFloatingItemLayoutAttributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath
{
    return [self layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:elementIndexPath];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath
{
    return [self layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:elementIndexPath];
}

#pragma mark - Invalidation

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

#pragma mark - Touch location

- (void)setTouchLocation:(CGPoint)touchLocation
{
    // Bound touch location to content bounds.
    CGRect contentBounds = self.contentBounds;
    if (!PTCGPointIsNull(touchLocation) &&
        !CGRectEqualToRect(contentBounds, CGRectZero) &&
        !CGRectContainsPoint(contentBounds, touchLocation)) {
        touchLocation.x = fmax(CGRectGetMinX(contentBounds),
                               fmin(touchLocation.x, CGRectGetMaxX(contentBounds)));
    }
    
    if (CGPointEqualToPoint(_touchLocation, touchLocation)) {
        // No change.
        return;
    }
    
    CGPoint previousTouchLocation = _touchLocation;
    
    _touchLocation = touchLocation;
    
    if (!PTCGPointIsNull(previousTouchLocation)) {
        // Transitioning from valid touch.
        self.previousAdjustedLayoutAttributes = self.adjustedLayoutAttributes;
    } else {
        self.previousAdjustedLayoutAttributes = nil;
    }
    
    [self invalidateLayout];
}

#pragma mark - Convenience

- (BOOL)isMagnifying
{
    return !PTCGPointIsNull(self.touchLocation);
}

- (NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *)effectiveLayoutAttributes
{
    if (self.adjustedLayoutAttributes) {
        return self.adjustedLayoutAttributes;
    }
    return self.layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)effectiveFloatingItemLayoutAttributes
{
    if (self.floatingItemAdjustedLayoutAttributes) {
        return self.floatingItemAdjustedLayoutAttributes;
    }
    return self.floatingItemLayoutAttributes;
}

- (UICollectionViewLayoutAttributes *)unadjustedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutAttributes[indexPath];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        return [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
    }
    
    return self.itemSize;
}

- (nullable NSIndexPath *)indexPathForFloatingItem
{
    if ([self.delegate respondsToSelector:@selector(collectionView:indexPathForFloatingItemInLayout:)]) {
        return [self.delegate collectionView:self.collectionView indexPathForFloatingItemInLayout:self];
    }
    return nil;
}

- (CGSize)sizeForFloatingItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = self.itemSize;
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForFloatingItemAtIndexPath:)]) {
        size = [self.delegate collectionView:self.collectionView layout:self sizeForFloatingItemAtIndexPath:indexPath];
    }
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        CGFloat minimumDimension = fmin(CGRectGetWidth(self.collectionView.bounds),
                                        CGRectGetHeight(self.collectionView.bounds));
        size.width = minimumDimension;
        size.height = minimumDimension;
    }
    
    return size;
}

- (CGPoint)locationForFloatingItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:locationForFloatingItemAtIndexPath:)]) {
        return [self.delegate collectionView:self.collectionView layout:self locationForFloatingItemAtIndexPath:indexPath];
    }
    return PTCGPointNull;
}

#pragma mark - delegate

- (id<PTThumbnailSliderLayoutDelegate>)delegate
{
    if ([self.collectionView.delegate conformsToProtocol:@protocol(PTThumbnailSliderLayoutDelegate)]) {
        return (id<PTThumbnailSliderLayoutDelegate>)self.collectionView.delegate;
    }
    return nil;
}

@end
