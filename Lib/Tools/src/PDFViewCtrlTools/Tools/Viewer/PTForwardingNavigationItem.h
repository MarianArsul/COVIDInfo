//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTDocumentNavigationItem.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL
@interface PTForwardingNavigationItem : PTDocumentNavigationItem

@property (nonatomic, strong, nullable) UINavigationItem *forwardingTargetItem;

- (void)setForwardingTargetItem:(nullable UINavigationItem *)forwardingTargetItem animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
