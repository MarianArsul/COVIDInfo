//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationToolbar.h"

#import "PTArrowCreate.h"
#import "PTEllipseCreate.h"
#import "PTFreeHandCreate.h"
#import "PTFreeHandHighlightCreate.h"
#import "PTPencilDrawingCreate.h"
#import "PTFreeTextCreate.h"
#import "PTCalloutCreate.h"
#import "PTLineCreate.h"
#import "PTRectangleCreate.h"
#import "PTStickyNoteCreate.h"
#import "PTPanTool.h"
#import "PTTextHighlightCreate.h"
#import "PTTextStrikeoutCreate.h"
#import "PTTextUnderlineCreate.h"
#import "PTTextSquigglyCreate.h"
#import "PTDigitalSignatureTool.h"
#import "PTAnalyticsManager.h"
#import "PTEraser.h"
#import "PTPolylineCreate.h"
#import "PTPolygonCreate.h"
#import "PTPencilDrawingCreate.h"
#import "PTCloudCreate.h"
#import "PTRulerCreate.h"
#import "PTPerimeterCreate.h"
#import "PTAreaCreate.h"
#import "PTToolsUtil.h"
#import "PTAnnotStyleViewController.h"
#import "PTPopoverNavigationController.h"

#import "NSLayoutConstraint+PTPriority.h"
#import "UIView+PTAdditions.h"

static const CGFloat PT_annotationToolbarButtonWidth = 44.0;
static const CGFloat PT_annotationToolbarButtonHeight = 40.0;

@interface PTAnnotationToolbar () <PTAnnotStyleViewControllerDelegate> {
	NSMutableArray* _buttonsArray;
}

@property (nonatomic, readonly, strong) UIColor *selectedTintColor;

@property (nonatomic, strong) PTEditToolbar *editToolbar;

@property (nonatomic) PTExtendedAnnotType toolAnnotType;

@property (nonatomic, strong) NSLayoutConstraint *editToolbarOnscreenConstraint;
@property (nonatomic, strong) NSLayoutConstraint *editToolbarOffscreenConstraint;

#pragma mark Annotation style view controller
@property (nonatomic) PTAnnotStyleViewController *stylePicker;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation PTAnnotationToolbar
#pragma clang diagnostic pop

// order in which buttons should appear
//-2 Comment
//-3 Highlight
//-6 Strike
//-7 Underline
//-13 Squiggly
//-5 Signature
//-4 FreeHand
//-8 FreeText
//-9 Arrow
//-12 Line
//-10 Rectangle
//-11 Elipse
//-14 Polyline
//-15 Polygon
//-16 Cloud
//-1 Pan


static PTExtendedAnnotType PTExtendedAnnotTypeForBarButton(PTAnnotBarButton buttonType)
{
    switch (buttonType) {
        case PTAnnotBarButtonStickynote:
            return PTExtendedAnnotTypeText;
        case PTAnnotBarButtonHighlight:
            return PTExtendedAnnotTypeHighlight;
        case PTAnnotBarButtonStrikeout:
            return PTExtendedAnnotTypeStrikeOut;
        case PTAnnotBarButtonUnderline:
            return PTExtendedAnnotTypeUnderline;
        case PTAnnotBarButtonSquiggly:
            return PTExtendedAnnotTypeSquiggly;
        case PTAnnotBarButtonSignature:
            return PTExtendedAnnotTypeSignature;
        case PTAnnotBarButtonFreehand:
            return PTExtendedAnnotTypeInk;
            
        case PTAnnotBarButtonFreetext:
            return PTExtendedAnnotTypeFreeText;
        case PTAnnotBarButtonArrow:
            return PTExtendedAnnotTypeArrow;
        case PTAnnotBarButtonLine:
            return PTExtendedAnnotTypeLine;
        case PTAnnotBarButtonRectangle:
            return PTExtendedAnnotTypeSquare;
        case PTAnnotBarButtonEllipse:
            return PTExtendedAnnotTypeCircle;
        case PTAnnotBarButtonPolygon:
            return PTExtendedAnnotTypePolygon;
        case PTAnnotBarButtonCloud:
            return PTExtendedAnnotTypeCloudy;
        case PTAnnotBarButtonPolyline:
            return PTExtendedAnnotTypePolyline;
        case PTAnnotBarButtonRuler:
            return PTExtendedAnnotTypeRuler;
        case PTAnnotBarButtonPerimeter:
            return PTExtendedAnnotTypePerimeter;
        case PTAnnotBarButtonArea:
            return PTExtendedAnnotTypeArea;
        case PTAnnotBarButtonFreehandHighlight:
            return PTExtendedAnnotTypeFreehandHighlight;
        case PTAnnotBarButtonCallout:
            return PTExtendedAnnotTypeCallout;
            
        // Button types without an annotation type.
        case PTAnnotBarButtonEraser:
        case PTAnnotBarButtonPan:
        case PTAnnotBarButtonClose:
        default:
            return PTExtendedAnnotTypeUnknown;
    }
}

@dynamic delegate;

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [super initWithFrame:UIScreen.mainScreen.bounds];
    if (self) {
        _toolManager = toolManager;
                
        _editToolbar = [[PTEditToolbar allocOverridden] initWithFrame:self.bounds];
        _editToolbar.translatesAutoresizingMaskIntoConstraints = NO;
        _editToolbar.delegate = self;
        _editToolbar.hidden = YES;

        [self addSubview:_editToolbar];

        _editToolbarOnscreenConstraint = [_editToolbar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
        _editToolbarOffscreenConstraint = [_editToolbar.bottomAnchor constraintEqualToAnchor:self.topAnchor];

        [NSLayoutConstraint activateConstraints:@[
            [_editToolbar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_editToolbar.heightAnchor constraintEqualToAnchor:self.heightAnchor],
            [_editToolbar.widthAnchor constraintEqualToAnchor:self.widthAnchor],
            // Edit toolbar starts offscreen.
            _editToolbarOffscreenConstraint,
        ]];
        
        _buttonsArray = [NSMutableArray array];
        
        NSDictionary<NSNumber *, NSString *> *toolButtonData = @{
            @(PTAnnotBarButtonStickynote)   : @"Annotation/Comment/Icon",
            @(PTAnnotBarButtonSignature)    : @"Annotation/Signature/Icon",
            @(PTAnnotBarButtonFreehand)     : @"Annotation/Ink/Icon",
            @(PTAnnotBarButtonRectangle)    : @"Annotation/Square/Icon",
            @(PTAnnotBarButtonArrow)        : @"Annotation/Arrow/Icon",
            @(PTAnnotBarButtonFreetext)     : @"Annotation/FreeText/Icon",
            @(PTAnnotBarButtonHighlight)    : @"Annotation/Highlight/Icon",
            @(PTAnnotBarButtonUnderline)    : @"Annotation/Underline/Icon",
            @(PTAnnotBarButtonSquiggly)     : @"Annotation/Squiggly/Icon",
            @(PTAnnotBarButtonStrikeout)    : @"Annotation/StrikeOut/Icon",
            @(PTAnnotBarButtonEraser)       : @"Tool/Eraser/Icon",
            @(PTAnnotBarButtonLine)         : @"Annotation/Line/Icon",
            @(PTAnnotBarButtonEllipse)      : @"Annotation/Circle/Icon",
            @(PTAnnotBarButtonPolyline)     : @"Annotation/Polyline/Icon",
            @(PTAnnotBarButtonPolygon)      : @"Annotation/Polygon/Icon",
            @(PTAnnotBarButtonCloud)        : @"Annotation/Cloud/Icon",
            @(PTAnnotBarButtonRuler)        : @"Annotation/Distance/Icon",
            @(PTAnnotBarButtonPerimeter)    : @"Annotation/Perimeter/Icon",
            @(PTAnnotBarButtonArea)         : @"Annotation/AreaRectangle/Icon",
            @(PTAnnotBarButtonFreehandHighlight) : @"Annotation/FreeHighlight/Icon",
            @(PTAnnotBarButtonCallout)      : @"Annotation/Callout/Icon",
            @(PTAnnotBarButtonPan)          : @"ic_pan_black_24dp"
        };
         
        // Build buttons for each tool type.
        for (NSNumber *key in toolButtonData) {
            NSString *imageName = toolButtonData[key];
            PTAnnotBarButton tag = key.integerValue;
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            UIImage* buttonImage = [PTToolsUtil toolImageNamed:imageName];
            if( @available(iOS 13.1, *) )
            {
                if( tag == PTAnnotBarButtonFreehand && [self.toolManager freehandUsesPencilKit] )
                {
                    buttonImage = [UIImage systemImageNamed:@"pencil.tip.crop.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
                }
            }

            [button setImage:buttonImage forState:UIControlStateNormal];
            
            button.tag = tag; // Used to identify the button's tool type.
            
            // Auto Layout within UIToolbars & UIBarButtonItems is iOS 11+.
            if (@available(iOS 11, *)) {
                button.translatesAutoresizingMaskIntoConstraints = NO;
                
                // Dimension constraints are optional to allow some layout flexibility.
                [NSLayoutConstraint pt_activateConstraints:@[
                    [button.widthAnchor constraintEqualToConstant:PT_annotationToolbarButtonWidth],
                    [button.heightAnchor constraintEqualToConstant:PT_annotationToolbarButtonHeight],
                ] withPriority:UILayoutPriorityDefaultHigh];
            } else {
                button.frame = CGRectMake(0.0, 0.0, PT_annotationToolbarButtonWidth, PT_annotationToolbarButtonHeight);
            }
            
            // Round button (background) corners.
            button.layer.masksToBounds = NO;
            button.layer.cornerRadius = 4;
            
            [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragEnter)];
            [button addTarget:self action:@selector(buttonTouchCancelled:) forControlEvents:UIControlEventTouchDragExit];
            [button addTarget:self action:@selector(toggleButton:) forControlEvents:UIControlEventTouchUpInside];
            
            // Add configured button to list.
            [_buttonsArray addObject:button];
        }
        
        // Close button requires special treatment.
        UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (@available(iOS 11, *)) {
            closeButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            [NSLayoutConstraint pt_activateConstraints:@[
                [closeButton.widthAnchor constraintEqualToConstant:PT_annotationToolbarButtonHeight],
                [closeButton.heightAnchor constraintEqualToConstant:PT_annotationToolbarButtonHeight],
            ] withPriority:UILayoutPriorityDefaultHigh];
        } else {
            closeButton.frame = CGRectMake(0.0, 0.0, PT_annotationToolbarButtonWidth, PT_annotationToolbarButtonHeight);
        }
        
        UIImage *image;
        
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
            closeButton.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        }
        
        if( image == Nil )
        {
            image = [PTToolsUtil toolImageNamed:@"ic_close_white_24dp"];
        }
        
        [closeButton setImage:image forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(doCancel:) forControlEvents:UIControlEventTouchUpInside];
        closeButton.tag = PTAnnotBarButtonClose;
        [_buttonsArray addObject:closeButton];
        
        _precedenceArray = @[
            @(PTAnnotBarButtonClose),
            @(PTAnnotBarButtonPan),
            @(PTAnnotBarButtonStickynote),
            @(PTAnnotBarButtonHighlight),
            @(PTAnnotBarButtonFreehand),
            @(PTAnnotBarButtonSignature),
            @(PTAnnotBarButtonFreetext),
            @(PTAnnotBarButtonStrikeout),
            @(PTAnnotBarButtonUnderline),
            @(PTAnnotBarButtonSquiggly),
            @(PTAnnotBarButtonArrow),
            @(PTAnnotBarButtonEraser),
            @(PTAnnotBarButtonEllipse),
            @(PTAnnotBarButtonLine),
            @(PTAnnotBarButtonRectangle),
            @(PTAnnotBarButtonPolygon),
            @(PTAnnotBarButtonCloud),
            @(PTAnnotBarButtonPolyline),
            @(PTAnnotBarButtonRuler),
            @(PTAnnotBarButtonPerimeter),
            @(PTAnnotBarButtonArea),
            @(PTAnnotBarButtonFreehandHighlight),
            @(PTAnnotBarButtonCallout),
        ];
        
        [self resetButtonItems];
        
        // Register for tool manager notifications.
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(toolManagerToolDidChangeNotification:)
                                                   name:PTToolManagerToolDidChangeNotification
                                                 object:toolManager];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(toolManagerAnnotationOptionsDidChangeNotification:)
                                                   name:PTToolManagerAnnotationOptionsDidChangeNotification
                                                 object:toolManager];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.editToolbar isHidden]) {
        [self resetButtonItems];
    }
    
    [self updateButtonAppearances];
}

- (void)setPrecedenceArray:(NSArray<NSNumber *> *)precedenceArray
{
    _precedenceArray = precedenceArray;
    
    [self resetButtonItems];
}

-(void)resetButtonItems
{
	UIBarButtonItem* sideSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	sideSpaceLeft.width = 10;
	UIBarButtonItem* sideSpaceRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	sideSpaceRight.width = 10;
	
	NSMutableArray* objectsForToolbar = [[NSMutableArray alloc] init];
	
	[objectsForToolbar addObject:sideSpaceLeft];
	[objectsForToolbar addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];

    CGFloat maxWidth = PT_annotationToolbarButtonWidth;
    
    // set number of toolbar items based on available space (for iPhone portrait orientation)
	NSUInteger maxPermitted = MIN([self.precedenceArray count] ,(unsigned int)([self bounds].size.width / maxWidth));

	int added = 0;
	
	for(int i = 0; i <= _buttonsArray.count; i++)
	{
		for(int j = 0; j < maxPermitted; j++ ) {
            if( i != [self.precedenceArray[j] intValue]) {
                continue;
            }

            int tagWeWant = i;
            
            // Check if annotation type can be created.
            PTExtendedAnnotType annotType = PTExtendedAnnotTypeForBarButton(tagWeWant);
            if (annotType != PTExtendedAnnotTypeUnknown && ![self.toolManager canCreateExtendedAnnotType:annotType]) {
                // Can't create annotation of this type.
                continue;
            }
            
            // Check if eraser is enabled.
            if (tagWeWant == PTAnnotBarButtonEraser && (![self.toolManager isEraserEnabled] || self.toolManager.isReadonly)) {
                continue;
            }
            
            for (UIButton* button in _buttonsArray) {
                if( button.tag == tagWeWant )
                {
                    if( button.tag == PTAnnotBarButtonFreehand )
                    {
                        if( @available(iOS 13.1, *) )
                        {
                            UIImage* buttonImage;
                            
                            if( [self.toolManager freehandUsesPencilKit] )
                            {
                                buttonImage = [UIImage systemImageNamed:@"pencil.tip.crop.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
                            }
                            else
                            {
                                buttonImage = [PTToolsUtil toolImageNamed:@"Annotation/Ink/Icon"];
                            }
                            [button setImage:buttonImage forState:UIControlStateNormal];
                        }
                    }
                    
                    
                    [objectsForToolbar addObject:[[UIBarButtonItem alloc] initWithCustomView:button]];
                    [objectsForToolbar addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
                    added++;
                    if( added >= maxPermitted )
                        goto escapeLoops;
                }
            }
				
		}
	}
	
escapeLoops:
	
	[objectsForToolbar addObject:sideSpaceRight];
	
	self.items = nil;
	self.items = [NSArray arrayWithArray:[objectsForToolbar copy]];
}

-(void)rotateToOrientation:(UIDeviceOrientation)orientation
{
	[self resetButtonItems];
    [self updateButtonAppearances];
    [self bringSubviewToFront:self.editToolbar];
}

-(void)buttonTouchDown:(UIButton*)button
{
	button.backgroundColor = self.tintColor;
    button.imageView.tintColor = nil; // Default tint color.
}

-(void)buttonTouchCancelled:(UIButton *)button
{
    // Reset button state.
    [self setButton:button selected:button.selected];
}

- (void)setButton:(UIButton *)button selected:(BOOL)selected
{
    button.selected = selected;
    
    if (selected) {
        button.backgroundColor = self.tintColor;
        button.imageView.tintColor = self.selectedTintColor;
    } else {
        button.backgroundColor = nil; // Transparent background.
        button.imageView.tintColor = nil; // Default tint color.
    }
}

-(void)toggleButton:(UIButton*)button
{
	[self toggleButton:button andSetTool:YES];
}

-(void)toggleButton:(UIButton*)button andSetTool:(BOOL)setTool
{
    for (UIBarButtonItem *item in self.items) {
        if ([item.customView isKindOfClass:[UIButton class]]) {
            UIButton *customButton = (UIButton *) item.customView;
            
            [self setButton:customButton selected:(customButton == button)];
        }
    }

	if( setTool )
	{
		BOOL backToPan;
		
        if ([self.delegate respondsToSelector:@selector(toolShouldGoBackToPan:)])
            backToPan = [self.delegate toolShouldGoBackToPan:self];
		else
			backToPan = YES;

		switch (button.tag) {
			case PTAnnotBarButtonSignature:
				{
					PTDigitalSignatureTool* dst = (PTDigitalSignatureTool*)[self.toolManager changeTool:[PTDigitalSignatureTool class]];
					
					// always false
					dst.backToPanToolAfterUse = NO;

					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Signature selected"];
				}
				break;
			case PTAnnotBarButtonFreehand:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Freehand selected"];
					
                    BOOL isPencilTool = [self.toolManager freehandUsesPencilKit];
                    if (!isPencilTool) {
                        PTFreeHandCreate* fhc = (PTFreeHandCreate*)[self.toolManager changeTool:[PTFreeHandCreate class]];
                        fhc.multistrokeMode = YES;
                        fhc.delegate = self;
                        fhc.backToPanToolAfterUse = NO;
                    } else if ([self.toolManager freehandUsesPencilKit]) {
                        if (@available(iOS 13.1, *) ) {
                            PTPencilDrawingCreate* pdc = (PTPencilDrawingCreate*)[self.toolManager changeTool:[PTPencilDrawingCreate class]];
                            pdc.backToPanToolAfterUse = NO;
                            pdc.shouldShowToolPicker = YES;
                        }
                    }
                    [self addEditToolbar];
                }
                break;
            case PTAnnotBarButtonRectangle:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Rectangle selected"];
					
					PTRectangleCreate* rc = (PTRectangleCreate*)[self.toolManager changeTool:[PTRectangleCreate class]];
					rc.backToPanToolAfterUse = backToPan;
				}
				break;
			case PTAnnotBarButtonArrow:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Arrow selected"];
					
					PTArrowCreate* ac = (PTArrowCreate*)[self.toolManager changeTool:[PTArrowCreate class]];
					ac.backToPanToolAfterUse = backToPan;
				}
				break;
			case PTAnnotBarButtonFreetext:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Freetext selected"];
					
					PTFreeTextCreate* ftc = (PTFreeTextCreate*)[self.toolManager changeTool:[PTFreeTextCreate class]];
					ftc.backToPanToolAfterUse = backToPan;
				}
				break;
			case PTAnnotBarButtonUnderline:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Underline selected"];
					
					PTTextUnderlineCreate* tuc = (PTTextUnderlineCreate*)[self.toolManager changeTool:[PTTextUnderlineCreate class]];
					tuc.backToPanToolAfterUse = backToPan;
				}
				break;
                
            case PTAnnotBarButtonSquiggly:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Squiggly selected"];
                
                PTTextSquigglyCreate* tsc = (PTTextSquigglyCreate*)[self.toolManager changeTool:[PTTextSquigglyCreate class]];
                tsc.backToPanToolAfterUse = backToPan;
            }
                break;
			case PTAnnotBarButtonStrikeout:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Strikeout selected"];
					
					PTTextStrikeoutCreate* tsc = (PTTextStrikeoutCreate*)[self.toolManager changeTool:[PTTextStrikeoutCreate class]];
					tsc.backToPanToolAfterUse = backToPan;
				}
				break;
			case PTAnnotBarButtonHighlight:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Highlight selected"];
					
					PTTextHighlightCreate* thc = (PTTextHighlightCreate*)[self.toolManager changeTool:[PTTextHighlightCreate class]];
					thc.backToPanToolAfterUse = backToPan;
				}
				break;
			case PTAnnotBarButtonStickynote:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Sticky Note selected"];
					PTStickyNoteCreate* snc = (PTStickyNoteCreate*)[self.toolManager changeTool:[PTStickyNoteCreate class]];
					snc.backToPanToolAfterUse = backToPan;
				}
				break;
			case PTAnnotBarButtonEraser:
			{
				[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Eraser selected"];
				PTEraser* eraser = (PTEraser*)[self.toolManager changeTool:[PTEraser class]];
				eraser.backToPanToolAfterUse = backToPan;
			}
				break;
			case PTAnnotBarButtonLine:
			{
				[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Line selected"];
				PTLineCreate* lc = (PTLineCreate*)[self.toolManager changeTool:[PTLineCreate class]];
				lc.backToPanToolAfterUse = backToPan;
			}
				break;
            case PTAnnotBarButtonPolyline:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Polyline selected"];
                PTPolylineCreate *polylineCreate = (PTPolylineCreate *)[self.toolManager changeTool:[PTPolylineCreate class]];
                polylineCreate.backToPanToolAfterUse = backToPan;
                
                [self addEditToolbar];
            }
                break;
            case PTAnnotBarButtonPolygon:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Polygon selected"];
                PTPolygonCreate *polygonCreate = (PTPolygonCreate *)[self.toolManager changeTool:[PTPolygonCreate class]];
                polygonCreate.backToPanToolAfterUse = backToPan;
                
                [self addEditToolbar];
            }
                break;
            case PTAnnotBarButtonCloud:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Cloud selected"];
                PTCloudCreate *cloudCreate = (PTCloudCreate *)[self.toolManager changeTool:[PTCloudCreate class]];
                cloudCreate.backToPanToolAfterUse = backToPan;
                
                [self addEditToolbar];
            }
                break;
			case PTAnnotBarButtonEllipse:
			{
				[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Ellipse selected"];
				PTEllipseCreate* ec = (PTEllipseCreate*)[self.toolManager changeTool:[PTEllipseCreate class]];
				ec.backToPanToolAfterUse = backToPan;
			}
				break;
            case PTAnnotBarButtonRuler:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Ruler selected"];
                PTRulerCreate *rulerCreate = (PTRulerCreate *)[self.toolManager changeTool:[PTRulerCreate class]];
                rulerCreate.backToPanToolAfterUse = backToPan;
            }
                break;
            case PTAnnotBarButtonPerimeter:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Perimeter selected"];
                PTPerimeterCreate *perimeterCreate = (PTPerimeterCreate *)[self.toolManager changeTool:[PTPerimeterCreate class]];
                perimeterCreate.backToPanToolAfterUse = backToPan;
                
                [self addEditToolbar];
            }
                break;
            case PTAnnotBarButtonArea:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Area selected"];
                PTAreaCreate* areaCreate = (PTAreaCreate*)[self.toolManager changeTool:[PTAreaCreate class]];
                areaCreate.backToPanToolAfterUse = backToPan;
                
                [self addEditToolbar];
            }
                break;
            case PTAnnotBarButtonFreehandHighlight:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Freehand highlight selected"];
                
                PTFreeHandHighlightCreate* fhc = (PTFreeHandHighlightCreate*)[self.toolManager changeTool:[PTFreeHandHighlightCreate class]];
                fhc.delegate = self;
                fhc.backToPanToolAfterUse = NO;
            }
                break;
            case PTAnnotBarButtonCallout:
            {
                [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Callout selected"];
                
                PTCalloutCreate* coc = (PTCalloutCreate*)[self.toolManager changeTool:[PTCalloutCreate class]];
                coc.backToPanToolAfterUse = backToPan;
            }
                break;
			default: //PTAnnotBarButtonPan:
				{
					[PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Annotation Toolbar] Pan selected"];
					
					PTPanTool* pt = (PTPanTool*)[self.toolManager changeTool:[PTPanTool class]];
					pt.backToPanToolAfterUse = backToPan;
				}
				break;
		}
	}
    
    PTTool *tool = self.toolManager.tool;
    
    if(tool.canEditStyle && self.editToolbar.hidden){
        [button setBackgroundImage:[self stylePickerDisclosureImageFromRect:button.frame] forState:UIControlStateSelected];
    }

    _toolAnnotType = tool.annotType;
    
    // Check if the same tool was selected
    BOOL sameToolSelected = [tool isKindOfClass:tool.previousToolType];
    
    // If the same tool was selected and the tool can have its style modified, show the style picker
    if ( sameToolSelected && tool.canEditStyle ){
        [self toggleStylePicker:button];
    } else if( self.stylePicker ){
        [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
        self.stylePicker = nil;
    }
    
}

- (void)doCancel: (UIBarButtonSystemItem*)barButton {
    if ([self.delegate respondsToSelector:@selector(annotationToolbarDidCancel:)]) {
        [self.delegate annotationToolbarDidCancel:self];
    }
    [self.toolManager createSwitchToolEvent:@"CloseAnnotationToolbar"];
}

- (void)doUndo: (UIBarButtonSystemItem*)barButton {
    // Stub to be filled in later
}

- (void)setButtonForTool: (PTTool*)tool {
	PTAnnotBarButton buttonToSelect = -1;
	
	
    if ([tool isKindOfClass:[PTPanTool class]]) {
        buttonToSelect = PTAnnotBarButtonPan;
    } else if ([tool isKindOfClass:[PTRectangleCreate class]]) {
		buttonToSelect = PTAnnotBarButtonRectangle;
    } else if ([tool isKindOfClass:[PTFreeHandCreate class]]) {
        if ([tool isKindOfClass:[PTFreeHandHighlightCreate class]]) {
            buttonToSelect = PTAnnotBarButtonFreehandHighlight;
        } else {
            buttonToSelect = PTAnnotBarButtonFreehand;
        }
    } else if ([tool isKindOfClass:[PTStickyNoteCreate class]]) {
         buttonToSelect = PTAnnotBarButtonStickynote;
    } else if ([tool isKindOfClass:[PTTextUnderlineCreate class]] ||
               [tool.defaultClass isSubclassOfClass:[PTTextUnderlineCreate class]]) {
         buttonToSelect = PTAnnotBarButtonUnderline;
    } else if ([tool isKindOfClass:[PTTextSquigglyCreate class]] ||
               [tool.defaultClass isSubclassOfClass:[PTTextSquigglyCreate class]]) {
        buttonToSelect = PTAnnotBarButtonSquiggly;
    } else if ([tool isKindOfClass:[PTTextStrikeoutCreate class]] ||
               [tool.defaultClass isSubclassOfClass:[PTTextStrikeoutCreate class]]) {
         buttonToSelect = PTAnnotBarButtonStrikeout;
    } else if ([tool isKindOfClass:[PTTextHighlightCreate class]] ||
               [tool.defaultClass isSubclassOfClass:[PTTextHighlightCreate class]]) {
         buttonToSelect = PTAnnotBarButtonHighlight;
    } else if ([tool isKindOfClass:[PTFreeTextCreate class]]) {
        if ([tool isKindOfClass:[PTCalloutCreate class]]) {
            buttonToSelect = PTAnnotBarButtonCallout;
        } else {
            buttonToSelect = PTAnnotBarButtonFreetext;
        }
	} else if ([tool isKindOfClass:[PTDigitalSignatureTool class]]) {
         buttonToSelect = PTAnnotBarButtonSignature;
	} else if ([tool isKindOfClass:[PTEraser class]]) {
		buttonToSelect = PTAnnotBarButtonEraser;
    } else if ([tool isKindOfClass:[PTArrowCreate class]]) {
        buttonToSelect = PTAnnotBarButtonArrow;
    } else if ([tool isKindOfClass:[PTLineCreate class]]) {
        if ([tool isKindOfClass:[PTRulerCreate class]]) {
            buttonToSelect = PTAnnotBarButtonRuler;
        } else {
            buttonToSelect = PTAnnotBarButtonLine;
        }
    } else if ([tool isKindOfClass:[PTCloudCreate class]]) {
        buttonToSelect = PTAnnotBarButtonCloud;
    } else if ([tool isKindOfClass:[PTPolygonCreate class]]) {
        if ([tool isKindOfClass:[PTAreaCreate class]]) {
            buttonToSelect = PTAnnotBarButtonArea;
        } else {
         buttonToSelect = PTAnnotBarButtonPolygon;
        }
    } else if ([tool isKindOfClass:[PTPolylineCreate class]]) {
        if ([tool isKindOfClass:[PTPerimeterCreate class]]) {
            buttonToSelect = PTAnnotBarButtonPerimeter;
        } else {
            buttonToSelect = PTAnnotBarButtonPolyline;
        }
	} else if ([tool isKindOfClass:[PTEllipseCreate class]]) {
		buttonToSelect = PTAnnotBarButtonEllipse;
    } else {
		if ([tool.defaultClass isSubclassOfClass:[PTPanTool class]]) {
			buttonToSelect = PTAnnotBarButtonPan;
		}
	}
	
	for (UIBarButtonItem* barButton in self.items) {
		if ([barButton.customView isMemberOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)barButton.customView;
            
            if (button.tag == buttonToSelect) {
                if (button.selected == NO ) {
                    [self toggleButton:button andSetTool:NO];
                }
                break;
            } else if (buttonToSelect == PTAnnotBarButtonPan) {
                // Manually unselect buttons when switching back to the pan tool.
                // Fixes an issue where the old tool button would stay selected if the pan tool
                // button is missing.
                [self setButton:button selected:NO];
            }
		}
	}
    
    // Show edit toolbar if necessary.
    if ([tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)tool;
        BOOL isFreehandTool = NO;
        BOOL isPencilTool = NO;
        if ([self.toolManager freehandUsesPencilKit]) {
            if (@available(iOS 13.1, *) ) {
                isPencilTool = [tool isKindOfClass:[PTPencilDrawingCreate class]];
            }
        } else {
            if ([tool isKindOfClass:[PTFreeHandCreate class]]) {
                isFreehandTool = ![tool isKindOfClass:[PTFreeHandHighlightCreate class]];
            }
        }

        if ((createTool.requiresEditSupport || isFreehandTool || isPencilTool)
            && self.editToolbar.hidden) {
            if (!isPencilTool) {
                [self addEditToolbar];
            }else if (!tool.backToPanToolAfterUse){
                [self addEditToolbar];
            }
        }
        else if (!(createTool.requiresEditSupport || isFreehandTool || isPencilTool))
        {
//            [self dismissEditToolbarAndCommit:YES];
            self.editToolbarOnscreenConstraint.active = NO;
            self.editToolbarOffscreenConstraint.active = YES;
            self.editToolbar.hidden = YES;
            self.editToolbar.alpha = 0.0;
        }

        if (@available(iOS 13.1, *) ) {
            self.editToolbar.styleButtonHidden = [createTool isKindOfClass:[PTPencilDrawingCreate class]];
        }
        else
        {
            self.editToolbar.styleButtonHidden = NO;
        }

        
        if (![createTool isKindOfClass:[PTFreeHandCreate class]]
            && ![createTool isKindOfClass:[PTPolylineCreate class]]
            && !isPencilTool) {
            self.editToolbar.undoRedoHidden = YES;
        } else {
            self.editToolbar.undoRedoHidden = NO;
            if (isPencilTool) {
                // Only show our own undo/redo buttons in compact size classes as PencilKit's are visible otherwise
                self.editToolbar.undoRedoHidden = !(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact || self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact);
            }
            // Start observing undo notifications.
            if ([createTool isKindOfClass:[PTPolylineCreate class]] || isPencilTool) {
                [NSNotificationCenter.defaultCenter addObserver:self
                                                       selector:@selector(undoManagerStateDidChangeWithNotification:)
                                                           name:NSUndoManagerDidCloseUndoGroupNotification
                                                         object:createTool.undoManager];
                
                [NSNotificationCenter.defaultCenter addObserver:self
                                                       selector:@selector(undoManagerStateDidChangeWithNotification:)
                                                           name:NSUndoManagerDidUndoChangeNotification
                                                         object:createTool.undoManager];
                
                [NSNotificationCenter.defaultCenter addObserver:self
                                                       selector:@selector(undoManagerStateDidChangeWithNotification:)
                                                           name:NSUndoManagerDidRedoChangeNotification
                                                         object:createTool.undoManager];
                
                [self updateEditToolbarWithUndoManager:createTool.undoManager];
            }
        }
    }
    else
    {
        if (!self.editToolbar.hidden && self.hidesWithEditToolbar) {
            if ([self.delegate respondsToSelector:@selector(annotationToolbarDidCancel:)]) {
                [self.delegate annotationToolbarDidCancel:self];
            }
        }
        
        self.editToolbarOnscreenConstraint.active = NO;
        self.editToolbarOffscreenConstraint.active = YES;
        self.editToolbar.hidden = YES;
        self.editToolbar.alpha = 0.0;
        
        // Stop observing undo notifications.
        [NSNotificationCenter.defaultCenter removeObserver:self name:NSUndoManagerDidCloseUndoGroupNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:NSUndoManagerDidUndoChangeNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:NSUndoManagerDidRedoChangeNotification object:nil];
    }
}

-(void)addEditToolbar
{
    [self layoutIfNeeded];
    
    self.editToolbarOffscreenConstraint.active = NO;
    self.editToolbarOnscreenConstraint.active = YES;
    
    self.editToolbar.alpha = 0.0;
    self.editToolbar.hidden = NO;
    
    [UIView animateWithDuration:0.2f animations:^(void) {
        [self layoutIfNeeded];
        
        self.editToolbar.alpha = 1.0;
        
        [self bringSubviewToFront:self.editToolbar];
    } completion:^(BOOL finished) {
        
    }];
}

-(void)dismissEditToolbarAndCommit:(BOOL)commit
{
    if (commit) {
        
        if ([self.toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
            [self.toolManager.tool performSelector:@selector(commitAnnotation)];
        }
    }else{
        if ([self.toolManager.tool respondsToSelector:@selector(cancelEditingAnnotation)]) {
            [self.toolManager.tool performSelector:@selector(cancelEditingAnnotation)];
        }

    }
    
    [self layoutIfNeeded];
    
    if (self.hidesWithEditToolbar) {
        if ([self.delegate respondsToSelector:@selector(annotationToolbarDidCancel:)]) {
            [self.delegate annotationToolbarDidCancel:self];
        }
    }
    
    self.editToolbarOnscreenConstraint.active = NO;
    self.editToolbarOffscreenConstraint.active = YES;
    
    [UIView animateWithDuration:0.2f animations:^(void) {
        [self layoutIfNeeded];
        
        self.editToolbar.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.editToolbar.hidden = YES;
        self.editToolbar.alpha = 1.0;
        
        self.editToolbar.undoEnabled = NO;
        self.editToolbar.redoEnabled = NO;
        
        [self.toolManager changeTool:[PTPanTool class]];
    }];
}

-(void)toggleStylePicker:(id)sender
{
        PTAnnotStyle *annotStyle = [[PTAnnotStyle allocOverridden] initWithAnnotType:_toolAnnotType];
        
        if(self.stylePicker.presentingViewController == nil){
            self.stylePicker = [[PTAnnotStyleViewController allocOverridden] initWithToolManager:self.toolManager annotStyle:annotStyle];
            self.stylePicker.delegate = self;
            
            CGRect anchorRect = CGRectZero;
            UIView *anchorView = [[UIView alloc] init];
            if ([sender isKindOfClass:[UIBarButtonItem class]]) {
                UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
                UIView *view = [barButtonItem valueForKey:@"view"];
                anchorRect = view.bounds;
                anchorView = view;
            }else if ([sender isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)sender;
                anchorRect = button.bounds;
                anchorView = button;
            }
            
            PTPopoverNavigationController *navigationController = [[PTPopoverNavigationController allocOverridden] initWithRootViewController:self.stylePicker];
            
            navigationController.presentationManager.popoverSourceView = anchorView;
            navigationController.presentationManager.popoverSourceRect = anchorRect;
                        
            UIViewController *viewController = [self pt_viewController];
            [viewController presentViewController:navigationController animated:YES completion:nil];
        }else{
            [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
            self.stylePicker = nil;
        }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        // Update button appearance after UIAppearance is applied.
        [self updateButtonAppearances];
    }
}

#pragma mark - Appearance

- (UIColor *)selectedTintColor
{
    if (self.barTintColor) {
        // Remove alpha from color.
        return [self.barTintColor colorWithAlphaComponent:1.0];
    }
    
    if (self.barStyle == UIBarStyleDefault) {
        return UIColor.whiteColor;
    } else {
        UIColor *color = UIColor.blackColor;
        if ([self isTranslucent]) {
            return [color colorWithAlphaComponent:0.85];
        }
        return color;
    }
}

- (void)setBarTintColor:(UIColor *)barTintColor
{
    [super setBarTintColor:barTintColor];
    
    // Update all buttons for new bar tint color.
    [self updateButtonAppearances];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    // Update all buttons for new tint color.
    [self updateButtonAppearances];
}

- (void)setTranslucent:(BOOL)translucent
{
    [super setTranslucent:translucent];
    
    // Update all buttons for translucency.
    [self updateButtonAppearances];
}

- (void)updateButtonAppearances
{
    // Update appearance of all buttons.
    for (UIBarButtonItem *item in self.items) {
        if ([item.customView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)item.customView;

            BOOL editable = NO;
            switch (button.tag) {
                case PTAnnotBarButtonHighlight:
                case PTAnnotBarButtonStrikeout:
                case PTAnnotBarButtonUnderline:
                case PTAnnotBarButtonSquiggly:
                case PTAnnotBarButtonFreetext:
                case PTAnnotBarButtonArrow:
                case PTAnnotBarButtonLine:
                case PTAnnotBarButtonRectangle:
                case PTAnnotBarButtonEllipse:
                case PTAnnotBarButtonRuler:
                case PTAnnotBarButtonPerimeter:
                case PTAnnotBarButtonArea:
                    editable = YES;
                    break;
                default:
                    break;
            }
            if(editable && !CGSizeEqualToSize(button.frame.size, CGSizeZero)){
                if(self.editToolbar.hidden){
                    [button setBackgroundImage:[self stylePickerDisclosureImageFromRect:button.frame] forState:UIControlStateSelected];
                }
            }

            [self setButton:button selected:button.selected];
        }
    }
}

-(UIImage*)stylePickerDisclosureImageFromRect:(CGRect)rect
{
    if (CGRectGetWidth(rect) == 0 || CGRectGetHeight(rect) == 0) {
        return nil;
    }
    
    UIBezierPath *triangle = [UIBezierPath bezierPath];
    [triangle moveToPoint:CGPointMake(rect.size.width-3, rect.size.height-3)];
    [triangle addLineToPoint:CGPointMake(rect.size.width-9, rect.size.height-3)];
    [triangle addLineToPoint:CGPointMake(rect.size.width-3, rect.size.height-9)];
    [triangle closePath];

    CAShapeLayer *bgLayer = [CAShapeLayer layer];
    bgLayer.path = triangle.CGPath;
    [bgLayer setFillColor:self.selectedTintColor.CGColor];
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    [bgLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

#pragma mark - FreeHandCreate Delegate

-(void)strokeAdded:(PTFreeHandCreate*)freeHandCreate
{
    self.editToolbar.undoEnabled = YES;
    self.editToolbar.redoEnabled = NO;
}

#pragma mark - PTEditToolbar Delegate

- (void)editToolbarDidCancel:(PTEditToolbar *)editToolbar
{
    [self dismissEditToolbarAndCommit:NO];
}

- (void)editToolbarDidCommit:(PTEditToolbar *)editToolbar
{
    [self dismissEditToolbarAndCommit:YES];
}

- (void)editToolbarUndoChange:(PTEditToolbar *)editToolbar
{
    if ([self.toolManager.tool isKindOfClass:[PTFreeHandCreate class]]) {
        PTFreeHandCreate *freehandCreate = (PTFreeHandCreate *)(self.toolManager.tool);
        
        [freehandCreate undoStroke];
        
        [self updateEditToolbarForFreeHandCreate:freehandCreate];
    }
    
    if ([self.toolManager.tool isKindOfClass:[PTPolylineCreate class]]) {
        [self.toolManager.tool.undoManager undo];
    }
    if ([self.toolManager freehandUsesPencilKit]) {
        if (@available(iOS 13.1, *) ) {
            if ([self.toolManager.tool isKindOfClass:[PTPencilDrawingCreate class]]) {
                [self.toolManager.tool.undoManager undo];
            }
        }
    }
}

- (void)editToolbarRedoChange:(PTEditToolbar *)editToolbar
{
    if ([self.toolManager.tool isKindOfClass:[PTFreeHandCreate class]]) {
        PTFreeHandCreate *freehandCreate = (PTFreeHandCreate *)(self.toolManager.tool);
        
        [freehandCreate redoStroke];
        
        [self updateEditToolbarForFreeHandCreate:freehandCreate];
    }
    
    if ([self.toolManager.tool isKindOfClass:[PTPolylineCreate class]]) {
        [self.toolManager.tool.undoManager redo];
    }
    if ([self.toolManager freehandUsesPencilKit]) {
        if (@available(iOS 13.1, *) ) {
            if ([self.toolManager.tool isKindOfClass:[PTPencilDrawingCreate class]]) {
                [self.toolManager.tool.undoManager redo];
            }
        }
    }
}

- (void)updateEditToolbarForFreeHandCreate:(PTFreeHandCreate *)freehandCreate
{
    self.editToolbar.undoEnabled = [freehandCreate canUndoStroke];
    self.editToolbar.redoEnabled = [freehandCreate canRedoStroke];
}

- (void)updateEditToolbarWithUndoManager:(NSUndoManager *)undoManager
{
    self.editToolbar.undoEnabled = undoManager.canUndo;
    self.editToolbar.redoEnabled = undoManager.canRedo;
}

- (void)editToolbarToggleStylePicker:(UIBarButtonItem *)button
{
    PTTool *tool = self.toolManager.tool;
    
    _toolAnnotType = tool.annotType;
    
    // If the tool can have its style modified, show the style picker
    if ( tool.canEditStyle ){
        [self toggleStylePicker:button];
    } else if( self.stylePicker ){
        [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
        self.stylePicker = nil;
    }
}

// PTEditToolbar positioning.
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

#pragma mark - AnnotationStyleViewController Delegate

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didCommitStyle:(PTAnnotStyle *)annotStyle
{
    [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
    self.stylePicker = nil;
}

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didChangeStyle:(PTAnnotStyle *)annotStyle
{
    [annotStyle setCurrentValuesAsDefaults];
    
    // Refresh create-tool with new appearance.
    if ([self.toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        [self.toolManager.tool setNeedsDisplay];
    }
}

#pragma mark - PTToolManagerAnnotationOptionsDidChangeNotification

- (void)toolManagerToolDidChangeNotification:(NSNotification *)notification
{
    PTToolManager *toolManager = (PTToolManager *)notification.object;
    if (self.toolManager != toolManager) {
        return;
    }
    
    PTTool *tool = toolManager.tool;
    if (![tool isKindOfClass:[PTTool class]]) {
        return;
    }

    [self setButtonForTool:((PTTool *)tool)];
}

- (void)toolManagerAnnotationOptionsDidChangeNotification:(NSNotification *)notification
{
    PTToolManager *toolManager = (PTToolManager *)notification.object;
    if (self.toolManager != toolManager) {
        return;
    }
    
    [self resetButtonItems];
}

#pragma mark - NSUndoManager notifications

- (void)undoManagerStateDidChangeWithNotification:(NSNotification *)notification
{
    NSUndoManager *undoManager = (NSUndoManager *)notification.object;
    
    BOOL isPencilTool = NO;
    if ([self.toolManager freehandUsesPencilKit]) {
        if (@available(iOS 13.1, *) ) {
            isPencilTool = [self.toolManager.tool isKindOfClass:[PTPencilDrawingCreate class]];
        }
    }

    if (![self.toolManager.tool isKindOfClass:[PTPolylineCreate class]] && !isPencilTool) {
        return;
    }
    
    [self updateEditToolbarWithUndoManager:undoManager];
}

@end
