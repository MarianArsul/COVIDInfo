//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIColor+PTEquality.h"

#import <tgmath.h>

NS_INLINE BOOL compareRGBAComponents(CGFloat value1, CGFloat value2)
{
    return round(value1 * 255) == round(value2 * 255);
}

@implementation UIColor (PTEquality)

- (BOOL)pt_isEqualToColor:(UIColor *)color
{
    UIColor *lhs = self;
    UIColor *rhs = color;
    
    // Shallow comparison.
    if (!rhs) {
        return NO;
    }
    else if ([lhs isEqual:rhs]) {
        return YES;
    }
    
    // Compare RGBA components.
    CGFloat red1, green1, blue1, alpha1;
    CGFloat red2, green2, blue2, alpha2;
    
    BOOL lhsSuccess = [lhs getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
    BOOL rhsSuccess =  [rhs getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
    
    if (lhsSuccess && rhsSuccess) {
        return (compareRGBAComponents(red1, red2)
                && compareRGBAComponents(green1, green2)
                && compareRGBAComponents(blue1, blue2)
                && compareRGBAComponents(alpha1, alpha2));
    }
    
    
    return NO;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIColor, PTEquality)
