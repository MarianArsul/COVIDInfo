//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotStyle.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStylePreview : UIView

@property (nonatomic) PTExtendedAnnotType annotType;

@property (nonatomic, strong, nullable) UIColor *color;

@property (nonatomic, strong, nullable) UIColor *fillColor;

@property (nonatomic, strong, nullable) UIColor *textColor;

@property (nonatomic, strong, nullable) UIFontDescriptor *fontDescriptor;

@property (nonatomic) CGFloat thickness;

@property (nonatomic) CGFloat opacity;

@property (nonatomic) CGFloat textSize;

@end

NS_ASSUME_NONNULL_END
