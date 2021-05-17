//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTSearchSettingsViewController.h"
#import "PTToolsUtil.h"

@interface PTSearchSettingsTableViewCell : UITableViewCell
@property (nonatomic, copy) NSString* key;
@end

@implementation PTSearchSettingsTableViewCell
@end

NSString * const PTTextSearchMatchCaseKey = @"PTTextSearchMatchCaseKey";
NSString * const PTTextSearchMatchWholeWordKey = @"PTTextSearchMatchWholeWordKey";

@interface PTSearchSettingsViewController ()

@end

@implementation PTSearchSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[PTSearchSettingsTableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.alwaysBounceVertical = NO;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self startObservingContentSize];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopObservingContentSize];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PTSearchSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    BOOL on = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = PTLocalizedString(@"Match Case", @"Label for case-sensitive search toggle in PTTextSearchViewController");
            cell.key = PTTextSearchMatchCaseKey;
            if ([defaults objectForKey:PTTextSearchMatchCaseKey]) {
                on = [defaults boolForKey:PTTextSearchMatchCaseKey];
            }
            break;
        default:
            cell.textLabel.text = PTLocalizedString(@"Whole Word", @"Label for whole word search toggle in PTTextSearchViewController");
            cell.key = PTTextSearchMatchWholeWordKey;
            if ([defaults objectForKey:PTTextSearchMatchWholeWordKey]) {
                on = [defaults boolForKey:PTTextSearchMatchWholeWordKey];
            }
            break;
    }
    UISwitch* radio = [[UISwitch alloc] init];
    radio.tag = indexPath.row;
    radio.on = on;
    [radio addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = radio;
    return cell;
}

#pragma mark - Responding to changes

-(void)switchChanged:(UISwitch*)radio
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:radio.tag inSection:0];
    PTSearchSettingsTableViewCell* tableViewCell = [self.tableView cellForRowAtIndexPath:indexPath];
    [[NSUserDefaults standardUserDefaults] setBool:radio.on forKey:tableViewCell.key];
    if ([self.delegate respondsToSelector:@selector(searchSettingsViewControllerDidToggleSearchMode:)]) {
        [self.delegate searchSettingsViewControllerDidToggleSearchMode:self];
    }
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
}

@end
