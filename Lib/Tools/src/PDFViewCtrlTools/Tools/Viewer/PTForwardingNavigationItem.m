//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTForwardingNavigationItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTForwardingNavigationItem ()

@end

NS_ASSUME_NONNULL_END

@implementation PTForwardingNavigationItem

- (void)setForwardingTargetItem:(UINavigationItem *)forwardingTargetItem
{
    [self PT_setForwardingTargetItem:forwardingTargetItem animated:NO];
}

- (void)setForwardingTargetItem:(UINavigationItem *)forwardingTargetItem animated:(BOOL)animated
{
    [self willChangeValueForKey:PT_SELF_KEY(forwardingTargetItem)];
    
    [self PT_setForwardingTargetItem:forwardingTargetItem animated:animated];
    
    [self didChangeValueForKey:PT_SELF_KEY(forwardingTargetItem)];
}

+ (BOOL)automaticallyNotifiesObserversOfForwardingTargetItem
{
    return NO;
}

#pragma mark Private API

- (void)PT_setForwardingTargetItem:(UINavigationItem *)forwardingTargetItem animated:(BOOL)animated
{
    UINavigationItem *previousForwardingTargetItem = _forwardingTargetItem;
    _forwardingTargetItem = forwardingTargetItem;
    
    if (previousForwardingTargetItem) {
        [self PT_setForwardedLeftBarButtonItems:nil
                     previousLeftBarButtonItems:self.leftBarButtonItems
                              forNavigationItem:previousForwardingTargetItem
                                       animated:animated];
    }
    
    if (forwardingTargetItem) {
        forwardingTargetItem.title = self.title;
        
        forwardingTargetItem.prompt = self.prompt;
        
        [forwardingTargetItem setHidesBackButton:self.hidesBackButton animated:animated];
        forwardingTargetItem.leftItemsSupplementBackButton = self.leftItemsSupplementBackButton;
        
        forwardingTargetItem.titleView = self.titleView;
        
        [self PT_setForwardedLeftBarButtonItems:self.leftBarButtonItems
                     previousLeftBarButtonItems:nil
                              forNavigationItem:forwardingTargetItem
                                       animated:animated];
        
        [forwardingTargetItem setRightBarButtonItems:self.rightBarButtonItems animated:animated];
        
        if (@available(iOS 11.0, *)) {
            forwardingTargetItem.largeTitleDisplayMode = self.largeTitleDisplayMode;
            
            forwardingTargetItem.searchController = self.searchController;
            forwardingTargetItem.hidesSearchBarWhenScrolling = self.hidesSearchBarWhenScrolling;
        }
        
        if (@available(iOS 13.0, *)) {
            forwardingTargetItem.standardAppearance = self.standardAppearance;
            forwardingTargetItem.compactAppearance = self.compactAppearance;
            forwardingTargetItem.scrollEdgeAppearance = self.scrollEdgeAppearance;
        }
    }
}

#pragma mark - Property accessor forwarding

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    [self.forwardingTargetItem setTitle:title];
}

- (void)setLargeTitleDisplayMode:(UINavigationItemLargeTitleDisplayMode)largeTitleDisplayMode
{
    [super setLargeTitleDisplayMode:largeTitleDisplayMode];
    [self.forwardingTargetItem setLargeTitleDisplayMode:largeTitleDisplayMode];
}

- (void)setPrompt:(NSString *)prompt
{
    [super setPrompt:prompt];
    [self.forwardingTargetItem setPrompt:prompt];
}

- (void)setBackBarButtonItem:(UIBarButtonItem *)backBarButtonItem
{
    if (self.forwardingTargetItem) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Cannot set a backBarButtonItem with a parent item"
                                     userInfo:nil];
    }
    [super setBackBarButtonItem:backBarButtonItem];
}

- (void)setHidesBackButton:(BOOL)hidesBackButton animated:(BOOL)animated
{
    [super setHidesBackButton:hidesBackButton animated:animated];
    [self.forwardingTargetItem setHidesBackButton:hidesBackButton animated:animated];
}

- (void)setLeftItemsSupplementBackButton:(BOOL)leftItemsSupplementBackButton
{
    [super setLeftItemsSupplementBackButton:leftItemsSupplementBackButton];
    [self.forwardingTargetItem setLeftItemsSupplementBackButton:leftItemsSupplementBackButton];
}

- (void)setTitleView:(UIView *)titleView
{
    [super setTitleView:titleView];
    [self.forwardingTargetItem setTitleView:titleView];
}

- (void)setLeftBarButtonItems:(NSArray<UIBarButtonItem *> *)leftBarButtonItems animated:(BOOL)animated
{
    NSArray<UIBarButtonItem *> *previousLeftBarButtonItems = self.leftBarButtonItems;

    [super setLeftBarButtonItems:leftBarButtonItems animated:animated];
    
    [self PT_setForwardedLeftBarButtonItems:leftBarButtonItems
                 previousLeftBarButtonItems:previousLeftBarButtonItems
                          forNavigationItem:self.forwardingTargetItem
                                   animated:animated];
}

- (void)setLeftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem animated:(BOOL)animated
{
    NSArray<UIBarButtonItem *> *previousLeftBarButtonItems = self.leftBarButtonItems;
    
    [super setLeftBarButtonItem:leftBarButtonItem animated:animated];
    
    [self PT_setForwardedLeftBarButtonItems:(leftBarButtonItem ? @[leftBarButtonItem] : nil)
                 previousLeftBarButtonItems:previousLeftBarButtonItems
                          forNavigationItem:self.forwardingTargetItem
                                   animated:animated];
}

- (void)PT_setForwardedLeftBarButtonItems:(NSArray<UIBarButtonItem *> *)leftBarButtonItems previousLeftBarButtonItems:(NSArray<UIBarButtonItem *> *)previousLeftBarButtonItems forNavigationItem:(UINavigationItem *)navigationItem animated:(BOOL)animated
{
    if (!navigationItem) {
        return;
    }
    
    NSArray<UIBarButtonItem *> *forwardingTargetItems = navigationItem.leftBarButtonItems;
    
    NSArray<UIBarButtonItem *> *items = nil;
    if (leftBarButtonItems.count > 0) {
        if (forwardingTargetItems.count > 0) {
            if (previousLeftBarButtonItems.count > 0) {
                
                UIBarButtonItem *leadingPreviousItem = previousLeftBarButtonItems.firstObject;
                NSUInteger leadingPreviousItemIndex = [forwardingTargetItems indexOfObject:leadingPreviousItem];
                
                if (leadingPreviousItemIndex != NSNotFound) {
                    NSArray<UIBarButtonItem *> *trimmedItems = [forwardingTargetItems subarrayWithRange:NSMakeRange(0, leadingPreviousItemIndex)];
                    
                    // Append the incoming items to the (trailing) end of the
                    // target's trimmed items.
                    items = [trimmedItems arrayByAddingObjectsFromArray:leftBarButtonItems];
                } else {
                    // Couldn't find the previous item(s) in the target's current
                    // items.
                    // Append the incoming items to the (trailing) end of the target's
                    // current items.
                    items = [forwardingTargetItems arrayByAddingObjectsFromArray:leftBarButtonItems];
                }
            } else {
                // No previous items - the target's items are "clean".
                // Append the incoming items to the (trailing) end of the target's
                // current items.
                items = [forwardingTargetItems arrayByAddingObjectsFromArray:leftBarButtonItems];
            }
        } else {
            // Target does not contain any items - use incoming items.
            items = leftBarButtonItems;
        }
    } else {
        if (previousLeftBarButtonItems.count) {
            UIBarButtonItem *leadingPreviousItem = previousLeftBarButtonItems.firstObject;
            NSUInteger leadingPreviousItemIndex = [forwardingTargetItems indexOfObject:leadingPreviousItem];
            
            if (leadingPreviousItemIndex != NSNotFound) {
                NSArray<UIBarButtonItem *> *trimmedItems = [forwardingTargetItems subarrayWithRange:NSMakeRange(0, leadingPreviousItemIndex)];
                
                // Use the trimmed items.
                items = trimmedItems;
            } else {
                // Couldn't find the previous item(s) in the target's current
                // items.
                // Use the target's current items.
                items = forwardingTargetItems;
            }
        } else {
            // No previous items - the target's items are "clean".
            // Use the target's current items.
            items = forwardingTargetItems;
        }
    }
    [navigationItem setLeftBarButtonItems:items animated:animated];
}

- (void)setRightBarButtonItems:(NSArray<UIBarButtonItem *> *)rightBarButtonItems animated:(BOOL)animated
{
    [super setRightBarButtonItems:rightBarButtonItems animated:animated];
    [self.forwardingTargetItem setRightBarButtonItems:rightBarButtonItems animated:animated];
}

- (void)setRightBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated
{
    [super setRightBarButtonItem:item animated:animated];
    [self.forwardingTargetItem setRightBarButtonItem:item animated:animated];
}

- (void)setSearchController:(UISearchController *)searchController
{
    [super setSearchController:searchController];
    [self.forwardingTargetItem setSearchController:searchController];
}

- (void)setHidesSearchBarWhenScrolling:(BOOL)hidesSearchBarWhenScrolling
{
    [super setHidesSearchBarWhenScrolling:hidesSearchBarWhenScrolling];
    [self.forwardingTargetItem setHidesSearchBarWhenScrolling:hidesSearchBarWhenScrolling];
}

- (void)setStandardAppearance:(UINavigationBarAppearance *)standardAppearance
{
    [super setStandardAppearance:standardAppearance];
    [self.forwardingTargetItem setStandardAppearance:standardAppearance];
}

- (void)setCompactAppearance:(UINavigationBarAppearance *)compactAppearance
{
    [super setCompactAppearance:compactAppearance];
    [self.forwardingTargetItem setCompactAppearance:compactAppearance];
}

- (void)setScrollEdgeAppearance:(UINavigationBarAppearance *)scrollEdgeAppearance
{
    [super setScrollEdgeAppearance:scrollEdgeAppearance];
    [self.forwardingTargetItem setScrollEdgeAppearance:scrollEdgeAppearance];
}

@end
