//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"
#import "ToolsMacros.h"

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - CGPoint

PT_LOCAL const CGPoint PTCGPointNull;

PT_LOCAL CGPoint PTCGPointAdd(CGPoint a, CGPoint b);

PT_LOCAL CGPoint PTCGPointSubtract(CGPoint a, CGPoint b);

PT_LOCAL CGPoint PTCGPointMultiply(CGPoint point, CGFloat n);

PT_LOCAL CGPoint PTCGPointDivide(CGPoint point, CGFloat n);

PT_LOCAL CGFloat PTCGPointLength(CGPoint point);

PT_LOCAL CGFloat PTCGPointCrossProduct(CGPoint a, CGPoint b);

PT_LOCAL CGFloat PTCGPointAngleFromXAxis(CGPoint point);

PT_LOCAL CGFloat PTCGPointDistanceToPoint(CGPoint point1, CGPoint point2);

PT_LOCAL CGPoint PTCGPointSnapToPoint(CGPoint point, CGPoint snapPoint);

PT_LOCAL BOOL PTCGPointIsNull(CGPoint point);

#pragma mark - CGRect

PT_LOCAL CGPoint PTCGRectGetCenter(CGRect rect);

PT_LOCAL NSArray *PTVerticesFromRect(CGRect rect);

PT_LOCAL CGFloat PTCGRectMaxXEdge(CGRect rect);

PT_LOCAL CGFloat PTCGRectMaxYEdge(CGRect rect);

#pragma mark - CGVector

PT_LOCAL const CGVector PTCGVectorZero;

PT_LOCAL CGVector PTCGPointOffsetFromPoint(CGPoint point1, CGPoint point2);

PT_LOCAL CGPoint PTCGVectorOffsetPoint(CGPoint point, CGVector vector);

#pragma mark - CGSize

PT_LOCAL CGFloat PTCGSizeAspectRatio(CGSize size);

NS_ASSUME_NONNULL_END
