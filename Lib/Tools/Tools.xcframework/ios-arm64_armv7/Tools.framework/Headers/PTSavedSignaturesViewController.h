//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTOverridable.h>
#import <Tools/PTSignaturesManager.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@class PTSavedSignaturesViewController;

/**
* A delegate used to respond
*/
@protocol PTSavedSignaturesViewControllerDelegate <NSObject>

@required
/**
 * Notifies the delegate when the user wishes to create a new signature that will be saved for reuse.
 *
 */
-(void)savedSignaturesControllerNewSignature:(PTSavedSignaturesViewController*)savedSignaturesController;

/**
* Notifies the delegate when the user wishes to create a new signature that will not be saved for reuse.
*
*/
-(void)savedSignaturesControllerOneTimeSignature:(PTSavedSignaturesViewController*)savedSignaturesController;

/**
* Notifies the delegate when the user wishes to save new to the document.
*
* @param signatureDoc A PDF that contains the signature.
*
*/
-(void)savedSignaturesController:(PTSavedSignaturesViewController*)savedSignaturesController addSignature:(PTPDFDoc*)signatureDoc;

@optional

/**
 * Notifies the delegate when the controller is dismissed.
 */
-(void)savedSignaturesControllerWasDismissed:(PTSavedSignaturesViewController*)savedSignaturesController;

@end

/**
* Presents a list of saved signatures, and buttons to create new ones.
*/
@interface PTSavedSignaturesViewController : UITableViewController<PTOverridable>

/**
 * The signature manager used by the `PTSavedSignaturesViewController`
 */
@property (nonatomic, readonly, strong) PTSignaturesManager* signaturesManager;

/**
 * The PTSavedSignaturesViewController object's delegate.
 */
@property (nonatomic, weak) id<PTSavedSignaturesViewControllerDelegate> delegate;

/**
* A convenience initializer to initalize with a pre-existing signature manager.
*/
-(instancetype)initWithSignaturesManager:(PTSignaturesManager*)signaturesManager;


@end

NS_ASSUME_NONNULL_END
