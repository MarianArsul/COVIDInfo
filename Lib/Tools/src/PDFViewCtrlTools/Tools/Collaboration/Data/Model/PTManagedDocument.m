//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTManagedDocument.h"

@implementation PTManagedDocument

// Attributes
@dynamic identifier;
@dynamic unreadCount;

// Relationships
@dynamic annotations;

#pragma mark - PTManagedObject

+ (NSString *)entityName
{
    return @"Document";
}

+ (instancetype)insertDocumentWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    PTManagedDocument *document = [self insertInManagedObjectContext:managedObjectContext];
    document.identifier = identifier;
    return document;
}

@end
