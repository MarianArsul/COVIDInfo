//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTFilterableDataSource : NSObject

@property (nonatomic, copy, nullable) NSArray<NSArray<id> *> *items;

@property (nonatomic, strong, nullable) NSPredicate *predicate;

@property (nonatomic, readonly, copy, nullable) NSArray<NSArray<id> *> *filteredItems;

- (void)filterItems;

- (void)insertItem:(id)item atFilteredIndexPath:(NSIndexPath *)filteredIndexPath;

- (void)removeItemAtFilteredIndexPath:(NSIndexPath *)filteredIndexPath;
- (void)removeItem:(id)item inSection:(NSInteger)section;

- (void)moveItemAtFilteredIndexPath:(NSIndexPath *)sourceFilteredIndexPath toFilteredIndexPath:(NSIndexPath *)destinationFilteredIndexPath;

@end

NS_ASSUME_NONNULL_END
