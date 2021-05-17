//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolGroupDefaultsViewController.h"

#import "PTToolGroupDefaultsTableViewCell.h"
#import "PTFilterableDataSource.h"
#import "PTLabelHeaderFooterView.h"
#import "PTTool.h"
#import "PTToolBarButtonItem.h"
#import "PTToolsUtil.h"

#import "CGGeometry+PTAdditions.h"
#import "NSArray+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"
#import "NSObject+PTAdditions.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "UIFont+PTAdditions.h"
#import "UIGeometry+PTAdditions.h"

#define PT_CellIdentifier @"cell"
#define PT_FooterLabelIdentifier @"footerLabel"

NS_ASSUME_NONNULL_BEGIN

@interface PTToolGroupDefaultsViewController ()

@property (nonatomic, strong) PTFilterableDataSource *dataSource;

@end

NS_ASSUME_NONNULL_END

@implementation PTToolGroupDefaultsViewController

- (instancetype)init
{
    UITableViewStyle style = UITableViewStyleGrouped;
    if (@available(iOS 13.0, *)) {
        style = UITableViewStyleInsetGrouped;
    }
    return [super initWithStyle:style];
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 58;
    
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = UITableViewAutomaticDimension;
    
    [self.tableView registerClass:[PTToolGroupDefaultsTableViewCell class]
           forCellReuseIdentifier:PT_CellIdentifier];
    [self.tableView registerClass:[PTLabelHeaderFooterView class] forHeaderFooterViewReuseIdentifier:PT_FooterLabelIdentifier];
    
    self.tableView.editing = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self beginObservingToolManager:self.toolGroupManager.toolManager];
    
    [self.dataSource filterItems];
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self endObservingToolManager:self.toolGroupManager.toolManager];
}

- (void)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Annotation mode manager

- (void)setToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    PTToolGroupManager *previousToolGroupManager = _toolGroupManager;
    _toolGroupManager = toolGroupManager;
    
    if (self.viewIfLoaded.window) {
        [self endObservingToolManager:previousToolGroupManager.toolManager];
        [self beginObservingToolManager:toolGroupManager.toolManager];
    }
    
    [self.dataSource filterItems];
    [self.tableView reloadData];
}

- (void)beginObservingToolManager:(PTToolManager *)toolManager
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(toolManagerAnnotationOptionsDidChange:)
                   name:PTToolManagerAnnotationOptionsDidChangeNotification
                 object:toolManager];
}

- (void)endObservingToolManager:(PTToolManager *)toolManager
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center removeObserver:self
                      name:PTToolManagerAnnotationOptionsDidChangeNotification
                    object:toolManager];
}

#pragma mark Notifications

- (void)toolManagerAnnotationOptionsDidChange:(NSNotification *)notification
{
    if (notification.object != self.toolGroupManager.toolManager) {
        return;
    }
    
    [self.dataSource filterItems];
    [self.tableView reloadData];
}

- (void)setItemGroups:(NSArray<PTToolGroup *> *)itemGroups
{
    _itemGroups = [itemGroups copy]; // @property (copy) semantics.
    
    // Update data source - create NSArray<NSArray<UIBarButtonItem>>
    self.dataSource.items = [_itemGroups pt_mapObjectsWithBlock:^id(PTToolGroup *group, NSUInteger index, BOOL *stop) {
        return group.barButtonItems;
    }];
    
    [self.tableView reloadData];
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath update:(BOOL)update
{
    // Update data source.
    [self.dataSource removeItemAtFilteredIndexPath:indexPath];
    
    PTToolGroup *sourceGroup = self.itemGroups[indexPath.section];
    sourceGroup.barButtonItems = [self.dataSource.items[indexPath.section] copy];
    
    if (update) {
        [self.tableView beginUpdates];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
}

- (void)moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath update:(BOOL)update
{
    // Get the cell before performing the move operation.
    PTToolGroupDefaultsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
    
    // Update data source.
    [self.dataSource moveItemAtFilteredIndexPath:sourceIndexPath
                             toFilteredIndexPath:destinationIndexPath];
    
    PTToolGroup *sourceGroup = self.itemGroups[sourceIndexPath.section];
    sourceGroup.barButtonItems = [self.dataSource.items[sourceIndexPath.section] copy];
    
    if (sourceIndexPath.section != destinationIndexPath.section) {
        PTToolGroup *destinationGroup = self.itemGroups[destinationIndexPath.section];
        destinationGroup.barButtonItems = [self.dataSource.items[destinationIndexPath.section] copy];
    }
    
    if (update) {
        [self.tableView beginUpdates];
        
        [self.tableView moveRowAtIndexPath:sourceIndexPath
                               toIndexPath:destinationIndexPath];
        
        [self.tableView endUpdates];
    }
    
//    if (sourceIndexPath.section != destinationIndexPath.section) {
//        // Update the table view cell(s) with the updated data.
//        // Required when moving items between sections or when the cell's appearance needs to be updated.
//        [tableView reloadData];
//    }
    
    [self configureCell:cell forIndexPath:destinationIndexPath];
}

- (void)copyItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath update:(BOOL)update
{
    // Get the cell before performing the move operation.
    PTToolGroupDefaultsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
    
    // Update data source.
    UIBarButtonItem *item = self.dataSource.filteredItems[sourceIndexPath.section][sourceIndexPath.row];
    
    // Create a copy of the item if possible.
    if ([item conformsToProtocol:@protocol(NSCopying)]) {
        item = [item copy];
        
        if ([item isKindOfClass:[PTToolBarButtonItem class]]) {
            PTToolBarButtonItem *toolItem = (PTToolBarButtonItem *)item;
            
            // Give the item a unique identifier string to differentiate it
            // from other tool items with the same tool class.
            toolItem.identifier = [NSUUID UUID].UUIDString;
        }
    }
    
    [self.dataSource insertItem:item atFilteredIndexPath:destinationIndexPath];
    
    if (sourceIndexPath.section != destinationIndexPath.section) {
        PTToolGroup *destinationGroup = self.itemGroups[destinationIndexPath.section];
        destinationGroup.barButtonItems = [self.dataSource.items[destinationIndexPath.section] copy];
    }
    
    if (update) {
        [self.tableView beginUpdates];
        
        [self.tableView insertRowsAtIndexPaths:@[destinationIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
    
    //    if (sourceIndexPath.section != destinationIndexPath.section) {
    //        // Update the table view cell(s) with the updated data.
    //        // Required when moving items between sections or when the cell's appearance needs to be updated.
    //        [tableView reloadData];
    //    }
        
    [self configureCell:cell forIndexPath:destinationIndexPath];
}

#pragma mark - Icon tint color

- (void)setIconTintColor:(UIColor *)iconTintColor
{
    _iconTintColor = iconTintColor;
    
    if (self.tableView.window) {
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:[PTToolGroupDefaultsTableViewCell class]]) {
                ((PTToolGroupDefaultsTableViewCell *)cell).tintColor = iconTintColor;
            }
        }
    }
}

- (PTFilterableDataSource *)dataSource
{
    if (!_dataSource) {
        _dataSource = [[PTFilterableDataSource alloc] init];
        
        __weak __typeof__(self) weakSelf = self;
        _dataSource.predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary<NSString *, id> *bindings) {
            __strong __typeof__(self) self = weakSelf;
            if (!self.toolGroupManager.toolManager) {
                return YES;
            }
            if ([object isKindOfClass:[PTToolBarButtonItem class]]) {
                PTToolBarButtonItem *item = (PTToolBarButtonItem *)object;
                
                const Class toolClass = item.toolClass;
                if ([toolClass isSubclassOfClass:[PTTool class]]
                    && [toolClass createsAnnotation]) {
                    const PTExtendedAnnotType annotType = [toolClass annotType];
                    if (![self.toolGroupManager.toolManager canCreateExtendedAnnotType:annotType]) {
                        return NO;
                    }
                }
            }
            return YES;
        }];
    }
    return _dataSource;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.filteredItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.filteredItems[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PTToolGroupDefaultsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PT_CellIdentifier forIndexPath:indexPath];
    
//    [cell.switchView addTarget:self
//                        action:@selector(cellSwitchValueChanged:)
//              forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[PTToolGroupDefaultsTableViewCell class]]) {
        [self configureCell:(PTToolGroupDefaultsTableViewCell *)cell
               forIndexPath:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PTLocalizedString(@"Remove",
                             @"Remove row item title");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 0) && (editingStyle == UITableViewCellEditingStyleDelete)) {
        [self removeItemAtIndexPath:indexPath update:YES];
    }
    else if ((indexPath.section > 0) && (editingStyle == UITableViewCellEditingStyleInsert)) {
        NSIndexPath *sourceIndexPath = indexPath;
        NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0]
                                                               inSection:0];
        
        [self copyItemAtIndexPath:sourceIndexPath
                      toIndexPath:destinationIndexPath
                           update:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
            // Move to last row in the source section.
            const NSInteger rowCount = [self.tableView numberOfRowsInSection:sourceIndexPath.section];
            
            return [NSIndexPath indexPathForRow:rowCount - 1
                                      inSection:sourceIndexPath.section];
        } else {
            // Move to first row in the source section.
            return [NSIndexPath indexPathForRow:0
                                      inSection:sourceIndexPath.section];
        }
    }
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self moveItemAtIndexPath:sourceIndexPath
                  toIndexPath:destinationIndexPath
                       update:NO];
}

#pragma mark - <UITableViewDelegate>

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PTToolGroup *group = self.itemGroups[indexPath.section];
    
    switch (indexPath.section) {
        case 0:
        {
            // Deletion only allowed for favorite groups.
            if ([group isFavorite]) {
                return UITableViewCellEditingStyleDelete;
            } else {
                return UITableViewCellEditingStyleNone;
            }
        }
            break;
        default:
            return UITableViewCellEditingStyleInsert;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Don't indent rows while in editing mode (the only mode).
    return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView.numberOfSections <= 1) {
        return nil;
    }
    
    PTToolGroup *group = self.itemGroups[section];
    if (group.title.length == 0) {
        return nil;
    }
    
    
    UIView *view = [[UIView alloc] init];
    
    view.layoutMargins = PTUIEdgeInsetsMakeUniform(8);
    
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont pt_boldPreferredFontForTextStyle:UIFontTextStyleTitle3];
    [view addSubview:label];
    
    // Section title.
    label.text = group.title;
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutMarginsGuide = view.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor],
        [label.topAnchor constraintGreaterThanOrEqualToAnchor:layoutMarginsGuide.topAnchor],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.trailingAnchor],
        [label.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
        
        [view.heightAnchor constraintEqualToConstant:58], // From _UIActivityUserDefaultsViewController
    ]];
    [NSLayoutConstraint pt_activateConstraints:@[
        [label.widthAnchor constraintEqualToConstant:0],
        [label.heightAnchor constraintEqualToConstant:0],
    ] withPriority:UILayoutPriorityFittingSizeLevel];
    
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    PTLabelHeaderFooterView *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:PT_FooterLabelIdentifier];
    
    [self configureFooter:footer inSection:section];
    
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Hide section footers.
    if (tableView.numberOfSections <= 1) {
        return 0.0;
    }
    
    NSString *sectionTitle = [self titleForFooterInSection:section];
    if (sectionTitle.length > 0) {
        // Use section footer's intrinsic height.
        return UITableViewAutomaticDimension;
    } else {
        // Hide the section footer.
        // NOTE: This removes the section footer view for the given section.
        return 0.0;
    }
}

#pragma mark - Configuration

- (void)configureCell:(PTToolGroupDefaultsTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    UIBarButtonItem *item = self.dataSource.filteredItems[indexPath.section][indexPath.row];
    
    [cell configureWithItem:item];
    
    BOOL switchHidden = YES;
    cell.switchView.hidden = switchHidden;
    cell.separatorHidden = switchHidden;
    
    cell.itemImageView.tintColor = self.iconTintColor;
}

- (void)configureFooter:(PTLabelHeaderFooterView *)footer inSection:(NSInteger)section
{
    NSString *sectionTitle = [self titleForFooterInSection:section];
    
    footer.label.text = sectionTitle;
    
    NSString *sectionDescription = nil;
    if (self.itemGroups.count > 0) {
        sectionDescription = PTLocalizedString(@"Add tools to this group",
                                               @"Empty tool group description");
    }
    footer.detailLabel.text = sectionDescription;
    
    footer.detailLabel.numberOfLines = 0;
}

- (nullable NSString *)titleForFooterInSection:(NSInteger)section
{
    PTToolGroup *group = self.itemGroups[section];
    
    if (group.barButtonItems.count == 0) {
        return PTLocalizedString(@"No items",
                                 @"No items placeholder");
    }
    
    return nil;
}

#pragma mark - Control actions

//- (void)cellSwitchValueChanged:(UISwitch *)sender
//{
//    BOOL isOn = [sender isOn];
//
//    CGPoint point = [self.tableView convertPoint:PTCGRectGetCenter(sender.bounds)
//                                        fromView:sender];
//    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
//    if (!indexPath) {
//        return;
//    }
//    UIBarButtonItem *item = [self itemsForSection:indexPath.section][indexPath.row];
//    if (item) {
//        item.pt_hidden = !isOn;
//
//        [self saveItemsToUserDefaults];
//    }
//}

@end
