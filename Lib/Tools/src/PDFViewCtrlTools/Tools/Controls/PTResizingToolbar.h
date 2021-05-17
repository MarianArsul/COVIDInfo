//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTResizingToolbar : UIToolbar

@property (nonatomic, strong, nullable) UIView *contentView;

@property (nonatomic, strong, nullable) UIBarButtonItem *leadingItem;

@property (nonatomic, copy, nullable) NSArray<UIBarButtonItem *> *leadingItems;

@property (nonatomic, strong, nullable) UIBarButtonItem *trailingItem;

@property (nonatomic, copy, nullable) NSArray<UIBarButtonItem *> *trailingItems;

@end

NS_ASSUME_NONNULL_END
