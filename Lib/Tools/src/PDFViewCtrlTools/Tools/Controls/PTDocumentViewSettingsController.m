//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentViewSettingsController.h"

#import "PTPDFViewCtrlAdditions.h"
#import "PTToolsUtil.h"

#import "UIViewController+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentViewSettingsController ()

@property (nonatomic, strong) PTMappedFile* sepiaColourLookupMap;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentViewSettingsController

- (void)PTDocumentViewSettingsController_commonInit
{
    _settings = [[PTDocumentViewSettings alloc] init];
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self PTDocumentViewSettingsController_commonInit];
        
        _pdfViewCtrl = pdfViewCtrl;
                
        self.title = PTLocalizedString(@"View Settings", @"View settings title");
    }
    return self;
}

- (void)setSettings:(PTDocumentViewSettings *)settings
{
    if (settings) {
        _settings = settings;
    } else {
        _settings = [[PTDocumentViewSettings alloc] init];
    }
    
    if (self.viewIfLoaded.window) {
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Only bounce when scrolling is required.
    self.tableView.alwaysBounceHorizontal = NO;
    self.tableView.alwaysBounceVertical = NO;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    [self updateDoneButton:NO];
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
    
    [self updateDoneButton:animated];
    
    [self.tableView reloadData];
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateDoneButton:NO];
}

#pragma mark - Done button

@synthesize doneButtonItem = _doneButtonItem;

- (UIBarButtonItem *)doneButtonItem
{
    if (!_doneButtonItem) {
        _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                        target:self
                                                                        action:@selector(done:)];
    }
    return _doneButtonItem;
}

- (BOOL)showsDoneButton
{
    // Don't show the "Done" button when in a popover presentation.
    return !([self pt_isInPopover]);
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

- (void)done:(id)sender
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
            return PTLocalizedString(@"Color Mode", @"");
            break;
        case 2:
            return PTLocalizedString(@"Page Rotation", @"");
            break;
        default:
            return PTLocalizedString(@"Error", @"");
            break;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return 5;   // Viewing mode: Single Page, Facing, Cover Facing, Reflow, Vertical Scrolling
        case 1: return 3;   // Color modes
        case 2: return 1;   // Rotation
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
            TrnPagePresentationMode mode = e_trn_single_page;
            switch (indexPath.row) {
                case 0:
                    text = PTLocalizedString(@"Single Page", @"Single page view mode title");
                    image = [PTToolsUtil toolImageNamed:@"ic_view_mode_single_black_24px.png"];
                    mode = e_trn_single_page;
                    break;
                case 1:
                    text = PTLocalizedString(@"Facing", @"Facing page view mode title");
                    image = [PTToolsUtil toolImageNamed:@"ic_view_mode_facing_black_24px.png"];
                    mode = e_trn_facing;
                    break;
                case 2:
                    text = PTLocalizedString(@"Cover Facing", @"Cover facing view mode title");
                    image = [PTToolsUtil toolImageNamed:@"ic_view_mode_cover_black_24px.png"];
                    mode = e_trn_facing_cover;
                    break;
                case 3:
                    text = PTLocalizedString(@"Reader", @"Reflow (reader) view mode title");
                    image = [PTToolsUtil toolImageNamed:@"ic_view_mode_reflow_black_24px.png"];
                    if (@available(iOS 13.0, *)) {
                        image = [UIImage systemImageNamed:@"doc.plaintext" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
                    }
                    break;
                case 4:
                    text = PTLocalizedString(@"Vertical Scrolling", @"Vertical scrolling title");
                    image = [PTToolsUtil toolImageNamed:@"ic_view_mode_continuous_black_24px.png"];
                    break;
            }
            cell.textLabel.text = text;
            cell.imageView.image = image;
            
            if (indexPath.row < 4) {
                BOOL selected = NO;
                
                if (indexPath.row < 3) {
                    TrnPagePresentationMode currentBasePagePresentationMode = PTPagePresentationModeGetBaseMode(self.settings.pagePresentationMode);
                    
                    selected = (mode == currentBasePagePresentationMode) && !([self.settings isReflowEnabled]);
                } else {
                    selected = [self.settings isReflowEnabled];
                }
                
                if (selected) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            } else {
                UISwitch *switchView = [[UISwitch alloc] init];
                cell.accessoryView = switchView;
                
                switchView.on = PTPagePresentationModeIsContinuous(self.settings.pagePresentationMode);
                
                [switchView addTarget:self
                               action:@selector(verticalScrollingSwitchValueChanged:)
                     forControlEvents:UIControlEventValueChanged];
                
                // Disable row selection.
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                {
                    cell.textLabel.text = PTLocalizedString(@"Light Mode", @"");
                    cell.imageView.image = [PTToolsUtil toolImageNamed:@"ic_mode_day_black_24dp"];
                    
                    
                    BOOL isLightMode = (self.settings.colorPostProcessMode == e_ptpostprocess_none);
                    
                    if (isLightMode) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
                }
                case 1:
                {
                    cell.textLabel.text = PTLocalizedString(@"Dark Mode", @"");
                    cell.imageView.image = [PTToolsUtil toolImageNamed:@"ic_mode_night_black_24px.png"];
                    
                    BOOL isNightMode = (self.settings.colorPostProcessMode == e_ptpostprocess_night_mode);
                    
                    if (isNightMode) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
                }
                case 2:
               {
                   cell.textLabel.text = PTLocalizedString(@"Sepia Mode", @"");
                   
                   if (@available(iOS 13.0, *)) {
                       cell.imageView.image = [UIImage systemImageNamed:@"a.square.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleUnspecified]];
                   }
                   
                   else
                   {
                       [PTToolsUtil toolImageNamed:@"Annotation/Underline/Icon"];
                   }
                   
                   
                   BOOL isSepiaMode = (self.settings.colorPostProcessMode == e_ptpostprocess_gradient_map);
                   
                   if (isSepiaMode) {
                       cell.accessoryType = UITableViewCellAccessoryCheckmark;
                   } else {
                       cell.accessoryType = UITableViewCellAccessoryNone;
                   }
                   break;
               }
                
                    
                    break;
                default:
                    break;
            }
            break;
        }
        case 2: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = PTLocalizedString(@"Rotate Pages", @"");
                    cell.imageView.image = [PTToolsUtil toolImageNamed:@"ic_rotate_right_black_24px.png"];
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

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect row.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row < 3) {
            TrnPagePresentationMode pagePresentationMode = e_trn_single_page;
            switch (indexPath.row) {
                case 0:
                    pagePresentationMode = e_trn_single_page;
                    break;
                case 1:
                    pagePresentationMode = e_trn_facing;
                    break;
                case 2:
                    pagePresentationMode = e_trn_facing_cover;
                    break;
            }
            BOOL continuous = PTPagePresentationModeIsContinuous(self.settings.pagePresentationMode);
            
            [self setPagePresentationMode:pagePresentationMode continuous:continuous];
        } else if (indexPath.row == 3) {
            if (![self.settings isReflowEnabled]) {
                self.settings.reflowEnabled = YES;
                
                // Notify delegate of change.
                if ([self.delegate respondsToSelector:@selector(documentViewSettingsController:didUpdateSettings:)]) {
                    [self.delegate documentViewSettingsController:self didUpdateSettings:self.settings];
                }
            }
        }
        
        [self.tableView reloadData];
    } else if (indexPath.section == 1) {
        
        if( indexPath.row == 0 )
        {
            self.settings.colorPostProcessMode = e_ptpostprocess_none;
        }
        else if( indexPath.row == 1)
        {
            self.settings.colorPostProcessMode = e_ptpostprocess_night_mode;
        }
        else if( indexPath.row == 2)
        {
            self.settings.colorPostProcessMode = e_ptpostprocess_gradient_map;
        }
        
        if ([self.delegate respondsToSelector:@selector(documentViewSettingsController:didUpdateSettings:)]) {
            [self.delegate documentViewSettingsController:self didUpdateSettings:self.settings];
        }
        
        [self.tableView reloadData];
    } else if (indexPath.section == 2) {

        [self rotatePagesClockwise];
    }
}

#pragma mark - UIControl actions

- (void)verticalScrollingSwitchValueChanged:(UISwitch *)control
{
    const TrnPagePresentationMode mode = self.settings.pagePresentationMode;
    const BOOL continuous = [control isOn];
    
    TrnPagePresentationMode effectivePagePresentationMode = PTPagePresentationModeGetEffectiveMode(mode,
                                                                                                   continuous);
    
    BOOL needsUpdate = NO;
    
    if (![self.settings isReflowEnabled]) {
        needsUpdate = (self.settings.pagePresentationMode != effectivePagePresentationMode);
    }
    else { // Reflow enabled.
        needsUpdate = YES;
    }
    
    if (needsUpdate) {
        self.settings.pagePresentationMode = effectivePagePresentationMode;
        
        // Notify delegate of change.
        if ([self.delegate respondsToSelector:@selector(documentViewSettingsController:didUpdateSettings:)]) {
            [self.delegate documentViewSettingsController:self didUpdateSettings:self.settings];
        }
    }
}

- (void)setPagePresentationMode:(TrnPagePresentationMode)mode continuous:(BOOL)continuous
{
    TrnPagePresentationMode effectivePagePresentationMode = PTPagePresentationModeGetEffectiveMode(mode,
                                                                                             continuous);

    BOOL needsUpdate = NO;
    
    if (![self.settings isReflowEnabled]) {
        needsUpdate = (self.settings.pagePresentationMode != effectivePagePresentationMode);
    }
    else { // Reflow enabled.
        needsUpdate = YES;
    }
    
    if (needsUpdate) {
        self.settings.pagePresentationMode = effectivePagePresentationMode;
        self.settings.reflowEnabled = NO; // Reflow is disabled.
        
        // Notify delegate of change.
        if ([self.delegate respondsToSelector:@selector(documentViewSettingsController:didUpdateSettings:)]) {
            [self.delegate documentViewSettingsController:self didUpdateSettings:self.settings];
        }
    }
}


- (void)rotatePagesClockwise
{
    PTRotate pageRotation = self.settings.pageRotation;
    pageRotation = (pageRotation + 1) % 4;
    self.settings.pageRotation = pageRotation;
    
    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(documentViewSettingsController:didUpdateSettings:)]) {
        [self.delegate documentViewSettingsController:self didUpdateSettings:self.settings];
    }
}

@end
