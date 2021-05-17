//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTableViewCell.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTTableViewCell ()

@end

NS_ASSUME_NONNULL_END

@implementation PTTableViewCell

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    CGSize systemLayoutSize = [super systemLayoutSizeFittingSize:targetSize
                                   withHorizontalFittingPriority:horizontalFittingPriority
                                         verticalFittingPriority:verticalFittingPriority];
    // Enforce a minimum cell (content) height of 44 pts.
    systemLayoutSize.height = fmax(44.0, systemLayoutSize.height);
    return systemLayoutSize;
}

@end
