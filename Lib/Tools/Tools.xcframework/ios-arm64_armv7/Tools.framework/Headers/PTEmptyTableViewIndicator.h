//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------


#import <Tools/ToolsDefines.h>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTEmptyTableViewIndicator;

/**
 * Constants that indicate how to align the contents of a `PTEmptyTableViewIndicator` view.
 *
 * The vertical alignment options are mutually exclusive to each other, and likewise for the
 * horizontal alignment options.
 */
typedef NS_OPTIONS(NSUInteger, PTEmptyTableViewAlignment) {
    /// Align to the top edge of the view.
    PTEmptyTableViewAlignmentTop = 1 << 0,
    /// Align centered vertically in the view.
    PTEmptyTableViewAlignmentCenteredVertically = 0,
    /// Align to the bottom edge of the view.
    PTEmptyTableViewAlignmentBottom = 1 << 1,
    
    /// Align to the left edge of the view.
    PTEmptyTableViewAlignmentLeft = 1 << 2,
    /// Align centered horizontally in the view.
    PTEmptyTableViewAlignmentCenteredHorizontally = 0,
    /// Align to the right edge of the view.
    PTEmptyTableViewAlignmentRight = 1 << 3,
    
    /// Align to the leading edge of the view.
    PTEmptyTableViewAlignmentLeading = 1 << 4,
    /// Align to the trailing edge of the view.
    PTEmptyTableViewAlignmentTrailing = 1 << 5,
};

/**
 * A view used to indicate that the contents of a table or collection view are empty. Assigning an
 * instance of this class to the `backgroundView` property of a `UITableView` or `UICollectionView`
 * will display the indicator as a non-scrolling subview. Adding an instance of this class as a
 * subview to a table or collection view will make it scroll with the scroll view.
 */
PT_EXPORT
@interface PTEmptyTableViewIndicator : UIView

/**
 * The image view displayed by the indicator.
 */
@property (nonatomic, readonly, strong) UIImageView *imageView;

/**
 * The label displayed by the indicator.
 */
@property (nonatomic, readonly, strong) UILabel *label;

/**
 * A bitmask describing the alignment of the image and label in this view.
 *
 * The default alignment is horizontally and vertically centered.
 */
@property (nonatomic, assign) PTEmptyTableViewAlignment alignment;

@end

NS_ASSUME_NONNULL_END
