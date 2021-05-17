//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTChoiceFormViewController.h"

static NSString * const PTChoiceFormViewController_CellIdentifier = @"CellIdentifier";

@interface PTChoiceFormViewController()

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation PTChoiceFormViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isMultiSelect = NO;
    }
    return self;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.delegate choiceFormNumberOfChoices:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PTChoiceFormViewController_CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [self.delegate choiceForm:self titleOfChoiceAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSMutableArray<NSNumber *> *items = [self.delegate choiceFromGetSelectedItemsInActiveListbox:self];
    for (NSNumber *number in items) {
        if (number.intValue != indexPath.row) {
            continue;
        }
        
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    }

    return cell;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    self.tableView.dataSource = self;
    self.tableView.delegate = self.delegate;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:PTChoiceFormViewController_CellIdentifier];
    
    [self.view addSubview:self.tableView];
    
    if (@available(iOS 11, *)) {
        // Fill superview (view controller root view).
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    } else {
        PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
        // Set up constraints.
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:
         @[
           [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
           [self.tableView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
           [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor],
           [self.tableView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
           ]];
        PT_IGNORE_WARNINGS_END
    }
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

// Size for popover.
- (CGSize)preferredContentSize
{
    return CGSizeMake(250, 5*44);
}

@end
