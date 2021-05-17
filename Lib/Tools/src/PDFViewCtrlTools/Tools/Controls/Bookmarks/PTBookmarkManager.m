//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBookmarkManager.h"

static NSString * const PT_BookmarkManagerUserBookmarkObjTitle = @"pdftronUserBookmarks";

static PTBookmarkManager *PTBookmarkManager_defaultManager;

@implementation PTBookmarkManager

+ (PTBookmarkManager *)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PTBookmarkManager_defaultManager = [[PTBookmarkManager alloc] init];
    });
    
    return PTBookmarkManager_defaultManager;
}

- (PTBookmark *)rootPDFBookmarkForDoc:(PTPDFDoc *)doc create:(BOOL)create
{
    PTBookmark *bookmark = nil;
    
    BOOL shouldUnlock = NO;
    @try {
        [doc LockRead];
        shouldUnlock = YES;
        
        PTObj *catalog = [doc GetRoot];
        if (![catalog IsValid]) {
            return nil;
        }
        
        PTObj *bookmarkObj = [catalog FindObj:PT_BookmarkManagerUserBookmarkObjTitle];
        if ([bookmarkObj IsValid]) {
            // Found existing bookmark obj.
            bookmark = [[PTBookmark alloc] initWithIn_bookmark_dict:bookmarkObj];
        } else if (create) {
            // Create new bookmark obj.
            bookmark = [PTBookmark Create:doc in_title:PT_BookmarkManagerUserBookmarkObjTitle];
            [catalog Put:PT_BookmarkManagerUserBookmarkObjTitle obj:[bookmark GetSDFObj]];
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
        bookmark = nil;
    } @finally {
        if (shouldUnlock) {
            [doc UnlockRead];
        }
    }
    
    return bookmark;
}

- (BOOL)removeRootPDFBookmarkForDoc:(PTPDFDoc *)doc
{
    if (!doc) {
        return NO;
    }
    
    BOOL shouldUnlock = NO;
    @try {
        [doc Lock];
        shouldUnlock = YES;
        
        PTObj *catalog = [doc GetRoot];
        if (![catalog IsValid]) {
            return NO;
        }
        
        [catalog EraseDictElementWithKey:PT_BookmarkManagerUserBookmarkObjTitle];
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
        return NO;
    } @finally {
        if (shouldUnlock) {
            [doc Unlock];
        }
    }
    
    return YES;
}

- (NSArray<PTUserBookmark *> *)bookmarksForDoc:(PTPDFDoc *)doc
{
    return [self bookmarksForDoc:doc rootPDFBookmark:[self rootPDFBookmarkForDoc:doc create:NO]];
}

- (NSArray<PTUserBookmark *> *)bookmarksForDoc:(PTPDFDoc *)doc rootPDFBookmark:(PTBookmark *)rootPDFBookmark
{
    if (!doc) {
        return @[];
    }
    
    if (!rootPDFBookmark) {
        return @[];
    }
    
    NSMutableArray<PTUserBookmark *> *bookmarks = [NSMutableArray array];
    
    BOOL shouldUnlock = NO;
    @try {
        [doc LockRead];
        shouldUnlock = YES;
        
        if (![rootPDFBookmark HasChildren]) {
            return @[];
        }
        
        for (PTBookmark *bookmark = [rootPDFBookmark GetFirstChild]; [bookmark IsValid]; bookmark = [bookmark GetNext]) {
            PTAction *action = [bookmark GetAction];
            if (![action IsValid] || [action GetType] != e_ptGoTo) {
                continue;
            }
            
            PTDestination *dest = [action GetDest];
            if (![dest IsValid]) {
                continue;
            }
            
            PTUserBookmark *userBookmark = [[PTUserBookmark alloc] initWithPDFBookmark:bookmark];
            [bookmarks addObject:userBookmark];
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [doc UnlockRead];
        }
    }
    
    return [bookmarks copy];
}

- (void)saveBookmarks:(NSArray<PTUserBookmark *> *)bookmarks forDoc:(PTPDFDoc *)doc
{
    if (!doc) {
        return;
    }
    
    if (bookmarks.count < 1) {
        [self removeRootPDFBookmarkForDoc:doc];
        return;
    }
    
    BOOL shouldUnlock = NO;
    @try {
        [doc Lock];
        shouldUnlock = YES;
        
        PTBookmark *rootBookmark = [self rootPDFBookmarkForDoc:doc create:YES];
        if (!rootBookmark) {
            PTLog(@"Failed to save user bookmarks: no root bookmark");
            return;
        }
        
        PTBookmark *firstBookmark = nil;
        PTBookmark *currentBookmark = nil;
        
        if ([rootBookmark HasChildren]) {
            firstBookmark = [rootBookmark GetFirstChild];
        }
        
        for (PTUserBookmark *userBookmark in bookmarks) {
            if (userBookmark.bookmark) {
                [self commitUserBookmark:userBookmark forDoc:doc];
                currentBookmark = userBookmark.bookmark;
            } else {
                if (!currentBookmark) {
                    // No items in the list above this are currently in the document.
                    if (!firstBookmark) {
                        // This means there are no bookmarks at all, so create one.
                        currentBookmark = [rootBookmark AddChildWithTitle:userBookmark.title];
                        [currentBookmark SetAction:[PTAction CreateGoto:[PTDestination CreateFit:[doc GetPage:userBookmark.pageNumber]]]];
                        firstBookmark = currentBookmark;
                    } else {
                        // There already are bookmarks, so the new bookmark needs to be inserted
                        // infront of the first one.
                        currentBookmark = [firstBookmark AddPrevWithTitle:userBookmark.title];
                        [currentBookmark SetAction:[PTAction CreateGoto:[PTDestination CreateFit:[doc GetPage:userBookmark.pageNumber]]]];
                        firstBookmark = currentBookmark;
                    }
                } else {
                    // At least one item in the list above the current item was in the list.
                    currentBookmark = [currentBookmark AddNextWithTitle:userBookmark.title];
                    [currentBookmark SetAction:[PTAction CreateGoto:[PTDestination CreateFit:[doc GetPage:userBookmark.pageNumber]]]];
                }
                userBookmark.bookmark = currentBookmark;
            }
        }
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [doc Unlock];
        }
    }
}

- (void)commitUserBookmark:(PTUserBookmark *)userBookmark forDoc:(PTPDFDoc *)doc
{
    NSParameterAssert(doc != nil);
    
    if (!userBookmark.bookmark || ![userBookmark isEdited]) {
        return;
    }
    
    PTAction *action = [userBookmark.bookmark GetAction];
    PTDestination *dest = [action GetDest];
    [dest SetPage:[doc GetPage:userBookmark.pageNumber]];
    [userBookmark.bookmark SetTitle:userBookmark.title];

    userBookmark.edited = NO;
}

- (void)addBookmark:(PTUserBookmark *)bookmark forDoc:(PTPDFDoc *)doc
{
    if (!doc) {
        return;
    }
    
    PTBookmark *rootPDFBookmark = [self rootPDFBookmarkForDoc:doc create:YES];
    NSArray<PTUserBookmark *> *bookmarks = [self bookmarksForDoc:doc rootPDFBookmark:rootPDFBookmark];
    bookmarks = [bookmarks arrayByAddingObject:bookmark];

    [self saveBookmarks:bookmarks forDoc:doc];
}

- (void)updateBookmarksForDoc:(PTPDFDoc *)doc pageDeletedWithPageObjNum:(unsigned int)pageObjNum
{
    if (!doc) {
        return;
    }
    
    NSArray<PTUserBookmark *> *bookmarks = [self bookmarksForDoc:doc rootPDFBookmark:[self rootPDFBookmarkForDoc:doc create:NO]];
    
    BOOL shouldUnlock = NO;
    @try {
        [doc Lock];
        shouldUnlock = YES;
        
        for (PTUserBookmark *bookmark in bookmarks) {
            if (bookmark.pageObjNum == pageObjNum) {
                [bookmark.bookmark Delete];
            }
        }
    } @catch (NSException *exception) {
        
    } @finally {
        if (shouldUnlock) {
            [doc Unlock];
        }
    }
}

- (void)updateBookmarksForDoc:(PTPDFDoc *)doc pageMovedFromPageNumber:(int)oldPageNumber pageObjNum:(unsigned int)oldPageObjNum toPageNumber:(int)newPageNumber pageObjNum:(unsigned int)newPageObjNum
{
    if (!doc) {
        return;
    }
    
    NSArray<PTUserBookmark *> *bookmarks = [self bookmarksForDoc:doc rootPDFBookmark:[self rootPDFBookmarkForDoc:doc create:NO]];
    
    BOOL shouldUnlock = NO;
    @try {
        [doc Lock];
        shouldUnlock = YES;
        
        for (PTUserBookmark *bookmark in bookmarks) {
            if (bookmark.pageObjNum != oldPageObjNum) {
                continue;
            }
            
            bookmark.pageObjNum = newPageObjNum;
            bookmark.pageNumber = newPageNumber;
            [bookmark.bookmark Delete];
            bookmark.bookmark = nil;
        }
        
        [self saveBookmarks:bookmarks forDoc:doc];
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [doc Unlock];
        }
    }
}

- (NSArray<PTUserBookmark *> *)bookmarksFromJSONString:(NSString *)jsonString
{
    NSError *error = nil;
    id jsonValue = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                   options:0
                                                     error:&error];
    if (!jsonValue) {
        NSLog(@"Failed to read bookmarks from JSON: %@", error);
        return nil;
    }
    
    NSMutableArray<PTUserBookmark *> *bookmarks = [NSMutableArray array];
    
    if ([jsonValue isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDictionary = (NSDictionary *)jsonValue;
        for (id key in jsonDictionary) {
            if ([key isKindOfClass:[NSString class]]) {
                NSString *keyString = (NSString *)key;
                
                // Scan int from the (string) key.
                int pageNumber = -1;
                NSScanner *scanner = [NSScanner scannerWithString:keyString];
                if (![scanner scanInt:&pageNumber]) {
                    NSLog(@"Failed to parse bookmark page number from \"%@\"", keyString);
                    continue;
                }
                
                NSString *title = nil;
                id value = jsonDictionary[key];
                if ([value isKindOfClass:[NSString class]]) {
                    title = (NSString *)value;
                }
                
                PTUserBookmark *bookmark = [[PTUserBookmark alloc] initWithTitle:title
                                                                      pageNumber:(pageNumber + 1)]; // 0-indexed
                [bookmarks addObject:bookmark];
            }
        }
    }
    
    return [bookmarks copy];
}

- (NSString *)JSONStringFromBookmarks:(NSArray<PTUserBookmark *> *)bookmarks
{
    NSMutableDictionary<NSString *, NSString *> *jsonDictionary = [NSMutableDictionary dictionary];
    
    for (PTUserBookmark *bookmark in bookmarks) {
        int jsonPageNumber = bookmark.pageNumber - 1; // JSON format is zero-indexed
        
        NSAssert(jsonPageNumber >= 0,
                 @"JSON bookmark page number must be positive: %d", jsonPageNumber);
        
        NSString *jsonKey = @(jsonPageNumber).stringValue;

        jsonDictionary[jsonKey] = (bookmark.title ?: @"");
    }
    
    if (![NSJSONSerialization isValidJSONObject:jsonDictionary]) {
        NSLog(@"Failed to export bookmarks to JSON: %@",
              [NSString stringWithFormat:@"JSON object is invalid:\n%@", jsonDictionary]);
        return nil;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Failed to export bookmarks to JSON: %@", error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData
                                 encoding:NSUTF8StringEncoding];
}

- (void)importBookmarksForDoc:(PTPDFDoc *)doc fromJSONString:(NSString *)jsonString
{
    NSArray<PTUserBookmark *> *bookmarks = [self bookmarksFromJSONString:jsonString];
    [self saveBookmarks:bookmarks forDoc:doc];
}

- (NSString *)exportBookmarksFromDoc:(PTPDFDoc *)doc
{
    NSArray<PTUserBookmark *> *bookmarks = [self bookmarksForDoc:doc];
    return [self JSONStringFromBookmarks:bookmarks];
}

@end
