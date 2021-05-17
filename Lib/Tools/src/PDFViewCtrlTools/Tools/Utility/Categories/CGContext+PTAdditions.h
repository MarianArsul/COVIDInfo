//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"
#import "ToolsMacros.h"

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL
void pt_CGContextAddArcTo(CGContextRef context, double radius, double xAxisRotation, BOOL isLargeArc, BOOL sweep, double endX, double endY);

NS_ASSUME_NONNULL_END
