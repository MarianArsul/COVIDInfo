//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTWidgetAnnotationOptions.h"

@implementation PTWidgetAnnotationOptions

- (instancetype)initWithCanCreate:(BOOL)canCreate canEdit:(BOOL)canEdit
{
    self = [super initWithCanCreate:canCreate canEdit:canEdit];
    if (self) {
        if (@available(iOS 13.4, *)) {
            _preferredDatePickerStyle = UIDatePickerStyleAutomatic;
        }
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAnnotationOptions:(PTAnnotationOptions *)annotationOptions
{
    if (![super isEqualToAnnotationOptions:annotationOptions]) {
        return NO;
    }
    
    if (![annotationOptions isKindOfClass:[PTWidgetAnnotationOptions class]]) {
        return NO;
    }
    
    PTWidgetAnnotationOptions *widgetAnnotationOptions = (PTWidgetAnnotationOptions *)annotationOptions;
    if (@available(iOS 13.4, *)) {
        const BOOL datePickerStyleEqual = (self.preferredDatePickerStyle == widgetAnnotationOptions.preferredDatePickerStyle);
        return (datePickerStyleEqual);
    } else {
        return YES;
    }
}

#pragma mark - <NSObject>

- (NSUInteger)hash
{
    NSUInteger result = [super hash];
    if (@available(iOS 13.4, *)) {
        result ^= ((NSUInteger)self.preferredDatePickerStyle);
    }
    return result;
}

- (NSString *)description
{
    if (@available(iOS 13.4, *)) {
        return [NSString stringWithFormat:@"<%@: %p; canCreate: %@; canEdit: %@; preferredDatePickerStyle: %ld>",
                [self class], self,
                PT_NSStringFromBOOL(self.canCreate), PT_NSStringFromBOOL(self.canEdit),
                (long)self.preferredDatePickerStyle];
    } else {
        return [NSString stringWithFormat:@"<%@: %p; canCreate: %@; canEdit: %@>",
                [self class], self,
                PT_NSStringFromBOOL(self.canCreate), PT_NSStringFromBOOL(self.canEdit)];
    }
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    PTWidgetAnnotationOptions *options = [super copyWithZone:zone];
    
    if (@available(iOS 13.4, *)) {
        options.preferredDatePickerStyle = self.preferredDatePickerStyle;
    }
    
    return options;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        if (@available(iOS 13.4, *)) {
            UIDatePickerStyle preferredDatePickerStyle = UIDatePickerStyleAutomatic;
            if ([coder containsValueForKey:PT_KEY(self, preferredDatePickerStyle)]) {
                preferredDatePickerStyle = [coder decodeIntegerForKey:PT_KEY(self, preferredDatePickerStyle)];
            }
            _preferredDatePickerStyle = preferredDatePickerStyle;
        }

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    if (@available(iOS 13.4, *)) {
        [coder encodeInteger:self.preferredDatePickerStyle
                      forKey:PT_KEY(self, preferredDatePickerStyle)];
    }
}


@end
