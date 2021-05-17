//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTTouchForwardingView : UIView

@property (nonatomic, copy, nullable) NSArray<UIView *> *passthroughViews;

@end

NS_ASSUME_NONNULL_END
