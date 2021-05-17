//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL
@interface PTTableView : UITableView

@property (nonatomic, getter=isIntrinsicContentSizeEnabled) BOOL intrinsicContentSizeEnabled;

@end

NS_ASSUME_NONNULL_END
