//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextMarkupEditTool.h"

#import "PTTextSelectToolSubclass.h"

#import "PTAnnotEditTool.h"
#import "PTSelectionBar.h"
#import "PTPanTool.h"
#import "PTAnalyticsManager.h"
#import "PTColorDefaults.h"

#import "PTToolsUtil.h"

#if TARGET_OS_MACCATALYST
@interface PTTextMarkupEditTool ()
@property (nonatomic, strong) UIMenu *contextMenu;
@property (nonatomic, strong) UIMenu *typeMenu;
@end
#endif

@interface PTTextMarkupEditTool ()

/**
 Used strictly as a utility class for text annotation editing.
 */
@property (nonatomic, retain) PTAnnotEditTool* annotEditUtilityTool;

@property (nonatomic, assign) CGRect annotRect;

@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTTextMarkupEditTool

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        // Initialization code.
        _isPencilTouch = YES;
    }
    return self;
}

-(void)setToolManager:(PTToolManager *)toolManager
{
    [super setToolManager:toolManager];
    
    self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.toolManager.annotationsCreatedWithPencilOnly;
}

-(void)prepUtilityTool
{
	if( !self.annotEditUtilityTool )
		self.annotEditUtilityTool = [[PTAnnotEditTool alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
	
    self.annotEditUtilityTool.toolManager = self.toolManager;
	self.annotEditUtilityTool.currentAnnotation = self.currentAnnotation;
	self.annotEditUtilityTool.annotationPageNumber = self.annotationPageNumber;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self.annotEditUtilityTool commitSelectedAnnotationStyle];
        self.annotEditUtilityTool = nil;
    }
    
    [super willMoveToSuperview:newSuperview];
}

#pragma mark - UIMenuController actions

-(void)editSelectedAnnotationStyle
{
    [self prepUtilityTool];
    
    [self.annotEditUtilityTool editSelectedAnnotationStyle];
}

-(void)deleteSelectedAnnotation
{
    [self ClearSelectionBars];
    [self ClearSelectionOnly];
    self.selectionStart = self.selectionEnd = CGPointZero;
    [super deleteSelectedAnnotation];
}

#pragma mark Changing annotation type

-(void)editSelectedAnnotationType
{
	[self attachAnnotTypeChangeMenuItems];
	[self ShowUtilityMenuController];
}

-(void)changeSelectedAnnotationToHighlight
{
	[self changeSelectedTextMarkupToType:PTExtendedAnnotTypeHighlight];
}

-(void)changeSelectedAnnotationToUnderline
{
	[self changeSelectedTextMarkupToType:PTExtendedAnnotTypeUnderline];
}

-(void)changeSelectedAnnotationToSquiggly
{
	[self changeSelectedTextMarkupToType:PTExtendedAnnotTypeSquiggly];
}

-(void)changeSelectedAnnotationToStrikeout
{
	[self changeSelectedTextMarkupToType:PTExtendedAnnotTypeStrikeOut];
}

-(void)copySelectedTextMarkupText
{
    PTTextExtractor* textExtractor = [[PTTextExtractor alloc] init];
    PTPage *page = [[self.pdfViewCtrl GetDoc] GetPage:self.annotationPageNumber];
    [textExtractor Begin:page clip_ptr:0 flags:e_ptno_ligature_exp];
    NSString *textToCopy = [textExtractor GetTextUnderAnnot:self.currentAnnotation];
    if (textToCopy && textToCopy.length > 0) {
        [[UIPasteboard generalPasteboard] setString:textToCopy];
    }
}

#pragma mark - MenuController menu adding

-(void)attachAnnotTypeChangeMenuItems
{
	NSMutableArray* menuItems = [[NSMutableArray alloc] init];
    
    UIMenuItem* menuItem;
    
    PTExtendedAnnotType annotType = self.currentAnnotation.extendedAnnotType;
	
	if (annotType != PTExtendedAnnotTypeHighlight && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeHighlight]) {
		menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Highlight", @"Highlight tool name") action:@selector(changeSelectedAnnotationToHighlight)];
		[menuItems addObject:menuItem];
	}
    
	if (annotType != PTExtendedAnnotTypeUnderline && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeUnderline]) {
		menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Underline", @"Underline tool name") action:@selector(changeSelectedAnnotationToUnderline)];
		[menuItems addObject:menuItem];
	}

    if (annotType != PTExtendedAnnotTypeSquiggly && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeSquiggly]) {
		menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Squiggly", @"Squiggly tool name") action:@selector(changeSelectedAnnotationToSquiggly)];
		[menuItems addObject:menuItem];
	}
	
    if (annotType != PTExtendedAnnotTypeStrikeOut && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeStrikeOut]) {
		menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Strikeout", @"Strikeout tool name") action:@selector(changeSelectedAnnotationToStrikeout)];
		[menuItems addObject:menuItem];
	}
    
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    theMenu.menuItems = menuItems;
}

- (void)attachInitialMenuItems
{
    BOOL hasEditPermission = [self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation];
    
    NSMutableArray<UIMenuItem *> *menuItems = [NSMutableArray array];
    
    if (hasEditPermission) {
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Style", @"") action:@selector(editSelectedAnnotationStyle)]];
    }
    
    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)]];

    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Copy", @"Copy text markup text menu item") action:@selector(copySelectedTextMarkupText)]];

    
    if (hasEditPermission) {
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Type", @"") action:@selector(editSelectedAnnotationType)]];
        
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Flatten", @"") action:@selector(flattenSelectedAnnotations)]];
        
        
        [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Delete", @"") action:@selector(deleteSelectedAnnotation)]];
    }
    
    UIMenuController *menu = UIMenuController.sharedMenuController;
    menu.menuItems = menuItems;
}

#if TARGET_OS_MACCATALYST
#pragma mark - UIContextMenus
- (UIMenu *)contextMenu
{
    BOOL hasEditPermission = [self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation];
    if (!_contextMenu) {
        NSMutableArray* menuActions = [NSMutableArray array];
        UIAction* menuAction;
        if (hasEditPermission) {
            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Style", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self editSelectedAnnotationStyle];}];
            [menuActions addObject:menuAction];
        }
        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Note", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self editSelectedAnnotationNote];}];
        [menuActions addObject:menuAction];

        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Copy", @"Copy text markup text menu item") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self copySelectedTextMarkupText];}];
        [menuActions addObject:menuAction];

        if (hasEditPermission) {
            [menuActions addObject:self.typeMenu];

            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Flatten", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self flattenSelectedAnnotations];}];
            [menuActions addObject:menuAction];

            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Delete", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self deleteSelectedAnnotation];}];
            [menuActions addObject:menuAction];
        }
        _contextMenu = [UIMenu menuWithTitle:@"Text Markup Menu" children:menuActions];
    }
    return _contextMenu;
}

- (UIMenu *)typeMenu
{
    NSMutableArray* menuActions = [NSMutableArray array];
    UIAction* menuAction;

    PTExtendedAnnotType annotType = self.currentAnnotation.extendedAnnotType;

    if (annotType != PTExtendedAnnotTypeHighlight && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeHighlight]) {
        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Highlight", @"Highlight tool name") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self changeSelectedAnnotationToHighlight];}];
        [menuActions addObject:menuAction];
    }

    if (annotType != PTExtendedAnnotTypeUnderline && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeUnderline]) {
        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Underline", @"Underline tool name") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self changeSelectedAnnotationToUnderline];}];
        [menuActions addObject:menuAction];
    }

    if (annotType != PTExtendedAnnotTypeSquiggly && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeSquiggly]) {
        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Squiggly", @"Squiggly tool name")  image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self changeSelectedAnnotationToSquiggly];}];
        [menuActions addObject:menuAction];
    }

    if (annotType != PTExtendedAnnotTypeStrikeOut && [self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeStrikeOut]) {
        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Strikeout", @"Strikeout tool name") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self changeSelectedAnnotationToStrikeout];}];
        [menuActions addObject:menuAction];
    }
    _typeMenu = [UIMenu menuWithTitle:@"Type" children:menuActions];
    return _typeMenu;
}
#endif

-(void)flattenSelectedAnnotations
{
    [self flattenAnnotations:@[self.currentAnnotation]];
    // Switch to default tool.
    self.nextToolType = self.defaultClass;
    // Create tool switch event back to default class.
    [self.toolManager createSwitchToolEvent:self.nextToolType];
}

- (void)ShowUtilityMenuController
{
    if (self.selectionLayers.count != 0 && self.selectionOnScreen) {
        UIMenuController *theMenu = UIMenuController.sharedMenuController;
        
        [theMenu setTargetRect:CGRectMake(self.selectionStartCorner.x, self.selectionStartCorner.y-15, self.selectionEndCorner.x-self.selectionStartCorner.x, self.selectionEndCorner.y-self.selectionStartCorner.y+30) inView:self];
        
        if (![self shouldShowMenu:theMenu forAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber]) {
            // don't show menu if delegate says not to.
            return;
        }
        
        [theMenu setMenuVisible:YES animated:YES];
    }
}

#pragma mark - Annotation Modification

-(void)changeSelectedTextMarkupToType:(PTExtendedAnnotType)annotType
{
	@try {
		[self.pdfViewCtrl DocLock:YES];
        
		PTTextMarkup *textMarkup = [[PTTextMarkup alloc] initWithAnn:self.currentAnnotation];
		PTObj *sdfObj = [textMarkup GetSDFObj];
        
        // Get the text markup Subtype name.
        NSString *typeName = nil;
        switch (annotType) {
            case PTExtendedAnnotTypeHighlight:
                typeName = @"Highlight";
                break;
            case PTExtendedAnnotTypeStrikeOut:
                typeName = @"StrikeOut";
                break;
            case PTExtendedAnnotTypeUnderline:
                typeName = @"Underline";
                break;
            case PTExtendedAnnotTypeSquiggly:
                typeName = @"Squiggly";
                break;
            default:
                PTLog(@"Invalid annot type for text markup: %@", PTExtendedAnnotNameFromType(annotType));
                return;
                break;
        }
        
        NSAssert(typeName != nil, @"Text markup Subtype name must be non-null");
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        // Update text markup Subtype.
        [sdfObj PutName:@"Subtype" name:typeName];
		
		[textMarkup RefreshAppearance];
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlock];
	}

    #if TARGET_OS_MACCATALYST
    self.contextMenu = nil;
    #endif

    [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
	
	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

-(void)changeSelectedTextMarkupAnnotQuads
{
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
		
		
		PTPage* p = [doc GetPage:self.annotationPageNumber];
		
		
		if( ![p IsValid] )
		{
			return;
		}
		
		assert([p IsValid]);
		
		PTSelection* sel = [self.pdfViewCtrl GetSelection:self.annotationPageNumber];
		PTVectorQuadPoint* quads = [sel GetQuads];
		NSUInteger numQuads = [quads size];
		
		PTPDFRect* oldRect = [self.currentAnnotation GetRect];
		
		PTPDFPoint* startRectPointA = [[PTPDFPoint alloc] initWithPx:[oldRect GetX1] py:[oldRect GetY1]];
		PTPDFPoint* startRectPointB = [[PTPDFPoint alloc] initWithPx:[oldRect GetX2] py:[oldRect GetY2]];
		
		PTPDFPoint* newPtA = [self.pdfViewCtrl ConvPagePtToScreenPt:startRectPointA page_num:self.annotationPageNumber];
		PTPDFPoint* newPtB = [self.pdfViewCtrl ConvPagePtToScreenPt:startRectPointB page_num:self.annotationPageNumber];
		
		PTPDFRect* pageSpaceOldRect = [[PTPDFRect alloc] initWithX1:[newPtA getX] y1:[newPtA getY] x2:[newPtB getX] y2:[newPtB getY]];
		
		PTPDFRect* boundingRect;
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
		
		// overwrite existing quads with nothing
		[[self.currentAnnotation GetSDFObj] EraseDictElementWithKey:@"QuadPoints"];
		[[self.currentAnnotation GetSDFObj] EraseDictElementWithKey:@"Rect"];
		
		if( numQuads > 0 )
		{
			PTQuadPoint* qp = [quads get:0];
			
			TRN_point* point = [qp getP1];
			
			double x1 = [point getX];
			double y1 = [point getY];
			
			point = [qp getP3];
			
			double x2 = [point getX];
			double y2 = [point getY];
			
			PTPDFRect* r = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
			
			if( ! boundingRect )
			{
				boundingRect = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
				[self.currentAnnotation SetRect:boundingRect];
			}
			else
				boundingRect = [PTTool GetRectUnion:boundingRect Rect2:r];
			
			PTTextMarkup* mktp = [[PTTextMarkup alloc] initWithAnn:self.currentAnnotation];
			
			for( int i=0; i < numQuads; ++i )
			{
				PTQuadPoint* quad = [quads get:i];

				if( self.textMarkupAdobeHack )
				{
					// Acrobat and Preview do not follow the PDF specification regarding
					// the ordering of quad points in a text markup annotation. Enable
					// this code for compatibility with those viewers.

					PTPDFPoint* point1 = [quad getP1];
					PTPDFPoint* point2 = [quad getP2];
					PTPDFPoint* point3 = [quad getP3];
					PTPDFPoint* point4 = [quad getP4];
					
					PTQuadPoint* newQuad = [[PTQuadPoint alloc] init];
					
					[newQuad setP1:point4];
					[newQuad setP2:point3];
					[newQuad setP3:point1];
					[newQuad setP4:point2];
					
					[mktp SetQuadPoint:i qp:newQuad];
					
				}
				else
				{
					[mktp SetQuadPoint:i qp:quad];
				}
				
			}
			
			[mktp RefreshAppearance];
			[self.pdfViewCtrl UpdateWithRect:pageSpaceOldRect];
			[self.pdfViewCtrl UpdateWithAnnot:mktp page_num:self.annotationPageNumber];
			
		}
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
	
	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
	
    [self ClearSelectionBars];
    
    [self ClearSelectionOnly];
}

#pragma mark - Annotation Selection

- (BOOL)selectTextMarkupAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber
{
    return [self selectTextMarkupAnnotation:annotation onPageNumber:pageNumber showMenu:!PT_ToolsMacCatalyst];
}

- (BOOL)selectTextMarkupAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber showMenu:(BOOL)showMenu
{
    @try {
        [self.pdfViewCtrl DocLockRead];
        
        if (![annotation IsValid]) {
            return NO;
        }
        
        PTExtendedAnnotType annotType = [annotation extendedAnnotType];
        
        if (annotType == PTExtendedAnnotTypeHighlight || annotType == PTExtendedAnnotTypeUnderline || annotType == PTExtendedAnnotTypeStrikeOut || annotType == PTExtendedAnnotTypeSquiggly) {
            // Set current annotation.
            self.currentAnnotation = annotation;
            self.annotationPageNumber = pageNumber;
            
            if (![self.toolManager tool:self canEditAnnotation:self.currentAnnotation]) {
                // Cannot select/edit annotation.
                return NO;
            }
            
            // Check if the annotation should be selected.
            if (![self shouldSelectAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber]) {
                return NO;
            }
            
            [self ClearSelectionBars];
            [self selectCurrentTextMarkupAnnotation];
            [self attachInitialMenuItems];
            
            // Notify that the annotation was selected.
            [self didSelectAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            
            // Successfully selected annotation.
            return YES;
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        [self.pdfViewCtrl DocUnlockRead];
        if (showMenu) {
            [self ShowMenuController];
        }
    }

    return NO;
}

-(void)selectCurrentTextMarkupAnnotation
{
	if( !self.currentAnnotation )
		return;
	
	// get the quads that represent the text that is annotated (not the entire anntation rect)
	PTTextMarkup* mkup = [[PTTextMarkup alloc] initWithAnn:self.currentAnnotation];
	
	int numQuads = [mkup GetQuadPointCount];
	
	NSMutableArray* textMarkupQuads = [[NSMutableArray alloc] init];
	
	for(int m = 0; m < numQuads; ++m)
	{
		PTQuadPoint* qp = [mkup GetQuadPoint:m];
        
        
        double minX = fmin([[qp getP1] getX], fmin([[qp getP2] getX], fmin([[qp getP3] getX], [[qp getP4] getX])));
        double minY = fmin([[qp getP1] getY], fmin([[qp getP2] getY], fmin([[qp getP3] getY], [[qp getP4] getY])));
        double maxX = fmax([[qp getP1] getX], fmax([[qp getP2] getX], fmax([[qp getP3] getX], [[qp getP4] getX])));
        double maxY = fmax([[qp getP1] getY], fmax([[qp getP2] getY], fmax([[qp getP3] getY], [[qp getP4] getY])));

        PTPDFRect* bbox = [[PTPDFRect alloc] initWithX1:minX y1:minY x2:maxX y2:maxY];
        [bbox Normalize];

        // use the y centre of the bounding box to avoid ever over-selecting when lines are close together
        PTRotate rotation = [[[self.pdfViewCtrl GetDoc] GetPage:self.annotationPageNumber] GetRotation];
        
        double height;
        
        if( rotation == e_pt0 || rotation == e_pt180)
            height = [bbox Height];
        else
            height = [bbox Width];
        
        double centre = height/2;
        
        if( rotation == e_pt0 || rotation == e_pt180)
            [bbox InflateWithXY:0 y:-centre+1];
        else
            [bbox InflateWithXY:-centre+1 y:0];
        


		[textMarkupQuads addObject:bbox];
	}
	
	self.selectionStartPageNumber = self.selectionEndPageNumber = self.annotationPageNumber;
	
	PTPDFRect* startRect = textMarkupQuads.firstObject;
	PTPDFRect* endRect = textMarkupQuads.lastObject;
	
    self.selectionStart = CGPointMake(([self.pdfViewCtrl GetRightToLeftLanguage] ? [startRect GetX2] : [startRect GetX1]), [startRect GetY1]);
    self.selectionEnd = CGPointMake(( [self.pdfViewCtrl GetRightToLeftLanguage] ? [endRect GetX1] : [endRect GetX2]), [endRect GetY2]);
	
	NSArray<NSValue*>* selection = [self MakeSelection];
		
    CGRect firstQuad = [selection.firstObject CGRectValue];

    int rtlOffset = 0;
    if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES)
        rtlOffset = firstQuad.size.width;

    self.selectionStartCorner = CGPointMake(firstQuad.origin.x + [self.pdfViewCtrl GetHScrollPos]+rtlOffset, firstQuad.origin.y + [self.pdfViewCtrl GetVScrollPos]);

    CGRect lastQuad = [selection.lastObject CGRectValue];

    rtlOffset = 0;
    if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES)
        rtlOffset = lastQuad.size.width;

    self.selectionEndCorner = CGPointMake(lastQuad.origin.x + lastQuad.size.width + [self.pdfViewCtrl GetHScrollPos] - rtlOffset, lastQuad.origin.y + lastQuad.size.height/2 + [self.pdfViewCtrl GetVScrollPos]);

    // Only draw selection lines and bars if annot has edit permission.
    BOOL drawBars = [self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation];
    
    [self DrawSelectionQuads:selection WithLines:drawBars WithDropAnimation:NO];
    if (drawBars) {
        [self DrawSelectionBars:selection];
    }
}

-(BOOL)handleSelectionEvent:(UIGestureRecognizer *)sender
{
	CGPoint down = [sender locationInView:self.pdfViewCtrl];
    @try
	{
		[self.pdfViewCtrl DocLockRead];
		
		self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
        
        self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y];
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@", exception.name, exception.reason);
	}
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    BOOL selected = [self selectTextMarkupAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    if (!selected) {
        // Switch to default tool.
        self.nextToolType = self.defaultClass;
        // Create tool switch event back to default class.
        [self.toolManager createSwitchToolEvent:self.nextToolType];
        return YES; // Stop Tool loop.
    }
	if (![self.currentAnnotation IsValid]) {
        // Switch to default tool.
		self.nextToolType = self.defaultClass;
		return NO;
	}
	
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    BOOL ret = [super pdfViewCtrl:pdfViewCtrl touchesShouldBegin:touches withEvent:event inContentView:view];

    
    if( [touches.allObjects.firstObject.view isKindOfClass:[PTSelectionBar class]] )
    {
        ret =  YES;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }

    return ret;

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    if( [view isKindOfClass:[PTSelectionBar class]] )
    {
        return NO;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        return !self.isPencilTouch;
    }
    
    
    if( ![super pdfViewCtrl:pdfViewCtrl touchesShouldCancelInContentView:view] )
	{
		return NO;
	}
	else
	{
		self.nextToolType = self.defaultClass;
		return YES;
	}
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = touches.allObjects[0];
	
    if( [touch.view isKindOfClass:[PTSelectionBar class]])
	{
		return [super pdfViewCtrl:pdfViewCtrl onTouchesBegan:touches withEvent:event];
	}
    else
	{
		[self ClearSelectionBars];
		[self ClearSelectionOnly];
		self.nextToolType = self.defaultClass;
        
        if( [self.nextToolType createsAnnotation] )
        {
            [self.toolManager createSwitchToolEvent:@"Back to creation tool"];
        
            return YES;
        }
        
		return NO;
	}
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	
	PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];
	
	if( !(annotType == PTExtendedAnnotTypeHighlight || annotType == PTExtendedAnnotTypeUnderline || annotType == PTExtendedAnnotTypeStrikeOut || annotType == PTExtendedAnnotTypeSquiggly)	)
	{
		return YES;
	}

	[super pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
	
	// 2nd condition: only select if not already selected
	if( self.currentAnnotation )
	{
		// remove little dots after adjusting an annotation in creation mode, and clicking to dismiss
		
		if( self.leadingBar != nil )
		{
			[self.leadingBar removeFromSuperview];
			self.leadingBar = nil;
		}
		
		if( self.trailingBar != nil )
		{
			[self.trailingBar removeFromSuperview];
			self.trailingBar = nil;
		}
		
		// necessary to select an annot immediately after it is created
		[self selectCurrentTextMarkupAnnotation];
		
        if (!PT_ToolsMacCatalyst) {
            [self attachInitialMenuItems];
            [self ShowMenuController];
        }
	}
	
	return YES;
	
}



-(BOOL)onSwitchToolEvent:(id)userData
{
    if( userData && [userData isEqual:@"Back to creation tool"] )
    {
        self.nextToolType = self.defaultClass;
        return NO;
    }
    else if (userData == self.nextToolType && self.nextToolType != Nil) {
        // We are switching to the next tool type.
        return NO;
    } else {
        [self selectCurrentTextMarkupAnnotation];
        [self attachInitialMenuItems];
        [self ShowMenuController];
        return YES;
    }
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    return [self handleSelectionEvent:(UITapGestureRecognizer *)gestureRecognizer];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    return [self handleSelectionEvent:(UILongPressGestureRecognizer *)gestureRecognizer];
}

#pragma mark - TextSelectTool

-(void)selectionBarUp:(PTSelectionBar *)bar withTouches:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[super selectionBarUp:bar withTouches:touches withEvent:event];
	
	@try
	{
		[self.pdfViewCtrl DocLock:YES];

		[self changeSelectedTextMarkupAnnotQuads];

		[self selectCurrentTextMarkupAnnotation];
		
		self.nextToolType = [PTTextMarkupEditTool class];
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@", exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlock];
	}
}

#pragma mark - <PTNoteEditControllerDelegate>

-(void)noteEditController:(PTNoteEditController*)noteEditController saveNewNoteForMovingAnnotationWithString:(NSString*)str
{
	[super noteEditController:noteEditController saveNewNoteForMovingAnnotationWithString:str];
	[self ShowMenuController];
}

#pragma mark - UIContextMenuInteractionDelegate

#if TARGET_OS_MACCATALYST
- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location configuration:(UIContextMenuConfiguration * _Nullable __autoreleasing *)configuration
{
    PTPDFRect *annotPageRect = [self.currentAnnotation GetRect];
    CGRect annotScreenRect = [self.pdfViewCtrl PDFRectPage2CGRectScreen:annotPageRect PageNumber:self.annotationPageNumber];
    if (CGRectContainsPoint(annotScreenRect, location)) {
        *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"textMarkupContextMenuConfiguration" previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            return self.contextMenu;
        }];
        return YES;
    }
    return NO;
}
#endif
@end
