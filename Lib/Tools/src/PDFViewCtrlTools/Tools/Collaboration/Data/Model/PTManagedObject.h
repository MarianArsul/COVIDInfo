//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTManagedObject : NSManagedObject

@property (nonatomic, class, readonly, copy) NSString *entityName;

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

NS_ASSUME_NONNULL_END
