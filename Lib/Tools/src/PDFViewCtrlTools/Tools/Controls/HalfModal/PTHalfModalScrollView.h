//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTGrabberView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTHalfModalScrollView : UIScrollView

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong, null_resettable) UIView *backgroundView;

@property (nonatomic, strong) PTGrabberView *grabber;

@property (nonatomic, assign, getter=isGrabberHidden) BOOL grabberHidden;

@property (nonatomic, strong, nullable) UIViewController *presentedViewController;

@property (nonatomic, assign) CGFloat drawerHeight;

@property (nonatomic, assign) CGFloat cornerRadius;

@property (nonatomic, assign, getter=isPresenting) BOOL presenting;

@property (nonatomic, assign) CGFloat preferredContentHeight;

@end

NS_ASSUME_NONNULL_END
