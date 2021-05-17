//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIDocumentInteractionController+PTAdditions.h"

#import <objc/runtime.h>

static void *PT_UIDocumentInteractionController_savedBarTintColorKey = &PT_UIDocumentInteractionController_savedBarTintColorKey;

@interface UIDocumentInteractionController ()

@property (nonatomic, strong, nullable, setter=pt_setSavedBarTintColor:) UIColor *pt_savedBarTintColor;

@end

@implementation UIDocumentInteractionController (PTAdditions)

- (UIColor *)pt_savedBarTintColor
{
    return objc_getAssociatedObject(self, PT_UIDocumentInteractionController_savedBarTintColorKey);
}

- (void)pt_setSavedBarTintColor:(UIColor *)color
{
    return objc_setAssociatedObject(self, PT_UIDocumentInteractionController_savedBarTintColorKey,
                                    color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)pt_prepareForPresentation
{
    // Save the current bar tint color.
    self.pt_savedBarTintColor = [UINavigationBar appearance].barTintColor;
    // Reset bar tint color to the default color to avoid issues with custom (button) tint colors
    // provided by Apple or other third-party view controllers.
    [UINavigationBar appearance].barTintColor = nil;
}

- (void)pt_cleanupFromPresentation
{
    // Avoid clobbering the bar tint color if called multiple times.
    if (!self.pt_savedBarTintColor) {
        return;
    }
    
    // Restore the saved bar tint color.
    [UINavigationBar appearance].barTintColor = self.pt_savedBarTintColor;
    self.pt_savedBarTintColor = nil;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIDocumentInteractionController, PTAdditions)
