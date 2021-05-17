//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentTabBar.h"

#import "PTDocumentTabBarFlowLayout.h"
#import "PTDocumentTabBarCell.h"
#import "PTToolsUtil.h"

#import "NSLayoutConstraint+PTPriority.h"
#import "UICollectionView+PTAdditions.h"
#import "CGGeometry+PTAdditions.h"

#include <tgmath.h>

static const CGFloat PT_DocumentTabBarDefaultMinimumTabWidth = 120;

static NSString * const PTDocumentTabBar_CellReuseIdentifier = @"PTDocumentTabBarCell";

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentTabBar ()
{
    BOOL _constraintsLoaded;
    BOOL _needsLeadingViewConstraintsUpdate;
    BOOL _needsTrailingViewConstraintsUpdate;
}

@property (nonatomic, assign) CGVector interactiveMovementOffset;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentTabBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Set up collection view layout.
        UICollectionViewFlowLayout *collectionViewLayout = [[PTDocumentTabBarFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        // No margins.
        collectionViewLayout.sectionInset = UIEdgeInsetsZero;
        // No horizontal spacing.
        collectionViewLayout.minimumLineSpacing = 0.0;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:collectionViewLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;

        [_collectionView registerClass:[PTDocumentTabBarCell class] forCellWithReuseIdentifier:PTDocumentTabBar_CellReuseIdentifier];
        
        _interactiveMovementOffset = PTCGVectorZero;
        
        [_collectionView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCollectionViewLongPress:)]];
        
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_collectionView];
        
        _collectionView.allowsSelection = YES;
        
        // Disable scroll indicators.
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        
        _collectionView.backgroundColor = nil;
                
        _minimumTabWith = PT_DocumentTabBarDefaultMinimumTabWidth;
        
        // 1px bottom border.
        const CGFloat shadowHeight = (1 / UIScreen.mainScreen.nativeScale);
        const CGRect shadowFrame = CGRectMake(0, CGRectGetHeight(frame) - shadowHeight,
                                              CGRectGetWidth(frame), shadowHeight);
        UIView *shadowView = [[UIView alloc] initWithFrame:shadowFrame];
        
        shadowView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        
        // Allow the top margin and width to change.
        // (Left, bottom, and right margins, and height are fixed).
        shadowView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleWidth);
        
        [self addSubview:shadowView];
        
        // Background view.
        _backgroundView = [[UIToolbar alloc] init];
        _backgroundView.frame = self.bounds;
        _backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight);
        _backgroundView.translatesAutoresizingMaskIntoConstraints = YES;
        
        [self insertSubview:_backgroundView belowSubview:_collectionView];
        
        [self setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                forAxis:UILayoutConstraintAxisVertical];
        [self setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh + 1
                                              forAxis:UILayoutConstraintAxisVertical];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 32.0);
}

#pragma mark - Constraints

- (void)loadConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.collectionView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.collectionView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.collectionView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
    ] withPriority:UILayoutPriorityFittingSizeLevel];
}

- (void)updateLeadingViewConstraints
{
    if (!self.leadingView) {
        return;
    }
    
    self.leadingView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.leadingView.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
        [self.leadingView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.leadingView.trailingAnchor constraintEqualToAnchor:self.collectionView.leadingAnchor],
    ]];
}

- (void)updateTrailingViewConstraints
{
    if (!self.trailingView) {
        return;
    }
    
    self.trailingView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.trailingView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.trailingView.leadingAnchor constraintEqualToAnchor:self.collectionView.trailingAnchor],
        [self.trailingView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.trailingView.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
    ]];

}

- (void)updateConstraints
{
    if (!_constraintsLoaded) {
        _constraintsLoaded = YES;
        [self loadConstraints];
    }
    if (_needsLeadingViewConstraintsUpdate) {
        _needsLeadingViewConstraintsUpdate = NO;
        [self updateLeadingViewConstraints];
    }
    if (_needsTrailingViewConstraintsUpdate) {
        _needsTrailingViewConstraintsUpdate = NO;
        [self updateTrailingViewConstraints];
        
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Background view

- (void)setBackgroundView:(UIView *)backgroundView
{
    UIView *previousBackgroundView = _backgroundView;
    _backgroundView = backgroundView;
    
    if (previousBackgroundView) {
        [previousBackgroundView removeFromSuperview];
    }
    if (backgroundView) {
        backgroundView.frame = self.bounds;
        backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight);
        backgroundView.translatesAutoresizingMaskIntoConstraints = YES;
        
        [self insertSubview:backgroundView belowSubview:self.collectionView];
    }
}

#pragma mark - Leading/trailing views

- (void)setLeadingView:(UIView *)leadingView
{
    UIView *previousLeadingView = _leadingView;
    _leadingView = leadingView;
    
    if (previousLeadingView) {
        [previousLeadingView removeFromSuperview];
    }
    if (leadingView) {
        [self insertSubview:leadingView aboveSubview:self.collectionView];
        _needsLeadingViewConstraintsUpdate = YES;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setTrailingView:(UIView *)trailingView
{
    UIView *previousTrailingView = _trailingView;
    _trailingView = trailingView;
    
    if (previousTrailingView) {
        [previousTrailingView removeFromSuperview];
    }
    if (trailingView) {
        [self insertSubview:trailingView aboveSubview:self.collectionView];
        _needsTrailingViewConstraintsUpdate = YES;
        [self setNeedsUpdateConstraints];
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.tabManager.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTDocumentTabBarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PTDocumentTabBar_CellReuseIdentifier forIndexPath:indexPath];
        
    [cell.button addTarget:self
                    action:@selector(closeDocumentTab:)
          forControlEvents:(UIControlEventPrimaryActionTriggered)];
    
    return cell;
}

#pragma mark Interactive movement

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Multiple items are required for movement.
    return (self.tabManager.items.count > 1
            && self.tabManager.selectedIndex == indexPath.item);
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // Update data source.
    [self.tabManager moveItemAtIndex:sourceIndexPath.item
                             toIndex:destinationIndexPath.item];
}

#pragma mark - <UICollectionViewDelegate>

// NOTE: Consider highlights as selections.

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Allow selection (highlight) by default.
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView selectItemAtIndexPath:indexPath
                                 animated:NO
                           scrollPosition:UICollectionViewScrollPositionNone];
    
    // Scroll to make item visible.
    [collectionView pt_scrollItemToVisible:indexPath animated:YES];
    
    // Change selected index on selection (highlight).
    self.tabManager.selectedIndex = indexPath.item;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Selection is handled via highlighting.
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Selection is handled via highlighting.
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[PTDocumentTabBarCell class]]) {
        PTDocumentTabBarCell *tabCell = (PTDocumentTabBarCell *)cell;
        tabCell.tab = self.tabManager.items[indexPath.item];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[PTDocumentTabBarCell class]]) {
        PTDocumentTabBarCell *tabCell = (PTDocumentTabBarCell *)cell;
        tabCell.tab = nil;
    }
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect bounds = collectionView.bounds;
    
    UIEdgeInsets inset = collectionView.contentInset;
    if (@available(iOS 11, *)) {
        inset = collectionView.adjustedContentInset;
    }
    
    bounds = UIEdgeInsetsInsetRect(bounds, inset);
    
    const NSInteger itemCount = [self.collectionView numberOfItemsInSection:indexPath.section];
    
    return CGSizeMake(fmax(CGRectGetWidth(bounds) / itemCount, self.minimumTabWith), CGRectGetHeight(bounds));
}

#pragma mark - Selection

- (NSUInteger)selectedIndex
{
    NSArray<NSIndexPath *> *selectedIndexPaths = self.collectionView.indexPathsForSelectedItems;
    
    NSIndexPath *indexPath = selectedIndexPaths.firstObject;
    return (indexPath ? indexPath.item : NSNotFound);
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex animated:(BOOL)animated
{
    if (selectedIndex >= [self.collectionView numberOfItemsInSection:0]) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:selectedIndex inSection:0];
    
    [self.collectionView selectItemAtIndexPath:indexPath
                                      animated:animated
                                scrollPosition:UICollectionViewScrollPositionNone];
    
    [self.collectionView pt_scrollItemToVisible:indexPath animated:animated];
}

- (void)removeTabAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    const NSUInteger currentSelectedIndex = self.selectedIndex;
    
    [self.collectionView pt_performBatchUpdates:^{
        // Remove tab.
        [self.tabManager removeItemAtIndex:index];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        // Delete item from collection view.
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        if (index == currentSelectedIndex &&
            currentSelectedIndex == 0) {
            self.selectedIndex = 0;
        }
    } animated:animated];
}

- (void)reloadItems
{
    NSUInteger selected = self.selectedIndex;
    [self.collectionView reloadData];
    self.selectedIndex = selected;
}

#pragma mark - Actions

- (void)closeDocumentTab:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        
        // Get location of button in collection view.
        CGPoint location = [self.collectionView convertPoint:PTCGRectGetCenter(button.bounds) fromView:button];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
        if (!indexPath) {
            return;
        }
        
        // Remove tab.
        [self removeTabAtIndex:indexPath.item animated:YES];
    }
}

- (void)handleCollectionViewLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.view != self.collectionView) {
        return;
    }
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint position = [gestureRecognizer locationInView:self.collectionView];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:position];
            if (indexPath && [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath]) {
                
                UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
                if (cell) {
                    // Save offset from cell center to touch position.
                    self.interactiveMovementOffset = PTCGPointOffsetFromPoint(cell.center, position);
                    
                    // Adjust and apply initial target position.
                    CGPoint targetPosition = PTCGVectorOffsetPoint(position, self.interactiveMovementOffset);
                    [self.collectionView updateInteractiveMovementTargetPosition:targetPosition];
                }
                
                self.interactivelyMoving = YES;
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint position = [gestureRecognizer locationInView:self.collectionView];

            // Offset touch position by saved offset.
            CGPoint targetPosition = PTCGVectorOffsetPoint(position, self.interactiveMovementOffset);
            [self.collectionView updateInteractiveMovementTargetPosition:targetPosition];
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self.collectionView endInteractiveMovement];
            
            // Reset offset.
            self.interactiveMovementOffset = PTCGVectorZero;
            
            self.interactivelyMoving = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled:
            // Fall through.
        default:
        {
            [self.collectionView cancelInteractiveMovement];
            
            // Reset offset.
            self.interactiveMovementOffset = PTCGVectorZero;
            
            self.interactivelyMoving = NO;
            break;
        }
    }
}

@end
