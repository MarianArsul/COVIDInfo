//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationManager.h"

#import "PTCoreDataManager.h"

#import "PTAnnot+PTAdditions.h"
#import "PTDate+NSDate.h"
#import "PTFDFDoc+PTAdditions.h"
#import "PTKeyValueObserving.h"

#import "PTColorDefaults.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationManager ()

@property (nonatomic, strong) PTCoreDataManager *dataManager;

@property (nonatomic, strong, nullable) NSManagedObjectID *documentObjectID;
@property (nonatomic, strong, nullable) PTManagedDocument *document;
@property (nonatomic) int32_t previousDocumentUnreadCount;

@property (nonatomic, strong, nullable) NSManagedObjectID *userObjectID;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotationManager

- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager
{
    self = [self init];
    if (self) {
        _collaborationManager = collaborationManager;
        
        NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
        
        [notificationCenter addObserver:self
                               selector:@selector(remoteAnnotationsAddedWithNotification:)
                                   name:PTCollaborationManagerRemoteAnnotationsAddedNotification
                                 object:collaborationManager];
        
        [notificationCenter addObserver:self
                               selector:@selector(remoteAnnotationsModifiedWithNotification:)
                                   name:PTCollaborationManagerRemoteAnnotationsModifiedNotification
                                 object:collaborationManager];
        
        [notificationCenter addObserver:self
                               selector:@selector(remoteAnnotationsRemovedWithNotification:)
                                   name:PTCollaborationManagerRemoteAnnotationsRemovedNotification
                                 object:collaborationManager];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataManager = [[PTCoreDataManager alloc] initWithName:@"CollaborationDataModel" completion:^{
            
        }];
    }
    return self;
}

- (void)setDocumentIdentifier:(NSString *)documentIdentifier
{
    _documentIdentifier = [documentIdentifier copy]; // @property (copy) semantics.
    
    if (documentIdentifier) {
        [self loadDocument];
    }
}

- (void)setUserIdentifier:(NSString *)userIdentifier
{
    _userIdentifier = [userIdentifier copy]; // @property (copy) semantics.
    
    if (userIdentifier) {
        [self loadUser];
    }
}

- (void)setCurrentAnnotationIdentifier:(NSString *)identifier
{
    _currentAnnotationIdentifier = [identifier copy]; // @property (copy) semantics.
    
    if (identifier) {
        [self markRepliesAsReadForAnnotationIdentifier:identifier];
    }
}

- (PTManagedAnnotation *)managedAnnotationForAnnot:(PTAnnot *)annot
{
    NSString *uniqueID = annot.uniqueID;
    if (uniqueID.length == 0) {
        return nil;
    }
    
    if (!self.documentObjectID) {
        return nil;
    }
    
    PTManagedDocument *document = [self.dataManager.mainContext objectWithID:self.documentObjectID];
    return [document fetchAnnotationWithIdentifier:uniqueID];
}

- (PTManagedAnnotation *)managedAnnotationForAnnotationIdentifier:(NSString *)annotationIdentifier
{
    if (annotationIdentifier.length == 0) {
        return nil;
    }
    
    if (!self.documentObjectID) {
        return nil;
    }
    
    PTManagedDocument *document = [self.dataManager.mainContext objectWithID:self.documentObjectID];
    return [document fetchAnnotationWithIdentifier:annotationIdentifier];
}

- (NSFetchRequest<PTManagedAnnotation *> *)fetchRequestForDocumentAnnotations
{
    NSAssert(self.documentObjectID != nil, @"Document must be loaded before fetching annotations");
    
    NSFetchRequest *request = [PTManagedAnnotation fetchRequest];
        
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                         @[
                           // Belong to the current document...
                           [NSPredicate predicateWithFormat:@"%K == %@",
                            PT_CLASS_KEY(PTManagedAnnotation, document), self.documentObjectID],
                           // without a parent annotation (ie. not a reply).
                           [NSPredicate predicateWithFormat:@"%K == nil",
                            PT_CLASS_KEY(PTManagedAnnotation, parent)],
                           
                           // Filter out annotations without an author.
                           [NSPredicate predicateWithFormat:@"%K != nil",
                            PT_CLASS_KEY(PTManagedAnnotation, author)],
                           ]];
    
    return request;
}

- (NSFetchRequest<PTManagedAnnotation *> *)fetchRequestForAnnotationReplies:(PTManagedAnnotation *)annotation
{    
    NSFetchRequest *request = [PTManagedAnnotation fetchRequest];
    
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@",
                         PT_CLASS_KEY(PTManagedAnnotation, parent), annotation];
    
    return request;
}

- (NSFetchedResultsController<PTManagedAnnotation *> *)fetchedResultsControllerForDocumentAnnotationsSortedByKeyPath:(NSString *)keyPath
{
    NSFetchRequest<PTManagedAnnotation *> *request = [self fetchRequestForDocumentAnnotations];
    
    // Sort by annotation creation date.
    request.sortDescriptors =
    @[
      [NSSortDescriptor sortDescriptorWithKey:PT_CLASS_KEY(PTManagedAnnotation, creationDate)
                                    ascending:YES]
      ];
    
    NSManagedObjectContext *context = self.dataManager.mainContext;
    
    return [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                               managedObjectContext:context
                                                 sectionNameKeyPath:keyPath
                                                          cacheName:nil];
}

- (NSFetchedResultsController<PTManagedAnnotation *> *)fetchedResultsControllerWithFetchRequest:(NSFetchRequest<PTManagedAnnotation *> *)fetchRequest sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    NSManagedObjectContext *context = self.dataManager.mainContext;

    return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:context
                                                 sectionNameKeyPath:sectionNameKeyPath
                                                          cacheName:nil];
}

- (NSFetchedResultsController<PTManagedAnnotation *> *)fetchedResultsControllerForAnnotationReplies:(PTManagedAnnotation *)annotation
{
    NSFetchRequest<PTManagedAnnotation *> *request = [self fetchRequestForAnnotationReplies:annotation];
    
    // Sort by reply creation date.
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:PT_CLASS_KEY(PTManagedAnnotation, creationDate)
                                                              ascending:YES]];
    
    NSManagedObjectContext *context = self.dataManager.mainContext;
    
    return [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                               managedObjectContext:context
                                                 sectionNameKeyPath:nil
                                                          cacheName:nil];
}

- (void)loadDocument
{
    if (self.documentIdentifier.length == 0) {
        return;
    }
    
    [self.dataManager performBackgroundTask:^(NSManagedObjectContext *context) {
        
        // Fetch the document with a matching identifier.
        NSFetchRequest *request = [PTManagedDocument fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"%K == %@",
                             PT_CLASS_KEY(PTManagedDocument, identifier), self.documentIdentifier];
        
        NSError *error = nil;
        NSArray<PTManagedDocument *> *results = [context executeFetchRequest:request
                                                                       error:&error];
        if (!results) {
            PTLog(@"Failed to fetch document: %@", error);
            return;
        }
        
        PTManagedDocument *document = results.firstObject;
        if (!document) {
            // Document has not been loaded previously - create a new document.
            document = [PTManagedDocument insertDocumentWithIdentifier:self.documentIdentifier
                                                inManagedObjectContext:context];
            
            if ([context hasChanges]) {
                NSError *saveError = nil;
                if (![context save:&saveError]) {
                    PTLog(@"Save error: %@", saveError);
                }
            }
        }
    
        // Save document object ID for use across contexts.
        // NOTE: The document object ID must be set before this block exits.
        self.documentObjectID = document.objectID;
    
        dispatch_async(dispatch_get_main_queue(), ^{
            self.document = [self.dataManager.mainContext objectWithID:self.documentObjectID];
            
//            // Observe the document's unreadCount property for changes.
//            [self pt_observeObject:self.document
//                        forKeyPath:PT_CLASS_KEY(PTManagedDocument, unreadCount)
//                          selector:@selector(documentUnreadCountDidChange:)];
            
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(objectsDidChangeWithNotification:)
                                                       name:NSManagedObjectContextObjectsDidChangeNotification
                                                     object:self.dataManager.mainContext];
        });
    }];
}

//- (void)documentUnreadCountDidChange:(PTKeyValueObservedChange *)change
//{
//    if (self.document != change.object) {
//        return;
//    }
//
//    // Notify delegate of change.
//    if ([self.delegate respondsToSelector:@selector(annotationManager:documentUnreadCountDidChange:)]) {
//        [self.delegate annotationManager:self documentUnreadCountDidChange:self.document.unreadCount];
//    }
//}

- (void)loadUser
{
    if (self.userIdentifier.length == 0) {
        return;
    }
    
    [self.dataManager performBackgroundTask:^(NSManagedObjectContext *context) {
        
        PTManagedUser *user = [PTManagedUser fetchUserWithIdentifier:self.userIdentifier
                                                             context:context];
        if (!user) {
            user = [PTManagedUser insertUserWithIdentifier:self.userIdentifier
                                    inManagedObjectContext:context];
            
            if ([context hasChanges]) {
                NSError *saveError = nil;
                if (![context save:&saveError]) {
                    PTLog(@"Save error: %@", saveError);
                }
            }
        }
        
        // Save user object ID for use across contexts.
        // NOTE: The user object ID needs to be set before this block returns.
        self.userObjectID = user.objectID;
    }];
}

- (void)markRepliesAsReadForAnnotationIdentifier:(NSString *)identifier document:(PTManagedDocument *)document context:(NSManagedObjectContext *)context
{
    PTManagedAnnotation *annotation = [document fetchAnnotationWithIdentifier:identifier];
    if (!annotation) {
        // Annotation not found.
        return;
    }
    
    [annotation markAllRepliesAsRead];
    
    if ([context hasChanges]) {
        NSError *saveError = nil;
        if (![context save:&saveError]) {
            PTLog(@"Failed to save context: %@", saveError);
        }
    }
}

- (void)markRepliesAsReadForAnnotationIdentifier:(NSString *)identifier
{
    [self.dataManager performBackgroundTask:^(NSManagedObjectContext *context) {
        PTManagedDocument *document = [context objectWithID:self.documentObjectID];
        
        [self markRepliesAsReadForAnnotationIdentifier:identifier
                                              document:document
                                               context:context];
    }];
}

- (NSString *)sanitizeXFDFString:(NSString *)xfdfString
{
    NSMutableString *mutableXFDFString = [xfdfString mutableCopy];
    
    NSArray<NSString *> *commandTags = @[
        @"<add>",
        @"</add>",
        @"<add />",
        
        @"<modify>",
        @"</modify>",
        @"<modify />",
        
        @"<delete />",
    ];
    
    // Remove command tags from XFDF string.
    for (NSString *tag in commandTags) {
        [mutableXFDFString replaceOccurrencesOfString:tag withString:@""
                                              options:0 range:NSMakeRange(0, mutableXFDFString.length)];
    }
    
    NSString *xmlStart = @"<?xml";
    
    if (![mutableXFDFString hasPrefix:xmlStart]) {
        NSString *xfdfStart = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<xfdf xmlns=\"http://ns.adobe.com/xfdf/\" xml:space=\"preserve\">";

        [mutableXFDFString insertString:xfdfStart atIndex:0];
    }
    
    NSString *xfdfEnd = @"</xfdf>";

    if (![mutableXFDFString hasSuffix:xfdfEnd]) {
        [mutableXFDFString appendString:xfdfEnd];
    }
    
    return [mutableXFDFString copy];
}

- (nullable PTFDFDoc *)fdfDocFromXFDFString:(NSString *)xfdfString
{
    @try {
        return [PTFDFDoc CreateFromXFDF:xfdfString];
    } @catch (NSException *exception) {
        PTLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    return nil;
}

- (UIColor *)colorForAnnot:(PTAnnot *)annot
{
    UIColor *color = [PTColorDefaults uiColorFromColorPt:[annot GetColorAsRGB] compNum:3];
    
    PTAnnotType annotType = [annot GetType];
    if (annotType == e_ptFreeText) {
        PTFreeText *freeText = [[PTFreeText alloc] initWithAnn:annot];
        color =  [PTColorDefaults uiColorFromColorPt:[freeText GetTextColor] compNum:[freeText GetTextColorCompNum]];
    }
    else if ([annot IsMarkup]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];
        if ([markup GetInteriorColorCompNum] == 3) {
            UIColor *fillColor = [PTColorDefaults uiColorFromColorPt:[markup GetInteriorColor] compNum:3];
            if (CGColorGetAlpha(fillColor.CGColor) != 0.0) {
                color = fillColor;
            }
        }
    }
    
    return color;
}

- (void)updateManagedAnnotation:(PTManagedAnnotation *)annotation withCollaborationAnnotation:(PTCollaborationAnnotation *)collaborationAnnotation
{
    NSString *inReplyTo = nil;
    
    NSString *xfdf = [self sanitizeXFDFString:collaborationAnnotation.xfdf];
    
    PTFDFDoc *fdfDoc = [self fdfDocFromXFDFString:xfdf];
    PTAnnot *annot = nil;
    for (PTAnnot *fdfAnnot in fdfDoc.annots) {
        // Filter out popup annotations.
        if ([fdfAnnot IsValid] && [fdfAnnot GetType] != e_ptPopup) {
            annot = fdfAnnot;
            break;
        }
    }
    if ([annot IsValid]) {
        PTAnnotType annotType = [annot GetType];
        PTPDFRect *annotRect = [annot GetRect];
        [annotRect Normalize];
        
        NSString *contents = [annot GetContents];
        
        UIColor *color = [self colorForAnnot:annot];
        
        NSDate *modificationDate = nil;
        
        PTDate *date = [annot GetDate];
        if ([date IsValid]) {
            modificationDate = date.NSDateValue;
        }
        
        double opacity = 1.0;
        NSDate *creationDate = nil;
        
        if ([annot IsMarkup]) {
            PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];
            opacity = [markup GetOpacity];
            
            PTDate *creationDates = [markup GetCreationDates];
            if ([creationDates IsValid]) {
                creationDate = creationDates.NSDateValue;
            }
        }
        
        int pageNumber = INT_MIN;
        
        PTObj *annotObj = [annot GetSDFObj];
        NSAssert([annotObj IsValid], @"FDF Annot's SDF object is invalid");
        
        // The "IRT" entry is a string in (X)FDF with the parent annotation's "NM" entry.
        PTObj *inReplyToObj = [annotObj FindObj:@"IRT"];
        if ([inReplyToObj IsValid] && [inReplyToObj IsString]) {
            inReplyTo = [inReplyToObj GetAsPDFText];
        }
        
        PTObj *pageObj = [annotObj FindObj:@"Page"];
        if ([pageObj IsValid] && [pageObj IsNumber]) {
            pageNumber = [pageObj GetNumber];
        }
        
        // Set properties on managed annotation.
        annotation.type = annotType;
        annotation.opacity = opacity;
        
        if (pageNumber >= 0) {
            // NOTE: (X)FDF page numbers are zero-indexed.
            annotation.pageNumber = pageNumber + 1;
        }
        
        if (color) {
            annotation.color = color;
        }
        if (contents.length > 0) {
            annotation.contents = [contents stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        }
        
        if (creationDate) {
            annotation.creationDate = creationDate;
            
            if (!annotation.lastReplyDate) {
                annotation.lastReplyDate = creationDate;
            }
        }
        if (modificationDate) {
            annotation.modificationDate = modificationDate;
        }
    }
    [fdfDoc Close];
    
    // Establish parent/reply relationship.
    if (inReplyTo.length > 0) {
        PTManagedDocument *document = annotation.document;
        
        NSAssert(document != nil,
                 @"Cannot add annotation reply: missing document reference");
        
        PTManagedAnnotation *parent = [document fetchAnnotationWithIdentifier:inReplyTo];
        if (!parent) {
            parent = [PTManagedAnnotation insertAnnotationWithIdentifier:inReplyTo
                                                  inManagedObjectContext:annotation.managedObjectContext];
            [document addAnnotationsObject:parent];
        }
        
        annotation.parent = parent;
    } else {
        // Annotation does not have a parent.
        annotation.parent = nil;
    }
}

- (BOOL)shouldMarkAnnotationUnread:(PTManagedAnnotation *)annotation
{
    if ([self.userIdentifier isEqualToString:annotation.author.identifier]) {
        // Annotation was created by the current user.
        return NO;
    }
    
    // Check if the annotation is a parent or reply.
    PTManagedAnnotation *parent = annotation.parent;
    if (!parent) {
        // Annotation is parent and cannot be "unread".
        return NO;
    }
    
    // Annotation is a reply.
    // Check if the parent is the current annotation.
    if ([self.currentAnnotationIdentifier isEqualToString:parent.identifier]) {
        // We are currently looking at the annotation so don't mark as unread.
        return NO;
    }
    
    // Annotation is unread.
    return YES;
}

#pragma mark - Annotation actions

- (void)addAnnotations:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations markUnreads:(BOOL)markUnreads forDocumentObjectID:(NSManagedObjectID *)documentObjectID intoContext:(NSManagedObjectContext *)context
{
    NSAssert(![NSThread.currentThread isMainThread],
             @"%s cannot be called on the main thread", __PRETTY_FUNCTION__);
    
    PTManagedDocument *document = [context objectWithID:documentObjectID];
    
    int unreadChangedCount = 0;
    
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        PTManagedAnnotation *annotation = [document fetchAnnotationWithIdentifier:collaborationAnnotation.annotationID];
        if (!annotation) {
            // Create annotation and add to document.
            annotation = [PTManagedAnnotation insertAnnotationWithIdentifier:collaborationAnnotation.annotationID
                                                      inManagedObjectContext:context];
            [document addAnnotationsObject:annotation];
        }
        
        [self updateManagedAnnotation:annotation withCollaborationAnnotation:collaborationAnnotation];
        
        // Set the author of the annotation.
        PTManagedUser *author = [PTManagedUser fetchUserWithIdentifier:collaborationAnnotation.userID
                                                               context:context];
        if (!author) {
            // Create user.
            author = [PTManagedUser insertUserWithIdentifier:collaborationAnnotation.userID
                                        inManagedObjectContext:context];
        }
        // Set/update author name.
        if (collaborationAnnotation.userName.length > 0
            && ![author.name isEqualToString:collaborationAnnotation.userName]) {
            author.name = collaborationAnnotation.userName;
        }
        annotation.author = author;

        // Set annotation unread status.
        BOOL unread = (markUnreads && [self shouldMarkAnnotationUnread:annotation]);
        if (unread) {
            annotation.unread = YES;
            
            // Update the parent annotation's unread count.
            if (annotation.parent) {
                annotation.parent.unreadCount++;
            }
            unreadChangedCount++;
        }
        
        // Update the parent's last reply date.
        PTManagedAnnotation *parent = annotation.parent;
        if (parent) {
            if (!parent.lastReplyDate ||
                [annotation.creationDate compare:parent.lastReplyDate] == NSOrderedDescending) {
                parent.lastReplyDate = annotation.creationDate;
            }
        }
    }
    
    if (markUnreads && unreadChangedCount > 0) {
        document.unreadCount = document.unreadCount + unreadChangedCount;
    }
    
    if ([context hasChanges]) {
        // Save changes in context.
        NSError *saveError = nil;
        if (![context save:&saveError]) {
            PTLog(@"Failed to save context: %@", saveError);
        }
    }
}

- (void)updateAnnotations:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations forDocumentObjectID:(NSManagedObjectID *)documentObjectID context:(NSManagedObjectContext *)context
{
    NSAssert(![NSThread.currentThread isMainThread],
             @"%s cannot be called on the main thread", __PRETTY_FUNCTION__);
    
    PTManagedDocument *document = [context objectWithID:documentObjectID];
    
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        PTManagedAnnotation *annotation = [document fetchAnnotationWithIdentifier:collaborationAnnotation.annotationID];
        if (!annotation) {
            // Annotation not found.
            continue;
        }
        
        [self updateManagedAnnotation:annotation withCollaborationAnnotation:collaborationAnnotation];
    }
    
    if ([context hasChanges]) {
        // Save changes in context.
        NSError *saveError = nil;
        if (![context save:&saveError]) {
            PTLog(@"Failed to save context: %@", saveError);
        }
    }
}

- (void)removeAnnotations:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations forDocumentObjectID:(NSManagedObjectID *)documentObjectID context:(NSManagedObjectContext *)context
{
    NSAssert(![NSThread.currentThread isMainThread],
             @"%s cannot be called on the main thread", __PRETTY_FUNCTION__);
    
    PTManagedDocument *document = [context objectWithID:documentObjectID];

    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        PTManagedAnnotation *annotation = [document fetchAnnotationWithIdentifier:collaborationAnnotation.annotationID];
        if (!annotation) {
            // Annotation not found.
            continue;
        }
        
        // Delete annotation from context.
        [context deleteObject:annotation];
    }
    
    if ([context hasChanges]) {
        // Save changes in context.
        NSError *saveError = nil;
        if (![context save:&saveError]) {
            PTLog(@"Failed to save context: %@", saveError);
        }
    }
}

- (void)addAnnotations:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations markUnreads:(BOOL)markUnreads
{
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        if (collaborationAnnotation.annotationID.length == 0) {
            PTLog(@"Failed to add annotation with missing identifier");
            
            return;
        }
    }
    
    [self.dataManager performBackgroundTask:^(NSManagedObjectContext *context) {
        NSAssert(self.documentObjectID != nil,
                 @"Document must be loaded before adding annotations");
        
        [self addAnnotations:collaborationAnnotations
                 markUnreads:markUnreads
         forDocumentObjectID:self.documentObjectID
                 intoContext:context];
    }];
}

- (void)updateAnnotations:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations
{
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        if (collaborationAnnotation.annotationID.length == 0) {
            PTLog(@"Failed to update annotation with missing identifier");
            return;
        }
    }
    
    [self.dataManager performBackgroundTask:^(NSManagedObjectContext *context) {
        NSAssert(self.documentObjectID != nil,
                 @"Document must be loaded before updating annotations");
        
        [self updateAnnotations:collaborationAnnotations
            forDocumentObjectID:self.documentObjectID
                        context:context];
    }];
}

- (void)removeAnnotations:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations
{
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        if (collaborationAnnotation.annotationID.length == 0) {
            PTLog(@"Failed to remove annotation with missing identifier");
            return;
        }
    }
    
    [self.dataManager performBackgroundTask:^(NSManagedObjectContext *context) {
        NSAssert(self.documentObjectID != nil,
                 @"Document must be loaded before removing annotations");

        [self removeAnnotations:collaborationAnnotations forDocumentObjectID:self.documentObjectID context:context];
    }];
}

#pragma mark - PTCollaborationManager notifications

- (void)remoteAnnotationsAddedWithNotification:(NSNotification *)notification
{
    if (notification.object != self.collaborationManager) {
        return;
    }
    
    NSArray<PTCollaborationAnnotation *> *annotations = notification.userInfo[PTCollaborationManagerAnnotationsUserInfoKey];
    if (!annotations) {
        PTLog(@"Received annotation added notification without annotation objects");
        return;
    }
    
    BOOL isInitial = ((NSNumber *)notification.userInfo[PTCollaborationManagerIsInitialUserInfoKey]).boolValue;
    
    [self addAnnotations:annotations markUnreads:!isInitial];
}

- (void)remoteAnnotationsModifiedWithNotification:(NSNotification *)notification
{
    if (notification.object != self.collaborationManager) {
        return;
    }
    
    NSArray<PTCollaborationAnnotation *> *annotations = notification.userInfo[PTCollaborationManagerAnnotationsUserInfoKey];
    if (!annotations) {
        PTLog(@"Received annotation modified notification without annotation objects");
        return;
    }
    
    [self updateAnnotations:annotations];
}

- (void)remoteAnnotationsRemovedWithNotification:(NSNotification *)notification
{
    if (notification.object != self.collaborationManager) {
        return;
    }
    
    NSArray<PTCollaborationAnnotation *> *annotations = notification.userInfo[PTCollaborationManagerAnnotationsUserInfoKey];
    if (!annotations) {
        PTLog(@"Received annotation removed notification without annotation objects");
        return;
    }
    
    [self removeAnnotations:annotations];
}

#pragma mark - NSManagedObjectContext notifications

- (void)objectsDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.dataManager.mainContext) {
        return;
    }
    
    if (!self.document) {
        return;
    }
    
    int32_t unreadCount = self.document.unreadCount;
    
    if (unreadCount != self.previousDocumentUnreadCount) {
        self.previousDocumentUnreadCount = unreadCount;
        
        if ([self.delegate respondsToSelector:@selector(annotationManager:documentUnreadCountDidChange:)]) {
            [self.delegate annotationManager:self documentUnreadCountDidChange:unreadCount];
        }
    }
}

@end
