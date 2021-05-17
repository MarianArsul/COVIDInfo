//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolsUtil.h"

#import "PTMoreItemsViewController.h"

/**
 * The PTMoreItemsViewController class displays controls allowing the user
 * to perform additional actions.
 */
@interface PTMoreItemsViewController ()

@property (nonatomic, strong) PTToolManager *toolManager;

@property (nonatomic, strong) NSIndexPath* undoIndexPath;
@property (nonatomic, strong) NSIndexPath* redoIndexPath;

@property (nonatomic, assign) BOOL needsTintAdjustmentModeUpdate;

@end

@implementation PTMoreItemsViewController

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    UITableViewStyle tableViewStyle;
    if( @available(iOS 13, *) )
    {
        tableViewStyle = UITableViewStyleInsetGrouped;
    }
    else
    {
        tableViewStyle = UITableViewStyleGrouped;
    }
        
    self = [super initWithStyle:tableViewStyle];
    if (self) {
        
        _toolManager = toolManager;
        _undoIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
        _redoIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
        

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self updateButtonsForUndoManagerState];
    [self subscribeToUndoManagerNotifications];
    [self startObservingContentSize];
    // so items that need to be disabled are disabled.
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unsubscribeFromUndoManagerNotifications];
    [self stopObservingContentSize];
}

- (void)undo:(UIButton*)sender
{
    [self.toolManager.undoManager undo];
}

- (void)redo:(UIButton*)sender
{
    [self.toolManager.undoManager redo];
}

-(void)updateButtonForUndoManagerState:(NSIndexPath*)buttonIndex
{
    
    NSAssert([buttonIndex isEqual:self.undoIndexPath] || [buttonIndex isEqual:self.redoIndexPath], @"Bad button index");
    
    BOOL canDo;
    
    if( [buttonIndex isEqual:self.undoIndexPath] )
    {
        canDo = self.toolManager.undoManager.canUndo;
    }
    else if( [buttonIndex isEqual:self.redoIndexPath] )
    {
        canDo = self.toolManager.undoManager.canRedo;
    }
    else
    {
        return;
    }
    
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:buttonIndex];
    
    cell.userInteractionEnabled = canDo;
    cell.textLabel.enabled = canDo;
    cell.detailTextLabel.enabled = canDo;
    // cell.accessoryView.alpha = canDo ? 1.0 : 0.20; Does not work reliably for unknown reasons.
    if( canDo )
    {
        cell.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    }
    else
    {
        cell.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    }
}


- (void)updateButtonsForUndoManagerState
{
    
    [self updateButtonForUndoManagerState:self.undoIndexPath];
    [self updateButtonForUndoManagerState:self.redoIndexPath];

}

#pragma mark - NSUndoManager notifications

-(void)subscribeToUndoManagerNotifications
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                                               name:NSUndoManagerDidCloseUndoGroupNotification
                                             object:self.toolManager.undoManager];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                                               name:NSUndoManagerDidUndoChangeNotification
                                             object:self.toolManager.undoManager];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                                               name:NSUndoManagerDidRedoChangeNotification
                                             object:self.toolManager.undoManager];
}

-(void)unsubscribeFromUndoManagerNotifications
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSUndoManagerDidCloseUndoGroupNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSUndoManagerDidUndoChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSUndoManagerDidRedoChangeNotification object:nil];
}

- (void)undoManagerStateDidChangeWithNotification:(NSNotification *)notification
{
    NSUndoManager *undoManager = (NSUndoManager *)notification.object;
    if (undoManager != self.toolManager.undoManager) {
        return;
    }
    
    [self updateButtonsForUndoManagerState];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 )
        return self.items.count;
    else
        return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    // From the items array (Share, etc?)
    if (indexPath.section == 0)
    {
        cell.textLabel.text = self.items[indexPath.row].title;
        cell.accessoryView = [[UIImageView alloc] initWithImage:self.items[indexPath.row].image];
        BOOL enabled = self.items[indexPath.row].enabled;

        cell.userInteractionEnabled = enabled;
        cell.textLabel.enabled = enabled;
        cell.detailTextLabel.enabled = enabled;
        cell.tintAdjustmentMode = enabled ? UIViewTintAdjustmentModeAutomatic : UIViewTintAdjustmentModeDimmed;
        
    }
    // undo
    else if( [indexPath isEqual:self.undoIndexPath] )
    {
        cell.textLabel.text = PTLocalizedString(@"Undo",@"Undo");

        UIImage *image;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"arrow.uturn.left" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        } else {
            image = [PTToolsUtil toolImageNamed:@"ic_undo_black_24dp"];
        }

        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
        
        [self updateButtonForUndoManagerState:indexPath];

    }
    // redo
    else if( [indexPath isEqual:self.redoIndexPath] )
    {
        cell.textLabel.text = PTLocalizedString(@"Redo",@"Redo");
        
        UIImage *image;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"arrow.uturn.right" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        } else {
            image = [PTToolsUtil toolImageNamed:@"ic_redo_black_24dp"];
        }
        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
        
        [self updateButtonForUndoManagerState:indexPath];
        
    }

    
    return cell;
}

-(void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

#pragma tableview delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UIBarButtonItem* item = self.items[indexPath.row];
        [UIApplication.sharedApplication sendAction:item.action to:item.target from:self.popoverPresentationController.barButtonItem forEvent:nil];
    }
    if( indexPath.section == 1)
    {
        if( indexPath.row == 0 )
        {
            [self undo:Nil];
        }
        else if( indexPath.row == 1)
        {
            [self redo:Nil];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - Table view content size observer

- (void)startObservingContentSize
{
    [self.tableView addObserver:self
           forKeyPath:@"contentSize"
              options:NSKeyValueObservingOptionNew
              context:nil];
}

- (void)stopObservingContentSize
{
    [self.tableView removeObserver:self
              forKeyPath:@"contentSize"
                 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    self.preferredContentSize = self.tableView.contentSize;
    self.navigationController.preferredContentSize = self.tableView.contentSize;
}

@end
