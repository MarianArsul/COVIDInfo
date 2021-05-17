//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTReflowViewController.h"

#import "PTReflowManager.h"
#import "PTReflowPageContentViewController.h"

static const NSUInteger kPTReflowViewControllerCyclingCount = 3;

@interface PTReflowViewController () <PTReflowManagerDelegate, PTReflowPageContentViewControllerDelegate>

@property (nonatomic, strong) PTReflowManager *reflowManager;

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, copy) NSArray<PTReflowPageContentViewController *> *viewControllers;

@property (nonatomic, readonly, assign) int pageCount;

// Whether the UIPageViewController is transitioning between view controllers.
@property (nonatomic, assign, getter=isTransitioning) BOOL transitioning;

#pragma mark - Presented page number

@property (nonatomic, assign) int presentedPageNumber;

- (void)setPresentedPageNumber:(int)presentedPageNumber animated:(BOOL)animated;

#pragma mark - Interactive scale

@property (nonatomic, assign) CGFloat initialScale;

// Re-declare as readwrite internally.
@property (nonatomic, readwrite, strong) UIPageViewController *pageViewController;

@end

@implementation PTReflowViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    return [self initWithPDFViewCtrl:pdfViewCtrl scrollingDirection:PTReflowViewControllerScrollingDirectionHorizontal];
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl scrollingDirection:(PTReflowViewControllerScrollingDirection)scrollingDirection
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        _scrollingDirection = scrollingDirection;
        
        _viewControllers = @[];
        
        _reflowManager = [[PTReflowManager alloc] initWithPDFViewCtrl:pdfViewCtrl];
        _reflowManager.delegate = self;
        _reflowMode = _reflowManager.reflowMode = PTReflowModeTextAndRawImages;
        // Initialize later in viewWillAppear:, since the PDFViewCtrl state could change in-between.
        _pageNumber = 0;
        
        _scale = 1.0;
        
        _initialScale = _scale;
        
        // Start observing PDFViewCtrl notifications.
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(pdfViewCtrlColorModeChanged:)
                                                   name:PTPDFViewCtrlColorPostProcessModeDidChangeNotification
                                                 object:self.pdfViewCtrl];
    }
    return self;
}

#pragma mark - View lifecycle

// NOTE: Do *not* call super implementation.
- (void)loadView
{
    // Standard root view.
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.view = view;
    
    [self loadPageViewController];
}

- (void)loadPageViewController
{
    UIPageViewControllerNavigationOrientation orientation = (self.scrollingDirection == PTReflowViewControllerScrollingDirectionHorizontal) ?
        UIPageViewControllerNavigationOrientationHorizontal :
        UIPageViewControllerNavigationOrientationVertical;
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:orientation options:nil];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    // View controller containment.
    [self addChildViewController:self.pageViewController];
    
    self.pageViewController.view.frame = self.view.bounds;
    self.pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.pageViewController.view];
    
    [self.pageViewController didMoveToParentViewController:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    // Create content view controllers.
    NSMutableArray<PTReflowPageContentViewController *> *pageContentViewControllers = [NSMutableArray arrayWithCapacity:kPTReflowViewControllerCyclingCount];
    for (NSUInteger i = 0; i < kPTReflowViewControllerCyclingCount; i++) {
        PTReflowPageContentViewController *pageContentViewController = [[PTReflowPageContentViewController alloc] init];
        pageContentViewController.pageNumber = 0;
        pageContentViewController.delegate = self;

        pageContentViewController.scale = self.scale;
        pageContentViewController.turnPageOnTap = self.turnPageOnTap;

        pageContentViewControllers[i] = pageContentViewController;
    }
    self.viewControllers = [pageContentViewControllers copy];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(reflowDone)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.reflowManager clearCache];
    
    // Request reflow for PDFViewCtrl's current page.
    int pageNumber = 0;
    
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        pageNumber = [self.pdfViewCtrl GetCurrentPage];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    if (pageNumber > 0) {
        self.pageNumber = pageNumber;
    }
    
    // Start observing PDFViewCtrl notifications.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlPageDidChangeNotification:)
                                               name:PTPDFViewCtrlPageDidChangeNotification
                                             object:self.pdfViewCtrl];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.reflowManager cancelAllRequests];
    
    if (self.pageNumber > 0) {
        // Synchronize PDFViewCtrl's current page.
        @try {
            [self.pdfViewCtrl SetCurrentPage:self.pageNumber];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Stop observing PDFViewCtrl notifications.
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTPDFViewCtrlPageDidChangeNotification
                                                object:self.pdfViewCtrl];
}

- (void)unloadPageViewController
{
    if (!self.pageViewController) {
        return;
    }
    
    // View controller containment.
    [self.pageViewController willMoveToParentViewController:nil];
    [self.pageViewController.view removeFromSuperview];
    [self.pageViewController removeFromParentViewController];
    
    self.pageViewController = nil;
}

// Reload the page view controller to update init-time settings.
- (void)reloadPageViewController
{
    // Save view controllers (pages).
    NSArray<UIViewController *> *viewControllers = self.pageViewController.viewControllers;
    
    // Unload and load the page view controller again.
    [self unloadPageViewController];
    [self loadPageViewController];
    
    // Restore view controllers (pages) if necessary.
    if (viewControllers.count > 0) {
        [self.pageViewController setViewControllers:viewControllers
                                          direction:UIPageViewControllerNavigationDirectionForward
                                           animated:NO
                                         completion:nil];
    }
}

#pragma mark - Scrolling direction

- (void)setScrollingDirection:(PTReflowViewControllerScrollingDirection)scrollingDirection
{
    if (_scrollingDirection == scrollingDirection) {
        // No change.
        return;
    }
    
    _scrollingDirection = scrollingDirection;
    
    // The page view controller needs to be reloaded in order for the scrolling direction to be changed.
    [self reloadPageViewController];
}

#pragma mark -Mode

- (void)setReflowMode:(PTReflowMode)reflowMode
{
    _reflowMode = reflowMode;
    self.reflowManager.reflowMode = reflowMode;
}

#pragma mark - toggling night mode

-(void)setBackgroundColors:(UIColor*)backgroundColor
{
    self.view.backgroundColor = backgroundColor;
    self.pageViewController.view.backgroundColor = backgroundColor;
    
    for(PTReflowPageContentViewController* contentController in self.viewControllers)
    {
        [contentController refreshWebview];
        contentController.backgroundColor = backgroundColor;
        contentController.webView.scrollView.backgroundColor = backgroundColor;
        contentController.webView.backgroundColor = backgroundColor;
        
        
        if( contentController.pageNumber > 0 )
        {
            [self.reflowManager requestReflowForPageNumber:contentController.pageNumber];
        }
    }
    
}

-(void)setFontOverrideName:(NSString*)fontOverrideName
{
    self.reflowManager.fontOverrideName = fontOverrideName;
    
    [self.reflowManager clearCache];
    
    for(PTReflowPageContentViewController* contentController in self.viewControllers)
    {
        [contentController refreshWebview];
        
        if( contentController.pageNumber > 0 )
        {
            [self.reflowManager requestReflowForPageNumber:contentController.pageNumber];
        }
    }
}

-(NSString*)fontOverrideName
{
    return self.reflowManager.fontOverrideName;
}

-(void)pdfViewCtrlColorModeChanged:(NSNotification*)notification
{
    [self.reflowManager clearCache];
    
    
    
    NSNumber* mode = notification.userInfo[PTPDFViewCtrlColorPostProcessModeUserInfoKey];
    
    BOOL isDarkMode = ([mode isEqual:@(e_ptpostprocess_night_mode)] || [mode isEqual:@(e_ptpostprocess_invert)] );
    
    BOOL isSepia = ([mode isEqual:@(e_ptpostprocess_gradient_map)]);
    
    
    
    if( isDarkMode )
    {
        [self setBackgroundColors:UIColor.blackColor];
    }
    else if( isSepia )
    {
        [self setBackgroundColors:[UIColor colorWithRed:252.0/255 green:234.0/255 blue:213.0/255 alpha:1]];
    }
    else
    {
        [self setBackgroundColors:UIColor.whiteColor];
    }

    
}

#pragma mark - Content view controller handling

- (PTReflowPageContentViewController *)pageContentViewControllerForPageNumber:(int)pageNumber
{
    NSParameterAssert(pageNumber > 0);

    if (self.pageCount < 1) {
        return nil;
    }

    int index = (pageNumber - 1) % kPTReflowViewControllerCyclingCount;

    return self.viewControllers[index];
}

- (void)recycleContentViewController:(PTReflowPageContentViewController *)viewController forPageNumber:(int)pageNumber
{
    NSParameterAssert(pageNumber > 0);

//    if (viewController.pageNumber == pageNumber) {
//        return;
//    }

    if (@available(iOS 13.0, *)) {
        [viewController refreshWebview];
    }
    
    viewController.delegate = self;

    int oldPageNumber = viewController.pageNumber;
    viewController.pageNumber = pageNumber;

    // Cancel old page request and request new page.
    [self.reflowManager cancelRequestForPageNumber:oldPageNumber];
    self.reflowManager.reflowMode = self.reflowMode;
    [self.reflowManager requestReflowForPageNumber:pageNumber];
}

#pragma mark - Page number

-(int)pageCount
{
    int pageCount = 0;
    
    BOOL shouldUnlockRead = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlockRead = YES;
        
        pageCount = [self.pdfViewCtrl GetPageCount];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        pageCount = 0;
    } @finally {
        if (shouldUnlockRead) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    return pageCount;
}

- (void)setPageNumber:(int)pageNumber
{
    [self setPageNumber:pageNumber animated:NO];
}

- (void)setPageNumber:(int)pageNumber animated:(BOOL)animated
{
    if (self.pageCount > 0) {
        NSParameterAssert(pageNumber > 0 && pageNumber <= self.pageCount);
    } else {
        NSParameterAssert(pageNumber == 0);
    }
    
    if (_pageNumber == pageNumber) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_KEY(self, pageNumber)];
    
    _pageNumber = pageNumber;
    
    // Update presented page if necessary.
    [self setPresentedPageNumber:pageNumber animated:animated];
    
    [self didChangeValueForKey:PT_KEY(self, pageNumber)];
    
    // Notify delegate of page change.
    if ([self.delegate respondsToSelector:@selector(reflowController:didChangeToPageNumber:)]) {
        [self.delegate reflowController:self didChangeToPageNumber:pageNumber];
    } else {
        // Synchronize PDFViewCtrl page number manually.
        @try {
            [self.pdfViewCtrl SetCurrentPage:pageNumber];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
    }
}

// Disable automatic KVO notifications.
+ (BOOL)automaticallyNotifiesObserversOfPageNumber
{
    return NO;
}

#pragma mark - Presented page number

- (int)presentedPageNumber
{
    UIViewController *viewController = self.pageViewController.viewControllers.firstObject;
    if (![viewController isKindOfClass:[PTReflowPageContentViewController class]]) {
        return 0;
    }
    
    PTReflowPageContentViewController *pageContentViewController = (PTReflowPageContentViewController *)viewController;
    return pageContentViewController.pageNumber;
}

- (void)setPresentedPageNumber:(int)presentedPageNumber
{
    [self setPresentedPageNumber:presentedPageNumber animated:NO];
}

- (void)setPresentedPageNumber:(int)pageNumber animated:(BOOL)animated
{
    int currentPresentedPageNumber = self.presentedPageNumber;
    
    if (currentPresentedPageNumber == pageNumber) {
        return;
    }
    
    PTReflowPageContentViewController *viewController = [self pageContentViewControllerForPageNumber:pageNumber];
    
    [self recycleContentViewController:viewController forPageNumber:pageNumber];
    
    // Determine the navigation direction for animated transitions.
    UIPageViewControllerNavigationDirection direction = (currentPresentedPageNumber < pageNumber) ?
        UIPageViewControllerNavigationDirectionForward :
        UIPageViewControllerNavigationDirectionReverse;
    
    [self.pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:nil];
}

#pragma mark - Scale

- (void)setScale:(CGFloat)scale
{
    if (_scale == scale) {
        // No change.
        return;
    }
    
    _scale = scale;
    
    // Update content view controllers.
    for (PTReflowPageContentViewController *viewController in self.viewControllers) {
        viewController.scale = scale;
    }
}

- (void)PT_setScaleFromBaseScale:(CGFloat)scale factor:(CGFloat)factor
{
    if (factor <= 0.0) {
        return;
    }
    
    self.scale = MAX(0.25, MIN(scale * factor, 5.0));
}

#pragma mark - Turn page on tap

- (void)setTurnPageOnTap:(BOOL)turnPageOnTap
{
    _turnPageOnTap = turnPageOnTap;
    
    // Update content view controllers.
    for (PTReflowPageContentViewController *viewController in self.viewControllers) {
        viewController.turnPageOnTap = turnPageOnTap;
    }
}

#pragma mark - <UIPageViewControllerDelegate>

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers
{
    self.transitioning = YES;
    
    UIViewController *pendingViewController = pendingViewControllers.firstObject;
    if (![pendingViewController isKindOfClass:[PTReflowPageContentViewController class]]) {
        return;
    }
    
    // Check that the pending view controller has a valid page number.
//    PTReflowPageContentViewController *viewController = (PTReflowPageContentViewController *)pendingViewController;
//    int transitioningPageNumber = viewController.pageNumber;
//    
//    NSAssert(transitioningPageNumber > 0 && transitioningPageNumber <= self.pageCount,
//             @"Transitioning to invalid page number: %d", transitioningPageNumber);
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (!completed) {
        // Page did not change.
        self.transitioning = NO;
        return;
    }
    
    UIViewController *viewController = pageViewController.viewControllers.firstObject;
    if ([viewController isKindOfClass:[PTReflowPageContentViewController class]]) {
        PTReflowPageContentViewController *pageContentViewController = (PTReflowPageContentViewController *)viewController;
        // New page number should be valid, as checked in pageViewController:willTransitionToViewControllers:
        int pageNumber = pageContentViewController.pageNumber;
        
        self.pageNumber = pageNumber;
    }
    
    self.transitioning = NO;
}

#pragma mark - <UIPageViewControllerDataSource>

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSParameterAssert([viewController isKindOfClass:[PTReflowPageContentViewController class]]);
    
    PTReflowPageContentViewController *pageContentViewController = (PTReflowPageContentViewController *)viewController;
    int pageNumber = pageContentViewController.pageNumber;
    
    if (pageNumber <= 1) {
        // On first page already.
        return nil;
    }
    
    // Return previous page.
    int previousPageNumber = pageNumber - 1;
    
    PTReflowPageContentViewController *previousViewController = [self pageContentViewControllerForPageNumber:previousPageNumber];
    
    [self recycleContentViewController:previousViewController forPageNumber:previousPageNumber];
    
    return previousViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSParameterAssert([viewController isKindOfClass:[PTReflowPageContentViewController class]]);
    
    PTReflowPageContentViewController *pageContentViewController = (PTReflowPageContentViewController *)viewController;
    int pageNumber = pageContentViewController.pageNumber;

    if (pageNumber >= self.pageCount) {
        // On last page already.
        return nil;
    }
    
    // Return next page.
    int nextPageNumber = pageNumber + 1;
    
    PTReflowPageContentViewController *nextViewController = [self pageContentViewControllerForPageNumber:nextPageNumber];
    
    [self recycleContentViewController:nextViewController forPageNumber:nextPageNumber];
    
    return nextViewController;
}

#pragma mark - <PTReflowManagerDelegate>

- (void)reflowManager:(PTReflowManager *)reflowManager didBeginRequestForPageNumber:(int)pageNumber
{

    PTReflowPageContentViewController *viewController = [self pageContentViewControllerForPageNumber:pageNumber];
    if (viewController.pageNumber != pageNumber) {
        NSLog(@"[reflow] didBeginRequest pagenumbers did not match");
        return;
    }

    NSLog(@"[reflow] didBeginRequest pagenumbers ok");
    // Enter loading state.
    viewController.state = PTReflowContentStateLoading;
}

- (void)reflowManager:(PTReflowManager *)reflowManager requestFailedForPageNumber:(int)pageNumber
{

    PTReflowPageContentViewController *viewController = [self pageContentViewControllerForPageNumber:pageNumber];
    if (viewController.pageNumber != pageNumber) {
        NSLog(@"[reflow] requestFailedForPageNumber pagenumbers did not match");
        return;
    }

    NSLog(@"[reflow] requestFailedForPageNumber pagenumbers ok");
    // Enter idle state.
    viewController.state = PTReflowContentStateIdle;
}

- (void)reflowManager:(PTReflowManager *)reflowManager requestCancelledForPageNumber:(int)pageNumber
{

    PTReflowPageContentViewController *viewController = [self pageContentViewControllerForPageNumber:pageNumber];
    if (viewController.pageNumber != pageNumber) {
        NSLog(@"[reflow] requestCancelledForPageNumber pagenumbers did not match");
        return;
    }

    NSLog(@"[reflow] requestCancelledForPageNumber pagenumbers ok");
    // Enter idle state.
    viewController.state = PTReflowContentStateIdle;
}

- (void)reflowManager:(PTReflowManager *)reflowManager didReceiveResult:(NSURL *)reflowFile forPageNumber:(int)pageNumber
{
    
    PTReflowPageContentViewController *viewController = [self pageContentViewControllerForPageNumber:pageNumber];
    if (viewController.pageNumber != pageNumber) {
        NSLog(@"[reflow] didReceiveResult pagenumbers did not match");
        return;
    }
    

    NSLog(@"[reflow] didReceiveResult pagenumbers ok");
    
    [viewController loadURL:reflowFile];
    
    // Enter complete state.
    viewController.state = PTReflowContentStateComplete;
    
    BOOL isDarkMode = ( [self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_night_mode || [self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_invert  );
    
    BOOL isSepiaMode = ([self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_gradient_map);
    
    if( isDarkMode == YES && self.view.backgroundColor != UIColor.blackColor )
    {
        [self setBackgroundColors:UIColor.blackColor];
    }
    else if( isSepiaMode == YES && !([self.view.backgroundColor isEqual:[UIColor colorWithRed:252.0/255 green:234.0/255 blue:213.0/255 alpha:1]]))
    {
        [self setBackgroundColors:[UIColor colorWithRed:252.0/255 green:234.0/255 blue:213.0/255 alpha:1]];
    }
    else if( isDarkMode == NO && isSepiaMode == NO && self.view.backgroundColor != UIColor.whiteColor)
    {
        [self setBackgroundColors:UIColor.whiteColor];
    }
    
    
}

#pragma mark - <PTReflowContentViewControllerDelegate>

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didSelectFileURL:(NSURL *)fileURL
{
    if (pageContentViewController.pageNumber != self.pageNumber) {
        return;
    }
    
    int pageNumber = [self.reflowManager pageNumberForReflowFile:fileURL];
    if (pageNumber < 1) {
        return;
    }
    
    self.pageNumber = pageNumber;
}

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (pageContentViewController.pageNumber != self.pageNumber) {
        return;
    }
    
    // Notify delegate of tap.
    if ([self.delegate respondsToSelector:@selector(reflowController:handleTap:)]) {
        [self.delegate reflowController:self handleTap:gestureRecognizer];
    }
}

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController changePageWithDirection:(PTReflowContentNavigationDirection)direction
{
    if (pageContentViewController.pageNumber != self.pageNumber) {
        return;
    }

    switch (direction) {
        case PTReflowContentNavigationDirectionForward:
            if (self.pageNumber < self.pageCount) {
                self.pageNumber++;
            }
            break;
        case PTReflowContentNavigationDirectionReverse:
            if (self.pageNumber > 1) {
                self.pageNumber--;
            }
            break;
    }
}

#pragma mark Scale

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didBeginScale:(CGFloat)scale
{
    if (pageContentViewController.pageNumber != self.pageNumber) {
        return;
    }

    // Save current scale.
    self.initialScale = self.scale;
    
    [self PT_setScaleFromBaseScale:self.initialScale factor:scale];
}

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didChangeScale:(CGFloat)scale
{
    if (pageContentViewController.pageNumber != self.pageNumber) {
        return;
    }
    
    NSAssert(self.initialScale != 0.0, @"Initial reflow content scale not set");

    [self PT_setScaleFromBaseScale:self.initialScale factor:scale];
}

- (void)reflowContentViewController:(PTReflowPageContentViewController *)pageContentViewController didEndScale:(CGFloat)scale
{
    if (pageContentViewController.pageNumber != self.pageNumber) {
        return;
    }
    
    [self PT_setScaleFromBaseScale:self.initialScale factor:scale];
    
    self.initialScale = 0.0;
}

- (void)reflowContentViewControllerDidCancelScale:(PTReflowPageContentViewController *)pageContentViewController
{
    if (pageContentViewController.pageNumber != self.pageNumber) {
        return;
    }
    
    if (self.initialScale == 0.0) {
        return;
    }
    
    self.scale = self.initialScale;
    
    self.initialScale = 0.0;
}

#pragma mark - Actions

- (void)reflowDone
{
    // Notify delegate of event.
    if ([self.delegate respondsToSelector:@selector(reflowControllerDidCancel:)]) {
        [self.delegate reflowControllerDidCancel:self];
        return;
    }
    
    if (self.presentingViewController) {
        // Manually dismiss view controller.
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Notification actions

- (void)pdfViewCtrlPageDidChangeNotification:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    int currentPageNumber = ((NSNumber *) notification.userInfo[PTPDFViewCtrlCurrentPageNumberUserInfoKey]).intValue;
    if (currentPageNumber == 0) {
        return;
    }
        
    // Only update/synchronize page number when the UIPageViewController is not actively transitioning.
    // If the page number is set while the page view controller is transitioning there is a chance
    // of an NSInternalInconsistencyException exception occurring with the reason:
    // "Invalid parameter not satisfying:   [views count] == 3"
    if (![self isTransitioning]) {
        self.pageNumber = currentPageNumber;
    }
}

@end
