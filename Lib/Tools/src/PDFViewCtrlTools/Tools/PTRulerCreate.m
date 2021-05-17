//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTRulerCreate.h"
#import "PTColorDefaults.h"

@interface PTRulerCreate ()
@end

@implementation PTRulerCreate

- (Class)annotClass
{
    return [PTLineAnnot class];
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeRuler;
}


@end
