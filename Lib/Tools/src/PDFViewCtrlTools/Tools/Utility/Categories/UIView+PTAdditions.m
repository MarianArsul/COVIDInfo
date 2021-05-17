//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIView+PTAdditions.h"

#import "UIViewController+PTAdditions.h"

@implementation UIView (PTAdditions)

- (UIViewController *)pt_containingViewController
{
    // Walk up the responder chain to find the closest view controller.
    for (UIResponder *responder = self.nextResponder; responder; responder = responder.nextResponder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

- (UIViewController *)pt_viewController
{
    // Find the containing view controller.
    UIViewController *viewController = self.pt_containingViewController;
    if (viewController) {
        return viewController;
    }
    
    // Find the top presented view controller.
    UIViewController *topController = UIApplication.sharedApplication.keyWindow.rootViewController;
    return topController.pt_topmostPresentedViewController;
}

- (UIView *)pt_ancestorOfKindOfClass:(Class)ancestorClass
{
    if (!ancestorClass) {
        return nil;
    }
    
    UIView *ancestor = self;
    while (ancestor) {
        if ([ancestor isKindOfClass:ancestorClass]) {
            return ancestor;
        }
        ancestor = ancestor.superview;
    }
    
    return nil;
}

- (BOOL)pt_isDescendantOfKindOfView:(Class)viewClass
{
    return ([self pt_ancestorOfKindOfClass:viewClass] != nil);
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIView, PTAdditions)
