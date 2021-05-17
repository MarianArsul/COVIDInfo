//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentViewController.h"

#import "PTDocumentBaseViewControllerPrivate.h"

#import "PTErrors.h"
#import "PTTimer.h"
#import "PTToolsUtil.h"
#import "UTTypes.h"
#import "PTFileAttachmentHandler.h"
#import "PTHalfModalPresentationController.h"
#import "PTPanelViewController.h"
#import "PTPDFViewCtrlAdditions.h"
#import "PTPDFViewCtrlViewController.h"
#import "PTSelectableBarButtonItem.h"
#import "PTDocumentViewSettingsManager.h"
#import "PTDocumentItemProvider.h"

#import "PTPanTool.h"
#import "PTPencilDrawingCreate.h"

#import "UIViewController+PTAdditions.h"
#import "NSLayoutConstraint+PTPriority.h"
#import "NSHTTPURLResponse+PTAdditions.h"
#import "NSURL+PTAdditions.h"
#import "NSObject+PTOverridable.h"
#import "UIDocumentInteractionController+PTAdditions.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "CGGeometry+PTAdditions.h"
#import "PTToolsSettingsManager.h"
#import "PTKeyValueObserving.h"
#import "PTColorDefaults.h"
#import "PTFreeTextCreate.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentViewController()

@property (nonatomic, strong, nullable) NSLayoutConstraint *annotationToolbarOnscreenConstraint;

@end

NS_ASSUME_NONNULL_END

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation PTDocumentViewController
#pragma clang diagnostic pop

#pragma mark - Initialization and helpers

- (void)PTDocumentViewController_commonInit
{

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self PTDocumentViewController_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTDocumentViewController_commonInit];
    }
    return self;
}

#pragma mark - UIViewController

- (void)loadView
{
    [super loadView];
    
    [self loadAnnotationToolbar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.toolbarItems = nil;
        
    self.thumbnailSliderEnabled = YES;
    self.thumbnailSliderController.leadingToolbarItem = self.navigationListsButtonItem;
    self.thumbnailSliderController.trailingToolbarItem = self.thumbnailsButtonItem;
    
    // if iPhone hide search due to lack of space
    // the PTMoreItemsViewController will show search on an iPhone
    [self setToolbarButtonVisibility];
}

- (void)attachAnnotationToolbar
{
    if (self.annotationToolbar.superview) {
        // Already attached.
        return;
    }
    
    UIViewController *viewController;
    if (self.navigationController) {
        // NOTE: UINavigationController's safe area does *not* include the navigation bar.
        viewController = self.navigationController;
    }
    else {
        viewController = self;
    }
    
    [viewController.view addSubview:self.annotationToolbar];
    
    self.annotationToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *onscreenConstraint = [self.annotationToolbar.topAnchor constraintEqualToAnchor:viewController.pt_safeTopAnchor];
    
    NSLayoutConstraint *offscreenConstraint = [self.annotationToolbar.bottomAnchor constraintEqualToAnchor:viewController.view.topAnchor];
    offscreenConstraint.priority = UILayoutPriorityDefaultHigh;
    
    NSAssert(onscreenConstraint.priority > offscreenConstraint.priority,
             @"Onscreen priority must be greater than offscreen priority");
    
    [NSLayoutConstraint activateConstraints:
     @[
         [self.annotationToolbar.leadingAnchor constraintEqualToAnchor:viewController.view.leadingAnchor],
         [self.annotationToolbar.widthAnchor constraintEqualToAnchor:viewController.view.widthAnchor],
         /* Use PTAnnotationToolbar instrinsic height. */
         offscreenConstraint,
     ]];
    
    onscreenConstraint.active = !self.annotationToolbar.hidden;
    
    self.annotationToolbarOnscreenConstraint = onscreenConstraint;
}

- (void)detachAnnotationToolbar
{
    if (!self.annotationToolbar.superview) {
        // Already detached.
        return;
    }
    
    [self.annotationToolbar removeFromSuperview];
    self.annotationToolbarOnscreenConstraint = nil;
}

- (void)loadAnnotationToolbar
{
    self.annotationToolbar = [[PTAnnotationToolbar allocOverridden] initWithToolManager:self.toolManager];
    self.annotationToolbar.delegate = self;
    self.annotationToolbar.hidden = YES;
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self attachAnnotationToolbar];
    
    [self refreshFreehandButtonItemIcon];
    
    // Notifications.
    [self subscribeToUndoManagerNotifications];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Notifications.
    [self unsubscribeFromUndoManagerNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Detach annotation toolbar(s).
    [self detachAnnotationToolbar];
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    
    if (!parent) {
        // Being removed from parent view controller.
        [self stopAutomaticControlHidingTimer];
    }
}

#pragma mark - Items

- (void)loadItems
{
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = @[
        self.moreItemsButtonItem,
        self.annotationButtonItem,
        self.settingsButtonItem,
        self.appSettingsButtonItem,
        self.readerModeButtonItem,
        self.freehandButtonItem,
    ];
    
    self.moreItems = @[
        self.searchButtonItem,
        self.shareButtonItem,
        self.exportButtonItem,
        self.addPagesButtonItem,
    ];
    
    self.appSettingsButtonHidden = YES;
}

#pragma mark - <UIContentContainer>

-(void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [self setToolbarButtonVisibility];
}

#pragma mark - PTDocumentBaseViewControllerPrivate

- (void)toolsSettingsDidChange:(PTKeyValueObservedChange *)change
{
    [super toolsSettingsDidChange:change];
    
    if([change.keyPath isEqualToString:PT_CLASS_KEY(PTToolsSettingsManager, showInkInMainToolbar)])
    {
        [self setToolbarButtonVisibility];
    }
}

#pragma mark - Bar button items

-(void)setToolbarButtonVisibility
{
    self.freehandButtonHidden = self.toolManager.isReadonly || !PTToolsSettingsManager.sharedManager.showInkInMainToolbar;
    
    NSMutableArray* moreItems = [[NSMutableArray alloc] init];
    
    if( PTToolsSettingsManager.sharedManager.showTextSearchInMainToolbar )
    {
        NSMutableArray* moreItems2 = [self.moreItemsViewController.items mutableCopy];
        [moreItems2 removeObject:self.searchButtonItem];
        self.moreItemsViewController.items = moreItems2;
        [self addItemToRightBarButtonItems:self.searchButtonItem];
    }
    
    if( !self.searchButtonHidden )
    {
        if( PTToolsSettingsManager.sharedManager.showTextSearchInMainToolbar )
        {
            [self addItemToRightBarButtonItems:self.searchButtonItem];
        }
        else
        {
            [self removeItemFromRightBarButtonItems:self.searchButtonItem];
            [moreItems addObject:self.searchButtonItem];
        }
    }
    
    if( !self.shareButtonHidden )
    {
        [moreItems addObject:self.shareButtonItem];
    }
    
    if( !self.exportButtonHidden )
    {
        [moreItems addObject:self.exportButtonItem];
    }
    
    if( !self.addPagesButtonHidden )
    {
        [moreItems addObject:self.addPagesButtonItem];
    }
    
    self.moreItemsViewController.items = moreItems;
}

// helpers
-(void)removeItemFromRightBarButtonItems:(UIBarButtonItem*)item
{
    NSMutableArray* rightButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    [rightButtonItems removeObject:item];
    self.navigationItem.rightBarButtonItems = [rightButtonItems copy];
    
    NSMutableArray* moreButtonItems = [self.moreItemsViewController.items mutableCopy];
    [moreButtonItems removeObject:item];
    self.moreItemsViewController.items = [moreButtonItems copy];
}

-(void)addItemToRightBarButtonItems:(UIBarButtonItem*)item
{
    NSMutableArray* rightButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    
    if( [rightButtonItems containsObject:item] )
    {
        return;
    }
    
    [rightButtonItems addObject:item];
    self.navigationItem.rightBarButtonItems = [rightButtonItems copy];
}

-(BOOL)isRightBarButtonItemHidden:(UIBarButtonItem*)item
{
    return ([self.navigationItem.rightBarButtonItems containsObject:item] == NO) && ([self.moreItemsViewController.items containsObject:item] == NO);
}

- (void)setRightBarButtonItem:(UIBarButtonItem *)item isHidden:(BOOL)hidden {
    
    if( hidden == [self isRightBarButtonItemHidden:item] )
        return;
    
    if( hidden )
    {
        [self removeItemFromRightBarButtonItems:item];
    }
    else
    {
        [self addItemToRightBarButtonItems:item];
    }
}

#pragma mark freehandButtonHidden

-(BOOL)isFreehandButtonHidden
{
    return [self isRightBarButtonItemHidden:self.freehandButtonItem];
}

-(void)setFreehandButtonHidden:(BOOL)freehandButtonHidden
{
    [self setRightBarButtonItem:self.freehandButtonItem isHidden:freehandButtonHidden];
}

#pragma mark readerModeButtonHidden

-(BOOL)isReaderModeButtonHidden
{
    return [self isRightBarButtonItemHidden:self.readerModeButtonItem];
}

-(void)setReaderModeButtonHidden:(BOOL)readerModeButtonHidden
{
    [self setRightBarButtonItem:self.readerModeButtonItem isHidden:readerModeButtonHidden];
}

#pragma mark appSettingsButtonHidden

-(BOOL)isAppSettingsButtonHidden
{
    return [self isRightBarButtonItemHidden:self.appSettingsButtonItem];
}

-(void)setAppSettingsButtonHidden:(BOOL)appSettingsButtonHidden
{
    [self setRightBarButtonItem:self.appSettingsButtonItem isHidden:appSettingsButtonHidden];
}

#pragma mark viewerSettingsButtonHidden

-(BOOL)isViewerSettingsButtonHidden
{
    return [self isRightBarButtonItemHidden:self.settingsButtonItem];
}

-(void)setViewerSettingsButtonHidden:(BOOL)viewerSettingsButtonHidden
{
    [self setRightBarButtonItem:self.settingsButtonItem isHidden:viewerSettingsButtonHidden];
}

#pragma mark shareButtonHidden

-(BOOL)isShareButtonHidden
{
    return [self isRightBarButtonItemHidden:self.shareButtonItem];
}

-(void)setShareButtonHidden:(BOOL)shareButtonHidden
{
    [self setRightBarButtonItem:self.shareButtonItem isHidden:shareButtonHidden];
}

#pragma mark searchButtonHidden

-(BOOL)isSearchButtonHidden
{
    return [self isRightBarButtonItemHidden:self.searchButtonItem];
}

-(void)setSearchButtonHidden:(BOOL)searchButtonHidden
{
    [self setRightBarButtonItem:self.searchButtonItem isHidden:searchButtonHidden];
}

#pragma mark exportButtonHidden

-(BOOL)isExportButtonHidden
{
    return [self isRightBarButtonItemHidden:self.exportButtonItem];
}

-(void)setExportButtonHidden:(BOOL)exportButtonHidden
{
    [self setRightBarButtonItem:self.exportButtonItem isHidden:exportButtonHidden];
}

#pragma mark annotationToolbarButtonHidden

-(BOOL)isAnnotationToolbarButtonHidden
{
    return [self isRightBarButtonItemHidden:self.annotationButtonItem];
}

-(void)setAnnotationToolbarButtonHidden:(BOOL)annotationToolbarButtonHidden
{
    [self setRightBarButtonItem:self.annotationButtonItem isHidden:annotationToolbarButtonHidden];
}

#pragma mark moreItemsButtonHidden

-(BOOL)isMoreItemsButtonHidden
{
    return [self isRightBarButtonItemHidden:self.moreItemsButtonItem];
}

-(void)setMoreItemsButtonHidden:(BOOL)moreItemsButtonHidden
{
    [self setRightBarButtonItem:self.moreItemsButtonItem isHidden:moreItemsButtonHidden];
}

#pragma mark - addPagesButtonHidden

-(BOOL)isAddPagesButtonHidden
{
    return [self isRightBarButtonItemHidden:self.addPagesButtonItem];
}

-(void)setAddPagesButtonHidden:(BOOL)addPagesButtonHidden
{
    [self setRightBarButtonItem:self.addPagesButtonItem isHidden:addPagesButtonHidden];
}

#pragma mark - thumbnailBrowserButtonHidden

-(BOOL)isThumbnailBrowserButtonHidden
{
    return [self.thumbnailSliderController.trailingToolbarItems containsObject:self.thumbnailsButtonItem] == NO;
}

-(void)setThumbnailBrowserButtonHidden:(BOOL)thumbnailBrowserButtonHidden
{
    if( thumbnailBrowserButtonHidden == [self isThumbnailBrowserButtonHidden] )
        return;
    
    NSMutableArray* trailingToolbarItems = [self.thumbnailSliderController.trailingToolbarItems mutableCopy];
    
    if( thumbnailBrowserButtonHidden )
    {
        [trailingToolbarItems removeObject:self.thumbnailsButtonItem];
    }
    else
    {
        [trailingToolbarItems addObject:self.thumbnailsButtonItem];
    }
    
    self.thumbnailSliderController.trailingToolbarItems = [trailingToolbarItems copy];
}

#pragma mark navigationListsButtonHidden

-(BOOL)isNavigationListsButtonHidden
{
    return [self.thumbnailSliderController.leadingToolbarItems containsObject:self.navigationListsButtonItem] == NO;
}

-(void)setNavigationListsButtonHidden:(BOOL)navigationListsButtonHidden
{
    if( navigationListsButtonHidden == [self isNavigationListsButtonHidden] )
        return;
    
    NSMutableArray* leadingToolbarItems = [self.thumbnailSliderController.leadingToolbarItems mutableCopy];
    
    if( navigationListsButtonHidden )
    {
        [leadingToolbarItems removeObject:self.navigationListsButtonItem];
    }
    else
    {
        [leadingToolbarItems addObject:self.navigationListsButtonItem];
    }
    
    self.thumbnailSliderController.leadingToolbarItems = [leadingToolbarItems copy];
}

#pragma mark - undoManager

- (NSUndoManager *)undoManager
{
    // Use the tool manager's undo manager (which tracks document level undo/redo-able actions).
    // NOTE: The tool manager is not part of the responder chain so its undo manager would not be
    // used otherwise.
    return self.toolManager.undoManager;
}

- (void)updateButtonsForUndoManagerState
{
    self.undoButtonItem.enabled = self.toolManager.undoManager.canUndo;
    self.redoButtonItem.enabled = self.toolManager.undoManager.canRedo;
}

#pragma mark Notifications

- (void)subscribeToUndoManagerNotifications
{
    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
    
    [notificationCenter addObserver:self
                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                               name:NSUndoManagerDidCloseUndoGroupNotification
                             object:self.toolManager.undoManager];
    
    [notificationCenter addObserver:self
                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                               name:NSUndoManagerDidUndoChangeNotification
                             object:self.toolManager.undoManager];
    
    [notificationCenter addObserver:self
                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                               name:NSUndoManagerDidRedoChangeNotification
                             object:self.toolManager.undoManager];
    
    // Update buttons at time of subscription.
    [self updateButtonsForUndoManagerState];
}

- (void)unsubscribeFromUndoManagerNotifications
{
    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;

    [notificationCenter removeObserver:self
                                  name:NSUndoManagerDidCloseUndoGroupNotification
                                object:self.toolManager.undoManager];
    
    [notificationCenter removeObserver:self
                                  name:NSUndoManagerDidUndoChangeNotification
                                object:self.toolManager.undoManager];
    
    [notificationCenter removeObserver:self
                                  name:NSUndoManagerDidRedoChangeNotification
                                object:self.toolManager.undoManager];
}

- (void)undoManagerStateDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.undoManager) {
        return;
    }
    
    [self updateButtonsForUndoManagerState];
}

#pragma mark - Annotation toolbar

- (PTAnnotationToolbar *)annotationToolbar
{
    [self loadViewIfNeeded];
    
    NSAssert(_annotationToolbar, @"Annotation toolbar was not loaded");
    
    return _annotationToolbar;
}

#pragma mark - Toolbar bar button callbacks

- (void)toggleAnnotationToolbar
{
    [self attachAnnotationToolbar];
    
    [self toggleToolbar:self.annotationToolbar
         withConstraint:self.annotationToolbarOnscreenConstraint];
}

- (void)toggleToolbar:(UIToolbar *)toolbar withConstraint:(NSLayoutConstraint *)constraint
{
//    [self hideViewControllers];
    
    BOOL initiallyHidden = toolbar.isHidden;
    
    if (initiallyHidden) {
        // show the toolbar
        [toolbar.superview bringSubviewToFront:toolbar];
        
//        [self.toolManager setTool:[[PTPanTool alloc] initWithPDFViewCtrl:self.pdfViewCtrl]];
        
        // Notify delegate.
        if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:willShowToolbar:)]) {
            [self.toolbarDelegate documentViewController:self willShowToolbar:toolbar];
        }
    } else {
        // hide the toolbar
        // Notify delegate.
        if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:willHideToolbar:)]) {
            [self.toolbarDelegate documentViewController:self willHideToolbar:toolbar];
        }
    }
    
    // Apply any pending layout updates.
    [UIView performWithoutAnimation:^{
        [toolbar.superview layoutIfNeeded];
    }];
    
    // Toggle constraint.
    constraint.active = initiallyHidden;
    
    // Animate toolbar into new state.
    [UIView animateWithDuration:0.2f animations:^(void) {
        // Animate layout changes.
        [toolbar.superview layoutIfNeeded];
        
        if (initiallyHidden) {
            toolbar.hidden = NO;
            toolbar.alpha = 1.0;
        }
        else {
            toolbar.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        if (!initiallyHidden) {
            // it is now hidden
            [self.toolManager setTool:[[PTPanTool alloc] initWithPDFViewCtrl:self.pdfViewCtrl]];
            toolbar.hidden = YES;
            
            // Notify delegate.
            if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:didHideToolbar:)]) {
                [self.toolbarDelegate documentViewController:self didHideToolbar:toolbar];
            }
        } else {
            
            
            // Notify delegate.
            if ([self.toolbarDelegate respondsToSelector:@selector(documentViewController:didShowToolbar:)]) {
                [self.toolbarDelegate documentViewController:self didShowToolbar:toolbar];
            }
        }
    }];
}

-(void)setToolToFreehand
{
    BOOL isPencilTool = [self.toolManager freehandUsesPencilKit];
    if (!isPencilTool) {
        PTFreeHandCreate* fhc = [[PTFreeHandCreate alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
        fhc.multistrokeMode = YES;
        fhc.delegate = self.annotationToolbar;
        fhc.backToPanToolAfterUse = NO;
        fhc.requiresEditSupport = YES;
        self.toolManager.tool = fhc;
    } else if ([self.toolManager freehandUsesPencilKit]) {
        if (@available(iOS 13.1, *) ) {
            PTPencilDrawingCreate* pdc = [[PTPencilDrawingCreate alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
            pdc.backToPanToolAfterUse = NO;
            pdc.shouldShowToolPicker = YES;
            self.toolManager.tool = pdc;
        }
    }
}

- (void)undo:(id)sender
{
    [self.undoManager undo];
}

- (void)redo:(id)sender
{
    [self.undoManager redo];
}

#pragma mark - Annotation, FindText delegates

// The "x" on the annotation bar was clicked. Hide the annotation bar
- (void)annotationToolbarDidCancel:(PTAnnotationToolbar *)annotationToolbar {
    if (annotationToolbar.hidesWithEditToolbar) {
        annotationToolbar.hidesWithEditToolbar = NO;
    }
    
    [self toggleAnnotationToolbar];
    // make sure the annotation toolbar doesn't happen to disappear right away, wait the standard 5 seconds
    
    [self restartAutomaticControlHidingTimerIfNeeded];
}

- (BOOL)toolShouldGoBackToPan:(PTAnnotationToolbar*)annotationToolbar
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:@"stickyAnnotationToolbar"];
}

#pragma mark - <PTToolManagerDelegate>

- (void)toolManagerToolChanged:(PTToolManager *)toolManager
{
    PTTool *tool = toolManager.tool;
    
    // Show annotation toolbar if the tool requires edit support (PTEditToolbar).
    BOOL shouldShowToolbar = YES;
    // Unless we're activating PTPencilDrawingCreate by just drawing on the doc with Apple Pencil
    if (@available(iOS 13.1, *)) {
        if ([tool isKindOfClass:[PTPencilDrawingCreate class]]){
            shouldShowToolbar = !tool.backToPanToolAfterUse;
        }
    }

    if ([tool isKindOfClass:[PTCreateToolBase class]] &&
        ((PTCreateToolBase *)tool).requiresEditSupport && shouldShowToolbar) {
        // The current tool requires editing UI support.
        if (self.annotationToolbar.hidden) {
            [self setControlsHidden:NO animated:NO];
            
            [self toggleAnnotationToolbar];
            
            self.annotationToolbar.hidesWithEditToolbar = YES;
        }
    }
    
    // if no annot toolbar (tool activated from long-press in pan tool).
    if (self.annotationToolbar.hidden) {
        tool.backToPanToolAfterUse = YES;
    }
    
    // Uncomment the following code to show a dialog asking for an annotation author.
//    // Set up the annotation author.
//    NSString *annotationAuthor = [NSUserDefaults.standardUserDefaults stringForKey:@"annotation_author"];
//
//    if ((annotationAuthor.length == 0)
//        && tool.createsAnnotation && (tool.annotationAuthor.length == 0)
//        && ![tool isKindOfClass:[PTDigitalSignatureTool class]]) {
//
//        // there is no annotation author, check if we have asked them for one
//        BOOL alreadyAsked =  [NSUserDefaults.standardUserDefaults boolForKey:@"askedForAnnotAuthor"];
//
//        if (!alreadyAsked) {
//            [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"askedForAnnotAuthor"];
//
//            [self askForAnnotationAuthor];
//        }
//    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

#pragma mark Freehand

@synthesize freehandButtonItem = _freehandButtonItem;

- (UIBarButtonItem *)freehandButtonItem
{
    if (!_freehandButtonItem) {
        _freehandButtonItem = [[UIBarButtonItem alloc] initWithImage:[self freehandItemImage]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(setToolToFreehand)];
        _freehandButtonItem.title = PTLocalizedString(@"Freehand Drawing",
                                                      @"Freehand Drawing button title");
    }
    
    return _freehandButtonItem;
}

-(void)refreshFreehandButtonItemIcon
{
    _freehandButtonItem.image = [self freehandItemImage];
}

-(UIImage*)freehandItemImage
{
    UIImage* image;
    
    if( [self.toolManager freehandUsesPencilKit] )
    {
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"pencil.tip.crop.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
        }
    }
    else
    {
        image = [PTToolsUtil toolImageNamed:@"Annotation/Ink/Icon"];
    }
    
    return image;
}

#pragma mark Annotation (toolbar)

@synthesize annotationButtonItem = _annotationButtonItem;

- (UIBarButtonItem *)annotationButtonItem
{
    if (!_annotationButtonItem) {
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"square.and.pencil" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_edit_black_24dp"];
        }

        _annotationButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(toggleAnnotationToolbar)];
        
        _annotationButtonItem.title = PTLocalizedString(@"Annotation Toolbar",
                                                        @"Annotation Toolbar button title");
    }
    return _annotationButtonItem;
}

@synthesize undoButtonItem = _undoButtonItem;

- (UIBarButtonItem *)undoButtonItem
{
    if (!_undoButtonItem) {
        UIImage *image;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"arrow.uturn.left"
                            withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        } else {
            image = [PTToolsUtil toolImageNamed:@"ic_undo_black_24dp"];
        }
        
        _undoButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(undo:)];
        _undoButtonItem.title = PTLocalizedString(@"Undo",
                                                  @"Undo button title");
    }
    return _undoButtonItem;
}

@synthesize redoButtonItem = _redoButtonItem;

- (UIBarButtonItem *)redoButtonItem
{
    if (!_redoButtonItem) {
        UIImage *image;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"arrow.uturn.right"
                            withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium]];
        } else {
            image = [PTToolsUtil toolImageNamed:@"ic_redo_black_24dp"];
        }

        _redoButtonItem = [[UIBarButtonItem alloc] initWithImage:image
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(redo:)];
        _redoButtonItem.title = PTLocalizedString(@"Redo",
                                                  @"Redo button title");
    }
    return _redoButtonItem;
}

#pragma mark - Annotation toolbar

- (BOOL)isAnnotationToolbarHidden
{
    return [self.annotationToolbar isHidden];
}

- (void)setAnnotationToolbarHidden:(BOOL)hidden
{
    if ([self isAnnotationToolbarHidden] == hidden) {
        // No change.
        return;
    }
    
    [self toggleAnnotationToolbar];
}

- (void)setReflowHidden:(BOOL)hidden
{
    [super setReflowHidden:hidden];
    
    self.freehandButtonItem.enabled = hidden;
    self.annotationButtonItem.enabled = hidden;
}

-(void)toggleAnnotationToolbarKBShortcut{
    if (self.controlsHidden) {
        [self setControlsHidden:NO animated:NO];
    }
    [self toggleAnnotationToolbar];
}

- (NSArray<UIKeyCommand *> *)keyCommands
{
    return [[super keyCommands] arrayByAddingObjectsFromArray:@[
        // Toggle Annotation Toolbar
        [UIKeyCommand keyCommandWithInput:@"A"
                            modifierFlags:(UIKeyModifierCommand | UIKeyModifierShift)
                                   action:@selector(toggleAnnotationToolbarKBShortcut)
                     discoverabilityTitle:PTLocalizedString(@"Toggle Annotation Toolbar",
                                                            @"Toggle Annotation Toolbar keyboard shortcut title")],
    ]];
}

#pragma mark - SubclassingHooks

- (void)didOpenDocument
{
    if ([self.delegate respondsToSelector:@selector(documentViewControllerDidOpenDocument:)]) {
        [self.delegate documentViewControllerDidOpenDocument:self];
    }
}

- (void)handleDocumentOpeningFailureWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(documentViewController:
                                                    didFailToOpenDocumentWithError:)]) {
        [self.delegate documentViewController:self
               didFailToOpenDocumentWithError:error];
    }
}

- (void)didBecomeInvalid
{
    if ([self.delegate respondsToSelector:@selector(documentViewControllerDidBecomeInvalid:)]) {
        [self.delegate documentViewControllerDidBecomeInvalid:self];
    }
}

- (BOOL)shouldExportCachedDocumentAtURL:(NSURL *)cachedDocumentURL
{
    if ([self.delegate respondsToSelector:@selector(documentViewController:
                                                    shouldExportCachedDocumentAtURL:)]) {
        return [self.delegate documentViewController:self
                     shouldExportCachedDocumentAtURL:cachedDocumentURL];
    }
    return YES;
}

- (NSURL *)destinationURLforDocumentAtURL:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(documentViewController:
                                                    destinationURLForDocumentAtURL:)]) {
        return [self.delegate documentViewController:self
                      destinationURLForDocumentAtURL:url];
    }
    return nil;
}

- (BOOL)shouldDeleteCachedDocumentAtURL:(NSURL *)cachedDocumentURL
{
    if ([self.delegate respondsToSelector:@selector(documentViewController:
                                                    shouldDeleteCachedDocumentAtURL:)]) {
        [self.delegate documentViewController:self
              shouldDeleteCachedDocumentAtURL:cachedDocumentURL];
    }
    return NO;
}

- (BOOL)shouldHideControls
{
    const BOOL hide = [super shouldHideControls];
    
    return (hide || [self.annotationToolbar isHidden]);
}

- (BOOL)shouldShowControls
{
    const BOOL show = [super shouldShowControls];
    
    return (show || ![self.annotationToolbar isHidden]);
}

@end
