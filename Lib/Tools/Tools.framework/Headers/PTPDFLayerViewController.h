//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTToolManager.h>

#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The PTLayerInfo class encapsulates a single Optional Content Group and its
 * visibility in the current context.
 */
@interface PTLayerInfo : NSObject

/**
 * The Optional Content Group (OCG) associated with a `PTLayerInfo` object.
 */
@property (nonatomic, strong, nullable) PTGroup *group;

/**
 * The current visibility state of the Optional Content Group (OCG) associated
 * with a `PTLayerInfo` object.
 */
@property (nonatomic, assign) BOOL state;

@end

@class PTPDFLayerViewController;

/**
 * The methods declared by the PTPDFLayerViewControllerDelegate protocol allow the adopting delegate to respond to messages from
 * the PTPDFLayerViewController class.
 *
 */
@protocol PTPDFLayerViewControllerDelegate <NSObject>
@optional

/**
 * Tells the delegate that the annotation control wants to be closed.
 */
- (void)pdfLayerViewControllerDidCancel:(PTPDFLayerViewController *)pdfLayerViewController;

@end

/**
 * The PTPDFLayerViewController class displays a list of the document's Optional
 * Content Groups (OCGs), also known as layers.
 *
 * The visibility of each layer can be toggled on or off using this control.
 */
@interface PTPDFLayerViewController : UITableViewController  <PTOverridable>

/**
 * An array of PDF layers (Optional Content Groups) and their state (visibility) in the current context
 */
@property (nonatomic, strong) NSArray<PTLayerInfo *> *layers;

/**
 * Returns a new instance of a `PTPDFLayerViewController`.
 */
- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl NS_DESIGNATED_INITIALIZER;

/**
 * An object that conforms to the PTPDFLayerViewControllerDelegate protocol.
 */
@property (nonatomic, weak, nullable) id<PTPDFLayerViewControllerDelegate> delegate;


- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;


- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
