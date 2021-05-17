//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UIScrollView+PTAdditions.h"

#import <objc/runtime.h>

static void * UIScrollView_PTAdditions_pt_extendedContentInset = &UIScrollView_PTAdditions_pt_extendedContentInset;

static void * UIScrollView_PTAdditions_pt_extendedScrollIndicatorInsets = &UIScrollView_PTAdditions_pt_extendedScrollIndicatorInsets;

@implementation UIScrollView (PTAdditions)

- (UIEdgeInsets)pt_effectiveContentInset
{
    if (@available(iOS 11.0, *)) {
        return self.adjustedContentInset;
    } else {
        return self.contentInset;
    }
}

- (BOOL)pt_isScrollBouncing
{
    return ([self pt_isScrollBouncingTop] ||
            [self pt_isScrollBouncingLeft] ||
            [self pt_isScrollBouncingBottom] ||
            [self pt_isScrollBouncingRight]);
}

- (BOOL)pt_isScrollBouncingTop
{
    if (!self.bounces || [self isDragging]) {
        return NO;
    }
    
    const UIEdgeInsets contentInset = self.pt_effectiveContentInset;
    
    return self.contentOffset.y < -(contentInset.top);
}

- (BOOL)pt_isScrollBouncingLeft
{
    if (!self.bounces || [self isDragging]) {
        return NO;
    }
    
    const UIEdgeInsets contentInset = self.pt_effectiveContentInset;
    
    return self.contentOffset.x < -(contentInset.left);
}

- (BOOL)pt_isScrollBouncingBottom
{
    if (!self.bounces || [self isDragging]) {
        return NO;
    }
        
    const CGFloat contentHeight = self.contentSize.height;
    const UIEdgeInsets contentInset = self.contentInset;
    const CGFloat effectiveContentHeight = contentInset.top + contentHeight + contentInset.bottom;
    const CGFloat viewportHeight = CGRectGetHeight(self.bounds);
    
    if (effectiveContentHeight >= viewportHeight) {
        
    }

    const CGFloat maximumVerticalContentOffset = contentHeight + contentInset.bottom - viewportHeight;
    
    return self.contentOffset.y > maximumVerticalContentOffset;
}

- (BOOL)pt_isScrollBouncingRight
{
    if (!self.bounces || [self isDragging]) {
        return NO;
    }
    
    const CGFloat contentWidth = self.contentSize.width;
    const UIEdgeInsets contentInset = self.pt_effectiveContentInset;
    const CGFloat effectiveContentWidth = contentInset.left + contentWidth + contentInset.right;
    const CGFloat viewportWidth = CGRectGetWidth(self.bounds);
    
    if (effectiveContentWidth >= viewportWidth) {
        
    }
    
    const CGFloat maximumHorizontalContentOffset = contentWidth + contentInset.right - viewportWidth;
    
    return self.contentOffset.x > maximumHorizontalContentOffset;
}

#pragma mark - extendedContentInset

- (UIEdgeInsets)pt_extendedContentInset
{
    NSValue *value = objc_getAssociatedObject(self, UIScrollView_PTAdditions_pt_extendedContentInset);
    if (value) {
        return value.UIEdgeInsetsValue;
    }
    
    // No saved value.
    return UIEdgeInsetsZero;
}

- (void)pt_setExtendedContentInset:(UIEdgeInsets)extendedContentInset
{
    UIEdgeInsets oldExtendedContentInset = [self pt_extendedContentInset];

    if (UIEdgeInsetsEqualToEdgeInsets(extendedContentInset, oldExtendedContentInset)) {
        // No change.
        return;
    }
    
    UIEdgeInsets contentInset = self.contentInset;
    
    // Update content inset with change.
    contentInset.top += (extendedContentInset.top - oldExtendedContentInset.top);
    contentInset.left += (extendedContentInset.left - oldExtendedContentInset.left);
    contentInset.bottom += (extendedContentInset.bottom - oldExtendedContentInset.bottom);
    contentInset.right += (extendedContentInset.right - oldExtendedContentInset.right);
    
    self.contentInset = contentInset;
    
    // Save new value.
    objc_setAssociatedObject(self, UIScrollView_PTAdditions_pt_extendedContentInset,
                             [NSValue valueWithUIEdgeInsets:extendedContentInset],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)pt_extendedScrollIndicatorInsets
{
    NSValue *value = objc_getAssociatedObject(self, UIScrollView_PTAdditions_pt_extendedScrollIndicatorInsets);
    if (value) {
        return value.UIEdgeInsetsValue;
    }
    
    // No saved value.
    return UIEdgeInsetsZero;
}

- (void)pt_setExtendedScrollIndicatorInsets:(UIEdgeInsets)extendedScrollIndicatorInsets
{
    UIEdgeInsets oldExtendedScrollIndicatorInsets = [self pt_extendedScrollIndicatorInsets];
    
    if (UIEdgeInsetsEqualToEdgeInsets(extendedScrollIndicatorInsets, oldExtendedScrollIndicatorInsets)) {
        // No change.
        return;
    }
    
    UIEdgeInsets scrollIndicatorInsets = self.scrollIndicatorInsets;
    
    // Update scroll indicator insets with change.
    scrollIndicatorInsets.top += (extendedScrollIndicatorInsets.top - oldExtendedScrollIndicatorInsets.top);
    scrollIndicatorInsets.left += (extendedScrollIndicatorInsets.left - oldExtendedScrollIndicatorInsets.left);
    scrollIndicatorInsets.bottom += (extendedScrollIndicatorInsets.bottom - oldExtendedScrollIndicatorInsets.bottom);
    scrollIndicatorInsets.right += (extendedScrollIndicatorInsets.right - oldExtendedScrollIndicatorInsets.right);
    
    self.scrollIndicatorInsets = scrollIndicatorInsets;
    
    // Save new value.
    objc_setAssociatedObject(self, UIScrollView_PTAdditions_pt_extendedScrollIndicatorInsets,
                             [NSValue valueWithUIEdgeInsets:extendedScrollIndicatorInsets],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

@end

PT_DEFINE_CATEGORY_SYMBOL(UIScrollView, PTAdditions)
