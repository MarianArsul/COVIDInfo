//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTOverridable.h>
#import <Tools/PTToolManager.h>
#import <Tools/PTAnnotStyle.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotStyleViewController;
@class PTToolManager;

/**
 * The methods declared by the PTAnnotStyleViewControllerDelegate protocol allow the adopting delegate
 * to respond to messages from the AnnotStyleViewController class.
 */
@protocol PTAnnotStyleViewControllerDelegate <NSObject>
@required

/**
 * Informs the delegate when the annotation style has been committed by the user.
 */
- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didCommitStyle:(PTAnnotStyle *)annotStyle;

@optional

/**
 * Allows the delegate to adjust the minimum value for the given annotation
 * style and style key.
 */
- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController minimumValue:(inout CGFloat *)minimumValue forStyle:(PTAnnotStyle *)annotStyle key:(PTAnnotStyleKey)styleKey;

/**
 * Allows the delegate to adjust the maximum value for the given annotation
 * style and style key.
 */
- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController maximumValue:(inout CGFloat *)maximumValue forStyle:(PTAnnotStyle *)annotStyle key:(PTAnnotStyleKey)styleKey;

/**
 * Informs the delegate when the annotation style has been changed by the user.
 */
- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didChangeStyle:(PTAnnotStyle *)annotStyle;

@end

/**
 * The AnnotStyleViewController displays a list of controls for adjusting the appearance and properties
 * of an annotation or annotation type.
 * The available controls are determined based on the type of annotation provided.
 */
PT_EXPORT
@interface PTAnnotStyleViewController : UIViewController <PTOverridable, PTAnnotStyleDelegate>

/**
 * Returns a new instance of an AnnotStyleViewController.
 *
 * @param annotStyle An instance of `PTAnnotStyle` initialized with an annotation or annotation type.
 */
- (instancetype)initWithAnnotStyle:(PTAnnotStyle *)annotStyle NS_DESIGNATED_INITIALIZER;

/**
 * Returns a new instance of an AnnotStyleViewController.
 *
 * @param toolManager An instance of `PTToolManager`.
 * @param annotStyle An instance of `PTAnnotStyle` initialized with an annotation or annotation type.
 */
- (instancetype)initWithToolManager:(PTToolManager *)toolManager annotStyle:(PTAnnotStyle *)annotStyle;

/**
 * An object that manages and stores the current colors and properties for an annotation.
 */
@property (nonatomic, strong) PTAnnotStyle *annotStyle;

/**
 * An object that conforms to the PTAnnotStyleViewControllerDelegate protocol.
 */
@property (nonatomic, weak, nullable) id<PTAnnotStyleViewControllerDelegate> delegate;

/**
 * The configuration that will be used for the font picker.
 */
@property (nonatomic, strong, nullable) UIFontPickerViewControllerConfiguration* fontPickerConfiguration NS_AVAILABLE_IOS(13_0);

/**
 * Request the AnnotStyleViewController to call its delegate's `annotStyleViewController:didCommitStyle` method.
 */
- (void)selectStyle;


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;


- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
