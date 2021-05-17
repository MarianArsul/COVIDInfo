//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTBaseCollaborationManager.h>
#import <Tools/PTToolManager.h>
#import <Tools/PTOverridable.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The PTCollaborationAnnotationReplyViewController displays a list of replies made to an annotation.
 */
@interface PTCollaborationAnnotationReplyViewController : UIViewController <PTOverridable>

/**
 * Initializes a PTAnnotationReplyViewController instance with a collaboration manager.
 */
- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager NS_DESIGNATED_INITIALIZER;

/**
 * The collaboration manager associated with this control.
 */
@property (nonatomic, readonly, strong) PTBaseCollaborationManager *collaborationManager;

/**
 * The tool manager associated with this control.
 */
@property (nonatomic, readonly, strong) PTToolManager *toolManager;

/**
 * The unique identifier of the current annotation whose replies are shown.
 */
@property (nonatomic, copy, nullable) NSString *currentAnnotationIdentifier;


- (instancetype)initWithNibName:(nullable NSString *)nibName bundle:(nullable NSBundle *)nibBundle NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
