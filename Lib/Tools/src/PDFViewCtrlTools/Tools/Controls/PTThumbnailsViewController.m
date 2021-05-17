//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTThumbnailsViewController.h"

#import "PTThumbnailViewLayout.h"
#import "PTThumbnailViewCell.h"
#import "PTBookmarkUtils.h"
#import "PTBookmarkManager.h"
#import "PTToolsUtil.h"
#import "PTAddPagesViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSLayoutConstraint+PTPriority.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "UIView+PTAdditions.h"
#import "UIViewController+PTAdditions.h"

#include <tgmath.h>

static NSString * const PT_ThumbnailCellIdentifier = @"cellIdentifier";
static NSString * const PT_ThumbnailHeaderIdentifier = @"thumbnailHeaderIdentifier";

const PTFilterMode PTThumbnailFilterAll = @"All";
const PTFilterMode PTThumbnailFilterAnnotated = @"Annotated";
const PTFilterMode PTThumbnailFilterBookmarked = @"Bookmarked";

NS_ASSUME_NONNULL_BEGIN

@interface PTThumbnailHeader : UICollectionReusableView <UIToolbarDelegate>

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UISegmentedControl* segmentedControl;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTThumbnailHeader

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Use a toolbar as the background view to get the same appearance as a UINavigationBar.
        _toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _toolbar.delegate = self;
        
        [self addSubview:_toolbar];
        
        self.layoutMargins = UIEdgeInsetsMake(8, 0, 8, 0);
        
        _segmentedControl = [[UISegmentedControl alloc] init];
        _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:_segmentedControl];
        
        // Schedule constraints load.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutMarginsGuide = self.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        // Center segmented control in superview.
        [self.segmentedControl.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.segmentedControl.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        // Pin segmented control to top and bottom of layout margins.
        [self.segmentedControl.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor],
        [self.segmentedControl.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
        
        // Leading and trailing edges must be within the layout margins area.
        [self.segmentedControl.leadingAnchor constraintGreaterThanOrEqualToAnchor:layoutMarginsGuide.leadingAnchor],
        [self.segmentedControl.trailingAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.trailingAnchor],
    ]];
    
    // Make segmented control as small as possible, respecting its intrinsicContentSize.
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.segmentedControl.widthAnchor constraintEqualToConstant:0],
        [self.segmentedControl.heightAnchor constraintEqualToConstant:0],
    ] withPriority:UILayoutPriorityDefaultLow];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Hierarchy

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        [self updateToolbar];
    }
}

#pragma mark - Toolbar

- (void)updateToolbar
{
    // Find the view's containing navigation controller.
    UINavigationController *navigationController = self.pt_viewController.navigationController;
    if (!navigationController) {
        return;
    }
    
    // Synchronize toolbar appearance with navigation bar.
    UINavigationBar *navigationBar = navigationController.navigationBar;
    
    self.toolbar.barStyle = navigationBar.barStyle;
    self.toolbar.barTintColor = navigationBar.barTintColor;
    self.toolbar.tintColor = navigationBar.tintColor;
    self.toolbar.translucent = navigationBar.translucent;
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

@end

@interface PTThumbnailsViewController ()

@property (nonatomic, readwrite, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) UIBarButtonItem *rotateCWButton;
@property (nonatomic, strong) UIBarButtonItem *rotateCCWButton;
@property (nonatomic, strong) UIBarButtonItem *addPagesButton;
@property (nonatomic, strong) UIBarButtonItem *selectAllButton;

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, strong, nullable) PTToolManager *toolManager;

@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, UIImage *> *thumbsList;

// current page, 1-indexed
@property (nonatomic, assign) int currentPageIndex;

@property (nonatomic, assign) CGPoint interactiveMovementOffset;

@property (nonatomic, assign) BOOL didSetupConstraints;

@property (nonatomic, assign, getter=isDismissing) BOOL dismissing;

@property (nonatomic, assign) CGSize pageSize;

@property (nonatomic, assign) unsigned long numAnnots;

@property (nonatomic, strong) NSMutableOrderedSet<NSNumber *> *pagesToShow;

@property (nonatomic, strong) PTAddPagesViewController *addPagesViewController;

@property (nonatomic, copy, nullable) NSString *documentPassword;
// Feedback generator.
@property (nonatomic, strong, nullable) UINotificationFeedbackGenerator *notificationFeedbackGenerator;
@end

@implementation PTThumbnailsViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        _thumbsList = [NSMutableDictionary dictionary];
        
        _editingEnabled = YES;
        
        _pagesToShow = [NSMutableOrderedSet orderedSet];
        
        _currentPageIndex = -11;
        
        _filterMode = PTThumbnailFilterAll;
        
        _filterModes = [NSOrderedSet orderedSetWithArray:@[PTThumbnailFilterAll, PTThumbnailFilterAnnotated, PTThumbnailFilterBookmarked]];
    }
    return self;
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self initWithPDFViewCtrl:toolManager.pdfViewCtrl];
    if (self) {
        _toolManager = toolManager;
    }
    return self;
}


#pragma mark - Properties

-(void)setCurrentPageIndex:(int)currentPageIndex
{
    _currentPageIndex = currentPageIndex;
}

#pragma mark - Utility

-(unsigned int)pageNumberFromIndexPath:(NSIndexPath*)indexPath
{
    if( self.filterMode == PTThumbnailFilterAll || self.pagesToShow.count == 0)
    {
        return (unsigned int)(indexPath.item+1);
    }
    else
    {
        unsigned int pageNumber = [self.pagesToShow[indexPath.item] unsignedIntValue];
        
        return pageNumber;
    }

}

-(NSIndexPath*)indexPathFromPageNumber:(unsigned int)pageNumber
{
    if( self.filterMode == PTThumbnailFilterAll || self.pagesToShow.count == 0)
    {
        return [NSIndexPath indexPathForItem:pageNumber-1 inSection:0];
    }
    else
    {
        NSUInteger cellNumber = [self.pagesToShow indexOfObject:@(pageNumber)];
        
        if( cellNumber == NSNotFound )
        {
            return Nil;
        }
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:cellNumber inSection:0];
        
        return indexPath;
    }
   
}

- (PTAddPagesViewController *)addPagesViewController
{
    if(!_addPagesViewController){
        _addPagesViewController = [[PTAddPagesViewController allocOverridden] initWithToolManager:self.toolManager];
    }
    return _addPagesViewController;
}

#pragma mark - Filtering

- (void)setEditingSupported:(BOOL)editingSupported
{
    _editingSupported = editingSupported && self.pdfViewCtrl.externalAnnotManager == Nil;
    
    [self updateEditButtonItems];

    if (!editingSupported) {
        // End editing.
        [self setEditing:NO animated:NO];
    }
}

-(void)setFilterMode:(PTFilterMode)filterMode
{
    if( filterMode == PTThumbnailFilterAll )
    {
        [self showAllPages];
        self.editingSupported = YES;
    }
    else if( filterMode == PTThumbnailFilterAnnotated )
    {
        [self showOnlyPagesWithAnnots];
        self.editingSupported = NO;
    }
    else if( filterMode == PTThumbnailFilterBookmarked )
    {
        [self showOnlyPagesWithBookmarks];
        self.editingSupported = NO;
    }
    
    _filterMode = filterMode;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    
    CGFloat height = self.filterModes.count > 1 ? 46.0 : 0.0;
    return CGSizeMake(self.view.frame.size.width, height);
}

- (void)setFilterModes:(NSOrderedSet<PTFilterMode> *)filterModes
{
    _filterModes = filterModes;
    if (![_filterModes containsObject:self.filterMode]) {
        self.filterMode = _filterModes.firstObject;
    }
    [self.collectionView reloadData];
}

-(void)segmentedControlValueChanged:(UISegmentedControl*)segmentedControl
{
    self.filterMode = [self.filterModes objectAtIndex:segmentedControl.selectedSegmentIndex];
    
    [self.collectionView reloadData];
}

-(void)showAllPages
{
    
    [self.pagesToShow removeAllObjects];
    
}

- (void)showOnlyPagesWithBookmarks {
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    @try {
        [doc LockRead];
        
        [self.pagesToShow removeAllObjects];
        
        NSArray* bookmarks = [PTBookmarkManager.defaultManager bookmarksForDoc:[self.pdfViewCtrl GetDoc]];
        
        for(PTUserBookmark* bookmark in bookmarks)
        {
            [self.pagesToShow addObject:@(bookmark.pageNumber)];
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: reason: %@", exception.name, exception.reason);
    } @finally {
        [doc UnlockRead];
    }

}

- (void)showOnlyPagesWithAnnots {
    
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    @try {
        
        [doc LockRead];
                
        [self.pagesToShow removeAllObjects];
        
        int pageCount = [self.pdfViewCtrl GetPageCount];
        
        for( int pageNumber = 1; pageNumber <= pageCount; pageNumber++)
        {
            NSArray<PTAnnot*>* annots = [self.pdfViewCtrl GetAnnotationsOnPage:pageNumber];
            
            for(PTAnnot* annot in annots)
            {
                if (![annot IsValid]) continue;
                
                BOOL isAnnot = NO;
                switch ([annot GetType])
                {
                    case e_ptLink:
                    {
                        isAnnot = NO;
                        break;
                    }
                    default:
                    {
                        isAnnot = YES;
                        break;
                    }
                }
                
                if(isAnnot)
                {
                    [self.pagesToShow addObject:@(pageNumber)];
                    break;
                }
            }
            
        }

    
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: reason: %@", exception.name, exception.reason);
    } @finally {
        [doc UnlockRead];
    }
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Collection view layout.
    PTThumbnailViewLayout *layout = [[PTThumbnailViewLayout alloc] init];
    layout.sectionHeadersPinToVisibleBounds = YES;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.allowsMultipleSelection = YES;
    
    self.collectionView.alwaysBounceVertical = YES;
    
    [self.collectionView registerClass:[PTThumbnailViewCell class] forCellWithReuseIdentifier:PT_ThumbnailCellIdentifier];
    
    layout.headerReferenceSize = CGSizeMake(100,46);
    
    [self.collectionView registerClass:[PTThumbnailHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PT_ThumbnailHeaderIdentifier];

    self.collectionView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    
    if (@available(iOS 10, *)) { 
        self.collectionView.prefetchingEnabled = NO;
    }
    
    self.interactiveMovementOffset = CGPointZero;
    
    // Add long press recognizer (used for activating drag & drop in edit mode).
    [self.collectionView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)]];
    
    [self.view addSubview:self.collectionView];
    
    if (@available(iOS 11, *)) {
        // Inset sections (cells) from safe area.
        // NOTE: This does *not* inset the section headers/footers, unlike the
        // UIScrollView contentInsetAdjustmentBehavior.
        layout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    }

    self.currentPageIndex = [self.pdfViewCtrl GetCurrentPage];
    
    // Title used when not in edit mode.
    NSString *title = nil;
//    BOOL shouldUnlock = NO;
//    @try {
//        [self.pdfViewCtrl DocLockRead];
//        shouldUnlock = YES;
//
//        title = [[[self.pdfViewCtrl GetDoc] GetDocInfo] GetTitle];
//    } @catch (NSException *exception) {
//        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
//    } @finally {
//        if (shouldUnlock) {
//            [self.pdfViewCtrl DocUnlockRead];
//        }
//    }
    if (title.length < 1) {
        title = PTLocalizedString(@"Thumbnails", @"Thumbnails browser title");
    }
    if (self.title.length == 0) {
        self.title = title;
    }

    
    self.pageSize = [self pageSizeForThumbnails];
        
    self.deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteItem:)];
    self.deleteButton.enabled = NO;

    self.rotateCWButton = [[UIBarButtonItem alloc] initWithImage:[PTToolsUtil toolImageNamed:@"ic_rotate_right_black_24dp"] style:UIBarButtonItemStylePlain target:self action:@selector(rotatePagesClockwise:)];
    self.rotateCWButton.enabled = NO;

    self.rotateCCWButton = [[UIBarButtonItem alloc] initWithImage:[PTToolsUtil toolImageNamed:@"ic_rotate_left_black_24dp"] style:UIBarButtonItemStylePlain target:self action:@selector(rotatePagesCounterClockwise:)];
    self.rotateCCWButton.enabled = NO;

    self.addPagesButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPagesButtonPressed:)];

    self.selectAllButton = [[UIBarButtonItem alloc] initWithTitle:PTLocalizedString(@"Select All", @"Select All pages title") style:UIBarButtonItemStylePlain target:self action:@selector(selectAll:)];
    
    self.notificationFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
    // Start in a non-editable state.
    [self setEditing:NO animated:NO];
    
    // editing document pages not support while collaborating
    [self setEditingSupported:(self.pdfViewCtrl.externalAnnotManager == Nil)];
    
    [self updateBarButtonItems:NO];
    
    // Schedule constraints update.
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints
{
    if (!self.didSetupConstraints) {
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
           [self.collectionView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
           [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
           [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
           ]];
        
        // Constraints are set up.
        self.didSetupConstraints = YES;
    }
    
    // Call super implementation as final step.
    [super updateViewConstraints];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.editingEnabled) {
        [self.navigationController setToolbarHidden:self.toolManager.isReadonly animated:animated];
    }
    
    

    if (self.editing) {
        [self setEditing:NO animated:NO];
    }
    
    [self updateDoneButton:animated];
    
    if( self.filterMode == PTThumbnailFilterAnnotated )
    {
        [self showOnlyPagesWithAnnots];
    }
    else if( self.filterMode == PTThumbnailFilterBookmarked )
    {
        [self showOnlyPagesWithBookmarks];
    }
    else //if( self.filterMode == PTThumbnailFilterAll )
    {
        [self showAllPages];
    }
    
    if (!self.dismissing) {
        [self.collectionView reloadData];
        
        self.currentPageIndex = [self.pdfViewCtrl GetCurrentPage];
        
    }
    [self.notificationFeedbackGenerator prepare];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlPageCountDidChangeNotification:)
                                               name:PTPDFViewCtrlStreamingEventNotification
                                             object:self.pdfViewCtrl];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerPageAddedWithNotification:)
                                               name:PTToolManagerPageAddedNotification
                                             object:self.toolManager];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
      if(CGSizeEqualToSize(self.collectionView.contentSize, CGSizeZero)) {
        [self scrollToCurrentPage];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.collectionView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTPDFViewCtrlStreamingEventNotification
                                                object:self.pdfViewCtrl];
    
    if (self.editing) {
        [self setEditing:NO animated:NO];
    }

    self.notificationFeedbackGenerator = nil;

    if (self.transitionCoordinator) {
        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            self.dismissing = YES;
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            self.dismissing = NO;
        }];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Update the constraints so that the collectionView's layout resizes to the new size.
    [self.view setNeedsUpdateConstraints];
    // Force layout invalidation when size changes because item sizes need to be updated.
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [self loadViewIfNeeded];
    
    if (editing && ![self isEditingEnabled]) {
        return;
    }
    
    [self updateBarButtonItems:animated];
    
    if (editing) {
        // Disable deletion and rotation buttons when starting editing.
        self.deleteButton.enabled = NO;
        self.rotateCWButton.enabled = NO;
        self.rotateCCWButton.enabled = NO;
    } else {
        [self.collectionView cancelInteractiveMovement];
    }
    
    // Update visible cells.
    for (PTThumbnailViewCell *cell in self.collectionView.visibleCells) {
        [cell setEditing:editing animated:animated];
    }
    
    [self updateTitle];
    [self clearSelection:YES];
    
    PTThumbnailHeader* thumbnailHeader = (PTThumbnailHeader*)[self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    thumbnailHeader.segmentedControl.enabled = !editing;
    
//    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
    [self.thumbsList removeAllObjects];
}

#pragma mark - Editing

- (void)setEditingEnabled:(BOOL)editingEnabled
{
    _editingEnabled = editingEnabled;
    
    if (!editingEnabled) {
        [self setEditing:NO animated:NO];
    }
//    else
//    {
//        [self.navigationController setToolbarHidden:self.toolManager.isReadonly animated:animated];
//    }

    [self updateEditButtonItems];
}

- (void)updateEditButtonItems
{
    const BOOL canEdit = ([self isEditingEnabled] && self.editingSupported);
    
    self.addPagesButton.enabled = canEdit;
    self.editButtonItem.enabled = canEdit;
}

#pragma mark - Done button

- (UIBarButtonItem *)doneButtonItem
{
    if (!_doneButtonItem) {
        _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    }
    return _doneButtonItem;
}

- (BOOL)showsDoneButton
{
    // Don't show the "Done" button when editing or in a popover presentation.
    return !([self isEditing] || [self pt_isInPopover]);
}

- (void)updateDoneButton:(BOOL)animated
{
    UIBarButtonItem *rightBarButtonItem = nil;
    if ([self showsDoneButton]) {
        rightBarButtonItem = self.doneButtonItem;
    }
    
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem
                                      animated:animated];
}

#pragma mark - Bar button items

- (void)updateBarButtonItems:(BOOL)animated
{
    [self updateDoneButton:animated];
    
    if ([self isEditing] && [self isEditingEnabled]) {
        // Set toolbar items for editing.
        [self setToolbarItems:@[
            self.addPagesButton,
            [UIBarButtonItem pt_flexibleSpaceItem],
            self.deleteButton,
            [UIBarButtonItem pt_flexibleSpaceItem],

            self.rotateCCWButton,
            [UIBarButtonItem pt_fixedSpaceItemWithWidth:24],
            self.rotateCWButton,

            [UIBarButtonItem pt_flexibleSpaceItem],
            self.editButtonItem,
        ] animated:animated];
    } else {
        // Set toolbar items for normal state.
        [self setToolbarItems:@[
            self.addPagesButton,
            [UIBarButtonItem pt_flexibleSpaceItem],
            self.editButtonItem,
        ] animated:animated];
    }
}

#pragma mark - header

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{

    PTThumbnailHeader* headerView = [collectionView dequeueReusableSupplementaryViewOfKind:
                                         UICollectionElementKindSectionHeader withReuseIdentifier:PT_ThumbnailHeaderIdentifier forIndexPath:indexPath];
    
    [headerView.segmentedControl removeAllSegments];
    int idx = 0;
    for (PTFilterMode filterMode in self.filterModes) {
        NSString *localizedSegmentTitle;
        // Hardcoded because genstrings/extractLocStrings will only accept string literals for localized strings
        if (filterMode == PTThumbnailFilterAll) {
            localizedSegmentTitle = PTLocalizedString(@"All", @"All pages");
        }else if (filterMode == PTThumbnailFilterBookmarked){
            localizedSegmentTitle = PTLocalizedString(@"Bookmarked", @"Bookmarked pages");
        }else if (filterMode == PTThumbnailFilterAnnotated){
            localizedSegmentTitle = PTLocalizedString(@"Annotated", @"Annotated pages");
        }
        [headerView.segmentedControl insertSegmentWithTitle:localizedSegmentTitle atIndex:idx animated:NO];
        idx++;
    }

    NSUInteger selectedIndex = [self.filterModes indexOfObject:self.filterMode];
    headerView.segmentedControl.selectedSegmentIndex = selectedIndex;

    [headerView.segmentedControl addTarget:self
                                    action:@selector(segmentedControlValueChanged:)
                          forControlEvents:UIControlEventValueChanged];

    headerView.segmentedControl.enabled = !self.editing;
    
    return headerView;
}


#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // There is only one section that contains all the items.
    
    if( self.filterMode != PTThumbnailFilterAll )
    {
        return self.pagesToShow.count;
    }
    else //if( self.filterMode == PTThumbnailFilterAll )
    {
        return [[self.pdfViewCtrl GetDoc] GetPageCount];
    }
    

}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTThumbnailViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PT_ThumbnailCellIdentifier forIndexPath:indexPath];
    
    
	cell.nightMode = !([self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_none);
	
    BOOL isCurrentPage = self.currentPageIndex ==  [self pageNumberFromIndexPath:indexPath];// (indexPath.item+1);
    BOOL isChecked = [collectionView.indexPathsForSelectedItems containsObject:indexPath];
    
    int pageNumber = [self pageNumberFromIndexPath:indexPath];
    
    NSString *pageLabel = [self.toolManager.pageLabelManager pageLabelTitleForPageNumber:pageNumber];
    
    [cell setPageNumber:pageNumber
              pageLabel:pageLabel
          isCurrentPage:isCurrentPage
              isEditing:self.editing
              isChecked:isChecked];
    
    if ([self.thumbsList.allKeys containsObject:indexPath]) {
        [cell setThumbnail:self.thumbsList[indexPath] forPage:pageNumber];
    } else {
        [self requestThumbnail:(int)pageNumber];
    }
    
    return cell;
}

-(BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    // All items can be moved in edit mode.
    return [self isEditing];
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
//    [self clearSelection:YES];
    
    BOOL didSetCurrentPage = NO;
        
    // update all cells in between
    if (sourceIndexPath.item < destinationIndexPath.item) {
        for (NSInteger index = sourceIndexPath.item; index < destinationIndexPath.item; index++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:index+1 inSection:0];

            // Swap thumbnails.
            UIImage *thumb = self.thumbsList[nextIndexPath];
            self.thumbsList[nextIndexPath] = self.thumbsList[indexPath];
            self.thumbsList[indexPath] = thumb;
            
            if (indexPath.item+1 == self.currentPageIndex) {
                if (indexPath.item == sourceIndexPath.item) {
                    self.currentPageIndex = (int)destinationIndexPath.item+1;
                } else {
                    self.currentPageIndex--;
                }
                didSetCurrentPage = YES;
            }
            
        }
        if (destinationIndexPath.item+1 == self.currentPageIndex && !didSetCurrentPage) {
            if (destinationIndexPath.item == sourceIndexPath.item) {
                // current page index did not change
            } else {
                self.currentPageIndex--;
            }
        }
    } else {
        for (NSInteger index = sourceIndexPath.item; index > destinationIndexPath.item; index--) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            NSIndexPath *prevIndexPath = [NSIndexPath indexPathForItem:index-1 inSection:0];
            
            // Swap thumbnails.
            UIImage *thumb = self.thumbsList[prevIndexPath];
            self.thumbsList[prevIndexPath] = self.thumbsList[indexPath];
            self.thumbsList[indexPath] = thumb;
            
            if (indexPath.item+1 == self.currentPageIndex) {
                if (indexPath.item == sourceIndexPath.item) {
                    self.currentPageIndex = (int)destinationIndexPath.item+1;
                } else {
                    self.currentPageIndex--;
                }
                didSetCurrentPage = YES;
            }
            
        }
        if (destinationIndexPath.item+1 == self.currentPageIndex && !didSetCurrentPage) {
            if (destinationIndexPath.item == sourceIndexPath.item) {
                // current page index did not change
            } else {
                self.currentPageIndex++;
            }
        }
    }
    
    // do nothing if the page was not moved
    if (sourceIndexPath.item != destinationIndexPath.item) {
        // update PDFDoc
        unsigned int sourcePageNum = (unsigned int) sourceIndexPath.item + 1;
        unsigned int destinationPageNum = (unsigned int) destinationIndexPath.item + 1;

        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLock:YES];
            shouldUnlock = YES;
            
            // get the page to move
            PTPage *pageToMove = [doc GetPage:sourcePageNum];
            
            NSString* docPath = [doc GetFileName];
            
            NSURL* url = [NSURL fileURLWithPath:docPath];
            
            NSArray<NSMutableDictionary*>* bookmarkArray = [PTBookmarkUtils bookmarkDataForDocument:url];
            
            NSArray<NSMutableDictionary*>* sortedBookmarks = [bookmarkArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                int first = [a[@"page-number"] intValue];
                int second = [b[@"page-number"] intValue];
                return (first > second);
            }];
            
            NSMutableArray<NSMutableDictionary*>* mutableBookmarkArray = [sortedBookmarks mutableCopy];
            
            if (sourceIndexPath.item < destinationIndexPath.item) {
                // Copy page to destination.
                PTPageIterator *dest = [doc GetPageIterator:destinationPageNum + 1];
                [doc PageInsert:dest page:pageToMove];
                
                // Delete original page.
                PTPageIterator *itr = [doc GetPageIterator:sourcePageNum];
                [doc PageRemove:itr];
            } else {
                // Copy page to destination.
                PTPageIterator *dest = [doc GetPageIterator:destinationPageNum];
                [doc PageInsert:dest page:pageToMove];
                
                // Delete original page.
                PTPageIterator *itr = [doc GetPageIterator:sourcePageNum + 1];
                [doc PageRemove:itr];
            }
            
            PTPage* newPage = [doc GetPage:destinationPageNum];
            
            NSMutableArray* newBookmarks = [PTBookmarkUtils updateUserBookmarks:mutableBookmarkArray
                                                                oldPageNumber:sourcePageNum
                                                                newPageNumber:destinationPageNum
                                                                 oldSDFNumber:[[pageToMove GetSDFObj] GetObjNum]
                                                                 newSDFNumber:[[newPage GetSDFObj] GetObjNum]];
            
            [PTBookmarkUtils saveBookmarkData:newBookmarks forFileUrl:url];
            
            [PTBookmarkManager.defaultManager updateBookmarksForDoc:doc
                                         pageMovedFromPageNumber:sourcePageNum
                                                      pageObjNum:[[pageToMove GetSDFObj] GetObjNum]
                                                      toPageNumber:destinationPageNum
                                                      pageObjNum:[[newPage GetSDFObj] GetObjNum]];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlock];
            }
        }
        
        // Notify tool manager of page move.
        [self.toolManager pageMovedFromPageNumber:sourcePageNum toPageNumber:destinationPageNum];
    }
    
    [self updateCellsFromIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (![cell isKindOfClass:[PTThumbnailViewCell class]]) {
        return;
    }
    
    PTThumbnailViewCell *thumbnailCell = (PTThumbnailViewCell *)cell;
    
    thumbnailCell.editing = self.editing;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        self.deleteButton.enabled = (collectionView.indexPathsForSelectedItems.count > 0);
        self.rotateCWButton.enabled = (collectionView.indexPathsForSelectedItems.count > 0);
        self.rotateCCWButton.enabled = (collectionView.indexPathsForSelectedItems.count > 0);
        [self updateTitle];
    } else {
        self.currentPageIndex =  [self pageNumberFromIndexPath:indexPath];  // (int)indexPath.item+1; //james
        [self done];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.deleteButton.enabled = (collectionView.indexPathsForSelectedItems.count > 0);
    self.rotateCWButton.enabled = (collectionView.indexPathsForSelectedItems.count > 0);
    self.rotateCCWButton.enabled = (collectionView.indexPathsForSelectedItems.count > 0);
    [self updateTitle];
}

#pragma mark - Sizing

- (CGSize)pageSizeForThumbnails
{
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        PTPage *page = [doc GetPage:1];
        if ([page IsValid]) {
            PTPDFRect *cropBoxRect = [page GetCropBox];
            [cropBoxRect Normalize];
            
            return CGSizeMake([cropBoxRect Width], [cropBoxRect Height]);
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    // Default: US letter size.
    return CGSizeMake(595.28, 841.89);
}

- (CGSize)thumbnailSizeForPageSize:(CGSize)pageSize containerSize:(CGSize)containerSize interitemSpacing:(CGFloat)interitemSpacing
{
    static const CGFloat targetVisibleThumbnailCount = 10;
    
    CGFloat pageAspectRatio = (pageSize.height != 0) ? (pageSize.width / pageSize.height) : 1;
    
    CGFloat containerArea = containerSize.width * containerSize.height;
    
    // Determine the approximate thumbnail width.
    CGFloat approximateThumbnailArea = containerArea / targetVisibleThumbnailCount;
    CGFloat approximateThumbnailWidthSquared = approximateThumbnailArea * pageAspectRatio;
    CGFloat approximateThumbnailWidth = sqrt(approximateThumbnailWidthSquared);
    
    // Determine number of columns for approximate thumbnail width.
    CGFloat columnCount = fmax(1, round(containerSize.width / approximateThumbnailWidth));
    
    // Determine available width for thumbnails from total interitem spacing.
    CGFloat totalInteritemSpacing = (interitemSpacing * (columnCount - 1));
    CGFloat availableWidth = containerSize.width - totalInteritemSpacing;
    
    CGFloat thumbnailWidth = availableWidth / columnCount;
    CGFloat thumbnailHeight = thumbnailWidth / pageAspectRatio;
    
    return CGSizeMake(floor(thumbnailWidth), floor(thumbnailHeight));
}

#pragma mark - UICollectionViewDelegateFlowLayout methods

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect containerBounds = collectionView.bounds;
    
    // Inset bounds by contentInset.
    UIEdgeInsets contentInset = collectionView.contentInset;
    if (@available(iOS 11, *)) {
        contentInset = collectionView.adjustedContentInset;
    }
    
    containerBounds = UIEdgeInsetsInsetRect(containerBounds, contentInset);
    
    // Inset bounds by sectionInset.
    UIEdgeInsets sectionInset = UIEdgeInsetsZero;
    CGFloat interitemSpacing = 0;
    if ([collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
        
        sectionInset = flowLayout.sectionInset;
        
        interitemSpacing = flowLayout.minimumInteritemSpacing;
    }
    
    containerBounds = UIEdgeInsetsInsetRect(containerBounds, sectionInset);
    
    CGSize containerSize = containerBounds.size;
    CGSize pageSize = self.pageSize;
    
    return [self thumbnailSizeForPageSize:pageSize containerSize:containerSize interitemSpacing:interitemSpacing];
}

#pragma mark - UILongPressGestureRecognizer action method

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
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
                [self collectionView:self.collectionView didBeginInteractiveMovementForItemAtIndexPath:indexPath withTargetPosition:position];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint position = [gestureRecognizer locationInView:self.collectionView];
            position = [self collectionView:self.collectionView interactiveMovementTargetPositionForProposedPosition:position];
            [self.collectionView updateInteractiveMovementTargetPosition:position];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self.collectionView endInteractiveMovement];
            [self collectionViewDidEndInterativeMovement:self.collectionView];
            break;
        }
        default:
        {
            [self.collectionView cancelInteractiveMovement];
            [self collectionViewDidCancelInteractiveMovement:self.collectionView];
            break;
        }
    }
}

# pragma mark - Interactive movement methods

/**
 @brief
 This method is called when the collection view begins interactive movement for an item.
 
 @discussion
 When interactive movement begins, the collection view's layout object sets the center property
 of the item's layout attributes to an internally provided value, usually equal to the item's center.
 Subsequent updates to the layout attributes' center property will set its value to the position
 provided to -[UICollectionView updateInteractiveMovementTargetPosition:].
 
 In order to move the item relative to the initial target position, this method saves the offset
 between the item's center and the initial target position. The offset is then subtracted from all
 subsequent positions provided to -[UICollectionView updateInteractiveMovementTargetPosition:].

 @param collectionView The collection view object for which interactive movement is now active.
 @param indexPath The index path of the item that is being moved.
 @param position The position of the item in the collection view's coordinate system.
 */
- (void)collectionView:(UICollectionView *)collectionView didBeginInteractiveMovementForItemAtIndexPath:(NSIndexPath *)indexPath withTargetPosition:(CGPoint)position
{
    PTThumbnailViewCell *cell = (PTThumbnailViewCell*) [collectionView cellForItemAtIndexPath:indexPath];
    
    self.interactiveMovementOffset = CGPointMake(position.x - cell.center.x, position.y - cell.center.y);
    
    // Adjust and apply initial target position.
    position = [self collectionView:collectionView interactiveMovementTargetPositionForProposedPosition:position];
    [collectionView updateInteractiveMovementTargetPosition:position];
    
    // Animate cell into interactive state.
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        cell.alpha = 0.7;
        cell.transform = CGAffineTransformMakeScale(1.25, 1.25);
    } completion:nil];
}

- (void)collectionViewDidEndInterativeMovement:(UICollectionView *)collectionView
{
    self.interactiveMovementOffset = CGPointZero;
}

- (void)collectionViewDidCancelInteractiveMovement:(UICollectionView *)collectionView
{
    self.interactiveMovementOffset = CGPointZero;
}

- (CGPoint)collectionView:(UICollectionView *)collectionView interactiveMovementTargetPositionForProposedPosition:(CGPoint)proposedPosition
{
    return CGPointMake(proposedPosition.x - self.interactiveMovementOffset.x,
                       proposedPosition.y - self.interactiveMovementOffset.y);
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        [self loadViewIfNeeded];
        
        NSAssert(_collectionView != nil,
                 @"Collection view failed to load");
    }
    return _collectionView;
}

#pragma mark - Selector
-(void)done
{
    [self.pdfViewCtrl CancelAllThumbRequests];
    [self.pdfViewCtrl UpdatePageLayout];

    unsigned int pageNumber = self.currentPageIndex;

    [self.pdfViewCtrl SetCurrentPage:pageNumber];

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)rotatePagesClockwise:(id)sender
{
    NSArray<NSIndexPath *> *selectedItems = self.collectionView.indexPathsForSelectedItems;
    PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        for (NSIndexPath *indexPath in selectedItems) {
            int pageNumber = (int) indexPath.item + 1;
            PTPage *page = [doc GetPage:pageNumber];
            PTRotate originalRotation = [page GetRotation];
            PTRotate rotation;
            switch (originalRotation)
            {
                case e_pt0:   rotation = e_pt90;  break;
                case e_pt90:  rotation = e_pt180; break;
                case e_pt180: rotation = e_pt270; break;
                case e_pt270: rotation = e_pt0;   break;
                default:      rotation = e_pt0;   break;
            }
            [page SetRotation: rotation];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
        [self updateThumbsList];
        [self updatePageNumber:selectedItems];
        [self.pdfViewCtrl UpdatePageLayout];
    }
}

-(void)rotatePagesCounterClockwise:(id)sender
{
    NSArray<NSIndexPath *> *selectedItems = self.collectionView.indexPathsForSelectedItems;
    PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        for (NSIndexPath *indexPath in selectedItems) {
            int pageNumber = (int) indexPath.item + 1;
            PTPage *page = [doc GetPage:pageNumber];
            PTRotate originalRotation = [page GetRotation];
            PTRotate rotation;
            switch (originalRotation)
            {
                case e_pt0:   rotation = e_pt270;  break;
                case e_pt90:  rotation = e_pt0; break;
                case e_pt180: rotation = e_pt90; break;
                case e_pt270: rotation = e_pt180;   break;
                default:      rotation = e_pt0;   break;
            }
            [page SetRotation: rotation];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    [self updateThumbsList];
    [self updatePageNumber:selectedItems];
    [self.pdfViewCtrl UpdatePageLayout];
}

-(void)addPagesButtonPressed:(UIBarButtonItem*)button
{
    self.addPagesViewController.modalPresentationStyle = UIModalPresentationPopover;
    self.addPagesViewController.popoverPresentationController.barButtonItem = button;
    self.addPagesViewController.popoverPresentationController.delegate = self;
    self.addPagesViewController.popoverPresentationController.permittedArrowDirections = (UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown);
    [self presentViewController:self.addPagesViewController animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}

-(void)deleteItem:(id)sender
{
    // Show confirmation alert message.
	NSString *title = PTLocalizedString(@"Delete Page(s)?", @"");
	NSString *message = PTLocalizedString(@"Do you want to delete the selected page(s)?", @"");
	NSString *cancelTitle = PTLocalizedString(@"Cancel", @"");
	NSString *deleteTitle = PTLocalizedString(@"Delete", @"");
	
	UIAlertController *alertController = [UIAlertController
										  alertControllerWithTitle:title
										  message:message
										  preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
														   style:UIAlertActionStyleCancel
														 handler:nil];
	
	UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:deleteTitle
														   style:UIAlertActionStyleDestructive
														 handler:^(UIAlertAction *action) {
															 [self deleteSelectedItems];
														 }];
	
	[alertController addAction:cancelAction];
	[alertController addAction:deleteAction];

	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteSelectedItems
{
    NSArray<NSIndexPath *> *selectedItems = self.collectionView.indexPathsForSelectedItems;
    
    // Sort selected items by index.
    NSArray *sortedArray = [selectedItems sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSIndexPath *first = (NSIndexPath*)a;
        NSIndexPath *second = (NSIndexPath*)b;
        return (first.item < second.item);
    }];
    
    if (sortedArray.count < 1) {
        // Nothing to delete.
        return;
    }
    
    if (sortedArray.count >= [[self.pdfViewCtrl GetDoc] GetPageCount]) {
        // Attempting to delete all pages in the document.
        NSString *title = PTLocalizedString(@"Cannot Delete All Pages",
                                            @"Alert title for error deleting all pages");

        NSString *message = PTLocalizedString(@"All the pages in the document cannot be deleted.",
                                              @"Alert message for error deleting all pages");
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        NSString *okTitle = PTLocalizedString(@"OK", @"OK title");
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        
        alertController.preferredAction = okAction;
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    

        // Delete from back
        for (NSIndexPath *indexPath in sortedArray) {
            
            __block PTPDFDoc* currentDoc;
            __block PTPage *page;
            int pageNumber = (int) indexPath.item + 1;;
            
            [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
                
                currentDoc = doc;
 
                [self.collectionView performBatchUpdates:^{

                    

                    // change current page
                    if (self.currentPageIndex == pageNumber) {
                        if (pageNumber < [doc GetPageCount]) {
                            //self.currentPageIndex++;
                        } else {
                            self.currentPageIndex--;
                        }
                    } else if (self.currentPageIndex > pageNumber) {
                        self.currentPageIndex--;
                    }

                    // delete page from PDFDoc
                    page = [doc GetPage:pageNumber];
                    PTPageIterator *itr = [doc GetPageIterator:pageNumber];
                    [doc PageRemove:itr];

                    // delete cell from control
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];

                    [self.thumbsList removeObjectForKey:indexPath];
                    
                    [PTBookmarkManager.defaultManager updateBookmarksForDoc:currentDoc pageDeletedWithPageObjNum:[[page GetSDFObj] GetObjNum]];

                } completion:nil];
            } error:Nil];
            
            // Update bookmark.
           
            
            [self.toolManager pageRemovedForPageNumber:pageNumber];

        }


    [self updateThumbsList];
    [self updatePageNumber:selectedItems];
    [self clearSelection:NO];
}

-(void)updatePageNumber:(NSArray*)items
{
    NSArray *sortedArray;
    sortedArray = [self.collectionView.indexPathsForVisibleItems sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSIndexPath *first = (NSIndexPath*)a;
        NSIndexPath *second = (NSIndexPath*)b;
        return (first.item > second.item);
    }];
    
    NSIndexPath* first = sortedArray.firstObject;
    int pageNum = (int)first.item+1;
    
    for (int i=0; i<[[self.pdfViewCtrl GetDoc] GetPageCount]; i++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        if (indexPath == nil){
            //NSLog(@"couldn't find index path");
        } else {
            PTThumbnailViewCell *cell = (PTThumbnailViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            if (cell && [self.collectionView.visibleCells containsObject:cell]) {
                NSString *pageLabel = [self.toolManager.pageLabelManager pageLabelTitleForPageNumber:pageNum];
                BOOL isCurrentPage = self.currentPageIndex == pageNum;
                BOOL isChecked = NO;
                [cell setPageNumber:pageNum pageLabel:pageLabel isCurrentPage:isCurrentPage isEditing:self.editing isChecked:isChecked];
                if ([self.thumbsList.allKeys containsObject:indexPath]) {
                    [cell setThumbnail:self.thumbsList[indexPath] forPage:indexPath.item+1];
                } else {
                    [self requestThumbnail:(int)indexPath.item+1];
                }
                
                pageNum++;
            }
        }
    }
}

-(void)updateThumbsList
{
    if (self.thumbsList) {
        for (int i=0; i<[[self.pdfViewCtrl GetDoc] GetPageCount]; i++) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            if (indexPath == nil){
                //NSLog(@"couldn't find index path");
            } else {
                if ([self.thumbsList.allKeys containsObject:indexPath] ) {
                    // do nothing
                } else {
                    NSIndexPath* next = [self findNextThumb:indexPath];
                    if (next) {
                        UIImage* thumb = self.thumbsList[next];
                        self.thumbsList[indexPath] = thumb;
                        [self.thumbsList removeObjectForKey:next];
                    }
                }
            }
        }
    }
}

-(NSIndexPath*)findNextThumb:(NSIndexPath*)start
{
    if (start && self.thumbsList) {
        if ([self.thumbsList.allKeys containsObject:start] ) {
            return start;
        } else {
            if (start.item+1 <[[self.pdfViewCtrl GetDoc] GetPageCount]) {
                NSIndexPath* next = [NSIndexPath indexPathForItem:start.item+1 inSection:0];
                return [self findNextThumb:next];
            } else {
                return nil;
            }
        }
    } else
        return nil;
}

-(void)selectAll:(id)sender
{
	NSString* selectAll = PTLocalizedString(@"Select All", @"");
	
    if ([self.selectAllButton.title isEqual:selectAll]) {
        NSInteger numSections = [self.collectionView numberOfSections];
        for (int section = 0; section < numSections; section++) {
            NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
            for (int item = 0; item < numItems; item++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                if (indexPath) {
                    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                }
            }
        }
        
        self.deleteButton.enabled = NO;
		
		NSString* deselectAll = PTLocalizedString(@"Deselect All", @"");
        
        self.selectAllButton.title = deselectAll;
    } else {
        [self clearSelection:YES];
        
        self.selectAllButton.title = selectAll;
    }
    
}

- (IBAction)checkboxClickEvent:(id)sender event:(id)event
{
    CGPoint currentTouchPosition = [[[event allTouches] anyObject] locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint: currentTouchPosition];
    
    if (!indexPath) {
        //NSLog(@"couldn't find index path");
    } else {
        
        //NSLog(@"%ld indexPath", (long)indexPath.item);
        
        if ([self.collectionView.indexPathsForSelectedItems containsObject:indexPath]) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        } else {
            [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        if (self.collectionView.indexPathsForSelectedItems.count > 0) {
            self.deleteButton.enabled = YES;
        } else {
            self.deleteButton.enabled = NO;
        }
        
        [self updateTitle];
    }
}

#pragma mark - Thumbnail

- (void)requestThumbnail:(int)pageNumber
{
    __weak __typeof__(self) weakSelf = self;
    [self.pdfViewCtrl GetThumbAsync:pageNumber completion:^(UIImage * _Nullable image) {
        __strong __typeof__(weakSelf) self = weakSelf;
        if (!image) {
            return;
        }
        [self setThumbnail:image forPage:pageNumber];
    }];
}

- (void)setThumbnail:(UIImage*)image forPage:(NSInteger)pageNum
{
    NSIndexPath *indexPath = [self indexPathFromPageNumber:(unsigned int)pageNum];

    if (indexPath == nil) {
        //NSLog(@"couldn't find index path");
    } else {
        PTThumbnailViewCell *cell = (PTThumbnailViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [cell setThumbnail:image forPage:pageNum];
        }
    }
}

#pragma mark - Actions

- (void)scrollToCurrentPage
{
    NSIndexPath* indexPath = [self indexPathFromPageNumber:self.currentPageIndex];
    
    if (indexPath == nil){
        //NSLog(@"couldn't find index path");
    } else {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
}

// NOTE:
// -[UICollectionView cellForItemAtIndexPath:] will return nil for the items being moved interactively.
// Those items are invalidated by -[UICollectionViewLayout invalidationContextForEndingInteractiveMovementOfItemsToFinalIndexPaths:previousIndexPaths:movementCancelled:],
// which triggers calls to -[UICollectionViewDataSource collectionView:cellForItemAtIndexPath:]
// for only those items.
-(void)updateCellsFromIndexPath:(NSIndexPath*)fromPath toIndexPath:(NSIndexPath*)toPath
{
    // Determine the minimum and maximum item index.
    NSInteger minItem;
    NSInteger maxItem;
    
    if (fromPath.item < toPath.item) {
        minItem = fromPath.item;
        maxItem = toPath.item;
    } else {
        minItem = toPath.item;
        maxItem = fromPath.item;
    }
    
    for (NSInteger item = minItem; item <= maxItem; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        if ([cell isKindOfClass:[PTThumbnailViewCell class]]) {
            PTThumbnailViewCell *thumbnailCell = (PTThumbnailViewCell *)cell;
            
            const int pageNumber = (int)indexPath.item + 1;
            NSString *pageLabel = [self.toolManager.pageLabelManager pageLabelTitleForPageNumber:pageNumber];

            [thumbnailCell setPageNumber:pageNumber pageLabel:pageLabel];
        }
    }
}

-(void)clearSelection:(BOOL)uncheckCell
{
    if (self.collectionView.indexPathsForSelectedItems.count > 0) {
        for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        
        [self updateTitle];
    }
    
    self.deleteButton.enabled = NO;
    self.rotateCWButton.enabled = NO;
    self.rotateCCWButton.enabled = NO;
    [self updateTitle];
}

- (void)updateTitle
{
    if (self.editing) {
        NSUInteger selectedCount = self.collectionView.indexPathsForSelectedItems.count;
        
        NSString *format = PTLocalizedString(@"Selected: %lu", @"");
        
        self.navigationItem.title = [NSString localizedStringWithFormat:format, (unsigned int)selectedCount];
    } else {
        self.navigationItem.title = self.title;
    }
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateDoneButton:NO];
}

#pragma mark - Notifications

-(void)pdfViewCtrlPageCountDidChangeNotification:(NSNotification*)notification
{
    
    BOOL shouldUnlock = NO;
    @try {
        
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        long oldPageNum = [self.collectionView numberOfItemsInSection:0];
        long newPageNum = [[self.pdfViewCtrl GetDoc] GetPageCount];
        
        NSMutableArray* newItems = [NSMutableArray array];
        
        for(int i = 0; i < newPageNum - oldPageNum; i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:oldPageNum+i inSection:0];
            [newItems addObject:indexPath];
        }
        
        if( newItems.count > 0 )
        {
            [self.collectionView insertItemsAtIndexPaths:[newItems copy]];
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }

}

-(void)toolManagerPageAddedWithNotification:(NSNotification*)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    [self.collectionView reloadData];
}

@end
