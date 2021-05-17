//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationViewController.h"

#import "PTAnalyticsManager.h"
#import "PTToolsUtil.h"
#import "PTAnnot+PTAdditions.h"

static UIImage *AnnotationImage(int type) {
    switch (type) {
        case PTExtendedAnnotTypeText:
            return [PTToolsUtil toolImageNamed:@"Annotation/Comment/Icon"];
        case PTExtendedAnnotTypeLine:
            return [PTToolsUtil toolImageNamed:@"Annotation/Line/Icon"];
        case PTExtendedAnnotTypeSquare:
            return [PTToolsUtil toolImageNamed:@"Annotation/Square/Icon"];
        case PTExtendedAnnotTypeCircle:
            return [PTToolsUtil toolImageNamed:@"Annotation/Circle/Icon"];
        case PTExtendedAnnotTypeUnderline:
            return [PTToolsUtil toolImageNamed:@"Annotation/Underline/Icon"];
        case PTExtendedAnnotTypeStrikeOut:
            return [PTToolsUtil toolImageNamed:@"Annotation/StrikeOut/Icon"];
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypePencilDrawing:
            return [PTToolsUtil toolImageNamed:@"Annotation/Ink/Icon"];
        case PTExtendedAnnotTypeFreehandHighlight:
            return [PTToolsUtil toolImageNamed:@"Annotation/FreeHighlight/Icon"];
        case PTExtendedAnnotTypeHighlight:
            return [PTToolsUtil toolImageNamed:@"Annotation/Highlight/Icon"];
        case PTExtendedAnnotTypeFreeText:
            return [PTToolsUtil toolImageNamed:@"Annotation/FreeText/Icon"];
        case PTExtendedAnnotTypeImageStamp:
            return [PTToolsUtil toolImageNamed:@"Annotation/Image/Icon"];
        case PTExtendedAnnotTypeArrow:
            return [PTToolsUtil toolImageNamed:@"Annotation/Arrow/Icon"];
        case PTExtendedAnnotTypeSquiggly:
            return [PTToolsUtil toolImageNamed:@"Annotation/Squiggly/Icon"];
        case PTExtendedAnnotTypePolyline:
            return [PTToolsUtil toolImageNamed:@"Annotation/Polyline/Icon"];
        case PTExtendedAnnotTypePolygon:
            return [PTToolsUtil toolImageNamed:@"Annotation/Polygon/Icon"];
        case PTExtendedAnnotTypeCloudy:
            return [PTToolsUtil toolImageNamed:@"Annotation/Cloud/Icon"];
        case PTExtendedAnnotTypeSignature:
            return [PTToolsUtil toolImageNamed:@"Annotation/Signature/Icon"];
        case PTExtendedAnnotTypeStamp:
            return [PTToolsUtil toolImageNamed:@"Annotation/Stamp/Icon"];
        case PTExtendedAnnotTypeCaret:
            return [PTToolsUtil toolImageNamed:@"Annotation/Caret/Icon"];
        case PTExtendedAnnotTypeRedact:
            return [PTToolsUtil toolImageNamed:@"Annotation/RedactionRectangle/Icon"];
        case PTExtendedAnnotTypeRuler:
            return [PTToolsUtil toolImageNamed:@"Annotation/Distance/Icon"];
        case PTExtendedAnnotTypePerimeter:
            return [PTToolsUtil toolImageNamed:@"Annotation/Perimeter/Icon"];
        case PTExtendedAnnotTypeArea:
            return [PTToolsUtil toolImageNamed:@"Annotation/Area/Icon"];

    }
    
    return nil;
}

@interface PTAnnotationViewController ()

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@property (nonatomic, strong, nullable) PTToolManager *toolManager;

@property (nonatomic, strong) UILabel *noAnnotsLabel;

@property (nonatomic, strong) NSThread *runner;

// We use this only internally. When we first create a root bookmark view, we asynchronously
// begin fetching a list of all annotations. We then pass this along to each child bookmark
// view so it doesn't have to generate it itself.
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSDictionary<NSString *, id> *> *> *annotations;

@property (nonatomic, assign, getter=isRemovingAnnotation) BOOL removingAnnotation;

@property (nonatomic, strong) UIBarButtonItem *doneButton;

@property (nonatomic, assign) BOOL showsDoneButton;

@property (nonatomic, assign, getter=isTabBarItemSetup) BOOL tabBarItemSetup;

@end

@implementation PTAnnotationViewController

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self initWithPDFViewCtrl:toolManager.pdfViewCtrl];
    if (self) {
        _toolManager = toolManager;
        
        // Observe PTToolManager annotation notifications.
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(toolManagerAnnotationAddedNotification:)
                                                   name:PTToolManagerAnnotationAddedNotification
                                                 object:toolManager];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(toolManagerAnnotationModifiedNotification:)
                                                   name:PTToolManagerAnnotationModifiedNotification
                                                 object:toolManager];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(toolManagerAnnotationRemovedNotification:)
                                                   name:PTToolManagerAnnotationRemovedNotification
                                                 object:toolManager];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(toolManagerAnnotationModifiedNotification:)
                                                   name:PTToolManagerFormFieldDataModifiedNotification
                                                 object:toolManager];
        
    }
    return self;
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		_pdfViewCtrl = pdfViewCtrl;
        
        _annotations = [NSMutableArray array];
        
        self.title = PTLocalizedString(@"Annotations", @"Annotations controller title");
    }
    return self;
}

- (void)refresh
{
    // Cancel existing task.
    [self.runner cancel];
    
    [self.annotations removeAllObjects];
    [self.tableView reloadData];
    
    PTPDFDoc *document = nil;
    @try {
        document = [self.pdfViewCtrl GetDoc];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        document = nil;
    }
    if (!document) {
        return;
    }
    
    self.runner = [[NSThread alloc] initWithTarget:self selector:@selector(beginAddingAnnotationResultsForDocument:) object:document];
    [self.runner start];
}

- (void)refreshIfVisible
{
    if (self.viewIfLoaded.window) {
        [self refresh];
    }
}

- (void)addAnnotations:(NSMutableArray *)annotationsForPage
{
    [self.annotations addObject:annotationsForPage];
  
	[self.tableView reloadData];
}

- (void)dismiss
{
    if ([self.delegate respondsToSelector:@selector(annotationViewControllerDidCancel:)]) {
        [self.delegate annotationViewControllerDidCancel:self];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    // Empty label.
    self.noAnnotsLabel = [[UILabel alloc] init];

    self.noAnnotsLabel.text = PTLocalizedString(@"This document does not contain any annotations.",
                                                @"Annotation summary: no annotations in document.");
    self.noAnnotsLabel.numberOfLines = 0;
    self.noAnnotsLabel.textAlignment = NSTextAlignmentCenter;
    self.noAnnotsLabel.lineBreakMode = NSLineBreakByWordWrapping;

    [self.view addSubview:self.noAnnotsLabel];
    
    self.noAnnotsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.noAnnotsLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [self.noAnnotsLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
       [self.noAnnotsLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.view.layoutMarginsGuide.widthAnchor],
       [self.noAnnotsLabel.heightAnchor constraintLessThanOrEqualToAnchor:self.view.layoutMarginsGuide.heightAnchor],
       ]];
    
    [self showEmptyLabel:NO];

    // Show done button for phones.
    self.showsDoneButton = (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular);
    
    if ([self editingEnabled]) {
        self.toolbarItems =
        @[
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
          self.editButtonItem,
          ];
    } else {
        self.toolbarItems = nil;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.showsDoneButton = self.view.frame.size.width ==  self.view.window.bounds.size.width;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
    
    [self refresh];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Reset editing state.
    self.editing = NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (self.showsDoneButton) {
        // Hide Done button while editing.
        UIBarButtonItem *rightBarButtonItem = editing ? nil : self.doneButton;
        
        [self.navigationItem setRightBarButtonItem:rightBarButtonItem animated:animated];
    }
}

- (void)showEmptyLabel:(BOOL)show
{
    BOOL hidden = !show;
    
    /*
     * The empty label needs to be centered in the view, but the default UITableView content insets
     * shift the table view's (Auto Layout) center down. Remove those insets.
     */
    if (@available(iOS 11, *)) {
        self.tableView.contentInsetAdjustmentBehavior = hidden ? UIScrollViewContentInsetAdjustmentAutomatic : UIScrollViewContentInsetAdjustmentNever;
    } else {
        PT_IGNORE_WARNINGS_BEGIN("deprecated-declarations")
        self.automaticallyAdjustsScrollViewInsets = hidden;
        PT_IGNORE_WARNINGS_END
    }
    
    self.tableView.scrollEnabled = hidden;
    
    self.noAnnotsLabel.hidden = hidden;
}

- (UITabBarItem *)tabBarItem
{
    UITabBarItem *tabBarItem = [super tabBarItem];
    
    if (![self isTabBarItemSetup]) {
        
        
        UIImage *image = [PTToolsUtil toolImageNamed:@"Annotation/Ink/Icon"];
        
        // Add image to tab bar item.
        tabBarItem.image = image;

        self.tabBarItemSetup = YES;
    }
    
    return tabBarItem;
}

#pragma mark - Done button

- (void)setShowsDoneButton:(BOOL)showsDoneButton
{
    _showsDoneButton = showsDoneButton;
    
    if (showsDoneButton && ![self isEditing]) {
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (UIBarButtonItem *)doneButton
{
    if (!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(dismiss)];
    }
    return _doneButton;
}

#pragma mark - Readonly

- (void)setReadonly:(BOOL)readonly
{
    _readonly = readonly;
    
    // Check if editing is enabled/disabled (takes tool manager into account as well).
    if ([self editingEnabled]) {
        // Add edit button to toolbar.
        self.toolbarItems =
        @[
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
          self.editButtonItem,
          ];
    } else {
        // Remove edit button from toolbar.
        self.toolbarItems = nil;
        
        // Exit edit mode if necessary.
        self.editing = NO;
    }
}

- (BOOL)editingEnabled
{
    // Editing is disabled when readonly is set on this control or tool manager.
    return (![self isReadonly] && ![self.toolManager isReadonly]);
}

-(PTAnnot*)annotationForIndexPath:(NSIndexPath*)indexPath
{
    NSError* error;
    BOOL success;
    __block PTAnnot* annot;
    
    success = [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        
        NSDictionary *anAnnotation = self.annotations[indexPath.section][indexPath.row];
        NSUInteger objNum = [anAnnotation[KEY_OBJNUM] unsignedIntegerValue];
        PTObj* ob = [[doc GetSDFDoc] GetObj:(unsigned int)objNum];
        annot = [[PTAnnot alloc] initWithD:ob];
        
        
    } error:&error];
    
    if( success )
    {
        return annot;
    }
    else
    {
        PTLog(@"Error retrieving annotation: %@", error);
        return Nil;
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.annotations.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.annotations.count > 0) {
        return self.annotations[section].count;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.annotations.count > 0) {
        NSDictionary<NSString *, id> *annotationItem = self.annotations[section].firstObject;
        
        int pageNumber = ((NSNumber *) annotationItem[KEY_PAGENUM]).intValue;
        
		NSString *localizedPage = PTLocalizedString(@"Page %d", @"Page number title");
        return [NSString localizedStringWithFormat:localizedPage, pageNumber];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
        
    if (self.annotations.count > 0 && self.annotations[indexPath.section].count)
	{
        NSDictionary *details = self.annotations[indexPath.section][indexPath.row];

        //cell.textLabel.text = [details objectForKey:KEY_SUBTYPE];
        cell.textLabel.text = details[KEY_CONTENTS];
        cell.accessoryType = UITableViewCellAccessoryNone;

        cell.textLabel.numberOfLines = 2;
        cell.textLabel.font = [UIFont systemFontOfSize:14.0f];

        cell.imageView.image = AnnotationImage([details[KEY_TYPE] intValue]);
        cell.imageView.tintColor = details[KEY_COLOR];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self editingEnabled];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        self.removingAnnotation = YES;
        
        NSDictionary *anAnnotation = self.annotations[indexPath.section][indexPath.row];
        
        int pageNumber = [anAnnotation[@"pageNumber"] intValue];
        PTAnnot* annot;
        BOOL updated = NO;
        BOOL success = NO;
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            
            PTPDFDoc* document = [self.pdfViewCtrl GetDoc];
            
            NSUInteger objNum = [anAnnotation[KEY_OBJNUM] unsignedIntegerValue];
            PTObj* ob = [[document GetSDFDoc] GetObj:(unsigned int)objNum];
            annot = [[PTAnnot alloc] initWithD:ob];
            
            PTPage* pg = [document GetPage:pageNumber];
            
            
            if ([pg IsValid] && [annot IsValid]) {
                
                [self.toolManager willRemoveAnnotation:annot onPageNumber:pageNumber];
                
                [pg AnnotRemoveWithAnnot:annot];
                success = YES;
            }
            
            NSMutableArray* pagesOnScreen = [self.pdfViewCtrl GetVisiblePages];
            
            for( NSNumber* pageNum in pagesOnScreen )
            {
                if( pageNum.intValue == pageNumber)
                {
                    [self.pdfViewCtrl UpdateWithAnnot:annot page_num:pageNumber];
                    updated = YES;
                    break;
                }
            }
            
            if( !updated && success)
                [self.pdfViewCtrl Update:YES];
            
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
            if( !updated && success)
                [self.pdfViewCtrl Update:YES];
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
        
        if( success )
        {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.annotations[indexPath.section] removeObjectAtIndex:indexPath.row];
            if( self.annotations[indexPath.section].count == 0 )
            {
                [self.annotations removeObjectAtIndex:indexPath.section];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            }
            [self.tableView endUpdates];
            
            [self.toolManager selectAnnotation:nil onPageNumber:pageNumber];
            
            // Notify tool manager of removal.
            [self.toolManager annotationRemoved:annot onPageNumber:pageNumber];
            
            // Notify delegate.
            if ([self.delegate respondsToSelector:@selector(annotationViewController:annotationRemoved:onPageNumber:)]) {
                [self.delegate annotationViewController:self annotationRemoved:annot onPageNumber:pageNumber];
            }
        }
        
        self.removingAnnotation = NO;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Bookmark] Navigated by Annotation List"];
    
	 NSDictionary *anAnnotation = self.annotations[indexPath.section][indexPath.row];
	
	int pageNumber = [anAnnotation[KEY_PAGENUM] intValue];
    NSUInteger objNum = [anAnnotation[KEY_OBJNUM] unsignedIntegerValue];
    
    
    PTObj* ob = [[[self.pdfViewCtrl GetDoc] GetSDFDoc] GetObj:(unsigned int)objNum];
    PTAnnot* annot = [[PTAnnot alloc] initWithD:ob];

    if (self.pdfViewCtrl.currentPage != pageNumber) {
        self.toolManager.tool.currentAnnotation = nil;
        [self.pdfViewCtrl SetCurrentPage:pageNumber];
    }

	if ([self.delegate respondsToSelector:@selector(annotationViewController:selectedAnnotaion:)]) {
		[self.delegate annotationViewController:self selectedAnnotaion:anAnnotation];
	}

    BOOL selectedAnnot = NO;

    if ([annot IsValid]) {
        selectedAnnot = [self.toolManager selectAnnotation:annot onPageNumber:pageNumber];
    }

    if (!selectedAnnot) {
        [self flashAnnot:annot onPage:pageNumber];
    }
}

-(void)flashAnnot:(PTAnnot*)annot onPage:(int)pageNumber
{
    PTPDFRect* screen_rect = [self.pdfViewCtrl GetScreenRectForAnnot:annot page_num: pageNumber];
    double x1 = [screen_rect GetX1];
    double x2 = [screen_rect GetX2];
    double y1 = [screen_rect GetY1];
    double y2 = [screen_rect GetY2];

    CGRect rect = CGRectMake(MIN(x1,x2), MIN(y1, y2), MAX(x1,x2) - MIN(x1,x2), MAX(y1, y2) - MIN(y1, y2));

    rect.origin.x += [self.pdfViewCtrl GetHScrollPos];
    rect.origin.y += [self.pdfViewCtrl GetVScrollPos];

    // Create a view to be our highlight marker
    UIView *highlight = [[UIView alloc] initWithFrame:rect];
    highlight.backgroundColor = [UIColor colorWithRed:0.4375f green:0.53125f blue:1.0f alpha:1.0f];
    [self.pdfViewCtrl.toolOverlayView addSubview:highlight];

    NSTimeInterval delay = 0.0;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        delay = 0.3;
    }

    // Pulse the annotation. There seem to be issues with the built-in repeat and auto-reverse...
    highlight.alpha = 0.0f;

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

        [UIView animateWithDuration:0.20f delay:0.0f options:0 animations:^(void) {
            highlight.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.20f delay:0.0f options:0 animations:^(void) {
                highlight.alpha = 0.4f;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.20f delay:0.0f options:0 animations:^(void) {
                    highlight.alpha = 1.0f;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.20f delay:0.0f options:0 animations:^(void) {
                        highlight.alpha = 0.0f;
                    } completion:^(BOOL finished) {
                        [highlight removeFromSuperview];
                    }];
                }];
            }];
        }];
    });
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - Annotation loading

// @TODO: refresh annotations when the user adds a new annotation
- (void)beginAddingAnnotationResultsForDocument:(PTPDFDoc *)document
{
    @autoreleasepool {
        [document LockRead];
        
		BOOL annotFound = NO;
        PTPageIterator* pageIterator = [document GetPageIterator:1];
        int idx = 0;
        PTTextExtractor* textExtractor = [[PTTextExtractor alloc] init];
        while ([pageIterator HasNext]) {
            idx++;
            PTPage *page = [pageIterator Current];
            NSMutableArray *annotations = [NSMutableArray array];

            if ([page IsValid]) {
                int annotationCount = [page GetNumAnnots];
                for (int a = 0; a < annotationCount; a++) {
                    PTAnnot *annotation = [page GetAnnot:a];
                    if (!annotation || ![annotation IsValid]) { continue; }
                    if (!AnnotationImage((int)[annotation extendedAnnotType])) { continue; }

                    NSString* contents = @"";
                    switch ([annotation extendedAnnotType]) {
                        case PTExtendedAnnotTypeFreeText:
                        case PTExtendedAnnotTypeRuler:
                        case PTExtendedAnnotTypePerimeter:
                        case PTExtendedAnnotTypeArea:
                            contents = [annotation GetContents];
                            break;
                        case PTExtendedAnnotTypeLine:
                        case PTExtendedAnnotTypeSquare:
                        case PTExtendedAnnotTypeCircle:
                        case PTExtendedAnnotTypePolygon:
                        case PTExtendedAnnotTypeText:
                        case PTExtendedAnnotTypeInk:
                        case PTExtendedAnnotTypeFreehandHighlight:
                        case PTExtendedAnnotTypeStamp:
                        case PTExtendedAnnotTypeImageStamp:
                        case PTExtendedAnnotTypePencilDrawing:
                        case PTExtendedAnnotTypeSignature:
                        {
                            PTMarkup* annot = [[PTMarkup alloc] initWithAnn:annotation];
							NSString* author = [annot GetTitle];
							if( !author )
								 author = @"";
							if( author.length > 0 )
							{
								contents = author;
							}
                            PTPopup* popup = [annot GetPopup];
                            if([popup IsValid]) {
								
								NSString* popupContents = [popup GetContents];
                                if( popupContents.length > 0 )
                                {
                                    if( author.length > 0 )
                                    {
                                        contents = [NSString stringWithFormat:@"%@: %@",author, popupContents];
                                    }
                                    else
                                    {
                                        contents = popupContents;
                                    }
                                }
                            }

                            break;
                        }
                        case PTExtendedAnnotTypeUnderline:
                        case PTExtendedAnnotTypeStrikeOut:
                        case PTExtendedAnnotTypeHighlight:
                        case PTExtendedAnnotTypeSquiggly:
                            [textExtractor Begin:page clip_ptr:0 flags:e_ptno_ligature_exp];
                            contents = [textExtractor GetTextUnderAnnot:annotation];
                            break;
                        default:
                            break;
                    }

                    PTExtendedAnnotType kind = [annotation extendedAnnotType];
                    
                    if ([annotation extendedAnnotType] == PTExtendedAnnotTypeLine) {
                        PTObj* lineSdf = [annotation GetSDFObj];
                        PTObj* lineObj = [lineSdf FindObj:@"LE"];
                        
                        if( [lineObj IsValid] && [lineObj IsArray])
                        {
                            unsigned long s = [lineObj Size];
                            for(unsigned long i = 0; i < s; i++)   
                            {
                                PTObj* obj = [lineObj GetAt:i];
                                if( [obj IsName] && ([[obj GetName] isEqualToString:@"OpenArrow"] || [[obj GetName] isEqualToString:@"ClosedArrow"] ) )
                                {
                                    kind = XE_ARROW;
                                    break;   
                                }   
                            }
                        }
                    }
                    else if (kind == PTExtendedAnnotTypePolygon) {
                        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annotation];
                        if ([markup GetBorderEffect] == e_ptCloudy) {
                            kind = XE_CLOUD;
                        }
                    }
                    
                    unsigned int objNum = [[annotation GetSDFObj] GetObjNum];
                    
                    if( !contents )
                        contents = @"";
                    
                    
					
                    [annotations addObject:@{KEY_PAGENUM: @(idx), 
                                            KEY_SUBTYPE: [[[[annotation GetSDFObj] Get: @"Subtype"] Value] GetName].description,
                                            KEY_TYPE: @(kind),
                                            KEY_RECT: [annotation GetRect],
                                            KEY_CONTENTS: [contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]],
											KEY_OBJNUM: @(objNum),
                                            KEY_COLOR: annotation.colorPrimary
                    }];
                }
            }
            
            [document UnlockRead];
            
            NSThread *thread = NSThread.currentThread;
            
            if (thread.cancelled) { return; }
            
            if (annotations.count > 0) {
				annotFound = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.runner != thread) {
                        return;
                    }
                    
                    [self showEmptyLabel:NO];
                    [self addAnnotations:annotations];
                });
            }

            [document LockRead];
            
            [pageIterator Next];
        }

        [document UnlockRead];
		
        if( !annotFound ) {
            NSThread *thread = NSThread.currentThread;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.runner != thread) {
                    return;
                }
                
                [self showEmptyLabel:YES];
            });
        }
    }
}

- (void)removeAllAnnotsInDoc:(PTPDFDoc *)doc
{
    @try {
        PTPageIterator *pageIterator = [doc GetPageIterator:1];
        while ([pageIterator HasNext]) {
            PTPage *page = [pageIterator Current];
            
            if ([page IsValid]) {
                int annotationCount = [page GetNumAnnots];
                for (int annotIndex = annotationCount - 1; annotIndex >= 0; annotIndex--) {
                    @try {
                        PTAnnot *annot = [page GetAnnot:annotIndex];
                        
                        if (![annot IsValid]) {
                            continue;
                        }
                        if ([annot extendedAnnotType] != PTExtendedAnnotTypeLink && [annot extendedAnnotType] != PTExtendedAnnotTypeWidget) {
                            [page AnnotRemoveWithAnnot:annot];
                        }
                    } @catch (NSException *exception) {
                        // Ignore
                    }
                }
            }
            
            [pageIterator Next];
        }
    } @catch (NSException *exception) {
        // Ignored
    }
}

#pragma mark - Notifications

- (void)toolManagerAnnotationAddedNotification:(NSNotification *)notification
{
    [self refreshIfVisible];
}

- (void)toolManagerAnnotationModifiedNotification:(NSNotification *)notification
{
    [self refreshIfVisible];
}

- (void)toolManagerAnnotationRemovedNotification:(NSNotification *)notification
{
    // Check if the removal was triggered by this control.
    if ([self isRemovingAnnotation]) {
        return;
    }
    
    [self refreshIfVisible];
}

#pragma mark - Convenience

-(void)ConvertPagePtToScreenPtX:(CGFloat*)x Y:(CGFloat*)y PageNumber:(int)pageNumber
{
    PTPDFPoint *pagePt = [[PTPDFPoint alloc] initWithPx:(*x) py:(*y)];
    
    [pagePt setX:*x];
    [pagePt setY:*y];
    
    PTPDFPoint *m_screenPt = [self.pdfViewCtrl ConvPagePtToScreenPt:pagePt page_num:pageNumber];
    
    *x = (float)[m_screenPt getX];
    *y = (float)[m_screenPt getY];
}

-(CGRect)PDFRectPage2CGRectScreen:(PTPDFRect*)r PageNumber:(int)pageNumber
{
    PTPDFPoint* pagePtA = [[PTPDFPoint alloc] init];
    PTPDFPoint* pagePtB = [[PTPDFPoint alloc] init];
    
    [pagePtA setX:[r GetX1]];
    [pagePtA setY:[r GetY2]];
    
    [pagePtB setX:[r GetX2]];
    [pagePtB setY:[r GetY1]];
    
    CGFloat paX = [pagePtA getX];
    CGFloat paY = [pagePtA getY];
    
    CGFloat pbX = [pagePtB getX];
    CGFloat pbY = [pagePtB getY];
    
    
    [self ConvertPagePtToScreenPtX:&paX Y:&paY PageNumber:pageNumber];
    [self ConvertPagePtToScreenPtX:&pbX Y:&pbY PageNumber:pageNumber];
    
    return CGRectMake(paX, paY, pbX-paX, pbY-paY);
}

@end
