//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationOptions.h"

@implementation PTAnnotationOptions

+ (instancetype)options
{
    return [[self alloc] init];
}

- (instancetype)init
{
    return [self initWithCanCreate:YES canEdit:YES];
}

- (instancetype)initWithCanCreate:(BOOL)canCreate canEdit:(BOOL)canEdit
{
    self = [super init];
    if (self) {
        _canCreate = canCreate;
        _canEdit = canEdit;
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAnnotationOptions:(PTAnnotationOptions *)annotationOptions
{
    BOOL canCreateEqual = (self.canCreate == annotationOptions.canCreate);
    BOOL canEditEqual = (self.canEdit == annotationOptions.canEdit);
    
    return (canCreateEqual && canEditEqual);
}

#pragma mark - <NSObject>

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [self isEqualToAnnotationOptions:(PTAnnotationOptions *)object];
}

- (NSUInteger)hash
{
    return ((NSUInteger)self.canCreate) ^ ((NSUInteger)self.canEdit);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; canCreate: %@; canEdit: %@>",
            [self class], self,
            PT_NSStringFromBOOL(self.canCreate), PT_NSStringFromBOOL(self.canEdit)];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithCanCreate:self.canCreate canEdit:self.canEdit];
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        BOOL canCreate = YES;
        if ([coder containsValueForKey:PT_KEY(self, canCreate)]) {
            canCreate = [coder decodeBoolForKey:PT_KEY(self, canCreate)];
        }
        
        BOOL canEdit = YES;
        if ([coder containsValueForKey:PT_KEY(self, canEdit)]) {
            canEdit = [coder decodeBoolForKey:PT_KEY(self, canEdit)];
        }
        
        _canCreate = canCreate;
        _canEdit = canEdit;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.canCreate forKey:PT_KEY(self, canCreate)];
    [coder encodeBool:self.canEdit forKey:PT_KEY(self, canEdit)];
}

@end
