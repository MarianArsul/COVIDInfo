//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTFadingScrollView : UIScrollView

@property (nonatomic, assign) CGFloat fadingDistance;

@property (nonatomic, readonly) UIEdgeInsets fadingInsets;

@end

NS_ASSUME_NONNULL_END
