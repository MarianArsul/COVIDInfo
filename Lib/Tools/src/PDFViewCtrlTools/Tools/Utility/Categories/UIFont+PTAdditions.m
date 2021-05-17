//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2019 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIFont+PTAdditions.h"

@implementation UIFont (PTAdditions)

// https://mackarous.com/dev/2018/12/4/dynamic-type-at-any-font-weight
+ (instancetype)pt_preferredFontForTextStyle:(UIFontTextStyle)style weight:(UIFontWeight)weight
{
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    UIFont *font = [UIFont systemFontOfSize:descriptor.pointSize weight:weight];
    if (@available(iOS 11.0, *)) {
        UIFontMetrics *metrics = [UIFontMetrics metricsForTextStyle:style];
        font = [metrics scaledFontForFont:font];
    }
    return font;
}

+ (instancetype)pt_preferredFontForTextStyle:(UIFontTextStyle)style withTraits:(UIFontDescriptorSymbolicTraits)traits
{
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    descriptor = [descriptor fontDescriptorWithSymbolicTraits:traits];
    return [UIFont fontWithDescriptor:descriptor size:0];
}

+ (instancetype)pt_boldPreferredFontForTextStyle:(UIFontTextStyle)style
{
    return [self pt_preferredFontForTextStyle:style
                                   withTraits:UIFontDescriptorTraitBold];
}

+ (instancetype)pt_italicPreferredFontForTextStyle:(UIFontTextStyle)style
{
    return [self pt_preferredFontForTextStyle:style
                                   withTraits:UIFontDescriptorTraitItalic];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIFont, PTAdditions)
