//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTToolManager.h"
#import "PTBaseCollaborationManager.h"

#import "PTManagedDocument.h"
#import "PTManagedAnnotation.h"

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotationManager;

@protocol PTAnnotationManagerDelegate <NSObject>
@optional

- (void)annotationManager:(PTAnnotationManager *)annotationManager documentUnreadCountDidChange:(int)unreadCount;

@end

@interface PTAnnotationManager : NSObject

- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager;

@property (nonatomic, weak, nullable) PTBaseCollaborationManager *collaborationManager;

@property (nonatomic, weak, nullable) id<PTAnnotationManagerDelegate> delegate;

@property (nonatomic, nullable, copy) NSString *documentIdentifier;

@property (nonatomic, nullable, copy) NSString *userIdentifier;

@property (nonatomic, nullable, copy) NSString *currentAnnotationIdentifier;

#pragma mark - Fetching

- (nullable PTManagedAnnotation *)managedAnnotationForAnnot:(PTAnnot *)annot;

- (nullable PTManagedAnnotation *)managedAnnotationForAnnotationIdentifier:(NSString *)annotationIdentifier;

- (NSFetchRequest<PTManagedAnnotation *> *)fetchRequestForDocumentAnnotations;

- (NSFetchRequest<PTManagedAnnotation *> *)fetchRequestForAnnotationReplies:(PTManagedAnnotation *)annotation;

- (NSFetchedResultsController<PTManagedAnnotation *> *)fetchedResultsControllerForDocumentAnnotationsSortedByKeyPath:(NSString *)keyPath;
- (NSFetchedResultsController<PTManagedAnnotation *> *)fetchedResultsControllerForAnnotationReplies:(PTManagedAnnotation *)annotation;

- (NSFetchedResultsController<PTManagedAnnotation *> *)fetchedResultsControllerWithFetchRequest:(NSFetchRequest<PTManagedAnnotation *> *)fetchRequest sectionNameKeyPath:(NSString *)sectionNameKeyPath;

@end

NS_ASSUME_NONNULL_END
