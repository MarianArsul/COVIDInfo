//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFreeTextAnnotationOptions.h"

@implementation PTFreeTextAnnotationOptions

- (instancetype)initWithCanCreate:(BOOL)canCreate canEdit:(BOOL)canEdit
{
    self = [super initWithCanCreate:canCreate canEdit:canEdit];
    if (self) {
        _inputAccessoryViewEnabled = YES;
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAnnotationOptions:(PTAnnotationOptions *)annotationOptions
{
    if (![super isEqualToAnnotationOptions:annotationOptions]) {
        return NO;
    }
    
    if (![annotationOptions isKindOfClass:[PTFreeTextAnnotationOptions class]]) {
        return NO;
    }
    
    return YES;
    
}



@end
