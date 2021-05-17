//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTToolGroupManager.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The `PTToolGroupViewController` class displays the available list of annotation
 * modes from a `PTToolGroupManager` instance.
 */
PT_EXPORT
@interface PTToolGroupViewController : UITableViewController

/**
 * The tool group manager associated with this view.
 */
@property (nonatomic, strong, nullable) PTToolGroupManager *toolGroupManager;

@end

NS_ASSUME_NONNULL_END
