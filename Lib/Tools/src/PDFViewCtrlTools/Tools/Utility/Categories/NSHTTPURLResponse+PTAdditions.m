//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSHTTPURLResponse+PTAdditions.h"

#import "NSString+PTAdditions.h"

@implementation NSHTTPURLResponse (PTAdditions)

- (NSArray<NSString *> *)pt_contentDispositionParameters
{
    NSString *contentDisposition = nil;
    id contentDispositionValue = self.allHeaderFields[@"Content-Disposition"];
    if ([contentDispositionValue isKindOfClass:[NSString class]]) {
        contentDisposition = (NSString *)contentDispositionValue;
    }
    
    if (contentDisposition.length == 0) {
        return nil;
    }
    
    // Trim leading and trailing quotes.
    if ([contentDisposition hasPrefix:@"\""] &&
        [contentDisposition hasSuffix:@"\""]) {
        const NSRange trimmedRange = NSMakeRange(1, contentDisposition.length - 2);
        contentDisposition = [contentDisposition substringWithRange:trimmedRange];
    }
    
    NSCharacterSet *separator = [NSCharacterSet characterSetWithCharactersInString:@";"];
    
    return [contentDisposition pt_componentsSeparatedByCharactersInSet:separator options:PTStringSeparationOptionsQuoting];
}

- (NSString *)pt_contentDispositionFilename
{
    NSArray<NSString *> *parameters = self.pt_contentDispositionParameters;
    
    for (NSString *parameter in parameters) {
        const NSRange separatorRange = [parameter rangeOfString:@"="];
        if (separatorRange.location == NSNotFound) {
            continue;
        }
        
        const NSUInteger separatorIndex = separatorRange.location;
        
        NSString *parameterName = [parameter substringToIndex:separatorIndex];
        NSString *value = [parameter substringFromIndex:separatorIndex + 1];
        
        parameterName = [parameterName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        value = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        
        
        
        // filename*=[charset'[language]']encodedFilename
        if ([parameterName isEqualToString:@"filename*"]) {
            const NSUInteger valueLength = value.length;
            
            const NSRange leadingQuoteRange = [value rangeOfString:@"'"];
            const NSUInteger leadingQuoteIndex = leadingQuoteRange.location;
            if (leadingQuoteIndex != NSNotFound &&
                (leadingQuoteIndex + 1) < valueLength) {
                const NSRange searchRange = NSMakeRange(leadingQuoteIndex + 1,
                                                        valueLength - (leadingQuoteIndex + 1));
                
                const NSRange trailingQuoteRange = [value rangeOfString:@"'"
                                                                options:0
                                                                  range:searchRange];
                const NSUInteger trailingQuoteIndex = trailingQuoteRange.location;
                if (trailingQuoteIndex != NSNotFound) {
                    NSString *charsetName = [value substringToIndex:leadingQuoteIndex];
                    NSString *encodedFilename = [value substringFromIndex:trailingQuoteIndex + 1];
                    
                    charsetName = [charsetName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                    encodedFilename = [encodedFilename stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                    
                    // Determine NSString encoding for charset name.
//                    NSStringEncoding encoding = NSASCIIStringEncoding;
//                    if ([charsetName caseInsensitiveCompare:@"UTF-8"]) {
//                        encoding = NSUTF8StringEncoding;
//                    } else if ([charsetName caseInsensitiveCompare:@"ISO-8859-1"]) {
//                        encoding = NSISOLatin1StringEncoding;
//                    } else {
//                        NSLog(@"Unknown Content Disposition filename* charset: %@", charsetName);
//                    }
                    
                    
                    
                    return encodedFilename;
                }
            }
            return value;
        }
        // filename=asciiFilename
        else if ([parameterName isEqualToString:@"filename"]) {
            return value;
        }
    }
    
    return nil;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSHTTPURLResponse, PTAdditions)
