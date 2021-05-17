//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPolygon+PTAdditions.h"

@implementation PTPolygon (PTAdditions)

- (double)area
{
    double area = 0.0f;
    int numPoints = [self GetVertexCount];
    for (int i = 0; i < numPoints; i++) {
        PTPDFPoint *point = [self GetVertex:i];
        double addX = point.getX;
        
        int idx = (i == numPoints - 1) ? 0 : i + 1;
        PTPDFPoint *pointB = [self GetVertex:idx];
        double addY = pointB.getY;
        double subX = pointB.getX;
        
        double subY = point.getY;
        
        area += addX * addY - subX * subY;
    }
    return fabs(area)/2;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTPolygon, PTAdditions)
