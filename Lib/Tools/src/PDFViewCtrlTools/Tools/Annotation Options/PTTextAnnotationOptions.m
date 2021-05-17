//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextAnnotationOptions.h"

@implementation PTTextAnnotationOptions

- (instancetype)initWithCanCreate:(BOOL)canCreate canEdit:(BOOL)canEdit
{
    self = [super initWithCanCreate:canCreate canEdit:canEdit];
    if (self) {
        _opensPopupOnTap = YES;
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAnnotationOptions:(PTAnnotationOptions *)annotationOptions
{
    if (![super isEqualToAnnotationOptions:annotationOptions]) {
        return NO;
    }
    
    if (![annotationOptions isKindOfClass:[PTTextAnnotationOptions class]]) {
        return NO;
    }
    
    PTTextAnnotationOptions *textAnnotationOptions = (PTTextAnnotationOptions *)annotationOptions;
    return (self.opensPopupOnTap == textAnnotationOptions.opensPopupOnTap);
}

#pragma mark - <NSObject>

- (NSUInteger)hash
{
    return ([super hash]) ^ ((NSUInteger)self.opensPopupOnTap);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; canCreate: %@; canEdit: %@; opensPopupOnTap: %@>",
            [self class], self,
            PT_NSStringFromBOOL(self.canCreate), PT_NSStringFromBOOL(self.canEdit),
            PT_NSStringFromBOOL(self.opensPopupOnTap)];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    PTTextAnnotationOptions *options = [super copyWithZone:zone];
    
    options.opensPopupOnTap = self.opensPopupOnTap;
    
    return options;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        BOOL opensPopupOnTap = YES;
        if ([coder containsValueForKey:PT_KEY(self, opensPopupOnTap)]) {
            opensPopupOnTap = [coder decodeBoolForKey:PT_KEY(self, opensPopupOnTap)];
        }
        
        _opensPopupOnTap = opensPopupOnTap;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeBool:self.opensPopupOnTap forKey:PT_KEY(self, opensPopupOnTap)];
}


@end
