//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentViewSettingsManager.h"

#import "PTAutoCoding.h"

#define MAX_DOCUMENT_INFO_COUNT 50

@interface PTDocumentInfo : NSObject <NSCoding>

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, nullable) NSData *bookmarkData;

@property (nonatomic, assign) int lastReadPageNumber;

@property (nonatomic, strong, nullable) PTDocumentViewSettings *viewSettings;

@end

@implementation PTDocumentInfo

- (void)PTDocumentInfo_commonInit
{
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self PTDocumentInfo_commonInit];
    }
    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        [self PTDocumentInfo_commonInit];
        
        [PTAutoCoding autoUnarchiveObject:self withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [PTAutoCoding autoArchiveObject:self withCoder:coder];
}

@end

@implementation PTDocumentViewSettingsManager

static PTDocumentViewSettingsManager *PTDocumentViewSettingsManager_sharedManager;

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PTDocumentViewSettingsManager_sharedManager = [[self alloc] init];
    });
    
    NSAssert(PTDocumentViewSettingsManager_sharedManager != nil,
             @"Failed to create %@ for %@", NSStringFromClass(self), NSStringFromSelector(_cmd));
    
    return PTDocumentViewSettingsManager_sharedManager;
}

#pragma mark - User defaults

- (NSArray<PTDocumentInfo *> *)settingsUserDefaults
{
    NSArray<PTDocumentInfo *> *settings = nil;
    
    NSArray *array = [NSUserDefaults.standardUserDefaults arrayForKey:@"documentViewSettings"];
    if (!array) {
        settings = @[];
    } else {
        NSMutableArray<PTDocumentInfo *> *list = [NSMutableArray arrayWithCapacity:array.count];
        for (id value in array) {
            if (![value isKindOfClass:[NSData class]]) {
                continue;
            }
            NSData *data = (NSData *)value;
            [list addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        }
        settings = [list copy];
    }
    
    return settings;
}

- (void)saveDocumentInfoList:(NSArray<PTDocumentInfo *> *)list
{
    NSMutableArray<NSData *> *archivedData = [NSMutableArray arrayWithCapacity:list.count];
    for (PTDocumentInfo *info in list) {
        [archivedData addObject:[NSKeyedArchiver archivedDataWithRootObject:info]];
    }
    [NSUserDefaults.standardUserDefaults setObject:archivedData forKey:@"documentViewSettings"];
}

#pragma mark - Finding document info

- (PTDocumentInfo *)findDocumentInfoForURL:(NSURL *)url
{
    return [self findDocumentInfoForURL:url withStoredInfo:[self settingsUserDefaults]];
}

- (PTDocumentInfo *)findDocumentInfoForURL:(NSURL *)url withStoredInfo:(NSArray<PTDocumentInfo *> *)storedInfo
{
    for (PTDocumentInfo *info in storedInfo) {
        if (!info.bookmarkData) {
            continue;
        }
        
        NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:info.bookmarkData
                                                       options:NSURLBookmarkResolutionWithoutUI
                                                 relativeToURL:nil
                                           bookmarkDataIsStale:nil
                                                         error:nil];
        if (!resolvedURL) {
            continue;
        }
        
        if ([url isEqual:resolvedURL]) {
            return info;
        }
    }
    
    return nil;
}

- (int)lastReadPageNumberForDocumentAtURL:(NSURL *)url
{
    NSParameterAssert(url != nil);
    
    PTDocumentInfo *info = [self findDocumentInfoForURL:url];
    if (info) {
        return info.lastReadPageNumber;
    }
    
    return 1;
}

- (void)setLastReadPageNumber:(int)lastReadPageNumber forDocumentAtURL:(NSURL *)url
{
    NSArray<PTDocumentInfo *> *storedInfo = [self settingsUserDefaults];
    
    PTDocumentInfo *info = [self findDocumentInfoForURL:url withStoredInfo:storedInfo];
    if (!info) {
        info = [[PTDocumentInfo alloc] init];
        info.bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                          includingResourceValuesForKeys:nil
                                           relativeToURL:nil
                                                   error:nil];
        
        NSMutableArray<PTDocumentInfo *> *mutableList = [storedInfo mutableCopy];
        [mutableList insertObject:info atIndex:0];
        if (mutableList.count > MAX_DOCUMENT_INFO_COUNT) {
            [mutableList removeLastObject];
        }
        storedInfo = [mutableList copy];
    }
    
    info.lastReadPageNumber = lastReadPageNumber;
    
    [self saveDocumentInfoList:storedInfo];
}

#pragma mark - Settings

- (PTDocumentViewSettings *)viewSettingsForDocumentAtURL:(NSURL *)url
{
    NSParameterAssert(url != nil);
    
    PTDocumentInfo *info = [self findDocumentInfoForURL:url];
    return info.viewSettings;
}

- (void)setViewSettings:(PTDocumentViewSettings *)settings forDocumentAtURL:(NSURL *)url
{
    NSArray<PTDocumentInfo *> *storedInfo = [self settingsUserDefaults];
    
    PTDocumentInfo *info = [self findDocumentInfoForURL:url withStoredInfo:storedInfo];
    if (!info) {
        info = [[PTDocumentInfo alloc] init];
        info.bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                          includingResourceValuesForKeys:nil
                                           relativeToURL:nil
                                                   error:nil];
        
        NSMutableArray<PTDocumentInfo *> *mutableList = [storedInfo mutableCopy];
        [mutableList insertObject:info atIndex:0];
        if (mutableList.count > MAX_DOCUMENT_INFO_COUNT) {
            [mutableList removeLastObject];
        }
        storedInfo = [mutableList copy];
    }
    
    info.viewSettings = settings;
    
    [self saveDocumentInfoList:storedInfo];
    
    // Update the default view settings.
    [self setDefaultViewSettings:settings];
}

#pragma mark - Default settings

- (PTDocumentViewSettings *)defaultViewSettings
{
    PTDocumentViewSettings *settings = nil;
    
    id value = [NSUserDefaults.standardUserDefaults objectForKey:@"defaultDocumentViewSettings"];
    if (value && [value isKindOfClass:[NSData class]]) {
        NSData *archivedData = (NSData *)value;
        settings = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
    }
    else {
        settings = [[PTDocumentViewSettings alloc] init];
    }

    return settings;
}

- (void)setDefaultViewSettings:(PTDocumentViewSettings *)defaultViewSettings
{
    NSParameterAssert(defaultViewSettings != nil);
    
    PTDocumentViewSettings *settingsCopy = [defaultViewSettings copy];
    
    settingsCopy.reflowEnabled = NO;
    settingsCopy.pageRotation = e_pt0;
    
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:settingsCopy];
    
    [NSUserDefaults.standardUserDefaults setObject:archivedData
                                            forKey:@"defaultDocumentViewSettings"];
}

@end
