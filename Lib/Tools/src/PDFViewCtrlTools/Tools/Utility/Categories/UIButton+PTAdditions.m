//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIButton+PTAdditions.h"

@implementation UIButton (PTAdditions)

- (void)pt_setInsetsForContentPadding:(UIEdgeInsets)contentPadding imageTitleSpacing:(CGFloat)imageTitleSpacing
{
    const UIUserInterfaceLayoutDirection layoutDirection = [[self class] userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute];
    
    switch (layoutDirection) {
        case UIUserInterfaceLayoutDirectionLeftToRight:
        {
            self.contentEdgeInsets = UIEdgeInsetsMake(contentPadding.top,
                                                      contentPadding.left,
                                                      contentPadding.bottom,
                                                      contentPadding.right + imageTitleSpacing);
            
            self.titleEdgeInsets = UIEdgeInsetsMake(0,
                                                    imageTitleSpacing,
                                                    0,
                                                    -imageTitleSpacing);
        }
            break;
        case UIUserInterfaceLayoutDirectionRightToLeft:
        {
            self.contentEdgeInsets = UIEdgeInsetsMake(contentPadding.top,
                                                      contentPadding.left + imageTitleSpacing,
                                                      contentPadding.bottom,
                                                      contentPadding.right);
            
            self.titleEdgeInsets = UIEdgeInsetsMake(0,
                                                    -imageTitleSpacing,
                                                    0,
                                                    imageTitleSpacing);
        }
            break;
    }
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIButton, PTAdditions)
