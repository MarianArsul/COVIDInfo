//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTHalfModalPresentationManager.h>
#import <Tools/PTOverridable.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A `UINavigationController` subclass designed to be used with a `UIPopoverPresentationController`,
 * or other `UIPresentationController` classes that rely on the `preferredContentSize` of the
 * view controllers on the navigation stack.
 *
 * The default `modalPresentationStyle` for instances of this class is `UIModalPresentationCustom`
 * and the `transitioningDelegate` is set to the `presentationManager` property.
 */
PT_EXPORT
@interface PTPopoverNavigationController : UINavigationController <PTOverridable>

/**
 * The presentation manager responsible for controlling how the view controller is displayed.
 */
@property (nonatomic, strong, nullable) PTHalfModalPresentationManager *presentationManager;

@end

NS_ASSUME_NONNULL_END
