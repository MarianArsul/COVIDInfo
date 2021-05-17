//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPanTool.h"

#import "PTAnnotEditTool.h"
#import "PTRectangleCreate.h"
#import "PTEllipseCreate.h"
#import "PTLineCreate.h"
#import "PTRulerCreate.h"
#import "PTArrowCreate.h"
#import "PTStickyNoteCreate.h"
#import "PTFreeHandCreate.h"
#import "PTFreeHandHighlightCreate.h"
#import "PTTextSelectTool.h"
#import "PTEraser.h"
#import "PTFormFillTool.h"
#import "PTFreeTextCreate.h"
#import "PTCalloutCreate.h"
#import "PTCalloutEditTool.h"
#import "PTDigitalSignatureTool.h"
#import "PTRichMediaTool.h"
#import "PTAnalyticsManager.h"
#import "PTTextMarkupEditTool.h"
#import "PTPolylineCreate.h"
#import "PTPerimeterCreate.h"
#import "PTPolygonCreate.h"
#import "PTAreaCreate.h"
#import "PTCloudCreate.h"
#import "PTImageStampCreate.h"
#import "PTRubberStampCreate.h"
#import "PTAnnotSelectTool.h"
#import "PTRectangleRedactionCreate.h"
#import "PTPolylineEditTool.h"
#import "PTFileAttachmentCreate.h"
#import "PTPencilDrawingCreate.h"

#import "PTToolsUtil.h"
#import "PTAnnotationPasteboard.h"

#import "PTAnnot+PTAdditions.h"

@class PTPDFViewCtrl;

@implementation PTPanTool


- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{

    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        _showMenuOnTap = NO;
        _showMenuNextTap = YES;
        
    }

    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if (self.superview) {
        
        self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = NO;
        
        // Workaround for:
        // UIMenuController is dismissed immediately after being shown the first time.
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            UIMenuController *menu = [UIMenuController sharedMenuController];
            [menu setTargetRect:CGRectMake(CGFLOAT_MIN, CGFLOAT_MIN, 0.0, 0.0) inView:self];
            [menu setMenuVisible:YES animated:NO];
        });
    }
}

#pragma mark - Touch Event Handling

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    return YES;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if( [self.pdfViewCtrl GetDoc] == nil )
    {
        return YES;
    }

    CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
    BOOL annotIsInGroup = NO;
    [self.pdfViewCtrl becomeFirstResponder];

    if( gestureRecognizer.state == UIGestureRecognizerStateBegan )
    {

        if( [self.currentAnnotation IsValid] )
        {
            self.currentAnnotation = nil;
        }
        
        int pn = [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y];

        if( pn < 1 )
        {
            return YES;
        }
        
        self.annotationPageNumber = pn;

        @try
        {
            [self.pdfViewCtrl DocLockRead];

            self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
            annotIsInGroup = self.currentAnnotation.isInGroup;
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlockRead];
        }

        PTExtendedAnnotType annotType = self.currentAnnotation.extendedAnnotType;

        if ([self.currentAnnotation IsValid] &&
            ([self.toolManager tool:self canEditAnnotation:self.currentAnnotation]
             || (annotType == PTExtendedAnnotTypeLink && [self.toolManager isLinkFollowingEnabledForTool:self])))
        {

            if(annotType == PTExtendedAnnotTypeWidget) {
                self.nextToolType = [PTFormFillTool class];
            }
            else if(annotType == PTExtendedAnnotTypeLine || annotType == PTExtendedAnnotTypeArrow || annotType == PTExtendedAnnotTypeRuler) {
                self.nextToolType = [PTPolylineEditTool class];
            }
			else if(annotType == PTExtendedAnnotTypeHighlight || annotType == PTExtendedAnnotTypeUnderline || annotType == PTExtendedAnnotTypeStrikeOut || annotType ==  PTExtendedAnnotTypeSquiggly) {
                self.nextToolType = [PTTextMarkupEditTool class];
            }
            else if(annotType == PTExtendedAnnotTypePolyline || annotType == PTExtendedAnnotTypePolygon || annotType == PTExtendedAnnotTypeCloudy)
            {
                self.nextToolType = [PTPolylineEditTool class];
            }
            else if (annotType == PTExtendedAnnotTypeCallout) {
                self.nextToolType = [PTCalloutEditTool class];
            }
            else
            {
                self.nextToolType = [PTAnnotEditTool class];
            }

            if (annotIsInGroup) {
                self.nextToolType = [PTAnnotEditTool class];
            }

            return NO;

        }
        else
        {
            self.currentAnnotation = nil;
        }
    }

    if( !self.currentAnnotation )
    {
        if ([self.toolManager isTextSelectionEnabledForTool:self]) {
            [self.pdfViewCtrl SetTextSelectionMode:e_ptrectangular];
            [self.pdfViewCtrl SelectX1:down.x Y1:down.y X2:1+down.x Y2:1+down.y];
            [self.pdfViewCtrl SetTextSelectionMode:e_ptstructural];

            PTSelection* selection = [self.pdfViewCtrl GetSelection:-1];

            //if over text
            if (selection == 0 || [[selection GetQuads] size] > 0)
            {
                [self hideMenu];
                self.nextToolType = [PTTextSelectTool class];
                return NO;
            }
        }

        if( gestureRecognizer.state == UIGestureRecognizerStateBegan )
        {
            // show creation menu
            [self becomeFirstResponder];
            [self attachInitialMenuItems];

            self.longPressPoint = [gestureRecognizer locationInView:self.pdfViewCtrl];

            // animated "NO" prevents flicker when moving finger
            [self showSelectionMenu:CGRectMake(self.longPressPoint.x, self.longPressPoint.y, 1, 1) animated:YES];
        }
    }

    return YES;
}

#pragma mark - UIMenuController Items

- (nullable UIMenuItem *)menuItemForExtendedAnnotType:(PTExtendedAnnotType)annotType
{
    switch (annotType) {
        case PTExtendedAnnotTypeText:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"Note tool name") action:@selector(createStickeyNote)];
        case PTExtendedAnnotTypeSignature:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Signature", @"Signature tool name") action:@selector(createSignature)];
        case PTExtendedAnnotTypeInk:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Ink", @"Ink tool name") action:@selector(createFreeHand)];
        case PTExtendedAnnotTypeFreehandHighlight:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Free Highlight",
                                                                       @"Freehand highlight tool name")
                                              action:@selector(createFreeHandHighlight)];
        case PTExtendedAnnotTypeFreeText:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Text", @"Text tool name") action:@selector(createFreeText)];
        case PTExtendedAnnotTypeArrow:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Arrow", @"Arrow tool name") action:@selector(createArrow)];
        case PTExtendedAnnotTypeLine:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Line", @"Line tool name") action:@selector(createLine)];
        case PTExtendedAnnotTypeSquare:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Rectangle", @"Rectangle tool name") action:@selector(createRectangle)];
        case PTExtendedAnnotTypeCircle:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Ellipse", @"Ellipse tool name") action:@selector(createEllipse)];
        case PTExtendedAnnotTypePolygon:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Polygon", @"Polygon tool name") action:@selector(createPolygon)];
        case PTExtendedAnnotTypeCloudy:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Cloud", @"Cloud tool name") action:@selector(createCloud)];
        case PTExtendedAnnotTypePolyline:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Polyline", @"Polyline tool name") action:@selector(createPolyline)];
        case PTExtendedAnnotTypeFileAttachment:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"File Attachment", @"File attachment tool name") action:@selector(createFileAttachment)];
        case PTExtendedAnnotTypeRedact:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Redaction", @"Redaction tool name") action:@selector(createRedaction)];
        case PTExtendedAnnotTypeImageStamp:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Image", @"Image Stamp tool name") action:@selector(createImageStamp)];
        case PTExtendedAnnotTypeStamp:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Stamp", @"Rubber Stamp tool name") action:@selector(createRubberStamp)];
        case PTExtendedAnnotTypeRuler:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Ruler", @"Ruler tool name") action:@selector(createRuler)];
        case PTExtendedAnnotTypePerimeter:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Perimeter", @"Perimeter tool name") action:@selector(createPerimeter)];
        case PTExtendedAnnotTypeArea:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Area", @"Area tool name") action:@selector(createArea)];
        case PTExtendedAnnotTypeCallout:
            return [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Callout",
                                                                       @"Callout tool name")
                                              action:@selector(createCallout)];
        default:
            return nil;
    }
}

- (NSArray<UIMenuItem *> *)menuItemsForAnnotTypes:(NSArray<NSNumber *> *)annotTypes
{
    NSMutableArray<UIMenuItem *> *menuItems = [NSMutableArray array];

    for (NSNumber *annotTypeValue in annotTypes) {
        PTExtendedAnnotType annotType = (PTExtendedAnnotType)annotTypeValue.unsignedIntegerValue;
        
        if (![self.toolManager tool:self canCreateExtendedAnnotType:annotType]) {
            continue;
        }
        
        UIMenuItem *menuItem = [self menuItemForExtendedAnnotType:annotType];
        NSAssert(menuItem, @"Missing menu item for extended annotation type %lud", (unsigned long)annotType);
        
        [menuItems addObject:menuItem];
    }
    
    return [menuItems copy];
}

- (NSArray<UIMenuItem *> *)shapeMenuItems
{
    return [self menuItemsForAnnotTypes:@[
        @(PTExtendedAnnotTypeLine),
        @(PTExtendedAnnotTypeArrow),
        @(PTExtendedAnnotTypeSquare),
        @(PTExtendedAnnotTypeCircle),
        @(PTExtendedAnnotTypePolygon),
        @(PTExtendedAnnotTypeCloudy),
        @(PTExtendedAnnotTypeFreehandHighlight),
        @(PTExtendedAnnotTypePolyline),
        @(PTExtendedAnnotTypeCallout),
    ]];
}

- (NSArray<UIMenuItem *> *)measureMenuItems
{
    return [self menuItemsForAnnotTypes:@[
        @(PTExtendedAnnotTypeRuler),
        @(PTExtendedAnnotTypePerimeter),
        @(PTExtendedAnnotTypeArea),
    ]];
}

- (NSArray<UIMenuItem *> *)attachMenuItems
{
    return [self menuItemsForAnnotTypes:@[
        @(PTExtendedAnnotTypeFileAttachment),
    ]];
}

- (void)attachInitialMenuItems
{
    NSMutableArray<UIMenuItem *> *menuItems = [NSMutableArray array];
    
    // "Paste" (annotations) item.
    if (PTAnnotationPasteboard.defaultPasteboard.annotations.count > 0 && !self.toolManager.readonly) {
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Paste",
                                                                                 @"Paste annotations")
                                                        action:@selector(pasteAnnotationsAtPoint)]];
    }else if (UIPasteboard.generalPasteboard.hasImages) {
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Paste",
                                                                                 @"Paste image")
                                                        action:@selector(pasteImageAtPoint)]];
    }
    
    [menuItems addObjectsFromArray:[self menuItemsForAnnotTypes:@[
        @(PTExtendedAnnotTypeInk),
        @(PTExtendedAnnotTypeFreeText),
        @(PTExtendedAnnotTypeSignature),
        @(PTExtendedAnnotTypeText),
    ]]];
    
    // "Shapes…" submenu.
    if ([self shapeMenuItems].count > 0) {
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Shapes…",
                                                                                 @"Shapes submenu title")
                                                        action:@selector(showShapesMenu)]];
    }
    
    [menuItems addObjectsFromArray:[self menuItemsForAnnotTypes:@[
        @(PTExtendedAnnotTypeImageStamp),
        @(PTExtendedAnnotTypeStamp),
        @(PTExtendedAnnotTypeRedact),
    ]]];
    
    // "Measure…" submenu.
    if ([self measureMenuItems].count > 0) {
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Measure…",
                                                                                 @"Measure submenu title")
                                                        action:@selector(showMeasureMenu)]];
    }
    
    // "Attach…" submenu.
    if ([self attachMenuItems].count > 0) {
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Attach…",
                                                                                 @"Attach submenu title")
                                                        action:@selector(showAttachMenu)]];
    }
    
    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Select Annotations",
                                                                             @"Select annotations tool name")
                                                    action:@selector(multiSelectTool)]];
    
    UIMenuController *theMenu = UIMenuController.sharedMenuController;
    theMenu.menuItems = [menuItems copy];
}

- (void)showShapesMenu
{
    UIMenuController *theMenu = UIMenuController.sharedMenuController;
    theMenu.menuItems = [self shapeMenuItems];
    
    [theMenu setMenuVisible:YES animated:YES];
}

- (void)showMeasureMenu
{
    UIMenuController *theMenu = UIMenuController.sharedMenuController;
    theMenu.menuItems = [self measureMenuItems];
    
    [theMenu setMenuVisible:YES animated:YES];
}

- (void)showAttachMenu
{
    UIMenuController *theMenu = UIMenuController.sharedMenuController;
    theMenu.menuItems = [self attachMenuItems];
    
    [theMenu setMenuVisible:YES animated:YES];
}

#pragma mark - UIContextMenuInteraction Actions
#if TARGET_OS_MACCATALYST
- (nullable UIAction *)menuActionForExtendedAnnotType:(PTExtendedAnnotType)annotType
{
    switch (annotType) {
        case PTExtendedAnnotTypeText:
            return [UIAction actionWithTitle:PTLocalizedString(@"Note", @"Note tool name") image:nil identifier:nil handler:^(UIAction *action){[self createStickeyNote];}];
        case PTExtendedAnnotTypeSignature:
            return [UIAction actionWithTitle:PTLocalizedString(@"Signature", @"Signature tool name") image:nil identifier:nil handler:^(UIAction *action){[self createSignature];}];
        case PTExtendedAnnotTypeInk:
            return [UIAction actionWithTitle:PTLocalizedString(@"Ink", @"Ink tool name") image:nil identifier:nil handler:^(UIAction *action){[self createFreeHand];}];
        case PTExtendedAnnotTypeFreeText:
            return [UIAction actionWithTitle:PTLocalizedString(@"Text", @"Text tool name") image:nil identifier:nil handler:^(UIAction *action){[self createFreeText];}];
        case PTExtendedAnnotTypeArrow:
            return [UIAction actionWithTitle:PTLocalizedString(@"Arrow", @"Arrow tool name") image:nil identifier:nil handler:^(UIAction *action){[self createArrow];}];
        case PTExtendedAnnotTypeLine:
            return [UIAction actionWithTitle:PTLocalizedString(@"Line", @"Line tool name") image:nil identifier:nil handler:^(UIAction *action){[self createLine];}];
        case PTExtendedAnnotTypeSquare:
            return [UIAction actionWithTitle:PTLocalizedString(@"Rectangle", @"Rectangle tool name") image:nil identifier:nil handler:^(UIAction *action){[self createRectangle];}];
        case PTExtendedAnnotTypeCircle:
            return [UIAction actionWithTitle:PTLocalizedString(@"Ellipse", @"Ellipse tool name") image:nil identifier:nil handler:^(UIAction *action){[self createEllipse];}];
        case PTExtendedAnnotTypePolygon:
            return [UIAction actionWithTitle:PTLocalizedString(@"Polygon", @"Polygon tool name") image:nil identifier:nil handler:^(UIAction *action){[self createPolygon];}];
        case PTExtendedAnnotTypeCloudy:
            return [UIAction actionWithTitle:PTLocalizedString(@"Cloud", @"Cloud tool name") image:nil identifier:nil handler:^(UIAction *action){[self createCloud];}];
        case PTExtendedAnnotTypePolyline:
            return [UIAction actionWithTitle:PTLocalizedString(@"Polyline", @"Polyline tool name") image:nil identifier:nil handler:^(UIAction *action){[self createPolyline];}];
        case PTExtendedAnnotTypeFileAttachment:
            return [UIAction actionWithTitle:PTLocalizedString(@"File Attachment", @"File attachment tool name") image:nil identifier:nil handler:^(UIAction *action){[self createFileAttachment];}];
        case PTExtendedAnnotTypeRedact:
            return [UIAction actionWithTitle:PTLocalizedString(@"Redaction", @"Redaction tool name") image:nil identifier:nil handler:^(UIAction *action){[self createRedaction];}];
        case PTExtendedAnnotTypeImageStamp:
            return [UIAction actionWithTitle:PTLocalizedString(@"Image", @"Image Stamp tool name") image:nil identifier:nil handler:^(UIAction *action){[self createImageStamp];}];
        case PTExtendedAnnotTypeRuler:
            return [UIAction actionWithTitle:PTLocalizedString(@"Ruler", @"Ruler tool name") image:nil identifier:nil handler:^(UIAction *action){[self createRuler];}];
        case PTExtendedAnnotTypePerimeter:
            return [UIAction actionWithTitle:PTLocalizedString(@"Perimeter", @"Perimeter tool name") image:nil identifier:nil handler:^(UIAction *action){[self createPerimeter];}];
        case PTExtendedAnnotTypeArea:
            return [UIAction actionWithTitle:PTLocalizedString(@"Area", @"Area tool name") image:nil identifier:nil handler:^(UIAction *action){[self createArea];}];
        default:
            return nil;
    }
}

- (NSArray<UIAction *> *)menuActionsForExtendedAnnotTypes:(NSArray<NSNumber *> *)annotTypes
{
    NSMutableArray<UIAction *> *menuActions = [NSMutableArray array];

    for (NSNumber *annotTypeValue in annotTypes) {
        PTExtendedAnnotType annotType = (PTExtendedAnnotType)annotTypeValue.unsignedIntegerValue;

        if (![self.toolManager tool:self canCreateExtendedAnnotType:annotType]) {
            continue;
        }
        UIAction *menuAction = [self menuActionForExtendedAnnotType:annotType];
        NSAssert(menuAction, @"Missing menu action for extended annotation type %lud", (unsigned long)annotType);

        [menuActions addObject:menuAction];
    }

    return [menuActions copy];
}

- (NSArray<UIAction *> *)shapesMenuActions{
    return [self menuActionsForExtendedAnnotTypes:
            @[
                @(PTExtendedAnnotTypeLine),
                @(PTExtendedAnnotTypeArrow),
                @(PTExtendedAnnotTypeSquare),
                @(PTExtendedAnnotTypeCircle),
                @(PTExtendedAnnotTypePolygon),
                @(PTExtendedAnnotTypeCloudy),
                @(PTExtendedAnnotTypePolyline),
            ]];
}

- (NSArray<UIAction *> *)measureMenuActions
{
    return [self menuActionsForExtendedAnnotTypes:
            @[
                @(PTExtendedAnnotTypeRuler),
                @(PTExtendedAnnotTypePerimeter),
                @(PTExtendedAnnotTypeArea),
            ]];
}

- (NSArray<UIAction *> *)attachMenuActions
{
    return [self menuActionsForExtendedAnnotTypes:
            @[
                @(PTExtendedAnnotTypeFileAttachment),
            ]];
}
#endif
#pragma mark - Tool Switching

- (void)pasteImageAtPoint{
    PTImageStampCreate *isc = [[PTImageStampCreate allocOverridden] initWithPDFViewCtrl:self.pdfViewCtrl];
    double offset = 0;
    for (UIImage *image in UIPasteboard.generalPasteboard.images) {
        CGPoint pastePoint = CGPointMake(self.longPressPoint.x + offset, self.longPressPoint.y + offset);
        [isc stampImage:image atPoint:pastePoint];
        offset += 10;
    }
}

// Paste the copied annotations at the long-press location.
- (void)pasteAnnotationsAtPoint
{
    int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.longPressPoint.x
                                                               y:self.longPressPoint.y];
    if (pageNumber < 1) {
        return;
    }
    CGPoint longPressPagePoint = [self convertScreenPtToPagePt:self.longPressPoint
                                                  onPageNumber:pageNumber];
    
    PTPDFPoint *pagePoint = [[PTPDFPoint alloc] initWithPx:longPressPagePoint.x
                                                        py:longPressPagePoint.y];
    
    [PTAnnotationPasteboard.defaultPasteboard pasteAnnotationsOnPageNumber:pageNumber atPagePoint:pagePoint withToolManager:self.toolManager completion:^(NSArray<PTAnnot *> * _Nullable pastedAnnotations, NSError * _Nullable error) {
        if (pastedAnnotations.count == 0) {
            return;
        }

        NSError* lockError;
        
        [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
            for(PTAnnot* pastedAnnot in pastedAnnotations )
            {
                if( [pastedAnnot GetType] == e_ptFreeText )
                {
                    PTFreeText* ft = [[PTFreeText alloc] initWithAnn:pastedAnnot];
                    
                    [PTFreeTextCreate createAppearanceForAnnot:ft onDoc:doc withViewerRotation:[self.pdfViewCtrl GetRotation]];
                    
                }
            }
            
        } error:&lockError];
        
        NSAssert(lockError == Nil, @"Error on write");

        // Select the pasted annotations.
        self.currentAnnotation = pastedAnnotations.firstObject;
        self.annotationPageNumber = pageNumber;
        
        PTTool *tool = [self.toolManager changeTool:[PTAnnotEditTool class]];
        if ([tool isKindOfClass:[PTAnnotEditTool class]]) {
            PTAnnotEditTool *editTool = (PTAnnotEditTool *)tool;
            editTool.selectedAnnotations = pastedAnnotations;
            [editTool selectAnnotation:self.currentAnnotation onPageNumber:pageNumber];
        }
    }];
}

-(void)multiSelectTool
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTAnnotSelectTool class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Select annot tool selected"];
}

-(void)createRectangle
{
	// the next tool will adopt the backToPanToolAfterUse setting of the current tool.
	// tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTRectangleCreate class];
	[self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Rectangle selected"];
}

-(void)createEllipse
{
	// the next tool will adopt the backToPanToolAfterUse setting of the current tool.
	// tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTEllipseCreate class];
	[self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Ellipse selected"];
}

-(void)createLine
{
	// the next tool will adopt the backToPanToolAfterUse setting of the current tool.
	// tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTLineCreate class];
	[self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Line selected"];
}

-(void)createRuler
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTRulerCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Ruler selected"];
}

-(void)createPolyline
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTPolylineCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Polyline selected"];
}

-(void)createPolygon
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTPolygonCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Polygon selected"];
}

-(void)createCloud
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTCloudCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Cloud selected"];
}

-(void)createPerimeter
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTPerimeterCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Perimeter selected"];
}

-(void)createArea
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTAreaCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Area selected"];
}

-(void)createArrow
{
	// the next tool will adopt the backToPanToolAfterUse setting of the current tool.
	// tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTArrowCreate class];
	[self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Arrow selected"];
}

-(void)createStickeyNote
{
	// the next tool will adopt the backToPanToolAfterUse setting of the current tool.
	// tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTStickyNoteCreate class];
	[self.toolManager createSwitchToolEvent:nil];
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] StickyNote selected"];
}

-(void)createFreeHand
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTFreeHandCreate class];
    if ([self.toolManager freehandUsesPencilKit]) {
        if (@available(iOS 13.1, *) ) {
            if ([self.toolManager.pencilTool isEqual:[PTPencilDrawingCreate class]]){
                self.nextToolType = [PTPencilDrawingCreate class];
            }
        }
    }
	[self.toolManager createSwitchToolEvent:@"From Long Press"];
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] FreeHand selected"];
}

-(void)createFreeHandHighlight
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTFreeHandHighlightCreate class];
    [self.toolManager createSwitchToolEvent:@"From Long Press"];
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] FreeHand highlight selected"];
}

//-(void)createEraser
//{
//    self.nextToolType = [PTEraser class];
//	[m_pdfViewCtrl postCustomEvent:nil];
//    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Eraser selected"];
//}

-(void)createFreeText
{
	// the next tool will adopt the backToPanToolAfterUse setting of the current tool.
	// tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTFreeTextCreate class];
	[self.toolManager createSwitchToolEvent:@"Start"];
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] FreeText selected"];
}

- (void)createCallout
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTCalloutCreate class];
    [self.toolManager createSwitchToolEvent:@"Start"];
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Callout selected"];
}

-(void)createSignature
{
	// the next tool will adopt the backToPanToolAfterUse setting of the current tool.
	// tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
	self.nextToolType = [PTDigitalSignatureTool class];
	[self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Signature selected"];
}

-(void)createFileAttachment
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTFileAttachmentCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] File attachment selected"];
}

-(void)createRedaction
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTRectangleRedactionCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Redaction selected"];
}

-(void)createImageStamp
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTImageStampCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Image stamp selected"];
}

-(void)createRubberStamp
{
    // the next tool will adopt the backToPanToolAfterUse setting of the current tool.
    // tools activated through the quick menu should never always go back to the pan tool.
    self.backToPanToolAfterUse = YES;
    self.nextToolType = [PTRubberStampCreate class];
    [self.toolManager createSwitchToolEvent:nil];

    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Rubber stamp selected"];
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    if ([self.toolManager freehandUsesPencilKit]) {
        if (@available(iOS 13.1, *)) {
            if ([self.nextToolType isSubclassOfClass:[PTPencilDrawingCreate class]]) {
                return NO;
            }
        }
    }
    
    // When the nextToolType is any of the following tool classes, the custom switch-tool event
    // should *NOT* be handled (return NO) so that the current tool is actually switched.
    NSArray<Class> *nextToolTypes = @[
        [PTFreeHandCreate class],
        [PTDigitalSignatureTool class],
        [PTFreeTextCreate class],
        [PTRectangleCreate class], // rectangle, rectangle-redaction
        [PTEllipseCreate class],
        [PTLineCreate class], // line, ruler
        [PTArrowCreate class],
        [PTPolylineCreate class], // polyline, polygon, cloudy, perimeter, area
        [PTStickyNoteCreate class],
        [PTFileAttachmentCreate class],
        [PTImageStampCreate class],
        [PTRubberStampCreate class],
    ];
    for (Class cls in nextToolTypes) {
        if ([self.nextToolType isSubclassOfClass:cls]) {
            return NO;
        }
    }
    
    if( [userData isKindOfClass:[NSString class]])
    {
        if( [((NSString*)userData) isEqualToString:@"BackToPanFromFreeText"] ) {
            self.showMenuNextTap = YES;
        }
    }
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
    if (touch.tapCount == 2 || (PT_ToolsMacCatalyst && !self.nextToolType) ) {
        if( self.currentAnnotation )
        {
            self.currentAnnotation = nil;
        }
        @try
        {
            [self.pdfViewCtrl DocLockRead];
            self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlockRead];
        }
        // Don't switch to text select if there's an annot on top of the text
        if ([self.toolManager isTextSelectionEnabledForTool:self] && ![self.currentAnnotation IsValid]) {
            [self.pdfViewCtrl SetTextSelectionMode:e_ptrectangular];
            [self.pdfViewCtrl SelectX1:down.x Y1:down.y X2:1+down.x Y2:1+down.y];
            [self.pdfViewCtrl SetTextSelectionMode:e_ptstructural];

            PTSelection* selection = [self.pdfViewCtrl GetSelection:-1];

            //if over text
            if (selection == 0 || [[selection GetQuads] size] > 0 )
            {
                [self hideMenu];
                self.nextToolType = [PTTextSelectTool class];
                return NO;
            }
        }
    }
    if (touch.type == UITouchTypePencil && self.toolManager.tool.nextToolType != self.toolManager.pencilTool) {
        self.toolManager.tool.backToPanToolAfterUse = YES;
        // Don't switch tool if we're in read only mode and the Pencil tool creates or deletes annotations
        BOOL shouldSwitchToPencilTool = YES;
        
        if ([self.toolManager.pencilTool isSubclassOfClass:[PTEraser class]] || [self.toolManager.pencilTool createsAnnotation]) {
            shouldSwitchToPencilTool = !self.toolManager.isReadonly;
        }
        if (shouldSwitchToPencilTool) {
            self.toolManager.tool.nextToolType = [self.toolManager.pencilTool class];
            return NO;
        }
    }
    self.backgroundColor = [UIColor clearColor];

    self.frame = CGRectMake(0, 0, 0, 0);

    if( self.nextToolType )
        return NO;

    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if( [self.pdfViewCtrl GetDoc] == nil )
        {
            return YES;
        }

        CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];

        [self.pdfViewCtrl becomeFirstResponder];

        int pn = [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y];

        if( pn < 1 )
        {
            return YES;
        }
        
        self.annotationPageNumber = pn;

        if( self.currentAnnotation )
        {
            self.currentAnnotation = nil;
        }
        BOOL annotIsInGroup = NO;

        PTLinkInfo* linkInfo = nil;
        @try
        {
            [self.pdfViewCtrl DocLockRead];

            self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
            annotIsInGroup = self.currentAnnotation.isInGroup;

            if( ![self.currentAnnotation IsValid] )
                linkInfo = [self.pdfViewCtrl GetLinkAt:down.x y:down.y];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlockRead];
        }

        PTExtendedAnnotType annotType = self.currentAnnotation.extendedAnnotType;

        if ([self.currentAnnotation IsValid] &&
            ([self.toolManager tool:self canEditAnnotation:self.currentAnnotation]
             || (annotType == PTExtendedAnnotTypeLink && [self.toolManager isLinkFollowingEnabledForTool:self])))
        {

            if(annotType == PTExtendedAnnotTypeWidget) {
                self.nextToolType = [PTFormFillTool class];
            }
            else if (annotType == PTExtendedAnnotTypeLine || annotType == PTExtendedAnnotTypeArrow || annotType == PTExtendedAnnotTypeRuler)
            {
                self.nextToolType = [PTPolylineEditTool class];
            }
            else if(annotType == PTExtendedAnnotTypeRichMedia)
            {
                self.nextToolType = [PTRichMediaTool class];
            }
            else if(annotType == PTExtendedAnnotTypeHighlight || annotType == PTExtendedAnnotTypeUnderline || annotType == PTExtendedAnnotTypeStrikeOut || annotType ==  PTExtendedAnnotTypeSquiggly) {
                self.nextToolType = [PTTextMarkupEditTool class];
            }
            else if(annotType == PTExtendedAnnotTypePolyline || annotType == PTExtendedAnnotTypePolygon || annotType == PTExtendedAnnotTypeCloudy || annotType == PTExtendedAnnotTypePerimeter || annotType == PTExtendedAnnotTypeArea)
            {
                self.nextToolType = [PTPolylineEditTool class];
            }
            else if (annotType == PTExtendedAnnotTypeCallout) {
                self.nextToolType = [PTCalloutEditTool class];
            }
            else
            {
                self.nextToolType = [PTAnnotEditTool class];
            }

            if (annotIsInGroup) {
                self.nextToolType = [PTAnnotEditTool class];
            }

            return NO;
        }

        if( [linkInfo getUrl].length > 0 && [self.toolManager isLinkFollowingEnabledForTool:self])
        {
            self.nextToolType = [PTAnnotEditTool class];
            return NO;
        }

        if( self.showMenuOnTap && self.showMenuNextTap )
        {
            // show creation menu
            [self becomeFirstResponder];
            [self attachInitialMenuItems];

            self.longPressPoint = [gestureRecognizer locationInView:self.pdfViewCtrl];

            // animated "NO" prevents flicker when moving finger
            [self showSelectionMenu:CGRectMake(self.longPressPoint.x, self.longPressPoint.y, 1, 1) animated:YES];
        }

        self.showMenuNextTap = !self.showMenuNextTap;
    }

    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if( [self.pdfViewCtrl GetDoc] == nil )
    {
        return YES;
    }

    CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];

    if (PT_ToolsMacCatalyst ) {
        if( self.currentAnnotation )
        {
            self.currentAnnotation = nil;
        }
        @try
        {
            [self.pdfViewCtrl DocLockRead];
            self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlockRead];
        }
        // Don't switch to text select if there's an annot on top of the text
        if ([self.toolManager isTextSelectionEnabledForTool:self] && ![self.currentAnnotation IsValid]) {
            [self.pdfViewCtrl SetTextSelectionMode:e_ptrectangular];
            [self.pdfViewCtrl SelectX1:down.x Y1:down.y X2:1+down.x Y2:1+down.y];
            [self.pdfViewCtrl SetTextSelectionMode:e_ptstructural];

            PTSelection* selection = [self.pdfViewCtrl GetSelection:-1];

            //if over text
            if (selection == 0 || [[selection GetQuads] size] > 0 )
            {
                [self hideMenu];
                self.nextToolType = [PTTextSelectTool class];
                return NO;
            }
        }
    }
    return [super pdfViewCtrl:pdfViewCtrl handleDoubleTap:gestureRecognizer];
}

-(BOOL)canResignFirstResponder
{
    return ![[UIMenuController sharedMenuController] isMenuVisible];
}

#pragma mark - UIContextMenuInteractionDelegate
#if TARGET_OS_MACCATALYST
- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location configuration:(UIContextMenuConfiguration * _Nullable __autoreleasing *)configuration
{
    [self.pdfViewCtrl becomeFirstResponder];
    self.longPressPoint = location;
    int pn = [self.pdfViewCtrl GetPageNumberFromScreenPt:location.x y:location.y];
    if( pn < 1 )
    {
        return YES;
    }

    self.annotationPageNumber = pn;

    if( self.currentAnnotation )
    {
        self.currentAnnotation = nil;
    }
    BOOL annotIsInGroup = NO;

    PTLinkInfo* linkInfo = nil;
    @try
    {
        [self.pdfViewCtrl DocLockRead];

        self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:location.x y:location.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
        annotIsInGroup = self.currentAnnotation.isInGroup;

        if( ![self.currentAnnotation IsValid] )
            linkInfo = [self.pdfViewCtrl GetLinkAt:location.x y:location.y];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }

    PTExtendedAnnotType annotType = self.currentAnnotation.extendedAnnotType;

    if ([self.currentAnnotation IsValid] &&
        ([self.toolManager tool:self canEditAnnotation:self.currentAnnotation]
         || (annotType == PTExtendedAnnotTypeLink && [self.toolManager isLinkFollowingEnabledForTool:self])))
    {

        if(annotType == PTExtendedAnnotTypeWidget) {
            self.nextToolType = [PTFormFillTool class];
        }
        else if (annotType == PTExtendedAnnotTypeLine || annotType == PTExtendedAnnotTypeArrow || annotType == PTExtendedAnnotTypeRuler)
        {
            self.nextToolType = [PTPolylineEditTool class];
        }
        else if(annotType == PTExtendedAnnotTypeRichMedia)
        {
            self.nextToolType = [PTRichMediaTool class];
        }
        else if(annotType == PTExtendedAnnotTypeHighlight || annotType == PTExtendedAnnotTypeUnderline || annotType == PTExtendedAnnotTypeStrikeOut || annotType ==  PTExtendedAnnotTypeSquiggly) {
            self.nextToolType = [PTTextMarkupEditTool class];
        }
        else if(annotType == PTExtendedAnnotTypePolyline || annotType == PTExtendedAnnotTypePolygon || annotType == PTExtendedAnnotTypeCloudy || annotType == PTExtendedAnnotTypePerimeter || annotType == PTExtendedAnnotTypeArea)
        {
            self.nextToolType = [PTPolylineEditTool class];
        }
        else
        {
            self.nextToolType = [PTAnnotEditTool class];
        }

        if (annotIsInGroup) {
            self.nextToolType = [PTAnnotEditTool class];
        }

        return NO;
    }

    if ([self.toolManager isTextSelectionEnabledForTool:self] && ![self.currentAnnotation IsValid]) {
        [self.pdfViewCtrl SetTextSelectionMode:e_ptrectangular];
        [self.pdfViewCtrl SelectX1:location.x Y1:location.y X2:1+location.x Y2:1+location.y];
        [self.pdfViewCtrl SetTextSelectionMode:e_ptstructural];

        PTSelection* selection = [self.pdfViewCtrl GetSelection:-1];

        //if over text
        if (selection == 0 || [[selection GetQuads] size] > 0 )
        {
            self.nextToolType = [PTTextSelectTool class];
            return NO;
        }
    }

    if( [linkInfo getUrl].length > 0 && [self.toolManager isLinkFollowingEnabledForTool:self])
    {
        self.nextToolType = [PTAnnotEditTool class];
        return NO;
    }

    NSMutableArray *menuActions = [NSMutableArray array];
    if (PTAnnotationPasteboard.defaultPasteboard.annotations.count > 0) {
        UIAction *pasteAction = [UIAction actionWithTitle:PTLocalizedString(@"Paste",
                                                                            @"Paste annotations") image:nil identifier:nil handler:^(UIAction *action){[self pasteAnnotationsAtPoint];}];
        [menuActions addObject:pasteAction];
    }
    [menuActions addObjectsFromArray:[self menuActionsForExtendedAnnotTypes:
                                      @[
                                          @(PTExtendedAnnotTypeInk),
                                          @(PTExtendedAnnotTypeFreeText),
                                          @(PTExtendedAnnotTypeSignature),
                                          @(PTExtendedAnnotTypeText),
                                      ]]];

    UIMenu *shapesMenu = [UIMenu menuWithTitle:PTLocalizedString(@"Shapes…",@"Shapes submenu title") children:[self shapesMenuActions]];
    UIMenu *measureMenu = [UIMenu menuWithTitle:PTLocalizedString(@"Measure…",@"Measure submenu title") children:[self measureMenuActions]];
    UIMenu *attachMenu = [UIMenu menuWithTitle:PTLocalizedString(@"Attach…",@"Attach submenu title") children:[self attachMenuActions]];

    UIAction *selectAnnotationsAction = [UIAction actionWithTitle:PTLocalizedString(@"Select Annotations", @"Select annotations tool name") image:nil identifier:nil handler:^(UIAction *action){[self multiSelectTool];}];
    [menuActions addObjectsFromArray:@[shapesMenu, measureMenu, attachMenu, selectAnnotationsAction]];

    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:[menuActions copy]];

    *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"panTool" previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        return mainMenu;
    }];
    return YES;
}
#endif
@end
