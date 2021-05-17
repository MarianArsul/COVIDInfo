//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTBaseCollaborationManager.h>
#import <Tools/PTEmptyTableViewIndicator.h>
#import <Tools/PTOverridable.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The PTCollaborationAnnotationViewController displays a list of all annotations in a collaboration
 * session.
 * The list will contain any comments that have been added to the annotations, and selecting an annotation
 * will scroll the PTPDFViewCtrl to the position of the annotation.
 */
PT_EXPORT
@interface PTCollaborationAnnotationViewController : UITableViewController <PTOverridable>

/**
 * Initializes a `PTCollaborationAnnotationViewController` with a collaboration manager.
 */
- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager;

/**
 * The collaboration manager associated with this control.
 */
@property (nonatomic, strong, nullable) PTBaseCollaborationManager *collaborationManager;

/**
 * The "Done" bar button item shown by this view controller to allow dismissing it when shown in a
 * non-popover modal presentation.
 */
@property (nonatomic, readonly, strong) UIBarButtonItem *doneButtonItem;

/**
 * The view shown by this controller when there are no annotations in the document.
 */
@property (nonatomic, readonly, strong) PTEmptyTableViewIndicator *emptyIndicator;

@end

NS_ASSUME_NONNULL_END
