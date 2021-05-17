//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBookmarkViewController.h"

#import "PTBookmarkViewCell.h"
#import "PTBookmarkUtils.h"
#import "PTBookmarkManager.h"
#import "PTBookmarkManager+PTCompatibility.h"
#import "PTToolsUtil.h"

static NSString * const PTBookmarkViewController_cellReuseIdentifier = @"BookmarkCell";

@interface PTBookmarkViewController () <UITextViewDelegate, PTBookmarkViewCellDelegate>

@property (nonatomic, weak) PTPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, strong, nullable) PTToolManager *toolManager;

@property (nonatomic, strong, nullable) NSURL *documentURL;

@property (nonatomic, strong, nullable) NSIndexPath *lastCreatedBookmarkIndexPath;

@property (nonatomic, strong) UIBarButtonItem *doneButton;

@property (nonatomic, assign) BOOL showsDoneButton;

@property (nonatomic, assign, getter=isTabBarItemSetup) BOOL tabBarItemSetup;

@end

@implementation PTBookmarkViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		_pdfViewCtrl = pdfViewCtrl;
        
        // Get file path, if available.
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            
            NSString *filePath = [[self.pdfViewCtrl GetDoc] GetFileName];
            filePath = filePath.stringByExpandingTildeInPath;
            if (filePath && [NSFileManager.defaultManager fileExistsAtPath:filePath isDirectory:nil]) {
                _documentURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
            }
        } @catch (NSException *exception) {
            PTLog(@"Exception: %@: %@", exception.name, exception.reason);
            _documentURL = nil;
        } @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
        
        self.title = PTLocalizedString(@"Bookmarks", @"Title of bookmarks list");
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

- (void)loadBookmarks
{
    NSArray<PTUserBookmark *> *bookmarks = nil;
    if ([self editingEnabled]) {
        bookmarks = [PTBookmarkManager.defaultManager bookmarksForDoc:[self.pdfViewCtrl GetDoc]];
        if (bookmarks.count < 1 && self.documentURL) {
            // Backwards compatibility.
            bookmarks = [PTBookmarkManager.defaultManager legacyBookmarksForDocumentURL:self.documentURL];
        }
    } else {
        // Load file-based bookmarks first, in case the file was previously readonly.
        bookmarks = [PTBookmarkManager.defaultManager legacyBookmarksForDocumentURL:self.documentURL];
        if (bookmarks.count < 1) {
            bookmarks = [PTBookmarkManager.defaultManager bookmarksForDoc:[self.pdfViewCtrl GetDoc]];
        }
    }
    
    if (!bookmarks) {
        bookmarks = @[];
    }
    
    // Sort bookmarks by page number.
    bookmarks = [bookmarks sortedArrayUsingComparator:^NSComparisonResult(PTUserBookmark *first, PTUserBookmark *second) {
        return (first.pageNumber > second.pageNumber);
    }];
    
    self.bookmarks = [bookmarks mutableCopy];
}

- (void)saveBookmarks
{
    if ([self editingEnabled]) {
        [PTBookmarkManager.defaultManager saveBookmarks:self.bookmarks forDoc:[self.pdfViewCtrl GetDoc]];
        
        if (self.documentURL) {
            // After porting, delete file-based bookmarks.
            [PTBookmarkUtils deleteBookmarkDataForDocument:self.documentURL];
        }
    } else if (self.documentURL) {
        // Save bookmarks with legacy API.
        [PTBookmarkManager.defaultManager saveLegacyBookmarks:self.bookmarks forDocumentURL:self.documentURL];
    }
}

#pragma mark - Readonly

- (void)setReadonly:(BOOL)readonly
{
    _readonly = readonly;
    
    if ([self editingEnabled]) {
        self.toolbarItems =
        @[
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBookmark:)],
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
          self.editButtonItem,
          ];
    } else {
        self.toolbarItems = nil;
        
        self.editing = NO;
    }
}

- (BOOL)editingEnabled
{
    return (![self isReadonly] && ![self.toolManager isReadonly]);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    if ([self editingEnabled]) {
        self.toolbarItems =
        @[
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBookmark:)],
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
          self.editButtonItem,
          ];
    } else {
        self.toolbarItems = nil;
    }
    
    // On iPhone we need a button to dismiss the full-screen view. iPad the user can click outside the popover.
    self.showsDoneButton = (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular);

    // Register table view cell class.
    [self.tableView registerClass:[PTBookmarkViewCell class] forCellReuseIdentifier:PTBookmarkViewController_cellReuseIdentifier];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.showsDoneButton = self.view.frame.size.width ==  self.view.window.bounds.size.width;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    self.navigationController.toolbarHidden = NO;
    
    [self loadBookmarks];
    
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [self saveBookmarks];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
	[self setEditing:NO animated:NO];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
    
	if (!editing) {
        // End editing & hide keyboard.
        [self.tableView endEditing:YES];
	}
    
    if (self.showsDoneButton) {
        // Hide Done button while editing.
        UIBarButtonItem *rightBarButtonItem = editing ? nil : self.doneButton;
        
        [self.navigationItem setRightBarButtonItem:rightBarButtonItem animated:animated];
    }
}

- (UITabBarItem *)tabBarItem
{
    UITabBarItem *tabBarItem = [super tabBarItem];
    
    if (![self isTabBarItemSetup]) {
        // Add image to tab bar item.
        tabBarItem.image = [PTToolsUtil toolImageNamed:@"ic_bookmarks_white_24dp"];
        
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

#pragma mark - Actions

-(void)addBookmark:(id)sender
{
    int pageNum = [self.pdfViewCtrl GetCurrentPage];
    
    for(PTUserBookmark* existingBookmark in self.bookmarks)
    {
        if( existingBookmark.pageNumber == pageNum )
        {
            NSString* alertTitle = PTLocalizedString(@"Could Not Add Bookmark", @"Bookmark on same page number exists already.");
            NSString* alertMessage = PTLocalizedString(@"A bookmark on page %d (with the title \"%@\") already exists.", @"Existing user bookmark error.");
            NSString* existingBookmarkTitle = existingBookmark.title;
            
            
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                     message:[NSString stringWithFormat:alertMessage, pageNum, existingBookmarkTitle]
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK",@"")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alertController addAction:okAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
            
            
            return;
        }
    }
    
    NSString *pageLabelTitle = nil;
    
    PTPageLabelManager *pageLabelManager = self.toolManager.pageLabelManager;
    if (pageLabelManager) {
        pageLabelTitle = [pageLabelManager pageLabelTitleForPageNumber:pageNum];
    }
    
    NSString *bookmarkTitle = nil;
    if (pageLabelTitle) {
        NSString *format = PTLocalizedString(@"Page %@", @"Bookmark page label");
        bookmarkTitle = [NSString localizedStringWithFormat:format, pageLabelTitle];
    } else {
        NSString *format = PTLocalizedString(@"Page %d", @"Bookmark page number label");
        bookmarkTitle = [NSString localizedStringWithFormat:format, pageNum];
    }
    
    // Get page SDF object number.
    unsigned int pageObjNum = 0;
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        PTPage *page = [doc GetPage:pageNum];
        if ([page IsValid]) {
            pageObjNum = [[page GetSDFObj] GetObjNum];
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
        pageObjNum = 0;
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    // Create new user bookmark.
    PTUserBookmark *bookmark = [[PTUserBookmark alloc] initWithTitle:bookmarkTitle pageNumber:pageNum pageObjNum:pageObjNum];
    
    NSArray<PTUserBookmark *> *bookmarks = [self.bookmarks arrayByAddingObject:bookmark];
    bookmarks = [bookmarks sortedArrayUsingComparator:^NSComparisonResult(PTUserBookmark *first, PTUserBookmark *second) {
        return (first.pageNumber > second.pageNumber);
    }];
    
    self.bookmarks = [bookmarks mutableCopy];
    [self saveBookmarks];

    // Update the table view for the new item.
    NSUInteger newIndex = [self.bookmarks indexOfObject:bookmark];
    if (newIndex != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
        self.lastCreatedBookmarkIndexPath = indexPath;
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        // Animating the scroll and showing the keyboard (by the newly created bookmark) confuses
        // the UITableView(Controller) when shown in a popover presentation.
        BOOL animated = !self.bookmarksEditableOnCreation;
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:animated];
        
        if (self.bookmarksEditableOnCreation) {
            // We need to wait until the keyboard has shown before resetting the last created
            // index path. The table view jumps around while the keyboard is being shown, which causes
            // the table view cell for the target index path is re-created at least once, due to the
            // table view adjusting its content inset.
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(keyboardDidShow:)
                                                       name:UIKeyboardDidShowNotification
                                                     object:nil];
        }
    } else {
        [self refresh];
    }
    
    // Notify delegate.
    if ([self.delegate respondsToSelector:@selector(bookmarkViewController:didAddBookmark:)]) {
        [self.delegate bookmarkViewController:self didAddBookmark:bookmark];
    }
}

- (void)refresh
{
    [self.tableView reloadData];
}

- (void)dismiss
{
    if ([self.delegate respondsToSelector:@selector(bookmarkViewControllerDidCancel:)]) {
        [self.delegate bookmarkViewControllerDidCancel:self];
    }
}

#pragma mark - Notifications

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (self.bookmarksEditableOnCreation) {
        // Reset target index path for editing.
        self.lastCreatedBookmarkIndexPath = nil;
        
        // Remove observer for keyboard notification.
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.bookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PTBookmarkViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PTBookmarkViewController_cellReuseIdentifier
                                                               forIndexPath:indexPath];
    
    PTUserBookmark *bookmark = self.bookmarks[indexPath.row];
    
    [cell configureWithText:bookmark.title];
    cell.delegate = self;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self editingEnabled];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the bookmark from the data source.
        PTUserBookmark *bookmark = self.bookmarks[indexPath.row];
        [self.bookmarks removeObjectAtIndex:indexPath.row];

        if ([self editingEnabled] && bookmark.bookmark) {
            // Delete bookmark.
            BOOL shouldUnlock = NO;
            @try {
                [self.pdfViewCtrl DocLock:YES];
                shouldUnlock = YES;
                
                [bookmark.bookmark Delete];
            } @catch (NSException *exception) {
                PTLog(@"Exception: %@: %@", exception.name, exception.reason);
            } @finally {
                if (shouldUnlock) {
                    [self.pdfViewCtrl DocUnlock];
                }
            }
        }
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        // Notify delegate.
        if ([self.delegate respondsToSelector:@selector(bookmarkViewController:didRemoveBookmark:)]) {
            [self.delegate bookmarkViewController:self didRemoveBookmark:bookmark];
        }
    }
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check if the last created bookmark is becoming visible.
    if ([indexPath isEqual:self.lastCreatedBookmarkIndexPath]) {
        // Check if the cell's text should be edited.
        if (!self.bookmarksEditableOnCreation) {
            return;
        }
        
        // Edit the cell's text & show keyboard.
        PTBookmarkViewCell *bookmarkCell = nil;
        if ([cell isKindOfClass:[PTBookmarkViewCell class]]) {
            bookmarkCell = (PTBookmarkViewCell *)cell;
            
            bookmarkCell.textFieldEditable = YES;
            [bookmarkCell.textField becomeFirstResponder];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PTUserBookmark *bookmark = self.bookmarks[indexPath.row];
    
    [self.pdfViewCtrl SetCurrentPage:bookmark.pageNumber];
    
    // Notify delegate of selection.
    if ([self.delegate respondsToSelector:@selector(bookmarkViewController:selectedBookmark:)]) {
        [self.delegate bookmarkViewController:self selectedBookmark:bookmark];
    }
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		[self dismiss];
	}
}

#pragma mark - <PTBookmarkViewCellDelegate>

- (void)bookmarkViewCell:(PTBookmarkViewCell *)bookmarkViewCell didChangeText:(NSString *)text
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:bookmarkViewCell];
    if (!indexPath) {
        return;
    }

    // Update title.
    PTUserBookmark *bookmark = self.bookmarks[indexPath.row];
    bookmark.title = text;
}

- (void)bookmarkViewCell:(PTBookmarkViewCell *)bookmarkViewCell didCommitText:(NSString *)text
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:bookmarkViewCell];
    if (!indexPath) {
        return;
    }
    
    // Update title.
    PTUserBookmark *bookmark = self.bookmarks[indexPath.row];
    bookmark.title = text;
    
    [self saveBookmarks];
    
    // When not in edit mode, disable editing of the cell's text after the first time.
    if (self.bookmarksEditableOnCreation && (![self isEditing] && [bookmarkViewCell isTextFieldEditable])) {
        bookmarkViewCell.textFieldEditable = NO;
    }
    
    // Notify delegate.
    if ([self.delegate respondsToSelector:@selector(bookmarkViewController:didModifyBookmark:)]) {
        [self.delegate bookmarkViewController:self didModifyBookmark:bookmark];
    }
}

@end
