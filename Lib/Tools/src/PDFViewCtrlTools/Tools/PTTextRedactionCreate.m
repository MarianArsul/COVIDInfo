//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextRedactionCreate.h"

@implementation PTTextRedactionCreate

- (Class)annotClass
{
    return [PTRedactionAnnot class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeRedact;
}

@end
