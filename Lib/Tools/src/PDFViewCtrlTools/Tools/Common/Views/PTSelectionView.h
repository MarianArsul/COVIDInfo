//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTResizeWidgetView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTSelectionView : UIView

- (nullable PTResizeWidgetView *)resizeWidgetForLocation:(PTResizeHandleLocation)location;

@end

NS_ASSUME_NONNULL_END
