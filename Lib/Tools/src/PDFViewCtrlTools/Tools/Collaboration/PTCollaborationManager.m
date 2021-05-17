//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTCollaborationManager ()

@property (strong, nonatomic) PTExternalAnnotManager *externalAnnotManager;

@end

NS_ASSUME_NONNULL_END

@implementation PTCollaborationManager

- (instancetype)initWithToolManager:(PTToolManager *)toolManager userId:(NSString *)userId
{
    self = [super initWithToolManager:toolManager userId:userId];
    if (self) {
        _externalAnnotManager = [toolManager.pdfViewCtrl EnableAnnotationManager:userId];
    }
    return self;
}

#pragma mark - XFDF handling

- (NSString *)GetLastXFDFCommand
{
    return [self.externalAnnotManager GetLastXFDF];
}

- (void)mergeInitialXFDFString:(NSString *)xfdfString
{
    [self MergeXFDF:xfdfString];
}

- (void)mergeXFDFString:(NSString *)xfdfString
{
    [self MergeXFDF:xfdfString];
}

- (void)mergeInitialXFDFCommand:(NSString *)xfdfCommand
{
    [self MergeXFDF:xfdfCommand];
}

- (void)mergeXFDFCommand:(NSString *)xfdfCommand
{
    [self MergeXFDF:xfdfCommand];
}

- (void)MergeXFDF:(NSString *)inputXFDF
{
    BOOL shouldUnlock = NO;
    @try {
        [self.toolManager.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        [self.externalAnnotManager MergeXFDF:inputXFDF];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.toolManager.pdfViewCtrl DocUnlock];
        }
    }
}

- (NSString *)exportXFDFStringWithError:(NSError * _Nullable __autoreleasing *)error
{
    __block NSString *xfdfString = nil;
    
    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;
    
    NSError *readError = nil;
    [pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        PTPDFDoc *mainDoc = doc;
        
        PTFDFDoc *mainFDFDoc = [mainDoc FDFExtract:e_ptannots_only];
        
        void * const mainDocImpl = (void *)[[mainDoc GetSDFDoc] GetHandleInternal];

        // Find the TRN_SDFDoc handle for the "extra" doc, which contains all of the external
        // annots.
        void *extraDocImpl = NULL;
        
        const int pageCount = [pdfViewCtrl GetPageCount];
        for (int pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
            NSArray<PTAnnot *> *annots = [pdfViewCtrl GetAnnotationsOnPage:pageNumber];
            for (PTAnnot *annot in annots) {
                if (![annot IsValid]) {
                    continue;
                }
                
                PTObj *annotObj = [annot GetSDFObj];
                if (![annotObj IsValid]) {
                    continue;
                }
                PTSDFDoc *annotDoc = [annotObj GetDoc];
                
                // Check if annot's doc isn't the main doc.
                void *annotDocImpl = (void *)[annotDoc GetHandleInternal];
                if (annotDocImpl != mainDocImpl) {
                    extraDocImpl = annotDocImpl;
                    break;
                }
            }
            if (extraDocImpl != NULL) {
                // Found the extra doc.
                break;
            }
        }
        
        if (extraDocImpl != NULL) {
            // Create a PDFDoc from the extra doc (SDFDoc) reference.
            PTSDFDoc *extraSDFDoc = [PTSDFDoc CreateInternal:(unsigned long long)extraDocImpl];
            [extraSDFDoc setSwigCMemOwn:NO]; // Not owned by ObjC.
            PTPDFDoc *extraDoc = [[PTPDFDoc alloc] initWithSdfdoc:extraSDFDoc];
            
            // Merge in the external annots into the exported doc.
            PTFDFDoc *extraFDFDoc = [extraDoc FDFExtract:e_ptannots_only];
            NSString *extraXFDFString = [extraFDFDoc SaveAsXFDFToString];
            [extraFDFDoc Close];
            
            NSMutableString *mutableXFDFString = [extraXFDFString mutableCopy];
            [mutableXFDFString replaceOccurrencesOfString:@"<annots>"
                                               withString:@"<add>"
                                                  options:(0)
                                                    range:NSMakeRange(0, mutableXFDFString.length)];
            [mutableXFDFString replaceOccurrencesOfString:@"</annots>"
                                               withString:@"</add>"
                                                  options:(0)
                                                    range:NSMakeRange(0, mutableXFDFString.length)];
            NSString *extraXFDFCommand = [mutableXFDFString copy];

            [mainFDFDoc MergeAnnots:extraXFDFCommand permitted_user:@""];
        }
        
        xfdfString = [mainFDFDoc SaveAsXFDFToString];
        
        [mainFDFDoc Close];
    } error:&readError];
    if (readError) {
        if (error) {
            *error = readError;
        }
    }
    
    return xfdfString;
}

@end
