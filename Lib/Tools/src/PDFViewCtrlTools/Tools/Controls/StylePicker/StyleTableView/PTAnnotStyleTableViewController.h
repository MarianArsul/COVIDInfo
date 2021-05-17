//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotStyleTableViewItem.h"
#import "PTPopoverTableViewController.h"
#import "PTMeasurementScale.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotStyleTableViewController;

@protocol PTAnnotStyleTableViewControllerDelegate <NSObject>
@optional

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController sliderDidBeginSlidingForItemAtIndexPath:(NSIndexPath *)indexPath;

- (float)tableViewController:(PTAnnotStyleTableViewController *)tableViewController sliderValueDidChange:(float)value forItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController sliderDidEndSlidingForItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController textFieldContentsDidChange:(NSString *)text forItemAtIndexPath:(NSIndexPath *)indexPath;

- (PTMeasurementScale *)tableViewController:(PTAnnotStyleTableViewController *)tableViewController scaleDidChange:(PTMeasurementScale *)ruler forItemAtIndexPath:(NSIndexPath *)indexPath;

- (PTMeasurementScale *)tableViewController:(PTAnnotStyleTableViewController *)tableViewController precisionDidChange:(PTMeasurementScale *)ruler forItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController snappingToggled:(BOOL)snappingEnabled forItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface PTAnnotStyleTableViewController : PTPopoverTableViewController

@property (nonatomic, copy, nullable) NSArray<NSArray<PTAnnotStyleTableViewItem *> *> *items;

@property (nonatomic, weak, nullable) id<PTAnnotStyleTableViewControllerDelegate> delegate;

- (nullable PTAnnotStyleTableViewItem *)tableViewItemForAnnotStyleKey:(PTAnnotStyleKey)key;

@end

NS_ASSUME_NONNULL_END
