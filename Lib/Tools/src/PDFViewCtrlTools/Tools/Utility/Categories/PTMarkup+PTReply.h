//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PTMarkupReplyType) {
    PTMarkupReplyTypeNone,
    PTMarkupReplyTypeReply,
    PTMarkupReplyTypeGroup,
};

@interface PTMarkup (PTReply)

@property (nonatomic, readonly, assign, getter=isReply) BOOL reply;

- (BOOL)isInReplyToAnnot:(PTAnnot *)annot;

@property (nonatomic, nullable) PTAnnot *inReplyToAnnot;

@property (nonatomic, copy, nullable) NSString *inReplyToAnnotId;

@property (nonatomic) PTMarkupReplyType replyType;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(PTMarkup, PTReply)
PT_IMPORT_CATEGORY(PTMarkup, PTReply)
