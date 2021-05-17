//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTManagedAnnotation.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTCollaborationAnnotationViewCell : UITableViewCell

@property (nonatomic, strong) UIView *unreadIndicatorView;

@property (nonatomic, strong) UIImageView *annotationImageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UILabel *messageLabel;

@property (nonatomic, strong) UILabel *dateLabel;

@property (nonatomic, assign) UIEdgeInsets contentInsets;

- (void)configureWithAnnotation:(PTManagedAnnotation *)annotation;

@end

NS_ASSUME_NONNULL_END
