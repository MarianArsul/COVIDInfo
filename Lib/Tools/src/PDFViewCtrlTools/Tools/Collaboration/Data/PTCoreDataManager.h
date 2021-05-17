//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTCoreDataManager : NSObject

@property (nonatomic, readonly, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name completion:(void (^ _Nullable)(void))completion NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;

@property (nonatomic, readonly, strong) NSManagedObjectContext *backgroundContext;

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext *context))block;

@end

NS_ASSUME_NONNULL_END
