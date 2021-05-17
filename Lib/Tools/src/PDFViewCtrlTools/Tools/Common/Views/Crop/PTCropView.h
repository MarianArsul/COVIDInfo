//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTShapeView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTCropView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, readonly, strong) UIView *contentView;
@property (nonatomic, readonly, strong) PTShapeView *cropAreaView;
@property (nonatomic, readonly, copy) NSArray<PTShapeView *> *handleViews;

@property (nonatomic, assign) UIEdgeInsets cropInset;
@property (nonatomic, readonly, assign) CGRect cropBounds;

@property (nonatomic, readonly, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, readonly, assign) UIRectEdge resizingEdges;
@property (nonatomic, readonly, assign) UIEdgeInsets resizingCropInset;

@property (nonatomic, readonly, assign, getter=isResizing) BOOL resizing;

@end


NS_ASSUME_NONNULL_END
