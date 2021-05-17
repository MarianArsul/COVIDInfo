//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBookmarkUtils.h"

@implementation PTBookmarkUtils

const PTBookmarkInfoKey PTBookmarkInfoKeyPageNumber = @"page-number";
const PTBookmarkInfoKey PTBookmarkInfoKeySDFObjNumber = @"sdf-obj-number";
const PTBookmarkInfoKey PTBookmarkInfoKeyName = @"name";
const PTBookmarkInfoKey PTBookmarkInfoKeyUniqueId = @"unique-id";

+ (NSString *)bookmarkFileNameFromFileURL:(NSURL *)documentUrl
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray<NSURL *> *paths = [manager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
	
	NSURL *libraryDirectory = paths[0];
    
    NSString* docName = libraryDirectory.path.stringByDeletingLastPathComponent;
    
    @try
    {
        docName = [documentUrl.path substringFromIndex:docName.length];
    }
    @catch (NSException *exception)
    {

        
        docName = documentUrl.lastPathComponent;
    }
    
    docName = [docName stringByReplacingOccurrencesOfString:@"/" withString:@""];
	
	NSString* libraryName = [libraryDirectory.path stringByAppendingPathComponent:docName];
	return libraryName;
}


+(void)fileMovedFrom:(NSURL*)oldLocation to:(NSURL*)newLocation
{
	NSString* oldBookmarkFile = [self bookmarkFileNameFromFileURL:oldLocation];
    if (oldBookmarkFile.length == 0) {
        PTLog(@"Failed to get old bookmark file for URL \"%@\"", oldLocation);
        return;
    }
    
    // Check if old bookmark file exists.
    if (![[NSFileManager defaultManager] fileExistsAtPath:oldBookmarkFile]) {
        PTLog(@"File does not exist for old bookmark file \"%@\"", oldBookmarkFile);
        return;
    }
    
    NSString* newBookmarkFile = [self bookmarkFileNameFromFileURL:newLocation];
    if (newBookmarkFile.length == 0) {
        PTLog(@"Failed to get new bookmark file for URL \"%@\"", newLocation);
        return;
    }
    
    NSError *error = nil;
    
    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:oldBookmarkFile toPath:newBookmarkFile error:&error];
    if (!success) {
        PTLog(@"Failed to move bookmark file from \"%@\" to \"%@\": %@", oldBookmarkFile, newBookmarkFile, error);
    }
}


+(void)saveBookmarkData:(NSArray*)bookmarkData forFileUrl:(NSURL*)documentUrl
{
	NSError* error;
	
	NSMutableArray* propertyList;
 
    if (!bookmarkData) {
		propertyList = [NSMutableArray array];
    } else {
		propertyList = [NSMutableArray arrayWithArray:bookmarkData];
    }
    
	// bookmark file is an array of dictionaries
	// dictionary key value pairs are
	// @"page-number" : NSNumber numberWithInt
	// @"sdf-obj-number" : NSNumber numberWithInt
	// @"name" : NSString
	// @"unqiue-id" : NSString (a UUID string)
	
	NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:propertyList
																   format:NSPropertyListBinaryFormat_v1_0
																  options:0
																	error:&error];
	
    if (!plistData) {
		PTLog(@"Couldn't generate bookmark data: %@", error);
        return;
    }

	NSString* libraryName = [self bookmarkFileNameFromFileURL:documentUrl];
    if (libraryName.length == 0) {
        PTLog(@"Failed to get bookmark save location for URL \"%@\"", documentUrl);
        return;
    }
	
	BOOL success = [plistData writeToFile:libraryName options:0 error:&error];
    if (!success) {
        PTLog(@"Failed to save bookmark data to \"%@\" for URL \"%@\": %@", libraryName, documentUrl, error);
    }
}

+(NSArray<NSMutableDictionary*>*)bookmarkDataForDocument:(NSURL*)documentUrl
{
	NSString *libraryName = [self bookmarkFileNameFromFileURL:documentUrl];

	NSData* data = [NSData dataWithContentsOfFile:libraryName];
	
	if( !data.length )
	{
		return @[];
	}
	
	NSError* error;
	
	NSMutableArray<NSMutableDictionary *> *plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:&error];
    
	return [NSArray arrayWithArray:plist];
}


+(NSMutableArray<NSMutableDictionary*>*)updateUserBookmarks:(NSMutableArray<NSMutableDictionary*>*)bookmarks oldPageNumber:(unsigned int)oldPageNumber newPageNumber:(unsigned int)newPageNumber oldSDFNumber:(unsigned int)oldSDFNumber newSDFNumber:(unsigned int)newSDFNumber
{
	if( newPageNumber != oldPageNumber )
	{
		unsigned int updateStartingAtPageNumber = MIN(oldPageNumber, newPageNumber);
		unsigned int updateEndingAtPageNumber = MAX(oldPageNumber, newPageNumber);
		
		int change = 0;
		
		if( newPageNumber > oldPageNumber )
		{
			change = -1;
		}
		else
		{
			change = 1;
		}
		
		// assumes bookmarks is sorted by page number
		for (NSMutableDictionary* bookmarkDict in bookmarks) {
			
			unsigned int orgPageNum = [bookmarkDict[@"page-number"] intValue];
			
			if( orgPageNum >= updateStartingAtPageNumber && orgPageNum <= updateEndingAtPageNumber )
			{
				if(orgPageNum == oldPageNumber)
				{
					bookmarkDict[@"page-number"] = [NSNumber numberWithInt:newPageNumber];
					
					//might need SDF obj updated
					if( [bookmarkDict[@"obj-number"] unsignedIntValue] == oldSDFNumber)
					{
						bookmarkDict[@"obj-number"] = @(newSDFNumber);
					}
				}
				else
				{
					bookmarkDict[@"page-number"] = @((unsigned int)((int)[bookmarkDict[@"page-number"] unsignedIntValue] + change));
				}
			}
		}
	}
	
	return bookmarks;

}

+(void)deleteBookmarkDataForDocument:(NSURL *)documentURL
{
    NSString* bookmarkFile = [self bookmarkFileNameFromFileURL:documentURL];
    if (bookmarkFile.length == 0) {
        PTLog(@"Failed to get bookmark file for URL \"%@\"", documentURL);
        return;
    }
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:bookmarkFile error:&error];
    if (!success && [[NSFileManager defaultManager] fileExistsAtPath:bookmarkFile]) {
        PTLog(@"Failed to remove bookmark file from \"%@\": %@", bookmarkFile, error);
    }
}

@end
