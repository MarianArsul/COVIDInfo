//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentTabTableViewController.h"

#import "PTToolsUtil.h"
#import "PTKeyValueObserving.h"

#import "UIBarButtonItem+PTAdditions.h"
#import "UIViewController+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentTabTableViewController ()

@property (nonatomic, assign, getter=isObservingTabManager) BOOL observingTabManager;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentTabTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = PTLocalizedString(@"Document Tabs",
                                   @"Document tabs list title");
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self updateDoneButton:NO];
    
    self.toolbarItems = @[
        self.closeAllTabsButtonItem,
        [UIBarButtonItem pt_flexibleSpaceItem],
        self.editButtonItem,
    ];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [self updateDoneButton:animated];
}

#pragma mark - View appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateDoneButton:animated];
    
    self.navigationController.toolbarHidden = NO;
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self beginObservingTabManager:self.tabManager];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self endObservingTabManager:self.tabManager];
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateDoneButton:NO];
}

#pragma mark - Done button

- (UIBarButtonItem *)doneButtonItem
{
    if (!_doneButtonItem) {
        _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss:)];
    }
    return _doneButtonItem;
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark - Close all tabs

- (UIBarButtonItem *)closeAllTabsButtonItem
{
    if (!_closeAllTabsButtonItem) {
        NSString *title = PTLocalizedString(@"Close All",
                                            @"Close All tabs button title");
        _closeAllTabsButtonItem = [[UIBarButtonItem alloc] initWithTitle:title  style:UIBarButtonItemStylePlain target:self action:@selector(closeAllTabs:)];
    }
    return _closeAllTabsButtonItem;
}

- (void)closeAllTabs:(id)sender
{
    NSArray<PTDocumentTabItem *> *items = [self.tabManager.items copy];
    
    // Close all tabs except the selected tab, which is displaying a view controller.
    for (PTDocumentTabItem *item in items) {
        if (item != self.tabManager.selectedItem) {
            [self.tabManager removeItem:item];
        }
    }
    // Close the selected tab last.
    if (self.tabManager.selectedItem) {
        [self.tabManager removeItem:self.tabManager.selectedItem];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tabManager.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"
                                                            forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (self.tabManager != nil);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self.tabManager moveItemAtIndex:sourceIndexPath.row
                             toIndex:destinationIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
        {
            [self.tabManager removeItemAtIndex:indexPath.row];
        }
            break;
        default:
            break;
    }
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Notify delegate of selection.
    if ([self.delegate respondsToSelector:@selector(documentTabViewController:didSelectTabAtIndex:)]) {
        [self.delegate documentTabViewController:self didSelectTabAtIndex:indexPath.row];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PTLocalizedString(@"Close", @"Close document tab title");
}

#pragma mark - Cell configuration

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PTDocumentTabItem *tab = self.tabManager.items[indexPath.row];
    
    if (tab.displayName) {
        cell.textLabel.text = tab.displayName;
    } else {
        cell.textLabel.text = (tab.documentURL ?: tab.sourceURL).lastPathComponent;
    }
    
    cell.showsReorderControl = YES;

    if (indexPath.row == self.tabManager.selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - Tab manager

- (void)setTabManager:(PTDocumentTabManager *)tabManager
{
    if (_tabManager == tabManager) {
        // No change.
        return;
    }
    
    const BOOL isObserving = [self isObservingTabManager];
    
    PTDocumentTabManager *previousTabManager = _tabManager;
    
    if (isObserving) {
        [self endObservingTabManager:previousTabManager];
    }
    
    _tabManager = tabManager;
    
    if (isObserving) {
        [self beginObservingTabManager:tabManager];
    }
    
    if (![self isBeingDismissed]) {
        [self.tableView reloadData];
    }
}

#pragma mark Observation

- (void)beginObservingTabManager:(PTDocumentTabManager *)tabManager
{
    [self pt_observeObject:tabManager
                forKeyPath:PT_CLASS_KEY(PTDocumentTabManager, items)
                  selector:@selector(tabManagerTabsDidChange:)];
    
    self.observingTabManager = YES;
}

- (void)endObservingTabManager:(PTDocumentTabManager *)tabManager
{
    [self pt_removeObservationsForObject:tabManager
                                 keyPath:PT_CLASS_KEY(PTDocumentTabManager, items)];
    
    self.observingTabManager = NO;
}

- (void)tabManagerTabsDidChange:(PTKeyValueObservedChange *)change
{
    if (self.tabManager != change.object) {
        return;
    }
    
    NSArray<NSIndexPath *> *changedIndexPaths = [self indexPathsForIndexes:change.indexes
                                                                   section:0];
    
    switch (change.kind) {
        case NSKeyValueChangeSetting:
        {
            [self.tableView reloadData];
        }
            break;
        case NSKeyValueChangeInsertion:
        {
            if ([self.tabManager isMoving]) {
                break;
            }
            
            [self.tableView insertRowsAtIndexPaths:changedIndexPaths
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
        case NSKeyValueChangeReplacement:
        {
            [self.tableView reloadRowsAtIndexPaths:changedIndexPaths
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
        case NSKeyValueChangeRemoval:
        {
            if ([self.tabManager isMoving]) {
                break;
            }
            
            [self.tableView deleteRowsAtIndexPaths:changedIndexPaths
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
    }
}

- (NSArray<NSIndexPath *> *)indexPathsForIndexes:(NSIndexSet *)indexes section:(NSInteger)section
{
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:section]];
    }];
    
    return [indexPaths copy];
}

@end
