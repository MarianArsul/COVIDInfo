//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@interface UIViewController (PTSubclassing)

- (void)encodeWithCoder:(NSCoder *)coder NS_REQUIRES_SUPER;

- (void)viewWillAppear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewDidAppear:(BOOL)animated NS_REQUIRES_SUPER;

- (void)viewWillDisappear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewDidDisappear:(BOOL)animated NS_REQUIRES_SUPER;

- (void)viewWillLayoutSubviews NS_REQUIRES_SUPER;
- (void)viewDidLayoutSubviews NS_REQUIRES_SUPER;

- (void)updateViewConstraints NS_REQUIRES_SUPER;

- (void)addChildViewController:(UIViewController *)childController NS_REQUIRES_SUPER;
- (void)removeFromParentViewController NS_REQUIRES_SUPER;

- (void)willMoveToParentViewController:(UIViewController *)parent NS_REQUIRES_SUPER;
- (void)didMoveToParentViewController:(UIViewController *)parent NS_REQUIRES_SUPER;

@end
