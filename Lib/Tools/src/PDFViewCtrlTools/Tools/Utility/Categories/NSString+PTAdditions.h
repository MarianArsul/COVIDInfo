//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

PT_LOCAL NSString * const PTKeyPathSeparator;

typedef NS_OPTIONS(NSUInteger, PTStringSeparationOptions) {
    PTStringSeparationOptionsQuoting = 1 << 1,
};

@interface NSString (PTAdditions)

@property (nonatomic, readonly) NSString *pt_sentenceCapitalizedString;

@property (nonatomic, readonly) NSArray<NSString *> *pt_keyPathComponents;

- (NSArray<NSString *> *)pt_componentsSeparatedByCharactersInSet:(NSCharacterSet *)separator options:(PTStringSeparationOptions)options;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(NSString, PTAdditions)
PT_IMPORT_CATEGORY(NSString, PTAdditions)
