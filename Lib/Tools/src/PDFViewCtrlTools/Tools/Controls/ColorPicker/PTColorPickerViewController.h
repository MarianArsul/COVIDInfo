//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTOverridable.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTColorPickerViewController;

/**
 * The methods declared by the PTColorPickerViewControllerDelegate protocol allow the adopting delegate to
 * respond to messages from the `PTColorPickerViewController` class.
 */
@protocol PTColorPickerViewControllerDelegate <NSObject>

/**
 * Informs the delegate that a color has been selected by the user.
 */
- (void)colorPickerController:(PTColorPickerViewController *)colorPickerController didSelectColor:(UIColor *)color;

@end

/**
 * The PTColorPickerViewController displays a grid of color cells for selection. Selecting a color cell notifies
 * the delegate object.
 */
@interface PTColorPickerViewController : UIPageViewController <PTOverridable, UIPageViewControllerDataSource>

 /**
  *
  * Initializes a newly created PTColorPickerViewController, with the option of setting the colors to display.
  *
  * @param style The style for transitions between pages.
  *
  * @param navigationOrientation The orientation of the page-by-page navigation.
  *
  * @param options A dictionary of options.
  *
  * @param colors An array of 28 colours, that will be displayed in a 4x7 grid.
  *
  */
- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(nullable NSDictionary<UIPageViewControllerOptionsKey, id> *)options colors:(nullable NSArray<UIColor*>*)colors;

/**
 * The currently selected color.
 */
@property (nonatomic, strong, nullable) UIColor *color;

/**
 * An identifier that can be used to indicate the type of color being picked.
 */
@property (nonatomic, strong) id tag;

/**
 * The colors that are displayed by this view controller.
 */
@property (nonatomic, copy, null_resettable) NSArray<UIColor *> *colors;

/**
 * An object that conforms to the `PTColorPickerViewControllerDelegate` protocol.
 */
@property (nonatomic, weak, nullable) id<PTColorPickerViewControllerDelegate> colorPickerDelegate;

@end

NS_ASSUME_NONNULL_END
