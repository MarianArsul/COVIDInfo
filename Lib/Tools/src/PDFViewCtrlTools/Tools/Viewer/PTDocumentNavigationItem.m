//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentNavigationItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentNavigationItem ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<UIBarButtonItem *> *> *adaptiveLeftBarButtonItems;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<UIBarButtonItem *> *> *adaptiveRightBarButtonItems;

@property (nonatomic, getter=isSettingLeftBarButtonItems) BOOL settingLeftBarButtonItems;
@property (nonatomic, getter=isSettingRightBarButtonItems) BOOL settingRightBarButtonItems;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentNavigationItem

- (void)PTDocumentNavigationItem_commonInit
{
    _adaptiveLeftBarButtonItems = [NSMutableDictionary dictionary];
    _adaptiveRightBarButtonItems = [NSMutableDictionary dictionary];
    
    _traitCollection = [[UITraitCollection alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self PTDocumentNavigationItem_commonInit];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super initWithTitle:title];
    if (self) {
        [self PTDocumentNavigationItem_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTDocumentNavigationItem_commonInit];
    }
    return self;
}

#pragma mark - Left bar button item(s)

@dynamic leftBarButtonItems;

- (void)setLeftBarButtonItems:(NSArray<UIBarButtonItem *> *)leftBarButtonItems animated:(BOOL)animated
{
    NSArray<UIBarButtonItem *> *items = [leftBarButtonItems copy];
    
    if (![self isSettingLeftBarButtonItems]) {
        [self PT_setLeftBarButtonItems:items
                          forSizeClass:UIUserInterfaceSizeClassCompact];
        [self PT_setLeftBarButtonItems:items
                          forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    
    [super setLeftBarButtonItems:items animated:animated];
}

@dynamic leftBarButtonItem;

- (void)setLeftBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated
{
    if (![self isSettingLeftBarButtonItems]) {
        NSArray<UIBarButtonItem *> *items = (item) ? @[item] : nil;
        
        [self PT_setLeftBarButtonItems:items
                          forSizeClass:UIUserInterfaceSizeClassCompact];
        [self PT_setLeftBarButtonItems:items
                          forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    
    [super setLeftBarButtonItem:item animated:animated];
}

#pragma mark Adaptivity

- (UIBarButtonItem *)leftBarButtonItemForSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    return [self leftBarButtonItemsForSizeClass:sizeClass].firstObject;
}

- (NSArray<UIBarButtonItem *> *)leftBarButtonItemsForSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    return self.adaptiveLeftBarButtonItems[@(sizeClass)];
}

- (void)setLeftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem forSizeClass:(UIUserInterfaceSizeClass)sizeClass animated:(BOOL)animated
{
    [self setLeftBarButtonItems:((leftBarButtonItem) ? @[leftBarButtonItem] : nil)
                   forSizeClass:sizeClass
                       animated:animated];
}

- (void)setLeftBarButtonItems:(NSArray<UIBarButtonItem *> *)leftBarButtonItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass animated:(BOOL)animated
{
    self.settingLeftBarButtonItems = YES;
    
    NSArray<UIBarButtonItem *> *items = [leftBarButtonItems copy];
    [self PT_setLeftBarButtonItems:items forSizeClass:sizeClass];
    
    if (sizeClass == self.traitCollection.horizontalSizeClass) {
        [self setLeftBarButtonItems:items animated:animated];
    }
    
    self.settingLeftBarButtonItems = NO;
}

- (void)PT_setLeftBarButtonItems:(NSArray<UIBarButtonItem *> *)leftBarButtonItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSParameterAssert(![leftBarButtonItems isKindOfClass:[NSMutableArray class]]);
    
    if (leftBarButtonItems) {
        self.adaptiveLeftBarButtonItems[@(sizeClass)] = leftBarButtonItems;
    } else {
        [self.adaptiveLeftBarButtonItems removeObjectForKey:@(sizeClass)];
    }
}

#pragma mark - Right bar button item(s)

@dynamic rightBarButtonItems;

- (void)setRightBarButtonItems:(NSArray<UIBarButtonItem *> *)rightBarButtonItems animated:(BOOL)animated
{
    NSArray<UIBarButtonItem *> *items = [rightBarButtonItems copy];
    
    if (![self isSettingRightBarButtonItems]) {
        [self PT_setRightBarButtonItems:items
                           forSizeClass:UIUserInterfaceSizeClassCompact];
        [self PT_setRightBarButtonItems:items
                           forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    
    [super setRightBarButtonItems:items animated:animated];
}

@dynamic rightBarButtonItem;

- (void)setRightBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated
{
    if (![self isSettingRightBarButtonItems]) {
        NSArray<UIBarButtonItem *> *items = (item) ? @[item] : nil;
        
        [self PT_setRightBarButtonItems:items
                           forSizeClass:UIUserInterfaceSizeClassCompact];
        [self PT_setRightBarButtonItems:items
                           forSizeClass:UIUserInterfaceSizeClassRegular];
    }
    
    [super setRightBarButtonItem:item animated:animated];
}

#pragma mark Adaptivity

- (UIBarButtonItem *)rightBarButtonItemForSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    return [self rightBarButtonItemsForSizeClass:sizeClass].firstObject;
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    return self.adaptiveRightBarButtonItems[@(sizeClass)];
}

- (void)setRightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem forSizeClass:(UIUserInterfaceSizeClass)sizeClass animated:(BOOL)animated
{
    [self setRightBarButtonItems:((rightBarButtonItem) ? @[rightBarButtonItem] : nil)
                    forSizeClass:sizeClass
                        animated:animated];
}

- (void)setRightBarButtonItems:(NSArray<UIBarButtonItem *> *)rightBarButtonItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass animated:(BOOL)animated
{
    self.settingRightBarButtonItems = YES;
    
    NSArray<UIBarButtonItem *> *items = [rightBarButtonItems copy];
    [self PT_setRightBarButtonItems:items forSizeClass:sizeClass];
    
    if (sizeClass == self.traitCollection.horizontalSizeClass) {
        [self setRightBarButtonItems:items animated:animated];
    }
    
    self.settingRightBarButtonItems = NO;
}

- (void)PT_setRightBarButtonItems:(NSArray<UIBarButtonItem *> *)rightBarButtonItems forSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    NSParameterAssert(![rightBarButtonItems isKindOfClass:[NSMutableArray class]]);
    
    if (rightBarButtonItems) {
        self.adaptiveRightBarButtonItems[@(sizeClass)] = rightBarButtonItems;
    } else {
        [self.adaptiveRightBarButtonItems removeObjectForKey:@(sizeClass)];
    }
}

- (void)setTraitCollection:(UITraitCollection *)traitCollection
{
    _traitCollection = [traitCollection copy];
    
    self.settingLeftBarButtonItems = YES;
    self.settingRightBarButtonItems = YES;
    
    NSArray<UIBarButtonItem *> *leftBarButtonItems = [self leftBarButtonItemsForSizeClass:_traitCollection.horizontalSizeClass];
    [self setLeftBarButtonItems:leftBarButtonItems animated:NO];
    
    NSArray<UIBarButtonItem *> *rightBarButtonItems = [self rightBarButtonItemsForSizeClass:_traitCollection.horizontalSizeClass];
    [self setRightBarButtonItems:rightBarButtonItems animated:NO];
    
    self.settingLeftBarButtonItems = NO;
    self.settingRightBarButtonItems = NO;
}

@end
