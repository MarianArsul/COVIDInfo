//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTBadgeIndicatorView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTBarButtonView : UIView

@property (nonatomic, strong, nullable) UIView *view;

@property (nonatomic, strong) PTBadgeIndicatorView *badgeIndicatorView;

- (instancetype)initWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
