//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAddPagesViewController.h"
#import "PTToolsUtil.h"

@interface PTAddPagesViewController ()

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@end

@implementation PTAddPagesViewController

#pragma mark - Initialization

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    UITableViewStyle tableViewStyle = UITableViewStyleGrouped;
    if( @available(iOS 13, *) )
    {
        tableViewStyle = UITableViewStyleInsetGrouped;
    }
    self = [super initWithStyle:tableViewStyle];
    if (self) {
        _toolManager = toolManager;
        _pdfViewCtrl = toolManager.pdfViewCtrl;
        _items = @[self.addBlankPagesButtonItem,self.addImagePageButtonItem, self.addCameraImagePageButtonItem,self.addDocumentPagesButtonItem];
    }
    return self;
}

- (UIBarButtonItem *)addBlankPagesButtonItem
{
    if (!_addBlankPagesButtonItem) {
        UIImage *image = [PTToolsUtil toolImageNamed:@"ic_view_mode_single_black_24px"];
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"doc" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        _addBlankPagesButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(showPageTemplateViewController:)];
        _addBlankPagesButtonItem.title = PTLocalizedString(@"New Blank Page", @"Add blank pages cell title in PTAddPagesViewController");
        
        _addBlankPagesButtonItem.enabled = self.pdfViewCtrl.externalAnnotManager == Nil;
    }
    return _addBlankPagesButtonItem;
}

- (UIBarButtonItem *)addImagePageButtonItem
{
    if (!_addImagePageButtonItem) {
        UIImage *image = [PTToolsUtil toolImageNamed:@"Annotation/Image/Icon"];
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"photo" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        _addImagePageButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showImagePickerController:)];
        _addImagePageButtonItem.title = PTLocalizedString(@"New Page from Photo Library", @"Add image page alert title in PTAddPagesViewController");
        
        _addImagePageButtonItem.enabled = self.pdfViewCtrl.externalAnnotManager == Nil;
    }
    return _addImagePageButtonItem;
}

- (UIBarButtonItem *)addCameraImagePageButtonItem
{
    if (!_addCameraImagePageButtonItem) {
        UIImage *image = [PTToolsUtil toolImageNamed:@"ic_annotation_camera_black_24dp"];
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"camera" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        _addCameraImagePageButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showCamera:)];
        _addCameraImagePageButtonItem.title = PTLocalizedString(@"New Page with Camera", @"Take photo alert title in PTAddPagesViewController");

        _addCameraImagePageButtonItem.enabled = self.pdfViewCtrl.externalAnnotManager == Nil;
    }
    return _addCameraImagePageButtonItem;
}

- (UIBarButtonItem *)addDocumentPagesButtonItem
{
    if (!_addDocumentPagesButtonItem) {
        UIImage *image = [PTToolsUtil toolImageNamed:@"ic_file_black_24dp"];
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"doc.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        _addDocumentPagesButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showDocumentPickerViewController:)];
        _addDocumentPagesButtonItem.title = PTLocalizedString(@"Import Pages from PDF", @"Add pages from document alert title in PTAddPagesViewController");
        
        _addDocumentPagesButtonItem.enabled = self.pdfViewCtrl.externalAnnotManager == Nil;
    }
    return _addDocumentPagesButtonItem;
}

- (PTAddPagesManager *)addPagesManager{
    if (!_addPagesManager) {
        _addPagesManager = [[PTAddPagesManager alloc] initWithToolManager:self.toolManager];
    }
    return _addPagesManager;
}

#pragma mark - View Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = PTLocalizedString(@"Add Pages", @"Add Pages View Controller title");
    [self.navigationController.navigationItem.backBarButtonItem setTitle:@" "];
    self.tableView.alwaysBounceVertical = NO;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.navigationController.preferredContentSize = self.tableView.contentSize;
    [self startObservingContentSize];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopObservingContentSize];
}

#pragma mark - Actions

-(void)prepareAddPagesManager{
    if (self.presentingViewController) {
        self.addPagesManager.presentingViewController = self.presentingViewController;
    }
    if (self.popoverPresentationController) {
        if (self.popoverPresentationController.barButtonItem) {
            self.addPagesManager.barButtonItem = self.popoverPresentationController.barButtonItem;
        }else if (self.popoverPresentationController.sourceView){
            self.addPagesManager.sourceView = self.popoverPresentationController.sourceView;
        }
    }
}

- (void)showPageTemplateViewController:(UIBarButtonItem *)sender
{
    [self prepareAddPagesManager];
    [self.addPagesManager showPageTemplateViewController];
}

- (void)showImagePickerController:(UIBarButtonItem *)sender
{
    [self prepareAddPagesManager];
    [self.addPagesManager showImagePickerController];
}

- (void)showCamera:(UIBarButtonItem *)sender
{
    [self prepareAddPagesManager];
    [self.addPagesManager showCamera];
}

- (void)showDocumentPickerViewController:(UIBarButtonItem *)sender
{
    [self prepareAddPagesManager];
    [self.addPagesManager showDocumentPickerViewController];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.text = self.items[indexPath.row].title;
    cell.accessoryView = [[UIImageView alloc] initWithImage:self.items[indexPath.row].image];
    BOOL enabled = self.items[indexPath.row].enabled;
    cell.userInteractionEnabled = enabled;
    cell.textLabel.enabled = enabled;
    cell.detailTextLabel.enabled = enabled;
    cell.tintAdjustmentMode = enabled ? UIViewTintAdjustmentModeAutomatic : UIViewTintAdjustmentModeDimmed;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIBarButtonItem* item = self.items[indexPath.row];
    [UIApplication.sharedApplication sendAction:item.action to:item.target from:item forEvent:nil];
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
