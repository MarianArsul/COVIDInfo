//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPolyLine+PTAdditions.h"

@implementation PTPolyLine (PTAdditions)

- (double)perimeter
{
    double perimeter = 0.0f;
    PTPDFPoint *prevPoint = nil;
    
    for (int i = 0; i < [self GetVertexCount]; i++) {
        PTPDFPoint *point = [self GetVertex:i];
        if (prevPoint != nil) {
            perimeter += sqrt(pow(point.getX-prevPoint.getX, 2) + pow(point.getY - prevPoint.getY, 2));
        }
        prevPoint = point;
    }
    return perimeter;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTPolyLine, PTAdditions)
