//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UINavigationBar+PTAdditions.h"

#include <objc/runtime.h>

static void *UINavigationBar_PTAdditions_pt_hiddenShadowImage = &UINavigationBar_PTAdditions_pt_hiddenShadowImage;
static void *UINavigationBar_PTAdditions_pt_savedShadowImage = &UINavigationBar_PTAdditions_pt_savedShadowImage;

@implementation UINavigationBar (PTAdditions)

- (BOOL)pt_isShadowHidden
{
    UIImage *hiddenShadowImage = objc_getAssociatedObject(self,
                                                          UINavigationBar_PTAdditions_pt_hiddenShadowImage);
    if (!hiddenShadowImage) {
        return NO;
    }
    
    return (self.shadowImage == hiddenShadowImage);
}

- (void)pt_setShadowHidden:(BOOL)hidden
{
    if ([self pt_isShadowHidden] == hidden) {
        return;
    }
    
    if (hidden) {
        // "Hide" the shadow by setting an empty image as the navigation bar's shadowImage.
        UIImage *hiddenShadowImage = objc_getAssociatedObject(self,
                                                              UINavigationBar_PTAdditions_pt_hiddenShadowImage);
        if (!hiddenShadowImage) {
            // Create an empty UIImage for the "hidden" shadow image.
            hiddenShadowImage = [[UIImage alloc] init];
            
            // Save the image, so it can be checked later in the pt_isShadowHidden method.
            objc_setAssociatedObject(self,
                                     UINavigationBar_PTAdditions_pt_hiddenShadowImage,
                                     hiddenShadowImage,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        if (self.shadowImage && self.shadowImage != hiddenShadowImage) {
            // Save the custom shadow image.
            objc_setAssociatedObject(self,
                                     UINavigationBar_PTAdditions_pt_savedShadowImage,
                                     self.shadowImage,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        self.shadowImage = hiddenShadowImage;
    } else {
        // Restore the saved custom shadow image.
        UIImage *savedShadowImage = objc_getAssociatedObject(self,
                                                             UINavigationBar_PTAdditions_pt_savedShadowImage);
        self.shadowImage = savedShadowImage;
        
        // Clear the saved custom shadow image.
        objc_setAssociatedObject(self,
                                 UINavigationBar_PTAdditions_pt_savedShadowImage,
                                 nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UINavigationBar, PTAdditions)
