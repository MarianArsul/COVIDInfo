//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTImageStampAnnotationOptions.h"

@implementation PTImageStampAnnotationOptions

- (instancetype)initWithCanCreate:(BOOL)canCreate canEdit:(BOOL)canEdit
{
    self = [super initWithCanCreate:canCreate canEdit:canEdit];
    if (self) {
        _rotationEnabled = YES;
        _cropEnabled = YES;
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAnnotationOptions:(PTAnnotationOptions *)annotationOptions
{
    if (![super isEqualToAnnotationOptions:annotationOptions]) {
        return NO;
    }
    
    if (![annotationOptions isKindOfClass:[PTImageStampAnnotationOptions class]]) {
        return NO;
    }
    
    PTImageStampAnnotationOptions *imageStampAnnotationOptions = (PTImageStampAnnotationOptions *)annotationOptions;
    BOOL rotationEnabledEqual = (self.rotationEnabled == imageStampAnnotationOptions.rotationEnabled);
    BOOL cropEnabledEqual = (self.cropEnabled == imageStampAnnotationOptions.cropEnabled);
    
    return (rotationEnabledEqual && cropEnabledEqual);
}

#pragma mark - <NSObject>

- (NSUInteger)hash
{
    return ([super hash]) ^ ((NSUInteger)self.rotationEnabled) ^ ((NSUInteger)self.cropEnabled);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; canCreate: %@; canEdit: %@; rotationEnabled: %@; cropEnabled: %@>",
            [self class], self,
            PT_NSStringFromBOOL(self.canCreate), PT_NSStringFromBOOL(self.canEdit),
            PT_NSStringFromBOOL(self.rotationEnabled), PT_NSStringFromBOOL(self.cropEnabled)];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    PTImageStampAnnotationOptions *options = [super copyWithZone:zone];
    
    options.rotationEnabled = self.rotationEnabled;
    options.cropEnabled = self.cropEnabled;
    
    return options;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        BOOL rotationEnabled = YES;
        if ([coder containsValueForKey:PT_KEY(self, rotationEnabled)]) {
            rotationEnabled = [coder decodeBoolForKey:PT_KEY(self, rotationEnabled)];
        }
        BOOL cropEnabled = YES;
        if ([coder containsValueForKey:PT_KEY(self, cropEnabled)]) {
            cropEnabled = [coder decodeBoolForKey:PT_KEY(self, cropEnabled)];
        }
        
        _rotationEnabled = rotationEnabled;
        _cropEnabled = cropEnabled;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeBool:self.rotationEnabled forKey:PT_KEY(self, rotationEnabled)];
    [coder encodeBool:self.cropEnabled forKey:PT_KEY(self, cropEnabled)];
}

@end
