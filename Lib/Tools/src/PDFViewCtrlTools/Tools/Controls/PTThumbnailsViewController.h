//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTOverridable.h>
#import <Tools/PTToolManager.h>

#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents options for filtering which pages appear in the `PTThumbnailsViewController`.
*/
typedef NSString * PTFilterMode NS_TYPED_ENUM;

/// A filter to show all thumbnails.
PT_EXPORT const PTFilterMode PTThumbnailFilterAll;

/// A filter to show thumbnails of annotated pages only.
PT_EXPORT const PTFilterMode PTThumbnailFilterAnnotated;

/// A filter to show thumbnails of bookmarked pages only.
PT_EXPORT const PTFilterMode PTThumbnailFilterBookmarked;

/**
 * Displays a grid of thumbnails that can be used for navigation, plus re-arranging and
 * deleting pages.
 */
@interface PTThumbnailsViewController : UIViewController <PTOverridable, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate>

/**
 * Initializes a new instance of the class.
 *
 * @param pdfViewCtrl The `PTPDFViewCtrl` instance that the control will coordinate with.
 */
- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl NS_DESIGNATED_INITIALIZER;

/**
 * Initializes a new instance of the class.
 *
 * @param toolManager The `PTToolManager` instance that the control will coordinate with.
 */
- (instancetype)initWithToolManager:(PTToolManager *)toolManager;

/**
 * The collection view object managed by this view controller.
 */
@property (nonatomic, readonly, strong) UICollectionView *collectionView;

/**
 * Whether editing of thumbnails is allowed. The default is `YES`.
 */
@property (nonatomic, assign, getter=isEditingEnabled) BOOL editingEnabled;

/**
* Whether editing of thumbnails is supported. Some modes of opperation do not support editing
* and so the edit button will be disabled even if `editingEnabled` is true.
*/
@property (nonatomic, assign, readonly, getter=isEditingSupported) BOOL editingSupported;

/**
 * An ordered set of `PTFilterMode` enums used to filter the thumbnails.
 *
 * If the set contains fewer than two filter modes then the filter control will not be shown.
*/
@property (nullable, nonatomic, copy) NSOrderedSet<PTFilterMode> *filterModes;

/**
 * The currently selected filter mode.
 */
@property (nonatomic, copy) PTFilterMode filterMode;

/**
 * Associates a thumbnail image with a page number
 *
 * @param image The image of the page.
 *
 * @param pageNum The page number of the page.
 */
- (void)setThumbnail:(UIImage *)image forPage:(NSInteger)pageNum;


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;


- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
