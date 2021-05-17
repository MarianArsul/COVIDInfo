//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTToolsSettingsViewController.h"
#import "PTToolsUtil.h"
#import "PTToolsSettingsManager.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface PTSettingsTableViewCell : UITableViewCell

@property (nonatomic, copy) NSString* key;
@property (nonatomic, copy) NSString* plistName;
@property (nonatomic) BOOL multivalue;

@end

@implementation PTSettingsTableViewCell


@end

@implementation PTToolsSettingsViewController

- (instancetype)initWithStyle:(UITableViewStyle)style plistName:(NSString *)plistName
{
    self = [super initWithStyle:style];
    if (self) {
        _plistName = plistName;
        if ([plistName hasSuffix:@".plist"]) {
            _plistName = [plistName stringByDeletingPathExtension];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = self.title == nil ? PTLocalizedString(@"App Settings",
                                                                      @"Global settings control title") : self.title;
    
    if( @available(iOS 11, *) )
    {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
    
    [self.tableView registerClass:[PTSettingsTableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    
}

-(void)done
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:Nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [PTToolsSettingsManager.sharedManager defaultSettingsForPlistName:self.plistName].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *settings = [PTToolsSettingsManager.sharedManager defaultSettingsForPlistName:self.plistName][section][PTToolsSettingsSettingKey];
    return settings.count;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [PTToolsSettingsManager.sharedManager defaultSettingsForPlistName:self.plistName][section][PTToolsSettingsCategoryKey];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [PTToolsSettingsManager.sharedManager defaultSettingsForPlistName:self.plistName][section][PTToolsSettingsFooterDescriptionKey];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self tableView:tableView titleForFooterInSection:section] != nil ? UITableViewAutomaticDimension : 0.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PTSettingsTableViewCell *cell = [[PTSettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];

    NSDictionary *item = [PTToolsSettingsManager.sharedManager defaultSettingsForPlistName:self.plistName][indexPath.section];
    NSArray *settings = item[PTToolsSettingsSettingKey];

    BOOL multivalueSection = [item[PTToolsSettingsMultivalueKey] boolValue];

    NSDictionary* settingInfo = settings[indexPath.item];

    NSString* name = settingInfo[PTToolsSettingsSettingNameKey];
    NSString* description = settingInfo[PTToolsSettingsCategoryDescriptionKey];
    cell.textLabel.text = name;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.text = description;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

    if (![settingInfo objectForKey:PTToolsSettingsPlistNameKey]) {

        NSString* key = settingInfo[PTToolsSettingsSettingKeyKey];
        NSString* minOS = settingInfo[PTToolsSettingsMinOSKey];

        cell.key = key;
        UISwitch* radio;
        if (!multivalueSection) {
            BOOL on = [PTToolsSettingsManager.sharedManager boolForKey:key];
            radio = [[UISwitch alloc] init];
            radio.on = on;
            [radio addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = radio;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }else{
            BOOL on = [PTToolsSettingsManager.sharedManager integerForKey:key] == indexPath.row;
            cell.accessoryType = on ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.multivalue = YES;
        }
        
        if( minOS != Nil && SYSTEM_VERSION_LESS_THAN(minOS) )
        {
            BOOL available = [settingInfo[PTToolsSettingsUnavailableKey] boolValue];
            if (radio != nil) {
                radio.on = available;
                radio.enabled = NO;
            }
            cell.textLabel.enabled = NO;
            NSString* unavailable = PTLocalizedString(@"Available on iOS XX.XX.XX and up.", @"Setting unavailable");
            unavailable = [unavailable stringByReplacingOccurrencesOfString:@"XX.XX.XX" withString:minOS];
            cell.detailTextLabel.text = unavailable;
            cell.detailTextLabel.enabled = NO;
        }
    }else if ([settingInfo objectForKey:PTToolsSettingsPlistNameKey]){
        // Setting contains a plist file name containing a list of settings
        cell.plistName = settingInfo[PTToolsSettingsPlistNameKey];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - Preference Changed

-(void)switchChanged:(UISwitch*)radio
{
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:radio.center fromView:radio.superview]];
    PTSettingsTableViewCell* tableViewCell = [self.tableView cellForRowAtIndexPath:indexPath];
        
    if( tableViewCell.key )
    {
        [PTToolsSettingsManager.sharedManager setBool:radio.on forKey:tableViewCell.key];
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PTSettingsTableViewCell* tableViewCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (tableViewCell.selectionStyle == UITableViewCellSelectionStyleNone) {
        return;
    }
    if (tableViewCell.plistName != nil) {
        PTToolsSettingsViewController *childSettingsVC = [[PTToolsSettingsViewController allocOverridden] initWithStyle:tableView.style plistName:tableViewCell.plistName];
        childSettingsVC.title = tableViewCell.textLabel.text;
        [self.navigationController pushViewController:childSettingsVC animated:YES];
    } else if(tableViewCell.key &&
              tableViewCell.multivalue) {
        [PTToolsSettingsManager.sharedManager setInteger:indexPath.row forKey:tableViewCell.key];
        [tableView reloadData];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
