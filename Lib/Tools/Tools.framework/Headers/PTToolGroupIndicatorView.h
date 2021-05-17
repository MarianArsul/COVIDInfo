//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTToolGroupManager.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The `PTToolGroupView` displays the current tool group of a `PTToolGroupManager`
 * instance.
 */
PT_EXPORT
@interface PTToolGroupIndicatorView : UIView

/**
 * The button shown by this view to indicate the current tool group. The button's
 * text is updated to display the current tool group when it changes.
 */
@property (nonatomic, strong) UIButton *button;

/**
 * The tool group manager associated with this view.
 */
@property (nonatomic, strong, nullable) PTToolGroupManager *toolGroupManager;

@end

NS_ASSUME_NONNULL_END
