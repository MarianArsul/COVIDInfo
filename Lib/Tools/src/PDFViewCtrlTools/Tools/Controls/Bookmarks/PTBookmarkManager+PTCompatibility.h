//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"
#import "PTBookmarkManager.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTBookmarkManager (PTCompatibility)

- (NSArray<PTUserBookmark *> *)legacyBookmarksForDocumentURL:(NSURL *)documentURL;

- (void)saveLegacyBookmarks:(NSArray<PTUserBookmark *> *)bookmarks forDocumentURL:(NSURL *)documentURL;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTBookmarkManager, PTCompatibility)
PT_IMPORT_CATEGORY(PTBookmarkManager, PTCompatibility)
