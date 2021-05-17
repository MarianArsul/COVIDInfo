//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTRectangleRedactionCreate.h"

@implementation PTRectangleRedactionCreate

- (Class)annotClass
{
    return [PTRedactionAnnot class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeRedact;
}

@end
