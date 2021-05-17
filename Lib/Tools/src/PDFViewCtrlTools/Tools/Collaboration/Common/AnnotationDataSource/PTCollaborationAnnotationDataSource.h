//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotationManager.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTCollaborationAnnotationDataSource;

typedef NS_ENUM(NSUInteger, PTCollaborationAnnotationSortMode) {
    PTCollaborationAnnotationSortModePageNumber,
    PTCollaborationAnnotationSortModeCreationDate,
    PTCollaborationAnnotationSortModeLastReplyDate,
};

@protocol PTCollaborationAnnotationDataSourceDelegate <NSObject>
@required

- (void)collaborationAnnotationDataSource:(PTCollaborationAnnotationDataSource *)dataSource configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath withAnnotation:(PTManagedAnnotation *)annotation;

- (void)collaborationAnnotationDataSourceDidChangeContent:(PTCollaborationAnnotationDataSource *)dataSource;

@end

@interface PTCollaborationAnnotationDataSource : NSObject <UITableViewDataSource>

- (instancetype)initWithTableView:(UITableView *)tableView;

@property (nonatomic, weak, nullable) UITableView *tableView;

@property (nonatomic, copy, nullable) NSString *cellReuseIdentifier;

@property (nonatomic, assign, getter=isPaused) BOOL paused;

@property (nonatomic, assign) PTCollaborationAnnotationSortMode sortMode;

@property (nonatomic, strong, nullable) PTAnnotationManager *annotationManager;

@property (nonatomic, strong, nullable) PTManagedAnnotation *annotation;

@property (nonatomic, weak, nullable) id<PTCollaborationAnnotationDataSourceDelegate> delegate;

@property (nonatomic, readonly, assign) NSInteger numberOfSections;

- (NSInteger)numberOfAnnotationsInSection:(NSInteger)section;

- (PTManagedAnnotation *)objectAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
