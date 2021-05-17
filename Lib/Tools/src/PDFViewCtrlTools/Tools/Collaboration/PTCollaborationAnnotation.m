//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationAnnotation.h"

@implementation PTCollaborationAnnotation

#pragma mark - Validation

- (BOOL)isValidForAdd
{
    return (self.annotationID.length > 0
            && self.userID.length > 0
            && self.xfdf.length > 0);
}

- (BOOL)isValidForModify
{
    return (self.annotationID.length > 0 &&
            self.xfdf.length > 0);
}

- (BOOL)isValidForRemove
{
    return (self.annotationID.length > 0);
}

#pragma mark - NSObject

#define PROP_ENTRY(object, property) PT_KEY(object, property) : (object).property ?: [NSNull null]

- (NSString *)description
{
    NSDictionary<NSString *, id> *propertyDict =
    @{
      PROP_ENTRY(self, annotationID),
      PROP_ENTRY(self, userID),
      PROP_ENTRY(self, userName),
      PROP_ENTRY(self, xfdf),
      PROP_ENTRY(self, parent),
      PROP_ENTRY(self, documentID),
      };
    
    NSMutableString *mutablePropertyString = [NSMutableString string];
    [propertyDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        [mutablePropertyString appendFormat:@"; %@: %@", key, value];
    }];
    NSString *propertyString = [mutablePropertyString copy];
    
    return [NSString stringWithFormat:@"<%@: %p%@>", [self class], self, propertyString];
}

#undef PROP_ENTRY

@end
