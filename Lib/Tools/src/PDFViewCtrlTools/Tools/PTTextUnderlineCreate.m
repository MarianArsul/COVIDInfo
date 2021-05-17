//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextUnderlineCreate.h"

@implementation PTTextUnderlineCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    return self;
}

-(Class)annotClass
{
    return [PTUnderline class];
}

+(PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeUnderline;
}

@end
