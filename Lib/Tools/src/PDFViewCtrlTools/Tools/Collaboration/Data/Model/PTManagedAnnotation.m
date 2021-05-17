//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTManagedAnnotation.h"

static void * const PTManagedAnnotation_repliesObservationContext = (void *)&PTManagedAnnotation_repliesObservationContext;

@interface PTManagedAnnotation (PTDynamicAccess)

- (BOOL)unread;

@end

@interface PTManagedAnnotation ()

@property (nonatomic) BOOL observing;

@end

@implementation PTManagedAnnotation

// Attributes
@dynamic color;
@dynamic contents;
@dynamic creationDate;
@dynamic identifier;
@dynamic lastReplyDate;
@dynamic modificationDate;
@dynamic opacity;
@dynamic pageNumber;
@dynamic replyCount;
@dynamic type;
@dynamic unread;
@dynamic unreadCount;

// Relationships
@dynamic author;
@dynamic document;
@dynamic parent;
@dynamic replies;

@synthesize observing = _observing;

- (BOOL)isUnread
{
    return [self unread];
}

#pragma mark - PTManagedObject

+ (NSString *)entityName
{
    return @"Annotation";
}

+ (instancetype)insertAnnotationWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    PTManagedAnnotation *annotation = [self insertInManagedObjectContext:managedObjectContext];
    annotation.identifier = identifier;
    return annotation;
}

- (void)startObservingRepliesKeyPath
{
    [self addObserver:self
           forKeyPath:PT_CLASS_KEY(PTManagedAnnotation, replies)
              options:0
              context:PTManagedAnnotation_repliesObservationContext];
    
    self.observing = YES;
}

- (void)stopObservingRepliesKeyPath
{
    if (!self.observing) {
        return;
    }
    
    [self removeObserver:self
              forKeyPath:PT_CLASS_KEY(PTManagedAnnotation, replies)
                 context:PTManagedAnnotation_repliesObservationContext];
    
    self.observing = NO;
}

- (PTManagedAnnotation *)lastReply
{
    NSFetchRequest<PTManagedAnnotation *> *request = [[self class] fetchRequest];
    // Replies to the current annotation.
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@",
                         PT_CLASS_KEY(PTManagedAnnotation, parent), self];
    // Only return one result (most recent reply).
    request.fetchLimit = 1;
    
    request.sortDescriptors =
    @[
      // Sort by creation date, descending.
      [NSSortDescriptor sortDescriptorWithKey:PT_CLASS_KEY(PTManagedAnnotation, creationDate)
                                    ascending:NO],
      ];
    
    NSError *fetchError = nil;
    NSArray<PTManagedAnnotation *> *results = [self.managedObjectContext executeFetchRequest:request
                                                                                       error:&fetchError];
    if (!results) {
        NSLog(@"Failed to fetch annotation last reply: %@", fetchError);
        return nil;
    }
    
    return results.firstObject;
}

- (void)markAllRepliesAsRead
{
    NSArray<PTManagedAnnotation *> *unreadReplies = [self fetchUnreadReplies];
    if (!unreadReplies) {
        // Replies not found.
        return;
    }
    
    int changedCount = 0;
    for (PTManagedAnnotation *reply in unreadReplies) {
        // Avoid unnecessary changes to reply.
        if ([reply isUnread]) {
            reply.unread = NO;
            changedCount++;
        }
    }
    
    // Update this annotation's and document's unreadCount.
    if (changedCount > 0) {
        if (self.unreadCount > 0) {
            self.unreadCount = MAX(0, self.unreadCount - changedCount);
        }
        
        PTManagedDocument *document = self.document;
        if (document.unreadCount > 0) {
            document.unreadCount = MAX(0, document.unreadCount - changedCount);
        }
    }
}

#pragma mark - Managed Object Lifecycle

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    
    [self startObservingRepliesKeyPath];
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    [self startObservingRepliesKeyPath];
}

- (void)prepareForDeletion
{
    [super prepareForDeletion];
    
    [self stopObservingRepliesKeyPath];
}

- (void)willTurnIntoFault
{
    [super willTurnIntoFault];
    
    [self stopObservingRepliesKeyPath];
}

#pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    if (context == PTManagedAnnotation_repliesObservationContext) {
        self.replyCount = (int32_t)self.replies.count;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
