//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTTool.h>
#import <Tools/PTAnnotEditTool.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The drawing mode for a `PTSelectionRectView`.
 */
typedef NS_ENUM(NSInteger, PTSelectionRectViewDrawingMode) {
    /// Draw nothing.
    PTSelectionRectViewDrawingModeNone,
    /// Draw a line starting at the north-east corner.
    PTSelectionRectViewDrawingModeLineNEStart,
    /// Draw a line starting at the north-west corner.
    PTSelectionRectViewDrawingModeLineNWStart,
};

@class PTAnnotEditTool;

/**
 * For use when editing line and arrow annotations, where the selection rectangle
 * is not shown when the annotation is not being moved, and has a different appearance than
 * other annotation types.
 */
@interface PTSelectionRectView : UIView

/**
 * The PTPDFViewCtrl that the annotation selection is on.
 */
@property (nonatomic, weak) PTPDFViewCtrl* pdfViewCtrl;

/**
 * The annotation that is selected.
 */
@property (nonatomic, strong, nullable) PTAnnot *annot;

/**
 * The drawing mode for the view. Used when editing line and arrow annotations.
 */
@property (nonatomic, assign) PTSelectionRectViewDrawingMode drawingMode;

/**
 * The adjustment to the view's frame when editing line and arrow annotations.
 */
@property (nonatomic, assign) CGFloat rectOffset;

/**
 * Refreshes the live representation of the annotation's appearance.
 */
-(void)refreshLiveAppearance;

/**
* Removes the live representation of the annotation's appearance.
*/
-(void)removeLiveAppearance;

/**
 * Returns a new instance of a PTSelectionRectView.
 */
- (instancetype)initWithFrame:(CGRect)frame forAnnot:(nullable PTAnnot*)annot withAnnotEditTool:(PTAnnotEditTool*)tool withPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl NS_DESIGNATED_INITIALIZER;


-(instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


-(instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;


-(instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
