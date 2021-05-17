//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTManagedObject.h"
#import "PTManagedDocument.h"
#import "PTManagedUser.h"

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@class PTManagedDocument;
@class PTManagedUser;

@interface PTManagedAnnotation : PTManagedObject

@property (nonatomic, copy, nullable) NSString *identifier;

@property (nonatomic) PTAnnotType type;

@property (nonatomic) double opacity;

@property (nonatomic) int32_t pageNumber;

@property (nonatomic, copy, nullable) NSString *contents;

@property (nonatomic, retain, nullable) UIColor *color;

@property (nonatomic, copy, nullable) NSDate *creationDate;

@property (nonatomic, copy, nullable) NSDate *modificationDate;

@property (nonatomic, copy, nullable) NSDate *lastReplyDate;

@property (nonatomic) int32_t replyCount;

@property (nonatomic, getter=isUnread) BOOL unread;
@property (nonatomic) int32_t unreadCount;

@property (nonatomic, retain, nullable) PTManagedDocument *document;

@property (nonatomic, retain, nullable) PTManagedAnnotation *parent;
@property (nonatomic, retain, nullable) NSSet<PTManagedAnnotation *> *replies;

@property (nonatomic, retain, nullable) PTManagedUser *author;

@property (nonatomic, readonly, retain, nullable) PTManagedAnnotation *lastReply;

#pragma mark - Convenience

+ (instancetype)insertAnnotationWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)markAllRepliesAsRead;

@end

@interface PTManagedAnnotation (PTFetching)

@property (nonatomic, readonly, nullable) NSString *creationDateDaySectionIdentifier;

@property (nonatomic, readonly, nullable) NSString *lastReplyDateDaySectionIdentifier;

- (nullable NSArray<PTManagedAnnotation *> *)fetchUnreadReplies;

@end

@interface PTManagedAnnotation (RepliesAccessors)

- (void)addRepliesObject:(PTManagedAnnotation *)value;
- (void)removeRepliesObject:(PTManagedAnnotation *)value;
- (void)addReplies:(NSSet<PTManagedAnnotation *> *)values;
- (void)removeReplies:(NSSet<PTManagedAnnotation *> *)values;

@end

NS_ASSUME_NONNULL_END
