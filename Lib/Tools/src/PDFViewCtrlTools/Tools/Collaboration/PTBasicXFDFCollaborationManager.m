//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBasicXFDFCollaborationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTBasicXFDFCollaborationManager ()
{
    NSString * _Nullable _lastXFDFCommand;
}
@end

NS_ASSUME_NONNULL_END

@implementation PTBasicXFDFCollaborationManager

- (void)didAddlocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    NSError *error = nil;
    _lastXFDFCommand = [self PT_createXFDFCommandForAddedAnnotations:@[annotation]
                                                 modifiedAnnotations:nil
                                                  removedAnnotations:nil
                                                               error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    // Call super implementation as final step.
    [super didAddlocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)willModifyLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    [super willModifyLocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)didModifyLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    NSError *error = nil;
    _lastXFDFCommand = [self PT_createXFDFCommandForAddedAnnotations:nil
                                                 modifiedAnnotations:@[annotation]
                                                  removedAnnotations:nil
                                                               error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }

    // Call super implementation as final step.
    [super didModifyLocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)willRemoveLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    NSError *error = nil;
    _lastXFDFCommand = [self PT_createXFDFCommandForAddedAnnotations:nil
                                                 modifiedAnnotations:nil
                                                  removedAnnotations:@[annotation]
                                                               error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }

    // Call super implementation as final step.
    [super willRemoveLocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)didRemoveLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    [super didRemoveLocalAnnotation:annotation onPageNumber:pageNumber];
}

- (nullable NSString *)PT_createXFDFCommandForAddedAnnotations:(nullable NSArray<PTAnnot *> *)addedAnnotations modifiedAnnotations:(nullable NSArray<PTAnnot *> *)modifiedAnnotations removedAnnotations:(nullable NSArray<PTAnnot *> *)removedAnnotations error:(NSError * _Nullable *)error
{
    __block NSString *xfdfCommand = nil;
    
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    NSError *readError = nil;
    [pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        // Vector of added annotations.
        PTVectorAnnot *addedAnnotationsVector = [[PTVectorAnnot alloc] init];
        for (PTAnnot *addedAnnotation in addedAnnotations) {
            [addedAnnotationsVector add:addedAnnotation];
        }
        // Vector of modified annotations.
        PTVectorAnnot *modifiedAnnotationsVector = [[PTVectorAnnot alloc] init];
        for (PTAnnot *modifiedAnnotation in modifiedAnnotations) {
            [modifiedAnnotationsVector add:modifiedAnnotation];
        }
        // Vector of removed annotations.
        PTVectorAnnot *removedAnnotationsVector = [[PTVectorAnnot alloc] init];
        for (PTAnnot *removedAnnotation in removedAnnotations) {
            [removedAnnotationsVector add:removedAnnotation];
        }
        
        PTFDFDoc *fdfDoc = [doc FDFExtractCommand:addedAnnotationsVector
                                   annot_modified:modifiedAnnotationsVector
                                    annot_deleted:removedAnnotationsVector];
        xfdfCommand = [fdfDoc SaveAsXFDFToString];
        
        [fdfDoc Close];
    } error:&readError];
    if (readError) {
        if (error) {
            *error = readError;
        }
    }

    return xfdfCommand;
}

#pragma mark XFDF

- (NSString *)GetLastXFDFCommand
{
    return _lastXFDFCommand;
}

- (void)mergeInitialXFDFString:(NSString *)xfdfString
{
    NSMutableString *mutableXFDFString = [xfdfString mutableCopy];
    [mutableXFDFString replaceOccurrencesOfString:@"<annots>"
                                       withString:@"<add>"
                                          options:(0)
                                            range:NSMakeRange(0, mutableXFDFString.length)];
    [mutableXFDFString replaceOccurrencesOfString:@"</annots>"
                                       withString:@"</add>"
                                          options:(0)
                                            range:NSMakeRange(0, mutableXFDFString.length)];
    NSString *xfdfCommand = [mutableXFDFString copy];
    
    [self mergeInitialXFDFCommand:xfdfCommand];
}

- (void)mergeXFDFString:(NSString *)xfdfString
{
    NSMutableString *mutableXFDFString = [xfdfString mutableCopy];
    [mutableXFDFString replaceOccurrencesOfString:@"<annots>"
                                       withString:@"<modify>"
                                          options:(0)
                                            range:NSMakeRange(0, mutableXFDFString.length)];
    [mutableXFDFString replaceOccurrencesOfString:@"</annots>"
                                       withString:@"</modify>"
                                          options:(0)
                                            range:NSMakeRange(0, mutableXFDFString.length)];
    NSString *xfdfCommand = [mutableXFDFString copy];
    
    [self mergeXFDFCommand:xfdfCommand];
}

- (void)mergeInitialXFDFCommand:(NSString *)xfdfCommand
{
    [self mergeXFDFCommand:xfdfCommand];
}

- (void)mergeXFDFCommand:(NSString *)xfdfCommand
{
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    NSError *error = nil;
    [pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        
        PTFDFDoc *fdfDoc = [doc FDFExtract:e_ptboth];
        [fdfDoc MergeAnnots:xfdfCommand permitted_user:@""];
        [doc FDFUpdate:fdfDoc];
        
        [pdfViewCtrl Update:YES];
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
}

- (NSString *)exportXFDFStringWithError:(NSError * _Nullable __autoreleasing *)error
{
    __block NSString *xfdfString = nil;
    
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    NSError *readError = nil;
    [pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        PTFDFDoc *fdfDoc = [doc FDFExtract:e_ptannots_only];
        xfdfString = [fdfDoc SaveAsXFDFToString];
        
        [fdfDoc Close];
    } error:&readError];
    if (readError) {
        if (error) {
            *error = readError;
        }
    }
    
    return xfdfString;
}

@end
