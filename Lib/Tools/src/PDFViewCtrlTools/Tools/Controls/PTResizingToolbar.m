//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTResizingToolbar.h"

#import "NSLayoutConstraint+PTPriority.h"

static const NSInteger PTResizingToolbar_flexibleItemTag = NSIntegerMax;
static const NSInteger PTResizingToolbar_ignoredItemTag = -1;

@interface PTResizingToolbar ()

@property (nonatomic, assign) BOOL contentViewConstaintsSetup;

@end

@implementation PTResizingToolbar

- (void)updateForItems
{
    NSMutableArray<UIBarButtonItem *> *mutableItems = [NSMutableArray array];
    
    if (@available(iOS 11.0, *)) {
        // Add leading items.
        if (self.leadingItems.count > 0) {
            [mutableItems addObjectsFromArray:self.leadingItems];
            
            // Add fixed space after leading items.
            UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            fixedSpace.width = 12.0;
            [mutableItems addObject:fixedSpace];
        }
        
        [mutableItems addObject:[[UIBarButtonItem alloc] initWithCustomView:self.contentView]];
        
        // Add trailing items.
        if (self.trailingItems.count > 0) {
            // Add fixed space before trailing items.
            UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            fixedSpace.width = 12.0;
            [mutableItems addObject:fixedSpace];

            [mutableItems addObjectsFromArray:self.trailingItems];
        }
    } else {
        // Add leading items.
        if (self.leadingItems.count > 0) {
            [mutableItems addObjectsFromArray:self.leadingItems];
            
            // The "block" item is needed to prevent the other buttons from extending their hit boxes over the UISlider.
            UIBarButtonItem *leadingBlock = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] init]];
            leadingBlock.tag = PTResizingToolbar_ignoredItemTag;
            
            [mutableItems addObject:leadingBlock];
        }
        
        // The flexible space item is used to separate the leading & trailing items and is the slider's
        // stand-in in the items array.
        UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        flexItem.tag = PTResizingToolbar_flexibleItemTag;

        [mutableItems addObject:flexItem];
        
        // Add trailing items.
        if (self.trailingItems.count > 0) {
            // The "block" item is needed to prevent the other buttons from extending their hit boxes over the UISlider.
            UIBarButtonItem *trailingBlock = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] init]];
            trailingBlock.tag = PTResizingToolbar_ignoredItemTag;
    
            [mutableItems addObject:trailingBlock];
            
            [mutableItems addObjectsFromArray:self.trailingItems];
        }
    }
    
    self.items = [mutableItems copy];
}

- (void)setContentView:(UIView *)contentView
{
    if (_contentView == contentView) {
        // No change.
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Update content view constraints after the next layout update.
        self.contentViewConstaintsSetup = NO;
    } else {
        // Remove old content view.
        [_contentView removeFromSuperview];
        
        // Add new content view.
        [self addSubview:contentView];
    }
    
    _contentView = contentView;
    
    [self updateForItems];
}

#pragma mark - Leading item(s)

- (UIBarButtonItem *)leadingItem
{
    return self.leadingItems.firstObject;
}

- (void)setLeadingItem:(UIBarButtonItem *)leadingItem
{
    [self setLeadingItems:((leadingItem) ? @[leadingItem] : nil)];
}

- (void)setLeadingItems:(NSArray<UIBarButtonItem *> *)leadingItems
{
    _leadingItems = [leadingItems copy];
    
    [self updateForItems];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingLeadingItem
{
    return [NSSet setWithObject:PT_CLASS_KEY(PTResizingToolbar, leadingItems)];
}

#pragma mark - Trailing item(s)

- (UIBarButtonItem *)trailingItem
{
    return self.trailingItems.firstObject;
}

- (void)setTrailingItem:(UIBarButtonItem *)trailingItem
{
    [self setTrailingItems:((trailingItem) ? @[trailingItem] : nil)];
}

- (void)setTrailingItems:(NSArray<UIBarButtonItem *> *)trailingItems
{
    _trailingItems = [trailingItems copy];
    
    [self updateForItems];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingTrailingItem
{
    return [NSSet setWithObject:PT_CLASS_KEY(PTResizingToolbar, trailingItems)];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (@available(iOS 11.0, *)) {
        // Setup content view constraints when it has a superview.
        if (self.contentView.superview && !self.contentViewConstaintsSetup) {
            [NSLayoutConstraint pt_activateConstraints:
             @[
               [self.contentView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
               ] withPriority:UILayoutPriorityDefaultHigh];

            self.contentViewConstaintsSetup = YES;
        }
    } else {
        if (self.contentView.superview) {
            [self PT_layoutContentView];
        }
    }
}

// iOS 10: manually layout the contentView.
- (void)PT_layoutContentView
{
    // Count the number of items before and after the flexible space item.
    NSUInteger leadingItemCount = 0;
    NSUInteger trailingItemCount = 0;
    
    // Used to switch from tracking leading items to trailing items.
    BOOL foundFlex = NO;
    
    for (UIBarButtonItem *toolbarItem in self.items) {
        // Skip ignored items.
        if (toolbarItem.tag == PTResizingToolbar_ignoredItemTag) {
            continue;
        }
        
        // Switch from tracking leading items to trailing items.
        if (toolbarItem.tag == PTResizingToolbar_flexibleItemTag) {
            foundFlex = YES;
            continue;
        }
        
        if (!foundFlex) {
            // Found a leading item.
            leadingItemCount++;
        } else {
            // Found a trailing item.
            trailingItemCount++;
        }
    }
    
    NSAssert(leadingItemCount == self.leadingItems.count, @"Leading item counts do not match");
    NSAssert(trailingItemCount == self.trailingItems.count, @"Trailing item counts do not match");
    
    // Rects enclosing all the leading and trailing buttons.
    CGRect leadingButtonsRect = CGRectZero;
    CGRect trailingButtonsRect = CGRectZero;
    
    CGRect toolbarBounds = self.bounds;
    
    CGRect leftRect = CGRectZero;
    CGRect rightRect = CGRectZero;
    
    // Divide toolbarBounds rect into equal left and right rects.
    CGRectDivide(toolbarBounds, &leftRect, &rightRect, CGRectGetWidth(toolbarBounds) / 2, CGRectMinXEdge);
    
    NSAssert(CGRectIntersectsRect(toolbarBounds, leftRect), @"Failed to divide toolbar rect in half");
    NSAssert(CGRectIntersectsRect(toolbarBounds, rightRect), @"Failed to divide toolbar rect in half");
    
    // Track the number of leading and trailing buttons.
    NSUInteger leadingSubviewCount = 0;
    NSUInteger trailingSubviewCount = 0;
    
    for (UIView *subview in self.subviews) {
        // Skip slider.
        if (subview == self.contentView) {
            continue;
        }
        
        // Skip non-UIControl subviews (eg. UIToolbar's _UIBarBackground, dummy UIView items, etc.).
        if (![subview isKindOfClass:[UIControl class]]) {
            continue;
        }
        
        CGRect subViewFrame = subview.frame;
        
        // Check whether the subview is on the toolbar's leading or trailing side.
        if (CGRectIntersectsRect(leftRect, subViewFrame) && leadingSubviewCount <= leadingItemCount) {
            // Subview corresponds to a leading item.
            if (CGRectIsEmpty(leadingButtonsRect)) {
                leadingButtonsRect = subViewFrame;
            } else {
                leadingButtonsRect = CGRectUnion(leadingButtonsRect, subViewFrame);
            }
            
            leadingSubviewCount++;
        } else if (CGRectIntersectsRect(rightRect, subViewFrame) && trailingSubviewCount <= trailingItemCount) {
            // Subview corresponds to a trailing item.
            if (CGRectIsEmpty(trailingButtonsRect)) {
                trailingButtonsRect = subViewFrame;
            } else {
                trailingButtonsRect = CGRectUnion(trailingButtonsRect, subViewFrame);
            }
            
            trailingSubviewCount++;
        }
    }
    
    CGRect frame = self.contentView.frame;
    
    CGRect insetToolbarBounds = UIEdgeInsetsInsetRect(toolbarBounds, self.layoutMargins);
    
    if (CGRectIsEmpty(leadingButtonsRect)) {
        // Extend to toolbar leading edge.
        frame.origin.x = CGRectGetMinX(insetToolbarBounds);
    } else {
        // Extend to trailing edge of leadingButtonsRect, or toolbar leading edge.
        frame.origin.x = fmax(CGRectGetMinX(insetToolbarBounds), CGRectGetMaxX(leadingButtonsRect) + 12.0);
    }
    
    if (CGRectIsEmpty(trailingButtonsRect)) {
        // Extend to toolbar trailing edge.
        frame.size.width = CGRectGetMaxX(insetToolbarBounds) - frame.origin.x;
    } else {
        // Extend to leading edge of trailingButtonsRect, or toolbar trailing edge.
        frame.size.width = fmin(CGRectGetMaxX(insetToolbarBounds), CGRectGetMinX(trailingButtonsRect) - 12.0) - frame.origin.x;
    }
    
    // Center vertically in toolbar.
    frame.origin.y = (CGRectGetHeight(toolbarBounds) / 2) - (CGRectGetHeight(frame) / 2);
    
    self.contentView.frame = frame;
}

@end
