//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTThumbnailSliderView.h"

#import "PTThumbnailSliderViewItem.h"
#import "PTThumbnailSliderLayout.h"
#import "PTThumbnailSliderViewCell.h"
#import "PTHintController.h"

#import "PTPanTool.h"
#import "PTAnnotEditTool.h"
#import "PTToolsUtil.h"

#import "CGGeometry+PTAdditions.h"

#include <tgmath.h>

static const NSTimeInterval PTThumbnailSliderView_raiseLowerAnimationDuration = 0.25; // seconds

@interface PTPDFViewCtrl (LockBlock)

- (void)DocLockReadWithBlock:(void (^)(void))block;

@end

@implementation PTPDFViewCtrl (LockBlock)

- (void)DocLockReadWithBlock:(void (^)(void))block
{
    BOOL shouldUnlockRead = NO;
    @try {
        [self DocLockRead];
        shouldUnlockRead = YES;
        
        if (block) {
            block();
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlockRead) {
            @try {
                [self DocUnlockRead];
            }
            @catch (NSException *exception) {
                // Ignored.
            }
        }
    }
}

@end

typedef NS_ENUM(NSUInteger, PTThumbnailSliderScrubbingRate) {
    PTThumbnailSliderScrubbingRateHigh,
    PTThumbnailSliderScrubbingRateHalf,
    PTThumbnailSliderScrubbingRateQuarter,
    PTThumbnailSliderScrubbingRateFine,
};

@interface PTThumbnailSliderView () <UICollectionViewDelegateFlowLayout, PTThumbnailSliderLayoutDelegate, UIGestureRecognizerDelegate>

// Whether the PDFViewCtrl didn't have a PDFDoc when we needed it, so we need to wait until it has
// a doc before requesting thumbnails of querying document information (page count, size, etc.).
@property (nonatomic) BOOL needsDoc;

@property (nonatomic, strong) NSCache<NSNumber *, PTThumbnailSliderViewItem *> *itemCache;

@property (nonatomic, copy) NSArray<PTThumbnailSliderViewItem *> *items;
@property (nonatomic, strong) PTThumbnailSliderViewItem *floatingItem;

@property (nonatomic, strong) PTThumbnailSliderLayout *collectionViewLayout;

// A page background color appropriate for the PDFViewCtrl's current color post-process mode.
@property (nonatomic, readonly, getter=isNightModeEnabled) BOOL nightModeEnabled;
@property (nonatomic, readonly, copy) UIColor *pageBackgroundColor;

// Gesture recognizers.
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, assign) PTThumbnailSliderScrubbingRate scrubbingRate;

// Scrubbing hint.
@property (nonatomic, assign) BOOL showsScrubbingHint;
@property (nonatomic, strong) UILongPressGestureRecognizer *hintLongPressGestureRecognizer;

// Gesture state tracking.
@property (nonatomic, assign) CGPoint gestureStartLocation;
@property (nonatomic, assign) CGPoint gesturePreviousLocation;
@property (nonatomic, assign) CGPoint previousEffectiveLocation;

// Feedback generators.
@property (nonatomic, strong, nullable) UIImpactFeedbackGenerator *impactFeedbackGenerator;

@end

@implementation PTThumbnailSliderView

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        
        [self registerForNotificationsFromPDFViewCtrl:_pdfViewCtrl];
        
        _items = @[];
        
        _floatingItem = [[PTThumbnailSliderViewItem alloc] init];
        _floatingItem.pageNumber = 1;
        
        _itemCache = [[NSCache alloc] init];
        
        // Tap gesture recognizer.
        // Tapping jumps to the corresponding page number.
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:_tapGestureRecognizer];
        
        // Pan gesture recognizer.
        // Panning updates the current page number and activates the "magnify" effect.
        // NOTE: The pan and long-press gestures are mutually exclusive.
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handlePanGesture:)];
        [self addGestureRecognizer:_panGestureRecognizer];
        
        // Long-press gesture recognizer.
        // Long-pressing activates the "magnify" effect and updates the current page number while
        // panning.
        // NOTE: The pan and long-press gestures are mutually exclusive.
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleLongPressGesture:)];
        [self addGestureRecognizer:_longPressGestureRecognizer];
        
        _hintLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(handleHintLongPressGesture:)];
        _hintLongPressGestureRecognizer.minimumPressDuration = 1.0; // seconds
        _hintLongPressGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_hintLongPressGestureRecognizer];
        
        _magnification = 1.5;
        
        _adjustsScrubbingSpeed = YES;
        _scrubbingRate = PTThumbnailSliderScrubbingRateHigh;
        
        // (Custom) collection view layout.
        _collectionViewLayout = [[PTThumbnailSliderLayout alloc] init];
        _collectionViewLayout.spacing = 2.0;
        _collectionViewLayout.magnification = _magnification;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds
                                             collectionViewLayout:_collectionViewLayout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _collectionView.backgroundColor = nil;
        
        // Disable clipsToBounds (default is YES for UICollectionView) so that the cells can
        // expand outside their superview.
        _collectionView.clipsToBounds = NO;
        
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        // Disable scrolling, user interaction, and scroll indicators.
        _collectionView.scrollEnabled = NO;
        _collectionView.userInteractionEnabled = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        
        [self addSubview:_collectionView];
        
        [_collectionView registerClass:[PTThumbnailSliderViewCell class]
            forCellWithReuseIdentifier:@"cell"];
        
        [_collectionView registerClass:[PTThumbnailSliderViewCell class]
            forSupplementaryViewOfKind:PTThumbnailSliderFloatingItemKind
                   withReuseIdentifier:@"item"];
        
        // Mask to clip subviews horizontally only.
        // NOTE: The mask must be updated when the view's size changes.
        CALayer *maskLayer = [CALayer layer];
        maskLayer.backgroundColor = UIColor.whiteColor.CGColor;
        maskLayer.frame = CGRectMake(CGRectGetMinX(self.bounds), -(CGFLOAT_MAX / 2.0),
                                     CGRectGetWidth(self.bounds), CGFLOAT_MAX);
        
        self.layer.mask = maskLayer;
    }
    return self;
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self initWithPDFViewCtrl:toolManager.pdfViewCtrl];
    if (self) {
        _toolManager = toolManager;
        
        [self registerForNotificationsFromToolManager:_toolManager];
    }
    return self;
}

- (CGSize)pageSizeForPageNumber:(int)pageNumber doc:(PTPDFDoc *)doc
{
    CGSize size = CGSizeZero;
    
    PTPage *page = [doc GetPage:pageNumber];
    if (![page IsValid]) {
        return size;
    }
    
    // Get page crop box dimensions.
    PTPDFRect *cropBox = [page GetCropBox];
    [cropBox Normalize];
    
    size = CGSizeMake([cropBox Width],
                      [cropBox Height]);
    
    // Check page rotation.
    PTRotate pageRotation = [page GetRotation];
    switch (pageRotation) {
        case e_pt90:
        case e_pt270:
        {
            // Page is rotated - rotate size as well.
            size = CGSizeMake(size.height, size.width);
        }
            break;
        default:
            break;
    }

    return size;
}

- (NSArray<PTThumbnailSliderViewItem *> *)itemsForDoc:(PTPDFDoc *)doc pageCount:(int)pageCount pageRange:(NSRange)pageRange fittingRect:(CGRect)rect spacing:(CGFloat)spacing
{
    NSMutableArray<PTThumbnailSliderViewItem *> *mutableItems = [NSMutableArray array];
    
    int firstPageNumber = (int)pageRange.location;
    int lastPageNumber = (int)NSMaxRange(pageRange);
    
    CGFloat availableWidth = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    
    CGFloat remainingAvailableWidth = availableWidth;
    
    if ((firstPageNumber == 1 && lastPageNumber == pageCount) || pageRange.length == 1) {
        // Try to add an item for the first page.
        CGSize pageSize = [self pageSizeForPageNumber:firstPageNumber doc:doc];
        CGFloat pageWidth = PTCGSizeAspectRatio(pageSize) * height;
        
        if (remainingAvailableWidth >= pageWidth) {
            [mutableItems addObject:[[PTThumbnailSliderViewItem alloc] initWithPageNumber:firstPageNumber size:pageSize]];
            remainingAvailableWidth -= (pageWidth + spacing);
        } else {
            // No room for the first page or any others.
            return [mutableItems copy];
        }
        
        // Try to add an item for the last page.
        pageSize = [self pageSizeForPageNumber:lastPageNumber doc:doc];
        pageWidth = PTCGSizeAspectRatio(pageSize) * height;
        
        if (remainingAvailableWidth >= pageWidth) {
            [mutableItems addObject:[[PTThumbnailSliderViewItem alloc] initWithPageNumber:lastPageNumber size:pageSize]];
            remainingAvailableWidth -= pageWidth;
        } else {
            // No room for the last page or any others.
            return [mutableItems copy];
        }
        
        // RECURSE
        if (remainingAvailableWidth > 0 && (firstPageNumber + 1 < lastPageNumber - 1)) {
            
            NSRange nestedPageRange = NSMakeRange(firstPageNumber + 1,
                                                  (lastPageNumber - 1) - (firstPageNumber + 1));
            CGRect nestedRect = CGRectMake(0, 0, remainingAvailableWidth, height);
            
            NSArray<PTThumbnailSliderViewItem *> *nestedItems = [self itemsForDoc:doc
                                                                        pageCount:pageCount
                                                                        pageRange:nestedPageRange
                                                                      fittingRect:nestedRect
                                                                          spacing:spacing];
            [mutableItems addObjectsFromArray:nestedItems];
        }
    } else {
        if (pageRange.length == 0 || (pageRange.length % 2) != 0) { // Odd number of pages.
            // Try to add an item for the middle page.
            int middlePageNumber = firstPageNumber + round((float)(lastPageNumber - firstPageNumber) / 2.0);
            
            CGSize pageSize = [self pageSizeForPageNumber:middlePageNumber doc:doc];
            CGFloat pageWidth = PTCGSizeAspectRatio(pageSize) * height;
            
            if (remainingAvailableWidth >= pageWidth) {
                [mutableItems addObject:[[PTThumbnailSliderViewItem alloc] initWithPageNumber:middlePageNumber size:pageSize]];
                remainingAvailableWidth -= pageWidth;
            } else {
                // No room for the middle page or any others.
                return [mutableItems copy];
            }
            
            // RECURSE:
            CGFloat nestedAvailableWidth = remainingAvailableWidth / 2.0;
            
            // LEFT RECURSE
            if (nestedAvailableWidth > 0 && (firstPageNumber <= middlePageNumber - 1)) {
                NSRange nestedPageRange = NSMakeRange(firstPageNumber,
                                                      (middlePageNumber - 1) - firstPageNumber);
                CGRect nestedRect = CGRectMake(0, 0, nestedAvailableWidth, height);
                
                NSArray<PTThumbnailSliderViewItem *> *nestedItems = [self itemsForDoc:doc
                                                                            pageCount:pageCount
                                                                            pageRange:nestedPageRange
                                                                          fittingRect:nestedRect
                                                                              spacing:spacing];
                
                [mutableItems addObjectsFromArray:nestedItems];
            }
            
            // RIGHT RECURSE
            if (nestedAvailableWidth > 0 && (middlePageNumber + 1 <= lastPageNumber)) {
                NSRange nestedPageRange = NSMakeRange(middlePageNumber + 1,
                                                      lastPageNumber - (middlePageNumber + 1));
                CGRect nestedRect = CGRectMake(0, 0, nestedAvailableWidth, height);
                
                NSArray<PTThumbnailSliderViewItem *> *nestedItems = [self itemsForDoc:doc
                                                                            pageCount:pageCount
                                                                            pageRange:nestedPageRange
                                                                          fittingRect:nestedRect
                                                                              spacing:spacing];
                
                [mutableItems addObjectsFromArray:nestedItems];
            }

        } else { // Even number of pages.
            CGFloat nestedAvailableWidth = remainingAvailableWidth / 2.0;
            
            // LEFT RECURSE
            int leftLastPageNumber = firstPageNumber + ((int)(pageRange.length) / 2) - 1;
            if (nestedAvailableWidth > 0 && (firstPageNumber <= leftLastPageNumber)) {
                NSRange nestedPageRange = NSMakeRange(firstPageNumber,
                                                      leftLastPageNumber - firstPageNumber);
                CGRect nestedRect = CGRectMake(0, 0, nestedAvailableWidth, height);
                
                NSArray<PTThumbnailSliderViewItem *> *nestedItems = [self itemsForDoc:doc
                                                                            pageCount:pageCount
                                                                            pageRange:nestedPageRange
                                                                          fittingRect:nestedRect
                                                                              spacing:spacing];
                
                [mutableItems addObjectsFromArray:nestedItems];
            }
            
            // RIGHT RECURSE
            int rightLastPageNumber = leftLastPageNumber + 1;
            if (nestedAvailableWidth > 0 && (rightLastPageNumber <= lastPageNumber)) {
                NSRange nestedPageRange = NSMakeRange(rightLastPageNumber,
                                                      lastPageNumber - rightLastPageNumber);
                CGRect nestedRect = CGRectMake(0, 0, nestedAvailableWidth, height);
                
                NSArray<PTThumbnailSliderViewItem *> *nestedItems = [self itemsForDoc:doc
                                                                            pageCount:pageCount
                                                                            pageRange:nestedPageRange
                                                                          fittingRect:nestedRect
                                                                              spacing:spacing];
                
                [mutableItems addObjectsFromArray:nestedItems];
            }
        }
    }

    return [mutableItems copy];
}

- (NSArray<PTThumbnailSliderViewItem *> *)itemsFittingRect:(CGRect)rect spacing:(CGFloat)spacing
{
    __block NSArray<PTThumbnailSliderViewItem *> *items = nil;
    
    [self.pdfViewCtrl DocLockReadWithBlock:^{
        // Get the document's page count.
        int pageCount = 1;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        if (!doc) {
            return;
        }
        pageCount = [doc GetPageCount];
        
        NSRange pageRange = NSMakeRange(1, pageCount - 1);
        
        NSArray<PTThumbnailSliderViewItem *> *allItems = [self itemsForDoc:doc
                                                                 pageCount:pageCount
                                                                 pageRange:pageRange
                                                               fittingRect:rect
                                                                   spacing:spacing];
        
        // Sort items by page number.
        items = [allItems sortedArrayUsingComparator:^NSComparisonResult(PTThumbnailSliderViewItem *lhs, PTThumbnailSliderViewItem *rhs) {
            return lhs.pageNumber > rhs.pageNumber;
        }];
    }];
    
    return items;
}

- (NSArray<NSNumber *> *)thumbnailPageNumbersFittingRect:(CGRect)rect spacing:(CGFloat)spacing
{
    NSMutableArray<NSNumber *> *pageNumbers = [NSMutableArray array];
    
    CGFloat availableWidth = CGRectGetWidth(rect);
    
    // Assume pages are going to be letter sized.
    const CGFloat letterAspectRatio = 8.5 / 11.0;
    
    __block CGFloat aspectRatio = letterAspectRatio;
    
    [self.pdfViewCtrl DocLockReadWithBlock:^{
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        if (!doc) {
            return;
        }
        
        int pageCount = [doc GetPageCount];
        if (pageCount < 1) {
            return;
        }
        
        CGSize pageSize = [self pageSizeForPageNumber:MIN(2, pageCount) doc:doc];
        aspectRatio = PTCGSizeAspectRatio(pageSize);
    }];
    
    CGFloat itemWidth = aspectRatio * CGRectGetHeight(rect);

    int maxItemCount = 1;
    
    // Check if more than one item can fit.
    if ((availableWidth - itemWidth) >= (itemWidth + spacing)) {
        // Each additional item takes up itemWidth + spacing.
        CGFloat additionalItemWidth = itemWidth + spacing;
        
        // Calculate the number of additional items that can fit in the remaining space, after the
        // first item.
        int additionalItemCount = (int)floor((availableWidth - itemWidth) / additionalItemWidth);

        maxItemCount = 1 + additionalItemCount;
    }
    
    __block int itemCount = 0;
    
    [self.pdfViewCtrl DocLockReadWithBlock:^{
        int pageCount = 1;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        if (doc) {
            pageCount = [doc GetPageCount];
        }
        
        if (pageCount <= maxItemCount) {
            itemCount = pageCount;
            
            for (int pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
                [pageNumbers addObject:@(pageNumber)];
            }
        } else {
            itemCount = maxItemCount;
            
            if (itemCount > 1) {
                for (int i = 0; i < itemCount; i++) {
                    double relativePageNumber = ((double)i) / (itemCount - 1);
                    
                    int pageNumber = 1 + round((pageCount - 1) * relativePageNumber);
                    [pageNumbers addObject:@(pageNumber)];
                }
            } else {
                [pageNumbers addObject:@(1)];
            }
        }
    }];

    return [pageNumbers copy];
}

- (NSArray<PTThumbnailSliderViewItem *> *)itemsForPageNumbers:(NSArray<NSNumber *> *)pageNumbers
{
    NSMutableArray<PTThumbnailSliderViewItem *> *mutableItems = [NSMutableArray arrayWithCapacity:pageNumbers.count];
    
    NSMutableArray<PTThumbnailSliderViewItem *> *mutableItemsNeedingInfo = [NSMutableArray array];
    
    for (NSNumber *pageNumber in pageNumbers) {
        PTThumbnailSliderViewItem *item = [self.itemCache objectForKey:pageNumber];
        if (!item) {
            item = [[PTThumbnailSliderViewItem alloc] init];
            item.pageNumber = pageNumber.intValue;
            
            [self.itemCache setObject:item forKey:pageNumber];
            
            [mutableItemsNeedingInfo addObject:item];
        }
        [mutableItems addObject:item];
    }
    
    NSArray<PTThumbnailSliderViewItem *> *items = [mutableItems copy];
    NSArray<PTThumbnailSliderViewItem *> *itemsNeedingInfo = [mutableItemsNeedingInfo copy];
    
    if (itemsNeedingInfo.count == 0) {
        return items;
    }
    
    [self.pdfViewCtrl DocLockReadWithBlock:^{
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        if (!doc) {
            return;
        }
        
        for (PTThumbnailSliderViewItem *item in itemsNeedingInfo) {
            item.size = [self pageSizeForPageNumber:item.pageNumber doc:doc];
        }
    }];
    
    return items;
}

- (void)invalidateThumbnails
{
    if (![self.pdfViewCtrl GetDoc]) {
        self.needsDoc = YES;
        return;
    }
    
    CGRect bounds = self.collectionView.bounds;
    CGFloat spacing = self.collectionViewLayout.spacing;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSArray<NSNumber *> *pageNumbers = [self thumbnailPageNumbersFittingRect:bounds
                                                                         spacing:spacing];
        NSArray<PTThumbnailSliderViewItem *> *items = [self itemsForPageNumbers:pageNumbers];
        
//        NSArray<PTThumbnailSliderViewItem *> *items = [self itemsFittingRect:bounds spacing:spacing];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.items = items;
        });
    });
}

#pragma mark - Night mode

- (BOOL)isNightModeEnabled
{
    return (self.pdfViewCtrl.colorPostProcessMode == e_ptpostprocess_night_mode);
}

- (UIColor *)pageBackgroundColor
{
    if ([self isNightModeEnabled]) {
        return UIColor.blackColor;
    }
    return UIColor.whiteColor;
}

#pragma mark - Magnification

- (void)setMagnification:(CGFloat)magnification
{
    _magnification = magnification;
    
    self.collectionViewLayout.magnification = magnification;
}

#pragma mark - Scrubbing rate

- (void)setScrubbingRate:(PTThumbnailSliderScrubbingRate)scrubbingRate
{
    if (_scrubbingRate == scrubbingRate) {
        // No change.
        return;
    }
    
    _scrubbingRate = scrubbingRate;
    
    [self updateScrubbingHint];
}

- (CGFloat)factorForScrubbingRate:(PTThumbnailSliderScrubbingRate)rate
{
    switch (rate) {
        case PTThumbnailSliderScrubbingRateHigh:
            return 1.0;
        case PTThumbnailSliderScrubbingRateHalf:
            return 0.5;
        case PTThumbnailSliderScrubbingRateQuarter:
            return 0.25;
        case PTThumbnailSliderScrubbingRateFine:
            return 0.1;
    }
}

- (NSString *)titleForScrubbingRate:(PTThumbnailSliderScrubbingRate)rate
{
    switch (rate) {
        case PTThumbnailSliderScrubbingRateHigh:
            return PTLocalizedString(@"Hi-Speed Scrubbing", @"Hi scrubbing rate title");
        case PTThumbnailSliderScrubbingRateHalf:
            return PTLocalizedString(@"Half-Speed Scrubbing", @"Half scrubbing rate title");
        case PTThumbnailSliderScrubbingRateQuarter:
            return PTLocalizedString(@"Quarter-Speed Scrubbing", @"Quarter scrubbing rate title");
        case PTThumbnailSliderScrubbingRateFine:
            return PTLocalizedString(@"Fine Scrubbing", @"Fine scrubbing rate title");
    }

}

#pragma mark - Scrubbing rate hint

- (void)showScrubbingHint
{
    NSString *title = [self titleForScrubbingRate:self.scrubbingRate];
    NSString *message = PTLocalizedString(@"Slide your finger up to adjust the scrubbing rate.",
                                          @"Scrubbing rate hint message");
    
    CGRect rect = CGRectInset(self.superview.bounds, -10, -10);
    
    if (!UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        rect = CGRectInset(self.superview.bounds, -10, -35);
    }
    
    [PTHintController.sharedHintController showWithTitle:title
                                                 message:message
                                                fromView:self.superview
                                                    rect:rect];
}

- (void)updateScrubbingHint
{
    if (![PTHintController.sharedHintController isVisible]) {
        return;
    }
    
    PTHintController.sharedHintController.title = [self titleForScrubbingRate:self.scrubbingRate];
}

- (void)hideScrubbingHint
{
    [PTHintController.sharedHintController hide];
}

#pragma mark - Layout

- (void)setBounds:(CGRect)bounds
{
    CGRect oldBounds = self.bounds;
    
    [super setBounds:bounds];
    
    if (!CGRectEqualToRect(oldBounds, bounds)) {
        [self invalidateThumbnails];
        
        // Update the horizontal mask.
        self.layer.mask.frame = CGRectMake(0,
                                           -CGRectGetHeight(self.bounds) * 100,
                                           CGRectGetWidth(self.bounds),
                                           CGRectGetHeight(self.bounds) * (100 * 2 + 1));

    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 32.0);
}

#pragma mark - Items

- (void)setItems:(NSArray<PTThumbnailSliderViewItem *> *)items
{
    _items = items;
    
    // Sort items by pageNumber, descending.
    // The page thumbnails will be requested in this order, and since the most recent thumbnail
    // request is usually returned first.
    NSArray<PTThumbnailSliderViewItem *> *descendingPageOrderedItems = [items sortedArrayUsingComparator:^NSComparisonResult(PTThumbnailSliderViewItem *lhs, PTThumbnailSliderViewItem *rhs) {
        return lhs.pageNumber < rhs.pageNumber;
    }];
    
    for (PTThumbnailSliderViewItem *item in descendingPageOrderedItems) {
        if (!item.image) {
            [self requestThumbnailForPageNumber:item.pageNumber];
        }
    }
    
    [self.collectionView reloadData];
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    BOOL showsScrubbingHint = NO;
    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        __block int pageCount = 0;
        [self.pdfViewCtrl DocLockReadWithBlock:^{
            pageCount = [self.pdfViewCtrl GetPageCount];
        }];
        if (pageCount > 0 && pageCount > items.count) {
            showsScrubbingHint = YES;
        }
    }
    self.showsScrubbingHint = showsScrubbingHint;
}

- (void)invalidateFloatingItem
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.floatingItem.pageNumber inSection:0];

    UICollectionReusableView *supplementaryView = [self.collectionView supplementaryViewForElementKind:PTThumbnailSliderFloatingItemKind atIndexPath:indexPath];
    if (supplementaryView) {
        PTThumbnailSliderViewCell *view = (PTThumbnailSliderViewCell *)supplementaryView;
        
        [view configureWithItem:self.floatingItem];
    }
    
    [self invalidateFloatingItemLayout];
}

- (void)invalidateFloatingItemLayout
{
//    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.floatingItem.pageNumber inSection:0];
    
//    UICollectionViewLayoutInvalidationContext *context = [[[[self.collectionViewLayout class] invalidationContextClass] alloc] init];
//    [context invalidateSupplementaryElementsOfKind:PTThumbnailSliderFloatingItemKind
//                                      atIndexPaths:@[indexPath]];
//    [self.collectionViewLayout invalidateLayoutWithContext:context];
    
    [self.collectionViewLayout invalidateLayout];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTThumbnailSliderViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                                                forIndexPath:indexPath];
    
    cell.imageView.backgroundColor = self.pageBackgroundColor;
        
    [cell configureWithItem:self.items[indexPath.item]];
    cell.nightModeEnabled = [self isNightModeEnabled];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    PTThumbnailSliderViewCell *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                         withReuseIdentifier:@"item"
                                                                                forIndexPath:indexPath];
    
    view.imageView.backgroundColor = [self.pageBackgroundColor colorWithAlphaComponent:0.7];
        
    [view configureWithItem:self.floatingItem];
    view.nightModeEnabled = [self isNightModeEnabled];
    
    return view;
}

#pragma mark - <UICollectionViewDelegate>

#pragma mark - <PTThumbnailSliderLayoutDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTThumbnailSliderViewItem *item = self.items[indexPath.item];
    
    CGSize targetSize = CGSizeMake(CGRectGetHeight(self.collectionView.bounds),
                                   CGRectGetHeight(self.collectionView.bounds));
    
    return [self sizeForItem:item fittingSize:targetSize];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForFloatingItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize targetSize = CGSizeMake(CGRectGetHeight(self.collectionView.bounds),
                                   CGRectGetHeight(self.collectionView.bounds));
    
    return [self sizeForItem:self.floatingItem fittingSize:targetSize];
}

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView indexPathForFloatingItemInLayout:(UICollectionViewLayout *)collectionViewLayout
{
    if (self.items.count > 0) {
        return [NSIndexPath indexPathForItem:self.floatingItem.pageNumber inSection:0];
    }
    return nil;
}

- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout locationForFloatingItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self locationForPageNumber:self.floatingItem.pageNumber];
}

#pragma mark - Item sizing

- (CGSize)sizeForItem:(PTThumbnailSliderViewItem *)item fittingSize:(CGSize)targetSize
{
    CGSize itemSize = CGSizeZero;
    if (item.image) {
        itemSize = item.image.size;
    } else {
        itemSize = item.size;
    }
    
    CGFloat maximumDimension = fmin(targetSize.width, targetSize.height);
    
    if (itemSize.width > 0 && itemSize.height > 0) {
        CGFloat aspectRatio = itemSize.width / itemSize.height;
        
        if (aspectRatio > 1.0) {
            // width > height
            itemSize.width = maximumDimension;
            itemSize.height = itemSize.width / aspectRatio;
        } else {
            // width < height
            itemSize.height = maximumDimension;
            itemSize.width = itemSize.height * aspectRatio;
        }
    }
    
    return itemSize;
}

#pragma mark - Page number to/from location

- (int)pageNumberForLocation:(CGPoint)location
{
    int pageNumber = 0;
    
    NSIndexPath *leftIndexPath = nil;
    NSIndexPath *rightIndexPath = nil;
    
    const NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
        
        UICollectionViewLayoutAttributes *attributes = [self.collectionViewLayout unadjustedLayoutAttributesForItemAtIndexPath:indexPath];
        if (attributes) {
            
            if (attributes.center.x < location.x) {
                leftIndexPath = indexPath;
                continue;
            }
            
            if (attributes.center.x > location.x) {
                rightIndexPath = indexPath;
                break;
            }
        }
    }
    
    if (!leftIndexPath && rightIndexPath) {
        // Location is to the left of all items.
        pageNumber = 1;
    }
    else if (leftIndexPath && rightIndexPath) {
        // Location is bounded by two items.
        UICollectionViewLayoutAttributes *leftAttributes = [self.collectionViewLayout unadjustedLayoutAttributesForItemAtIndexPath:leftIndexPath];
        UICollectionViewLayoutAttributes *rightAttributes = [self.collectionViewLayout unadjustedLayoutAttributesForItemAtIndexPath:rightIndexPath];
        
        CGFloat separation = rightAttributes.center.x - leftAttributes.center.x;
        
        PTThumbnailSliderViewItem *leftItem = self.items[leftIndexPath.item];
        PTThumbnailSliderViewItem *rightItem = self.items[rightIndexPath.item];
        
        CGFloat progress = (location.x - leftAttributes.center.x) / separation;
        
        pageNumber = leftItem.pageNumber + round((rightItem.pageNumber - leftItem.pageNumber) * progress);
    }
    else if (leftIndexPath && !rightIndexPath) {
        // Location is to the right of all items.
        pageNumber = self.pdfViewCtrl.pageCount;
    }

    return pageNumber;
}

- (CGPoint)locationForPageNumber:(int)pageNumber
{
    CGFloat x = CGFLOAT_MAX;
    
    NSInteger leftIndex = NSNotFound;
    NSInteger centerIndex = NSNotFound;
    NSInteger rightIndex = NSNotFound;
    
    const NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        PTThumbnailSliderViewItem *item = self.items[itemIndex];
        
        if (item.pageNumber < pageNumber) {
            leftIndex = itemIndex;
            continue;
        }
        else if (item.pageNumber == pageNumber) {
            centerIndex = itemIndex;
            break;
        }
        else if (item.pageNumber > pageNumber) {
            rightIndex = itemIndex;
            break;
        }
    }
    
    if (centerIndex != NSNotFound) {
        // Found an exact page number match.
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:centerIndex inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self.collectionViewLayout unadjustedLayoutAttributesForItemAtIndexPath:indexPath];
        if (attributes) {
            x = attributes.center.x;
        }
    } else if (leftIndex != NSNotFound && rightIndex != NSNotFound) {
        // Found a pair of bounding page numbers.
        PTThumbnailSliderViewItem *leftItem = self.items[leftIndex];
        PTThumbnailSliderViewItem *rightItem = self.items[rightIndex];
        
        CGFloat pageSeparation = rightItem.pageNumber - leftItem.pageNumber;
        CGFloat progress = (pageNumber - leftItem.pageNumber) / pageSeparation;

        NSIndexPath *leftIndexPath = [NSIndexPath indexPathForItem:leftIndex inSection:0];
        NSIndexPath *rightIndexPath = [NSIndexPath indexPathForItem:rightIndex inSection:0];
        
        UICollectionViewLayoutAttributes *leftAttributes = [self.collectionViewLayout unadjustedLayoutAttributesForItemAtIndexPath:leftIndexPath];
        UICollectionViewLayoutAttributes *rightAttributes = [self.collectionViewLayout unadjustedLayoutAttributesForItemAtIndexPath:rightIndexPath];
        if (leftAttributes && rightAttributes) {
            CGFloat separation = rightAttributes.center.x - leftAttributes.center.x;
            
            x = leftAttributes.center.x + round(separation * progress);
        }
    }
    
    if (x < CGFLOAT_MAX) {
        return CGPointMake(x, CGRectGetMidY(self.collectionView.bounds));
    }
    
    return PTCGPointNull;
}

#pragma mark - Touches

- (void)raiseCellsAroundLocation:(CGPoint)location
{
    [self raiseCellsAroundLocation:location animated:NO];
}

- (void)raiseCellsAroundLocation:(CGPoint)location animated:(BOOL)animated
{
    if (animated) {
        [self.collectionView.superview layoutIfNeeded];
        
        self.collectionViewLayout.touchLocation = location;
        
        [UIView animateWithDuration:PTThumbnailSliderView_raiseLowerAnimationDuration animations:^{
            [self.collectionView.superview layoutIfNeeded];
        }];
    } else {
        self.collectionViewLayout.touchLocation = location;
    }
}

- (void)lowerCells
{
    [self.collectionView.superview layoutIfNeeded];
    
    self.collectionViewLayout.touchLocation = PTCGPointNull;
    
    [UIView animateWithDuration:PTThumbnailSliderView_raiseLowerAnimationDuration animations:^{
        [self.collectionView.superview layoutIfNeeded];
    }];
}

- (void)updatePageNumberForGesture:(UIGestureRecognizer *)gestureRecognizer
{
    [self updatePageNumberForLocation:[gestureRecognizer locationInView:self.collectionView]];
}

- (void)updatePageNumberForLocation:(CGPoint)location
{
    int pageNumber = [self pageNumberForLocation:location];
    if (pageNumber < 1) {
        return;
    }
    
    if (pageNumber != self.pdfViewCtrl.currentPage) {
        [self.pdfViewCtrl SetCurrentPage:pageNumber];
        
        if (pageNumber == 1 || pageNumber == self.pdfViewCtrl.pageCount) {
            [self.impactFeedbackGenerator impactOccurred];
        }
        [self.impactFeedbackGenerator prepare];
    }
}

#pragma mark - Gesture tracking

- (void)updateScrubbingSpeedForGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (!self.adjustsScrubbingSpeed) {
        // Don't adjust the touch location.
        return;
    }
    
    CGPoint location = [gestureRecognizer locationInView:self.collectionView];
    CGPoint trackCenter = self.collectionView.center;
        
    CGFloat verticalOffset = fabs(location.y - trackCenter.y);
    
    PTThumbnailSliderScrubbingRate rate;
    if (verticalOffset < 50.0) {
        rate = PTThumbnailSliderScrubbingRateHigh;
    }
    else if (verticalOffset < 100.0) {
        rate = PTThumbnailSliderScrubbingRateHalf;
    }
    else if (verticalOffset < 150.0) {
        rate = PTThumbnailSliderScrubbingRateQuarter;
    }
    else {
        rate = PTThumbnailSliderScrubbingRateFine;
    }

    if (rate != self.scrubbingRate) {
        self.scrubbingRate = rate;
    }
}

- (CGPoint)effectiveTouchLocationForGesture:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.collectionView];

    if (!self.adjustsScrubbingSpeed) {
        // Don't adjust the touch location.
        return location;
    }
    
    CGFloat trackingOffset = location.x - self.gesturePreviousLocation.x;
    
    CGFloat trackingOffsetAdjustment = [self factorForScrubbingRate:self.scrubbingRate] * trackingOffset;
    
    // When moving closer (vertically) to the view, add an extra adjustment to the effective location
    // to make it "meet" the touch location, which may be significantly different from scrubbing at
    // reduced speeds.
    CGFloat extraAdjustment = 0;
    
    if (self.scrubbingRate == PTThumbnailSliderScrubbingRateHigh) {
        if (((self.gestureStartLocation.y < location.y) && (location.y < self.gesturePreviousLocation.y)) ||
            ((self.gestureStartLocation.y > location.y) && (location.y > self.gesturePreviousLocation.y))) {
            // Calculate the offset between the touch and (previous) effective location.
            CGFloat offsetFromTouch = location.x - self.previousEffectiveLocation.x;
            
            extraAdjustment = offsetFromTouch / (1 + fabs(location.y - self.gestureStartLocation.y));
        }
    }
    
    location.x = self.previousEffectiveLocation.x + trackingOffsetAdjustment + extraAdjustment;
    
    return location;
}

- (void)beginTrackingGesture:(UIGestureRecognizer *)gestureRecognizer
{
    self.tracking = YES;
    
    self.impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] init];
    [self.impactFeedbackGenerator prepare];
    
    self.gestureStartLocation = [gestureRecognizer locationInView:self.collectionView];
    self.gesturePreviousLocation = self.gestureStartLocation;
    self.previousEffectiveLocation = self.gestureStartLocation;
    
    [self updateScrubbingSpeedForGesture:gestureRecognizer];
    
    CGPoint location = [self effectiveTouchLocationForGesture:gestureRecognizer];
    
    CGRect contentBounds = self.collectionViewLayout.contentBounds;
    
    if (CGRectContainsPoint(contentBounds, location)) {
        [self updatePageNumberForLocation:location];
        
        [self raiseCellsAroundLocation:location animated:YES];
    }
}

- (void)trackGesture:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.collectionView];
    
    [self updateScrubbingSpeedForGesture:gestureRecognizer];
    CGPoint effectiveLocation = [self effectiveTouchLocationForGesture:gestureRecognizer];
    
    [self raiseCellsAroundLocation:effectiveLocation];
    
    [self updatePageNumberForLocation:effectiveLocation];
    
    self.gesturePreviousLocation = location;
    self.previousEffectiveLocation = effectiveLocation;
}

- (void)endTrackingGesture:(UIGestureRecognizer *)gestureRecognizer
{
    [self lowerCells];
    
    // Release feedback generator.
    self.impactFeedbackGenerator = nil;
    
    self.gestureStartLocation = PTCGPointNull;
    
    self.tracking = NO;

    [self hideScrubbingHint];
}

#pragma mark - Gestures

- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateRecognized) {
        return;
    }
        
    [self updatePageNumberForGesture:gestureRecognizer];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self beginTrackingGesture:gestureRecognizer];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [self trackGesture:gestureRecognizer];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self endTrackingGesture:gestureRecognizer];
        }
            break;
        default:
            break;
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self beginTrackingGesture:gestureRecognizer];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [self trackGesture:gestureRecognizer];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self endTrackingGesture:gestureRecognizer];
        }
            break;
        default:
            break;
    }
}

- (void)handleHintLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            // Only show scrubbing hint on phones.
            if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad && self.showsScrubbingHint) {
                [self showScrubbingHint];
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
            break;
        default:
            break;
    }
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.hintLongPressGestureRecognizer) {
        if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Thumbnails

- (void)receivedThumbnail:(UIImage *)thumbnail forPageNumber:(int)pageNumber
{
    if (!thumbnail) {
        return;
    }
    
    // Cache the thumbnail.
    if (self.itemCache) {
        PTThumbnailSliderViewItem *item = [self.itemCache objectForKey:@(pageNumber)];
        if (!item) {
            // Add an item to the cache for the specified page number.
            item = [[PTThumbnailSliderViewItem alloc] init];
            item.pageNumber = pageNumber;
            [self.itemCache setObject:item forKey:@(pageNumber)];
        }
        if (!item.image) {
            item.image = thumbnail;
        }
    }
    
    NSMutableArray<NSIndexPath *> *itemsToInvalidate = [NSMutableArray array];
    
    // Update any items in self.items that have a matching pageNumber.
    NSInteger itemIndex = 0;
    for (PTThumbnailSliderViewItem *item in self.items) {
        if (item.pageNumber == pageNumber) {
            item.image = thumbnail;
            
            [itemsToInvalidate addObject:[NSIndexPath indexPathForItem:itemIndex inSection:0]];
        }
        itemIndex++;
    }
    
    if (itemsToInvalidate.count > 0) {
        [self.collectionView reloadData];
        [self.collectionViewLayout invalidateLayout];
    }
    
    if (self.floatingItem.pageNumber == pageNumber) {
        self.floatingItem.image = thumbnail;
        [self invalidateFloatingItem];
    }
}

- (void)requestThumbnailForPageNumber:(int)pageNumber
{
    if ([self.pdfViewCtrl GetDoc]) {
        [self.pdfViewCtrl GetThumbAsync:pageNumber completion:^(UIImage *image) {
            [self receivedThumbnail:image forPageNumber:pageNumber];
        }];
    }
}

- (void)updateFloatingItemForPageNumber:(int)pageNumber
{
    self.floatingItem.pageNumber = pageNumber;
    
    // Check for cached item (& image).
    PTThumbnailSliderViewItem *item = [self.itemCache objectForKey:@(pageNumber)];
    if (item.image) {
        self.floatingItem.image = item.image;
        [self invalidateFloatingItem];
    } else {
        // Clear out the image while waiting for the new thumbnail.
        self.floatingItem.image = nil;
        [self invalidateFloatingItem];
        
        // Request the thumbnail for the floating item's page.
        [self requestThumbnailForPageNumber:pageNumber];
    }
}

#pragma mark - Notifications

#pragma mark - PTPDFViewCtrl

- (void)registerForNotificationsFromPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlDidChangePageWithNotification:)
                                               name:PTPDFViewCtrlPageDidChangeNotification
                                             object:pdfViewCtrl];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlStreamingEventWithNotification:)
                                               name:PTPDFViewCtrlStreamingEventNotification
                                             object:pdfViewCtrl];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlColorPostProcessModeDidChangeWithNotification:)
                                               name:PTPDFViewCtrlColorPostProcessModeDidChangeNotification
                                             object:pdfViewCtrl];
}

- (void)pdfViewCtrlDidChangePageWithNotification:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    if (![self.pdfViewCtrl GetDoc]) {
        self.needsDoc = YES;
        return;
    }
    
    int pageNumber = ((NSNumber *)notification.userInfo[PTPDFViewCtrlCurrentPageNumberUserInfoKey]).intValue;
    
    [self updateFloatingItemForPageNumber:pageNumber];
    
    // Manually update current image position when not tracking.
    if (![self isTracking]) {
        if (self.needsDoc) {
            self.needsDoc = NO;
            [self invalidateThumbnails];
        }
    }
}

- (void)pdfViewCtrlStreamingEventWithNotification:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    NSDictionary<NSString *, id> *userInfo = notification.userInfo;
    
    PTDownloadedType eventType = ((NSNumber *)userInfo[PTPDFViewCtrlStreamingEventTypeUserInfoKey]).intValue;
    int pageNumber = ((NSNumber *)userInfo[PTPDFViewCtrlPageNumberUserInfoKey]).intValue;

    if (eventType == e_ptdownloadedtype_page) {
        // Check if the page's corresponding item has an image.
        for (PTThumbnailSliderViewItem *item in self.items) {
            if (item.pageNumber != pageNumber) {
                continue;
            }

            // Re-request the thumbnail for this page number now that the page is downloaded.
            [self requestThumbnailForPageNumber:pageNumber];
        }
    }
}

- (void)pdfViewCtrlColorPostProcessModeDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    [self.itemCache removeAllObjects];
    
    [self invalidateThumbnails];
    [self updateFloatingItemForPageNumber:self.floatingItem.pageNumber];
}

#pragma mark - PTToolManager

- (void)registerForNotificationsFromToolManager:(PTToolManager *)toolManager
{
    // Annotation added/modified/removed.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerAnnotationAddedWithNotification:)
                                               name:PTToolManagerAnnotationAddedNotification
                                             object:toolManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerAnnotationModifiedWithNotification:)
                                               name:PTToolManagerAnnotationModifiedNotification
                                             object:toolManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerAnnotationRemovedWithNotification:)
                                               name:PTToolManagerAnnotationRemovedNotification
                                             object:toolManager];
    
    // Page added/moved/removed.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerPageEventWithNotification:)
                                               name:PTToolManagerPageAddedNotification
                                             object:toolManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerPageEventWithNotification:)
                                               name:PTToolManagerPageMovedNotification
                                             object:toolManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerPageEventWithNotification:)
                                               name:PTToolManagerPageRemovedNotification
                                             object:toolManager];
    
    // Tool changed.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerToolChangedWithNotification:)
                                               name:PTToolManagerToolDidChangeNotification
                                             object:toolManager];
}

#pragma mark Annotation notifications

- (void)toolManagerAnnotationAddedWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    for (PTThumbnailSliderViewItem *item in self.items) {
        if (item.pageNumber == pageNumber) {
            [self requestThumbnailForPageNumber:pageNumber];
        }
    }
    
    if (self.floatingItem.pageNumber == pageNumber) {
        [self requestThumbnailForPageNumber:pageNumber];
    }
}

- (void)toolManagerAnnotationModifiedWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    if (![self.toolManager.tool isKindOfClass:[PTPanTool class]]) {
        return;
    }
    
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    for (PTThumbnailSliderViewItem *item in self.items) {
        if (item.pageNumber == pageNumber) {
            [self requestThumbnailForPageNumber:pageNumber];
        }
    }
    
    if (self.floatingItem.pageNumber == pageNumber) {
        [self requestThumbnailForPageNumber:pageNumber];
    }
}

- (void)toolManagerAnnotationRemovedWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    for (PTThumbnailSliderViewItem *item in self.items) {
        if (item.pageNumber == pageNumber) {
            [self requestThumbnailForPageNumber:pageNumber];
        }
    }
    
    if (self.floatingItem.pageNumber == pageNumber) {
        [self requestThumbnailForPageNumber:pageNumber];
    }
}

#pragma mark Page notifications

- (void)toolManagerPageEventWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self invalidateThumbnails];
}

#pragma mark Tool notifications

- (void)toolManagerToolChangedWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    if (![self.pdfViewCtrl GetDoc]) {
        return;
    }
    
    // An annotation was deselected when changing to the pan tool from the annot edit tool.
    if ([self.toolManager.tool isKindOfClass:[PTPanTool class]] &&
        [self.toolManager.tool.previousToolType isSubclassOfClass:[PTAnnotEditTool class]]) {

        int pageNumber = self.pdfViewCtrl.currentPage;
        
        [self.itemCache removeObjectForKey:@(pageNumber)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateFloatingItemForPageNumber:pageNumber];
        });
    }
}

@end
