//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTDocumentTabItem.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentTabBarCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UIButton *button;

@property (nonatomic, nullable) PTDocumentTabItem *tab;

@end

NS_ASSUME_NONNULL_END
