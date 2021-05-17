//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTStandardColorsViewController.h"
#import "PTToolsUtil.h"
#import "PTColorViewCell.h"

#import "UIColor+PTHexString.h"
#import "UIColor+PTEquality.h"

static NSString * const PT_colorViewCellReuseIdentifier = @"ColorCell";

static const NSInteger PT_itemsPerRow = 7;
static const CGFloat PT_itemMargin = 8.0;

@interface PTStandardColorsViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic) BOOL requiresScrollViewInsets;

- (void)updateSelection;

@end

@implementation PTStandardColorsViewController


- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout colors:(NSArray<UIColor *> *)colors
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        _colors = [colors copy];
    }
    return self;
}

#pragma mark - Colors

@synthesize colors = _colors;

- (NSArray<UIColor *> *)colors
{
    if( _colors == Nil )
    {
        // Initialize with the standard color pallete.
        _colors = [self PT_standardColors];
    }
    return _colors;
}

- (void)setColors:(NSArray<UIColor *> *)colors
{
    if (!colors) {
        _colors = [self PT_standardColors];
    } else {
        _colors = [colors copy];
    }
    
    if ([self isViewLoaded]) {
        [self.collectionView reloadData];
    }
}

- (NSArray<UIColor *> *)PT_standardColors
{
    NSArray<NSString *> *hexColors = @[
        @"#F1A099", @"#FFC680", @"#FFE6A2", @"#80E5B1", @"#92E8E8", @"#A6BEF4", @"#E2A1E6",
        
        @"#E44234", @"#FF8D00", @"#FFCD45", @"#00CC63", @"#25D2D1", @"#4E7DE9", @"#C544CE",
        
        @"#88271F", @"#B54800", @"#D69A00", @"#007A3B", @"#167E7D", @"#2E4B8B", @"#76287B",
        
        @"#00000000", @"#FFFFFF", @"#CDCDCD", @"#9C9C9C", @"#696969", @"#373737", @"#000000",
    ];
    
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:hexColors.count];
    for (NSString *hexColor in hexColors) {
        [colors addObject:[UIColor pt_colorWithHexString:hexColor]];
    }
    
    return [colors copy];
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *standardColorsBGColor = [UIColor whiteColor];
    if (@available(iOS 11.0, *)) {
        standardColorsBGColor = [UIColor colorNamed:@"UIBGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
    }
    self.collectionView.backgroundColor = standardColorsBGColor;
    self.collectionView.opaque = YES;
    
    if (@available(iOS 11, *)) {
        // Always take safe area insets into account.
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    } else {
        // iOS 10 Workaround.

        // Scroll view insets are only applied automatically if the scroll view
        // is the view controller's root view.
        self.requiresScrollViewInsets = (self.view != self.collectionView);
    }
    
    // Enable multiple selection to keep previously selected cell until next is selected.
    self.collectionView.allowsMultipleSelection = YES;
    
    // Preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[PTColorViewCell class]
            forCellWithReuseIdentifier:PT_colorViewCellReuseIdentifier];

    // Set initial selection.
    [self updateSelection];
    
    if ([self.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *) self.collectionViewLayout;
        
        flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        flowLayout.minimumInteritemSpacing = PT_itemMargin;
        flowLayout.minimumLineSpacing = PT_itemMargin;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
    // iOS 10 Workaround.
    if (self.requiresScrollViewInsets && self.automaticallyAdjustsScrollViewInsets) {
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        CGFloat insetTop = self.topLayoutGuide.length;
        CGFloat insetBottom = self.bottomLayoutGuide.length;
        
        if (contentInset.top != insetTop || contentInset.bottom != insetBottom) {
            self.collectionView.contentInset = UIEdgeInsetsMake(insetTop, 0.0, insetBottom, 0.0);
            [self.collectionViewLayout invalidateLayout];
            
            // Scroll to top.
            [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x,
                                                              -self.collectionView.contentInset.top)
                                         animated:NO];
        }
    }
    PT_IGNORE_WARNINGS_END
    
    CGSize contentSize = self.collectionView.contentSize;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    // NOTE: DON'T add the adjustedContentInset, since that will be added by the navigationController.
    
    self.preferredContentSize = CGSizeMake(contentSize.width + contentInset.left + contentInset.right,
                                           contentSize.height + contentInset.top + contentInset.bottom);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Force layout invalidation when size changes because item sizes need to be updated.
    [self.collectionViewLayout invalidateLayout];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    // All items appear in the same section.
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.colors.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTColorViewCell *cell = (PTColorViewCell *) [collectionView dequeueReusableCellWithReuseIdentifier:PT_colorViewCellReuseIdentifier forIndexPath:indexPath];
    
    UIColor *color = self.colors[indexPath.item];
    
    [cell configureForColor:color];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<NSIndexPath *> *selectedIndexPaths = self.collectionView.indexPathsForSelectedItems;
    if (selectedIndexPaths.count == 1 && [selectedIndexPaths.firstObject isEqual:indexPath]) {
        // Do not allow deselecting the only selected item.
        return NO;
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionView.allowsMultipleSelection) {
        // Deselect any other selected cells.
        for (NSIndexPath *selectedIndexPath in self.collectionView.indexPathsForSelectedItems) {
            if (![selectedIndexPath isEqual:indexPath]) {
                [self.collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
            }
        }
    }
    
    UIColor *color = self.colors[indexPath.item];
    
    // Notify delegate of color selection.
    if ([self.colorPickerDelegate respondsToSelector:@selector(standardColorsViewController:didSelectColor:)]) {
        [self.colorPickerDelegate standardColorsViewController:self didSelectColor:color];
    }
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize collectionSize = collectionView.frame.size;
    UIEdgeInsets contentInset = collectionView.contentInset;
    if (@available(iOS 11, *)) {
        contentInset = collectionView.adjustedContentInset;
    }
    
    UIEdgeInsets sectionInset = UIEdgeInsetsZero;
    CGFloat interitemSpacing = 0.0;
    if ([collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
        
        sectionInset = flowLayout.sectionInset;
        interitemSpacing = flowLayout.minimumInteritemSpacing;
    }
    
    CGFloat totalSpacingWidth = (contentInset.left + contentInset.right + sectionInset.left + sectionInset.right); // Edge spacing.
    totalSpacingWidth += (interitemSpacing * (MAX(PT_itemsPerRow - 1, 0))); // Interitem spacing.
    
    CGFloat itemWidth = floorf((collectionSize.width - totalSpacingWidth) / PT_itemsPerRow);
    
    return CGSizeMake(itemWidth, itemWidth);
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
    BOOL changed = _selectedColor != selectedColor;
    
    _selectedColor = selectedColor;
    
    if (changed && self.viewLoaded) {
        [self updateSelection];
    }
}

- (void)updateSelection
{
    NSIndexPath *selectedIndexPath = nil;
    
    NSUInteger colorCount = self.colors.count;
    for (NSUInteger item = 0; item < colorCount; item++) {
        if ([self.colors[item] pt_isEqualToColor:self.selectedColor]) {
            selectedIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
            break;
        }
    }
    
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    if (selectedIndexPath) {
        [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

@end
