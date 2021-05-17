//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTManagedAnnotation.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationReplyTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *authorLabel;

@property (nonatomic, strong) UILabel *dateLabel;

@property (nonatomic, strong) UILabel *messageLabel;

- (void)configureWithAnnotation:(PTManagedAnnotation *)annotation;

@end

NS_ASSUME_NONNULL_END
