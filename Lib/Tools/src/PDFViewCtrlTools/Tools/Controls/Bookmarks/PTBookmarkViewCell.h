//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTBookmarkViewCell;

@protocol PTBookmarkViewCellDelegate <NSObject>
@optional

- (void)bookmarkViewCell:(PTBookmarkViewCell *)bookmarkViewCell didChangeText:(NSString *)text;

- (void)bookmarkViewCell:(PTBookmarkViewCell *)bookmarkViewCell didCommitText:(NSString *)text;

@end

@interface PTBookmarkViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;

// Can be set separately from the editing property, to allow the text to be edited
// outside of the UITableView's edit mode.
@property (nonatomic, assign, getter=isTextFieldEditable) BOOL textFieldEditable;

- (void)configureWithText:(NSString *)text;

@property (nonatomic, weak, nullable) id<PTBookmarkViewCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
