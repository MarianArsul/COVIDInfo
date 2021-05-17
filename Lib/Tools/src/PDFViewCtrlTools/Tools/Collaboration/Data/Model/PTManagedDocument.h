//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTManagedAnnotation.h"
#import "PTManagedObject.h"

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PTManagedAnnotation;

NS_ASSUME_NONNULL_BEGIN

@interface PTManagedDocument : PTManagedObject

@property (nonatomic, copy, nullable) NSString *identifier;

@property (nonatomic) int32_t unreadCount;

@property (nonatomic, retain, nullable) NSSet<PTManagedAnnotation *> *annotations;

+ (instancetype)insertDocumentWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

@interface PTManagedDocument (AnnotationsAccessors)

- (void)addAnnotationsObject:(PTManagedAnnotation *)value;
- (void)removeAnnotationsObject:(PTManagedAnnotation *)value;
- (void)addAnnotations:(NSSet<PTManagedAnnotation *> *)values;
- (void)removeAnnotations:(NSSet<PTManagedAnnotation *> *)values;

@end

@interface PTManagedDocument (PTFetching)

- (nullable PTManagedAnnotation *)fetchAnnotationWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
