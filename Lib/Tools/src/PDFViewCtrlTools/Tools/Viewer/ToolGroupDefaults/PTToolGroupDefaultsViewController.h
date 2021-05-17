//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTToolGroupManager.h"
#import "PTToolGroup.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTToolGroupDefaultsViewController : UITableViewController

@property (nonatomic, strong, nullable) PTToolGroupManager *toolGroupManager;

@property (nonatomic, copy, nullable) NSArray<PTToolGroup *> *itemGroups;

@property (nonatomic, nullable) UIColor *iconTintColor;
 
@end

NS_ASSUME_NONNULL_END
