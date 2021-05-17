//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTDocumentViewController.h>
#import <Tools/PTCollaborationAnnotationReplyViewController.h>
#import <Tools/PTCollaborationAnnotationViewController.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A subclass of the `PTDocumentViewController` that will synchronize annotations between the device and
 * central server.
 *
 * The implementation is minimal:
 *
 * 1. It connects the `PTCollaborationDocumentViewController.toolManager.collaborationManger` and the
 * `PTCollaborationServerCommunication service`.
 *
 * 2. It does not allow the user to select annotations where the author of the annotation does not match the user
 * that is logged in to the `PTCollaborationServerCommunication service`.
 */
PT_DEPRECATED_MSG(8.0.2, "Use the PTCollaborationDocumentController class instead")
@interface PTCollaborationDocumentViewController : PTDocumentViewController

/**
 * The object that communicates with the server.
 */
@property (nonatomic, strong, readonly) id<PTCollaborationServerCommunication> service;

/**
 * Creates a new `PTCollaborationDocumentViewController` and sets its `service` property to that
 * provided in this initializer.
 */
- (instancetype)initWithCollaborationService:(id<PTCollaborationServerCommunication>)service NS_DESIGNATED_INITIALIZER;

#pragma mark - View controllers

/**
 * The `PTCollaborationAnnotationReplyViewController` shown by this view controller for viewing annotation replies.
 */
@property (nonatomic, readonly, strong, nullable) PTCollaborationAnnotationReplyViewController *collaborationReplyViewController;

/**
 * The collaboration annotation view controller managed by this view controller and shown in a
 * `PTNavigationListsViewController`.
 */
@property (nonatomic, readonly, strong) PTCollaborationAnnotationViewController *collaborationAnnotationViewController;

#pragma mark - Hiding controls

/**
 * Whether the `PTCollaborationAnnotationViewController` is included in this view controller's
 * `PTNavigationListsViewController`. The default value is `YES`.
 */
@property (nonatomic, assign, getter=isCollaborationAnnotationListHidden) BOOL collaborationAnnotationListHidden;


- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
