//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTOutlineViewController.h"

#import "PTAnalyticsManager.h"
#import "PTToolsUtil.h"

#define KEY_BOOKMARK_OBJ_NUM @"_bookmarkObjNum"

@interface PTOutlineViewController ()

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, strong, nullable) PTToolManager *toolManager;

@property (nonatomic, strong, nullable) PTBookmark *bookmark;
@property (nonatomic, assign) unsigned int bookmarkObjNum;

@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *childrenBookmarks;

@property (nonatomic, weak, nullable) PTOutlineViewController *rootOutlineViewController;

@property (nonatomic, readonly, assign, getter=isReadonly) BOOL readonly;

@property (nonatomic, strong) UIBarButtonItem *doneButton;

@property (nonatomic, assign) BOOL showsDoneButton;

@property (nonatomic, assign, getter=isTabBarItemSetup) BOOL tabBarItemSetup;

@property (nonatomic, assign, getter=isValid) BOOL valid;

@end

@implementation PTOutlineViewController

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self initWithPDFViewCtrl:toolManager.pdfViewCtrl];
    if (self) {
        _toolManager = toolManager;
    }
    return self;
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
        
        self.title = PTLocalizedString(@"Outline", @"Outline view title");
        
        _childrenBookmarks = [self bookmarksForDoc:[pdfViewCtrl GetDoc] withFirstSibling:nil];
        
        _valid = YES;
    }
    return self;
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl fromBookmark:(PTBookmark *)bookmark
{
    self = [self initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
		_bookmark = bookmark;
        
        BOOL shouldUnlock = NO;
        @try {
            [pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            
            if ([bookmark IsValid]) {
                // Set title from bookmark.
                NSString *title = [bookmark GetTitle];
                if (title) {
                    self.title = title;
                }
                
                _bookmarkObjNum = [[bookmark GetSDFObj] GetObjNum];
                
                bookmark = [bookmark GetFirstChild];
            }
        } @catch (NSException *exception) {
            PTLog(@"Exception: %@: %@", exception.name, exception.reason);
            
            _bookmark = nil;
            _bookmarkObjNum = -1;
        } @finally {
            if (shouldUnlock) {
                [pdfViewCtrl DocUnlockRead];
            }
        }
        
        _childrenBookmarks = [self bookmarksForDoc:[pdfViewCtrl GetDoc] withFirstSibling:bookmark];
    }
    return self;
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)bookmarksForDoc:(PTPDFDoc *)doc withFirstSibling:(nullable PTBookmark *)firstSibling
{
    NSMutableArray<NSDictionary<NSString *, id> *> *bookmarks = [NSMutableArray array];
    
    @try {
        [doc LockRead];
        
        PTBookmark *current = firstSibling;
        if (![firstSibling IsValid]) {
            current = [doc GetFirstBookmark];
        }
        
        for (; [current IsValid]; current = [current GetNext]) {
            [bookmarks addObject:@{KEY_TITLE: [current GetTitle],
                                   KEY_CHILDREN: @([current HasChildren]),
                                   KEY_BOOKMARK: current,
                                   KEY_BOOKMARK_OBJ_NUM: @([[current GetSDFObj] GetObjNum]),
                                   }];
        }
        
        // Handle the case where the document's first bookmark has no siblings.
        if (!firstSibling && bookmarks.count == 1) {
            NSMutableArray<NSDictionary<NSString *, id> *> *nextLevel = [self bookmarksForDoc:doc withFirstSibling:[[doc GetFirstBookmark] GetFirstChild]];
            if (nextLevel.count > 0) {
                return nextLevel;
            }
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@", exception);
    } @finally {
        [doc UnlockRead];
    }
    
    return bookmarks;
}

- (nullable PTBookmark *)bookmarkForObjNum:(unsigned int)objNum
{
    BOOL shouldUnlockRead = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlockRead = YES;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        if (!doc) {
            return nil;
        }
        
        PTObj *obj = [[doc GetSDFDoc] GetObj:objNum];
        if (![obj IsValid]) {
            return nil;
        }
        
        return [[PTBookmark alloc] initWithIn_bookmark_dict:obj];
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@", exception);
    } @finally {
        if (shouldUnlockRead) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    return nil;
}

- (void)refresh
{
    [self.tableView reloadData];
}

- (void)dismiss {
    if ([self.delegate respondsToSelector:@selector(outlineViewControllerDidCancel:)]) {
        [self.delegate outlineViewControllerDidCancel:self];
    }
}

- (BOOL)isReadonly
{
    return [self.toolManager isReadonly];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    // On iPhone we need a button to dismiss the full-screen view. iPad the user can click outside the popover.
    self.showsDoneButton = (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular);
}

- (void)showEmptyView
{
    UILabel* noBookmarksLabel = [[UILabel alloc] init];
    
    
    noBookmarksLabel.text =  PTLocalizedString(@"This document does not\ncontain an outline.", @"");
    noBookmarksLabel.numberOfLines = 2;
    noBookmarksLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:noBookmarksLabel];
    
    noBookmarksLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [noBookmarksLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [noBookmarksLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
       /* Use intrinsic UILabel width and height. */
       ]];
    
    /*
     * The empty label needs to be centered in the view, but the default UITableView content insets
     * shift the table view's (Auto Layout) center down. Remove those insets.
     */
    if (@available(iOS 11, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
        self.automaticallyAdjustsScrollViewInsets = NO;
        PT_IGNORE_WARNINGS_END
    }
    
    self.tableView.scrollEnabled = NO;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.showsDoneButton = self.view.frame.size.width ==  self.view.window.bounds.size.width;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;
    
    if ((self.childrenBookmarks.count < 1 && !self.bookmark) ||
        (![self isValid] && [self.pdfViewCtrl GetDoc])) {
        
        // Reload bookmark when in invalid state.
        if (self.bookmark && ![self isValid]) {
            self.bookmark = [self bookmarkForObjNum:self.bookmarkObjNum];
        }
        
        self.childrenBookmarks = [self bookmarksForDoc:[self.pdfViewCtrl GetDoc]
                                      withFirstSibling:[self.bookmark GetFirstChild]];

        [self.tableView reloadData];
        
        // Reset validity.
        self.valid = YES;
    }
    
    if (self.childrenBookmarks.count < 1) {
        [self showEmptyView];
    }
    
    // Start observing PDFViewCtrl notifications.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlDocDidCloseWithNotification:)
                                               name:PTPDFViewCtrlDidCloseDocNotification
                                             object:self.pdfViewCtrl];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Stop observing PDFViewCtrl notifications.
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTPDFViewCtrlDidCloseDocNotification
                                                object:self.pdfViewCtrl];
}

- (UITabBarItem *)tabBarItem
{
    UITabBarItem *tabBarItem = [super tabBarItem];
    
    if (![self isTabBarItemSetup]) {
        // Add image to tab bar item.
        tabBarItem.image = [PTToolsUtil toolImageNamed:@"ic_outline_white_24dp"];
        
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.childrenBookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
	NSDictionary *details = self.childrenBookmarks[indexPath.row];
	
	cell.textLabel.text = [details[KEY_TITLE] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    cell.textLabel.numberOfLines = 2;

	if ([details[KEY_CHILDREN] boolValue]) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	cell.imageView.image = nil;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Bookmark] Navigated by Outline List"];
    
	NSDictionary *details = self.childrenBookmarks[indexPath.row];
    
    PTBookmark *bookmark = details[KEY_BOOKMARK];
    
    if (![self isValid]) {
        // Try to reload the bookmark using the SDF object number of the stale bookmark.
        unsigned int objNum = ((NSNumber *)self.childrenBookmarks[indexPath.row][KEY_BOOKMARK_OBJ_NUM]).unsignedIntValue;
        bookmark = [self bookmarkForObjNum:objNum];
    }
    
    if (bookmark) {
        PTAction *action = [bookmark GetAction];
        
        if ([action IsValid] && [action GetType] == e_ptGoTo && [[action GetDest] IsValid]) {
            int pageNumber = [[[action GetDest] GetPage] GetIndex];
            
            [self.pdfViewCtrl SetCurrentPage:pageNumber];
        }
    }
	
	if ([self.delegate respondsToSelector:@selector(outlineViewController:selectedBookmark:)]) {
		[self.delegate outlineViewController:self selectedBookmark:details];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    PTBookmark *child = self.childrenBookmarks[indexPath.row][KEY_BOOKMARK];
    
    if (![self isValid]) {
        // Try to reload the bookmark using the SDF object number of the stale bookmark.
        unsigned int objNum = ((NSNumber *)self.childrenBookmarks[indexPath.row][KEY_BOOKMARK_OBJ_NUM]).unsignedIntValue;
        child = [self bookmarkForObjNum:objNum];
        if (!child) {
            return;
        }
    }
    
    // Create a new outline view controller populated with the children of the selected outline (bookmark)
    // item.
    PTOutlineViewController *outlineViewController = [[PTOutlineViewController alloc] initWithPDFViewCtrl:self.pdfViewCtrl fromBookmark:child];
    
    // Use the same delegate and toolbar items as the current view controller.
	outlineViewController.delegate = self.delegate;
    outlineViewController.toolbarItems = self.toolbarItems;
    
    // Propagate the root outline view controller reference, using the current view controller if
    // it is the root.
    outlineViewController.rootOutlineViewController = self.rootOutlineViewController ?: self;
    
    [self.navigationController pushViewController:outlineViewController animated:YES];
}

#pragma mark - Notifications

// Posted when the PDFViewCtrl's doc is closed.
- (void)pdfViewCtrlDocDidCloseWithNotification:(NSNotification *)notification
{
    // Ensure notifcation is for the correct PDFViewCtrl.
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    // Enter invalid state when doc is closed.
    self.valid = NO;

    // Walk up navigation stack, marking outline view controllers as invalid. Stops at the first
    // non-outline view controller.
    // Multiple outline view controllers are pushed onto the navigation stack when navigating to
    // outline sub-levels.
    NSArray<UIViewController *> *viewControllers = self.navigationController.viewControllers;
    
    NSEnumerator *enumerator = viewControllers.reverseObjectEnumerator;
    UIViewController *viewController = nil;
    
    while ((viewController = [enumerator nextObject])) {
        if ([viewController isKindOfClass:[PTOutlineViewController class]]) {
            // Mark outline view controller as invalid.
            PTOutlineViewController *outlineViewController = (PTOutlineViewController *)viewController;
            outlineViewController.valid = NO;
        } else {
            // Stop: non-outline view controller found.
            break;
        }
    }
}

@end
