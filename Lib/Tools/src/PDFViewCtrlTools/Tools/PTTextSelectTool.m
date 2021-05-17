//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextSelectTool.h"
#import "PTTextSelectToolSubclass.h"

#import "PTSelectionBar.h"
#import "PTMagnifierView.h"
#import "PTPanTool.h"
#import "PTAnalyticsManager.h"
#import "PTColorDefaults.h"
#import "PTAnnotEditTool.h"
#import "PTTextMarkupEditTool.h"
#import "PTTextSearchViewController.h"

#import "PTToolsUtil.h"
#import "PTTimer.h"
#import "UIView+PTAdditions.h"

#if TARGET_OS_MACCATALYST
@interface PTTextSelectTool()
@property (nonatomic, strong) UIMenu*  contextMenu;
@end
#endif

@interface PTTextSelectTool()<CAAnimationDelegate>
{
    PTSelectionBar* m_moving_selection_bar;

    PTMagnifierView* loupe;

    BOOL swapBars;

    BOOL tapOK;

    CGPoint lastCurrStartCorner;
    CGPoint lastCurrEndCorner;
    PTTimer *doubleTapSelectTimer;
    CGPoint doubleTapPoint;
    CGPoint initialSelectionStartScreenPt;
    CGPoint initialSelectionEndScreenPt;
}

#pragma mark Private (redeclared) properties

@property (readwrite, nonatomic, assign) BOOL selectionOnScreen;

@property (readwrite, nonatomic, copy) NSArray<__kindof CALayer*>* selectionLayers;

@property (nonatomic, strong) UIImpactFeedbackGenerator*  impactFeedbackGenerator;

@end

@implementation PTTextSelectTool

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        _selectionLayers = [NSArray array];
    }
    
    return self;
}

-(void)removeAppearance
{
	[self ClearSelectionBars];
    [self ClearSelectionOnly];
    if( loupe.superview != nil )
        [loupe removeFromSuperview];
}

- (void)dealloc
{
	[self removeAppearance];
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
	if( newSuperview == nil)
		[self removeAppearance];
	
	[super willMoveToSuperview:newSuperview];
}

#if TARGET_OS_MACCATALYST
- (UIMenu *)contextMenu
{
    if (!_contextMenu) {
        NSMutableArray* menuActions = [NSMutableArray array];
        UIAction* menuAction;

        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Copy", @"Copy selected text menu item") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self textCopy];}];
        [menuActions addObject:menuAction];

        if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeHighlight]) {
            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Highlight", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self textHighlight];}];
            [menuActions addObject:menuAction];
        }

        if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeStrikeOut]) {
            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Strikeout", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self textStrikeout];}];
            [menuActions addObject:menuAction];
        }

        if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeUnderline]) {
            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Underline", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self textUnderline];}];
            [menuActions addObject:menuAction];
        }

        if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeSquiggly]) {
            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Squiggly", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self textSquiggly];}];
            [menuActions addObject:menuAction];
        }

        menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Define", @"") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self defineTerm];}];
        [menuActions addObject:menuAction];

        if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeRedact]) {
            menuAction = [UIAction actionWithTitle:PTLocalizedString(@"Redaction", @"Text redaction annot") image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {[self textRedaction];}];
            [menuActions addObject:menuAction];
        }
        _contextMenu = [UIMenu menuWithTitle:@"Text Menu" children:menuActions];
    }
    return _contextMenu;
}
#endif
- (void) attachInitialMenuItems
{
    NSMutableArray* menuItems = [NSMutableArray array];

    UIMenuItem* menuItem;
    
    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Copy", @"Copy selected text menu item") action:@selector(textCopy)];
    [menuItems addObject:menuItem];

    if ([self.toolManager.delegate respondsToSelector:@selector(viewControllerForToolManager:)]) {
        if ([self.toolManager.delegate viewControllerForToolManager:self.toolManager] != nil) {
            menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Search", @"Search document for selected text menu item") action:@selector(textSearch)];
            [menuItems addObject:menuItem];
        }
    }

    if( self.toolManager.textEditingEnabled )
    {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Edit", @"") action:@selector(editText)];
        [menuItems addObject:menuItem];
    }
    
    
    if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeHighlight]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Highlight", @"") action:@selector(textHighlight)];
        [menuItems addObject:menuItem];
    }
    
    if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeStrikeOut]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Strikeout", @"") action:@selector(textStrikeout)];
        [menuItems addObject:menuItem];
    }
    
    if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeUnderline]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Underline", @"") action:@selector(textUnderline)];
        [menuItems addObject:menuItem];
    }
    
    if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeSquiggly]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Squiggly", @"") action:@selector(textSquiggly)];
        [menuItems addObject:menuItem];
    }
    
    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Define", @"") action:@selector(defineTerm)];
    [menuItems addObject:menuItem];

    if ([self.toolManager tool:self canCreateExtendedAnnotType:PTExtendedAnnotTypeRedact]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Redaction", @"Text redaction annot") action:@selector(textRedaction)];
        [menuItems addObject:menuItem];
    }
    
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    theMenu.menuItems = menuItems;
}

-(void)defineTerm
{
    #if !TARGET_OS_MACCATALYST
	NSString* term = [self GetSelectedTextFromPage:self.selectionStartPageNumber ToPage:self.selectionEndPageNumber];
	term = [term stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
	UIReferenceLibraryViewController* reference = [[UIReferenceLibraryViewController alloc] initWithTerm:term];
	reference.modalPresentationStyle = UIModalPresentationPopover;
	
    [self.pt_viewController presentViewController:reference animated:YES completion:nil];
	
	UIPopoverPresentationController *popController = reference.popoverPresentationController;
	popController.permittedArrowDirections = (UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown);
	CGRect presentationRect = CGRectMake(self.selectionStartCorner.x, self.selectionStartCorner.y-15, self.selectionEndCorner.x-self.selectionStartCorner.x, self.selectionEndCorner.y-self.selectionStartCorner.y+30);
	
	popController.sourceRect = presentationRect;
	popController.sourceView = self;
    #endif
}

-(void)textCopy
{
    // copy string to the pasteboard
    [self CopySelectedTextToPasteboard];
    
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Copy selected"];
}

-(void)textSearch
{
    NSString *searchString = [self GetSelectedTextFromPage:self.selectionStartPageNumber ToPage:self.selectionEndPageNumber];
    PTTextSearchViewController *textSearchViewController = [[PTTextSearchViewController allocOverridden] initWithPDFViewCtrl:self.pdfViewCtrl];
    textSearchViewController.showsKeyboardOnViewDidAppear = NO;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:textSearchViewController];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:nil];
    [self.toolManager.viewController presentViewController:nav animated:NO completion:^{
        [self removeAppearance];
        [textSearchViewController findText:searchString];
    }];
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    return NO;
}

-(void)editText
{    
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] EditText selected"];
    
    __block NSString* selectedText;
    __block PTVectorQuadPoint* selectionQuads;
    
    NSError* error;
    
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        
        for ( int ipage = self.selectionStartPageNumber; ipage <= self.selectionEndPageNumber; ++ipage )
        {
            PTPage* p = [doc GetPage:ipage];
            
            if( ![p IsValid] )
            {
                return;
            }
            
            assert([p IsValid]);
            
            PTSelection* sel = [self.pdfViewCtrl GetSelection:ipage];
            selectedText = [sel GetAsUnicode];
            selectionQuads = [sel GetQuads];
            [sel GetQuads];
            
        }
    }
    error:&error];
    
    NSAssert(error == nil, @"could not get text");
    
    if( error )
    {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:PTLocalizedString(@"Edit Text", @"")
                                          message:@"This is a preliminary demonstration of content editing. It is not ready for production. Please get in touch with PDFTron if you are interested in a more advanced version of this technology."
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Cancel", @"")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        NSError* error;
        
        [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
            PTContentReplacer* contentReplacer = [[PTContentReplacer alloc] init];
            
            
            PTQuadPoint* qp = [selectionQuads get:0];
                           
           TRN_point* point = [qp getP1];
           
           double x1 = [point getX];
           double y1 = [point getY];
           
           point = [qp getP3];
           
           double x2 = [point getX]+10;
           double y2 = [point getY];
           
           PTPDFRect* replacementRect = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];

            PTPage *page = [doc GetPage:self.selectionStartPageNumber];
            
            [contentReplacer AddText: replacementRect replacement_text:alertController.textFields.firstObject.text];
            [contentReplacer Process: page];
            
            [self.pdfViewCtrl ClearSelection];
            
            [self.pdfViewCtrl Update:YES];
            
            self.nextToolType = [PTPanTool class];
            [self.toolManager createSwitchToolEvent:nil];
            
        } error:&error];
        
        if( !error )
        {
            [self.toolManager.undoRedoManager pageContentModifiedOnPageNumber:self.selectionStartPageNumber];
        }
        
     }];
        
    
    [alertController addAction:cancelAction];
    [alertController addAction:addAction];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = selectedText;
     }];
    
    [self.pt_viewController presentViewController:alertController animated:YES completion:nil];
    

}

-(void)textHighlight
{
    [self createTextMarkupAnnot:PTExtendedAnnotTypeHighlight];
	
	self.nextToolType = [PTTextMarkupEditTool class];
	[self.toolManager createSwitchToolEvent:nil];
    
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Highlight selected"];
}

-(void)textSquiggly
{
    [self createTextMarkupAnnot:PTExtendedAnnotTypeSquiggly];
	
	self.nextToolType = [PTTextMarkupEditTool class];
	[self.toolManager createSwitchToolEvent:nil];
    
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Squiggly selected"];
}

-(void)textUnderline
{
    [self createTextMarkupAnnot:PTExtendedAnnotTypeUnderline];
	
	self.nextToolType = [PTTextMarkupEditTool class];
	[self.toolManager createSwitchToolEvent:nil];
    
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Underline selected"];
}

-(void)textStrikeout
{
    [self createTextMarkupAnnot:PTExtendedAnnotTypeStrikeOut];
	
	self.nextToolType = [PTTextMarkupEditTool class];
	[self.toolManager createSwitchToolEvent:nil];
    
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Strikeout selected"];
}

-(void)textRedaction
{
    [self createRedactionAnnot];
    
    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:nil];
    
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[QuickMenu Tool] Redaction selected"];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{

    if( PT_ToolsMacCatalyst == NO )
    {
        CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];

        [self longPressTextSelectAt: down WithRecognizer: gestureRecognizer];
    }
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
    
    if (sender.state == UIGestureRecognizerStateEnded && tapOK)     
    {   
        [self ClearSelectionBars];
        [self ClearSelectionOnly];
        [self.pdfViewCtrl becomeFirstResponder]; // (hides keyboard)
        
        self.nextToolType = [PTPanTool class];
        
        return NO;
    }
    
    return YES;
    
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    tapOK = YES;

    UITouch *touch = touches.allObjects[0];
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
    if( [touch.view isKindOfClass:[PTSelectionBar class]] || PT_ToolsMacCatalyst )
    {

        m_moving_selection_bar = (PTSelectionBar*)touch.view;
        
        if( PT_ToolsMacCatalyst )
        {
            m_moving_selection_bar = [[PTSelectionBar alloc] initWithFrame:CGRectMake(down.x, down.y, 8, 8)];
            [m_moving_selection_bar setIsLeft:NO];
            self.selectionStartPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y];
            self.selectionStart = [self convertScreenPtToPagePt:down onPageNumber:self.selectionStartPageNumber];
        }
        
        if( self.selectionOnScreen ) // there is currently selected text
        {
            NSArray<NSValue*>* selection = [self MakeSelection];
            
            CGRect firstQuad = [selection[0] CGRectValue];
			
			int ltrOffsetFirst = 0;
			if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES)
			{
				ltrOffsetFirst = firstQuad.size.width;
			}
			
            self.selectionStartCorner = CGPointMake(firstQuad.origin.x + ltrOffsetFirst +[self.pdfViewCtrl GetHScrollPos], firstQuad.origin.y + [self.pdfViewCtrl GetVScrollPos]+firstQuad.size.height/2);
            
            CGRect lastQuad = [selection[selection.count-1] CGRectValue];
			
			int ltrOffsetLast = 0;
			
			if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES)
			{
				ltrOffsetLast = lastQuad.size.width;
			}
			
            self.selectionEndCorner = CGPointMake(lastQuad.origin.x + lastQuad.size.width - ltrOffsetLast + [self.pdfViewCtrl GetHScrollPos], lastQuad.origin.y + lastQuad.size.height/2 + [self.pdfViewCtrl GetVScrollPos]);
        }
    } else if (touch.tapCount == 2){
        doubleTapPoint = down;
        [doubleTapSelectTimer invalidate];
        doubleTapSelectTimer = [PTTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(selectTextAtDoubleTapPt) userInfo:nil repeats:NO];
    }
    else
    {

        m_moving_selection_bar = 0;
    }
    
    
    if( self.nextToolType )
        return NO;

    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    tapOK = NO;
	
	UITouch *touch = touches.allObjects[0];
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
	
	// make sure we don't try to select off the page.
	if( [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y] <= 0 )
	{
		[loupe removeFromSuperview];
		return YES;
	}
    if (!CGPointEqualToPoint(doubleTapPoint, CGPointZero)) {
        CGRect initialSelectionRect = CGRectMake(initialSelectionStartScreenPt.x, initialSelectionStartScreenPt.y, initialSelectionEndScreenPt.x-initialSelectionStartScreenPt.x, initialSelectionEndScreenPt.y-initialSelectionStartScreenPt.y);
        if (!CGRectContainsPoint(initialSelectionRect, down)) {
            if ((down.x > initialSelectionRect.origin.x + initialSelectionRect.size.width && !(down.y < initialSelectionRect.origin.y)) || down.y > initialSelectionRect.origin.y + initialSelectionRect.size.height) {
                m_moving_selection_bar = self.trailingBar;
            }else if(down.x < initialSelectionRect.origin.x || down.y < initialSelectionRect.origin.y) {
                m_moving_selection_bar = self.leadingBar;
            }
        }else{
            [self selectTextAtDoubleTapPt];
            m_moving_selection_bar = 0;
            [loupe removeFromSuperview];
            return YES;
        }
    }
    if( m_moving_selection_bar )
        [self selectionBarMoved:m_moving_selection_bar withTouches:touches withEvent:event];
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    tapOK = YES;
    [doubleTapSelectTimer invalidate];
    doubleTapPoint = CGPointZero;

	UITouch *touch = touches.allObjects[0];
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
	
    if( m_moving_selection_bar && [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y] > 0 )
        [self selectionBarUp:m_moving_selection_bar withTouches:touches withEvent:event];
    
    [self.pdfViewCtrl RequestRendering];
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
    if (PT_ToolsMacCatalyst) {
        doubleTapPoint = down;
        [self selectTextAtDoubleTapPt];
        return YES;
    }
    if (CGPointEqualToPoint(doubleTapPoint, CGPointZero)) {
        return YES;
    }
    return NO;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    doubleTapPoint = CGPointZero;
    return [self pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
}

-(void)showSelectionMenu
{
    [self ShowMenuController];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    
    if ( [view isKindOfClass:[PTSelectionBar class]] || PT_ToolsMacCatalyst )
    {
        // if this is not done, the scroll view takes over if it looks like a scroll action
        return NO;
    }
    else
        return YES;
}

-(CGPoint)GetFirstDotPoint:(NSArray<NSValue*>*)selection
{
    CGRect firstSelectionRect = [selection[0] CGRectValue];
	
	PTRotate currentRotation = [self.pdfViewCtrl GetRotation];
	
	int rtlOffset = ([self.pdfViewCtrl GetRightToLeftLanguage] == YES) ? firstSelectionRect.size.width : 0;

	if( currentRotation == e_pt0 || currentRotation == e_pt180 )
		return CGPointMake(firstSelectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos]-2+rtlOffset, firstSelectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]);
	else
		return CGPointMake(firstSelectionRect.origin.x+rtlOffset+[self.pdfViewCtrl GetHScrollPos], firstSelectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]+7);

}

-(CGPoint)GetSecondDotPoint:(NSArray<NSValue*>*)selection
{
    CGRect lastSelectionRect = [selection[selection.count-1] CGRectValue];

	PTRotate currentRotation = [self.pdfViewCtrl GetRotation];
	

	if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES )
	{
		if( currentRotation == e_pt0 || currentRotation == e_pt180 )
			return CGPointMake(lastSelectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos], lastSelectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]+lastSelectionRect.size.height);
		else
			return CGPointMake(lastSelectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos]+lastSelectionRect.size.width, lastSelectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]+lastSelectionRect.size.height-5);

	}
	else
	{
		if( currentRotation == e_pt0 || currentRotation == e_pt180 )
			return CGPointMake(lastSelectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos]+lastSelectionRect.size.width, lastSelectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]+lastSelectionRect.size.height);
		else
			return CGPointMake(lastSelectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos], lastSelectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]+lastSelectionRect.size.height-5);

		

	}
}

- (void) DrawSelectionBars:(NSArray<NSValue*>*)selection {
	// draws dots
    
    if( PT_ToolsMacCatalyst )
    {
        return;
    }
	
    const int padding = 14;
    const int vOffset = 14;
    const int hOffset = -6;
    
    if( selection.count == 0 )
        return;
    
    CGPoint dotPoint = [self GetFirstDotPoint:selection];
    
	if( self.leadingBar.superview )
		[self.leadingBar removeFromSuperview];
	
    self.leadingBar = [[PTSelectionBar alloc] initWithFrame:CGRectMake(dotPoint.x-padding+hOffset, dotPoint.y-padding-vOffset, 13+padding*2, 14+padding*2)];
    [self.leadingBar setIsLeft:YES];
    
    [self.pdfViewCtrl.toolOverlayView addSubview:self.leadingBar];
    
    dotPoint = [self GetSecondDotPoint:selection];
	
	if( self.trailingBar.superview )
		[self.trailingBar removeFromSuperview];
	
    self.trailingBar = [[PTSelectionBar alloc] initWithFrame:CGRectMake(dotPoint.x-padding+hOffset, dotPoint.y-padding, 13+padding*2, 14+padding*2)];
    [self.trailingBar setIsLeft:NO];
    [self.pdfViewCtrl.toolOverlayView addSubview:self.trailingBar];
    
}

-(void)selectTextAtDoubleTapPt
{
    if (self.selectionOnScreen) {
        [self ClearSelectionOnly];
        [self ClearSelectionBars];
    }
    double screenScale = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES )
        screenScale = [UIScreen mainScreen].scale ;

    [self.pdfViewCtrl SetTextSelectionMode:e_ptrectangular];
    [self.pdfViewCtrl SelectX1:doubleTapPoint.x Y1:doubleTapPoint.y X2:1/screenScale/2+doubleTapPoint.x Y2:1/screenScale/2+doubleTapPoint.y];
    [self.pdfViewCtrl SetTextSelectionMode:e_ptstructural];
    NSArray<NSValue*>* selections = [self GetQuadsFromPage:-1 ToPage:-1];
    if (selections == 0 || selections.count == 0)
    {
        [self ClearSelectionOnly];
        [self ClearSelectionBars];
        self.nextToolType = [PTPanTool class];
        return;
    }
    CGRect selection = [selections[0] CGRectValue];

    //in case two bounding boxes overlap.
    CGRect lastSelection = [selections[selections.count-1] CGRectValue];

    self.selectionEnd = CGPointMake(selection.origin.x + selection.size.width-1, selection.origin.y + selection.size.height-1);

    CGPoint selectionOrigin = selection.origin;

    //ensures it will be on the page
    selectionOrigin.x++;
    selectionOrigin.y++;

    self.selectionStart = selectionOrigin;

    self.selectionStartPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.selectionStart.x y:self.selectionStart.y];
    self.selectionEndPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.selectionEnd.x y:self.selectionEnd.y];
    initialSelectionStartScreenPt = self.selectionStart;
    initialSelectionEndScreenPt = self.selectionEnd;
    self.selectionStart = [self convertScreenPtToPagePt:self.selectionStart onPageNumber:self.selectionStartPageNumber];
    self.selectionEnd = [self convertScreenPtToPagePt:self.selectionEnd onPageNumber:self.selectionEndPageNumber];

    [self DrawSelectionQuads:selections WithLines:YES WithDropAnimation:NO];

    NSArray<NSValue *> *selectionArray = @[@(selection)];

    [self DrawSelectionBars:selectionArray];

    self.selectionStartCorner = CGPointMake(selection.origin.x + [self.pdfViewCtrl GetHScrollPos], selection.origin.y + [self.pdfViewCtrl GetVScrollPos]);

    self.selectionEndCorner = CGPointMake(lastSelection.origin.x+lastSelection.size.width + [self.pdfViewCtrl GetHScrollPos], lastSelection.origin.y+lastSelection.size.height/2+ [self.pdfViewCtrl GetVScrollPos]);
}

- (void) longPressTextSelectAt: (CGPoint) down WithRecognizer: (UILongPressGestureRecognizer *) gestureRecognizer
{
    CGPoint offsetSelectionStart, offsetSelectionEnd;
    CGFloat offsetFactor = 0.9; // iOS 13 text selection vertical offset

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self ClearSelectionBars];
    }

    double screenScale = 1;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES ) 
        screenScale = [UIScreen mainScreen].scale ;
    
    
    NSArray<NSValue*>* selections = [self GetQuadsFromPage:-1 ToPage:-1];
    CGRect currSelection = [selections[0] CGRectValue];
    CGRect lastSelection = [selections[selections.count-1] CGRectValue];

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.pdfViewCtrl SetTextSelectionMode:e_ptrectangular];
        [self.pdfViewCtrl SelectX1:down.x Y1:down.y X2:1/screenScale/2+down.x Y2:1/screenScale/2+down.y];
        selections = [self GetQuadsFromPage:-1 ToPage:-1];
        currSelection = [selections[0] CGRectValue];
        lastSelection = [selections[selections.count-1] CGRectValue];
        self.selectionStartPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:currSelection.origin.x y:currSelection.origin.y];
        self.selectionStart = [self convertScreenPtToPagePt:currSelection.origin onPageNumber:self.selectionStartPageNumber];
        self.selectionEndPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:lastSelection.origin.x+lastSelection.size.width y:lastSelection.origin.y+lastSelection.size.height];
        self.selectionEnd = [self convertScreenPtToPagePt:CGPointMake(lastSelection.origin.x+lastSelection.size.width,lastSelection.origin.y+lastSelection.size.height) onPageNumber:self.selectionEndPageNumber];
        initialSelectionStartScreenPt = currSelection.origin;
        initialSelectionEndScreenPt = CGPointMake(lastSelection.origin.x+lastSelection.size.width, lastSelection.origin.y+lastSelection.size.height);
    }else if (gestureRecognizer.state == UIGestureRecognizerStateChanged){
        if (selections.count > 0) {
            offsetSelectionStart = down;
            offsetSelectionEnd = down;
            BOOL touchOutsideInitialLine = down.y < initialSelectionStartScreenPt.y || down.y > initialSelectionEndScreenPt.y;
            BOOL selectionLinesChanged = currSelection.origin.y != initialSelectionStartScreenPt.y || lastSelection.origin.y+lastSelection.size.height != initialSelectionEndScreenPt.y;

            if (@available(iOS 13, *)) {
                if (touchOutsideInitialLine || selectionLinesChanged) {
                    offsetSelectionStart.y -= offsetFactor*currSelection.size.height;
                    offsetSelectionEnd.y -= offsetFactor*lastSelection.size.height;
                }
            }
            if ((offsetSelectionStart.x < initialSelectionStartScreenPt.x && offsetSelectionStart.y <= initialSelectionEndScreenPt.y) || offsetSelectionStart.y <= initialSelectionStartScreenPt.y) {
                offsetSelectionEnd = initialSelectionEndScreenPt;
            }else if ((offsetSelectionEnd.x > initialSelectionEndScreenPt.x && offsetSelectionEnd.y >= initialSelectionStartScreenPt.y) || offsetSelectionEnd.y >= initialSelectionEndScreenPt.y) {
                offsetSelectionStart = initialSelectionStartScreenPt;
            }else{
                offsetSelectionStart = initialSelectionStartScreenPt;
                offsetSelectionEnd = initialSelectionEndScreenPt;
            }
            offsetSelectionStart.y = MIN(offsetSelectionStart.y, initialSelectionStartScreenPt.y);

            offsetSelectionEnd.y = MAX(offsetSelectionEnd.y, initialSelectionEndScreenPt.y);
            if (fabs(offsetSelectionEnd.y-initialSelectionEndScreenPt.y) < fabs(offsetSelectionEnd.y-down.y)) {
                offsetSelectionEnd.y = initialSelectionEndScreenPt.y;
                offsetSelectionEnd.x = MAX(offsetSelectionEnd.x, initialSelectionEndScreenPt.x);
            }

            self.selectionStartPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:offsetSelectionStart.x y:offsetSelectionStart.y];
            self.selectionStart = [self convertScreenPtToPagePt:offsetSelectionStart onPageNumber:self.selectionStartPageNumber];
            self.selectionEndPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:offsetSelectionEnd.x y:offsetSelectionEnd.y];
            self.selectionEnd = [self convertScreenPtToPagePt:offsetSelectionEnd onPageNumber:self.selectionEndPageNumber];

            [self MakeSelection];
        }
    }
    selections = [self GetQuadsFromPage:-1 ToPage:-1];
    
    if (selections == 0 || selections.count == 0)
    {
        [self ClearSelectionOnly];
        [self ClearSelectionBars];
        
        // just show loupe
        if ( gestureRecognizer.state != UIGestureRecognizerStateEnded && gestureRecognizer.state != UIGestureRecognizerStateCancelled)
        {
            if( [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y] > 0 )
            {
                CGPoint magnifyPoint = [gestureRecognizer locationInView:self.pdfViewCtrl];
                down.y += self.pdfViewCtrl.frame.origin.y;
                down.x += self.pdfViewCtrl.frame.origin.x;
                [self addLoupeAtMagnifyPoint:magnifyPoint touchPoint:down];
            }
            else
            {
                [loupe removeFromSuperview];
            }
        }
        else
        {
            [loupe removeFromSuperview];
        }
        
        self.nextToolType = [PTPanTool class];
        
        return;
    }

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled)
    {
        // executed on touch up

		CGRect selection = [selections[0] CGRectValue];
		
		//in case two bounding boxes overlap.
		CGRect lastSelection = [selections[selections.count-1] CGRectValue];
		
        self.selectionEnd = CGPointMake(selection.origin.x + selection.size.width-1, selection.origin.y + selection.size.height-1);
        
        CGPoint selectionOrigin = selection.origin;
        
        //ensures it will be on the page
        selectionOrigin.x++;
        selectionOrigin.y++;
        
		self.selectionStart = selectionOrigin;

		self.selectionStartPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.selectionStart.x y:self.selectionStart.y];
		self.selectionEndPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.selectionEnd.x y:self.selectionEnd.y];
		
        self.selectionStart = [self convertScreenPtToPagePt:self.selectionStart onPageNumber:self.selectionStartPageNumber];
        self.selectionEnd = [self convertScreenPtToPagePt:self.selectionEnd onPageNumber:self.selectionEndPageNumber];
        
        [self DrawSelectionQuads:selections WithLines:YES WithDropAnimation:NO];
        
        [self DrawSelectionBars:selections];
        
        self.selectionStartCorner = CGPointMake(selection.origin.x + [self.pdfViewCtrl GetHScrollPos], selection.origin.y + [self.pdfViewCtrl GetVScrollPos]);
        
        self.selectionEndCorner = CGPointMake(lastSelection.origin.x+lastSelection.size.width + [self.pdfViewCtrl GetHScrollPos], lastSelection.origin.y+lastSelection.size.height/2+ [self.pdfViewCtrl GetVScrollPos]);
        
        [loupe removeFromSuperview];

        
        [self ShowMenuController];
    }
    else
    {
        BOOL animate = NO;

        if (loupe == nil) {
            loupe = [[PTMagnifierView alloc] initWithViewToMagnify:self.pdfViewCtrl];
            animate = YES;
        }
        [self DrawSelectionBars:selections];
        [self DrawSelectionQuads:selections WithLines:YES WithDropAnimation:animate];
        
        CGPoint magnifyPoint = [gestureRecognizer locationInView:self.pdfViewCtrl];
        down.y += self.pdfViewCtrl.frame.origin.y;
        down.x += self.pdfViewCtrl.frame.origin.x;
        [self addLoupeAtMagnifyPoint:magnifyPoint touchPoint:down];
    }
    
}

-(void)ClearSelectionBars
{
    
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
    
    [self.pdfViewCtrl ClearSelection];
}

-(void)ClearSelectionOnly
{
	assert(self.selectionLayers);
    [self.selectionLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    self.selectionLayers = [NSArray array];
}

-(void)DrawSelectionQuads:(NSArray<NSValue*>*)quads WithLines:(BOOL)lines WithDropAnimation:(BOOL)animated
{
    int drawnQuads = 0;
    
    [self ClearSelectionOnly];
	
	PTRotate currentRotation = [self.pdfViewCtrl GetRotation];
    
    // Create a temporary mutable array.
    NSMutableArray<__kindof CALayer*>* mutableSelectionLayers = [self.selectionLayers mutableCopy];
    
    for (NSValue* quad in quads) 
    {
        CALayer* selectionLayer = [[CALayer alloc] init];
        
        CGRect selectionRect = quad.CGRectValue;
        
        selectionLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos], selectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos], selectionRect.size.width, selectionRect.size.height);
		
        UIColor* tintish = self.tintColor;
        tintish = [tintish colorWithAlphaComponent:0.18];
        
        CGColorRef cgTintish = tintish.CGColor;
        
        selectionLayer.backgroundColor = cgTintish;
        
        [self.pdfViewCtrl.toolOverlayView.layer addSublayer:selectionLayer];
        
        if( animated )
        {
            CGRect inflatedRect = CGRectInset(selectionLayer.frame, -60, -60);
            CGRect startBounds = CGRectMake(0, 0, inflatedRect.size.width, inflatedRect.size.height);
            CGRect stopBounds = selectionLayer.bounds;

            CABasicAnimation * boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
//            boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            boundsAnimation.fromValue = [NSValue valueWithCGRect:startBounds];
            boundsAnimation.toValue = [NSValue valueWithCGRect:stopBounds];

            CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"alpha"];
            opacityAnimation.fromValue = [NSNumber numberWithFloat:0.01];
            opacityAnimation.toValue = [NSNumber numberWithFloat:0.18];
            
            CABasicAnimation *cornerAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
//            anim1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            cornerAnimation.fromValue = [NSNumber numberWithFloat:10.0f];
            cornerAnimation.toValue = [NSNumber numberWithFloat:0.0f];

            CAAnimationGroup * group = [CAAnimationGroup animation];
            group.removedOnCompletion = NO;
            group.fillMode = kCAFillModeForwards;
            group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            group.animations = [NSArray arrayWithObjects:boundsAnimation, opacityAnimation, cornerAnimation, nil];
            group.duration = 0.15;
            group.delegate = self;
            [selectionLayer addAnimation:group forKey:@"selection"];
            
            
            self.impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [self.impactFeedbackGenerator prepare];
            
        }

        
        [mutableSelectionLayers addObject:selectionLayer];
        
        
        // lines that form selection bars
        if( lines == YES && PT_ToolsMacCatalyst == NO)
        {
			int rtlOffset = 0;
			if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES )
				rtlOffset = selectionRect.size.width;
			
            self.selectionOnScreen = true;
            // start line
            if( drawnQuads == 0 )
            {
                CALayer* lineLayer = [[CALayer alloc] init];
				if( currentRotation == e_pt0 || currentRotation == e_pt180 )
					lineLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos]-2+rtlOffset, selectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]-5, 2, selectionRect.size.height+5);
                else
					lineLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos]-2+rtlOffset, selectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos], selectionRect.size.width+5, 2);
                
                lineLayer.backgroundColor = self.tintColor.CGColor;
                
                [self.pdfViewCtrl.toolOverlayView.layer addSublayer:lineLayer];
                if( animated )
                {
                    [self animateSelectionBar:self.leadingBar andLineLayer:lineLayer];
                }
                [mutableSelectionLayers addObject:lineLayer];
                
            }
            
            // end line
            if(drawnQuads == quads.count-1)
            {
                CALayer* lineLayer = [[CALayer alloc] init];
				

				if( currentRotation == e_pt0 || currentRotation == e_pt180 )
					lineLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos]+selectionRect.size.width-rtlOffset, selectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos], 2, selectionRect.size.height+5);
                else
					lineLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos]-2-rtlOffset, selectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos]+selectionRect.size.height, selectionRect.size.width+5, 2);
                
  
                lineLayer.backgroundColor = self.tintColor.CGColor;
                
                [self.pdfViewCtrl.toolOverlayView.layer addSublayer:lineLayer];
                if( animated )
                {
                    [self animateSelectionBar:self.trailingBar andLineLayer:lineLayer];
                }
                [mutableSelectionLayers addObject:lineLayer];
                
            }
        }
        else
        {
            self.selectionOnScreen = YES;
        }
        drawnQuads++;
    }
    
    // Convert back to an immutable array.
    self.selectionLayers = [mutableSelectionLayers copy];
}

-(void)animateSelectionBar:(PTSelectionBar*)bar andLineLayer:(CALayer*)lineLayer
{
    CGFloat delay = 0.075;
    CFTimeInterval duration = 0.1;

    CGRect inflatedRect = CGRectInset(lineLayer.frame, 0, 0.2*lineLayer.frame.size.height);
    CGRect startBounds = CGRectMake(0, 0, inflatedRect.size.width, inflatedRect.size.height);
    CGRect stopBounds = lineLayer.bounds;

    CABasicAnimation * boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    boundsAnimation.fromValue = [NSValue valueWithCGRect:startBounds];
    boundsAnimation.toValue = [NSValue valueWithCGRect:stopBounds];

    lineLayer.opacity = 0.0;
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    opacityAnimation.toValue = [NSNumber numberWithFloat:1.0];
    opacityAnimation.fillMode = kCAFillModeForwards;

    CAAnimationGroup * group = [CAAnimationGroup animation];
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    group.animations = [NSArray arrayWithObjects:boundsAnimation, opacityAnimation, nil];
    group.duration = duration;
    group.beginTime = CACurrentMediaTime() + delay;

    CGPoint dotStartPoint = bar.layer.position;
    CGPoint dotStopPoint = dotStartPoint;
    CGFloat direction = (bar == self.leadingBar) ? 1.0 : -1.0;
    dotStartPoint.y += direction*0.2*lineLayer.frame.size.height;

    CABasicAnimation * dotPositionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    dotPositionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    dotPositionAnimation.fromValue = [NSValue valueWithCGPoint:dotStartPoint];
    dotPositionAnimation.toValue = [NSValue valueWithCGPoint:dotStopPoint];

    bar.layer.opacity = 0.0;
    CABasicAnimation *dotOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    dotOpacityAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    dotOpacityAnimation.toValue = [NSNumber numberWithFloat:1.0];
    dotOpacityAnimation.fillMode = kCAFillModeForwards;

    CAAnimationGroup * dotGroup = [CAAnimationGroup animation];
    dotGroup.removedOnCompletion = NO;
    dotGroup.fillMode = kCAFillModeForwards;
    dotGroup.animations = [NSArray arrayWithObjects:dotPositionAnimation, dotOpacityAnimation, nil];
    dotGroup.duration = duration;
    dotGroup.beginTime = CACurrentMediaTime() + delay;
    [lineLayer addAnimation:group forKey:@"line"];
    [bar.layer addAnimation:dotGroup forKey:@"bar"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self.impactFeedbackGenerator impactOccurred];
}



- (NSArray<NSValue *> *)MakeSelection
{
    NSArray<NSValue *> *selection;
    if( self.selectionStartPageNumber <= self.selectionEndPageNumber )
    {
        [self.pdfViewCtrl SelectX1:self.selectionStart.x Y1:self.selectionStart.y PageNumber1:self.selectionStartPageNumber X2:self.selectionEnd.x Y2:self.selectionEnd.y PageNumber2:self.selectionEndPageNumber];
        
        selection = [self GetQuadsFromPage:self.selectionStartPageNumber ToPage:self.selectionEndPageNumber];
    }
    else
    {
        [self.pdfViewCtrl SelectX1:self.selectionEnd.x Y1:self.selectionEnd.y PageNumber1:self.selectionEndPageNumber X2:self.selectionStart.x Y2:self.selectionStart.y PageNumber2:self.selectionStartPageNumber];
        
        selection = [self GetQuadsFromPage:self.selectionEndPageNumber ToPage:self.selectionStartPageNumber];
    }
    
    return selection;
}

-(void) selectionBarMoved:(PTSelectionBar*) bar withTouches:(NSSet *) touches withEvent: (UIEvent *) event
{
    
    UITouch *touch = touches.allObjects[0];
    
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
    
    CGPoint offsetSelectionStart, offsetSelectionEnd;

    NSArray<NSValue*>* selections = [self GetQuadsFromPage:-1 ToPage:-1];
    CGRect currSelection = [selections[0] CGRectValue];
    CGRect lastSelection = [selections[selections.count-1] CGRectValue];
    CGFloat offsetFactor = 1.0; // iOS 13 text selection vertical offset

    if( bar.isLeft == true)
    {
        offsetSelectionStart = down;

        if (@available(iOS 13, *)) {
            // Offset the selection point to be above the touch point
            offsetSelectionStart.y -= offsetFactor*currSelection.size.height;
            // Only apply the offset after the user has already moved the selection up, otherwise the selection point's `y` value shouldn't change
            // Needs some refinement as this will also be the case after the user has subsequently moved the selection back down to the starting point
            if (down.y >= currSelection.origin.y - 0.5*currSelection.size.height){
                offsetSelectionStart.y = currSelection.origin.y;
            }
            /**
             * After the offset has been applied (i.e. the current touch point is now below the current selection rect)
             * move the offset with the touch to the point where the current selection begins
             **/
            if (down.y > currSelection.origin.y + currSelection.size.height) {
                offsetSelectionStart.y = MAX(down.y-offsetFactor*currSelection.size.height, currSelection.origin.y);
            }
        }

        self.selectionStartPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:offsetSelectionStart.x y:offsetSelectionStart.y];
        self.selectionStart = [self convertScreenPtToPagePt:offsetSelectionStart onPageNumber:self.selectionStartPageNumber];
    }
    else
    {
        offsetSelectionEnd = down;

        if (@available(iOS 13, *)) {
            if( PT_ToolsMacCatalyst == NO )
            {
                // Offset the selection point to be above the touch point
                offsetSelectionEnd.y -= offsetFactor*lastSelection.size.height;
                // Make sure that the offset doesn't go above the current selection's origin
                offsetSelectionEnd.y = MAX(offsetSelectionEnd.y, currSelection.origin.y);
                // Move the offset with the touch when the user moves their finger back up
                if (offsetSelectionEnd.y <= lastSelection.origin.y+lastSelection.size.height &&
                    offsetSelectionEnd.y >= lastSelection.origin.y) {
                    offsetSelectionEnd.y = lastSelection.origin.y+lastSelection.size.height;
                }
            }
        }
        self.selectionEndPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:offsetSelectionEnd.x y:offsetSelectionEnd.y];
        self.selectionEnd = [self convertScreenPtToPagePt:offsetSelectionEnd onPageNumber:self.selectionEndPageNumber];
    }

    const int padding = 14;
    const int vOffset = 14;
    const int hOffset = -6;
    
    NSArray<NSValue *> *selection = [self MakeSelection];
    
    if( selection.count == 0 )
    {
        return;
    }


    CGRect lastQuad = [selection[selection.count-1] CGRectValue];
    CGRect firstQuad = [selection[0] CGRectValue];
	
	if( [self.pdfViewCtrl GetRightToLeftLanguage] ==  NO )
	{
		self.selectionStartCorner = CGPointMake(firstQuad.origin.x + [self.pdfViewCtrl GetHScrollPos], firstQuad.origin.y + [self.pdfViewCtrl GetVScrollPos]);
		self.selectionEndCorner = CGPointMake(lastQuad.origin.x + lastQuad.size.width + [self.pdfViewCtrl GetHScrollPos], lastQuad.origin.y + lastQuad.size.height/2 + [self.pdfViewCtrl GetVScrollPos]);
	}
	else
	{
		self.selectionStartCorner = CGPointMake(firstQuad.origin.x + [self.pdfViewCtrl GetHScrollPos] + firstQuad.size.width, firstQuad.origin.y-firstQuad.size.height/2 + [self.pdfViewCtrl GetVScrollPos]);
		self.selectionEndCorner = CGPointMake(lastQuad.origin.x + [self.pdfViewCtrl GetHScrollPos], lastQuad.origin.y + lastQuad.size.height/2 + [self.pdfViewCtrl GetVScrollPos]);
	}
	
    [self DrawSelectionQuads:selection WithLines:YES WithDropAnimation:NO];
    
    CGRect oldLeft = self.leadingBar.frame;
    CGRect oldRight = self.trailingBar.frame;


    CGPoint dotPoint = [self GetFirstDotPoint:selection];
    self.leadingBar.frame = CGRectMake(dotPoint.x-padding+hOffset, dotPoint.y-padding-vOffset, bar.frame.size.width, bar.frame.size.height);

    dotPoint = [self GetSecondDotPoint:selection];
    self.trailingBar.frame = CGRectMake(dotPoint.x-padding+hOffset, dotPoint.y-padding, bar.frame.size.width, bar.frame.size.height);


    if( !(CGRectEqualToRect(oldLeft, self.leadingBar.frame) && CGRectEqualToRect(oldRight, self.trailingBar.frame)))
    {
       if(CGRectEqualToRect(oldLeft, self.leadingBar.frame))
       {
           if( bar.isLeft )
           {
               swapBars = YES;
               
           }
           else
               swapBars = NO;
       }
        else
        {
            if( bar.isLeft )
            {
                swapBars = NO;
            }
            else
                swapBars = YES;
        }
    }
    
    CGPoint magnifyPoint = [touch locationInView:self.pdfViewCtrl];
    down.y += self.pdfViewCtrl.frame.origin.y;
    down.x += self.pdfViewCtrl.frame.origin.x;
    [self addLoupeAtMagnifyPoint:magnifyPoint touchPoint:down];
    
    // keep dot on top
    [self.leadingBar.superview bringSubviewToFront:self.leadingBar];
    [self.trailingBar.superview bringSubviewToFront:self.trailingBar];
    
}

-(void)selectionBarUp:(PTSelectionBar *)bar withTouches:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    // keep dot on top
    [self.leadingBar.superview bringSubviewToFront:self.leadingBar];
    [self.trailingBar.superview bringSubviewToFront:self.trailingBar];
    
    UITouch *touch = touches.allObjects[0];
    
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
    
    down.x += [self.pdfViewCtrl GetHScrollPos];
    down.y += [self.pdfViewCtrl GetVScrollPos];
    
    NSArray<NSValue *> *selection = [self MakeSelection];
    
    CGRect firstQuad = [selection[0] CGRectValue];
    CGRect lastQuad = [selection[selection.count-1] CGRectValue];
	
	int rtlOffsetFirst = 0;
	int rtlOffsetLast = 0;
	if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES )
	{
		rtlOffsetFirst = firstQuad.size.width;
		rtlOffsetLast = lastQuad.size.width;
	}
	
    if( swapBars )
    {
        self.leadingBar.isLeft = NO;
        self.trailingBar.isLeft = YES;
        
        CGPoint selectionStartOnScreen = CGPointMake(lastQuad.origin.x + lastQuad.size.width - rtlOffsetLast, lastQuad.origin.y + lastQuad.size.height/2);
        self.selectionStart = [self convertScreenPtToPagePt:selectionStartOnScreen onPageNumber:self.selectionStartPageNumber];
        CGPoint selectionEndOnScreen = CGPointMake(firstQuad.origin.x + rtlOffsetFirst, firstQuad.origin.y+firstQuad.size.height/2);
        self.selectionEnd = [self convertScreenPtToPagePt:selectionEndOnScreen onPageNumber:self.selectionEndPageNumber];
    }
    else
    {
        self.leadingBar.isLeft = YES;
        self.trailingBar.isLeft = NO;
        
        CGPoint selectionStartOnScreen = CGPointMake(firstQuad.origin.x+rtlOffsetFirst, firstQuad.origin.y+firstQuad.size.height/2);
        self.selectionStart = [self convertScreenPtToPagePt:selectionStartOnScreen onPageNumber:self.selectionStartPageNumber];
        CGPoint selectionEndOnScreen = CGPointMake(lastQuad.origin.x + lastQuad.size.width - rtlOffsetLast, lastQuad.origin.y + lastQuad.size.height/2);
        self.selectionEnd = [self convertScreenPtToPagePt:selectionEndOnScreen onPageNumber:self.selectionEndPageNumber];
    }
    
    if( PT_ToolsMacCatalyst == NO )
    {
        [self ShowMenuController];
    }
    
    [loupe removeFromSuperview];
}

-(void)createTextMarkupAnnot:(PTExtendedAnnotType)annotType
{
	PTColorPostProcessMode mode = [self.pdfViewCtrl GetColorPostProcessMode];
	
	[self createTextMarkupAnnot:annotType
					  withColor:[PTColorDefaults defaultColorPtForAnnotType:annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:mode]
				 withComponents:[PTColorDefaults numCompsInColorPtForAnnotType:annotType attribute:ATTRIBUTE_STROKE_COLOR]
					withOpacity:[PTColorDefaults defaultOpacityForAnnotType:annotType]];
}


-(void)createTextMarkupAnnot:(PTExtendedAnnotType)annotType withColor:(PTColorPt*)color withComponents:(int)components withOpacity:(double)opacity
{
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
    
        for ( int ipage = self.selectionStartPageNumber; ipage <= self.selectionEndPageNumber; ++ipage )
        {
            PTPage* p = [doc GetPage:ipage];
            
            
            if( ![p IsValid] )
            {
                return;
            }
			
			assert([p IsValid]);

            PTSelection* sel = [self.pdfViewCtrl GetSelection:ipage];
            PTVectorQuadPoint* quads = [sel GetQuads];
            NSUInteger num_quads = [quads size];
            
            if( num_quads > 0 )
            {
                PTQuadPoint* qp = [quads get:0];
                
                TRN_point* point = [qp getP1];
                
                double x1 = [point getX];
                double y1 = [point getY];
                
                point = [qp getP3];
                
                double x2 = [point getX];
                double y2 = [point getY];
                
                PTPDFRect* r = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
                
                
                PTTextMarkup* mktp;
                
                switch (annotType) {
                    case PTExtendedAnnotTypeHighlight:
                        mktp = [PTHighlightAnnot Create:(PTSDFDoc*)doc pos:r];
                        break;
                    case PTExtendedAnnotTypeUnderline:
                        mktp = [PTUnderline Create:(PTSDFDoc*)doc pos:r];
                        break;
                    case PTExtendedAnnotTypeStrikeOut:
                        mktp = [PTStrikeOut Create:(PTSDFDoc*)doc pos:r];
                        break;
                    case PTExtendedAnnotTypeSquiggly:
                        mktp = [PTSquiggly Create:(PTSDFDoc*)doc pos:r];
                        break;
                    default:
                        // not a supported text annotation type?
                        assert(false);
                        break;
                }
                
                for( int i=0; i < num_quads; ++i )
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
				
				if( self.annotationAuthor && self.annotationAuthor.length > 0 && [mktp isKindOfClass:[PTMarkup class]]	)
				{
					[(PTMarkup*)mktp SetTitle:self.annotationAuthor];
				}
                
                // Check if the annotated text should be copied to the annotation's contents.
                BOOL shouldCopyAnnotatedTextToContents = NO;
                PTAnnotationOptions *options = [self.toolManager annotationOptionsForAnnotType:annotType];
                if ([options isKindOfClass:[PTTextMarkupAnnotationOptions class]]) {
                    shouldCopyAnnotatedTextToContents = ((PTTextMarkupAnnotationOptions *)options).copiesAnnotatedTextToContents;
                }
                if (shouldCopyAnnotatedTextToContents) {
                    PTPopup *popup = [PTPopup Create:[doc GetSDFDoc] pos:[mktp GetRect]];
                    [popup SetParent:mktp];
                    [mktp SetPopup:popup];
                    [popup SetContents:[sel GetAsUnicode]];
                }

                [p AnnotPushBack:mktp];

                [mktp SetColor:color numcomp:components];

                [mktp SetOpacity:opacity];
				
				double width = [PTColorDefaults defaultBorderThicknessForAnnotType:annotType];
                
				PTBorderStyle* bs = [[PTBorderStyle alloc] initWithS:e_ptsolid b_width:width b_hr:0 b_vr:0];
				
				//[m_default_text_annotation GetBorderStyle];
                
                [mktp SetBorderStyle:bs oldStyleOnly:NO];
                
                [mktp RefreshAppearance];
                                
                [self.pdfViewCtrl UpdateWithAnnot:mktp page_num:ipage];
				
				self.currentAnnotation = mktp;
				self.annotationPageNumber = ipage;
				
            }
        }
    
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
	
	[self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    
    [self ClearSelectionBars];
    
    [self ClearSelectionOnly];
}

-(void)createRedactionAnnot
{
    PTColorPostProcessMode mode = [self.pdfViewCtrl GetColorPostProcessMode];
    
    [self createRedactionWithColor:[PTColorDefaults defaultColorPtForAnnotType:PTExtendedAnnotTypeRedact attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:mode]
                    components:[PTColorDefaults numCompsInColorPtForAnnotType:PTExtendedAnnotTypeRedact attribute:ATTRIBUTE_STROKE_COLOR]
                       opacity:[PTColorDefaults defaultOpacityForAnnotType:PTExtendedAnnotTypeRedact]];
}

-(void)createRedactionWithColor:(PTColorPt*)color components:(int)components opacity:(double)opacity
{
    @try {
        [self.pdfViewCtrl DocLock:YES];
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        for (int ipage = self.selectionStartPageNumber; ipage <= self.selectionEndPageNumber; ++ipage) {
            PTPage* p = [doc GetPage:ipage];
            
            if (![p IsValid]) {
                return;
            }
            
            PTSelection* sel = [self.pdfViewCtrl GetSelection:ipage];
            PTVectorQuadPoint* quads = [sel GetQuads];
            NSUInteger num_quads = [quads size];
            
            if (num_quads == 0) {
                return;
            }
            
            PTQuadPoint* qp = [quads get:0];
            
            TRN_point* point = [qp getP1];
            
            double x1 = [point getX];
            double y1 = [point getY];
            
            point = [qp getP3];
            
            double x2 = [point getX];
            double y2 = [point getY];
            
            PTPDFRect* r = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
            
            PTRedactionAnnot *redactAnnot = [PTRedactionAnnot Create:(PTSDFDoc*)doc pos:r];
            
            for (int i = 0; i < num_quads; ++i) {
                PTQuadPoint* quad = [quads get:i];
                
                [redactAnnot SetQuadPoint:i qp:quad];
            }
            
            // Set annotation author.
            if (self.annotationAuthor.length > 0 && [redactAnnot isKindOfClass:[PTMarkup class]]) {
                [(PTMarkup*)redactAnnot SetTitle:self.annotationAuthor];
            }
            
            [p AnnotPushBack:redactAnnot];
            
            [redactAnnot SetColor:color numcomp:components];
            
            [redactAnnot SetOpacity:opacity];
            
            double width = [PTColorDefaults defaultBorderThicknessForAnnotType:PTExtendedAnnotTypeRedact];
            
            PTBorderStyle *bs = [[PTBorderStyle alloc] initWithS:e_ptsolid b_width:width b_hr:0 b_vr:0];
            
            [redactAnnot SetBorderStyle:bs oldStyleOnly:NO];
            
            [redactAnnot RefreshAppearance];
            
            [self.pdfViewCtrl UpdateWithAnnot:redactAnnot page_num:ipage];
            
            self.currentAnnotation = redactAnnot;
            self.annotationPageNumber = ipage;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    [self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    
    [self ClearSelectionBars];
    
    [self ClearSelectionOnly];
}

-(void)CopySelectedTextToPasteboard
{
    [UIPasteboard generalPasteboard].string = [self GetSelectedTextFromPage:self.selectionStartPageNumber ToPage:self.selectionEndPageNumber];
}

-(void)addLoupeAtMagnifyPoint:(CGPoint)magnifyPoint touchPoint:(CGPoint)touchPoint
{
    if (@available(iOS 13, *)) {
        return;
    }
    if(loupe == nil){
        loupe = [[PTMagnifierView alloc] initWithViewToMagnify:self.pdfViewCtrl];
    }

    [self.pdfViewCtrl.superview addSubview:loupe];

    [loupe setMagnifyPoint:magnifyPoint TouchPoint:touchPoint];
    [loupe setNeedsDisplay];
}

#pragma mark - Scroll View Responses
- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if( PT_ToolsMacCatalyst == NO )
    {
        [self showSelectionMenu];
    }
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if( decelerate == false && PT_ToolsMacCatalyst == NO)
    {
        [self showSelectionMenu];
    }
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if( PT_ToolsMacCatalyst == NO )
    {
        [self showSelectionMenu];
    }
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [loupe removeFromSuperview];
    
    if (self.leadingBar)
        self.selectionOnScreen = true;
    else
        self.selectionOnScreen = false;
    
    [super pdfViewCtrl:pdfViewCtrl pdfScrollViewWillBeginZooming:scrollView withView:view];
}

-(void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl*)pdfViewCtrl
{
    [self ClearSelectionBars];
    
    [self ClearSelectionOnly];
    
    TrnPagePresentationMode mode = [self.pdfViewCtrl GetPagePresentationMode];
    
    int page = [self.pdfViewCtrl GetCurrentPage];
    
    if( mode == e_ptsingle_page || mode == e_ptfacing || mode == e_ptfacing_cover )
    {
        if( self.selectionStartPageNumber != page || self.selectionEndPageNumber != page )
            return;
    }
    
    if( self.selectionOnScreen ) // there is currently selected text
    {
		// required to prevent possible deadlock
		dispatch_async( dispatch_get_main_queue(), ^{
			@try {
				[self.pdfViewCtrl DocLockRead];
				NSArray<NSValue*>* selection = [self MakeSelection];
				
				CGRect firstQuad = [selection[0] CGRectValue];
				
				int ltrOffsetFirst = 0;
				if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES)
				{
					ltrOffsetFirst = firstQuad.size.width;
				}
				
				self.selectionStartCorner = CGPointMake(firstQuad.origin.x + ltrOffsetFirst + [self.pdfViewCtrl GetHScrollPos], firstQuad.origin.y + [self.pdfViewCtrl GetVScrollPos]);
				
				CGRect lastQuad = [selection[selection.count-1] CGRectValue];
				
				int ltrOffsetLast = 0;
				if( [self.pdfViewCtrl GetRightToLeftLanguage] == YES)
				{
					ltrOffsetLast = lastQuad.size.width;
				}
				
				self.selectionEndCorner = CGPointMake(lastQuad.origin.x + lastQuad.size.width - ltrOffsetLast + [self.pdfViewCtrl GetHScrollPos], lastQuad.origin.y + lastQuad.size.height/2 + [self.pdfViewCtrl GetVScrollPos]);
				
				[self DrawSelectionQuads:selection WithLines:NO WithDropAnimation:NO];
				[self DrawSelectionBars:selection];
				
                if( PT_ToolsMacCatalyst == NO )
                {
                    [self showSelectionMenu];
                }
			}
			@catch (NSException *exception) {
				NSLog(@"Exception: %@: %@",exception.name, exception.reason);
			}
			@finally {
				[self.pdfViewCtrl DocUnlockRead];
			}

		});
    }
    else if (PT_ToolsMacCatalyst == NO )
    {
		[self showSelectionMenu];
    }
    
    [super pdfViewCtrlOnLayoutChanged:pdfViewCtrl];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidScroll:(UIScrollView *)scrollView
{
    
    [loupe removeFromSuperview];
    
    [super pdfViewCtrl:pdfViewCtrl pdfScrollViewDidScroll:scrollView];
}

- (void)ShowMenuController
{
    if (PT_ToolsMacCatalyst) {
        return;
    }
    if( self.selectionLayers.count != 0 && self.selectionOnScreen == true )
    {   
        [self becomeFirstResponder];
        [self attachInitialMenuItems];
			
        UIMenuController *theMenu = [UIMenuController sharedMenuController];
        [theMenu setTargetRect:CGRectMake(self.selectionStartCorner.x, self.selectionStartCorner.y-15, self.selectionEndCorner.x-self.selectionStartCorner.x, self.selectionEndCorner.y-self.selectionStartCorner.y+30) inView:self];
        
        int activePageNumber = 0;
        if( self.selectionEndPageNumber == self.selectionEndPageNumber)
            activePageNumber = self.selectionEndPageNumber;
        else
            activePageNumber = [self.pdfViewCtrl GetCurrentPage];
        
        if( ![self shouldShowMenu:theMenu forAnnotation:self.currentAnnotation onPageNumber:activePageNumber])
        {
            // don't show menu if delegate says not to.
            return;
        }
        
        [theMenu setMenuVisible:YES animated:YES];
    }
    
}

#pragma mark - helper

-(NSArray<NSValue*>*)GetQuadsFromPage:(int)page1 ToPage:(int)page2
{
    NSMutableArray<NSValue*>* quadsToReturn = [[NSMutableArray alloc] init];
    
    for(int page = page1; page <= page2; page++)
    {
        PTSelection* selection = [self.pdfViewCtrl GetSelection:page];
        
        PTVectorQuadPoint* quads = [selection GetQuads];
        
        NSUInteger numberOfQuads = [quads size];
      
        if( numberOfQuads == 0 )
            return nil;
        
        int pageNumber = [selection GetPageNum];


        for(int ii = 0; ii < numberOfQuads; ii++)
        {
            PTQuadPoint* aQuad = [quads get:ii];
            
            PTPDFPoint* t_point1 = [aQuad getP1];
            PTPDFPoint* t_point2 = [aQuad getP2];
            PTPDFPoint* t_point3 = [aQuad getP3];
            PTPDFPoint* t_point4 = [aQuad getP4];
            
            CGPoint point1 = CGPointMake([t_point1 getX], [t_point1 getY]);
            CGPoint point2 = CGPointMake([t_point2 getX], [t_point2 getY]);
            CGPoint point3 = CGPointMake([t_point3 getX], [t_point3 getY]);
            CGPoint point4 = CGPointMake([t_point4 getX], [t_point4 getY]);
            
            @try
            { 
                [self ConvertPagePtToScreenPtX:&point1.x Y:&point1.y PageNumber:pageNumber];
                [self ConvertPagePtToScreenPtX:&point2.x Y:&point2.y PageNumber:pageNumber];
                [self ConvertPagePtToScreenPtX:&point3.x Y:&point3.y PageNumber:pageNumber];
                [self ConvertPagePtToScreenPtX:&point4.x Y:&point4.y PageNumber:pageNumber];
                
            }
            @catch(NSException *exception)
            {
                continue;
            }
            
            float left = MIN(point1.x, MIN(point2.x, MIN(point3.x, point4.x)));
            float right = MAX(point1.x, MAX(point2.x, MAX(point3.x, point4.x)));
            
            float top = MIN(point1.y, MIN(point2.y, MIN(point3.y, point4.y)));
            float bottom = MAX(point1.y, MAX(point2.y, MAX(point3.y, point4.y)));
            
            
            
            [quadsToReturn addObject:[NSValue valueWithCGRect:CGRectMake(left, top, (right-left), (bottom-top))]];
        }
        
    }

    return [quadsToReturn copy];
}

- (NSString *)GetSelectedTextFromPage:(int)startPageNumber ToPage:(int)endPageNumber
{
    NSParameterAssert(startPageNumber <= endPageNumber);
    
    NSMutableString *totalSelection = [[NSMutableString alloc] init];
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        for (int pageNumber = startPageNumber; pageNumber <= endPageNumber; pageNumber++) {
            // Skip pages without selection(s).
            if (![self.pdfViewCtrl HasSelectionOnPage:pageNumber]) {
                continue;
            }
            
            PTSelection *selection = [self.pdfViewCtrl GetSelection:pageNumber];
            NSString *pageString = [selection GetAsUnicode];
            if (pageString.length > 0) {
                [totalSelection appendString:pageString];
            }
        }
    } error:&error];
    if (error) {
        NSLog(@"Error getting selection from page %d to %d: %@",
              startPageNumber, endPageNumber, error);
        return nil;
    }
    
    return [totalSelection copy];
}

-(void)pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
	TrnPagePresentationMode mode = [self.pdfViewCtrl GetPagePresentationMode];
	
	if( mode == e_ptsingle_page || mode == e_ptfacing || mode == e_ptfacing_cover )
    {		
		[self ClearSelectionBars];
		
		[self ClearSelectionOnly];
		
		self.selectionOnScreen = NO;
		
		self.currentAnnotation = nil;
		
		[self hideMenu];
	}
	[super pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:oldPageNumber To:newPageNumber];
}

#if TARGET_OS_MACCATALYST
- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location configuration:(UIContextMenuConfiguration * _Nullable __autoreleasing *)configuration
{
    if( !self.selectionOnScreen ){
        // Select text under right-click point
        doubleTapPoint = location;
        [self selectTextAtDoubleTapPt];
    }

    CGRect selectionRect = CGRectMake(self.selectionStartCorner.x, self.selectionStartCorner.y-15, self.selectionEndCorner.x-self.selectionStartCorner.x, self.selectionEndCorner.y-self.selectionStartCorner.y+30);
    // Convert to pdfViewCtrl coordinates as that's where the location is
    selectionRect = [self convertRect:selectionRect toView:self.pdfViewCtrl];
    if (CGRectContainsPoint(selectionRect, location)) {
        *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"textSelectContextMenuConfiguration" previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            return self.contextMenu;
        }];
        return YES;
    }
    return NO;
}
#endif

@end
