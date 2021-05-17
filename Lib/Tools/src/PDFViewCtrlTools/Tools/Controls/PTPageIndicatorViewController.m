//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPageIndicatorViewController.h"
#import "PTToolManager.h"

#import "ToolsDefines.h"
#import "PTToolsUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTPageIndicatorViewController ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, copy, nullable) NSString *pageLabel;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, readonly, assign) unsigned int pageCount;

@property (nonatomic, readonly, strong) UIView *defaultBackgroundView;

@property (nonatomic, weak, nullable) UIAlertAction *okAlertAction;

@end

NS_ASSUME_NONNULL_END

@implementation PTPageIndicatorViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
    }
    return self;
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self initWithPDFViewCtrl:toolManager.pdfViewCtrl];
    if (self) {
        _toolManager = toolManager;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    // Background view.
    self.backgroundView = self.defaultBackgroundView;
    self.backgroundView.frame = self.view.bounds;
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view insertSubview:self.backgroundView atIndex:0];
    
    // Content view.
    self.contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentView.layoutMargins = UIEdgeInsetsMake(4, 8, 4, 8);
    
    if (@available(iOS 11.0, *)) {
        self.contentView.insetsLayoutMarginsFromSafeArea = NO;
    }
    
    [self.view addSubview:self.contentView];
    
    // Label view.
    self.label = [[UILabel alloc] initWithFrame:self.view.bounds];
    self.label.font = [UIFont systemFontOfSize:UIFont.smallSystemFontSize];
    
    [self.contentView addSubview:self.label];

    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *marginsGuide = self.contentView.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.label.leadingAnchor constraintEqualToAnchor:marginsGuide.leadingAnchor],
       [self.label.topAnchor constraintEqualToAnchor:marginsGuide.topAnchor],
       [self.label.widthAnchor constraintEqualToAnchor:marginsGuide.widthAnchor],
       [self.label.heightAnchor constraintEqualToAnchor:marginsGuide.heightAnchor],
       ]];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapActionWithGesture:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentPage = [self.pdfViewCtrl GetCurrentPage];

    [self updateLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.currentPage = [self.pdfViewCtrl GetCurrentPage];
    [self updatePageCount];
    [self updateLabel];
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    if (self.pdfViewCtrl) {
        // Start observing PDFViewCtrl notifications.
        [center addObserver:self
                   selector:@selector(pdfViewCtrlPageDidChangeNotification:)
                       name:PTPDFViewCtrlPageDidChangeNotification
                     object:self.pdfViewCtrl];
        
        [center addObserver:self
                   selector:@selector(pdfViewCtrlPageCountDidChangeNotification:)
                       name:PTPDFViewCtrlStreamingEventNotification
                     object:self.pdfViewCtrl];
    }
    
    if (self.toolManager) {
        // Start observing ToolManager notifications.
        [center addObserver:self
                   selector:@selector(toolManagerPageRemovedNotification:)
                       name:PTToolManagerPageRemovedNotification
                     object:self.toolManager];
        
        [center addObserver:self
                   selector:@selector(toolManagerPageAddedNotification:)
                       name:PTToolManagerPageAddedNotification
                     object:self.toolManager];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    if (self.pdfViewCtrl) {
        // Stop observing PDFViewCtrl notifications.
        [center removeObserver:self
                          name:PTPDFViewCtrlPageDidChangeNotification
                        object:self.pdfViewCtrl];
        
        [center removeObserver:self
                          name:PTPDFViewCtrlStreamingEventNotification
                        object:self.pdfViewCtrl];
    }
    
    if (self.toolManager) {
        // Stop observing ToolManager notifications.
        [center removeObserver:self
                          name:PTToolManagerPageRemovedNotification
                        object:self.toolManager];
        
        [center removeObserver:self
                          name:PTToolManagerPageAddedNotification
                        object:self.toolManager];
    }
}

@synthesize pageCount = _pageCount;

- (void)updatePageCount
{
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        _pageCount = [doc GetPageCount];
    } error:nil];
}

- (unsigned int)pageCount
{
    if( _pageCount <= 1 )
    {
        [self updatePageCount];
    }
    return _pageCount;
}

#pragma mark - Background

@synthesize backgroundView = _backgroundView;

- (UIView *)backgroundView
{
    [self loadViewIfNeeded];
    
    return _backgroundView;
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    [self loadViewIfNeeded];

    // Remove old background view.
    if (_backgroundView) {
        [_backgroundView removeFromSuperview];
    }
    
    if (backgroundView) {
        _backgroundView = backgroundView;
    } else {
        _backgroundView = self.defaultBackgroundView;
    }
    
    [self.view insertSubview:_backgroundView atIndex:0];
}

- (UIView *)defaultBackgroundView
{
    UIBlurEffectStyle blurEffectStyle = UIBlurEffectStyleExtraLight;
    if (@available(iOS 13.0, *)) {
        blurEffectStyle = UIBlurEffectStyleSystemMaterial;
    }
    UIView *view = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurEffectStyle]];
    view.layer.cornerRadius = 4.0;
    view.layer.masksToBounds = YES; // Required for UIVisualEffectView cornerRadius.
    return view;
}

#pragma mark - Label

- (void)updateLabel
{
    NSString *shortFormat = PTLocalizedString(@"%d of %d", @"<current page number> of <page count>");
    NSString *shortTitle = [NSString localizedStringWithFormat:shortFormat,
                            self.currentPage, self.pageCount];

    NSString *fullTitle = shortTitle;
    
    PTPageLabelManager *pageLabelManager = self.toolManager.pageLabelManager;
    if (pageLabelManager) {
        self.pageLabel = [pageLabelManager pageLabelTitleForPageNumber:self.currentPage];
    }
    
    if (self.pageLabel.length > 0) {
        fullTitle = [NSString stringWithFormat:@"%@ (%@)", self.pageLabel, shortTitle];
    }
    
    self.label.text = fullTitle;
}

#pragma mark - Go to Page

- (void)presentGoToPageController
{
    PTPageLabelManager *pageLabelManager = self.toolManager.pageLabelManager;
    
    NSString *alertTitle = PTLocalizedString(@"Go to Page", @"Go to Page alert title");
    
    NSString *alertMessage = nil;
    if (pageLabelManager) {
        alertMessage = PTLocalizedString(@"Enter a page number",
                                         @"Go to Page alert message");
    } else {
        NSString *alertMessageFormat = PTLocalizedString(@"Enter a page number (%d to %d)",
                                                         @"Go to Page alert message");
        alertMessage = [NSString localizedStringWithFormat:alertMessageFormat, 1, self.pageCount];
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:alertMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // Page number text field.
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.enablesReturnKeyAutomatically = YES;
        textField.returnKeyType = UIReturnKeyGo;
        
        if (pageLabelManager) {
            textField.placeholder = PTLocalizedString(@"Page number",
                                                      @"Page number/label placeholder");
        } else {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = PTLocalizedString(@"Page number",
                                                      @"Page number placeholder");
        }
        
        [textField addTarget:self
                      action:@selector(alertTextFieldDidChange:)
            forControlEvents:(UIControlEventEditingDidBegin |
                              UIControlEventEditingChanged)];
    }];
    UITextField *textField = alertController.textFields.lastObject;
    
    // Cancel action.
    NSString *cancelTitle = PTLocalizedString(@"Cancel", @"Cancel alert label");
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    // OK action.
    NSString *okTitle = PTLocalizedString(@"OK", @"OK alert label");
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Attempt to jump to the page number or page label.
        NSString *text = textField.text;
        
        // Read int value from string.
        NSScanner *scanner = [NSScanner scannerWithString:text];
        int pageNumber = 0;
        if (![scanner scanInt:&pageNumber]) {
            // Failed to read int value from string.
            pageNumber = 0;
        }
        // Try to find the page number for the page label title.
        int pageNumberFromLabel = 0;
        if (pageLabelManager) {
            pageNumberFromLabel = [pageLabelManager pageNumberForPageLabelTitle:text];
        }
        if (pageNumberFromLabel > 0) {
            pageNumber = pageNumberFromLabel;
        }
        
        if ((pageNumber > 0) && (pageNumber <= self.pageCount)) {
            [self.pdfViewCtrl SetCurrentPage:pageNumber];
        } else {
            // Invalid page number.
            [self notifyInvalidPageNumber];
        }
    }];
    [alertController addAction:okAction];
    okAction.enabled = NO;
    
    alertController.preferredAction = okAction;
    
    self.okAlertAction = okAction;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)alertTextFieldDidChange:(UITextField *)textField
{
    UIAlertAction *action = self.okAlertAction;
    if (!action) {
        return;
    }
    
    action.enabled = (textField.text.length > 0);
}

- (void)notifyInvalidPageNumber
{
    NSString *alertTitle = PTLocalizedString(@"Invalid page number", @"Invalid page number alert title");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *okTitle = PTLocalizedString(@"OK", @"OK alert label");
    [alertController addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Gesture recognizer actions

- (void)tapActionWithGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.pageCount < 2) {
        return;
    }
    
    [self presentGoToPageController];
}

#pragma mark - Notifications

#pragma mark PDFViewCtrl

- (void)pdfViewCtrlPageDidChangeNotification:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    int currentPageNumber = ((NSNumber *) notification.userInfo[PTPDFViewCtrlCurrentPageNumberUserInfoKey]).intValue;
    if (currentPageNumber == 0) {
        return;
    }
    
    self.currentPage = currentPageNumber;
    
    [self updateLabel];
}

- (void)pdfViewCtrlPageCountDidChangeNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self updatePageCount];
    [self updateLabel];
}

#pragma mark Toolmanager

- (void)toolManagerPageRemovedNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self updatePageCount];
    [self updateLabel];
}

- (void)toolManagerPageAddedNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self updatePageCount];
    [self updateLabel];
}

@end
