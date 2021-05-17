//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDiffViewController.h"

#import "PTToolsUtil.h"
#import "PTColorDefaults.h"
#import "PTColorSliderTableViewCell.h"
#import "PTAnnotStyleColorTableViewCell.h"
#import "UIColor+PTHexString.h"

@interface PTDiffViewController () <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UIDocumentPickerDelegate, PTColorSliderTableViewCellDelegate>

@property (nonatomic, strong) UIPickerView *blendModePicker;
@property (nonatomic) BOOL blendModePickerVisible;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *blendModesArray;
@property (nonatomic, strong) NSArray *cellLabels;
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic, strong) NSIndexPath *selectedColourSlider;

@property (nonatomic, assign) NSUInteger selectingDocumentIdx;

@end

@implementation PTDiffViewController

- (instancetype)init
{
    return [self initWithDocument:nil secondDocument:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (instancetype)initWithDocument:(PTPDFDoc *)firstDocument secondDocument:(PTPDFDoc *)secondDocument
{
    return [self initWithDocument:firstDocument secondDocument:secondDocument firstDocumentColor:nil secondDocumentColor:nil];
}

- (instancetype)initWithDocument:(PTPDFDoc *)firstDocument secondDocument:(PTPDFDoc *)secondDocument firstDocumentColor:(UIColor *)firstDocumentColor secondDocumentColor:(UIColor *)secondDocumentColor
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _firstDocument = firstDocument;
        _secondDocument = secondDocument;
        _firstDocumentColor = firstDocumentColor;
        _secondDocumentColor = secondDocumentColor;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = PTLocalizedString(@"File Comparison", @"PTDiffViewController title");
    self.blendMode = e_ptbl_darken;
    self.firstDocumentColor = self.firstDocumentColor ?: [UIColor pt_colorWithHexString:@"#AA0000"];
    self.secondDocumentColor = self.secondDocumentColor ?: [UIColor pt_colorWithHexString:@"#00AAAA"];

    self.colors = [@[self.firstDocumentColor,self.secondDocumentColor] mutableCopy];

    self.blendModePicker = [[UIPickerView alloc] init];
    self.blendModesArray = @[[NSNumber numberWithInt:e_ptbl_compatible],
                             [NSNumber numberWithInt:e_ptbl_normal],
                             [NSNumber numberWithInt:e_ptbl_multiply],
                             [NSNumber numberWithInt:e_ptbl_screen],
                             [NSNumber numberWithInt:e_ptbl_difference],
                             [NSNumber numberWithInt:e_ptbl_darken],
                             [NSNumber numberWithInt:e_ptbl_lighten],
                             [NSNumber numberWithInt:e_ptbl_color_dodge],
                             [NSNumber numberWithInt:e_ptbl_color_burn],
                             [NSNumber numberWithInt:e_ptbl_exclusion],
                             [NSNumber numberWithInt:e_ptbl_hard_light],
                             [NSNumber numberWithInt:e_ptbl_overlay],
                             [NSNumber numberWithInt:e_ptbl_soft_light],
                             [NSNumber numberWithInt:e_ptbl_luminosity],
                             [NSNumber numberWithInt:e_ptbl_hue],
                             [NSNumber numberWithInt:e_ptbl_saturation],
                             [NSNumber numberWithInt:e_ptbl_color]];
    self.blendModePicker.delegate = self;
    self.blendModePicker.dataSource = self;
    [self.blendModePicker selectRow:5 inComponent:0 animated:NO];
    self.blendModePickerVisible = NO;
    self.blendModePicker.hidden = YES;
    self.blendModePicker.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];

    [self setTableViewCellLabels];
    [self.tableView reloadData];
    
    NSString *compareButtonString = PTLocalizedString(@"Compare", @"File comparison button label in PTDiffViewController");
    UIBarButtonItem *compareButton = [[UIBarButtonItem alloc] initWithTitle: compareButtonString style:UIBarButtonItemStylePlain target:self action:@selector(compareButtonPressed)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[flex,compareButton,flex];
    self.navigationController.toolbarHidden = NO;
    
    self.selectedColourSlider = [NSIndexPath indexPathForRow:-1 inSection:-1];
    [self.view setNeedsUpdateConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)updateViewConstraints
{
    [NSLayoutConstraint activateConstraints:
     @[[self.tableView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
       [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [self.tableView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
       ]];
    [super updateViewConstraints];
}

- (void)setTableViewCellLabels
{
    NSString *documentSelectString = PTLocalizedString(@"Select a file to compare", @"File comparison label in PTDiffViewController");
    NSString *firstDocumentString = self.firstDocument ? [self.firstDocument GetFileName].lastPathComponent.stringByDeletingPathExtension :  documentSelectString;
    NSString *secondDocumentString = self.secondDocument ? [self.secondDocument GetFileName].lastPathComponent.stringByDeletingPathExtension :  documentSelectString;
    
    NSString *documentColorString = PTLocalizedString(@"File display color", @"File display color label in PTDiffViewController");
    NSArray *firstDocumentSectionLabels = @[firstDocumentString, documentColorString, @""];
    NSArray *secondDocumentSectionLabels = @[secondDocumentString, documentColorString, @""];
    
    NSString *blendModeString = PTLocalizedString(@"Blend mode", @"Blend mode label in PTDiffViewController");
    NSArray *blendModeSectionLabels = @[blendModeString, @""];
    
    self.cellLabels = @[firstDocumentSectionLabels,
                        secondDocumentSectionLabels,
                        blendModeSectionLabels];
}

#pragma mark - TableView

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    // Blend mode UIPicker cell
    if (indexPath.section == 2 && indexPath.row == 1) {
        [cell.contentView addSubview:self.blendModePicker];
        [NSLayoutConstraint activateConstraints:
         @[[self.blendModePicker.widthAnchor constraintEqualToAnchor:cell.contentView.widthAnchor],
           [self.blendModePicker.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
           [self.blendModePicker.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor],
           [self.blendModePicker.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor]
           ]];
    }else if (indexPath.section == 2 && indexPath.row == 0) { // Blend mode label cell
        cellIdentifier = @"blendModeLabelCell";
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        }
        cell.textLabel.text = self.cellLabels[indexPath.section][indexPath.row];
        cell.detailTextLabel.text = [self stringForBlendMode:self.blendMode];
    }else if (indexPath.row == 2){ // Colour slider cell
        PTColorSliderTableViewCell *colorCell = [[PTColorSliderTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"colorSliderCell" withColor:[self.colors objectAtIndex:indexPath.section]];
        colorCell.selectionStyle = UITableViewCellSelectionStyleNone;
        colorCell.textLabel.text = self.cellLabels[indexPath.section][indexPath.row];
        colorCell.delegate = self;
        colorCell.color = [self.colors objectAtIndex:indexPath.section];
        colorCell.tag = indexPath.section;
        return colorCell;
    }else{
        if (indexPath.row == 0) {
            cellIdentifier = @"documentPickerCell";
            cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.enabled = YES;
            UIButton *documentSelectButton = [UIButton buttonWithType:UIButtonTypeSystem];
            documentSelectButton.tag = indexPath.section;
            [documentSelectButton addTarget:self action:@selector(selectDocument:) forControlEvents:UIControlEventTouchUpInside];
            NSString *documentSelectLabel = PTLocalizedString(@"Select", @"File select button title in PTDiffViewController");
            [documentSelectButton setTitle:documentSelectLabel forState:UIControlStateNormal];
            [documentSelectButton sizeToFit];
            cell.accessoryView = documentSelectButton;
        }else if (indexPath.row == 1) {
            cellIdentifier = @"colorPickerCell";
            cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
            }
            UIButton *colorIndicatorButton = [UIButton buttonWithType:UIButtonTypeCustom];
            colorIndicatorButton.backgroundColor = [self.colors objectAtIndex:indexPath.section];
            colorIndicatorButton.frame = CGRectMake(0, 0, 30, 30);
            colorIndicatorButton.layer.cornerRadius = 15;
            colorIndicatorButton.layer.borderWidth = 1.0f;
            colorIndicatorButton.layer.borderColor = UIColor.lightGrayColor.CGColor;
            colorIndicatorButton.layer.masksToBounds = YES;
            colorIndicatorButton.tag = indexPath.section;
            [colorIndicatorButton addTarget:self action:@selector(selectColor:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = colorIndicatorButton;
        }
        cell.textLabel.text = self.cellLabels[indexPath.section][indexPath.row];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section < 2 ? 3 : 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 44.0f;
    if (indexPath.section == 2 && indexPath.row == 1){
        height = self.blendModePickerVisible ? 216.0f : 0.0f;
    }else if (indexPath.row > 1){
        height = indexPath.section == self.selectedColourSlider.section ? 80.0f : 0.0f;
        [self.tableView cellForRowAtIndexPath:indexPath].hidden = !(indexPath.section == self.selectedColourSlider.section);
    }
    return height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2 && indexPath.row == 0) {
        if (self.blendModePickerVisible){
            [self hideBlendModePickerCell];
        } else {
            [self showBlendModePickerCell];
        }
    } else if (indexPath.section < 2 && indexPath.row == 1) {
        if (self.selectedColourSlider == indexPath) {
            self.selectedColourSlider = [NSIndexPath indexPathForRow:-1 inSection:-1];
            [self hideColourSliderCells];
        }else{
            self.selectedColourSlider = indexPath;
            [self showColourSliderCells];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 2 || indexPath.row == 2) return indexPath;
    if(indexPath.section < 2 || indexPath.row == 1) return indexPath;
    return nil;
}

#pragma mark - UIPickerView
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.blendModesArray.count;
}

- (nullable NSString *)stringForBlendMode:(PTBlendMode)blendMode
{
    switch (blendMode) {
        case e_ptbl_compatible:
            return PTLocalizedString(@"Compatible", @"Overlay blend mode title");
        case e_ptbl_normal:
            return PTLocalizedString(@"Normal", @"Overlay blend mode title");
        case e_ptbl_multiply:
            return PTLocalizedString(@"Multiply", @"Overlay blend mode title");
        case e_ptbl_screen:
            return PTLocalizedString(@"Screen", @"Overlay blend mode title");
        case e_ptbl_difference:
            return PTLocalizedString(@"Difference", @"Overlay blend mode title");
        case e_ptbl_darken:
            return PTLocalizedString(@"Darken", @"Overlay blend mode title");
        case e_ptbl_lighten:
            return PTLocalizedString(@"Lighten", @"Overlay blend mode title");
        case e_ptbl_color_dodge:
            return PTLocalizedString(@"Color Dodge", @"Overlay blend mode title");
        case e_ptbl_color_burn:
            return PTLocalizedString(@"Color Burn", @"Overlay blend mode title");
        case e_ptbl_exclusion:
            return PTLocalizedString(@"Exclusion", @"Overlay blend mode title");
        case e_ptbl_hard_light:
            return PTLocalizedString(@"Hard Light", @"Overlay blend mode title");
        case e_ptbl_overlay:
            return PTLocalizedString(@"Overlay", @"Overlay blend mode title");
        case e_ptbl_soft_light:
            return PTLocalizedString(@"Soft Light", @"Soft light blend mode title");
        case e_ptbl_luminosity:
            return PTLocalizedString(@"Luminosity", @"Luminosity blend mode title");
        case e_ptbl_hue:
            return PTLocalizedString(@"Hue", @"Hue blend mode title");
        case e_ptbl_saturation:
            return PTLocalizedString(@"Saturation", @"Saturation blend mode title");
        case e_ptbl_color:
            return PTLocalizedString(@"Color", @"Color blend mode title");
        default:
            return nil;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    PTBlendMode blendMode = [[self.blendModesArray objectAtIndex:row] intValue];
    return [self stringForBlendMode:blendMode];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.blendMode = [[self.blendModesArray objectAtIndex:row] intValue];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)showBlendModePickerCell
{
    self.blendModePickerVisible = YES;
    self.blendModePicker.alpha = 0.0f;
     self.blendModePicker.hidden = NO;
    [UIView animateWithDuration:0.25
                     animations:^{
                          [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
                         self.blendModePicker.alpha = 1.0f;
                         [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                     } completion:^(BOOL finished){
                         self.blendModePicker.hidden = NO;
                     }];
}

- (void)hideBlendModePickerCell
{
    self.blendModePickerVisible = NO;

    [UIView animateWithDuration:0.25
                     animations:^{
                         self.blendModePicker.alpha = 0.0f;
                         [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
                     }
                     completion:^(BOOL finished){
                         self.blendModePicker.hidden = YES;
                     }];
}

- (void)showColourSliderCells
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.tableView beginUpdates];
                         [self.tableView endUpdates];
                     } completion:^(BOOL finished){
                     }];
}

- (void)hideColourSliderCells
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.tableView beginUpdates];
                         [self.tableView endUpdates];
                     }
                     completion:^(BOOL finished){
                     }];
}

#pragma mark - Document Selection

- (void)selectDocument:(UIButton*)button
{
    self.selectingDocumentIdx = button.tag;
    [self showDocumentPicker];
}

- (void)showDocumentPicker
{
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"com.adobe.pdf"]
                                                                                                            inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

PT_IGNORE_WARNINGS_BEGIN("deprecated-implementations")
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    PTPDFDoc *selectedDocument = [[PTPDFDoc alloc] initWithFilepath:url.path];
    if (self.selectingDocumentIdx == 0) {
        self.firstDocument = selectedDocument;
    }else{
        self.secondDocument = selectedDocument;
    }
    [self setTableViewCellLabels];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:self.selectingDocumentIdx]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}
PT_IGNORE_WARNINGS_END
PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(nonnull NSArray<NSURL *> *)urls
{
    [self documentPicker:controller didPickDocumentAtURL:urls.firstObject];
}
PT_IGNORE_WARNINGS_END
#pragma mark - Document Comparison

- (void)compareButtonPressed
{
    if (!self.firstDocument || !self.secondDocument) {
        NSString *alertTitle = PTLocalizedString(@"You must select two files to compare", @"PTDiffViewController select files alert title");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                 message:@""
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK", @"")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action){
                                                                 [alertController dismissViewControllerAnimated:YES completion:nil];
                                                                 return;
                                                             }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }else{
        [self compareDocuments];
    }
}

- (void)compareDocuments
{
    PTColorPt *firstColor = self.firstDocumentColor ? [PTColorDefaults colorPtFromUIColor:self.firstDocumentColor] : [[PTColorPt alloc] initWithX:1 y:0 z:0 w:1.0/3.0];
    PTColorPt *secondColor = self.secondDocumentColor ? [PTColorDefaults colorPtFromUIColor:self.secondDocumentColor] : [[PTColorPt alloc] initWithX:0 y:1 z:1 w:1.0/3.0];
    PTDiffOptions *diffOptions = [[PTDiffOptions alloc] init];
    [diffOptions SetColorA:firstColor];
    [diffOptions SetColorB:secondColor];
    [diffOptions SetBlendMode:self.blendMode];
    
    PTPDFDoc *doc = [[PTPDFDoc alloc] init];

    int pageCountA = self.firstDocument.GetPageCount;
    int pageCountB = self.secondDocument.GetPageCount;

    for (int i = 1; i <= MAX(pageCountA, pageCountB) ; i++) {
        PTPage *pageA = [self.firstDocument GetPage:i];
        PTPage *pageB = [self.secondDocument GetPage:i];
        [doc AppendVisualDiff:pageA p2:pageB opts:diffOptions];
    }
    
    NSString* temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"diff.pdf"];
    [doc SaveToFile:temporaryFilePath flags:e_ptlinearized];
    
    if ([self.delegate respondsToSelector:@selector(diffViewController:didCreateDiffFileAtURL:)]) {
        [self.delegate diffViewController:self didCreateDiffFileAtURL:[NSURL fileURLWithPath:temporaryFilePath]];
    }
}

#pragma mark - Color Selection

- (void)selectColor:(UIButton*)button
{
    if (self.selectedColourSlider.section == button.tag) {
        self.selectedColourSlider = [NSIndexPath indexPathForRow:-1 inSection:-1];
        [self hideColourSliderCells];
    }else {
        self.selectedColourSlider = [NSIndexPath indexPathForRow:1 inSection:button.tag];
        [self showColourSliderCells];
    }
}

- (void)colorSliderTableViewCell:(PTColorSliderTableViewCell *)cell colorChanged:(UIColor *)color
{
    switch (cell.tag) {
        case 0:
            self.firstDocumentColor = color;
            break;
        case 1:
            self.secondDocumentColor = color;
            break;
        default:
            break;
    }
    [self.colors replaceObjectAtIndex:cell.tag withObject:color];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:cell.tag]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

@end
