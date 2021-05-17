//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTTableViewCell.h"
#import "PTAnnotStyleTableViewItem.h"
#import "PTMeasurementScale.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotStyleScaleTableViewCell;

@protocol PTAnnotStyleScaleTableViewCellDelegate <NSObject>

- (void)styleScaleTableViewCell:(PTAnnotStyleScaleTableViewCell *)cell measurementScaleDidChange:(PTMeasurementScale *)measurementScale;

@end

@interface PTAnnotStyleScaleTableViewCell : PTTableViewCell

@property (nonatomic, strong) PTMeasurementScale *measurementScale;

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UITextField *baseValueTextField;

@property (nonatomic, strong) UITextField *translateValueTextField;

@property (nonatomic, weak, nullable) id<PTAnnotStyleScaleTableViewCellDelegate> delegate;

- (void)configureWithItem:(PTAnnotStyleScaleTableViewItem *)item;

@end

NS_ASSUME_NONNULL_END
