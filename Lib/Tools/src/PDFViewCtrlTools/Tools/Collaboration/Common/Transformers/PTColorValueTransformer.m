//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTColorValueTransformer.h"

@implementation PTColorValueTransformer

+ (Class)transformedValueClass
{
    return [UIColor class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if (![value isKindOfClass:[UIColor class]]) {
        return nil;
    }
    UIColor *color = (UIColor *)value;
    
    NSKeyedArchiver *archiver = nil;
    if (@available(iOS 11.0, *)) {
        archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:YES];
    } else {
        archiver = [[NSKeyedArchiver alloc] init];
        archiver.requiresSecureCoding = YES;
    }
    
    [archiver encodeObject:color forKey:NSKeyedArchiveRootObjectKey];
    [archiver finishEncoding];
    
    NSData *data = archiver.encodedData;
    return data;
}

- (id)reverseTransformedValue:(id)value
{
    if (![value isKindOfClass:[NSData class]]) {
        return nil;
    }
    NSData *data = (NSData *)value;
    
    NSKeyedUnarchiver *unarchiver = nil;
    if (@available(iOS 11.0, *)) {
        NSError *unarchiveError = nil;
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data
                                                                 error:&unarchiveError];
        if (unarchiveError) {
            NSLog(@"Failed to transform NSData to UIColor: %@", unarchiveError);
            return nil;
        }
    } else {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        unarchiver.requiresSecureCoding = YES;
    }
    NSAssert(unarchiver != nil, @"Unarchiver for UIColor was not loaded");
    
    NSError *decodeError = nil;
    id color = [unarchiver decodeTopLevelObjectOfClasses:[NSSet setWithArray:@[
        [UIColor class],
    ]] forKey:NSKeyedArchiveRootObjectKey error:&decodeError];
    if (decodeError) {
        NSLog(@"Failed to transform NSData to UIColor: %@", decodeError);
    }
    return color;
}

+ (void)load
{
    PTColorValueTransformer *transformer = [[PTColorValueTransformer alloc] init];
    NSValueTransformerName name = NSStringFromClass([PTColorValueTransformer class]);
    [NSValueTransformer setValueTransformer:transformer
                                    forName:name];
}

@end
