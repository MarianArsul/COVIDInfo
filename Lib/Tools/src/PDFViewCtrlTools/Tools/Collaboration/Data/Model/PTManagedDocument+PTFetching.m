//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTManagedDocument.h"

@implementation PTManagedDocument (PTFetching)

- (PTManagedAnnotation *)fetchAnnotationWithIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier.length > 0);
    
    NSFetchRequest *request = [PTManagedAnnotation fetchRequest];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                         @[
                           // Belongs to current document...
                           [NSPredicate predicateWithFormat:@"%K == %@",
                            PT_CLASS_KEY(PTManagedAnnotation, document), self],
                           // with matching (annotation) identifier.
                           [NSPredicate predicateWithFormat:@"%K == %@",
                            PT_CLASS_KEY(PTManagedAnnotation, identifier), identifier],
                           ]];
    
    NSError *fetchError = nil;
    NSArray<PTManagedAnnotation *> *results = [self.managedObjectContext executeFetchRequest:request
                                                                                       error:&fetchError];
    if (!results) {
        NSLog(@"Failed to fetch annotation: %@", fetchError);
        return nil;
    }
    
    PTManagedAnnotation *annotation = results.firstObject;
    return annotation;
}

@end
