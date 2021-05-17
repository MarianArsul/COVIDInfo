//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPDFLayerViewController.h"

#import "PTToolsUtil.h"

@implementation PTLayerInfo
@end

@interface PTPDFLayerViewController ()

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, strong) UIBarButtonItem *doneButton;

@property (nonatomic, assign) BOOL showsDoneButton;

@property (nonatomic, assign, getter=isTabBarItemSetup) BOOL tabBarItemSetup;

@end

@implementation PTPDFLayerViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        self.title = PTLocalizedString(@"PDF Layers", @"PDF Layers controller title");
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Show done button for phones.
    self.showsDoneButton = (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.showsDoneButton = self.view.frame.size.width ==  self.view.window.bounds.size.width;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadLayers];
}

- (void)dismiss {
    if ([self.delegate respondsToSelector:@selector(pdfLayerViewControllerDidCancel:)]) {
        [self.delegate pdfLayerViewControllerDidCancel:self];
    }
}

- (UITabBarItem *)tabBarItem
{
    UITabBarItem *tabBarItem = [super tabBarItem];

    if (![self isTabBarItemSetup]) {
        // Add image to tab bar item.
        
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"square.stack.3d.up" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]];

        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_menu_white_24dp"];
        }

        tabBarItem.image = image;

        self.tabBarItemSetup = YES;
    }

    return tabBarItem;
}

#pragma mark - Done button

- (void)setShowsDoneButton:(BOOL)showsDoneButton
{
    _showsDoneButton = showsDoneButton;

    if (showsDoneButton && ![self isEditing]) {
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (UIBarButtonItem *)doneButton
{
    if (!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(dismiss)];
    }
    return _doneButton;
}

#pragma mark - Table view data source

- (void)loadLayers
{
    NSMutableArray* layersMutable;
    BOOL shouldUnlockRead = NO;
    @try
    {
        layersMutable = [[NSMutableArray alloc] init];
        [self.pdfViewCtrl DocLockRead];
        shouldUnlockRead = YES;

        if ([[self.pdfViewCtrl GetDoc] HasOC]) {
            PTConfig *config = [[self.pdfViewCtrl GetDoc] GetOCGConfig];
            if (![config IsValid]) {
                return;
            }
            PTContext *context = [self.pdfViewCtrl GetOCGContext];
            PTObj *ocgs = [config GetOrder];
            if (ocgs != nil) {
                int sz = (int) ocgs.Size;
                for (int i = 0; i < sz; i++) {
                    PTGroup *group = [[PTGroup alloc] initWithOcg:[ocgs GetAt:i]];
                    PTLayerInfo *layerInfo = [[PTLayerInfo alloc] init];
                    layerInfo.group = group;
                    layerInfo.state = [context GetState:group];
                    [layersMutable addObject:layerInfo];
                }
            }
        }
    }
    @catch(NSException *exception){
        NSLog(@"Exception: %@: reason: %@", exception.name, exception.reason);
    }
    @finally{
        if (shouldUnlockRead) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    self.layers = [NSArray arrayWithArray:layersMutable];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numLayers = self.layers.count;
    if (numLayers == 0) {
        UILabel *noLayersLabel = [[UILabel alloc] initWithFrame:self.tableView.bounds];

        noLayersLabel.text = PTLocalizedString(@"This document does not\ncontain any OCG layers.",
                                             @"String to indicate no layers in doc in PTPDFLayerViewController.");
        noLayersLabel.numberOfLines = 0;
        noLayersLabel.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = noLayersLabel;
   }
    return numLayers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSString* genericLayerLabel = PTLocalizedString(@"Layer", @"Refers to an OCG Layer");
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    @try {
        
        PTLayerInfo *layerInfo = [self.layers objectAtIndex:indexPath.row];
        PTGroup *layer = layerInfo.group;
        
        @try {
            cell.textLabel.text = [layer GetName];
        } @catch (NSException *exception) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %ld", genericLayerLabel, (long)indexPath.row+1];
        }
        
        
        UISwitch *layerSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        layerSwitch.tag = indexPath.row;
        [layerSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [layerSwitch setOn:layerInfo.state];
        cell.accessoryView = layerSwitch;
        
    } @catch (NSException *exception) {
        NSLog(@"Exception occurred: %@: %@", exception.name, exception.reason);
    }

    return cell;

}

- (void)switchChanged:(UISwitch*)sender {
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        PTContext *context = [self.pdfViewCtrl GetOCGContext];

        PTLayerInfo *layerInfo = [self.layers objectAtIndex:sender.tag];
        PTGroup *layer = layerInfo.group;

        [context SetState:layer state:sender.isOn];

        [self.pdfViewCtrl SetOCGContext:context];
        [self.pdfViewCtrl Update:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
        [self loadLayers];
    }
}

@end
