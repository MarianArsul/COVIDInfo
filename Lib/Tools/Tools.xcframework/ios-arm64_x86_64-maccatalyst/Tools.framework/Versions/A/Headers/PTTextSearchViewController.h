//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTOverridable.h>
#import <Tools/PTSearchSettingsViewController.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTTextSearchViewController;

/**
 * The methods declared by the PTTextSearchViewControllerDelegate protocol allow the adopting delegate
 * to respond to messages from the `PTTextSearchViewController` class.
 */
@protocol PTTextSearchViewControllerDelegate <NSObject>
/**
 * Informs the delegate that the user wishes to close the search view controller.
 */
- (void)searchViewControllerDidDismiss:(PTTextSearchViewController *)searchViewController;

@end

/**
 * The PTTextSearchViewController class displays a `UISearchBar` that allows the user to enter
 * and search text within a document.
 *
 * A `UIToolbar` is also shown with buttons allowing the user to navigate forwards and
 * backwards through the results as well as configure search options.
 * The view controller also provides an interface to display the search results in a `UITableView`.
 */
@interface PTTextSearchViewController : UIViewController <PTOverridable>

/**
 * Initializes a new instance of the class.
 *
 * @param pdfViewCtrl The `PTPDFViewCtrl` instance that the control will coordinate with.
 */
- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl NS_DESIGNATED_INITIALIZER;

/**
 * A Boolean value indicating if the search bar should become the first responder and show the keyboard when the text search view controller appears.
 * The default is `YES`.
 */
@property (nonatomic) BOOL showsKeyboardOnViewDidAppear;

/**
 * Performs a text search and highlights the results on screen.
 */
-(void)findText:(NSString *)searchString;

/**
 * The `PTSearchSettingsViewController` managed by this view controller.
 */
@property (nonatomic, strong) PTSearchSettingsViewController *searchSettingsViewController;
/**
 * An object conforming to the PTTextSearchViewControllerDelegate protocol.
 */
@property (nonatomic, weak, nullable) id<PTTextSearchViewControllerDelegate> delegate;


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;


- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
