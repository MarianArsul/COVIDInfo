//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTLabelHeaderFooterView : UITableViewHeaderFooterView

@property (nonatomic, readonly, strong) UILabel *label;
@property (nonatomic, readonly, strong) UILabel *detailLabel;

@property (nonatomic, readonly, strong, nullable) UILabel *textLabel NS_UNAVAILABLE;
@property (nonatomic, readonly, strong, nullable) UILabel *detailTextLabel NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
