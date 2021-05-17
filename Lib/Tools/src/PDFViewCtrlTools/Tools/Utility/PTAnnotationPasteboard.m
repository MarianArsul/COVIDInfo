//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationPasteboard.h"

#import "PTErrors.h"
#import "PTAnnot+PTAdditions.h"
#import "PTPDFRect+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationPasteboard ()

// The temp document where the copied annotations are stored (in memory).
@property (nonatomic, strong, nullable) PTPDFDoc *tempDoc;

// Re-declare as readwrite internally.
@property (nonatomic, readwrite, copy, nullable) NSArray<PTAnnot *> *annotations;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotationPasteboard

#pragma mark - defaultPasteboard

static PTAnnotationPasteboard *PTAnnotationPasteboard_defaultPasteboard;

+ (PTAnnotationPasteboard *)defaultPasteboard
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PTAnnotationPasteboard_defaultPasteboard = [[self alloc] init];
    });
    return PTAnnotationPasteboard_defaultPasteboard;
}

#pragma mark - Copy/paste

- (void)copyAnnotations:(NSArray<PTAnnot *> *)annotations withPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl fromPageNumber:(int)pageNumber completion:(void (^)(void))completion
{
    PTPDFDoc *tempDoc = self.tempDoc;
    if (!tempDoc) {
        tempDoc = [[PTPDFDoc alloc] init];
        self.tempDoc = tempDoc;
    }
    self.sourcePageNumber = pageNumber;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error = nil;
        NSArray<PTAnnot *> *copiedAnnotations = [self PT_copyAnnotations:annotations
                                                         withPDFViewCtrl:pdfViewCtrl
                                                                   toDoc:tempDoc
                                                                   error:&error];
        
        NSArray<NSString *> *extractedContents = nil;
        if (!error) {
            extractedContents = [self PT_extractTextFromAnnotations:annotations
                                                    withPDFViewCtrl:pdfViewCtrl
                                                              error:&error];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"An error occurred while copying annotations: %@", error);
            }
            
            self.annotations = copiedAnnotations;
            
            if (extractedContents.count > 0) {
                UIPasteboard.generalPasteboard.strings = extractedContents;
            }
            
            if (completion) {
                completion();
            }
        });
    });
}

- (void)pasteAnnotationsOnPageNumber:(int)pageNumber atPagePoint:(PTPDFPoint *)pagePoint withPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl completion:(void (^ _Nullable)(NSArray<PTAnnot *> * _Nullable pastedAnnotations, NSError * _Nullable error))completion
{
    NSArray<PTAnnot *> *annotations = self.annotations;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error = nil;
        NSArray<PTAnnot *> *pastedAnnotations = [self PT_pasteAnnotations:annotations
                                                             onPageNumber:pageNumber
                                                              atPagePoint:pagePoint
                                                          withPDFViewCtrl:pdfViewCtrl
                                                                    error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"An error occurred while pasting annotations: %@", error);
            }
            
            if (pastedAnnotations.count > 0) {
                for (PTAnnot *annot in pastedAnnotations) {
                    @try {
                        [pdfViewCtrl UpdateWithAnnot:annot page_num:pageNumber];
                    }
                    @catch (NSException *exception) {
                        // Ignored.
                    }
                }
            }
            
            if (completion) {
                completion(pastedAnnotations, error);
            }
        });
    });
}

- (void)pasteAnnotationsOnPageNumber:(int)pageNumber atPagePoint:(PTPDFPoint *)pagePoint withToolManager:(PTToolManager *)toolManager completion:(void (^)(NSArray<PTAnnot *> * _Nullable, NSError * _Nullable))completion
{
    [self pasteAnnotationsOnPageNumber:pageNumber atPagePoint:pagePoint withPDFViewCtrl:toolManager.pdfViewCtrl completion:^(NSArray<PTAnnot *> * _Nullable pastedAnnotations, NSError * _Nullable error) {
        // Notify tool manager of pasted/added annotations.
        if (pastedAnnotations.count > 0) {
            for (PTAnnot *annot in pastedAnnotations) {
                [toolManager annotationAdded:annot onPageNumber:pageNumber];
            }
        }
        
        if (completion) {
            completion(pastedAnnotations, error);
        }
    }];
}

- (void)clear
{
    self.annotations = nil;

    @try {
        [self.tempDoc Close];
    }
    @catch (NSException *exception) {
        // Ignored.
    }
    self.tempDoc = nil;
}

#pragma mark - Private

#pragma mark Copy

- (nullable NSArray<PTAnnot *> *)PT_copyAnnotations:(NSArray<PTAnnot *> *)annotations withPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl toDoc:(PTPDFDoc *)destinationDoc error:(NSError **)error
{
    if (annotations.count == 0) {
        return nil;
    }
    
    NSMutableArray<PTAnnot *> *copiedAnnotations = [NSMutableArray array];
    CGRect unionRect = CGRectNull;
    
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTVectorObj *annotsVector = [[PTVectorObj alloc] init];
        PTVectorObj *excludeListVector = [[PTVectorObj alloc] init];
        for (PTAnnot *annot in annotations) {
            if (![annot IsValid]) {
                continue;
            }
            PTObj *annotObj = [annot GetSDFObj];
            [annotsVector add:annotObj];
            
            PTObj *pageObj = [annotObj FindObj:@"P"];
            if ([pageObj IsValid]) {
                [excludeListVector add:pageObj];
            }
        }

        PTSDFDoc *destinationSDFDoc = [destinationDoc GetSDFDoc];
        PTVectorObj *importedAnnotsVector = [destinationSDFDoc ImportObjsWithExcludeList:annotsVector
                                                                            exclude_list:excludeListVector];
        const int importedAnnotsSize = (int)[importedAnnotsVector size];
        for (int i = 0; i < importedAnnotsSize; i++) {
            PTObj *importedAnnotObj = [importedAnnotsVector get:i];
            PTAnnot *importedAnnot = [[PTAnnot alloc] initWithD:importedAnnotObj];
            if (![importedAnnot IsValid]) {
                continue;
            }
            
            PTPDFRect *annotRect = [importedAnnot GetRect];
            [annotRect Normalize];
            CGRect annotCGRect = annotRect.CGRectValue;
            
            if (CGRectIsNull(unionRect)) {
                unionRect = annotCGRect;
            }
            else {
                unionRect = CGRectUnion(unionRect, annotCGRect);
            }
            
            [copiedAnnotations addObject:importedAnnot];
        }
    }
    @catch (NSException *exception) {
        if (error) {
            *error = exception.pt_error;
        }
        return nil;
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }
    
    return [copiedAnnotations copy];
}

- (nullable NSArray<NSString *> *)PT_extractTextFromAnnotations:(NSArray<PTAnnot *> *)annotations withPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl error:(NSError **)error
{
    NSMutableArray<NSString *> *extractedText = [NSMutableArray array];
    
    [pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        for (PTAnnot *annot in annotations) {
            if (![annot IsValid]) {
                continue;
            }
            
            // Check if this annotation's contents should be extracted.
            if (![self PT_shouldExtractTextForAnnotation:annot]) {
                continue;
            }
            
            NSString *contents = [annot GetContents];
            if (contents.length > 0) {
                [extractedText addObject:contents];
            }
        }
    } error:error];
    
    if (error && *error) {
        // An error occurred.
        return nil;
    }
    
    return [extractedText copy];
}

- (BOOL)PT_shouldExtractTextForAnnotation:(PTAnnot *)annotation
{
    switch (annotation.extendedAnnotType) {
        case PTExtendedAnnotTypeFreeText:
            return YES;
            
        default:
            return NO;
    }
}

#pragma mark Paste

- (nullable NSArray<PTAnnot *> *)PT_pasteAnnotations:(NSArray<PTAnnot *> *)annotations onPageNumber:(int)pageNumber atPagePoint:(PTPDFPoint *)pagePoint withPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl error:(NSError ** _Nullable)error
{
    if (annotations.count == 0) {
        return nil;
    }
    
    NSArray<PTAnnot *> *pastedAnnotations = nil;
    
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPDFDoc *destinationDoc = [pdfViewCtrl GetDoc];
        PTSDFDoc *destinationSDFDoc = [destinationDoc GetSDFDoc];
        
        NSMutableArray<PTAnnot *> *mutablePastedAnnotations = [NSMutableArray array];
        CGRect annotUnionRect = CGRectNull;
        
        for (PTAnnot *annot in annotations) {
            if (![annot IsValid]) {
                continue;
            }
            
            PTObj *annotObj = [annot GetSDFObj];
            
            PTObj *destAnnotObj = [destinationSDFDoc ImportObj:annotObj deep_copy:YES];
            PTAnnot *destAnnot = [[PTAnnot alloc] initWithD:destAnnotObj];
            
            if( [destAnnot IsMarkup] )
            {
                NSAssert([pdfViewCtrl.toolDelegate isKindOfClass:[PTToolManager class]], @"Must be a tool manager.");
                if( [pdfViewCtrl.toolDelegate isKindOfClass:[PTToolManager class]] )
                {
                    PTToolManager* toolManger = (PTToolManager*)(pdfViewCtrl.toolDelegate);
                    if( toolManger.annotationAuthor )
                    {
                        PTMarkup* markup = [[PTMarkup alloc] initWithAnn:destAnnot];
                        [markup SetTitle:toolManger.annotationAuthor];
                    }
                }
            }
            
            [mutablePastedAnnotations addObject:destAnnot];
            
            // Give the pasted annotation a new unique identifier.
            destAnnot.uniqueID = [NSUUID UUID].UUIDString;
            
            PTPDFRect *destAnnotRect = [destAnnot GetRect];
            [destAnnotRect Normalize];
            CGRect destAnnotCGRect = destAnnotRect.CGRectValue;
            
            if (CGRectIsNull(annotUnionRect)) {
                annotUnionRect = destAnnotCGRect;
            } else {
                annotUnionRect = CGRectUnion(annotUnionRect, destAnnotCGRect);
            }
        }
        pastedAnnotations = [mutablePastedAnnotations copy];
                
        PTPage *page = [destinationDoc GetPage:pageNumber];
        PTPDFRect *cropBox = [page GetBox:e_ptcrop];
        [cropBox Normalize];
        
        // Ensure that the annotation union rect is non-null.
        if (CGRectIsNull(annotUnionRect)) {
            // Use the page's crop box.
            annotUnionRect = cropBox.CGRectValue;
        }
        
        CGPoint targetPoint = CGPointMake([pagePoint getX], [pagePoint getY]);
        
        // Bound the target point:
        // Right edge.
        if ((targetPoint.x + (CGRectGetWidth(annotUnionRect) / 2.0)) > [cropBox GetX2]) {
            targetPoint.x = [cropBox GetX2] - (CGRectGetWidth(annotUnionRect) / 2.0);
        }
        // Left edge.
        if ((targetPoint.x - (CGRectGetWidth(annotUnionRect) / 2.0)) < [cropBox GetX1]) {
            targetPoint.x = [cropBox GetX1] + (CGRectGetWidth(annotUnionRect) / 2.0);
        }
        // Top edge.
        if ((targetPoint.y + (CGRectGetHeight(annotUnionRect) / 2.0)) > [cropBox GetY2]) {
            targetPoint.y = [cropBox GetY2] - (CGRectGetHeight(annotUnionRect) / 2.0);
        }
        // Bottom edge.
        if ((targetPoint.y - (CGRectGetHeight(annotUnionRect) / 2.0)) < [cropBox GetY1]) {
            targetPoint.y = [cropBox GetY1] + (CGRectGetHeight(annotUnionRect) / 2.0);
        }
        
        // Adjust all annot rects for the union rect & target point.
        for (PTAnnot *annot in pastedAnnotations) {
            if (![annot IsValid]) {
                continue;
            }
            
            PTPDFRect *boundingBox = [annot GetRect];
            [boundingBox Normalize];
            
            // Calculate new annot bounding box.
            CGVector displacement = CGVectorMake([boundingBox GetX1] - CGRectGetMinX(annotUnionRect),
                                                 [boundingBox GetY1] - CGRectGetMinY(annotUnionRect));
            
            CGPoint origin = CGPointMake(targetPoint.x - (CGRectGetWidth(annotUnionRect) / 2.0) + displacement.dx,
                                         targetPoint.y - (CGRectGetHeight(annotUnionRect) / 2.0) + displacement.dy);
            
            PTPDFRect *annotDestRect = [[PTPDFRect alloc] initWithX1:origin.x
                                                                  y1:origin.y
                                                                  x2:(origin.x + [boundingBox Width])
                                                                  y2:(origin.y + [boundingBox Height])];
            
            // Add annot to page and resize.
            [page AnnotPushBack:annot];
            [annot Resize:annotDestRect];
            
            if ([annot GetType] == e_ptFreeText) {
                PTRotate pageRotation = [page GetRotation];
                PTRotate viewRotation = pdfViewCtrl.rotation;
                int annotRotation = ((pageRotation + viewRotation) % 4) * 90;
                [annot SetRotation:annotRotation];
            }
        }
    }
    @catch (NSException *exception) {
        if (error) {
            *error = exception.pt_error;
        }
        return nil;
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
    
    return pastedAnnotations;
}

@end
