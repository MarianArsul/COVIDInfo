//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSignatureAnnotationOptions.h"

@implementation PTSignatureAnnotationOptions

- (instancetype)initWithCanCreate:(BOOL)canCreate canEdit:(BOOL)canEdit
{
    self = [super initWithCanCreate:canCreate canEdit:canEdit];
    if (self) {
        _canEditAppearance = NO;
        _signSignatureFieldsWithStamps = NO;
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAnnotationOptions:(PTAnnotationOptions *)annotationOptions
{
    if (![super isEqualToAnnotationOptions:annotationOptions]) {
        return NO;
    }
    
    if (![annotationOptions isKindOfClass:[PTSignatureAnnotationOptions class]]) {
        return NO;
    }
    
    PTSignatureAnnotationOptions *signatureAnnotationOptions = (PTSignatureAnnotationOptions *)annotationOptions;
    return (self.canEditAppearance == signatureAnnotationOptions.canEditAppearance &&
            self.signSignatureFieldsWithStamps == signatureAnnotationOptions.signSignatureFieldsWithStamps);
}

#pragma mark - <NSObject>

- (NSUInteger)hash
{
    return ([super hash]) ^ ((NSUInteger)self.canEditAppearance) ^ ((NSUInteger)self.signSignatureFieldsWithStamps);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; canCreate: %@; canEdit: %@; canEditAppearance: %@ ; signSignatureFieldsWithStamps: %@>",
            [self class], self,
            PT_NSStringFromBOOL(self.canCreate), PT_NSStringFromBOOL(self.canEdit),
            PT_NSStringFromBOOL(self.canEditAppearance), PT_NSStringFromBOOL(self.signSignatureFieldsWithStamps)];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    PTSignatureAnnotationOptions *options = [super copyWithZone:zone];
    
    options.canEditAppearance = self.canEditAppearance;
    options.signSignatureFieldsWithStamps = self.signSignatureFieldsWithStamps;
    
    return options;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        BOOL canEditAppearance = NO;
        BOOL signSignatureFieldsWithStamps = NO;
        if ([coder containsValueForKey:PT_KEY(self, canEditAppearance)]) {
            canEditAppearance = [coder decodeBoolForKey:PT_KEY(self, canEditAppearance)];
        }
        if ([coder containsValueForKey:PT_KEY(self, canEditAppearance)]) {
            signSignatureFieldsWithStamps = [coder decodeBoolForKey:PT_KEY(self, signSignatureFieldsWithStamps)];
        }
        
        _canEditAppearance = canEditAppearance;
        _signSignatureFieldsWithStamps = signSignatureFieldsWithStamps;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeBool:self.canEditAppearance forKey:PT_KEY(self, canEditAppearance)];
    [coder encodeBool:self.signSignatureFieldsWithStamps forKey:PT_KEY(self, signSignatureFieldsWithStamps)];
}

@end
