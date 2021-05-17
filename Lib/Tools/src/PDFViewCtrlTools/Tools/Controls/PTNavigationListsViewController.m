//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTNavigationListsViewController.h"

#import "PTToolsUtil.h"

#import "UIScrollView+PTAdditions.h"

@interface PTNavigationListsViewController () <UINavigationControllerDelegate, UIToolbarDelegate>

@property (nonatomic, strong) PTToolManager *toolManager;

@property (nonatomic, strong) UINavigationController *listNavigationController;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, assign) BOOL needsSegmentedControlColor;

@property (nonatomic, strong) NSMutableArray<NSArray<UIViewController *> *> *navigationStacks;

@end

@implementation PTNavigationListsViewController

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _toolManager = toolManager;
        
        _annotationViewController = [[PTAnnotationViewController allocOverridden] initWithToolManager:toolManager];
        _outlineViewController = [[PTOutlineViewController allocOverridden] initWithToolManager:toolManager];
        _bookmarkViewController = [[PTBookmarkViewController allocOverridden] initWithToolManager:toolManager];

        _listViewControllers = @[_outlineViewController, _annotationViewController, _bookmarkViewController];

        _pdfLayerViewController = [[PTPDFLayerViewController allocOverridden] initWithPDFViewCtrl:toolManager.pdfViewCtrl];

        // Set up initial navigation stacks.
        _navigationStacks = [NSMutableArray arrayWithCapacity:_listViewControllers.count];
        for (UIViewController *viewController in _listViewControllers) {
            [_navigationStacks addObject:@[viewController]];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.listNavigationController = [[UINavigationController alloc] init];
    self.listNavigationController.delegate = self;
    
    [self addChildViewController:self.listNavigationController];
    
    [self.view addSubview:self.listNavigationController.view];
    
    [self.listNavigationController didMoveToParentViewController:self];
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:UIScreen.mainScreen.bounds];
    // NOTE: Must be done before setting UISegmentedControl constraints (iOS 10).
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    self.toolbar.delegate = self;
    
    [self.view addSubview:self.toolbar];
    
    self.segmentedControl = [[UISegmentedControl alloc] init];
    
    [self.segmentedControl addTarget:self action:@selector(selectedSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    
    if (@available(iOS 11.0, *)) {
        // Use UIBarButtonItem Auto Layout support.
        self.toolbar.items = @[[[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl]];
    } else {
        // Handle Auto Layout manually.
        // NOTE: Does not work for iOS 11+, where the segmented control
        [self.toolbar addSubview:self.segmentedControl];
        
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [self.segmentedControl.centerXAnchor constraintEqualToAnchor:self.toolbar.centerXAnchor],
           [self.segmentedControl.topAnchor constraintEqualToAnchor:self.toolbar.layoutMarginsGuide.topAnchor],
           [self.segmentedControl.widthAnchor constraintEqualToAnchor:self.toolbar.layoutMarginsGuide.widthAnchor],
           [self.segmentedControl.heightAnchor constraintEqualToAnchor:self.toolbar.layoutMarginsGuide.heightAnchor],
           ]];
    }
    
    self.listNavigationController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.listNavigationController.view.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [self.listNavigationController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [self.listNavigationController.view.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
       [self.listNavigationController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
       
       [self.toolbar.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
       [self.toolbar.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [self.toolbar.topAnchor constraintEqualToAnchor:self.listNavigationController.navigationBar.bottomAnchor],
       ]];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self updateAdditionalSafeAreaInsets];
    
    if (self.needsSegmentedControlColor) {
        [self updateSegmentedControlColor];
        
        self.needsSegmentedControlColor = NO;
    }
}

- (void)updateAdditionalSafeAreaInsets
{
    CGRect frame = (![self.toolbar isHidden]) ? self.toolbar.frame : CGRectZero;
    
    if (@available(iOS 11.0, *)) {
        self.listNavigationController.topViewController.additionalSafeAreaInsets = UIEdgeInsetsMake(CGRectGetHeight(frame), 0, 0, 0);
    } else {
        PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
        // Manually adjust the top view controller's contentInset.
        if (self.automaticallyAdjustsScrollViewInsets) {
            UIViewController *viewController = self.listNavigationController.topViewController;
            
            UIScrollView *scrollView = nil;
            
            if ([viewController.view isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView *)viewController.view;
            }
            else if ([viewController.view.subviews.firstObject isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView *)viewController.view.subviews.firstObject;
            }
            
            if (scrollView) {
                UIEdgeInsets insets = UIEdgeInsetsMake(CGRectGetHeight(frame), 0, 0, 0);
                scrollView.pt_extendedContentInset = insets;
                scrollView.pt_extendedScrollIndicatorInsets = insets;
            }
        }
        PT_IGNORE_WARNINGS_END
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateListViewControllerVisibility];

    [self updateSegmentedControl];

    self.needsSegmentedControlColor = YES;
    
    if (self.listNavigationController.viewControllers.count < 1
        && self.listViewControllers.count > 0) {
        UIViewController *selectedViewController = self.selectedViewController;
        
        self.listNavigationController.viewControllers = @[selectedViewController];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.needsSegmentedControlColor) {
        [self updateSegmentedControlColor];
        
        self.needsSegmentedControlColor = NO;
    }
}

#pragma mark - Embedded navigation controller

- (UINavigationController *)listNavigationController
{
    [self loadViewIfNeeded];
    
    return _listNavigationController;
}

#pragma mark - Segmented control

- (void)updateSegmentedControl
{
    [self.segmentedControl removeAllSegments];
    
    // Hide toolbar and segmented control if not needed.
    if (self.listViewControllers.count <= 1) {
        self.toolbar.hidden = YES;
        return;
    }
    
    // Ensure toolbar is shown.
    self.toolbar.hidden = NO;
    
    UIViewController *selectedViewController = self.selectedViewController;
    
    for (UIViewController *viewController in self.listViewControllers) {
        // Use tabBarItem of each list view controller in the segmented control.
        UITabBarItem *tabBarItem = viewController.tabBarItem;
        if (tabBarItem.image) {
            [self.segmentedControl insertSegmentWithImage:tabBarItem.image atIndex:self.segmentedControl.numberOfSegments animated:NO];
        } else {
            NSString *title = tabBarItem.title ?: PTLocalizedString(@"No Title", @"Default view controller title for segmented control");
            
            [self.segmentedControl insertSegmentWithTitle:title atIndex:self.segmentedControl.numberOfSegments animated:NO];
        }
        
        if (viewController == selectedViewController) {
            // Select current (last) segment.
            self.segmentedControl.selectedSegmentIndex = (self.segmentedControl.numberOfSegments - 1);
        }
    }
}

// NOTE: For a translucent UINavigationBar, it's possible to see that the segmented control is not
// actually inside the UINavigationBar due to the small visual discrepancy from the UIVisualEffectViews.
// To avoid this problem, the nested UINavigationController's navigation bar can be made opaque.
- (void)updateSegmentedControlColor
{
    // Synchronize toolbar appearance with navigation bar.
    UINavigationBar *navigationBar = self.listNavigationController.navigationBar;
    
    self.toolbar.barStyle = navigationBar.barStyle;
    self.toolbar.barTintColor = navigationBar.barTintColor;
    self.toolbar.tintColor = navigationBar.tintColor;
    self.toolbar.translucent = navigationBar.translucent;
}

#pragma mark - List view controllers

- (void)setListViewControllers:(NSArray<UIViewController *> *)listViewControllers
{
    if ([_listViewControllers isEqualToArray:listViewControllers]) {
        // No change.
        return;
    }
    
    NSUInteger selectedIndex = self.selectedIndex;
    UIViewController *selectedViewController = self.selectedViewController;
    
    _listViewControllers = [listViewControllers copy];
    
    // Rebuild navigation stacks.
    NSMutableArray<NSArray<UIViewController *> *> *stacks = [NSMutableArray arrayWithCapacity:listViewControllers.count];
    
    for (UIViewController *viewController in listViewControllers) {
        // Find existing stack for view controller.
        NSArray<UIViewController *> *newStack = nil;
        for (NSArray<UIViewController *> *stack in self.navigationStacks) {
            if (viewController == stack.firstObject) {
                // Found exiting stack.
                newStack = stack;
                break;
            }
        }
        if (!newStack) {
            // Create new navigation stack for the (new) view controller.
            newStack = @[viewController];
        }
        [stacks addObject:newStack];
    }
    
    self.navigationStacks = stacks;
    
    // Check if the previously selected view controller is still present.
    NSUInteger newSelectedIndex = NSNotFound;
    if (selectedViewController) {
        newSelectedIndex = [listViewControllers indexOfObject:selectedViewController];
    }
    
    if (newSelectedIndex != NSNotFound) {
        // Update selected index.
        self.selectedIndex = newSelectedIndex;
    } else if (selectedIndex < listViewControllers.count) {
        // Select view controller at same index as previous selection.
        self.selectedViewController = listViewControllers[selectedIndex];
    } else {
        // Select view controller at index 0.
        self.selectedIndex = 0;
    }
    
    // Update segmented control after updating the selection.
    [self updateSegmentedControl];
}

- (void)addListViewController:(UIViewController *)listViewController
{
    if ([self.listViewControllers containsObject:listViewController]) {
        return;
    }
    
    NSMutableArray<UIViewController *> *listViewControllers = [self.listViewControllers mutableCopy];
    [listViewControllers addObject:listViewController];
    self.listViewControllers = [listViewControllers copy];
}

- (void)removeListViewController:(UIViewController *)listViewController
{
    NSMutableArray<UIViewController *> *listViewControllers = [self.listViewControllers mutableCopy];
    [listViewControllers removeObject:listViewController];
    self.listViewControllers = [listViewControllers copy];
}

-(void)updateListViewControllerVisibility
{
    
    NSMutableArray* listVCs = [self.listViewControllers mutableCopy];

    switch (self.pdfLayerViewControllerVisibility) {
        case PTNavigationListsViewControllerVisibilityAutomatic:
            if ([self docHasLayers]) {
                if ([self.listViewControllers containsObject:self.pdfLayerViewController]) {
                    break;
                }
                self.listViewControllers = [self.listViewControllers arrayByAddingObject:self.pdfLayerViewController];
            }else{
                [listVCs removeObject:self.pdfLayerViewController];
                self.listViewControllers = [listVCs copy];
            }
            break;
        case PTNavigationListsViewControllerVisibilityNeverHidden:
            if ([self.listViewControllers containsObject:self.pdfLayerViewController]) {
                break;
            }
            self.listViewControllers = [self.listViewControllers arrayByAddingObject:self.pdfLayerViewController];
            break;
        case PTNavigationListsViewControllerVisibilityAlwaysHidden:
            [listVCs removeObject:self.pdfLayerViewController];
            self.listViewControllers = [listVCs copy];
            break;
        default:
            [listVCs removeObject:self.pdfLayerViewController];
            self.listViewControllers = [listVCs copy];
            break;
    }
}

- (BOOL)docHasLayers
{
    BOOL shouldUnlockRead = NO;
    BOOL hasLayers = NO;
    @try
    {
        [self.toolManager.pdfViewCtrl DocLockRead];
        shouldUnlockRead = YES;

        if ([[self.toolManager.pdfViewCtrl GetDoc] HasOC]) {
            PTConfig *config = [[self.toolManager.pdfViewCtrl GetDoc] GetOCGConfig];
            if ([config IsValid]) {
                PTObj *ocgs = [config GetOrder];
                hasLayers = (ocgs != nil && (int) ocgs.Size > 0);
            }
        }
    }
    @catch(NSException *exception){
        NSLog(@"Exception: %@: reason: %@", exception.name, exception.reason);
    }
    @finally{
        if (shouldUnlockRead) {
            [self.toolManager.pdfViewCtrl DocUnlockRead];
        }
    }
    return hasLayers;
}

#pragma mark - Selection

- (UIViewController *)selectedViewController
{
    return (self.listViewControllers.count > 0) ? self.listViewControllers[self.selectedIndex] : nil;
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    NSUInteger index = [self.listViewControllers indexOfObject:selectedViewController];
    if (index != NSNotFound) {
        [self setSelectedIndex:index];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    // NOTE: Allow reselecting the same index, since the view controller at that index
    // may have been changed.
    
    _selectedIndex = selectedIndex;
    
    UIViewController *viewController = (self.listViewControllers.count > 0) ? self.listViewControllers[selectedIndex] : nil;
    
    UIViewController *rootViewController = self.listNavigationController.viewControllers.firstObject;
    if (viewController != rootViewController) {
        if (rootViewController) {
            // Save current navigation stack.
            NSUInteger previousIndex = [self.listViewControllers indexOfObject:rootViewController];
            if (previousIndex != NSNotFound) {
                self.navigationStacks[previousIndex] = self.listNavigationController.viewControllers;
            }
        }

        // Restore stack.
        NSArray<UIViewController *> *viewControllers = (self.navigationStacks.count > 0) ? self.navigationStacks[selectedIndex] : nil;
        if (!viewControllers && viewController) {
            viewControllers = @[viewController];
        }
        
        self.listNavigationController.viewControllers = viewControllers;
    }
    
    self.segmentedControl.selectedSegmentIndex = selectedIndex;
}

#pragma mark - Segmented control actions

- (void)selectedSegmentChanged:(UISegmentedControl *)segmentedControl
{
    NSInteger selectedIndex = segmentedControl.selectedSegmentIndex;
    
    self.selectedIndex = selectedIndex;
}

#pragma mark - <UINavigationControllerDelegate>

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // Update additional safe area insets.
    // NOTE: Required here since -viewDidLayoutSubviews will not be called every time.
    [self updateAdditionalSafeAreaInsets];
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

@end
