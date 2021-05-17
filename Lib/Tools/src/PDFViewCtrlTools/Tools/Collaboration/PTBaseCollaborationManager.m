//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBaseCollaborationManager.h"
#import "PTBaseCollaborationManager+Private.h"

#import "PTAnnotationManager.h"
#import "PTErrors.h"
#import "PTToolsUtil.h"
#import "PTPanTool.h"
#import "PTAnnotEditTool.h"

#import "PTAnnot+PTAdditions.h"
#import "PTFDFDoc+PTAdditions.h"
#import "PTPDFViewCtrl+PTAdditions.h"
#import "UIView+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Notification names

// Notification name values are equal to their constant's name.
const NSNotificationName PTCollaborationManagerRemoteAnnotationsAddedNotification = PT_NS_STRINGIFY(PTCollaborationManagerRemoteAnnotationsAddedNotification);
const NSNotificationName PTCollaborationManagerRemoteAnnotationsModifiedNotification = PT_NS_STRINGIFY(PTCollaborationManagerRemoteAnnotationsModifiedNotification);
const NSNotificationName PTCollaborationManagerRemoteAnnotationsRemovedNotification = PT_NS_STRINGIFY(PTCollaborationManagerRemoteAnnotationsRemovedNotification);

#pragma mark - Notification user info keys

// User info key values are equal to their constant's name.
NSString * const PTCollaborationManagerAnnotationsUserInfoKey = PT_NS_STRINGIFY(PTCollaborationManagerAnnotationsUserInfoKey);

NSString * const PTCollaborationManagerIsInitialUserInfoKey = PT_NS_STRINGIFY(PTCollaborationManagerIsInitialUserInfoKey);

@interface PTBaseCollaborationManager () <NSXMLParserDelegate>

@property (nonatomic, strong, nullable) id<PTCollaborationServerCommunication> server;

@property (nonatomic, assign, getter=isMergingXFDF) BOOL mergingXFDF;
@property (nonatomic, assign, getter=isInDeleteArray) BOOL inDeleteArray;
@property (nonatomic, assign, getter=isInIdElement) BOOL inIdElement;
@property (nonatomic, copy, nullable) NSArray<NSString *> *annotIdsToDelete;
@property (nonatomic, assign, getter=isUpdatingOptimisticLocalAnnotations) BOOL updatingOptimisticLocalAnnotations;

@end

NS_ASSUME_NONNULL_END

@implementation PTBaseCollaborationManager

- (instancetype)initWithToolManager:(PTToolManager *)toolManager userId:(NSString *)userId
{
    self = [super init];
    if (self) {
        _toolManager = toolManager;
        
        toolManager.annotationAuthor = userId;
        
        // Register with tool manager annotation notifications.
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserver:self
                   selector:@selector(localAnnotationAdded:)
                       name:PTToolManagerAnnotationAddedNotification
                     object:toolManager];
        
        [center addObserver:self
                   selector:@selector(localAnnotationWillModify:)
                       name:PTToolManagerAnnotationWillModifyNotification
                     object:toolManager];
        [center addObserver:self
                   selector:@selector(localAnnotationModified:)
                       name:PTToolManagerAnnotationModifiedNotification
                     object:toolManager];
        
        [center addObserver:self
                   selector:@selector(localAnnotationWillRemove:)
                       name:PTToolManagerAnnotationWillRemoveNotification
                     object:toolManager];
        [center addObserver:self
                   selector:@selector(localAnnotationRemoved:)
                       name:PTToolManagerAnnotationRemovedNotification
                     object:toolManager];
        
        _annotationManager = [[PTAnnotationManager alloc] initWithCollaborationManager:self];
    }
    return self;
}

//// bi-directional relationship. Collab manager owns the server, server has weak reference to collabManager
- (void)registerServerCommunicationComponent:(id<PTCollaborationServerCommunication>)server
{
    self.server = server;
    
    [self.server setCollaborationManager:self];
    
    self.annotationManager.documentIdentifier = server.documentID;
    self.annotationManager.userIdentifier = server.userID;
}

// Get the unique ID for the given annotation.
- (nullable NSString *)identifierForAnnot:(PTAnnot *)annot error:(NSError * _Nullable *)error
{
    BOOL shouldUnlock = NO;
    @try {
        [self.toolManager.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        if (![annot IsValid]) {
            if (error) {
                *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                          @{
                              NSLocalizedDescriptionKey: @"Invalid annotation",
                              NSLocalizedFailureReasonErrorKey: @"The given annotation is not valid",
                          }];
            }
            return nil;
        }
        
        PTObj *uniqueIDObj = [annot GetUniqueID];
        if (![uniqueIDObj IsValid] || ![uniqueIDObj IsString]) {
            
            if( [annot GetType] == e_ptWidget )
            {
                PTWidget* widget = [[PTWidget alloc] initWithAnn:annot];
                
                NSString* fieldID = [[widget GetField] GetName];
                
                return fieldID;
            }
            
            else if (error) {
                *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                          @{
                              NSLocalizedDescriptionKey: @"Invalid annotation unique ID",
                              NSLocalizedFailureReasonErrorKey: @"The given annotation does not have a valid unique ID",
                          }];
            }
            return nil;
        }
        
        return [uniqueIDObj GetAsPDFText];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:PTErrorDomain code:0 userInfo:
                      @{
                          NSLocalizedDescriptionKey: @"Failed to get annotation unique ID",
                          NSLocalizedFailureReasonErrorKey: @"The annotation unique ID could not be determined",
                          NSUnderlyingErrorKey: exception.pt_error,
                      }];
        }
        return nil;
    }
    @finally {
        if (shouldUnlock) {
            [self.toolManager.pdfViewCtrl DocUnlockRead];
        }
    }
    
    return nil;
}

- (nullable NSString *)authorForAnnot:(PTAnnot *)annot
{
    BOOL shouldUnlock = NO;
    @try {
        [self.toolManager.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        if (![annot IsValid]) {
            return nil;
        }
        else if (![annot IsMarkup]) {
            return nil;
        }
        
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];
        return [markup GetTitle];
    }
    @catch (NSException *exception) {
        return nil;
    }
    @finally {
        if (shouldUnlock) {
            [self.toolManager.pdfViewCtrl DocUnlockRead];
        }
    }
    
    return nil;
}

- (NSArray<PTAnnot *> *)selectedAnnotations
{
    NSMutableArray<PTAnnot *> *annots = [NSMutableArray array];
    if ([self.toolManager.tool isKindOfClass:[PTAnnotEditTool class]]) {
        PTAnnotEditTool *annotEdit = (PTAnnotEditTool *)self.toolManager.tool;
        if (annotEdit.selectedAnnotations.count > 0) {
            [annots addObjectsFromArray:annotEdit.selectedAnnotations];
        }
    } else if (self.toolManager.tool.currentAnnotation) {
        [annots addObject:self.toolManager.tool.currentAnnotation];
    }
    return [annots copy];
}

- (NSArray<NSString *> *)selectedAnnotationIdentifiers
{
    NSArray<PTAnnot *> *selectedAnnotations = [self selectedAnnotations];
    
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    for (PTAnnot *annot in selectedAnnotations) {
        NSError *error = nil;
        NSString *identifier = [self identifierForAnnot:annot
                                                  error:&error];
        if (identifier) {
            [identifiers addObject:identifier];
        } else {
            NSLog(@"Failed to get annotation unique ID: %@", error);
        }
    }
    return [identifiers mutableCopy];
}

- (NSString *)sanitizeXFDFCommand:(NSString *)xfdfCommand
{
    NSMutableString *mutableXFDFCommand = [xfdfCommand mutableCopy];
    
    NSString *xmlStart = @"<?xml";
    
    if (![mutableXFDFCommand hasPrefix:xmlStart]) {
        NSString *xfdfStart = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<xfdf xmlns=\"http://ns.adobe.com/xfdf/\" xml:space=\"preserve\">";
        
        [mutableXFDFCommand insertString:xfdfStart atIndex:0];
    }
    
    NSString *xfdfEnd = @"</xfdf>";
    
    if (![mutableXFDFCommand hasSuffix:xfdfEnd]) {
        [mutableXFDFCommand appendString:xfdfEnd];
    }
    
    return [mutableXFDFCommand copy];
}

- (BOOL)isAnnotStylePickerShowing
{
    UIViewController *viewController = self.toolManager.tool.pt_viewController;
    if (!viewController) {
        return NO;
    }
    
    UIViewController *presented = viewController.presentedViewController;
    if ([presented isKindOfClass:[PTAnnotStyleViewController class]]) {
        return YES;
    }
    return NO;
}

#pragma mark - Tool manager notifications for local changes

- (void)localAnnotationAdded:(NSNotification *)notification
{
    // Check notification object.
    if (notification.object != self.toolManager) {
        return;
    }
    NSDictionary<NSString *, id> *userInfo = notification.userInfo;
    
    PTAnnot *annotation = userInfo[PTToolManagerAnnotationUserInfoKey];
    const int pageNumber = ((NSNumber *)userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    [self didAddlocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)localAnnotationWillModify:(NSNotification *)notification
{
    // Check notification object.
    if (notification.object != self.toolManager) {
        return;
    }
    NSDictionary<NSString *, id> *userInfo = notification.userInfo;
    
    PTAnnot *annotation = userInfo[PTToolManagerAnnotationUserInfoKey];
    const int pageNumber = ((NSNumber *)userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    [self willModifyLocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)localAnnotationModified:(NSNotification *)notification
{
    // Check notification object.
    if (notification.object != self.toolManager) {
        return;
    }
    NSDictionary<NSString *, id> *userInfo = notification.userInfo;
    
    PTAnnot *annotation = userInfo[PTToolManagerAnnotationUserInfoKey];
    const int pageNumber = ((NSNumber *)userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;

    [self didModifyLocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)localAnnotationWillRemove:(NSNotification *)notification
{
    // Check notification object.
    if (notification.object != self.toolManager) {
        return;
    }
    NSDictionary<NSString *, id> *userInfo = notification.userInfo;

    PTAnnot *annotation = userInfo[PTToolManagerAnnotationUserInfoKey];
    const int pageNumber = ((NSNumber *)userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    [self willRemoveLocalAnnotation:annotation onPageNumber:pageNumber];
}

- (void)localAnnotationRemoved:(NSNotification *)notification
{
    // Check notification object.
    if (notification.object != self.toolManager) {
        return;
    }
    NSDictionary<NSString *, id> *userInfo = notification.userInfo;
    
    PTAnnot *annotation = userInfo[PTToolManagerAnnotationUserInfoKey];
    const int pageNumber = ((NSNumber *)userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    [self didRemoveLocalAnnotation:annotation onPageNumber:pageNumber];
}

#pragma mark - Initial annotations

- (void)loadInitialRemoteAnnotation:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self loadInitialRemoteAnnotations:@[collaborationAnnotation]];
}

- (void)loadInitialRemoteAnnotations:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations
{
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        // Check if annotation has the required fields.
        if (![collaborationAnnotation isValidForAdd]) {
            NSLog(@"Remote annotation is not valid for an add action");
        }
        
        if (![self isMergingXFDF]) {
            [self mergeInitialXFDFCommand:collaborationAnnotation.xfdf];
        }
    }
    
    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTCollaborationManagerRemoteAnnotationsAddedNotification
                                                      object:self
                                                    userInfo:@{
                                                        PTCollaborationManagerAnnotationsUserInfoKey: collaborationAnnotations,
                                                        PTCollaborationManagerIsInitialUserInfoKey: @YES,
                                                    }];
}

#pragma mark - NSXMLParserDelegate
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if( [elementName isEqualToString:@"delete"])
    {
        self.inDeleteArray = YES;
    }
    else if( [elementName isEqualToString:@"id"])
    {
        self.inIdElement = YES;
    }
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if( self.inDeleteArray && self.inIdElement )
    {
        self.annotIdsToDelete = [self.annotIdsToDelete arrayByAddingObject:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if( [elementName isEqualToString:@"delete"])
    {
        self.inDeleteArray = NO;
    }
    else if( [elementName isEqualToString:@"id"])
    {
        self.inIdElement = NO;
    }
}

#pragma mark - Importing XFDF

- (void)importAnnotationsWithXFDFString:(NSString *)xfdfString
{
    [self importAnnotationsWithXFDFString:xfdfString isInitial:YES];
}

- (void)importAnnotationsWithXFDFString:(NSString *)xfdfString isInitial:(BOOL)isInitial
{
    self.mergingXFDF = YES;
    
    @try {
        PTFDFDoc *fdfDoc = [PTFDFDoc CreateFromXFDF:xfdfString];
        
        // Merge XFDF into PDFViewCtrl.
        if (isInitial) {
            [self mergeInitialXFDFString:xfdfString];
        } else {
            [self mergeXFDFString:xfdfString];
        }
        
        [self PT_importAnnotationsWithFDFDoc:fdfDoc isInitial:isInitial];
        
        [fdfDoc Close];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    
    self.mergingXFDF = NO;
}

- (void)importAnnotationsWithXFDFCommand:(NSString *)xfdfCommand
{
    [self importAnnotationsWithXFDFCommand:xfdfCommand isInitial:YES];
}

- (void)deleteAnnotIdsToDelete {
    __block NSArray<PTAnnot*>* annotsToDelete = @[];
    __block NSArray<NSNumber*>* annotPageNumbers = @[];
    NSError* error;
    
    if( self.annotIdsToDelete.count > 0 )
    {
        [self.toolManager.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
            
            unsigned int currentPage = 1;
            for (PTPageIterator* itr = [doc GetPageIterator:currentPage]; [itr HasNext]; [itr Next])
            {
                
                @autoreleasepool {
                    PTPage* page = [itr Current];
                    unsigned int numAnnots = [page GetNumAnnots];
                    
                    for(int annotNum = 0; annotNum < numAnnots; annotNum++ )
                    {
                        PTAnnot* annot = [page GetAnnot:annotNum];
                        NSString* annotID = [[annot GetUniqueID] GetAsPDFText];
                        if( [self.annotIdsToDelete containsObject:annotID] )
                        {
                            if( [[[[PTMarkup alloc] initWithAnn:annot] GetTitle] isEqualToString:self.toolManager.annotationAuthor ] )
                            {
                                annotsToDelete = [annotsToDelete arrayByAddingObject:annot];
                                annotPageNumbers = [annotPageNumbers arrayByAddingObject:@(currentPage)];
                            }
                        }
                    }
                }
                currentPage++;
            }
        } error:&error];
        
        [self.toolManager.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
            for(unsigned int ii = 0; ii < [annotsToDelete count]; ii++)
            {
                
                PTAnnot* annotToDelete = annotsToDelete[ii];
                unsigned int annotPageNumber = [annotPageNumbers[ii] unsignedIntValue];
                
                PTPage* pg = [doc GetPage:annotPageNumber];
                
                BOOL success = NO;
                if ([pg IsValid] && [annotToDelete IsValid]) {
                    
                    [self.toolManager willRemoveAnnotation:annotToDelete onPageNumber:annotPageNumber];
                    
                    [pg AnnotRemoveWithAnnot:annotToDelete];
                    success = YES;
                }
                
                NSMutableArray* pagesOnScreen = [self.toolManager.pdfViewCtrl GetVisiblePages];
                
                BOOL updated = NO;
                for( NSNumber* pageNum in pagesOnScreen )
                {
                    if( pageNum.intValue == annotPageNumber)
                    {
                        [self.toolManager.pdfViewCtrl UpdateWithAnnot:annotToDelete page_num:annotPageNumber];
                        updated = YES;
                        break;
                    }
                }
                
                if( !updated && success)
                    [self.toolManager.pdfViewCtrl Update:YES];
            }
        } error:&error];
    }
}

- (void)importAnnotationsWithXFDFCommand:(NSString *)xfdfCommand isInitial:(BOOL)isInitial
{
    self.mergingXFDF = YES;
    
    // Add missing XFDF tags if missing.
    NSString *sanitizedCommand = [self sanitizeXFDFCommand:xfdfCommand];
    
    // this is a temporary workaround to support deleting annotations by the same user
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[xfdfCommand dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = self;
    self.inDeleteArray = NO;
    self.annotIdsToDelete = @[];
    [parser parse];
    NSError *parserError = [parser parserError];
    
    if(parserError)
    {
        NSLog(@"There was an XML parsing error %@", parserError);
    }
    
    const int selectedPageNumber = self.toolManager.tool.annotationPageNumber;
    NSArray<NSString *> *selectedIdentifiers = [self selectedAnnotationIdentifiers];
    
    BOOL modifiedSelectedAnnotation = NO;
    for (NSString *selectedIdentifier in selectedIdentifiers) {
        if ([sanitizedCommand containsString:selectedIdentifier]) {
            modifiedSelectedAnnotation = YES;
            break;
        }
    }
    
    Class previousToolClass = Nil;
    BOOL backToPan = YES;
    Class previousDefaultClass = Nil;
    
    if (modifiedSelectedAnnotation &&
        ![self isAnnotStylePickerShowing]) {
        // Save tool properties.
        PTTool *tool = self.toolManager.tool;
        previousToolClass = [tool class];
        backToPan = tool.backToPanToolAfterUse;
        previousDefaultClass = tool.defaultClass;
        
        // Deselect all annotations.
        [self.toolManager changeTool:[PTPanTool class]];
    }
    
    @try {
        PTFDFDoc *fdfDoc = [[PTFDFDoc alloc] init];
        [fdfDoc MergeAnnots:sanitizedCommand permitted_user:@""];
        
        // Merge XFDF into PDFViewCtrl.
        if (isInitial) {
            [self mergeInitialXFDFCommand:sanitizedCommand];
        } else {
            [self mergeXFDFCommand:sanitizedCommand];
        }
        
        [self PT_importAnnotationsWithFDFDoc:fdfDoc isInitial:isInitial];
        
        [fdfDoc Close];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    
    // Reselect modified annotations.
    if (modifiedSelectedAnnotation &&
        ![self isAnnotStylePickerShowing] &&
        selectedIdentifiers.count > 0 &&
        selectedPageNumber > 0) {
        NSString *selectedIdentifier = selectedIdentifiers.firstObject;
        PTAnnot *annot = [self.toolManager.pdfViewCtrl findAnnotWithUniqueID:selectedIdentifier onPageNumber:selectedPageNumber];
        if (annot) {
            // Reselect first annotation.
            
            const BOOL selected = [self.toolManager selectAnnotation:annot
                                                        onPageNumber:selectedPageNumber];
            if (selected &&
                previousToolClass &&
                [self.toolManager.tool isKindOfClass:previousToolClass]) {
                self.toolManager.tool.backToPanToolAfterUse = backToPan;
                self.toolManager.tool.defaultClass = previousDefaultClass;
            }
        }
    }
    
    // handle deleted annots by same author until core supports it.
    [self deleteAnnotIdsToDelete];
    
    self.mergingXFDF = NO;
}

- (void)PT_importAnnotationsWithFDFDoc:(PTFDFDoc *)fdfDoc isInitial:(BOOL)isInitial
{
    NSMutableArray<PTCollaborationAnnotation *> *mutableAnnotations = [NSMutableArray array];
    
    @try {
        for (PTAnnot *fdfAnnot in fdfDoc.annots) {
            if (![fdfAnnot IsValid]) {
                PTLog(@"Skipping invalid FDF annot");
                continue;
            }
            else if ([fdfAnnot GetType] == e_ptPopup) {
                PTLog(@"Skipping Popup FDF annot");
                continue;
            }
            else if (![fdfAnnot IsMarkup]) {
                PTLog(@"Skipping non-markup FDF annot");
                continue;
            }
            
            PTMarkup *fdfMarkup = [[PTMarkup alloc] initWithAnn:fdfAnnot];
            NSAssert([fdfMarkup IsValid], @"FDF markup annotation must be valid");
            
            // Extract the required information from the FDF annot.
            NSString *annotationIdentifier = nil;
            NSString *annotationAuthorIdentifier = nil;
            NSString *xfdf = nil;
            @try {
                annotationIdentifier = fdfMarkup.uniqueID;
                annotationAuthorIdentifier = [fdfMarkup GetTitle];
                
                xfdf = [PTFDFDoc XFDFStringFromAnnot:fdfMarkup];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception: %@, %@", exception.name, exception.reason);
                continue;
            }
            
            PTCollaborationAnnotation *collaborationAnnotation = [[PTCollaborationAnnotation alloc] init];
            
            collaborationAnnotation.annotationID = annotationIdentifier;
            collaborationAnnotation.userID = annotationAuthorIdentifier;
            collaborationAnnotation.xfdf = xfdf;
            
            [mutableAnnotations addObject:collaborationAnnotation];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    
    NSArray<PTCollaborationAnnotation *> *annotations = [mutableAnnotations copy];
    
    if (isInitial) {
        [self loadInitialRemoteAnnotations:annotations];
    } else {
        [self remoteAnnotationsAdded:annotations];
    }
}

#pragma mark - Methods by which the manager can be informed of remote changes

- (void)remoteAnnotationAdded:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self remoteAnnotationsAdded:@[collaborationAnnotation]];
}

- (void)remoteAnnotationsAdded:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations
{
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        // Check if annotation has the required fields.
        if (![collaborationAnnotation isValidForAdd]) {
            NSLog(@"Remote annotation is not valid for an add action");
        }
        
        if (![self isMergingXFDF]) {
            [self mergeXFDFCommand:collaborationAnnotation.xfdf];
        }
    }
    
    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTCollaborationManagerRemoteAnnotationsAddedNotification
                                                      object:self
                                                    userInfo:@{
                                                        PTCollaborationManagerAnnotationsUserInfoKey: collaborationAnnotations,
                                                    }];
}

- (void)remoteAnnotationModified:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self remoteAnnotationsModified:@[collaborationAnnotation]];
}

- (void)remoteAnnotationsModified:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations
{
    NSArray<PTAnnot *> *selectedAnnotations = [self selectedAnnotations];
    const int selectedPageNumber = self.toolManager.tool.annotationPageNumber;
    NSArray<NSString *> *selectedIdentifiers = [self selectedAnnotationIdentifiers];
    
    BOOL modifiedSelectedAnnotation = NO;
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        for (NSString *selectedIdentifier in selectedIdentifiers) {
            if ([collaborationAnnotation.xfdf containsString:selectedIdentifier]) {
                modifiedSelectedAnnotation = YES;
                break;
            }
        }
    }
    
    if (modifiedSelectedAnnotation &&
        ![self isAnnotStylePickerShowing] &&
        !self.updatingOptimisticLocalAnnotations) {
        // Deselect all annotations.
        [self.toolManager changeTool:[PTPanTool class]];
    }
    
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        // Check if annotation has the required fields.
        if (![collaborationAnnotation isValidForModify]) {
            NSLog(@"Remote annotation is not valid for a modify action");
        }
        
        [self mergeXFDFCommand:collaborationAnnotation.xfdf];
        
        if (collaborationAnnotation.annotationID &&
            [selectedIdentifiers containsObject:collaborationAnnotation.annotationID]) {
            modifiedSelectedAnnotation = YES;
        }
    }
    
    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTCollaborationManagerRemoteAnnotationsModifiedNotification
                                                      object:self
                                                    userInfo:@{
                                                        PTCollaborationManagerAnnotationsUserInfoKey: collaborationAnnotations,
                                                    }];
    
    // Reselect modified annotations.
    if (modifiedSelectedAnnotation &&
        ![self isAnnotStylePickerShowing] &&
        !self.updatingOptimisticLocalAnnotations &&
        selectedAnnotations.count > 0 &&
        selectedPageNumber > 0) {
        // Reselect first annotation.
        
        [self.toolManager selectAnnotation:selectedAnnotations.firstObject
                              onPageNumber:selectedPageNumber];
    }
}

- (void)remoteAnnotationRemoved:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self remoteAnnotationsRemoved:@[collaborationAnnotation]];
}

- (void)remoteAnnotationsRemoved:(NSArray<PTCollaborationAnnotation *> *)collaborationAnnotations
{
    NSArray<NSString *> *selectedIdentifiers = [self selectedAnnotationIdentifiers];
    BOOL removedSelectedAnnotation = NO;
    
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        for (NSString *selectedIdentifier in selectedIdentifiers) {
            if ([collaborationAnnotation.xfdf containsString:selectedIdentifier]) {
                removedSelectedAnnotation = YES;
                break;
            }
        }
    }
    
    // Deselect removed annotations.
    if (removedSelectedAnnotation &&
        !self.updatingOptimisticLocalAnnotations) {
        [self.toolManager changeTool:[PTPanTool class]];
    }
    
    self.annotIdsToDelete = @[];
    
    for (PTCollaborationAnnotation *collaborationAnnotation in collaborationAnnotations) {
        // Check if annotation has the required fields.
        if (![collaborationAnnotation isValidForRemove]) {
            NSLog(@"Remote annotation is not valid for a remove action");
        }
        
        NSString *deleteXfdf = [NSString stringWithFormat:@"<delete><id>%@</id></delete>",
                                collaborationAnnotation.annotationID];
        
        deleteXfdf = [self sanitizeXFDFCommand:deleteXfdf];
        
        self.annotIdsToDelete = [self.annotIdsToDelete arrayByAddingObject:collaborationAnnotation.annotationID];
        
        [self mergeXFDFCommand:deleteXfdf];
    }
    
    [self deleteAnnotIdsToDelete];
    
    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTCollaborationManagerRemoteAnnotationsRemovedNotification
                                                      object:self
                                                    userInfo:@{
                                                        PTCollaborationManagerAnnotationsUserInfoKey: collaborationAnnotations,
                                                    }];
}

@end

@implementation PTBaseCollaborationManager (PTSubclassing)

#pragma mark Local annotation changes

- (void)didAddlocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    // Get the annotation's ID.
    NSError *error = nil;
    NSString *annotationID = [self identifierForAnnot:annotation error:&error];
    if (annotationID.length == 0) {
        if (error) {
            NSLog(@"Failed to get ID of added local annotation: %@", error);
        } else {
            NSLog(@"Added local annotation missing a unique ID");
        }
        return;
    }
    
    // Get last XFDF.
    NSString *xfdf = [self GetLastXFDFCommand];
    if (xfdf.length == 0) {
        NSLog(@"Failed to get last XFDF for added local annotation");
        return;
    }
    
    NSString *annotationAuthor = [self authorForAnnot:annotation];
    
    PTCollaborationAnnotation* collaborationAnnotation = [[PTCollaborationAnnotation alloc] init];
    collaborationAnnotation.annotationID = annotationID;
    collaborationAnnotation.userID = annotationAuthor;
    collaborationAnnotation.xfdf = xfdf;
    
    [self.server localAnnotationAdded:collaborationAnnotation];
    
    // Optimistic update.
    self.updatingOptimisticLocalAnnotations = YES;
    [self remoteAnnotationAdded:collaborationAnnotation];
    self.updatingOptimisticLocalAnnotations = NO;
}

- (void)willModifyLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    
}

- (void)didModifyLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    // Get the annotation's ID.
    NSError *error = nil;
    NSString *annotationID = [self identifierForAnnot:annotation error:&error];
    if (annotationID.length == 0) {
        if (error) {
            NSLog(@"Failed to get ID of modified local annotation: %@", error);
        } else {
            NSLog(@"Modified local annotation missing a unique ID");
        }
        return;
    }
    
    // Get last XFDF.
    NSString *xfdf = [self GetLastXFDFCommand];
    if (xfdf.length == 0) {
        NSLog(@"Failed to get last XFDF for modified local annotation");
        return;
    }
    
    PTCollaborationAnnotation* collaborationAnnotation = [[PTCollaborationAnnotation alloc] init];
    collaborationAnnotation.annotationID = annotationID;
    collaborationAnnotation.xfdf = xfdf;
    
    [self.server localAnnotationModified:collaborationAnnotation];
    
    // Optimistic update.
    self.updatingOptimisticLocalAnnotations = YES;
    [self remoteAnnotationModified:collaborationAnnotation];
    self.updatingOptimisticLocalAnnotations = NO;
}

- (void)willRemoveLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    
}

- (void)didRemoveLocalAnnotation:(PTAnnot *)annotation onPageNumber:(int)pageNumber
{
    // Get the annotation's ID.
    NSError *error = nil;
    NSString *annotationID = [self identifierForAnnot:annotation error:&error];
    if (annotationID.length == 0) {
        if (error) {
            NSLog(@"Failed to get ID of removed local annotation: %@", error);
        } else {
            NSLog(@"Removed local annotation missing a unique ID");
        }
        return;
    }
    
    NSString *xfdf = [self GetLastXFDFCommand];
    if (xfdf.length == 0) {
        NSLog(@"Failed to get last XFDF for modified local annotation");
        return;
    }
    
    PTCollaborationAnnotation* collaborationAnnotation = [[PTCollaborationAnnotation alloc] init];
    collaborationAnnotation.annotationID = annotationID;
    collaborationAnnotation.xfdf = xfdf;
    
    [self.server localAnnotationRemoved:collaborationAnnotation];
    
    // Optimistic update.
    self.updatingOptimisticLocalAnnotations = YES;
    [self remoteAnnotationRemoved:collaborationAnnotation];
    self.updatingOptimisticLocalAnnotations = NO;
}

#pragma mark XFDF

- (NSString *)GetLastXFDFCommand
{
    return nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (NSString *)GetLastXFDF
{
    return [self GetLastXFDFCommand];
}

#pragma clang diagnostic pop

- (void)mergeInitialXFDFString:(NSString *)xfdfString
{
    
}

- (void)mergeXFDFString:(NSString *)xfdfString
{
    
}

- (void)mergeInitialXFDFCommand:(NSString *)xfdfCommand
{
    
}

- (void)mergeXFDFCommand:(NSString *)xfdfCommand
{
    
}

- (NSString *)exportXFDFStringWithError:(NSError * _Nullable __autoreleasing *)error
{
    return nil;
}

@end
