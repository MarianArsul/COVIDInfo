//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationAnnotationViewController.h"

#import "PTBaseCollaborationManager+Private.h"

#import "PTCollaborationAnnotationDataSource.h"
#import "PTCollaborationAnnotationViewCell.h"
#import "PTTableHeaderView.h"
#import "PTToolsUtil.h"

#import "CGGeometry+PTAdditions.h"
#import "PTPDFViewCtrl+PTAdditions.h"

@interface PTCollaborationAnnotationViewController () <PTCollaborationAnnotationDataSourceDelegate, PTTableHeaderViewDelegate>

@property (nonatomic, strong) PTCollaborationAnnotationDataSource *dataSource;
@property (nonatomic, assign) PTCollaborationAnnotationSortMode sortMode;

@property (nonatomic, strong) PTTableHeaderView *headerView;

@property (nonatomic, assign) BOOL showsDoneButton;

@property (nonatomic, assign, getter=isTabBarItemSetup) BOOL tabBarItemSetup;

@end

@implementation PTCollaborationAnnotationViewController

- (instancetype)init
{
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager
{
    self = [self init];
    if (self) {
        _collaborationManager = collaborationManager;
        
        _sortMode = PTCollaborationAnnotationSortModePageNumber;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = PTLocalizedString(@"Annotations", @"Collaboration annotation list title");
    
    if (@available(iOS 11.0, *)) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 8.0, 0, 0.0);
        self.tableView.separatorInsetReference = UITableViewSeparatorInsetFromAutomaticInsets;
    }
    
    PTAnnotationManager *annotationManager = self.collaborationManager.annotationManager;
    
    self.dataSource = [[PTCollaborationAnnotationDataSource alloc] initWithTableView:self.tableView];
    self.dataSource.annotationManager = annotationManager;
    self.dataSource.delegate = self;
    
    [self.tableView registerClass:[PTCollaborationAnnotationViewCell class] forCellReuseIdentifier:@"Cell"];
    self.dataSource.cellReuseIdentifier = @"Cell";
    
    // Show done button for phones.
    self.showsDoneButton = self.view.frame.size.width ==  self.view.window.bounds.size.width;
    
    self.toolbarItems =
    @[
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
      self.editButtonItem,
      ];
    
    self.headerView = [[PTTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    self.headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.headerView.delegate = self;
    
    UIView *maskView = [[UIView alloc] initWithFrame:self.headerView.frame];
    maskView.backgroundColor = UIColor.whiteColor;
    self.headerView.maskView = maskView;
    
    self.tableView.tableHeaderView = self.headerView;
    
    // Empty table view indicator.
    self.tableView.backgroundView = self.emptyIndicator;
    
    // Hide by default.
    self.emptyIndicator.hidden = YES;
    
    [self updateSortModeTitle];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
    
    self.dataSource.paused = NO;
    
    [self updateEmptyIndicatorHidden];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Reset editing state.
    self.editing = NO;
    
    self.dataSource.paused = YES;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self updateContentInsetBottom];
    
    [self updateTableHeaderView];
}

- (void)updateContentInsetBottom
{
    // Get the contentSize excluding the table header view.
    CGSize contentSize = self.tableView.contentSize;
    contentSize.height -= CGRectGetHeight(self.tableView.tableHeaderView.frame);
    
    // Get the table view bounds excluding the safe area insets.
    CGRect bounds = self.tableView.bounds;
    if (@available(iOS 11.0, *)) {
        bounds = UIEdgeInsetsInsetRect(bounds, self.tableView.safeAreaInsets);
    }
    
    UIEdgeInsets contentInset = self.tableView.contentInset;
    
    if (contentSize.height < CGRectGetHeight(bounds)) {
        contentInset.bottom = CGRectGetHeight(bounds) - contentSize.height;
    } else {
        contentInset.bottom = 0;
    }
    
    self.tableView.contentInset = contentInset;
}

- (void)updateTableHeaderView
{
    UIView *tableHeaderView = self.tableView.tableHeaderView;
    if (!tableHeaderView) {
        return;
    }
    
    // Manually update the height of the table header view.
    // See: https://useyourloaf.com/blog/variable-height-table-view-header
    
    // Calculate the header view's smallest size while satisfying its constraints.
    CGSize size = [tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    // Only update header view height if there was a change.
    if (CGRectGetHeight(tableHeaderView.frame) != size.height) {
        // Update header view (frame) height.
        CGRect frame = tableHeaderView.frame;
        frame.size.height = size.height;
        tableHeaderView.frame = frame;
        
        // Reassign table header view for new frame size to be recognized.
        self.tableView.tableHeaderView = tableHeaderView;
    }
    
    [self updateTableHeaderViewMask];
}

- (void)updateTableHeaderViewMask
{
    if (!self.tableView.tableHeaderView.maskView) {
        return;
    }
    
    // Update the table header view mask used to "clip" the header view at the visible edge of the
    // table view, to prevent the header from showing through UIVisualEffectViews, etc.
    
    // Get the content offset from the top of the safe area.
    CGPoint contentOffset = self.tableView.contentOffset;
    if (@available(iOS 11.0, *)) {
        contentOffset.y += self.tableView.safeAreaInsets.top;
    }
    
    UIView *headerView = self.tableView.tableHeaderView;

    // Initial header mask view frame matches the header view's bounds.
    CGRect maskViewFrame = headerView.bounds;
    
    // Check if a portion of the header view is visible.
    if (contentOffset.y < CGRectGetHeight(headerView.bounds)) {
        // Adjust origin and height of mask view frame to account for the amount of the header view
        // that is covered.
        maskViewFrame.origin.y = contentOffset.y;
        maskViewFrame.size.height -= contentOffset.y;
    } else {
        // Header is completely covered, so mask the entire view.
        maskViewFrame = CGRectZero;
    }
    headerView.maskView.frame = maskViewFrame;
}

#pragma mark - UIViewController

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (self.showsDoneButton) {
        // Hide Done button while editing.
        UIBarButtonItem *rightBarButtonItem = editing ? nil : self.doneButtonItem;
        
        [self.navigationItem setRightBarButtonItem:rightBarButtonItem animated:animated];
    }
}

- (UITabBarItem *)tabBarItem
{
    UITabBarItem *tabBarItem = [super tabBarItem];
    
    if (![self isTabBarItemSetup]) {
        // Add image to tab bar item.
        tabBarItem.image = [PTToolsUtil toolImageNamed:@"ic_annotations_white_24dp"];
        
        self.tabBarItemSetup = YES;
    }
    
    return tabBarItem;
}

#pragma mark - Done button

- (void)setShowsDoneButton:(BOOL)showsDoneButton
{
    _showsDoneButton = showsDoneButton;
    
    if (showsDoneButton && ![self isEditing]) {
        self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

@synthesize doneButtonItem = _doneButtonItem;

- (UIBarButtonItem *)doneButtonItem
{
    if (!_doneButtonItem) {
        _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                        target:self
                                                                        action:@selector(dismiss)];
    }
    return _doneButtonItem;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Empty indicator

@synthesize emptyIndicator = _emptyIndicator;

- (PTEmptyTableViewIndicator *)emptyIndicator
{
    if (!_emptyIndicator) {
        PTEmptyTableViewIndicator * const emptyIndicator = [[PTEmptyTableViewIndicator alloc] init];
        emptyIndicator.alignment = (PTEmptyTableViewAlignmentCenteredHorizontally |
                                    PTEmptyTableViewAlignmentCenteredVertically);
        emptyIndicator.preservesSuperviewLayoutMargins = YES;
        
        NSString * const emptyText = PTLocalizedString(@"This document does not contain any annotations.",
                                                @"Empty annotation list label");
        emptyIndicator.label.text = emptyText;
        
        _emptyIndicator = emptyIndicator;
    }
    return _emptyIndicator;
}

- (void)updateEmptyIndicatorHidden
{
    const NSInteger numberOfSections = self.dataSource.numberOfSections;
    const BOOL isEmptyIndicatorHidden = (numberOfSections > 0);
    
    self.emptyIndicator.hidden = isEmptyIndicatorHidden;
}

#pragma mark - Actions

- (void)selectAnnotation:(PTManagedAnnotation *)annotation pageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.collaborationManager.toolManager.pdfViewCtrl;
    
    NSString *identifier = annotation.identifier;
    
    PTAnnot *annot = [pdfViewCtrl findAnnotWithUniqueID:annotation.identifier onPageNumber:pageNumber];
    if (!annot) {
        NSLog(@"Failed to find annotation for identifier \"%@\" on page %d", identifier, pageNumber);
        return;
    }
    
    [self.collaborationManager.toolManager selectAnnotation:annot onPageNumber:pageNumber];
    
    // Flash the annotation's rect on the page.
    // NOTE: This must be done *AFTER* selecting the annotation, in case the tool manager's tool
    // adds any opqaue views to the PTPDFViewCtrl's toolOverlayView. Otherwise, the flashing will
    // not be visible.
    [pdfViewCtrl flashAnnotation:annot onPageNumber:pageNumber];
}

#pragma mark - Collaboration manager

- (void)setCollaborationManager:(PTBaseCollaborationManager *)collaborationManager
{
    _collaborationManager = collaborationManager;
    
    if (self.dataSource) {
        self.dataSource.annotationManager = collaborationManager.annotationManager;
    }
}

#pragma mark - Sort mode

- (void)setSortMode:(PTCollaborationAnnotationSortMode)sortMode
{
    if (_sortMode == sortMode) {
        // No change.
        return;
    }
    
    _sortMode = sortMode;
    
    
    self.dataSource.sortMode = sortMode;
    [self.tableView reloadData];
    
    [self updateSortModeTitle];
}

- (NSString *)titleForSortMode:(PTCollaborationAnnotationSortMode)sortMode
{
    switch (sortMode) {
        case PTCollaborationAnnotationSortModePageNumber:
            return PTLocalizedString(@"Page Number", @"Sort by page number");
        case PTCollaborationAnnotationSortModeCreationDate:
            return PTLocalizedString(@"Creation Date", @"Sort by (annotation) creation date");
        case PTCollaborationAnnotationSortModeLastReplyDate:
            return PTLocalizedString(@"Last Reply Date", @"Sort by last reply date");
    }
}

- (void)updateSortModeTitle
{
    // Update the title of the sort mode button for the current sort mode.
    NSString *sortModeTitle = [self titleForSortMode:self.sortMode];
    
    NSString *buttonTitleFormat = PTLocalizedString(@"Sorted by %@", @"Sorted by <sort-mode>");
    NSString *buttonTitle = [NSString localizedStringWithFormat:buttonTitleFormat, sortModeTitle];
    
    // Prevent fade out/in animation when changing button title.
    [UIView performWithoutAnimation:^{
        [self.headerView.sortButton setTitle:buttonTitle forState:UIControlStateNormal];
        [self.headerView.sortButton layoutIfNeeded];
    }];
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PTManagedAnnotation *annotation = [self.dataSource objectAtIndexPath:indexPath];
    const int pageNumber = annotation.pageNumber;
    
    // Only dismiss view controller when "fullscreen" (fills entire window width).
    BOOL dismiss = (CGRectGetWidth(self.view.frame) == CGRectGetWidth(self.view.window.bounds));
    
    if (dismiss) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self selectAnnotation:annotation pageNumber:pageNumber];
        }];
    } else {
        [self selectAnnotation:annotation pageNumber:pageNumber];
    }
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (!self.tableView.tableHeaderView) {
        return;
    }
    
    CGPoint contentOffset = *targetContentOffset;
    if (@available(iOS 11.0, *)) {
        contentOffset.y += self.tableView.safeAreaInsets.top;
    }
    
    CGRect frame = self.tableView.tableHeaderView.frame;
    CGFloat adjustment = 0.0;
    
    if (contentOffset.y < CGRectGetMaxY(frame)) {
        CGFloat center = CGRectGetMinY(frame) + (CGRectGetHeight(frame) / 2);
        // A portion of the table header view will be visible.
        // Show entire header view if more than half of it would be visible.
        if (contentOffset.y < center) {
            // Show entire table header view.
            adjustment = 0 - contentOffset.y;
        } else {
            // Hide table header view.
            adjustment = CGRectGetHeight(frame) - contentOffset.y;
        }
    }
    
    // Adjust target content offset.
    if (adjustment != 0.0) {
        targetContentOffset->y += adjustment;
    }
}

#pragma mark - <PTAnnotationTableDataSourceDelegate>
- (void)collaborationAnnotationDataSource:(PTCollaborationAnnotationDataSource *)dataSource configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath withAnnotation:(PTManagedAnnotation *)annotation
{
    PTCollaborationAnnotationViewCell *annotationViewCell = (PTCollaborationAnnotationViewCell *)cell;
    [annotationViewCell configureWithAnnotation:annotation];
    
    annotationViewCell.contentInsets = self.tableView.separatorInset;
}

- (void)collaborationAnnotationDataSourceDidChangeContent:(PTCollaborationAnnotationDataSource *)dataSource
{
    [self updateEmptyIndicatorHidden];
}

#pragma mark - <PTTableHeaderViewDelegate>

- (void)tableHeaderViewShowSort:(PTTableHeaderView *)tableHeaderView
{
    // Alert controller for sort mode selection.
    NSString *alertTitle = PTLocalizedString(@"Sort by:", @"Sort selection title");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Add actions for each sort mode.
    const PTCollaborationAnnotationSortMode sortModes[] = {
        PTCollaborationAnnotationSortModePageNumber,
        PTCollaborationAnnotationSortModeCreationDate,
        PTCollaborationAnnotationSortModeLastReplyDate,
    };
    const size_t sortModeCount = PT_C_ARRAY_SIZE(sortModes);
    for (size_t i = 0; i < sortModeCount; i++) {
        PTCollaborationAnnotationSortMode sortMode = sortModes[i];

        NSString *title = [self titleForSortMode:sortMode];
        [alertController addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.sortMode = sortMode;
        }]];
    }
    
    // Cancel.
    NSString *cancelTitle = PTLocalizedString(@"Cancel", @"Cancel sort mode selection");
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    
    CGRect bounds = tableHeaderView.bounds;
    alertController.popoverPresentationController.sourceView = tableHeaderView;
    alertController.popoverPresentationController.sourceRect = CGRectMake(PTCGRectGetCenter(bounds).x,
                                                                          0,
                                                                          0,
                                                                          CGRectGetHeight(bounds));
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
