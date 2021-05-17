//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTTool.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A non-annotating tool that is used to navigate the document. When the user taps or long
 * presses on the document, the pan tool will check the content of the document for annotaitons
 * and text, and if found, pass the event to the appropriate tool. When long pressing an
 * emtpy section of the document, the `PTPanTool` gives the option to switch to a selection of
 * annotation creation tools.
 */
@interface PTPanTool : PTTool

/**
 * Shows the UIMenuController after a tap (in addition to after a long press).
 * Default is false.
 */
@property (nonatomic, assign) BOOL showMenuOnTap;

/**
 * When true, and `showMenuOnTap` is true, the next tap event will show the UIMenuController.
 */
@property (nonatomic, assign) BOOL showMenuNextTap;

@end

NS_ASSUME_NONNULL_END
