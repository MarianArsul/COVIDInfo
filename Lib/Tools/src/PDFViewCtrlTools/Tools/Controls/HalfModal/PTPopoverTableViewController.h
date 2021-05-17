//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Replicated functionality from UITableViewController:
//
// Creates a table view with the correct dimensions and autoresizing, setting the datasource and delegate to self.
// In -viewWillAppear:, it reloads the table's data if it's empty. Otherwise, it deselects all rows (with or without animation) if clearsSelectionOnViewWillAppear is YES.
// In -viewDidAppear:, it flashes the table's scroll indicators.
// Implements -setEditing:animated: to toggle the editing state of the table.
// Sets the preferredContentSize to reflect the contentSize and contentInset of the table view.
//
// Does NOT adjust the contentInset when the virtual keyboard is shown.

@interface PTPopoverTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithStyle:(UITableViewStyle)style NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, null_resettable) UITableView *tableView;

@property (nonatomic, assign) BOOL clearsSelectionOnViewWillAppear;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
