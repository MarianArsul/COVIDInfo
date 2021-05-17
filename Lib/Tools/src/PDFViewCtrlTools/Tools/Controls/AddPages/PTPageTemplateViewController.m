//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPageTemplateViewController.h"
#import "PTPageTemplatesTableViewCell.h"
#import "PTPageColorTableViewCell.h"
#import "UIColor+PTEquality.h"

@interface PTPageTemplateViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDataSource,
                                            UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, strong) UITextField *pageNumberTextField;
@property (nonatomic, strong) UIPickerView *pageSizePicker;
@property (nonatomic, readonly, strong) NSArray<NSString*> *sortedPageSizeKeys;
@property (nonatomic, strong) UISegmentedControl *orientationControl;
@property (nonatomic, strong) UIStepper *pageCountStepper;
@property (nonatomic, strong) UICollectionView *pageTemplatesCollectionView;
@property (nonatomic, strong) UICollectionView *pageColorCollectionView;
@property (nonatomic, assign) BOOL pickerVisible;

@property (nonatomic, assign) PTPageTemplateStyle selectedPageType;
@property (nonatomic, assign) NSInteger numPages;
@property (nonatomic, strong, nullable) UIColor *pageColor;
@property (nonatomic, copy) NSString *pageSizeName;

@property (nonatomic) NSArray<NSNumber*> *defaultPageTemplates;
@property (nonatomic) NSDictionary<NSString*, NSValue*> *defaultPageSizes;
@property (nonatomic) NSArray<UIColor*> *defaultPageColors;

@property (nonatomic, strong) NSIndexPath* pageTemplateIndexPath;
@property (nonatomic, strong) NSIndexPath* pageSizeIndexPath;
@property (nonatomic, strong) NSIndexPath* pageSizePickerIndexPath;
@property (nonatomic, strong) NSIndexPath* pageColorIndexPath;
@property (nonatomic, strong) NSIndexPath* pageOrientationIndexPath;
@property (nonatomic, strong) NSIndexPath* pageCountIndexPath;
@property (nonatomic, strong) NSIndexPath* pageNumberIndexPath;

// Feedback generator.
@property (nonatomic, strong, nullable) UISelectionFeedbackGenerator *selectionFeedbackGenerator;
@end

static const int tableViewInset = 0;
static const int templatesPerPage = 5;
static const CGFloat pickerCellHeight = 180;

@implementation PTPageTemplateViewController

static NSString * const PTPageTemplatesTableViewCell_reuseID = @"PTPageTemplatesTableViewCell";
static NSString * const PTPageColorTableViewCell_reuseID = @"PTPageColorTableViewCell";

@synthesize defaultPageSize = _defaultPageSize;
#pragma mark - Initialization

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pageTemplateIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        _pageSizeIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        _pageSizePickerIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
        _pageColorIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];
        _pageOrientationIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
        _pageCountIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
        _pageNumberIndexPath = [NSIndexPath indexPathForRow:6 inSection:0];

        _pdfViewCtrl = pdfViewCtrl;
        _pageNumber = pdfViewCtrl.GetCurrentPage;
        self.defaultPageTemplates = @[@(PTPageTemplateStyleBlank),
                                      @(PTPageTemplateStyleLined),
                                      @(PTPageTemplateStyleGrid),
                                      @(PTPageTemplateStyleGraph),
                                      @(PTPageTemplateStyleDotted),
                                      @(PTPageTemplateStyleIsometricDotted),
                                      @(PTPageTemplateStyleMusic)];
        _pageTemplates = [self.defaultPageTemplates copy];
        _selectedPageType = (PTPageTemplateStyle)[_pageTemplates.firstObject integerValue];

        self.defaultPageSizes = @{
            @"US Letter": [NSValue valueWithCGSize:CGSizeMake(8.5, 11)],
            @"Legal": [NSValue valueWithCGSize:CGSizeMake(8.5, 14)],
            @"A4": [NSValue valueWithCGSize:CGSizeMake(8.27, 11.69)],
            @"A3": [NSValue valueWithCGSize:CGSizeMake(11.69, 16.54)],
            @"Ledger": [NSValue valueWithCGSize:CGSizeMake(11, 17)]};
        _pageSizes = [self.defaultPageSizes copy];

        self.defaultPageColors = [NSArray arrayWithObjects:PTAddPagesManager.whitePageColor, PTAddPagesManager.yellowPageColor, PTAddPagesManager.blueprintPageColor, nil];
        _pageColors = [self.defaultPageColors copy];
        _pageColor = _pageColors.firstObject;
    }
    return self;
}

#pragma mark - Setters

- (void)setPageTemplates:(NSArray<NSNumber *> *)pageTemplates
{
    if ([_pageTemplates isEqualToArray:pageTemplates]) {
        return;
    }
    _pageTemplates = pageTemplates;
    if (pageTemplates.count < 1) {
        _pageTemplates = self.defaultPageTemplates;
    }
}

- (void)setPageColors:(NSArray<UIColor *> *)pageColors
{
    if ([_pageColors isEqualToArray:pageColors]){
        return;
    }
    _pageColors = [pageColors copy];
    if (pageColors.count < 1) {
        // Reset to defaults if array is nil or empty
        _pageColors = [NSArray arrayWithObjects:PTAddPagesManager.whitePageColor, PTAddPagesManager.yellowPageColor, PTAddPagesManager.blueprintPageColor, nil];
    }
    if (![_pageColors containsObject:self.pageColor]) {
        self.pageColor = _pageColors.firstObject;
    }
}

- (void)setPageSizes:(NSDictionary<NSString *,NSValue *> *)pageSizes
{
    if ([_pageSizes isEqualToDictionary:pageSizes]) {
        return;
    }
    _pageSizes = [pageSizes copy];
    if (pageSizes.count < 1) {
        // Reset to defaults if dictionary is nil or empty
        _pageSizes = [self.defaultPageSizes copy];
    }
    [self.pageSizePicker reloadAllComponents];
}

- (void)setPageSizeName:(NSString *)pageSizeName
{
    _pageSizeName = pageSizeName;
    UITableViewCell *pageSizeCell = [self.tableView cellForRowAtIndexPath:self.pageSizeIndexPath];
    pageSizeCell.detailTextLabel.text = [self pageStringWithDimensions:pageSizeName];
}

-(NSString*)dimensionsForPage:(NSString*)pageString{
    CGSize value = [self.pageSizes[pageString] CGSizeValue];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.maximumFractionDigits = 2;
    CGFloat width = value.width;
    CGFloat height = value.height;
    NSString *widthString = [formatter stringFromNumber:[NSNumber numberWithFloat:width]];
    NSString *heightString = [formatter stringFromNumber:[NSNumber numberWithFloat:height]];
    NSString *dimensions = [NSString stringWithFormat:@"%@\" x %@\"", widthString,heightString];
    if ([pageString isEqualToString:@"A4"]) {
        dimensions = [NSString stringWithFormat:@"%i x %i mm", 210, 297];
    }
    if ([pageString isEqualToString:@"A3"]) {
        dimensions = [NSString stringWithFormat:@"%i x %i mm", 297, 420];
    }
    return dimensions;
}

-(NSString*)pageStringWithDimensions:(NSString*)pageString{
    NSString *dimensions = [self dimensionsForPage:pageString];
    NSString *combinedString = [NSString stringWithFormat:@"%@ (%@)",pageString,dimensions];
    return combinedString;
}

- (void)setDefaultPageSize:(NSString *)defaultPageSize
{
    if ([_defaultPageSize isEqualToString:defaultPageSize]){
        return;
    }
    _defaultPageSize = defaultPageSize;
    if (![self.pageSizes objectForKey:defaultPageSize]) {
        // Trying to set a default page size that does not exist in the dictionary of possible sizes
        _defaultPageSize = self.sortedPageSizeKeys.firstObject;
    }
}

-(NSString*)defaultPageSize{
    if (_defaultPageSize) {
        return _defaultPageSize;
    }
    NSString *localeDefault = @"A4";
    NSString* countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    if ([countryCode isEqualToString:@"US"]||
        [countryCode isEqualToString:@"CA"]||
        [countryCode isEqualToString:@"MX"]||
        [countryCode isEqualToString:@"CU"]||
        [countryCode isEqualToString:@"DO"]||
        [countryCode isEqualToString:@"GT"]||
        [countryCode isEqualToString:@"CR"]||
        [countryCode isEqualToString:@"SV"]||
        [countryCode isEqualToString:@"HN"]||
        [countryCode isEqualToString:@"BO"]||
        [countryCode isEqualToString:@"CO"]||
        [countryCode isEqualToString:@"VE"]||
        [countryCode isEqualToString:@"PH"]||
        [countryCode isEqualToString:@"CL"] ){
        localeDefault = @"US Letter";
        }
    if ([self.pageSizes.allKeys containsObject:localeDefault]) {
        return localeDefault;
    }
    return self.sortedPageSizeKeys.firstObject;
}

- (NSArray<NSString *> *)sortedPageSizeKeys
{
    return [self.pageSizes.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

- (UIStepper *)pageCountStepper
{
    if (!_pageCountStepper) {
        _pageCountStepper = [[UIStepper alloc] init];
        _pageCountStepper.minimumValue = 1;
        _pageCountStepper.value = 1;
        self.numPages = 1;
        [_pageCountStepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _pageCountStepper;
}

#pragma mark - Changes
-(void)stepperValueChanged:(UIStepper*)stepper
{
    [self.selectionFeedbackGenerator selectionChanged];
    self.numPages = (int)stepper.value;
    [self setPageCountLabel];
}

- (void)orientationChanged:(UISegmentedControl *)segmentedControl
{
    [self.selectionFeedbackGenerator selectionChanged];
}

-(void)setPageCountLabel
{
    int nPages = (int)self.pageCountStepper.value;
    UITableViewCell *pageCountCell = [self.tableView cellForRowAtIndexPath:self.pageCountIndexPath];
    pageCountCell.detailTextLabel.text = [NSString stringWithFormat:@"%i",nPages];
}

-(void)togglePickerView
{
    self.pickerVisible = !self.pickerVisible;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[self.pageSizePickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

#pragma mark - View Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[PTPageTemplatesTableViewCell class] forCellReuseIdentifier:PTPageTemplatesTableViewCell_reuseID];
    [self.tableView registerClass:[PTPageColorTableViewCell class] forCellReuseIdentifier:PTPageColorTableViewCell_reuseID];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    UIBarButtonItem *addPagesButton = [[UIBarButtonItem alloc] initWithTitle:PTLocalizedString(@"Add", @"Add pages add button title")
                                                                style:UIBarButtonItemStyleDone
                                                                target:self
                                                                action:@selector(addPagesButtonPressed)];
    self.navigationItem.rightBarButtonItem = addPagesButton;
    self.title = PTLocalizedString(@"Add Pages", @"Add Pages Control Title");
    self.tableView.alwaysBounceVertical = NO;

    [self.pageTemplatesCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)self.selectedPageType inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionLeft];
    self.pageSizeName = [self defaultPageSize];
    UIImage *portraitImage = [PTToolsUtil toolImageNamed:@"ic_view_mode_single_black_24dp"];
    UIImage *landscapeImage = [PTToolsUtil toolImageNamed:@"ic_page_orientation_landscape_24dp"];
    self.orientationControl = [[UISegmentedControl alloc] initWithItems:@[portraitImage, landscapeImage]];
    CGSize pageDimensions = [[self.pageSizes objectForKey:self.pageSizeName] CGSizeValue];
    self.orientationControl.selectedSegmentIndex = pageDimensions.width > pageDimensions.height ? 1 : 0;
    [self.orientationControl addTarget:self action:@selector(orientationChanged:) forControlEvents:UIControlEventValueChanged];
    // Hide empty rows below the last row
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.contentInset = UIEdgeInsetsMake(tableViewInset, 0, tableViewInset, 0);
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.selectionFeedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
    [self.selectionFeedbackGenerator prepare];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.selectionFeedbackGenerator = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == self.pageTemplateIndexPath) {
        PTPageTemplatesTableViewCell *cell = (PTPageTemplatesTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PTPageTemplatesTableViewCell_reuseID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
        self.pageTemplatesCollectionView = cell.collectionView;
        NSInteger templateIndex = [self.pageTemplates indexOfObject:[NSNumber numberWithInteger:self.selectedPageType]];
        NSIndexPath *indexPathToSelect = [NSIndexPath indexPathForItem:templateIndex inSection:0];
        if (![cell.collectionView.indexPathsForSelectedItems containsObject:indexPathToSelect]) {
            [cell.collectionView selectItemAtIndexPath:indexPathToSelect animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        }
        cell.tintColor = tableView.tintColor;
        return cell;
    } else if (indexPath == self.pageSizeIndexPath){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.textLabel.text = PTLocalizedString(@"Page Size", @"Add Page Template page size label");
        cell.detailTextLabel.text = [self pageStringWithDimensions:self.pageSizeName];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        return cell;
    } else if (indexPath == self.pageSizePickerIndexPath){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        self.pageSizePicker = [[UIPickerView alloc] init];
        self.pageSizePicker.delegate = self;
        self.pageSizePicker.dataSource = self;
        self.pageSizePicker.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:self.pageSizePicker];
        [NSLayoutConstraint activateConstraints:@[
            [self.pageSizePicker.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor],
            [self.pageSizePicker.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            [self.pageSizePicker.widthAnchor constraintEqualToAnchor:cell.contentView.widthAnchor],
            [self.pageSizePicker.heightAnchor constraintEqualToAnchor:cell.contentView.heightAnchor]]];
        if ([self.sortedPageSizeKeys containsObject:self.pageSizeName]) {
            NSInteger index = [self.sortedPageSizeKeys indexOfObject:self.pageSizeName];
            [self.pageSizePicker selectRow:index inComponent:0 animated:NO];
        }
        return cell;
    } else if (indexPath == self.pageColorIndexPath){
        PTPageColorTableViewCell *cell = (PTPageColorTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PTPageColorTableViewCell_reuseID];
        [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = PTLocalizedString(@"Background Color", @"Add Page Template background color label");
        self.pageColorCollectionView = cell.collectionView;
        [cell.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:[self.pageColors indexOfObject:self.pageColor] inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        cell.tintColor = tableView.tintColor;
        return cell;
    } else if (indexPath == self.pageOrientationIndexPath){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = PTLocalizedString(@"Orientation", @"Add Page Template page orientation label");
        cell.accessoryView = self.orientationControl;
        return cell;
    } else if (indexPath == self.pageCountIndexPath){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryView = self.pageCountStepper;
        cell.textLabel.text = PTLocalizedString(@"Number of Pages", @"Add Page Template page count label");
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i",(int)self.pageCountStepper.value];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        return cell;
    } else if (indexPath == self.pageNumberIndexPath){
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = PTLocalizedString(@"After Page Number", @"Add Page Template page page number label");
        self.pageNumberTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        self.pageNumberTextField.textAlignment = NSTextAlignmentRight;
        self.pageNumberTextField.keyboardType = UIKeyboardTypeNumberPad;
        self.pageNumberTextField.delegate = self;
        cell.accessoryView = self.pageNumberTextField;
        self.pageNumberTextField.placeholder = [NSString stringWithFormat:@"0 – %i",[self.pdfViewCtrl GetPageCount]];
        self.pageNumberTextField.text = [NSString stringWithFormat:@"%i",[self.pdfViewCtrl GetCurrentPage]];
        if (!PT_ToolsMacCatalyst) { // This causes a weird UI glitch on macOS and the whole view is blank
            cell.separatorInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, CGFLOAT_MAX);
        }
        return cell;
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath == self.pageSizeIndexPath) {
        [self togglePickerView];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet].location != NSNotFound){
        return NO;
    }
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    int pageNumber = [newString intValue];
    BOOL pageNumberOK = pageNumber >= 0 && pageNumber <= [self.pdfViewCtrl GetPageCount];
    if (pageNumberOK) {
        self.pageNumber = pageNumber;
    }
    return pageNumberOK;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.pageNumberTextField && textField.text.length < 1) {
        self.pageNumberTextField.text = [NSString stringWithFormat:@"%i",self.pageNumber];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == self.pageTemplateIndexPath) {
        /**
         * Todo: use self-sizing UICollectionViewCells AND UITableViewCells instead?
         * Preview image height is 3/2 the width of the collection view cell
         * The cell height (row height) is 3/2 the height of the preview image
         * The width of the cell is 1/5 the width of the tableView
         * All of the above ignore spacing.
        */
        return (tableView.frame.size.width/templatesPerPage)*(3.0/2.0)*(3.0/2.0);
    }
    if (indexPath == self.pageSizePickerIndexPath) {
        return self.pickerVisible ? pickerCellHeight : 0;
    }
    return 50.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == self.pageTemplateIndexPath) {
        // See sizing notes in `tableView estimatedHeightForRowAtIndexPath` method
        return (tableView.frame.size.width/templatesPerPage)*(3.0/2.0)*(3.0/2.0);
    }
    if (indexPath == self.pageSizePickerIndexPath) {
        return self.pickerVisible ? pickerCellHeight : 0;
    }
    return 50.0;
}

#pragma mark - Collection View Data Source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.pageColorCollectionView) {
        PTPageColorCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PTPageColorCollectionViewCell_reuseID forIndexPath:indexPath];
        cell.backgroundColor = [self.pageColors objectAtIndex:indexPath.item];
        return cell;
    } else {
        PTPageTemplateCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PTPageTemplateCollectionViewCell_reuseID forIndexPath:indexPath];
        cell.layer.masksToBounds = YES;
        NSNumber *pageTemplate = [self.pageTemplates objectAtIndex:indexPath.item];
        NSDictionary<NSNumber *, NSString *> *pageTemplateImageNames =
        @{
          @(PTPageTemplateStyleBlank) : @"", // Don't need to load a blank page image preview
          @(PTPageTemplateStyleLined) : @"linedPagePreview",
          @(PTPageTemplateStyleGrid)  : @"gridPagePreview",
          @(PTPageTemplateStyleGraph) : @"graphPagePreview",
          @(PTPageTemplateStyleMusic) : @"musicPagePreview",
          @(PTPageTemplateStyleDotted) : @"dottedPagePreview",
          @(PTPageTemplateStyleIsometricDotted) : @"dottedIsoPagePreview"};

        NSDictionary<NSNumber *, NSString *> *pageTemplateNames =
        @{
          @(PTPageTemplateStyleBlank) : PTLocalizedString(@"Blank",@"Blank page template name"),
          @(PTPageTemplateStyleLined) : PTLocalizedString(@"Lined",@"Lined page template name"),
          @(PTPageTemplateStyleGrid)  : PTLocalizedString(@"Grid",@"Grid page template name"),
          @(PTPageTemplateStyleGraph) : PTLocalizedString(@"Graph",@"Graph page template name"),
          @(PTPageTemplateStyleMusic) : PTLocalizedString(@"Music",@"Music page template name"),
          @(PTPageTemplateStyleDotted) : PTLocalizedString(@"Dotted",@"Dotted page template name"),
          @(PTPageTemplateStyleIsometricDotted) : PTLocalizedString(@"Iso",@"Isometric dotted page template name")};

        NSString *imageName = [pageTemplateImageNames objectForKey:pageTemplate];
        if (imageName.length > 0) {
            UIImage *image = [[PTToolsUtil toolImageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIColor *blueprintPageColor = PTAddPagesManager.blueprintPageColor;
            BOOL isBlueprint = [self.pageColor pt_isEqualToColor:blueprintPageColor];
            double lineShade = isBlueprint ? 0.85 : 0.35;
            UIColor *lineColor = [UIColor colorWithWhite:lineShade alpha:1.0];
            cell.templatePreview.tintColor = lineColor;
            cell.templatePreview.image = image;
        }else{
            cell.templatePreview.image = nil;
        }
        cell.templatePreview.backgroundColor = self.pageColor;

        NSString *templateName = [pageTemplateNames objectForKey:pageTemplate];
        if (templateName.length > 0) {
            cell.templateLabel.text = templateName;
        }
        return cell;
    }
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.pageColorCollectionView) {
        return self.pageColors.count;
    }
    return self.pageTemplates.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectionFeedbackGenerator selectionChanged];
    if (collectionView == self.pageColorCollectionView) {
        self.pageColor = [self.pageColorCollectionView cellForItemAtIndexPath:indexPath].backgroundColor;
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[self.pageTemplateIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }else{
        self.selectedPageType = (PTPageTemplateStyle)[[self.pageTemplates objectAtIndex:indexPath.item] integerValue];
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat totalWidth = collectionView.bounds.size.width;
    CGFloat spacing = 10;
    if (collectionView == self.pageColorCollectionView) {
        int itemsPerPage = MIN((int)self.pageColors.count, 3);
        CGFloat height = collectionView.bounds.size.height*0.6;
        CGFloat width = (totalWidth - ((2 * spacing) + ((itemsPerPage - 1) * spacing)))/itemsPerPage;
        CGFloat size = MIN(height, width);
        return CGSizeMake(size, size);
    }else{
        CGFloat itemsPerPage = templatesPerPage - 0.5;
        CGFloat width = (totalWidth - ((2 * spacing) + ((itemsPerPage - 1) * spacing)))/itemsPerPage;
        return CGSizeMake(width, collectionView.bounds.size.height-(2*spacing));
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat totalWidth = collectionView.bounds.size.width;
    CGFloat spacing = 10;
    if (collectionView == self.pageColorCollectionView) {
        CGFloat itemsPerPage = MIN((int)self.pageColors.count, 3.2);
        if (itemsPerPage < 2) {
            return 0;
        }
        CGFloat height = collectionView.bounds.size.height*0.6;
        CGFloat width = (totalWidth - ((2 * spacing) + ((itemsPerPage - 1) * spacing)))/itemsPerPage;
        CGFloat size = MIN(height, width);
        CGFloat internalSpace = totalWidth - (2*spacing) - (itemsPerPage*size);
        CGFloat interitemSpacing = internalSpace / (itemsPerPage-1);
        return interitemSpacing;
    }else{
        return 10;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

#pragma mark - Actions

-(void)cancelButtonPressed
{
    if ([self.delegate respondsToSelector:@selector(pageTemplateViewControllerDidCancel:)]) {
        [self.delegate pageTemplateViewControllerDidCancel:self];
    }
}

-(void)addPagesButtonPressed
{
    PTPageTemplateStyle pageTemplate = self.selectedPageType;
    CGSize pageSize = [[self.pageSizes objectForKey:self.pageSizeName] CGSizeValue];
    UIColor *backgroundColor = self.pageColor;
    int pageCount = (int)self.numPages;
    BOOL portrait = self.orientationControl.selectedSegmentIndex == 0;

    PTPDFDoc *newDoc = [PTAddPagesManager createDocWithTemplate:pageTemplate pageSize:pageSize backgroundColor:backgroundColor pageCount:pageCount portrait:portrait];
    if ([self.delegate respondsToSelector:@selector(pageTemplateViewController:createdDoc:)]) {
        [self.delegate pageTemplateViewController:self createdDoc:newDoc];
    }
}

#pragma mark - UIPickerView Delegate

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.pageSizes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSString *pageSizeKey = [self.sortedPageSizeKeys objectAtIndex:row];
    NSString *pageSizeString = [self pageStringWithDimensions:pageSizeKey];
    return pageSizeString;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.pageSizeName = [self.sortedPageSizeKeys objectAtIndex:row];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    cell.detailTextLabel.text = [self pageStringWithDimensions:self.pageSizeName];
}

@end
