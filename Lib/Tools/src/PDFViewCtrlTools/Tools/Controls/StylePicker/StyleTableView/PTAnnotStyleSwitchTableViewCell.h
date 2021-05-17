//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTTableViewCell.h"
#import "PTAnnotStyleTableViewItem.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotStyleSwitchTableViewCell;

@protocol PTAnnotStyleSwitchTableViewCellDelegate <NSObject>

- (void)styleSwitchTableViewCell:(PTAnnotStyleSwitchTableViewCell *)cell snappingToggled:(BOOL)snappingEnabled;

@end

@interface PTAnnotStyleSwitchTableViewCell : PTTableViewCell

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UISwitch *snapSwitch;

@property (nonatomic, weak, nullable) id<PTAnnotStyleSwitchTableViewCellDelegate> delegate;

- (void)configureWithItem:(PTAnnotStyleSwitchTableViewItem *)item;

@end

NS_ASSUME_NONNULL_END
