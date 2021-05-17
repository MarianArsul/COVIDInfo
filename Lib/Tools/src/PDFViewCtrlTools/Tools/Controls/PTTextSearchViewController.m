//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextSearchViewController.h"

#import "PTSearchOperation.h"

#import "UIGeometry+PTAdditions.h"
#import "PTToolsUtil.h"
#import "PTTouchForwardingView.h"
#import "UIView+PTAdditions.h"
#import "UIViewController+PTAdditions.h"

static NSString * const PTLastTextSearchString = @"PTLastTextSearchString";

@interface PTTextSearchViewController () <UISearchBarDelegate, UIToolbarDelegate, UITableViewDelegate, UITableViewDataSource, PTSearchOperationDelegate, UISearchBarDelegate, PTSearchSettingsViewControllerDelegate, UIPopoverPresentationControllerDelegate, PTToolManagerViewControllerPresentation>

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) PTTouchForwardingView *touchForwardingView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIToolbar *searchModesToolbar;

@property (nonatomic, strong) NSLayoutConstraint *toolBarBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *searchModesToolBarBottomConstraint;

@property (nonatomic, assign) BOOL constraintsLoaded;

@property (nonatomic, strong) UIButton *toolbarDoneButton;
@property (nonatomic, strong) UIButton *prevResultButton, *nextResultButton;
@property (nonatomic, strong) UIButton *resultLabel;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *listButton;

@property (nonatomic, strong) NSArray *sortedPageNumbers;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<PTExtendedSearchResult *> *> *results;
@property (nonatomic, strong) NSMutableArray *allResults;
@property (nonatomic, strong) PTExtendedSearchResult *currentResult;
@property (nonatomic) int pageResultIndex, fileResultIndex;

@property (nonatomic, strong) NSOperationQueue *searchQueue;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL searchCompleted;

@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSMutableArray*>* highlightViewsOnPage;
@property (nonatomic, strong) NSMutableArray<UIView*>* highlightViews;

@property (nonatomic) UIViewPropertyAnimator *popAnimation;

@end

@implementation PTTextSearchViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        _touchForwardingView = [[PTTouchForwardingView alloc] init];
        _searchQueue = [[NSOperationQueue alloc] init];
        _activityIndicator = [[UIActivityIndicatorView alloc] init];
        _highlightViews = [[NSMutableArray alloc] init];
        _highlightViewsOnPage = [[NSMutableDictionary alloc] init];
        _showsKeyboardOnViewDidAppear = YES;
    }
    return self;
}

- (UIStackView *)stackView{
    if (!_stackView) {
        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.distribution = UIStackViewDistributionFill;
        _stackView.spacing = 10;
        self.toolbarDoneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.toolbarDoneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]];
        [self.toolbarDoneButton setTitle:PTLocalizedString(@"Done", @"Done button title text in PTTextSearchViewController") forState:UIControlStateNormal];
        [self.toolbarDoneButton addTarget:self action:@selector(doneButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_stackView addArrangedSubview:self.toolbarDoneButton];

        [_stackView addArrangedSubview:self.searchBar];
    }
    return _stackView;
}

- (UISearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _searchBar.delegate = self;
        _searchBar.inputAssistantItem.leadingBarButtonGroups = @[];
        _searchBar.inputAssistantItem.trailingBarButtonGroups = @[];
        _searchBar.searchBarStyle = UISearchBarStyleMinimal;
        _searchBar.placeholder = PTLocalizedString(@"Search", @"Search bar placeholder text in PTTextSearchViewController");
        _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        if (@available(iOS 13.0, *)) {
            self.searchField = _searchBar.searchTextField;
        }
        else{
            for(UIView* view in _searchBar.subviews.firstObject.subviews){
                if([view isKindOfClass:[UITextField class]]){
                    self.searchField = (UITextField *)view;
                    break;
                }
            }
        }
        self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.searchField.rightViewMode = UITextFieldViewModeUnlessEditing;
    }
    return _searchBar;
}

- (PTSearchSettingsViewController *)searchSettingsViewController
{
    if(!_searchSettingsViewController){
        _searchSettingsViewController = [[PTSearchSettingsViewController allocOverridden] init];
        _searchSettingsViewController.delegate = self;
    }
    return _searchSettingsViewController;
}

#pragma mark - Configure View

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchCompleted = NO;
    self.touchForwardingView.frame = self.view.bounds;
    self.touchForwardingView.passthroughViews = @[self.presentingViewController.view];
    [self.view addSubview:self.touchForwardingView];
    self.title = PTLocalizedString(@"Search", @"Title of PTTextSearchViewController");
    self.extendedLayoutIncludesOpaqueBars = !self.navigationController.navigationBar.translucent;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellIdentifier"];
    
    [self.activityIndicator setHidesWhenStopped:YES];
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    self.toolbar.delegate = self;
    [self.toolbar setTranslucent:YES];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toolbar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny];
    self.toolbar.barTintColor = nil;
    UIBarButtonItem *stackViewItem = [[UIBarButtonItem alloc] initWithCustomView:self.stackView];
    [self.toolbar setItems:@[stackViewItem]];

    [self initButtons];
    [self layoutStackView];
    [self.view addSubview:self.toolbar];
    
    if (@available(iOS 11, *)) {
        self.toolBarBottomConstraint = [self.toolbar.bottomAnchor constraintEqualToAnchor:self.toolbar.superview.safeAreaLayoutGuide.bottomAnchor];
    }else{
        self.toolBarBottomConstraint = [self.toolbar.bottomAnchor constraintEqualToAnchor:self.toolbar.superview.bottomAnchor];
    }
    
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints
{
    if (!self.constraintsLoaded) {
        [NSLayoutConstraint activateConstraints:
         @[
             [self.toolbar.widthAnchor constraintEqualToAnchor:self.toolbar.superview.widthAnchor],
             [self.toolbar.centerXAnchor constraintEqualToAnchor:self.toolbar.superview.centerXAnchor],
             self.toolBarBottomConstraint,
         ]];
        
        self.constraintsLoaded = YES;
    }
    
    // Call super implementation as final step.
    [super updateViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.searchCompleted = NO;
    [self layoutStackView];
    [self.navigationController setNavigationBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShowOrHide:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShowOrHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [self.view setNeedsUpdateConstraints];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.showsKeyboardOnViewDidAppear) {
            [self.searchBar becomeFirstResponder];
        }
        if ( [[NSUserDefaults standardUserDefaults] objectForKey:PTLastTextSearchString]) {
            self.searchBar.text = [[NSUserDefaults standardUserDefaults] stringForKey:PTLastTextSearchString];
            [UIApplication.sharedApplication sendAction:@selector(selectAll:) to:nil from:nil forEvent:nil];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.view endEditing:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.searchBar.text = @"";
    [self clearSearch];
    if ([self.delegate respondsToSelector:@selector(searchViewControllerDidDismiss:)]) {
        [self.delegate searchViewControllerDidDismiss:self];
    }
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    [self setListButtonSelected:NO];
}

-(BOOL)isPopover
{
    
    // https://stackoverflow.com/a/31656088

    if (self.navigationController.popoverPresentationController.barButtonItem || (self.navigationController.popoverPresentationController.sourceView && !CGRectIsEmpty(self.navigationController.popoverPresentationController.sourceRect))) {
        return YES;
    }
    return NO;
}

#pragma mark - Configure Buttons

-(void)initButtons
{
    // Search settings button
    UIImage *settingsImage = [PTToolsUtil toolImageNamed:@"ic_search_settings_black_24px.png"];
    settingsImage = [settingsImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.settingsButton setImage:settingsImage forState:UIControlStateNormal];
    [self.settingsButton setImageEdgeInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    [self.settingsButton addTarget:self action:@selector(showSearchSettings:) forControlEvents:UIControlEventTouchUpInside];
    self.settingsButton.imageView.tintColor = self.searchField.leftView.tintColor;

    CGFloat imgEdgeInsets = 2.0;
    if (@available(iOS 13.0, *)) {
    }else{
        self.settingsButton.imageView.tintColor = [UIColor grayColor];
        self.settingsButton.frame = self.searchField.leftView.frame;
        imgEdgeInsets *= -1;
    }
    [self.settingsButton setImageEdgeInsets:UIEdgeInsetsMake(imgEdgeInsets,imgEdgeInsets,imgEdgeInsets,imgEdgeInsets)];
    self.searchField.leftView = self.settingsButton;

    // Search results label
    self.resultLabel = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.resultLabel setTitle:@"" forState:UIControlStateNormal | UIControlStateDisabled];
    [self.resultLabel.titleLabel setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];

    self.resultLabel.layer.cornerRadius = 4.0;
    self.resultLabel.layer.masksToBounds = YES;
    self.resultLabel.contentEdgeInsets = PTUIEdgeInsetsMakeUniform(self.resultLabel.layer.cornerRadius);
    UIColor *resultLabelColor = [UIColor blackColor];
    UIColor *resultLabelColorSelected = [UIColor whiteColor];
    UIColor *noResultsColor = [UIColor redColor];
    if (@available(iOS 13.0, *)) {
        resultLabelColor = [UIColor colorNamed:@"UIFGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
        resultLabelColorSelected = [UIColor colorNamed:@"UIBGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
        noResultsColor = [UIColor systemRedColor];
    }
    [self.resultLabel setTitleColor:resultLabelColor forState:UIControlStateNormal];
    [self.resultLabel setTitleColor:noResultsColor forState:UIControlStateDisabled];
    [self.resultLabel setTitleColor:resultLabelColorSelected forState:UIControlStateSelected];
//    [self.resultLabel addTarget:self action:@selector(toggleListView) forControlEvents:UIControlEventTouchUpInside];

    // Prev/next result buttons
    UIImage *prevImage = [PTToolsUtil toolImageNamed:@"ic_chevron_up_black_24px.png"];
    UIImage *nextImage = [PTToolsUtil toolImageNamed:@"ic_chevron_down_black_24px.png"];
    if (@available(iOS 13.0, *)) {
        prevImage = [UIImage systemImageNamed:@"chevron.up" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        nextImage = [UIImage systemImageNamed:@"chevron.down" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
    }
    self.prevResultButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.prevResultButton setImage:prevImage forState:UIControlStateNormal];
    [self.prevResultButton setContentEdgeInsets:UIEdgeInsetsMake(10,10,10,10)];
    [self.prevResultButton addTarget:self action:@selector(prevResult) forControlEvents:UIControlEventTouchUpInside];

    self.nextResultButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextResultButton setImage:nextImage forState:UIControlStateNormal];
    [self.nextResultButton setContentEdgeInsets:UIEdgeInsetsMake(10,10,10,10)];
    [self.nextResultButton addTarget:self action:@selector(nextResult) forControlEvents:UIControlEventTouchUpInside];

    UIImage *listImage = [PTToolsUtil toolImageNamed:@"ic_list_black_24px.png"];
    if (@available(iOS 13.0, *)) {
        listImage = [UIImage systemImageNamed:@"list.bullet" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
    }
    self.listButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.listButton setImage:listImage forState:UIControlStateNormal];
    [self.listButton addTarget:self action:@selector(toggleListView) forControlEvents:UIControlEventTouchUpInside];
    [self.listButton setContentEdgeInsets:UIEdgeInsetsMake(10,10,10,10)];
    self.listButton.layer.cornerRadius = 4.0;
    self.listButton.layer.masksToBounds = YES;
    self.listButton.contentEdgeInsets = PTUIEdgeInsetsMakeUniform(self.listButton.layer.cornerRadius);
}

-(void)layoutStackView{
    for (UIView *subView in self.stackView.arrangedSubviews) {
        if (subView != self.searchBar && subView != self.toolbarDoneButton) {
            [subView removeFromSuperview];
        }
    }
    NSMutableArray<UIView*> *trailingViews = [[NSMutableArray alloc] init];
    if (self.searchCompleted) {
        if (self.allResults.count > 0){
            [trailingViews addObject:self.prevResultButton];
            [trailingViews addObject:self.nextResultButton];
        }
    }else{
        [trailingViews addObject:self.activityIndicator];
    }
    if (self.searchCompleted && self.allResults.count > 0) {
        [trailingViews addObject:self.listButton];
    }
    for (UIView* view in trailingViews) {
        [self.stackView addArrangedSubview:view];
    }
    [self updateResultsLabel];
}

-(void)updateResultsLabel{
    NSString *resultsString = @"";

    NSString *format = PTLocalizedString(@"%i/%i", @"PTTextSearchViewController results count string");
    NSString *count = [NSString localizedStringWithFormat:format, self.fileResultIndex+1,(int)self.allResults.count];

    if (self.searchCompleted) {
        if (self.allResults.count > 0){
            [self.resultLabel setEnabled:YES];
            resultsString = count;
        }else{
            if(self.searchBar.text.length != 0){
                resultsString = PTLocalizedString(@"No Results", @"PTTextSearchViewController no results found string");
            }
            [self.resultLabel setEnabled:NO];
        }
    }
    [self.resultLabel setTitle:resultsString forState:UIControlStateNormal];
    [self.resultLabel setTitle:resultsString forState:UIControlStateDisabled];

    self.searchField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.searchField.rightView = self.resultLabel;
    [self.resultLabel sizeToFit];
}

-(void)doneButtonTapped
{
    [self.searchQueue cancelAllOperations];
    [self dismiss];
}

#pragma mark - Toggle Views

-(void)setListButtonSelected:(BOOL)selected
{
    UIColor *bgColor = selected ? self.toolbar.tintColor : nil;
    UIColor *listColorSelected = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        listColorSelected = [UIColor colorNamed:@"UIBGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
    }
    self.listButton.selected = selected;
    [self.listButton setBackgroundColor:bgColor];
    self.listButton.imageView.tintColor = selected ? listColorSelected : nil;

}

-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    [self setListButtonSelected:NO];
}

-(void)dismissListView:(UIBarButtonItem*)doneButton
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:Nil];
    [self setListButtonSelected:NO];
}

-(void)toggleListView
{
    [self.searchBar resignFirstResponder];
    [self.view layoutIfNeeded];
    if (self.currentResult) {
        NSNumber *currPage = [NSNumber numberWithInt:[self.currentResult.result GetPageNumber]];
        NSInteger currPageIndex = [self.sortedPageNumbers indexOfObject:currPage];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.pageResultIndex inSection:currPageIndex];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    
    UIViewController* listViewController;
    UIViewController* presentedController;

    listViewController = [[UIViewController alloc] init];
    self.tableView.frame = listViewController.view.bounds;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [listViewController.view addSubview:self.tableView];
    
    if( self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular )
    {
        presentedController = listViewController;
        presentedController.modalPresentationStyle = UIModalPresentationPopover;
        presentedController.popoverPresentationController.sourceView = self.listButton;
        presentedController.popoverPresentationController.delegate = self;
    }
    else
    {
        listViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                             target:self action:@selector(dismissListView:)];
                                                                                            
        listViewController.navigationItem.title = PTLocalizedString(@"Search Results", @"Search results");
        presentedController = [[UINavigationController alloc] initWithRootViewController:listViewController];
        presentedController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    
    
    
    // give a blur effct if desired
//    if (!UIAccessibilityIsReduceTransparencyEnabled())
//    {
//            self.tableView.backgroundColor = UIColor.clearColor;
//
//            UIBlurEffectStyle blurEffectStyle = UIBlurEffectStyleExtraLight;
//            if (@available(iOS 13.0, *)) {
//                blurEffectStyle = UIBlurEffectStyleSystemMaterial;
//            }
//            UIView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurEffectStyle]];
//            blurView.layer.cornerRadius = 4.0;
//            blurView.layer.masksToBounds = YES; // Required for UIVisualEffectView cornerRadius.
//
//
//            self.tableView.backgroundView = blurView;
//
//            //if inside a popover
//            presentedController.popoverPresentationController.backgroundColor = UIColor.clearColor;
//    }
    
    
    [self presentViewController:presentedController animated:YES completion:Nil];
    
    [self setListButtonSelected:YES];

    [self layoutStackView];
}

-(void)showSearchSettings:(UIButton*)button{
    self.searchSettingsViewController.modalPresentationStyle = UIModalPresentationPopover;
    self.searchSettingsViewController.popoverPresentationController.sourceView = button.superview;
    self.searchSettingsViewController.popoverPresentationController.sourceRect = button.frame;
    self.searchSettingsViewController.popoverPresentationController.delegate = self;
    self.searchSettingsViewController.popoverPresentationController.permittedArrowDirections = (UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown);
    [self presentViewController:self.searchSettingsViewController animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}

#pragma mark - Search Setup

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length == 0) {
        [self clearSearch];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self layoutStackView];
    if (@available(iOS 11.0, *)) {
        [self.stackView setCustomSpacing:0 afterView:self.searchBar];
        [self.stackView setCustomSpacing:0 afterView:self.prevResultButton];
        [self.stackView setCustomSpacing:0 afterView:self.nextResultButton];
    }

}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self layoutStackView];
    if (@available(iOS 11.0, *)) {
        [self.stackView setCustomSpacing:self.stackView.spacing afterView:self.searchBar];
        [self.stackView setCustomSpacing:self.stackView.spacing afterView:self.prevResultButton];
        [self.stackView setCustomSpacing:self.stackView.spacing afterView:self.nextResultButton];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self findText:searchBar.text];
}

#pragma mark - Search Operation

-(void)findText:(NSString *)searchString
{
    [self.searchBar resignFirstResponder];
    [[NSUserDefaults standardUserDefaults] setObject:searchString forKey:PTLastTextSearchString];
    self.searchCompleted = NO;
    [self.searchQueue cancelAllOperations];
    [self clearSearch];

    if (searchString.length == 0) {
        self.searchCompleted = YES;
        [self layoutStackView];
        return;
    }

    [self layoutStackView];
    [self.activityIndicator startAnimating];
    unsigned int mode = e_ptambient_string | e_ptpage_stop | e_pthighlight;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:PTTextSearchMatchCaseKey]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:PTTextSearchMatchCaseKey]) {
            mode |= e_ptcase_sensitive;
        }
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:PTTextSearchMatchWholeWordKey]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:PTTextSearchMatchWholeWordKey]) {
            mode |= e_ptwhole_word;
        }
    }

    NSNumber *searchModes = [NSNumber numberWithInt:mode];
    NSDictionary *searchParameters = @{@"pdfViewCtrl":self.pdfViewCtrl, @"searchString": searchString, @"mode": searchModes};
    PTSearchOperation *searchOperation = [[PTSearchOperation alloc] initWithData:searchParameters delegate:self];
    [self.searchQueue addOperation:searchOperation];
}

- (void)searchSettingsViewControllerDidToggleSearchMode:(PTSearchSettingsViewController *)searchSettingsViewController
{
    [self findText:self.searchBar.text];
}

#pragma mark - PTOperation Delegate

-(void)ptSearchOperationFinished:(PTSearchOperation *)ptOperation
{
    self.searchCompleted = YES;
    self.results = ptOperation.results;
    
    self.fileResultIndex = 0;
    self.pageResultIndex = 0;
    
    self.sortedPageNumbers = [self.results.allKeys sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSArray *arr in [self.results allValues]) {
        [self.allResults addObjectsFromArray:arr];
    }
    // Sort the array of all results
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"result.GetPageNumber"
                                                                   ascending:YES];
    [self.allResults sortUsingDescriptors:@[sortDescriptor]];
    
    if (![self.sortedPageNumbers containsObject:[NSNumber numberWithInt:[self.pdfViewCtrl GetCurrentPage]]] && self.allResults.count > 0) {
        NSUInteger index = [self.sortedPageNumbers indexOfObject:@([self.pdfViewCtrl GetCurrentPage])
                                  inSortedRange:NSMakeRange(0, self.sortedPageNumbers.count)
                                        options:NSBinarySearchingInsertionIndex
                                usingComparator:^(id object0, id object1) {
                                    int page0 = [object0 intValue];
                                    int page1 = [object1 intValue];
                                    if (page0 < page1) return NSOrderedAscending;
                                    else if (page0 > page1) return NSOrderedDescending;
                                    else return NSOrderedSame;
                                }];
        if (index == self.sortedPageNumbers.count) index = 0;
        [self.pdfViewCtrl SetCurrentPage:[self.sortedPageNumbers[index] intValue]];
    }
    
    NSArray *thisPage = [self.results objectForKey:[NSNumber numberWithInt:[self.pdfViewCtrl GetCurrentPage]]];
    self.currentResult = [thisPage objectAtIndex:self.pageResultIndex];
    self.fileResultIndex = (int)[self.allResults indexOfObjectIdenticalTo:self.currentResult];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.activityIndicator stopAnimating];
        [self.activityIndicator removeFromSuperview];
        [self layoutStackView];
        [self highlightResults];
        [self.tableView reloadData];
    }];
}

#pragma mark - Results

-(UIColor*)currentSearchResultColor
{
    return [UIColor orangeColor];
}

-(UIColor*)searchResultColor
{
    return (self.pdfViewCtrl.colorPostProcessMode == e_ptpostprocess_night_mode) ? [UIColor grayColor] : [UIColor yellowColor];
}

-(void)highlightResults
{
    if (self.allResults.count == 0) return;

    [self removeAllFloatingViews];
    
    for (PTExtendedSearchResult *extendedResult in self.allResults) {
        PTSearchResult *result = extendedResult.result;
        NSMutableArray<PTPDFRect *> *pageRects = extendedResult.rects;
        int pageNumber = [result GetPageNumber];

        PTPDFRect *pageRect = pageRects.firstObject;
        UIView *highlightView = [[UIView alloc] init];
        highlightView.layer.cornerRadius = 3;
        UIColor *backgroundColor = (self.currentResult.result == result) ? [self currentSearchResultColor] : [self searchResultColor];

        [self.pdfViewCtrl addFloatingView:highlightView toPage:pageNumber withPageRect:pageRect noZoom:NO];
        
        NSMutableArray* pageViews = self.highlightViewsOnPage[@(pageNumber)];
        if( !pageViews )
        {
            [self.highlightViewsOnPage setObject:[[NSMutableArray alloc] init] forKey:@(pageNumber)];
        }
        
        
        [self.highlightViewsOnPage[@(pageNumber)] addObject:highlightView];
        
        if (pageRects.count > 1) {
            for (int i = 1; i < pageRects.count; i++) {
                PTPDFRect *subRect = [pageRects objectAtIndex:i];
                CGRect screenSubRect = [self.pdfViewCtrl PDFRectPage2CGRectScreen:subRect PageNumber:pageNumber];
                screenSubRect = [highlightView convertRect:screenSubRect fromView:self.pdfViewCtrl];
                UIView *subView = [[UIView alloc] initWithFrame:screenSubRect];
                subView.layer.cornerRadius = 3;
                subView.backgroundColor = backgroundColor;
                [highlightView addSubview:subView];
            }
        }

        [self setColor:backgroundColor forHighlightView:highlightView];
        highlightView.layer.compositingFilter = (self.pdfViewCtrl.colorPostProcessMode == e_ptpostprocess_night_mode) ? @"screenBlendMode" : @"multiplyBlendMode";
    }
    if( [self.currentResult.result GetPageNumber] != self.pdfViewCtrl.currentPage )
    {
        [self.pdfViewCtrl SetCurrentPage:[self.currentResult.result GetPageNumber]];
    }
    UIView *highlightView = self.highlightViewsOnPage[[NSNumber numberWithInt:self.pdfViewCtrl.currentPage]][self.pageResultIndex];
    [self scrollToMakeVisible:highlightView onPage:self.pdfViewCtrl.currentPage];

}

-(void)setColor:(UIColor*)color forHighlightView:(UIView*)highlightView
{
    highlightView.backgroundColor = color;
    for (UIView *subView in highlightView.subviews) {
        subView.backgroundColor = color;
    }
    if ([color isEqual:[self currentSearchResultColor]]) {
        [self flashHighlight:highlightView completionHandler:nil];
    }
}

-(void)tempHideViews:(NSArray<UIView*>*)views
{
    [UIView animateKeyframesWithDuration:1.0f delay:0.0f options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0f relativeDuration:0.1f animations:^{
            for (UIView *view in views) {
                view.alpha = 0.15;
            }
        }];
        [UIView addKeyframeWithRelativeStartTime:0.4f relativeDuration:0.3f animations:^{
            for (UIView *view in views) {
                view.alpha = 0.75;
            }
        }];
        [UIView addKeyframeWithRelativeStartTime:0.7f relativeDuration:0.3f animations:^{
            for (UIView *view in views) {
                view.alpha = 1.0;
            }
        }];
    }completion:nil];
}

-(void)flashHighlight:(UIView *)highlightView completionHandler:(void (^)(BOOL))completionHandler
{
    
    if (highlightView.subviews.count > 0) {
        return;
    }
    self.popAnimation = [[UIViewPropertyAnimator alloc] initWithDuration:0.2f curve:UIViewAnimationCurveLinear animations:^{
        [UIView animateKeyframesWithDuration:self.popAnimation.duration delay:0.0f options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            [UIView addKeyframeWithRelativeStartTime:0.0f relativeDuration:0.2f animations:^{
                highlightView.transform = CGAffineTransformMakeScale(1.7, 1.7);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.2f relativeDuration:0.5f animations:^{
                highlightView.transform = CGAffineTransformMakeScale(1.2, 1.2);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.7f relativeDuration:0.3f animations:^{
                highlightView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
        }completion:nil];
    }];
    self.popAnimation.interruptible = YES;
    [self.popAnimation startAnimation];
}

-(void)prevResult
{
    NSNumber *currPage = [NSNumber numberWithInt:[self.currentResult.result GetPageNumber]];
    
    UIView* highlightView = self.highlightViewsOnPage[currPage][self.pageResultIndex];
    
    [self setColor:[self searchResultColor] forHighlightView:highlightView];

    [self.searchBar resignFirstResponder];
    
    NSInteger currPageIndex = [self.sortedPageNumbers indexOfObject:currPage];
    self.fileResultIndex -= 1;
    if (self.fileResultIndex < 0) {
        self.fileResultIndex = (int)self.allResults.count - 1;
    }
    if (self.pageResultIndex == 0) { // There is no result above this one on this page
        currPageIndex = currPageIndex == 0 ? self.sortedPageNumbers.count - 1 : currPageIndex - 1;
        NSArray *prevPageResults = self.results[self.sortedPageNumbers[currPageIndex]];
        self.pageResultIndex = (int)prevPageResults.count - 1;
    }else{
        self.pageResultIndex -= 1;
    }
    
    currPage = self.sortedPageNumbers[currPageIndex];
    self.currentResult = [self.allResults objectAtIndex:self.fileResultIndex];

    highlightView = self.highlightViewsOnPage[currPage][self.pageResultIndex];
    [self setColor:[self currentSearchResultColor] forHighlightView:highlightView];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.pageResultIndex inSection:currPageIndex];
    [self highlightEntry:indexPath];
    [self updateResultsLabel];

    if ([self.pdfViewCtrl GetCurrentPage] != [self.currentResult.result GetPageNumber]) {
        [self.pdfViewCtrl SetCurrentPage:[self.currentResult.result GetPageNumber]];
    }
    [self scrollToMakeVisible:highlightView onPage:[currPage intValue]];
}

-(void)nextResult
{

    [self.searchBar resignFirstResponder];
    NSNumber *currPage = [NSNumber numberWithInt:[self.currentResult.result GetPageNumber]];
    
    UIView* highlightView = self.highlightViewsOnPage[currPage][self.pageResultIndex];
     [self setColor:[self searchResultColor] forHighlightView:highlightView];
    NSInteger currPageIndex = [self.sortedPageNumbers indexOfObject:currPage];
    NSArray *thisPageResults = self.results[currPage];

    self.fileResultIndex += 1;
    if (self.fileResultIndex == self.allResults.count) {
        self.fileResultIndex = 0;
    }
    if (self.pageResultIndex + 1 < thisPageResults.count) { // There is another found result on this page.
        self.pageResultIndex += 1;
    }else{
        self.pageResultIndex = 0;
        currPageIndex += 1;
    }
    if (currPageIndex == self.sortedPageNumbers.count) { // We are on the last page of the doc. Loop round onto the first page.
        currPageIndex = 0;
    }
    currPage = self.sortedPageNumbers[currPageIndex];

    self.currentResult = [self.allResults objectAtIndex:self.fileResultIndex];
    
    highlightView = self.highlightViewsOnPage[currPage][self.pageResultIndex];
    [self setColor:[self currentSearchResultColor] forHighlightView:highlightView];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.pageResultIndex inSection:currPageIndex];
    [self highlightEntry:indexPath];
    [self updateResultsLabel];

    if ([self.pdfViewCtrl GetCurrentPage] != [self.currentResult.result GetPageNumber]) {
        [self.pdfViewCtrl SetCurrentPage:[self.currentResult.result GetPageNumber]];
    }
    [self scrollToMakeVisible:highlightView onPage:[currPage intValue]];
}

-(void)scrollToMakeVisible:(UIView*)view onPage:(int)page
{
    if( [self.pdfViewCtrl pagePresentationModeIsContinuous] == NO &&
       self.pdfViewCtrl.currentPage != page )
    {
        [self.pdfViewCtrl SetCurrentPage:page];
    }
    
    CGRect inflatedRect = CGRectInset(view.frame, -100, -100);
    
    
    [self.pdfViewCtrl.contentScrollView scrollRectToVisible:inflatedRect animated:YES];
}

-(void)highlightEntry:(NSIndexPath *)indexPath
{
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)removeAllFloatingViews
{
    for(NSArray* arrayOfViews in self.highlightViewsOnPage.allValues )
    {
        [self.pdfViewCtrl removeFloatingViews:arrayOfViews];
    }
    
    [self.highlightViewsOnPage removeAllObjects];
}

-(void)clearSearch
{
    self.results = [[NSMutableDictionary alloc] init];
    self.sortedPageNumbers = [[NSArray alloc] init];
    self.allResults = [[NSMutableArray alloc] init];
    self.searchBar.showsSearchResultsButton = NO;
    if (self.activityIndicator.animating) {
        [self.activityIndicator stopAnimating];
    }
    
    dispatch_async( dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.tableView.superview != nil) {
            [self.tableView layoutIfNeeded];
        }
        [self layoutStackView];
    });

    [self removeAllFloatingViews];
    [self.pdfViewCtrl CancelFindText];
 
}



#pragma mark - UISearchBar Delegate


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searchQueue cancelAllOperations];
    [self dismiss];
}

#pragma mark - TableView Data Source

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    PTExtendedSearchResult *extendedResult = self.results[self.sortedPageNumbers[indexPath.section]][indexPath.row];
    PTSearchResult *result = extendedResult.result;

    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    descriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:descriptor size:descriptor.pointSize];

    NSString *match = [result GetMatch];
    NSString *ambientString = [result GetAmbientString];
    NSRange matchRange = [ambientString rangeOfString:match];

    
    /*
    NSString *surroundingText;
    if (match.length == 1) {
        NSMutableArray<PTPDFRect *> *rects = extendedResult.rects;
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            PTPage *page = [[self.pdfViewCtrl GetDoc] GetPage:[result GetPageNumber]];
            PTTextExtractor* textExtractor = [[PTTextExtractor alloc] init];
            [textExtractor Begin:page clip_ptr:0 flags:0];

            PTPDFRect *rect1 = rects.firstObject;
            PTPDFRect *rect = [[PTPDFRect alloc] initWithX1:rect1.GetX1 y1:rect1.GetY1 x2:rect1.GetX2 y2:rect1.GetY2];
            double averageLetterWidth = rect.Width/match.length;
            [rect SetX1:[rect GetX1]-1*averageLetterWidth];
            [rect SetX2:[rect GetX2]+2*averageLetterWidth];
            PTAnnot *dummyAnnot = [PTAnnot Create:[[self.pdfViewCtrl GetDoc] GetSDFDoc] type:e_ptHighlight pos:rect];
            surroundingText = [textExtractor GetTextUnderAnnot:dummyAnnot];
            surroundingText = [surroundingText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        }
        @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
    }
    if ([ambientString containsString:surroundingText]) {
        NSRange matchRangeB = [ambientString rangeOfString:surroundingText];
        NSRange matchRangeC = [surroundingText rangeOfString:match];
        matchRange = NSMakeRange(matchRangeB.location+matchRangeC.location, matchRange.length);
    }
    */

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:ambientString];
    [attributedString addAttribute:NSFontAttributeName value:boldFont range:matchRange];
    [attributedString addAttribute:NSBackgroundColorAttributeName value:[UIColor yellowColor] range:matchRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:matchRange];

    cell.textLabel.attributedText = attributedString;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sortedPageNumbers.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.results[self.sortedPageNumbers[section]] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSNumber *pageNumber = self.sortedPageNumbers[section];
    NSString *format = PTLocalizedString(@"Page %d", @"Page number label in PTTextSearchViewController search results table section headers");
    NSString *pageNumberString = [NSString localizedStringWithFormat:format, [pageNumber intValue]];
    
    return pageNumberString;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (section == 0) ? 48 : 24;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.tableView.pt_viewController pt_isInPopover]){
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
        [self setListButtonSelected:NO];
    }
    
    UIView *highlightView = self.highlightViewsOnPage[@([self.currentResult.result GetPageNumber])][self.pageResultIndex];
    [self setColor:[self searchResultColor] forHighlightView:highlightView];
    PTExtendedSearchResult *extendedResult = self.results[self.sortedPageNumbers[indexPath.section]][indexPath.row];
    self.pageResultIndex = (int)indexPath.row;
    self.fileResultIndex = (int)[self.allResults indexOfObjectIdenticalTo:extendedResult];
    self.currentResult = extendedResult;
    highlightView = self.highlightViewsOnPage[@([self.currentResult.result GetPageNumber])][self.pageResultIndex];

    [self setColor:[self currentSearchResultColor] forHighlightView:highlightView];

    [self.pdfViewCtrl SetCurrentPage:[extendedResult.result GetPageNumber]];
    [self scrollToMakeVisible:highlightView onPage:[extendedResult.result GetPageNumber]];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

#pragma mark - Keyboard Animations

-(void)keyboardDidShowOrHide:(NSNotification *)notification
{
    [self.view layoutIfNeeded];
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    CGRect convertedEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.window];

    CGFloat heightDelta = CGRectGetMinY(convertedEndFrame) - CGRectGetMaxY(self.view.bounds);
    if (@available(iOS 11, *)) {
        heightDelta += heightDelta < 0 ? self.view.safeAreaInsets.bottom : 0;
    }

    if (![self isPopover]){
        self.toolBarBottomConstraint.constant = heightDelta;
        [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | animationCurve animations:^{
            [self.view layoutIfNeeded];
        } completion:nil];
    }
}


#pragma mark - PTToolManagerViewControllerPresentation Protocol

- (BOOL)prefersNavigationBarHidden{
    return YES;
}

@end
