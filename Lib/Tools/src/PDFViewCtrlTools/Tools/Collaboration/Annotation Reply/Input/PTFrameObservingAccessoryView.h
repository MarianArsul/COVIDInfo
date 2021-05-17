//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTFrameObservingAccessoryView;

@protocol PTFrameObservingAccessoryViewDelegate <NSObject>
@optional

- (void)frameObservingAccessoryView:(PTFrameObservingAccessoryView *)frameObservingAccessoryView frameDidChange:(CGRect)frame;

@end

@interface PTFrameObservingAccessoryView : UIView

@property (nonatomic, assign) CGFloat height;

@property (nonatomic, weak, nullable) id<PTFrameObservingAccessoryViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
