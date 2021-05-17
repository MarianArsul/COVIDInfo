//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationAnnotationDataSource.h"

#import "PTToolsUtil.h"

#import "PTPDFViewCtrl+PTAdditions.h"

#import <CoreData/CoreData.h>

@interface PTCollaborationAnnotationDataSource () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController<PTManagedAnnotation *> *fetchedResultsController;

@end

@implementation PTCollaborationAnnotationDataSource

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        _tableView = tableView;
        _tableView.dataSource = self;
        
        _paused = YES;
    }
    return self;
}

- (void)setPaused:(BOOL)paused
{
    if (_paused == paused) {
        // No change.
        return;
    }
    
    _paused = paused;
    
    if (paused) {
        // Disable change tracking.
        self.fetchedResultsController.delegate = nil;
    } else {
        // (Re)enable change tracking.
        self.fetchedResultsController.delegate = self;
        
        NSError *fetchError = nil;
        if (![self.fetchedResultsController performFetch:&fetchError]) {
            NSLog(@"Fetched results controller fetch failed: %@", fetchError);
        }
        [self.tableView reloadData];
        
        const id<PTCollaborationAnnotationDataSourceDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(collaborationAnnotationDataSourceDidChangeContent:)]) {
            [delegate collaborationAnnotationDataSourceDidChangeContent:self];
        }
    }
}

- (void)setAnnotationManager:(PTAnnotationManager *)annotationManager
{
    _annotationManager = annotationManager;
    
    if (annotationManager) {
        [self loadFetchedResultsController];
    }
}

- (void)setAnnotation:(PTManagedAnnotation *)annotation
{
    if (_annotation == annotation) {
        // No change.
        return;
    }
    
    _annotation = annotation;
    
    if (self.annotationManager) {
        [self loadFetchedResultsController];
    }
}

- (void)setSortMode:(PTCollaborationAnnotationSortMode)sortMode
{
    if (_sortMode == sortMode) {
        // No change.
        return;
    }
    
    _sortMode = sortMode;
    
    // Reload fetched results controller.
    [self loadFetchedResultsController];
}

- (NSString *)sectionKeyPathForSortMode:(PTCollaborationAnnotationSortMode)sortMode
{
    switch (sortMode) {
        case PTCollaborationAnnotationSortModePageNumber:
            return PT_CLASS_KEY(PTManagedAnnotation, pageNumber);
        case PTCollaborationAnnotationSortModeCreationDate:
            return PT_CLASS_KEY(PTManagedAnnotation, creationDateDaySectionIdentifier);
        case PTCollaborationAnnotationSortModeLastReplyDate:
            return PT_CLASS_KEY(PTManagedAnnotation, lastReplyDateDaySectionIdentifier);
    }
}

- (void)loadFetchedResultsController
{
    if (self.annotation) {
        self.fetchedResultsController = [self.annotationManager fetchedResultsControllerForAnnotationReplies:self.annotation];
        
        // Prefetch annotation authors.
        self.fetchedResultsController.fetchRequest.relationshipKeyPathsForPrefetching =
        @[PT_CLASS_KEY(PTManagedAnnotation, author)];
    } else {
        NSFetchRequest<PTManagedAnnotation *> *request = [self.annotationManager fetchRequestForDocumentAnnotations];
        
        // Set the fetch request's sort descriptor(s) based on the current sort mode.
        switch (self.sortMode) {
            case PTCollaborationAnnotationSortModePageNumber:
            {
                request.sortDescriptors =
                @[
                  // Page number, ascending (smallest first).
                  [NSSortDescriptor sortDescriptorWithKey:PT_CLASS_KEY(PTManagedAnnotation, pageNumber)
                                                ascending:YES],
                  // Creation date, ascending (oldest first).
                  [NSSortDescriptor sortDescriptorWithKey:PT_CLASS_KEY(PTManagedAnnotation, creationDate)
                                                ascending:YES],
                  ];
            }
                break;
            case PTCollaborationAnnotationSortModeCreationDate:
            {
                request.sortDescriptors =
                @[
                  // Creation date, descending (most recent first).
                  [NSSortDescriptor sortDescriptorWithKey:PT_CLASS_KEY(PTManagedAnnotation, creationDate)
                                                ascending:NO],
                  ];
            }
                break;
            case PTCollaborationAnnotationSortModeLastReplyDate:
            {
                request.sortDescriptors =
                @[
                  // Last reply date, descending (most recent first).
                  [NSSortDescriptor sortDescriptorWithKey:PT_CLASS_KEY(PTManagedAnnotation, lastReplyDate)
                                                ascending:NO],
                  ];
            }
                break;
        }
        
        NSString *sectionKeyPath = [self sectionKeyPathForSortMode:self.sortMode];
        
        self.fetchedResultsController = [self.annotationManager fetchedResultsControllerForDocumentAnnotationsSortedByKeyPath:sectionKeyPath];
        
        self.fetchedResultsController = [self.annotationManager fetchedResultsControllerWithFetchRequest:request
                                                                                      sectionNameKeyPath:sectionKeyPath];
    }
    
    if (![self isPaused]) {
        // Enable change tracking.
        self.fetchedResultsController.delegate = self;
        
        NSError *fetchError = nil;
        if (![self.fetchedResultsController performFetch:&fetchError]) {
            NSLog(@"Fetched results controller fetch failed: %@", fetchError);
        }
        [self.tableView reloadData];
        
        const id<PTCollaborationAnnotationDataSourceDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(collaborationAnnotationDataSourceDidChangeContent:)]) {
            [delegate collaborationAnnotationDataSourceDidChangeContent:self];
        }
    }
}

#pragma mark - Public API

- (NSInteger)numberOfSections
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)numberOfAnnotationsInSection:(NSInteger)section
{
    return self.fetchedResultsController.sections[section].numberOfObjects;
}

- (PTManagedAnnotation *)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    PTManagedAnnotation *annotation = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([self.delegate respondsToSelector:@selector(collaborationAnnotationDataSource:configureCell:forIndexPath:withAnnotation:)]) {
        [self.delegate collaborationAnnotationDataSource:self configureCell:cell forIndexPath:indexPath withAnnotation:annotation];
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fetchedResultsController.sections[section].numberOfObjects;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.fetchedResultsController.sectionNameKeyPath isEqualToString:PT_CLASS_KEY(PTManagedAnnotation, pageNumber)]) {
        // Format page number section title.
        NSString *pageNumberString = self.fetchedResultsController.sections[section].name;
        
        NSString *localizedFormat = PTLocalizedString(@"Page %@", @"Page <page-number>");
        return [NSString localizedStringWithFormat:localizedFormat, pageNumberString];
    }
    
    return self.fetchedResultsController.sections[section].name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseIdentifier forIndexPath:indexPath];
 
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *currentAuthor = self.annotationManager.collaborationManager.toolManager.annotationAuthor;
    if (currentAuthor.length == 0) {
        NSLog(@"Cannot determine if row can be edited: no current annotation author");
        return NO;
    }
    
    PTManagedAnnotation *annotation = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *annotationAuthor = annotation.author.identifier;
    if (annotationAuthor.length == 0) {
        NSLog(@"Cannot determine if row can be edited: annotation missing author identifier");
        return NO;
    }
    
    return [currentAuthor isEqualToString:annotationAuthor];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PTToolManager *toolManager = self.annotationManager.collaborationManager.toolManager;
        PTPDFViewCtrl *pdfViewCtrl = toolManager.pdfViewCtrl;
        
        PTManagedAnnotation *annotation = [self.fetchedResultsController objectAtIndexPath:indexPath];
        int pageNumber = annotation.pageNumber;

        PTAnnot *annot = [pdfViewCtrl findAnnotWithUniqueID:annotation.identifier
                                               onPageNumber:pageNumber];
        
        if (annot) {
            BOOL shouldUnlock = NO;
            @try {
                [pdfViewCtrl DocLock:YES];
                shouldUnlock = YES;
                
                PTPage *page = [[pdfViewCtrl GetDoc] GetPage:pageNumber];
                if ([page IsValid]) {
                    [page AnnotRemoveWithAnnot:annot];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"Exception: %@, %@", exception.name, exception.reason);
            }
            @finally {
                if (shouldUnlock) {
                    [pdfViewCtrl DocUnlock];
                }
            }
            
            [pdfViewCtrl UpdateWithAnnot:annot page_num:pageNumber];
            
            [toolManager annotationRemoved:annot onPageNumber:pageNumber];
        }
    }
}

#pragma mark - <NSFetchedResultsControllerDelegate>

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    
    const id<PTCollaborationAnnotationDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(collaborationAnnotationDataSourceDidChangeContent:)]) {
        [delegate collaborationAnnotationDataSourceDidChangeContent:self];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                [self configureCell:cell atIndexPath:indexPath];
            }
            break;
        }
        default:
            break;
    }
}

@end
