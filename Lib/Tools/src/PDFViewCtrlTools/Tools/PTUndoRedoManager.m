//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTUndoRedoManager.h"

#import "AnnotTypes.h"
#import "PTToolsUtil.h"

@implementation PTUndoRedoManager

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [super init];
    if (self) {
        _toolManager = toolManager;        
    }
    return self;
}

- (BOOL)isEnabled
{
    @try {
        return [self.toolManager.pdfViewCtrl isUndoRedoEnabled];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    return NO;
}

- (void)undo
{
    if (![self isEnabled]) {
        return;
    }
    
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    @try {
        [pdfViewCtrl CancelRendering];
        [pdfViewCtrl Undo];
        [pdfViewCtrl Update:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        return;
    }
}

- (void)redo
{
    if (![self isEnabled]) {
        return;
    }
    
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    @try {
        [pdfViewCtrl CancelRendering];
        [pdfViewCtrl Redo];
        [pdfViewCtrl Update:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        return;
    }
}

- (void)takeUndoSnapshot:(NSString *)actionInfo
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        [pdfViewCtrl TakeUndoSnapshot:actionInfo];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        return;
    } @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
}

@end

#pragma mark - Annotation change (add, modify, remove) events

@implementation PTUndoRedoManager (PTAnnotationChanges)

- (NSString *)nameForAnnotation:(PTAnnot *)annot
{
    PTExtendedAnnotType annotType = PTExtendedAnnotTypeUnknown;
 
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        annotType = annot.extendedAnnotType;
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }

    NSString *annotName = PTLocalizedAnnotationNameFromType(annotType);
    if (annotName.length == 0) {
        PTLog(@"Failed to get name of annot of type %lu", (unsigned long)annotType);
        annotName = PTLocalizedString(@"Annotation", @"Generic name for an annotation");
    }

    return annotName;
}

- (void)annotationAdded:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *annotationName = [self nameForAnnotation:annotation];
    
    NSString *localizedFormat = PTLocalizedString(@"Add %@ on Page %d",
                                                  @"Add <annotation-type> on Page <page-number>");
    NSString *actionInfo = [NSString localizedStringWithFormat:localizedFormat, annotationName, pageNumber];

    [self takeUndoSnapshot:actionInfo];
    [self registerAnnotationChangeUndoWithActionName:actionInfo];
}

- (void)annotationModified:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;

    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *annotationName = [self nameForAnnotation:annotation];
    
    NSString *localizedFormat = PTLocalizedString(@"Modify %@ on Page %d",
                                                  @"Modify <annotation-type> on Page <page-number>");
    NSString *actionInfo = [NSString localizedStringWithFormat:localizedFormat, annotationName, pageNumber];
    
    [self takeUndoSnapshot:actionInfo];
    [self registerAnnotationChangeUndoWithActionName:actionInfo];
}

- (void)annotationRemoved:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *annotationName = [self nameForAnnotation:annotation];
    
    NSString *localizedFormat = PTLocalizedString(@"Remove %@ on Page %d",
                                                  @"Remove <annotation-type> on Page <page-number>");
    NSString *actionInfo = [NSString localizedStringWithFormat:localizedFormat, annotationName, pageNumber];
    
    [self takeUndoSnapshot:actionInfo];
    [self registerAnnotationChangeUndoWithActionName:actionInfo];
}

- (void)formFieldDataModified:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *localizedFormat = PTLocalizedString(@"Modify Form Field on Page %d",
                                                  @"Modify Form Field on Page <page-number>");
    NSString *actionInfo = [NSString localizedStringWithFormat:localizedFormat, pageNumber];
    
    [self takeUndoSnapshot:actionInfo];
    [self registerAnnotationChangeUndoWithActionName:actionInfo];
}

#pragma mark - Annotation change undo/redo

#pragma mark Registration

- (void)registerAnnotationChangeUndoWithActionName:(nullable NSString *)actionName
{
    // Register an undo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target undoAnnotationChange];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

- (void)registerAnnotationChangeRedoWithActionName:(nullable NSString *)actionName
{
    // Register a redo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target redoAnnotationChange];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

#pragma mark Actions

- (void)undoAnnotationChange
{
    [self undo];
    [self registerAnnotationChangeRedoWithActionName:nil];
}

- (void)redoAnnotationChange
{
    [self redo];
    [self registerAnnotationChangeUndoWithActionName:nil];
}

@end

#pragma mark - Page change (add, move, remove) events

@implementation PTUndoRedoManager (PTPageChanges)

- (void)pageContentModifiedOnPageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *actionInfo = PTLocalizedString(@"Modify Page Content",
                                             @"Undo/redo modify page content");
    
    [self takeUndoSnapshot:actionInfo];
    [self registerPageAddUndoWithActionName:actionInfo];
}

- (void)pageAddedAtPageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *actionInfo = PTLocalizedString(@"Add Page",
                                             @"Undo/redo add page to document");
    
    [self takeUndoSnapshot:actionInfo];
    [self registerPageAddUndoWithActionName:actionInfo];
}

- (void)pageMovedFromPageNumber:(int)oldPageNumber toPageNumber:(int)newPageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *actionInfo = PTLocalizedString(@"Move Page",
                                             @"Undo/redo add page to document");
    
    [self takeUndoSnapshot:actionInfo];
    [self registerPageMoveUndoWithActionName:actionInfo];
}

- (void)pageRemovedForPageNumber:(int)pageNumber
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    if (![self isEnabled] || !pdfViewCtrl) {
        return;
    }
    
    NSString *actionInfo = PTLocalizedString(@"Remove Page",
                                             @"Undo/redo add page to document");
    
    [self takeUndoSnapshot:actionInfo];
    [self registerPageRemoveUndoWithActionName:actionInfo];
}

#pragma mark - Page add undo/redo

#pragma mark Registration

- (void)registerPageAddUndoWithActionName:(nullable NSString *)actionName
{
    // Register an undo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target undoAddPage];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

- (void)registerPageAddRedoWithActionName:(nullable NSString *)actionName
{
    // Register a redo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target redoAddPage];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

#pragma mark Actions

- (void)undoAddPage
{
    [self undo];
    [self.toolManager.pdfViewCtrl UpdatePageLayout];
    [self registerPageAddRedoWithActionName:nil];
}

- (void)redoAddPage
{
    [self redo];
    [self.toolManager.pdfViewCtrl UpdatePageLayout];
    [self registerPageAddUndoWithActionName:nil];
}

#pragma mark - Page move undo/redo

#pragma mark Registration

- (void)registerPageMoveUndoWithActionName:(nullable NSString *)actionName
{
    // Register an undo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target undoMovePage];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

- (void)registerPageMoveRedoWithActionName:(nullable NSString *)actionName
{
    // Register a redo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target redoMovePage];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

#pragma mark Actions

- (void)undoMovePage
{
    [self undo];
    [self.toolManager.pdfViewCtrl UpdatePageLayout];
    [self registerPageMoveRedoWithActionName:nil];
}

- (void)redoMovePage
{
    [self redo];
    [self.toolManager.pdfViewCtrl UpdatePageLayout];
    [self registerPageMoveUndoWithActionName:nil];
}

#pragma mark - Page remove undo/redo

#pragma mark Registration

- (void)registerPageRemoveUndoWithActionName:(nullable NSString *)actionName
{
    // Register an undo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target undoRemovePage];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

- (void)registerPageRemoveRedoWithActionName:(nullable NSString *)actionName
{
    // Register a redo action with the iOS undo manager.
    [self.toolManager.undoManager registerUndoWithTarget:self handler:^(PTUndoRedoManager *target) {
        [target redoRemovePage];
    }];
    if (![self.toolManager.undoManager isUndoing] && actionName) {
        [self.toolManager.undoManager setActionName:actionName];
    }
}

#pragma mark Actions

- (void)undoRemovePage
{
    [self undo];
    [self.toolManager.pdfViewCtrl UpdatePageLayout];
    [self registerPageRemoveRedoWithActionName:nil];
}

- (void)redoRemovePage
{
    [self redo];
    [self.toolManager.pdfViewCtrl UpdatePageLayout];
    [self registerPageRemoveUndoWithActionName:nil];
}

@end
