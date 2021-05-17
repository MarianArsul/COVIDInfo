//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSettingsViewController.h"

#import "PTToolsUtil.h"

@interface PTSettingsViewController ()

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@property (nonatomic) BOOL showsDoneButton;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation PTSettingsViewController
#pragma clang diagnostic pop

- (instancetype)init
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
        self.title = PTLocalizedString(@"Viewing Modes", @"View settings title");
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.alwaysBounceHorizontal = NO;
    self.tableView.alwaysBounceVertical = NO;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.showsDoneButton = self.view.frame.size.width ==  self.view.window.bounds.size.width;
    
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - Done button

- (UIBarButtonItem *)doneButtonItem
{
    if (!_doneButtonItem) {
        _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                        target:self
                                                                        action:@selector(dismiss)];
    }
    return _doneButtonItem;
}

- (void)setShowsDoneButton:(BOOL)showsDoneButton
{
    _showsDoneButton = showsDoneButton;
    
    if (showsDoneButton) {
        self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return PTLocalizedString(@"View Mode", @"");
			break;
		case 1:
			return PTLocalizedString(@"Page Rotation", @"");
			break;
		case 2:
			return PTLocalizedString(@"Night Mode", @"");
			break;
		case 3:
			return PTLocalizedString(@"Thumbnail Viewer", @"");
			break;
		default:
			return PTLocalizedString(@"Error", @"");
			break;
	}
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0: return 6;   // Viewing mode: Continuous, Single Page, Facing, Cover Facing, Reflow
		case 1: return 1;   // Rotation
		case 2: return 1;   // Night mode
		case 3: return 1;   // Thumbnails view
		default:
			break;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.accessoryView = nil;
	
	
	switch (indexPath.section) {
			
			// Page viewing mode
		case 0: {
            NSString *text = nil;
            UIImage *image = nil;
			switch (indexPath.row) {
				case 0:
					text = PTLocalizedString(@"Continuous", @"Continuous view mode title");
					image = [PTToolsUtil toolImageNamed:@"ic_view_mode_continuous_black_24dp"];
					break;
				case 1:
					text = PTLocalizedString(@"Single Page", @"Single page view mode title");
					image = [PTToolsUtil toolImageNamed:@"ic_view_mode_single_black_24dp"];
					break;
				case 2:
					text = PTLocalizedString(@"Facing", @"Facing page view mode title");
					image = [PTToolsUtil toolImageNamed:@"ic_view_mode_facing_black_24dp"];
					break;
				case 3:
					text = PTLocalizedString(@"Cover Facing", @"Cover facing view mode title");
					image = [PTToolsUtil toolImageNamed:@"ic_view_mode_cover_black_24dp"];
					break;
                case 4:
                    text = PTLocalizedString(@"Reader", @"Reflow (reader) view mode title");
                    if (@available(iOS 13.0, *)) {
                        image = [UIImage systemImageNamed:@"doc.plaintext" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
                    }
                    
                    if( image == Nil )
                    {
                        image = [PTToolsUtil toolImageNamed:@"ic_view_mode_reflow_black_24dp"];
                    }
                    break;
                case 5:
                    text = PTLocalizedString(@"Reader With Images", @"Reflow (reader) view mode title");
                    if (@available(iOS 13.0, *)) {
                        image = [UIImage systemImageNamed:@"doc.plaintext" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
                    }
                    
                    if( image == Nil )
                    {
                        image = [PTToolsUtil toolImageNamed:@"ic_view_mode_reflow_black_24dp"];
                    }
                    break;
//                case 6:
//                    text = PTLocalizedString(@"Reader With Images B", @"Reflow (reader) view mode title");
//                    image = [PTToolsUtil toolImageNamed:@"ic_view_mode_reflow_black_24px.png"];
//                    break;
                    
                    
                    
			}
            cell.textLabel.text = text;
            cell.imageView.image = image;
            NSString* mode = [[NSUserDefaults standardUserDefaults] stringForKey:@"viewMode"] ;
            
			if ([mode isEqualToString:cell.textLabel.text]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			break;
		}
		case 1: {
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = PTLocalizedString(@"Rotate Pages", @"");
					cell.imageView.image = [PTToolsUtil toolImageNamed:@"ic_rotate_right_black_24dp"];
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				default:
					break;
			}
			break;
		}
		case 2: {
			switch (indexPath.row) {
				case 0:
				{
					cell.textLabel.text = PTLocalizedString(@"Night Mode", @"");
					cell.imageView.image = [PTToolsUtil toolImageNamed:@"ic_mode_night_white_24dp"];
					
                    BOOL isNightMode = NO;
                    if ([self.delegate respondsToSelector:@selector(viewerIsNightMode)]) {
                        isNightMode = [self.delegate viewerIsNightMode];
                    }
                    
					if (isNightMode) {
						cell.accessoryType = UITableViewCellAccessoryCheckmark;
					} else {
						cell.accessoryType = UITableViewCellAccessoryNone;
					}
				}

					break;
				default:
					break;
			}
			break;
		}
		case 3: {
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = PTLocalizedString(@"Thumbnails", @"");
					cell.imageView.image = [PTToolsUtil toolImageNamed:@"ic_thumbnails_grid_black_24dp"];
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				default:
					break;
			}
			break;
		}
	}
	
	
	return cell;
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect row.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (indexPath.section == 0) {
        
        NSString* viewModeValue = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        
		[[NSUserDefaults standardUserDefaults] setObject:viewModeValue forKey:@"viewMode"];
        
        if( [viewModeValue hasPrefix:PTLocalizedString(@"Reader With Images", @"Reader with images")] )
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"readerWithImages" forKey:@"readerMode"];
        }
        else if( [viewModeValue hasPrefix:PTLocalizedString(@"Reader", @"Reader mode")] )
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"reader" forKey:@"readerMode"];
        }
		
		if ([self.delegate respondsToSelector:@selector(settingsViewControllerDidUpdateViewMode:)]) {
			[self.delegate settingsViewControllerDidUpdateViewMode:self];
		}
		
		[self.tableView reloadData];
	} else if (indexPath.section == 1) {
        if ([self.delegate respondsToSelector:@selector(settingsViewControllerDidRotateClockwise:)]) {
            [self.delegate settingsViewControllerDidRotateClockwise:self];
        }
        
	} else if (indexPath.section == 2) {
        if ([self.delegate respondsToSelector:@selector(settingsViewControllerDidToggleNightMode:)]) {
            [self.delegate settingsViewControllerDidToggleNightMode:self];
        }
        
		[self.tableView reloadData];
	} else if (indexPath.section == 3) {
		if ([self.delegate respondsToSelector:@selector(settingsViewControllerDidSelectThumbnails:)]) {
			[self.delegate settingsViewControllerDidSelectThumbnails:self];
		}
	}
}

@end
