//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTAnnotEditTool.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The `PTPolylineEditTool` is used to edit polyline, polygon, and cloudy annotations.
 */
@interface PTPolylineEditTool : PTAnnotEditTool

/**
 * The vertices of the annotation, expressed in page space.
 */
@property (nonatomic, copy, nullable) NSArray<PTPDFPoint *> *vertices;

/**
 * The index of the selected vertex in `vertices`. When no vertex is selected, the value
 * of this property is `NSNotFound`.
 */
@property (nonatomic, assign) NSUInteger selectedVertexIndex;

/**
 * The starting location of the touch on the annotation, in screen space.
 */
@property (nonatomic, assign) CGPoint touchStartPoint;

/**
 * The ending location of the touch on the annotation, in screen space.
 */
@property (nonatomic, assign) CGPoint touchEndPoint;

@end

NS_ASSUME_NONNULL_END
