//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTManagedAnnotation.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationReplyHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *label;

- (void)configureWithAnnotation:(PTManagedAnnotation *)annotation;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
