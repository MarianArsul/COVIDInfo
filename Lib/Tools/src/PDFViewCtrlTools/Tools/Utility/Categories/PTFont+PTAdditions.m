//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFont+PTAdditions.h"

#import <CoreText/CoreText.h>

@implementation PTFont (PTAdditions)

- (UIFont *)UIFontWithSize:(CGFloat)size
{
    if (![self IsEmbedded]) {
        // Get the matching UIFont for the font and family name.
        UIFontDescriptor *descriptor = [[UIFontDescriptor alloc] initWithFontAttributes:@{
            UIFontDescriptorNameAttribute: [self GetName],
            UIFontDescriptorFamilyAttribute: [self GetFamilyName],
        }];
        
        return [UIFont fontWithDescriptor:descriptor size:size];
    } else {
        PTObj *embeddedFontObj = [self GetEmbeddedFont];
        const int decodedFontBufferSize = [self GetEmbeddedFontBufSize];
        if ([embeddedFontObj IsValid] && decodedFontBufferSize > 0) {
            // Read the decoded embedded font data into a raw data object.
            PTFilter *fontStream = [embeddedFontObj GetDecodedStream];
            PTFilterReader *filterReader = [[PTFilterReader alloc] initWithFilter:fontStream];
            NSData *fontData = [filterReader Read:decodedFontBufferSize];
            
            NSAssert(fontData.length == decodedFontBufferSize,
                     @"Embedded font data length (%lu) does not match expected length (%d)",
                     (unsigned long)fontData.length, decodedFontBufferSize);
            
            // Create a Core Graphics font object from the raw font data.
            CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)fontData);
            CGFontRef graphicsFontRef = CGFontCreateWithDataProvider(dataProvider);
            CFRelease(dataProvider);
            if (!graphicsFontRef) {
                // Failed to create Core Graphics font object.
                return nil;
            }
            
//            // Register the graphics font so it can be found with font descriptor matching.
//            CFErrorRef errorRef = NULL;
//            if (!CTFontManagerRegisterGraphicsFont(fontRef, &errorRef)) {
//                NSLog(@"Failed to register embedded font: %@", (__bridge NSError *)errorRef);
//            }
            
            // Create a Core Text font object from the graphics font at the specified point size.
            // NOTE: CTFontRef is toll-free bridged to UIFont.
            CTFontRef fontRef = CTFontCreateWithGraphicsFont(graphicsFontRef, size, NULL, NULL);
            UIFont *font = (__bridge_transfer UIFont *)fontRef;
            
            CFRelease(graphicsFontRef);
            
            return font;
        }
    }

    return nil;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTFont, PTAdditions)
