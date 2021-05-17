//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "NSString+PTAdditions.h"

@implementation NSString (PTAdditions)

NSString * const PTKeyPathSeparator = @".";

- (NSString *)pt_sentenceCapitalizedString
{
    if (self.length < 1) {
        return self;
    }
    
    return [[self substringToIndex:1].capitalizedString stringByAppendingString:[self substringFromIndex:1]];
}

- (NSArray<NSString *> *)pt_keyPathComponents
{
    return [self componentsSeparatedByString:PTKeyPathSeparator];
}

- (NSArray<NSString *> *)pt_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separator options:(PTStringSeparationOptions)options
{
    const BOOL isQuotingEnabled = PT_BITMASK_CHECK(options,
                                                   PTStringSeparationOptionsQuoting);
    
    if (isQuotingEnabled && [separator characterIsMember:'"']) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:nil
                                     userInfo:nil];
        return nil;
    }
    
    const NSUInteger stringLength = self.length;
    NSUInteger componentIndex = 0;
    NSUInteger currentIndex = 0;
    
    NSMutableArray<NSString *> *components = [NSMutableArray array];
    do {
        BOOL isQuoted = NO;
        BOOL isEscaped = NO;
        while (currentIndex < stringLength) {
            const unichar character = [self characterAtIndex:currentIndex];
            
            if (isQuotingEnabled && !isEscaped && character == '"') {
                isQuoted = !isQuoted;
            }
            else if ([separator characterIsMember:character]) {
                if (!isQuoted) {
                    break;
                }
            }
            isEscaped = (!isEscaped && character == '\\');
            currentIndex++;
        }
        const NSRange componentRange = NSMakeRange(componentIndex,
                                                   currentIndex - componentIndex);
        NSString *component = [self substringWithRange:componentRange];
        if (component.length > 0) {
            [components addObject:component];
        }
        currentIndex++;
        componentIndex = currentIndex;
    } while (componentIndex < stringLength);
    
    return [components copy];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(NSString, PTAdditions)
