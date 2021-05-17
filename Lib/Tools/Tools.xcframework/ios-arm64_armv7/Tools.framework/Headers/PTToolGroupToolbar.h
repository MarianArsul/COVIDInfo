//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTToolGroupManager.h>
#import <Tools/PTAnnotationStylePresetsView.h>
#import <Tools/PTAnnotStyleToolbar.h>
#import <Tools/PTAnnotStyleViewController.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTToolGroupToolbar;

/**
 * The `PTToolGroupToolbarDelegate` protocol allows the adopting class to respond
 * to messages from the `PTToolGroupToolbar` class.
 */
@protocol PTToolGroupToolbarDelegate <NSObject>
@optional

/**
 * Returns the view controller that should be used for presentations from the annotation
 * mode toolbar.
 *
 * @param toolGroupToolbar The tool group toolbar requesting the view
 * controller
 *
 * @return the view controller that should be used for presentations
 */
- (UIViewController *)viewControllerForPresentationsFromToolGroupToolbar:(PTToolGroupToolbar *)toolGroupToolbar;

/**
 * Returns the view that should be used as the parent for overlay views, such as the
 * annotation style presets toolbar, shown by the tool group toolbar.
 *
 * @param toolGroupToolbar The tool group toolbar requesting the view
 *
 * @return the view that should be used as the parent for overlay views
 */
- (UIView *)viewForOverlaysFromToolGroupToolbar:(PTToolGroupToolbar *)toolGroupToolbar;

@end

/**
 * The `PTToolGroupToolbar` displays a list of buttons that allow the user to
 * switch between tools in a `PTToolManager` instance. The set of tool buttons
 * displayed by this control can be selected from a list of "Annotation Modes", each of
 * which have different tools available for different tasks (drawing, measuring, etc.).
 * The tool groups are controlled by a `PTToolGroupManager` instance used by
 * the toolbar.
 *
 * The tool buttons in the toolbar are represented by `UIBarButtonItem` instances. The
 * list of buttons for the current tool group are displayed in a scrollable area
 * of the toolbar.
 *
 * In addition to the tool buttons displayed in the center of the toolbar, other buttons
 * can be shown pinned at the leading and trailing ends of the toolbar. By default the
 * `PTToolGroupManager.undoButtonItem` and `PTToolGroupManager.redoButtonItem`
 * buttons are shown at the trailing end of the toolbar.
 */
PT_EXPORT
@interface PTToolGroupToolbar : UIView <PTAnnotStyleViewControllerDelegate, UIToolbarDelegate>

/**
 * Initializes a newly created `PTToolGroupToolbar` instance with the provided
 * tool group manager.
 *
 * @param toolGroupManager The tool group manager to be used by the receiver
 *
 * @return an initialized `PTToolGroupToolbar` instance
 */
- (instancetype)initWithToolGroupManager:(PTToolGroupManager *)toolGroupManager;

/**
 * The delegate object of the tool group toolbar.
 */
@property (nonatomic, weak, nullable) id<PTToolGroupToolbarDelegate> delegate;

/**
 * The tool group manager instance used to control the current tool group and the set of
 * bar button items displayed in this tool group toolbar.
 */
@property (nonatomic, strong, nullable) PTToolGroupManager *toolGroupManager;

/**
 * The bar button items displayed in the scrollable area of the toolbar.
 */
@property (nonatomic, copy, nullable) NSArray<UIBarButtonItem *> *items;

/**
 * The bar button items displayed at the leading end of the toolbar.
 */
@property (nonatomic, copy, nullable) NSArray<UIBarButtonItem *> *leadingItems;

/**
 * The bar button items displayed at the trailing end of the toolbar.
 */
@property (nonatomic, copy, nullable) NSArray<UIBarButtonItem *> *trailingItems;

/**
 * The tint color to apply to the `items`.
 */
@property (nonatomic, strong, nullable) UIColor *itemTintColor UI_APPEARANCE_SELECTOR;

#pragma mark - Annotation style presets toolbar

/**
 * The annotation style presets toolbar displayed when a tool is active in a
 * horizontally compact environment.
 */
@property (nonatomic, readonly, strong) PTAnnotStyleToolbar *presetsToolbar;

/**
 * Whether the `presetsToolbar` is enabled and will be shown when necessary.
 *
 * The default value of this property is `YES`.
 */
@property (nonatomic, assign, getter=isPresetsToolbarEnabled) BOOL presetsToolbarEnabled;

/**
 * Whether the `presetsToolbar` is hidden.
 *
 * The default value of this property is `YES`.
 */
@property (nonatomic, assign, getter=isPresetsToolbarHidden) BOOL presetsToolbarHidden;

/**
 * Sets whether the `presetsToolbar` is hidden.
 *
 * @param hidden Specify `YES` to hide the presets toolbar or `NO` to show it.
 *
 * @param animated Specify `YES` if you want to animate the change in visibility or `NO` if you want
 * the control to appear immediately.
 */
- (void)setPresetsToolbarHidden:(BOOL)hidden animated:(BOOL)animated;

/**
 * The annotation style presets view displayed when a tool is active in a horizontally
 * regular environment.
 */
@property (nonatomic, strong) PTAnnotationStylePresetsView *presetsView;

/**
 * Whether the `presetsView` is hidden.
 *
 * The default value of this property is `YES`.
 */
@property (nonatomic, getter=isPresetsViewHidden) BOOL presetsViewHidden;

/**
 * Sets whether the `presetsView` is hidden.
 *
 * @param hidden Specify `YES` to hide the presets view or `NO` to show it.
 *
 * @param animated Specify `YES` if you want to animate the change in visibility or `NO` if you want
 * the control to appear immediately.
 */
- (void)setPresetsViewHidden:(BOOL)hidden animated:(BOOL)animated;

/**
 * The annotation style view controller used by to edit annotation style presets.
 */
@property (nonatomic, weak, nullable) PTAnnotStyleViewController *stylePicker;

#pragma mark - Edit view

/**
 * Whether the edit view shown for multi-action annotation creation tools (polyline, polygon, etc.)
 * is hidden.
 *
 * The default value of this property is `YES`.
 */
@property (nonatomic, assign, getter=isEditViewHidden) BOOL editViewHidden;

/**
 * Sets whether the edit view is hidden.
 *
 * @param hidden Specify `YES` to hide the edit view or `NO` to show it.
 *
 * @param animated Specify `YES` if you want to animate the change in visibility or `NO` if you want
 * the control to appear immediately.
 */
- (void)setEditViewHidden:(BOOL)hidden animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
