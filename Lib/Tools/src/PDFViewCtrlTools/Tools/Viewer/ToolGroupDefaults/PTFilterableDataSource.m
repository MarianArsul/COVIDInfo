//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFilterableDataSource.h"

#import "NSArray+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTFilterableDataSource ()

@property (nonatomic, readwrite, copy, nullable) NSArray<NSArray<id> *> *filteredItems;

@end

NS_ASSUME_NONNULL_END

@implementation PTFilterableDataSource

- (void)setItems:(NSArray<NSArray<id> *> *)items
{
    _items = [items copy];
    
    [self filterItems];
}

- (void)setPredicate:(NSPredicate *)predicate
{
    _predicate = predicate;
    
    [self filterItems];
}

- (void)filterItems
{
    if (self.predicate) {
        self.filteredItems = [self.items pt_mapObjectsWithBlock:^NSArray<id> *(NSArray<id> *sectionItems, NSUInteger index, BOOL *stop) {
            return [sectionItems filteredArrayUsingPredicate:self.predicate];
        }];
    } else {
        self.filteredItems = self.items;
    }
}

- (void)insertItem:(id)item atFilteredIndexPath:(NSIndexPath *)filteredIndexPath
{
    const NSInteger section = filteredIndexPath.section;
    
    NSMutableArray<id> *sectionItems = [self.items[section] mutableCopy];
    NSArray<id> *filteredSectionItems = self.filteredItems[section];
    
    NSUInteger destinationItemIndex = NSNotFound;
    if (filteredIndexPath.row < filteredSectionItems.count) {
        const id destinationItem = filteredSectionItems[filteredIndexPath.row];
        destinationItemIndex = [sectionItems indexOfObject:destinationItem];
    } else {
        destinationItemIndex = filteredSectionItems.count;
    }
    NSAssert(destinationItemIndex != NSNotFound, NSInternalInconsistencyException);
    
    [sectionItems insertObject:item
                       atIndex:destinationItemIndex];
    
    self.items = [self.items pt_arrayByReplacingObjectAtIndex:section
                                                   withObject:[sectionItems copy]];
}

- (void)removeItemAtFilteredIndexPath:(NSIndexPath *)filteredIndexPath
{
    const NSInteger section = filteredIndexPath.section;
    const id item = self.filteredItems[section][filteredIndexPath.row];
    [self removeItem:item inSection:section];
}

- (void)removeItem:(id)item inSection:(NSInteger)section
{
    NSMutableArray<id> *sectionItems = [self.items[section] mutableCopy];
    [sectionItems removeObject:item];
    
    self.items = [self.items pt_arrayByReplacingObjectAtIndex:section
                                                   withObject:[sectionItems copy]];
}

- (void)moveItemAtFilteredIndexPath:(NSIndexPath *)sourceFilteredIndexPath toFilteredIndexPath:(NSIndexPath *)destinationFilteredIndexPath
{
    const NSInteger sourceSection = sourceFilteredIndexPath.section;
    const NSInteger destinationSection = destinationFilteredIndexPath.section;

    NSMutableArray<id> *sourceSectionItems = [self.items[sourceSection] mutableCopy];
    NSMutableArray<id> *filteredSourceSectionItems = [self.filteredItems[sourceSection] mutableCopy];
        
    NSMutableArray<id> *destinationSectionItems = nil;
    NSMutableArray<id> *filteredDestinationSectionItems = nil;
    if (sourceSection != destinationSection) {
        destinationSectionItems = [self.items[destinationSection] mutableCopy];
        filteredDestinationSectionItems = [self.filteredItems[destinationSection] mutableCopy];
    } else {
        destinationSectionItems = sourceSectionItems;
        filteredDestinationSectionItems = filteredSourceSectionItems;
    }
    
    const id item = filteredSourceSectionItems[sourceFilteredIndexPath.row];

    const id destinationItem = filteredDestinationSectionItems[destinationFilteredIndexPath.row];

    NSUInteger destinationItemIndex = NSNotFound;
    if (destinationItem) {
        destinationItemIndex = [destinationSectionItems indexOfObject:destinationItem];
    } else {
        destinationItemIndex = destinationSectionItems.count;
    }
    NSAssert(destinationItemIndex != NSNotFound, NSInternalInconsistencyException);
    
    [sourceSectionItems removeObject:item];
    [destinationSectionItems insertObject:item
                                  atIndex:destinationItemIndex];
    
    NSMutableArray<NSArray<id> *> *items = [self.items mutableCopy];
    items[sourceSection] = [sourceSectionItems copy];
    if (sourceSection != destinationSection) {
        items[destinationSection] = [destinationSectionItems copy];
    }
    self.items = [items copy];
}

@end
