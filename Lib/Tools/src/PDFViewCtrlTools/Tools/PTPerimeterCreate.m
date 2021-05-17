//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPerimeterCreate.h"
#import "PTColorDefaults.h"

@implementation PTPerimeterCreate

- (Class)annotClass
{
    return [PTPolyLine class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypePerimeter;
}

@end
