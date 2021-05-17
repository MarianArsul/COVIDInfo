//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIGeometry+PTAdditions.h"

UIEdgeInsets PTUIEdgeInsetsMakeUniform(CGFloat inset)
{
    return UIEdgeInsetsMake(inset, inset, inset, inset);
}
