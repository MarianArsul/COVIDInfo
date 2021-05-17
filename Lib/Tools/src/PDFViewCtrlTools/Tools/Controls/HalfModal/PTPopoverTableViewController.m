//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPopoverTableViewController.h"

#import "PTTableView.h"

@interface PTPopoverTableViewController ()
{
    BOOL _needsLoadViewConstraints;
}

@property (nonatomic, assign) BOOL needsInitialReload;

@end

@implementation PTPopoverTableViewController

// Default init calls this method.
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithStyle:UITableViewStylePlain];
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        PTTableView *tableView = [[PTTableView alloc] initWithFrame:CGRectZero
                                                                    style:style];
        tableView.dataSource = self;
        tableView.delegate = self;
                
        tableView.intrinsicContentSizeEnabled = YES;
        
        _tableView = tableView;
        
        _needsInitialReload = YES;
        _clearsSelectionOnViewWillAppear = YES;
        
        _needsLoadViewConstraints = YES;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight);
    
    [self.view addSubview:self.tableView];
    
    [self.view setNeedsUpdateConstraints];
}

- (void)loadViewConstraints
{
    guard (self.tableView) else {
        return;
    }
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
       [self.tableView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [self.tableView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
       [self.tableView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
       [self.tableView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor],
    ]];
}

- (void)updateViewConstraints
{
    if (_needsLoadViewConstraints) {
        _needsLoadViewConstraints = NO;
        
        [self loadViewConstraints];
    }
    // Call super implementation as final step.
    [super updateViewConstraints];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self tableViewUpdatePreferredContentSize];
}

- (void)tableViewUpdatePreferredContentSize
{
    CGSize preferredContentSize = CGSizeZero;
    
    if ([self.tableView isKindOfClass:[PTTableView class]]) {
        PTTableView *tableView = (PTTableView *)self.tableView;
        if ([tableView isIntrinsicContentSizeEnabled]) {
            preferredContentSize = tableView.intrinsicContentSize;
        }
    }
    
    if (CGSizeEqualToSize(preferredContentSize, CGSizeZero)) {
        const CGSize contentSize = self.tableView.contentSize;
        const UIEdgeInsets contentInset = self.tableView.contentInset;
        // NOTE: DON'T add the adjustedContentInset, since that will be added by the navigationController.
        
        const CGFloat contentInsetHorizontal = contentInset.left + contentInset.right;
        const CGFloat contentInsetVertical = contentInset.top + contentInset.bottom;
        
        preferredContentSize = CGSizeMake(contentSize.width + contentInsetHorizontal,
                                          contentSize.height + contentInsetVertical);
    }
    
    if (!CGSizeEqualToSize(preferredContentSize, self.preferredContentSize)) {
        self.preferredContentSize = preferredContentSize;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.needsInitialReload) {
        [self.tableView reloadData];
        
        self.needsInitialReload = NO;
    } else if (self.clearsSelectionOnViewWillAppear) {
        [self clearSelectionOnViewWillAppear:animated];
    }
}

- (void)clearSelectionOnViewWillAppear:(BOOL)animated
{
    // Deselect the selected row on viewWillAppear.
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath != nil) {
        // Check if there is a transition coordinator.
        id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
        if (coordinator != nil) {
            // Deselect the selected row in an alongside-animation for the transition.
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
            } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                if (context.cancelled) {
                    // Reselect the row for a cancelled transition.
                    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }];
        } else {
            // Directly deselect the selected row.
            [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView flashScrollIndicators];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:editing animated:animated];
}

#pragma mark - Property accessor overrides

- (void)setTableView:(UITableView *)tableView
{
    UITableView *previousTableView = _tableView;
    
    // Null-resettable.
    if (!tableView) {
        // Create a custom table view.
        PTTableView *customTableView = [[PTTableView alloc] initWithFrame:self.view.frame
                                                                    style:UITableViewStylePlain];
        customTableView.dataSource = self;
        customTableView.delegate = self;
                
        customTableView.intrinsicContentSizeEnabled = YES;
        
        tableView = customTableView;
    }
    
    _tableView = tableView;
    
    // Add new table view to view, above the old table view.
    // (Ensures that the z-order of the table view does not change)
    [self.view insertSubview:tableView
                aboveSubview:previousTableView];
    
    // Remove old table view from view.
    [previousTableView removeFromSuperview];
    
    // Schedule loadViewConstraints.
    _needsLoadViewConstraints = YES;
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:@"" forIndexPath:indexPath];
}

@end
