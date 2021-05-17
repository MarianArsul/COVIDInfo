//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTManagedUser.h"

@implementation PTManagedUser

@dynamic identifier;
@dynamic name;

@dynamic annotations;

+ (NSString *)entityName
{
    return @"User";
}

+ (instancetype)insertUserWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    PTManagedUser *user = [self insertInManagedObjectContext:managedObjectContext];
    user.identifier = identifier;
    return user;
}

@end
