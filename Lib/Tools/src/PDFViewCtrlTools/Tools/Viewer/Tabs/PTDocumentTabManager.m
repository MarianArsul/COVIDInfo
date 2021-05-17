//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentTabManager.h"

#import "PTToolsUtil.h"

#import "NSArray+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentTabManager ()
{
    NSMutableArray<PTDocumentTabItem *> *_mutableItems;
    NSArray<PTDocumentTabItem *> *_itemsCopy;
}

@property (nonatomic, readwrite, getter=isMoving) BOOL moving;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentTabManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableItems = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public item API

- (void)addItem:(PTDocumentTabItem *)item
{
    [self insertItem:item atIndex:self.items.count];
}

- (void)insertItem:(PTDocumentTabItem *)item atIndex:(NSUInteger)index
{
    NSAssert(index <= self.items.count,
             @"index for item insertion %lu is beyond item count of %lu",
             (unsigned long)index, (unsigned long)self.items.count);
    
    // Primitive mutator
    [self insertObject:item inItemsAtIndex:index];
}

- (void)removeItem:(PTDocumentTabItem *)item
{
    const NSUInteger index = [self.items indexOfObject:item];
    [self removeItemAtIndex:index];
}

- (void)removeItemAtIndex:(NSUInteger)index
{
    NSAssert(index <= self.items.count,
             @"index for item removal %lu is beyond item count of %lu",
             (unsigned long)index, (unsigned long)self.items.count);
        
    // Primitive mutator
    [self removeObjectFromItemsAtIndex:index];
}

- (void)moveItemAtIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex
{
    NSAssert(index <= self.items.count,
             @"original index for item before move %lu is beyond item count of %lu",
             (unsigned long)index, (unsigned long)self.items.count);
    NSAssert(newIndex <= self.items.count,
             @"new index for item after move %lu is beyond item count of %lu",
             (unsigned long)newIndex, (unsigned long)self.items.count);
    
    // Indicate that a item is being moved, since we will be generating remove and insert changes,
    // which should be considered together as a move change.
    self.moving = YES;
    
    PTDocumentTabItem *item = self.items[index];
    const BOOL isSelected = (item == self.selectedItem);
    
    [self removeItemAtIndex:index];
    [self insertItem:item atIndex:newIndex];
    
    // Re-select item after move.
    if (isSelected) {
        self.selectedItem = item;
    }
    
    self.moving = NO;
}

#pragma mark - Items

- (NSArray<PTDocumentTabItem *> *)items
{
    if (!_itemsCopy) {
        _itemsCopy = [_mutableItems copy];
    }
    
    NSAssert([_itemsCopy isEqualToArray:_mutableItems],
             @"Immutable copy of items differs from internal (mutable) items: copy has %lu items, internal has %lu items",
             (unsigned long)_itemsCopy.count, (unsigned long)_mutableItems.count);
    
    return _itemsCopy;
}

#pragma mark Selected index

- (NSUInteger)selectedIndex
{
    if (!self.selectedItem) {
        return NSNotFound;
    }
    
    return [self.items indexOfObject:self.selectedItem];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    self.selectedItem = self.items[selectedIndex];
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedIndex
{
    // Setting selectedItem will trigger change notifications for selectedIndex
    // because it is listed as "affecting" selectedIndex.
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedIndex
{
    // Changes to the selectedItem property should trigger change notifications
    // for the selectedIndex property.
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTDocumentTabManager, selectedItem),
    ]];
}

#pragma mark Selected item

- (void)setSelectedItem:(PTDocumentTabItem *)selectedItem
{
    if (!selectedItem) {
        // A nil selected item is only allowed with a item count of 0.
        if (self.items.count != 0) {
            NSString *reason = [NSString stringWithFormat:@"selected item cannot be nil with a item count of %lu",
                                (unsigned long)self.items.count];
            
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            @throw exception;
            return;
        }
    }
    // Ensure selected item is in items.
    else if (![self.items containsObject:selectedItem]) {
        NSString *reason = [NSString stringWithFormat:@"selected item %@ is not in the list of items",
                            selectedItem];
        
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        @throw exception;
        return;
    }
    
    _selectedItem = selectedItem;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedItem
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTDocumentTabManager, items),
    ]];
}

#pragma mark - KVC accessors

- (NSUInteger)countOfItems
{
    return _mutableItems.count;
}

- (id)objectInItemsAtIndex:(NSUInteger)index
{
    return _mutableItems[index];
}

- (NSArray *)itemsAtIndexes:(NSIndexSet *)indexes
{
    return [_mutableItems objectsAtIndexes:indexes];
}

- (void)getItems:(PTDocumentTabItem * __unsafe_unretained *)buffer range:(NSRange)inRange
{
    [_mutableItems getObjects:buffer range:inRange];
}

#pragma mark mutators

- (void)insertObject:(PTDocumentTabItem *)object inItemsAtIndex:(NSUInteger)index
{
    [_mutableItems insertObject:object atIndex:index];
    _itemsCopy = nil;
    
    // Set selectedItem when inserting the first item.
    if (!_selectedItem) {
        NSAssert(_mutableItems.count == 1, NSInternalInconsistencyException);
        
        _selectedItem = object;
    }
}

- (void)insertItems:(NSArray<PTDocumentTabItem *> *)items atIndexes:(NSIndexSet *)indexes
{
    NSParameterAssert(items.count == indexes.count);
    
    [_mutableItems insertObjects:items atIndexes:indexes];
    _itemsCopy = nil;
    
    if (!_selectedItem) {
        NSAssert(_mutableItems.count == items.count, NSInternalInconsistencyException);
        
        _selectedItem = items.firstObject;
    }
}

- (void)removeObjectFromItemsAtIndex:(NSUInteger)index
{
    [self PT_updateSelectionForItemsRemovedAtIndexes:[NSIndexSet indexSetWithIndex:index]];
    
    [_mutableItems removeObjectAtIndex:index];
    _itemsCopy = nil;
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [self PT_updateSelectionForItemsRemovedAtIndexes:indexes];
    
    [_mutableItems removeObjectsAtIndexes:indexes];
    _itemsCopy = nil;
}

- (void)PT_updateSelectionForItemsRemovedAtIndexes:(NSIndexSet *)indexes
{
    NSArray<PTDocumentTabItem *> *removedItems = [_mutableItems objectsAtIndexes:indexes];
    if (_selectedItem &&
        [removedItems containsObject:_selectedItem]) {
        if (_mutableItems.count > indexes.count) {
            const NSUInteger currentSelectedIndex = [_mutableItems indexOfObject:_selectedItem];
            NSAssert(currentSelectedIndex != NSNotFound, NSInternalInconsistencyException);
            
            NSUInteger selectedIndex = NSNotFound;
            
            for (NSUInteger index = currentSelectedIndex + 1; index < _mutableItems.count; index++) {
                if (![indexes containsIndex:index]) {
                    selectedIndex = index;
                    break;
                }
            }
            if (selectedIndex == NSNotFound) {
                NSAssert(currentSelectedIndex > 0, @"Expected: currentSelectedIndex > 0");
                
                for (NSUInteger index = currentSelectedIndex - 1; index >= 0; index--) {
                    if (![indexes containsIndex:index]) {
                        selectedIndex = index;
                        break;
                    }
                }
            }
            NSAssert(selectedIndex != NSNotFound, NSInternalInconsistencyException);
            
            _selectedItem = _mutableItems[selectedIndex];
        } else {
            _selectedItem = nil;
        }
    }
}

- (void)replaceObjectInItemsAtIndex:(NSUInteger)index withObject:(PTDocumentTabItem *)object
{
    [self PT_updateSelectionForItemsReplacedAtIndexes:[NSIndexSet indexSetWithIndex:index]
                                            withItems:@[object]];
    
    [_mutableItems replaceObjectAtIndex:index withObject:object];
    _itemsCopy = nil;
}

- (void)replaceItemsAtIndexes:(NSIndexSet *)indexes withItems:(NSArray<PTDocumentTabItem *> *)array
{
    [self PT_updateSelectionForItemsReplacedAtIndexes:indexes withItems:array];
    
    [_mutableItems replaceObjectsAtIndexes:indexes withObjects:array];
    _itemsCopy = nil;
}

- (void)PT_updateSelectionForItemsReplacedAtIndexes:(NSIndexSet *)indexes withItems:(NSArray<PTDocumentTabItem *> *)array
{
    NSParameterAssert(indexes.count == array.count);
    
    NSArray<PTDocumentTabItem *> * const replacedItems = [_mutableItems objectsAtIndexes:indexes];
    if (_selectedItem &&
        [replacedItems containsObject:_selectedItem]) {
        const NSUInteger currentSelectedIndex = [_mutableItems indexOfObject:_selectedItem];
        NSAssert(currentSelectedIndex != NSNotFound, NSInternalInconsistencyException);
        
        // Find the index in `array` that corresponds to the current selected index.
        __block NSUInteger arraySelectedIndex = 0;
        [indexes enumerateIndexesUsingBlock:^(const NSUInteger index, BOOL *stop) {
            if (index == currentSelectedIndex) {
                *stop = YES;
                return;
            }
            arraySelectedIndex++;
        }];
        NSAssert(arraySelectedIndex < array.count, NSInternalInconsistencyException);
        
        _selectedItem = array[arraySelectedIndex];
    }
}

#pragma mark - Persistence

#define PT_SAVED_TABS_FILENAME @"documentItems.plist"

+ (NSURL *)savedItemsURL
{
    NSURL *resourcesDirectoryURL = PTToolsUtil.toolsResourcesDirectoryURL;
    NSAssert(resourcesDirectoryURL != nil,
             @"Failed to get tools resources directory URL");
    
    return [resourcesDirectoryURL URLByAppendingPathComponent:PT_SAVED_TABS_FILENAME];
}

- (void)saveItems
{
    NSURL *savedItemsURL = [[self class] savedItemsURL];
    
    [self saveItemsToURL:savedItemsURL];
}

#define PT_ITEMS_VERSION 1
#define PT_ITEMS_VERSION_KEY @"version"

- (void)saveItemsToURL:(NSURL *)savedItemsURL
{
    NSKeyedArchiver *archiver = nil;
    if (@available(iOS 11.0, *)) {
        archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:YES];
    } else {
        archiver = [[NSKeyedArchiver alloc] init];
    }
    
    [self encodeItemsWithCoder:archiver];

    NSData *data = archiver.encodedData;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *writeError = nil;
        const BOOL writeSuccess = [data writeToURL:savedItemsURL
                                           options:(NSDataWritingAtomic)
                                             error:&writeError];
        if (!writeSuccess) {
            NSLog(@"Failed to save items: %@", writeError);
        }
    });
}

- (void)encodeItemsWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:PT_ITEMS_VERSION
                    forKey:PT_ITEMS_VERSION_KEY];
    
    [encoder encodeObject:self.items
                   forKey:PT_SELF_KEY(items)];
    [encoder encodeConditionalObject:self.selectedItem
                              forKey:PT_SELF_KEY(selectedItem)];
}

- (void)restoreItems
{
    NSURL *savedItemsURL = [[self class] savedItemsURL];
    
    [self restoreItemsFromURL:savedItemsURL];
}

- (void)restoreItemsFromURL:(NSURL *)savedItemsURL
{
    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:savedItemsURL options:0 error:&readError];
    if (!data) {
        // An NSFileReadNoSuchFileError error is allowed.
        const BOOL fileNotFound = ([readError.domain isEqual:NSCocoaErrorDomain] &&
                                   readError.code == NSFileReadNoSuchFileError);
        if (!fileNotFound) {
            NSLog(@"Failed to load saved items: %@", readError);
        }
        return;
    }
    
    NSKeyedUnarchiver *unarchiver = nil;
    if (@available(iOS 11.0, *)) {
        NSError *unarchiveError = nil;
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data
                                                                 error:&unarchiveError];
        if (unarchiveError) {
            NSLog(@"Failed to load saved items: %@", unarchiveError);
            return;
        }
    } else {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    }

    [self decodeItemsWithCoder:unarchiver];
}

- (void)decodeItemsWithCoder:(NSCoder *)decoder
{
    const NSInteger version = [decoder decodeIntegerForKey:PT_ITEMS_VERSION_KEY];

    if (version >= 1) {
        NSError *decodeError = nil;
        
        // Decode list of items.
        id decodedItems = [decoder decodeTopLevelObjectOfClasses:[NSSet setWithArray:@[
            [NSArray class],
            [PTDocumentTabItem class],
        ]] forKey:PT_SELF_KEY(items) error:&decodeError];
        if (!decodedItems && decodeError) {
            NSLog(@"Error decoding \"%@\": %@", PT_SELF_KEY(items), decodeError);
        }
        NSArray<PTDocumentTabItem *> *items = decodedItems;
        
        // Decode previously selected item.
        id decodedSelectedItem = [decoder decodeTopLevelObjectOfClass:[PTDocumentTabItem class] forKey:PT_SELF_KEY(selectedItem) error:&decodeError];
        if (!decodedSelectedItem && decodeError) {
            NSLog(@"Error decoding \"%@\": %@", PT_SELF_KEY(selectedItem), decodeError);
        }
        PTDocumentTabItem *selectedItem = decodedSelectedItem;
        
        if (items) {
            [self willChangeValueForKey:PT_SELF_KEY(items)];
            
            NSMutableArray<PTDocumentTabItem *> *itemsToKeep = [NSMutableArray array];
            for (PTDocumentTabItem *item in items) {
                // Filter out items without any URL information
                // (bookmarks could not be resolved).
                if (!item.sourceURL && !item.documentURL) {
                    continue;
                }
                
                // Check if the item is a duplicate.
                BOOL keepItem = YES;
                for (PTDocumentTabItem *itemToKeep in itemsToKeep) {
                    if (item.documentURL && itemToKeep.documentURL) {
                        // Check for same document URLs.
                        if ([item.documentURL isEqual:itemToKeep.documentURL]) {
                            // Duplicate item (document URL) - skip.
                            keepItem = NO;
                            break;
                        }
                    } else if (item.documentURL || itemToKeep.documentURL) {
                        // At least one item has a document URL.
                        if ([item.sourceURL isEqual:itemToKeep.sourceURL]) {
                            // Duplicate item (source URL) - skip.
                            keepItem = NO;
                            break;
                        }
                        continue;
                    } else {
                        if ([item.sourceURL isEqual:itemToKeep.sourceURL]) {
                            // Duplicate item (source URL) - skip.
                            keepItem = NO;
                            break;
                        }
                    }
                }
                if (keepItem) {
                    [itemsToKeep addObject:item];
                }
            }
            
            _mutableItems = [itemsToKeep mutableCopy] ?: [NSMutableArray array];
            _itemsCopy = nil;
            
            if (selectedItem && [_mutableItems containsObject:selectedItem]) {
                _selectedItem = selectedItem;
            } else {
                // Select first item in filtered list.
                _selectedItem = _mutableItems.firstObject;
            }
            
            [self didChangeValueForKey:PT_SELF_KEY(items)];
        }
    }
}

@end
