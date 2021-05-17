//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTOverridable.h>
#import <Tools/PTDigSigView.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTFloatingSigViewController;

/**
 * The methods declared by the PTFloatingSigViewControllerDelegate protocol allow the adopting delegate
 * to respond to message from the `PTFloatingSigViewController` class.
 */
@protocol PTFloatingSigViewControllerDelegate <NSObject>
@required

/**
 * Informs the delegate to save the specified path appearance for the signature form field.
 */
- (void)floatingSigViewController:(PTFloatingSigViewController *)floatingSigViewController saveAppearanceWithPath:(nullable NSMutableArray *)points withBoundingRect:(CGRect)boundingRect asDefault:(BOOL)asDefault;

/**
 * Informs the delegate that the signature view controller should be closed.
 */
- (void)floatingSigViewControllerCloseSignatureDialog:(PTFloatingSigViewController *)floatingSigViewController;

@end

/**
 * The PTFloatingSigViewController allows the user to add signatures anywhere on a document.
 * A default signature can be saved for subsequent use.
 */
@interface PTFloatingSigViewController : UIViewController <PTOverridable>

/**
 * The thickness of the drawn lines.
 */
@property (nonatomic, assign) CGFloat strokeThickness;

/**
 * The color to use for drawing.
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 * Whether to allow saving a default signature. The default value of this property is `YES`.
 */
@property (nonatomic, assign) BOOL showDefaultSignature;

/**
 * The canvas view where path appearances are drawn.
 */
@property (nonatomic, strong) PTDigSigView *digSigView;

/**
 * Whether to save the signature for later reuse.
 */
@property (nonatomic, assign) BOOL saveSignatureForReuse;

/**
 * An object that conforms to the `PTFloatingSigViewControllerDelegate` protocol.
 *
 */
@property (nonatomic, weak) id<PTFloatingSigViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
