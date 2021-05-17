//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPDFPoint+PTAdditions.h"

@implementation PTPDFPoint (PTAdditions)

- (CGPoint)CGPointValue
{
    return CGPointMake([self getX], [self getY]);
}

+ (instancetype)pointWithCGPoint:(CGPoint)point
{
    return [[self alloc] initWithCGPoint:point];
}

- (instancetype)initWithCGPoint:(CGPoint)point
{
    return [self initWithPx:point.x py:point.y];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTPDFPoint, PTAdditions)
