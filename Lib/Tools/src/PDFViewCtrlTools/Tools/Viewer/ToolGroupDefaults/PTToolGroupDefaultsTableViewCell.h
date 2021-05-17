//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTToolGroupDefaultsTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *itemImageView;

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UISwitch *switchView;

@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, assign, getter=isSeparatorHidden) BOOL separatorHidden;

- (void)configureWithItem:(UIBarButtonItem *)item;

@end

NS_ASSUME_NONNULL_END
