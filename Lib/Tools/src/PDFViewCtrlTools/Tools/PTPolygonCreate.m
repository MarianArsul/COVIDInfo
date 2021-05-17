//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPolygonCreate.h"

#import "PTPolylineCreateSubclass.h"

@implementation PTPolygonCreate

#pragma mark - CreateToolBase

- (Class)annotClass
{
    return [PTPolygon class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypePolygon;
}

#pragma mark - Drawing

- (void)endDrawPolylineWithRect:(CGRect)rect atPoint:(CGPoint)point withPoints:(nonnull NSArray<NSValue *> *)points
{
    [super endDrawPolylineWithRect:rect atPoint:point withPoints:points];
    
    // Draw line between end point and first point.
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClosePath(context);
}

#pragma mark - PolylineCreate

- (NSArray<NSValue *> *)vertices
{
    NSArray<NSValue *> *vertices = [super vertices];
    return [self closedPolygonForPoints:vertices];
}

- (NSArray<NSValue *> *)closedPolygonForPoints:(NSArray<NSValue *> *)points
{
    if (points.count < 2) {
        return points;
    }
    
    NSMutableArray<NSValue *> *mutablePoints = [points mutableCopy];
    
    NSValue *firstValue = points.firstObject;
    NSValue *lastValue = points.lastObject;
    if (firstValue && lastValue && !CGPointEqualToPoint(firstValue.CGPointValue, lastValue.CGPointValue)) {
        [mutablePoints addObject:[firstValue copy]];
    }
    
    return [mutablePoints copy];
}

@end
