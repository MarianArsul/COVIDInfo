//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTBaseCollaborationManager.h"
#import "PTManagedAnnotation.h"

#import <UIKit/UIKit.h>

@class PTAnnotationItem;

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationReplyMessagesViewController : UITableViewController

- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) PTBaseCollaborationManager *collaborationManager;

@property (nonatomic, strong, nullable) PTManagedAnnotation *annotation;

- (instancetype)initWithNibName:(nullable NSString *)nibName bundle:(nullable NSBundle *)nibBundle NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
