//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTSelectableBarButtonItem.h"

#import "PTBarButtonView.h"
#import "PTBadgeIndicatorView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTSelectableBarButtonItem ()

@property (nonatomic, readonly, strong, nullable) PTBarButtonView *barButtonView;

@property (nonatomic, readonly, strong) PTBadgeIndicatorView *badgeIndicatorView;

@end

NS_ASSUME_NONNULL_END
