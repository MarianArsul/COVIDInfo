//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTLineAnnot+PTAdditions.h"

@implementation PTLineAnnot (PTAdditions)

- (double)length {
    double xDist = (self.GetEndPoint.getX - self.GetStartPoint.getX);
    double yDist = (self.GetEndPoint.getY - self.GetStartPoint.getY);
    return sqrt(xDist * xDist + yDist * yDist);
}

#pragma mark - PTPolyLine API compatibility

- (int)GetVertexCount
{
    return 2;
}

- (PTPDFPoint*)GetVertex:(int)idx
{
    if( idx == 0 )
    {
        return [self GetStartPoint];
    }
    else if( idx == 1 )
    {
        return [self GetEndPoint];
    }
    else
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Index is out of range."
                                     userInfo:nil];
        return nil;
    }
}

- (void)SetVertex:(int)idx pt:(PTPDFPoint *)pt
{
    if( idx == 0 )
    {
        return [self SetStartPoint:pt];
    }
    else if( idx == 1 )
    {
        return [self SetEndPoint:pt];
    }
    else
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Index is out of range."
                                     userInfo:nil];
    }
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTLineAnnot, PTAdditions)
