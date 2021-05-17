//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationDocumentController.h"

#import "PTBaseCollaborationManager.h"
#import "PTBaseCollaborationManager+Private.h"
#import "PTCollaborationManager.h"
#import "PTCollaborationAnnotationViewController.h"
#import "PTCollaborationAnnotationReplyViewController.h"
#import "PTSelectableBarButtonItem.h"

#import "PTToolsUtil.h"

#import "PTPDFViewCtrl+PTAdditions.h"

@interface PTCollaborationDocumentController () <PTAnnotationManagerDelegate>
{
    PTSelectableBarButtonItem *_navigationListsBadgeItem;
}
@property (nonatomic, readonly) PTSelectableBarButtonItem *navigationListsButtonItem;

@property (nonatomic, strong, nullable) PTBaseCollaborationManager *collaborationManager;

@end

@implementation PTCollaborationDocumentController

- (instancetype)initWithCollaborationService:(id<PTCollaborationServerCommunication>)service
{
    self = [super init];
    if (self) {
        _service = service;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(documentViewControllerDidOpenDocumentWithNotification:)
                                                   name:PTDocumentViewControllerDidOpenDocumentNotification
                                                 object:self];
        
        // Respect the annotation author when deciding if an annotation can be edited.
        self.toolManager.annotationAuthorCheckEnabled = YES;
        
        // Don't automatically open text (sticky note) annotations.
        self.toolManager.textAnnotationOptions.opensPopupOnTap = NO;
        
        // Copy annotated text to text markup contents.
        self.toolManager.highlightAnnotationOptions.copiesAnnotatedTextToContents = YES;
        self.toolManager.underlineAnnotationOptions.copiesAnnotatedTextToContents = YES;
        self.toolManager.squigglyAnnotationOptions.copiesAnnotatedTextToContents = YES;
        self.toolManager.strikeOutAnnotationOptions.copiesAnnotatedTextToContents = YES;
        
        // Sign signature fields with stamps
        self.toolManager.signatureAnnotationOptions.signSignatureFieldsWithStamps = YES;
        
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collaborationAnnotationListHidden = NO;
}

- (PTSelectableBarButtonItem *)navigationListsButtonItem
{
    if (!_navigationListsBadgeItem) {
        UIBarButtonItem *superItem = [super navigationListsButtonItem];
        
        _navigationListsBadgeItem = [[PTSelectableBarButtonItem alloc] initWithImage:superItem.image
                                                                               style:superItem.style
                                                                              target:superItem.target
                                                                              action:superItem.action];
    }
    return _navigationListsBadgeItem;
}

#pragma mark - Collaboration reply view controller

@synthesize collaborationReplyViewController = _collaborationReplyViewController;

- (PTCollaborationAnnotationReplyViewController *)collaborationReplyViewController
{
    if (!_collaborationReplyViewController) {
        // Allow nil return before collaboration manager is loaded.
        if (!self.collaborationManager) {
            return nil;
        }
        
        _collaborationReplyViewController = [[PTCollaborationAnnotationReplyViewController allocOverridden] initWithCollaborationManager:self.collaborationManager];
        
        UIBarButtonItem *annotationListItem = [[UIBarButtonItem alloc] initWithImage:[PTToolsUtil toolImageNamed:@"ic_list_black_24px"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(showAnnotationListFromReplies)];
        
        _collaborationReplyViewController.navigationItem.rightBarButtonItem = annotationListItem;
    }
    return _collaborationReplyViewController;
}

#pragma mark - Collaboration annotation view controller

@synthesize collaborationAnnotationViewController = _collaborationAnnotationViewController;

- (PTCollaborationAnnotationViewController *)collaborationAnnotationViewController
{
    if (!_collaborationAnnotationViewController) {
        _collaborationAnnotationViewController = [[PTCollaborationAnnotationViewController allocOverridden] init];
    }
    return _collaborationAnnotationViewController;
}

- (BOOL)isCollaborationAnnotationListHidden
{
    // Ensure view is loaded before checking if collaboration annotation view controller is
    // included in the navigation lists view controller.
    [self loadViewIfNeeded];
    
    return [self.navigationListsViewController.listViewControllers containsObject:self.collaborationAnnotationViewController];
}

- (void)setCollaborationAnnotationListHidden:(BOOL)hidden
{
    UIViewController *viewController = self.collaborationAnnotationViewController;
    
    if (hidden) {
        [self.navigationListsViewController removeListViewController:viewController];
    } else {
        // Check if the normal annotation view controller is included in the list of view controllers
        // managed by the PTNavigationListsViewController.
        PTAnnotationViewController *annotationViewController = self.navigationListsViewController.annotationViewController;
        NSUInteger annotationListIndex = [self.navigationListsViewController.listViewControllers indexOfObject:annotationViewController];
        
        if (annotationListIndex != NSNotFound) {
            // Replace the normal annotation view controller with the collaboration version.
            NSMutableArray<UIViewController *> *listViewControllers = [self.navigationListsViewController.listViewControllers mutableCopy];
            [listViewControllers replaceObjectAtIndex:annotationListIndex withObject:viewController];
            self.navigationListsViewController.listViewControllers = [listViewControllers copy];
        } else {
            // Add the collaboration annotation view controller to the end.
            [self.navigationListsViewController addListViewController:viewController];
        }
    }
}

- (CGRect)screenRectForAnnot:(PTAnnot *)annot pageNumber:(int)pageNumber
{
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        if (![annot IsValid]) {
            return CGRectNull;
        }
        
        PTPDFRect *annotRect = [annot GetRect];

        return [self.pdfViewCtrl PDFRectPage2CGRectScreen:annotRect PageNumber:pageNumber];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    return CGRectNull;
}

- (void)showAnnotationReplies
{
    PTAnnot *annot = self.toolManager.tool.currentAnnotation;
    int pageNumber = self.toolManager.tool.annotationPageNumber;
    if (!annot || pageNumber < 1) {
        return;
    }
    
    NSString *annotationIdentifier = [self.pdfViewCtrl uniqueIDForAnnot:annot];
    if (annotationIdentifier.length == 0) {
        NSLog(@"Failed to get identifier for selected annotation");
        return;
    }
    
    PTCollaborationAnnotationReplyViewController *replyViewController =self.collaborationReplyViewController;
    if (!replyViewController) {
        NSLog(@"Failed to get collaboration reply view controller");
        return;
    }
    replyViewController.currentAnnotationIdentifier = annotationIdentifier;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:replyViewController];
    
    // Show in popover for regular horizontal size class.
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        nav.modalPresentationStyle = UIModalPresentationPopover;
        
        // Anchor popover to annot rect.
        CGRect annotRect = [self screenRectForAnnot:annot pageNumber:pageNumber];
        if (CGRectIsNull(annotRect)) {
            // Failed to get annot rect.
            // Anchor popover to PDFViewCtrl center.
            CGRect bounds = self.pdfViewCtrl.bounds;
            annotRect = CGRectMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds), 0, 0);
        }
        nav.popoverPresentationController.sourceView = self.pdfViewCtrl;
        nav.popoverPresentationController.sourceRect = annotRect;
        nav.popoverPresentationController.canOverlapSourceViewRect = YES;
    } else {
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showAnnotationListFromReplies
{
    if (self.collaborationReplyViewController.presentingViewController) {
        [self.collaborationReplyViewController dismissViewControllerAnimated:YES completion:^{
            [self showCollaborationAnnotationList];
        }];
    } else {
        [self showCollaborationAnnotationList];
    }
}

- (void)showCollaborationAnnotationList
{
    // Ensure collaboration annotation list is included in navigation lists controller.
    self.collaborationAnnotationListHidden = NO;
    // Select the collaboration annotation list.
    self.navigationListsViewController.selectedViewController = self.collaborationAnnotationViewController;
    [self showNavigationLists];
}

#pragma mark - <PTToolManagerDelegate>

- (BOOL)toolManager:(PTToolManager *)toolManager shouldShowMenu:(UIMenuController *)menuController forAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    BOOL shouldShowMenu = [super toolManager:toolManager shouldShowMenu:menuController forAnnotation:annotation onPageNumber:pageNumber];
    if (!shouldShowMenu) {
        return NO;
    }
    
    // Skip for long-press menu (no annotation selected).
    if (!annotation) {
        return YES;
    }
    
    // Do not replace menu item before the collaboration manager is loaded.
    if (!self.collaborationManager) {
        return YES;
    }

    UIMenuItem *noteMenuItem = nil;
    NSUInteger index = 0;
    for (UIMenuItem *menuItem in menuController.menuItems) {
        if (PT_SelectorEqualToSelector(menuItem.action, @selector(editSelectedAnnotationNote))) {
            noteMenuItem = menuItem;
            break;
        }
        index++;
    }
    if (noteMenuItem) {
        UIMenuItem *commentsMenuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Comments",
                                                                                           @"Annotation comments menu item")
                                                                  action:@selector(showAnnotationReplies)];
        
        NSMutableArray<UIMenuItem *> *mutableItems = [menuController.menuItems mutableCopy];
        [mutableItems replaceObjectAtIndex:index withObject:commentsMenuItem];
        menuController.menuItems = [mutableItems copy];
    } else {
        PTExtendedAnnotType annotType = PTExtendedAnnotTypeUnknown;
        
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            
            annotType = annotation.extendedAnnotType;
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        }
        @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
        
        if (annotType == PTExtendedAnnotTypeFreeText ||
            annotType == PTExtendedAnnotTypeCallout) {
            // Ensure that the Comments menu item is not added more than once.
            UIMenuItem *commentsMenuItem = nil;
            for (UIMenuItem *menuItem in menuController.menuItems) {
                if (PT_SelectorEqualToSelector(menuItem.action, @selector(showAnnotationReplies))) {
                    commentsMenuItem = menuItem;
                    break;
                }
            }
            
            if (!commentsMenuItem) {
                commentsMenuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Comments",
                                                                                       @"Annotation comments menu item")
                                                              action:@selector(showAnnotationReplies)];
                
                NSMutableArray<UIMenuItem *> *mutableItems = [menuController.menuItems mutableCopy];
                [mutableItems insertObject:commentsMenuItem atIndex:0];
                menuController.menuItems = [mutableItems copy];
            }
        }
    }
    
    return YES;
}

#pragma mark - Notifications

-(void)documentViewControllerDidOpenDocumentWithNotification:(NSNotification *)notification
{
    if (notification.object != self || self.service.userID == Nil) {
        
        NSLog(@"Cannot create a collaborationManager without a username.");
        NSAssert(self.service.userID != Nil, @"Cannot create a collaborationManager without a username.");
        return;
    }
    
    
    // Create the collaboration manager and connect it with the collaboration service.
    self.collaborationManager = [[PTCollaborationManager alloc] initWithToolManager:self.toolManager
                                                                             userId:self.service.userID];
    [self.collaborationManager registerServerCommunicationComponent:self.service];
    
    self.collaborationManager.annotationManager.delegate = self;
        
    self.collaborationAnnotationViewController.collaborationManager = self.collaborationManager;
    
    // Notify the service that the document has been loaded.
    [self.service documentLoaded];
}

#pragma mark - <PTAnnotationManagerDelegate>

- (void)annotationManager:(PTAnnotationManager *)annotationManager documentUnreadCountDidChange:(int)unreadCount
{
    _navigationListsBadgeItem.badgeHidden = (unreadCount == 0);
}

@end
