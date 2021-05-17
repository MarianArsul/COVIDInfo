//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTHalfModalScrollView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTHalfModalPresentationController : UIPresentationController

@property (nonatomic, strong) PTHalfModalScrollView *scrollView;

@property (nonatomic, copy, nullable) NSArray<UIView *> *passthroughViews;

/**
 * Whether the visible portion of the presenters view is dimmed.
 *
 * The default value is `NO`.
 */
@property (nonatomic, assign) BOOL dimsBackgroundView;

@property (nonatomic, assign) CGFloat cornerRadius;

/**
 * Whether the grabber "pill" at the top of the presented view controller is hidden.
 *
 * The default value is `NO`.
 */
@property (nonatomic, assign, getter=isGrabberHidden) BOOL grabberHidden;

@end

NS_ASSUME_NONNULL_END
