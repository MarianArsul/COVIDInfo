//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationAnnotationReplyViewController.h"

#import "PTBaseCollaborationManager+Private.h"

#import "PTAnnotationReplyMessagesViewController.h"
#import "PTAnnotationReplyInputViewController.h"
#import "PTToolsUtil.h"
#import "PTErrors.h"

#import "PTAnnot+PTAdditions.h"
#import "PTMarkup+PTReply.h"
#import "PTPDFViewCtrl+PTAdditions.h"
#import "UIViewController+PTAdditions.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTCollaborationAnnotationReplyViewController () <PTAnnotationReplyInputViewControllerDelegate>

@property (nonatomic, strong, nullable) PTManagedAnnotation *currentAnnotation;

@property (nonatomic, strong) PTAnnotationReplyMessagesViewController *messagesViewController;
@property (nonatomic, strong) PTAnnotationReplyInputViewController *replyInputViewController;

@property (nonatomic) BOOL adjustsInsetsForInputViewController;

@property (nonatomic, assign) BOOL viewConstraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTCollaborationAnnotationReplyViewController

- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _collaborationManager = collaborationManager;
        
        _adjustsInsetsForInputViewController = YES;
        
        self.title = PTLocalizedString(@"Comments", @"Annotation reply view controller title");
    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:PTLocalizedString(@"Close",
                                                                                     @"Close button title")
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(dismiss:)];
    self.navigationItem.leftBarButtonItem = item;
    
    // Reply messages view controller.
    self.messagesViewController = [[PTAnnotationReplyMessagesViewController alloc] initWithCollaborationManager:self.collaborationManager];
    
    self.messagesViewController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    // View controller containment.
    [self addChildViewController:self.messagesViewController];
    
    self.messagesViewController.view.frame = self.view.bounds;
    self.messagesViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.messagesViewController.view];
    
    [self.messagesViewController didMoveToParentViewController:self];
    
    self.replyInputViewController = [[PTAnnotationReplyInputViewController alloc] init];
    self.replyInputViewController.delegate = self;
    
    // View controller containment.
    [self addChildViewController:self.replyInputViewController];
    self.replyInputViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.replyInputViewController.view];
    [self.replyInputViewController didMoveToParentViewController:self];
    
    // Schedule view constraints update.
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Constraints

- (void)loadViewConstraints
{
    self.replyInputViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.replyInputViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [self.replyInputViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [self.replyInputViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
       [self.replyInputViewController.view.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.layoutMarginsGuide.topAnchor],
       /* Use replyInputViewController intrinsic height. */
       ]];
}

- (void)updateViewConstraints
{
    // Load view constraints if necessary.
    if (!self.viewConstraintsLoaded) {
        [self loadViewConstraints];
        
        // View constraints are loaded.
        self.viewConstraintsLoaded = YES;
    }
    
    // Call super implementation as final step.
    [super updateViewConstraints];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (@available(iOS 11.0, *)) {
        // Update messages VC bottom safe area inset.
        UIEdgeInsets additionalSafeAreaInsets = self.messagesViewController.additionalSafeAreaInsets;
        
        if (self.adjustsInsetsForInputViewController) {
            CGFloat replyInputHeight = CGRectGetHeight(self.replyInputViewController.view.frame);
            
            // Inset messages VC by reply input VC height (excluding safe area inset).
            additionalSafeAreaInsets.bottom = fmax(replyInputHeight - self.view.safeAreaInsets.bottom, 0);
        } else {
            // Remove messages VC bottom safe area inset.
            additionalSafeAreaInsets.bottom = 0.0;
        }
        
        self.messagesViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
    }
}

- (void)setAdjustsInsetsForInputViewController:(BOOL)adjustsInsetsForInputViewController
{
    if (_adjustsInsetsForInputViewController == adjustsInsetsForInputViewController) {
        // No change.
        return;
    }
    
    _adjustsInsetsForInputViewController = adjustsInsetsForInputViewController;

    // Schedule layout update.
    [self.view setNeedsLayout];
}

#pragma mark - View controller appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self registerForKeyboardNotifications];

    self.collaborationManager.annotationManager.currentAnnotationIdentifier = self.currentAnnotationIdentifier;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self deregisterForKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.collaborationManager.annotationManager.currentAnnotationIdentifier = nil;
}

#pragma mark - Keyboard

#pragma mark Notifications

- (void)registerForKeyboardNotifications
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillShowWithNotification:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillHideWithNotification:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)deregisterForKeyboardNotifications
{
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIKeyboardWillHideNotification
                                                object:nil];
}

- (void)keyboardWillShowWithNotification:(NSNotification *)notification
{
    if ([self pt_isInPopover]) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    
    // Check if keyboard notification is for the current app.
    BOOL isLocal = ((NSNumber *)userInfo[UIKeyboardIsLocalUserInfoKey]).boolValue;
    if (!isLocal) {
        return;
    }

    // Stop adding extra space for the input bar.
    self.adjustsInsetsForInputViewController = NO;
}

- (void)keyboardWillHideWithNotification:(NSNotification *)notification
{
    if ([self pt_isInPopover]) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    
    // Check if keyboard notification is for the current app.
    BOOL isLocal = ((NSNumber *)userInfo[UIKeyboardIsLocalUserInfoKey]).boolValue;
    if (!isLocal) {
        return;
    }

    // Stop adding extra space for the input bar.
    self.adjustsInsetsForInputViewController = YES;
}

#pragma mark - Button actions

- (void)dismiss:(UIBarButtonItem *)barButtonItem
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (PTAnnotationReplyMessagesViewController *)messagesViewController
{
    if (!_messagesViewController) {
        [self loadViewIfNeeded];
        
        NSAssert(_messagesViewController != nil,
                 @"Failed to load annotation replies messages view controller");
    }
    return _messagesViewController;
}

#pragma mark - Tool manager

- (PTToolManager *)toolManager
{
    return self.collaborationManager.toolManager;
}

#pragma mark - Current annotation

- (void)setCurrentAnnotationIdentifier:(NSString *)annotationIdentifier
{
    if ([_currentAnnotationIdentifier isEqualToString:annotationIdentifier]) {
        // No change.
        return;
    }
    
    _currentAnnotationIdentifier = annotationIdentifier;
    
    if (self.viewIfLoaded.window) {
        self.collaborationManager.annotationManager.currentAnnotationIdentifier = annotationIdentifier;
    }
    
    if (annotationIdentifier) {
        // Get the annotation for the specified identifier.
        PTManagedAnnotation *annotation = [self.collaborationManager.annotationManager managedAnnotationForAnnotationIdentifier:annotationIdentifier];
        if (!annotation) {
            NSLog(@"Failed to retrieve managed annotation for selected annot");
            return;
        }
        
        self.currentAnnotation = annotation;
    } else {
        // Clear the current annotation.
        self.currentAnnotation = nil;
    }
}

- (void)setCurrentAnnotation:(PTManagedAnnotation *)currentAnnotation
{
    PTManagedAnnotation *oldAnnotation = _currentAnnotation;
    if (oldAnnotation) {
        // Stop observing changes to old annotation's context.
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:NSManagedObjectContextObjectsDidChangeNotification
                                                    object:oldAnnotation.managedObjectContext];
    }
    
    _currentAnnotation = currentAnnotation;
    
    if (currentAnnotation) {
        // Start observing changes to annotation's context.
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(managedObjectContextObjectsDidChangeWithNotification:)
                                                   name:NSManagedObjectContextObjectsDidChangeNotification
                                                 object:currentAnnotation.managedObjectContext];
    }
    
    self.messagesViewController.annotation = currentAnnotation;
}

#pragma mark Notifications

- (void)managedObjectContextObjectsDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.currentAnnotation.managedObjectContext) {
        return;
    }
    
    if (!self.currentAnnotation) {
        return;
    }
    
    // Check if current annotation was updated or deleted.
    NSSet<NSManagedObject *> *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
    NSSet<NSManagedObject *> *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    
    if ([deletedObjects containsObject:self.currentAnnotation]) {
        // Current annotation was deleted.
        self.currentAnnotation = nil;
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if ([updatedObjects containsObject:self.currentAnnotation]) {
        // Current annotation was changed: reload the messages view controller.
        self.messagesViewController.annotation = self.currentAnnotation;
    }
}

#pragma mark - <PTAnnotationReplyInputViewDelegate>

- (void)annotationReplyInputViewController:(PTAnnotationReplyInputViewController *)annotationReplyInputViewController didSubmitText:(NSString *)text
{
    NSLog(@"Submitted text: %@", text);
    
    NSError *error = nil;
    BOOL success = [self doReplyWithText:text error:&error];
    if (!success) {
        NSLog(@"Error creating reply: %@", error);
    }
    
    [annotationReplyInputViewController.inputView clear];
}

#pragma mark - Annotation reply creation

- (BOOL)doReplyWithText:(NSString *)text error:(NSError * _Nullable *)error
{
    if (text.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to create reply annotation",
                NSLocalizedFailureReasonErrorKey: @"Cannot create reply with empty text",
            }];
        }
        return NO;
    }
    
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;

    int pageNumber = self.currentAnnotation.pageNumber;
    
    PTAnnot *parentAnnot = [pdfViewCtrl findAnnotWithUniqueID:self.currentAnnotation.identifier
                                                 onPageNumber:pageNumber];
    if (!parentAnnot) {
        if (error) {
            NSString *reason = [NSString localizedStringWithFormat:@"Failed to find annotation with ID \"%@\"",
                                self.currentAnnotation.identifier];
            
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to create reply annotation",
                NSLocalizedFailureReasonErrorKey: reason,
            }];
        }
        return NO;
    }
    
    NSString *author = self.toolManager.annotationAuthor;
    if (author.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to create reply annotation",
                NSLocalizedFailureReasonErrorKey: @"Annotation author is not specified",
            }];
        }
        return NO;
    }
    
    PTText *reply = nil;
    
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPage *page = [[pdfViewCtrl GetDoc] GetPage:pageNumber];
        if (![page IsValid]) {
            if (error) {
                *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                    NSLocalizedDescriptionKey: @"Failed to create reply annotation",
                    NSLocalizedFailureReasonErrorKey: @"Failed to get page for reply",
                }];
            }
            return NO;
        }
        
        // Create text annotation with reply text as contents.
        reply = [PTText CreateTextWithRect:[[pdfViewCtrl GetDoc] GetSDFDoc]
                                       pos:[parentAnnot GetRect]
                                  contents:text];
        [reply SetTitle:author];
        
        [reply SetFlag:e_pthidden value:YES];
        
        // Set reply's unique id to a new UUID.
        reply.uniqueID = [NSUUID UUID].UUIDString;
        
        // Add reply annotation to page.
        // NOTE: This must be done *before* setting the inReplyTo reference and reply type.
        [page AnnotPushBack:reply];
        
        // The reply annotation is "in reply to" the parent annotation.
        // (Use parent annotation's unique id).
        NSString *parentUniqueId = parentAnnot.uniqueID;
        reply.inReplyToAnnotId = parentUniqueId;
        
        reply.replyType = PTMarkupReplyTypeReply;
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
    
    if (!reply) {
        if (error) {
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to create reply annotation",
                NSLocalizedFailureReasonErrorKey: @"An unknown error has occurred",
            }];
        }
        return NO;
    }
    
    [self.toolManager annotationAdded:reply onPageNumber:pageNumber];
    
    return YES;
}

@end
