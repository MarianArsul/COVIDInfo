//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPDFRect+PTAdditions.h"

#include <tgmath.h>

@implementation PTPDFRect (PTAdditions)

- (CGRect)CGRectValue
{
    return CGRectMake([self GetX1], [self GetY1], [self Width], [self Height]);
}

+ (instancetype)rectFromCGRect:(CGRect)cgRect
{
    return [[self alloc] initWithCGRect:cgRect];
}

- (instancetype)initWithCGRect:(CGRect)cgRect
{
    return [self initWithX1:CGRectGetMinX(cgRect) y1:CGRectGetMinY(cgRect)
                         x2:CGRectGetMaxX(cgRect) y2:CGRectGetMaxY(cgRect)];
}

+ (PTPDFRect *)boundingBoxForPoints:(NSArray<PTPDFPoint *> *)points
{
    if (points.count == 0) {
        return nil;
    }
    
    double minX = DBL_MAX;
    double minY = DBL_MAX;
    
    double maxX = DBL_MIN;
    double maxY = DBL_MIN;
    
    for (PTPDFPoint *point in points) {
        const double x = [point getX];
        const double y = [point getY];
        
        minX = fmin(minX, x);
        minY = fmin(minY, y);
        
        maxX = fmax(maxX, x);
        maxY = fmax(maxY, y);
    }
    
    if (minX == DBL_MAX || minY == DBL_MAX ||
        maxX == DBL_MIN || maxY == DBL_MIN) {
        return nil;
    }
    
    // Create and normalize bounding box rect.
    PTPDFRect *rect = nil;
    @try {
        rect = [[PTPDFRect alloc] initWithX1:minX y1:minY x2:maxX y2:maxY];
        [rect Normalize];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        return nil;
    }
    
    return rect;
}

- (NSArray<PTPDFPoint *> *)points
{
    // Make a normalized copy of this rect to avoid side-effects in this method.
    PTPDFRect *normalizedRect = [[PTPDFRect alloc] initWithX1:[self GetX1]
                                                           y1:[self GetY1]
                                                           x2:[self GetX2]
                                                           y2:[self GetY2]];
    [normalizedRect Normalize];
    
    return @[
        // Bottom-left point.
        [[PTPDFPoint alloc] initWithPx:[self GetX1] py:[self GetY1]],
        // Bottom-right point.
        [[PTPDFPoint alloc] initWithPx:[self GetX2] py:[self GetY1]],
        // Top-right point.
        [[PTPDFPoint alloc] initWithPx:[self GetX2] py:[self GetY2]],
        // Top-left point.
        [[PTPDFPoint alloc] initWithPx:[self GetX1] py:[self GetY2]],
    ];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTPDFRect, PTAdditions)
