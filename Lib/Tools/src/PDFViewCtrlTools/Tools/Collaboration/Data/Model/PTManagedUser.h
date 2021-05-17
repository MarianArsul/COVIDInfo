//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTManagedObject.h"

#import "PTManagedAnnotation.h"

NS_ASSUME_NONNULL_BEGIN

@class PTManagedAnnotation;

@interface PTManagedUser : PTManagedObject

@property (nonatomic, copy, nullable) NSString *identifier;

@property (nonatomic, copy, nullable) NSString *name;

@property (nonatomic, retain, nullable) NSSet<PTManagedAnnotation *> *annotations;

+ (instancetype)insertUserWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

@interface PTManagedUser (PTFetching)

+ (nullable instancetype)fetchUserWithIdentifier:(NSString *)identifier context:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
