//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCoreDataManager.h"

@interface PTCoreDataManager ()

@property (nonatomic, class, readwrite, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic) BOOL persistentStoresLoaded;
@property (nonatomic) NSCondition *persistentStoresLoadedCondition;

// Redeclare as readwrite internally.
@property (nonatomic, readwrite, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readwrite, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *backgroundContext;

@end

@implementation PTCoreDataManager

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name completion:nil];
}

- (instancetype)initWithName:(NSString *)name completion:(void (^)(void))completion
{
    self = [super init];
    if (self) {
        _name = name;
        
        _persistentStoresLoaded = NO;
        _persistentStoresLoadedCondition = [[NSCondition alloc] init];
        
        [self loadWithCompletion:completion];
    }
    return self;
}

#pragma mark - Loading

- (void)loadWithCompletion:(void (^ _Nullable)(void))completion
{
    if (self.managedObjectModel) {
        return;
    }
    
    if (!PTCoreDataManager.managedObjectModel) {
        NSURL *modelURL = nil;
        // First check containing bundle for model, then main bundle.
        for (NSBundle *bundle in @[[NSBundle bundleForClass:[self class]], NSBundle.mainBundle]) {
            modelURL = [bundle URLForResource:self.name withExtension:@"momd"];
            if (modelURL) {
                break;
            }
        }
        NSAssert(modelURL, @"Failed to locate .momd bundle in application");
        
        NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSAssert(objectModel, @"Failed to initialize managed object model from URL: %@", modelURL);
        
        PTCoreDataManager.managedObjectModel = objectModel;
    }
    NSAssert(PTCoreDataManager.managedObjectModel, @"Failed to initialize object model");
    
    self.managedObjectModel = PTCoreDataManager.managedObjectModel;
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSAssert(coordinator, @"Failed to initialize persistent store coordinator");
    
    self.persistentStoreCoordinator = coordinator;
    
    // Create a new main queue context connected to the persistent store coordinator.
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainContext.name = @"Main context (main queue)";
    self.mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    self.mainContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    self.mainContext.automaticallyMergesChangesFromParent = YES;
    
    // Create a new background queue context as a child of the private context (private queue).
    self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.backgroundContext.name = @"Background context (private background queue)";
    self.backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    // In case of conflicts, the in-memory changes trump the persistent store changes.
    self.backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        
        NSString *storeName = [self.name stringByAppendingPathExtension:@"sqlite"];
        
        NSURL *applicationSupportURL = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
                                                                            inDomains:NSUserDomainMask].firstObject;
        
        // Create "Library/Application Support" directory (or ensure that it exists).
        BOOL applicationSupportExists = [NSFileManager.defaultManager createDirectoryAtURL:applicationSupportURL
                                                               withIntermediateDirectories:YES
                                                                                attributes:nil
                                                                                     error:nil];
        NSAssert(applicationSupportExists, @"The \"Library/Application Support\" directory does not exist");
        
        NSURL *storeURL = [applicationSupportURL URLByAppendingPathComponent:storeName];
        
        // Clear out previous store.
        NSError *destroyStoreError = nil;
        BOOL success = [coordinator destroyPersistentStoreAtURL:storeURL
                                                       withType:NSSQLiteStoreType
                                                        options:nil
                                                          error:&destroyStoreError];
        NSAssert(success, @"Failed to destroy previous store: %@", destroyStoreError);
        
        NSError *error = nil;
        NSPersistentStore *store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                             configuration:nil
                                                                       URL:storeURL
                                                                   options:nil
                                                                     error:&error];
        NSAssert(store, @"Failed to add SQLite persistent store: %@", error);
        
        PTLog(@"Persistent store added: %@", storeURL.path);
        
        [self.persistentStoresLoadedCondition lock];
        self.persistentStoresLoaded = YES;
        [self.persistentStoresLoadedCondition broadcast];
        [self.persistentStoresLoadedCondition unlock];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    });
}

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext * _Nonnull))block
{
    NSManagedObjectContext *backgroundContext = self.backgroundContext;
    
    [backgroundContext performBlock:^{
        
        [self.persistentStoresLoadedCondition lock];
        while (!self.persistentStoresLoaded) {
            [self.persistentStoresLoadedCondition wait];
        }
        [self.persistentStoresLoadedCondition unlock];
        
        if (block) {
            block(backgroundContext);
        }
    }];
}

#pragma mark - Model

static NSManagedObjectModel * _Nullable PTCoreDataManager_managedObjectModel;

+ (NSManagedObjectModel *)managedObjectModel
{
    return PTCoreDataManager_managedObjectModel;
}

+ (void)setManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    PTCoreDataManager_managedObjectModel = managedObjectModel;
}

@end
