//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBookmarkManager+PTCompatibility.h"

#import "PTBookmarkUtils.h"

@implementation PTBookmarkManager (PTCompatibility)

- (NSArray<PTUserBookmark *> *)legacyBookmarksForDocumentURL:(NSURL *)documentURL
{
    if (!documentURL) {
        return @[];
    }
    
    NSArray<NSDictionary<PTBookmarkInfoKey, id> *> *bookmarkData = [PTBookmarkUtils bookmarkDataForDocument:documentURL];
    
    NSMutableArray<PTUserBookmark *> *mutableUserBookmarks = [NSMutableArray arrayWithCapacity:bookmarkData.count];
    
    for (NSDictionary<PTBookmarkInfoKey, id> *bookmark in bookmarkData) {
        PTUserBookmark *userBookmark = [self userBookmarkFromLegacyBookmark:bookmark];
        [mutableUserBookmarks addObject:userBookmark];
    }
    
    return [mutableUserBookmarks copy];
}

- (void)saveLegacyBookmarks:(NSArray<PTUserBookmark *> *)bookmarks forDocumentURL:(NSURL *)documentURL
{
    NSMutableArray<NSDictionary<PTBookmarkInfoKey, id> *> *mutableBookmarkData = [NSMutableArray arrayWithCapacity:bookmarks.count];
    
    for (PTUserBookmark *userBookmark in bookmarks) {
        NSDictionary<PTBookmarkInfoKey, id> *legacyBookmark = [self legacyBookmarkFromUserBookmark:userBookmark];
        [mutableBookmarkData addObject:legacyBookmark];
    }
    
    NSArray<NSDictionary<PTBookmarkInfoKey, id> *> *bookmarkData = [mutableBookmarkData copy];
    
    [PTBookmarkUtils saveBookmarkData:bookmarkData forFileUrl:documentURL];
}

#pragma mark Conversion

- (PTUserBookmark *)userBookmarkFromLegacyBookmark:(NSDictionary<PTBookmarkInfoKey, id> *)dictionary
{
    int pageNumber = ((NSNumber *) dictionary[PTBookmarkInfoKeyPageNumber]).intValue;
    unsigned int sdfObjNumber = ((NSNumber *) dictionary[PTBookmarkInfoKeySDFObjNumber]).unsignedIntValue;
    NSString *name = (NSString *) dictionary[PTBookmarkInfoKeyName];
    // NOTE: UUID is ignored.
    
    return [[PTUserBookmark alloc] initWithTitle:name pageNumber:pageNumber pageObjNum:sdfObjNumber];
}

- (NSDictionary<PTBookmarkInfoKey, id> *)legacyBookmarkFromUserBookmark:(PTUserBookmark *)userBookmark
{
    return @{
             PTBookmarkInfoKeyPageNumber: @(userBookmark.pageNumber),
             PTBookmarkInfoKeySDFObjNumber: @(userBookmark.pageObjNum),
             PTBookmarkInfoKeyName: userBookmark.title,
             };
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTBookmarkManager, PTCompatibility)
