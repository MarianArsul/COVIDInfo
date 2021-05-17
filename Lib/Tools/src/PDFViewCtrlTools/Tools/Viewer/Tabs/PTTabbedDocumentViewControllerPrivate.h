//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTTabbedDocumentViewController.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTTabbedDocumentViewController (Private)

- (void)transitionFromHeaderView:(nullable UIView *)oldHeaderView toHeaderView:(nullable UIView *)newHeaderView forTab:(PTDocumentTabItem *)tab animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
