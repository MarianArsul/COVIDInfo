//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAreaCreate.h"
#import "PTColorDefaults.h"

@implementation PTAreaCreate

- (Class)annotClass
{
    return [PTPolygon class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeArea;
}

@end
