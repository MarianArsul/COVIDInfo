//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnot (PTAdditions)

@property (nonatomic, readonly, copy, nullable) NSArray<PTAnnot*> *annotationsInGroup;

@property (nonatomic, readonly) BOOL hasReplyTypeGroup;

@property (nonatomic, readonly) BOOL isInGroup;

@property (nonatomic, readonly, nullable) NSString *IRTAsNSString;

@property (nonatomic, copy, nullable) NSString *uniqueID;

@property (nonatomic, readonly) UIColor* colorPrimary;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTAnnot, PTAdditions)
PT_IMPORT_CATEGORY(PTAnnot, PTAdditions)
