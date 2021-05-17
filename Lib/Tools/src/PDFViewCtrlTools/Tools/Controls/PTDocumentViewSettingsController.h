//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTOverridable.h>
#import <Tools/PTDocumentViewSettings.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTDocumentViewSettingsController;

/**
 * The methods declared by the `PTSettingsViewControllerDelegate` protocol allow the adopting class
 * to respond to messages from the `PTSettingsViewController` class.
 */
@protocol PTDocumentViewSettingsControllerDelegate <NSObject>
@optional

- (void)documentViewSettingsController:(PTDocumentViewSettingsController *)documentViewSettingsController didUpdateSettings:(PTDocumentViewSettings *)settings;

@end

/**
 * The `PTDocumentViewSettingsController` class displays settings to control a `PTPDFViewCtrl`.
 */
@interface PTDocumentViewSettingsController : UITableViewController <PTOverridable>

@property (nonatomic, strong, null_resettable) PTDocumentViewSettings *settings;

@property (nonatomic, weak, readonly) PTPDFViewCtrl *pdfViewCtrl;

/**
 * The document view settings controller's delegate.
 */
@property (nonatomic, weak, nullable) id<PTDocumentViewSettingsControllerDelegate> delegate;

/*
 * Instantiates a new instance of this view controller.
 *
 * @param pdfViewCtrl The PTPDFViewCTrl that the control will interface with.
 *
 * @returns A new instance of this view controller.
 *
 */
- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) UIBarButtonItem *doneButtonItem;


PT_INIT_UNAVAILABLE;


- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString *)nibName bundle:(nullable NSBundle *)nibBundle NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
