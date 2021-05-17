//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTTableViewCell.h"
#import "PTAnnotStyleTableViewItem.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotStyleTextFieldTableViewCell;

@protocol PTAnnotStyleTextFieldTableViewCellDelegate <NSObject>
@optional

- (void)styleTextFieldCell:(PTAnnotStyleTextFieldTableViewCell *)cell didChangeText:(NSString *)text;

- (void)styleTextFieldCell:(PTAnnotStyleTextFieldTableViewCell *)cell didCommitText:(NSString *)text;

@end

@interface PTAnnotStyleTextFieldTableViewCell : PTTableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UITextField *textField;

- (void)configureWithItem:(PTAnnotStyleTextFieldTableViewItem *)item;

@property (nonatomic, weak, nullable) id<PTAnnotStyleTextFieldTableViewCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
