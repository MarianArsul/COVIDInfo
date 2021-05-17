//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolGroupViewController.h"

#import "PTToolGroupDefaultsViewController.h"
#import "PTFreeTextCreate.h" // For commitAnnotation selector.
#import "PTPanTool.h"
#import "PTToolsUtil.h"

#import "UIBarButtonItem+PTAdditions.h"
#import "UIViewController+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTToolGroupViewController ()

@end

NS_ASSUME_NONNULL_END

@implementation PTToolGroupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"cell"];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    
    self.tableView.alwaysBounceHorizontal = NO;
    self.tableView.alwaysBounceVertical = NO;
    
    self.tableView.tableFooterView = [[UIView alloc] init];
        
    [self updateTitle];
}

- (void)updateTitle
{
    if ([self isEditing]) {
        self.title = PTLocalizedString(@"Edit Annotation Modes",
                                       @"Edit Annotation Modes control title");
    } else {
        self.title = PTLocalizedString(@"Annotation Modes",
                                       @"Annotation Modes control title");
    }
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self tableViewUpdatePreferredContentSize];
}

- (void)tableViewUpdatePreferredContentSize
{
    CGSize contentSize = self.tableView.contentSize;
    UIEdgeInsets contentInset = self.tableView.contentInset;
    // NOTE: DON'T add the adjustedContentInset, since that will be added by the navigationController.
    
    CGSize preferredContentSize = CGSizeMake(contentSize.width + contentInset.left + contentInset.right,
                                             contentSize.height + contentInset.top + contentInset.bottom);
    
    if (!CGSizeEqualToSize(preferredContentSize, self.preferredContentSize)) {
        self.preferredContentSize = preferredContentSize;
    }
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.parentViewController == self.navigationController &&
        self.navigationController.viewControllers.firstObject == self) {
        self.navigationController.navigationBarHidden = [self pt_isInPopover];
    }
    
    // Update the view controller's preferred content size from its compressed layout
    // size, each time it will appear.
    // This fixes an issue where the size of a popover containing this view controller
    // inside a navigation controller has an incorrect height for subsequent
    // presentations.
    // https://noahgilmore.com/blog/popover-uinavigationcontroller-preferredcontentsize
    self.preferredContentSize = [self.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (self.parentViewController == self.navigationController &&
        self.navigationController.viewControllers.firstObject == self) {
        self.navigationController.navigationBarHidden = [self pt_isInPopover];
    }
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [self updateTitle];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.toolGroupManager.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSMutableArray<PTToolGroup *> *groups = [self.toolGroupManager.groups mutableCopy];
    
    PTToolGroup *itemGroup = groups[sourceIndexPath.row];
    [groups removeObjectAtIndex:sourceIndexPath.row];
    [groups insertObject:itemGroup atIndex:destinationIndexPath.row];
    
    self.toolGroupManager.groups = [groups copy];
}

#pragma mark - <UITableViewDelegate>

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PTToolGroup *selectedGroup = self.toolGroupManager.groups[indexPath.row];
    
    if (![self isEditing]) {
        self.toolGroupManager.selectedGroup = selectedGroup;
        
        PTToolManager *toolManager = self.toolGroupManager.toolManager;
        
        
        if ([toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
            [toolManager.tool performSelector:@selector(commitAnnotation)];
        }
        
        [toolManager changeTool:[PTPanTool class]];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if ([selectedGroup isEditable]) {
        PTToolGroupDefaultsViewController *controller = [[PTToolGroupDefaultsViewController alloc] init];
        
        NSString *localizedFormat = PTLocalizedString(@"Edit %@",
                                                      @"Edit tool group");
        controller.title = [NSString localizedStringWithFormat:localizedFormat,
                            selectedGroup.title];
        
        NSMutableArray<PTToolGroup *> *itemGroups = [NSMutableArray array];
        
        // Group to be edited is the first object.
        [itemGroups addObject:selectedGroup];
        
        if ([selectedGroup isFavorite]) {
            for (PTToolGroup *group in self.toolGroupManager.groups) {
                if (group == selectedGroup
                    || group.barButtonItems.count == 0
                    || group == self.toolGroupManager.pensItemGroup) {
                    continue;
                }
                [itemGroups addObject:group];
            }
        }
        
        controller.itemGroups = [itemGroups copy];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        
        [self presentViewController:nav animated:YES completion:nil];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Configuration

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PTToolGroup *group = self.toolGroupManager.groups[indexPath.row];
    
    cell.imageView.image = [group.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.adjustsImageSizeForAccessibilityContentSizeCategory = YES;
    
    cell.textLabel.text = group.title;
    
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    if (group == self.toolGroupManager.selectedGroup) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if ([group isEditable]) {
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.showsReorderControl = YES;
}

#pragma mark - Toolbar manager

- (void)setToolGroupManager:(PTToolGroupManager *)toolGroupManager
{
    _toolGroupManager = toolGroupManager;
    
    [self.tableView reloadData];
}

@end
