//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextMarkupAnnotationOptions.h"

@implementation PTTextMarkupAnnotationOptions

#pragma mark - Equality

- (BOOL)isEqualToAnnotationOptions:(PTAnnotationOptions *)annotationOptions
{
    if (![super isEqualToAnnotationOptions:annotationOptions]) {
        return NO;
    }
    
    if (![annotationOptions isKindOfClass:[self class]]) {
        return NO;
    }
    
    PTTextMarkupAnnotationOptions *textMarkupAnnotationOptions = (PTTextMarkupAnnotationOptions *)annotationOptions;
    
    return (self.copiesAnnotatedTextToContents == textMarkupAnnotationOptions.copiesAnnotatedTextToContents);
}

#pragma mark - <NSObject>

- (NSUInteger)hash
{
    return ([super hash]) ^ ((NSUInteger)self.copiesAnnotatedTextToContents);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; canCreate: %@; canEdit: %@; rotationEnabled: %@>",
            [self class], self,
            PT_NSStringFromBOOL(self.canCreate), PT_NSStringFromBOOL(self.canEdit),
            PT_NSStringFromBOOL(self.copiesAnnotatedTextToContents)];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    PTTextMarkupAnnotationOptions *options = [super copyWithZone:zone];
    
    options.copiesAnnotatedTextToContents = self.copiesAnnotatedTextToContents;
    
    return options;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        BOOL copiesAnnotatedTextToContents = YES;
        if ([coder containsValueForKey:PT_KEY(self, copiesAnnotatedTextToContents)]) {
            copiesAnnotatedTextToContents = [coder decodeBoolForKey:PT_KEY(self, copiesAnnotatedTextToContents)];
        }
        
        _copiesAnnotatedTextToContents = copiesAnnotatedTextToContents;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeBool:self.copiesAnnotatedTextToContents forKey:PT_KEY(self, copiesAnnotatedTextToContents)];
}

@end
