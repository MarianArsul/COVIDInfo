//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTTableViewCell.h"
#import "PTAnnotStyleTableViewItem.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStyleColorTableViewCell : PTTableViewCell

@property (nonatomic, strong) UILabel *label;

- (void)configureWithItem:(PTAnnotStyleColorTableViewItem *)item;

@end

NS_ASSUME_NONNULL_END
