//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTManagedUser.h"

@implementation PTManagedUser (PTFetching)

+ (instancetype)fetchUserWithIdentifier:(NSString *)identifier context:(NSManagedObjectContext *)context
{
    // Fetch the user with a matching identifier.
    NSFetchRequest<PTManagedUser *> *request = [PTManagedUser fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@",
                         PT_CLASS_KEY(PTManagedUser, identifier), identifier];
    
    NSError *fetchError = nil;
    NSArray<PTManagedUser *> *results = [context executeFetchRequest:request
                                                               error:&fetchError];
    if (!results) {
        NSLog(@"Failed to fetch user for identifier \"%@\": %@", identifier, fetchError);
        return nil;
    }
    
    NSAssert(results.count <= 1,
             @"Expected at most one fetch result for user with identifier \"%@\": found %lu results",
             identifier, (unsigned long)results.count);
    
    return results.firstObject;
}

@end
