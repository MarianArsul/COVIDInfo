//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "CGGeometry+PTAdditions.h"

#import <tgmath.h>

static CGFloat const PT_SnapThreshold = 20.0;

#pragma mark - CGPoint

const CGPoint PTCGPointNull = { .x = INFINITY, .y = INFINITY };

CGPoint PTCGPointAdd(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

CGPoint PTCGPointSubtract(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

CGPoint PTCGPointMultiply(CGPoint point, CGFloat n)
{
    return CGPointMake(point.x * n, point.y * n);
}

CGPoint PTCGPointDivide(CGPoint point, CGFloat n)
{
    return PTCGPointMultiply(point, 1 / n);
}

CGFloat PTCGPointLength(CGPoint point)
{
    return hypot(point.x, point.y);
}

CGFloat PTCGPointCrossProduct(CGPoint a, CGPoint b)
{
    return (a.x * b.y) - (a.y * b.x);
}

CGFloat PTCGPointAngleFromXAxis(CGPoint point)
{
    return atan2(point.y, point.x);
}

CGFloat PTCGPointDistanceToPoint(CGPoint point1, CGPoint point2)
{
    const CGPoint separation = PTCGPointSubtract(point2, point1);
    return PTCGPointLength(separation);
}

CGPoint PTCGPointSnapToPoint(CGPoint point, CGPoint snapPoint)
{
    CGFloat distance = PTCGPointDistanceToPoint(point, snapPoint);
    return distance < PT_SnapThreshold ? snapPoint : point;
}

BOOL PTCGPointIsNull(CGPoint point)
{
    return CGPointEqualToPoint(point, PTCGPointNull);
}

#pragma mark - CGRect

CGPoint PTCGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

NSArray *PTVerticesFromRect(CGRect rect)
{
    CGPoint topLeft, topRight, bottomLeft, bottomRight;
    topLeft = rect.origin;
    topRight = CGPointMake(rect.origin.x+rect.size.width, rect.origin.y);
    bottomLeft = CGPointMake(rect.origin.x, rect.origin.y+rect.size.height);
    bottomRight = CGPointMake(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);

    NSArray *points = [NSArray arrayWithObjects:
    [NSValue valueWithCGPoint:topLeft],
    [NSValue valueWithCGPoint:topRight],
    [NSValue valueWithCGPoint:bottomLeft],
    [NSValue valueWithCGPoint:bottomRight],
    nil];
    return points;
}

CGFloat PTCGRectMaxXEdge(CGRect rect)
{
    return rect.origin.x+rect.size.width;
}

CGFloat PTCGRectMaxYEdge(CGRect rect)
{
    return rect.origin.y+rect.size.height;
}

#pragma mark - CGVector

const CGVector PTCGVectorZero = { .dx = 0.0, .dy = 0.0 };

CGVector PTCGPointOffsetFromPoint(CGPoint point1, CGPoint point2)
{
    return CGVectorMake(point1.x - point2.x, point1.y - point2.y);
}

CGPoint PTCGVectorOffsetPoint(CGPoint point, CGVector vector)
{
    return CGPointMake(point.x + vector.dx, point.y + vector.dy);
}

CGFloat PTCGSizeAspectRatio(CGSize size)
{
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return 1.0;
    }
    return (size.width / size.height);
}
