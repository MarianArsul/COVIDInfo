//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTTableHeaderView;

@protocol PTTableHeaderViewDelegate <NSObject>
@optional

- (void)tableHeaderViewShowSort:(PTTableHeaderView *)tableHeaderView;

@end

@interface PTTableHeaderView : UIView

@property (nonatomic, strong) UIButton *sortButton;

@property (nonatomic, weak, nullable) id<PTTableHeaderViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
