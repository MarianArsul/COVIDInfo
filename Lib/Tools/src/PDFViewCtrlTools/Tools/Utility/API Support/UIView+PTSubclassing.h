//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@interface UIView (PTSubclassing)

- (void)encodeWithCoder:(NSCoder *)coder NS_REQUIRES_SUPER;

- (void)didAddSubview:(UIView *)subview NS_REQUIRES_SUPER;
- (void)willRemoveSubview:(UIView *)subview NS_REQUIRES_SUPER;

- (void)willMoveToSuperview:(UIView *)newSuperview NS_REQUIRES_SUPER;
- (void)didMoveToSuperview NS_REQUIRES_SUPER;

- (void)willMoveToWindow:(UIWindow *)newWindow NS_REQUIRES_SUPER;
- (void)didMoveToWindow NS_REQUIRES_SUPER;

@end
