//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDigitalSignatureTool.h"

#import "PTAnnotEditTool.h"
#import "PTPanTool.h"
#import "PTDigSigViewController.h"
#import "PTFloatingSigViewController.h"
#import "PTDigSigView.h"
#import "PTSignaturesManager.h"
#import "PTToolsUtil.h"
#import "PTColorDefaults.h"
#import "PTSavedSignaturesViewController.h"

#import "UIView+PTAdditions.h"

#include <tgmath.h>

@interface PTSavedSignaturesViewControllerState : NSObject

@property (nonatomic, assign) BOOL showOneTimeSignatureOnPresentation;

+(PTSavedSignaturesViewControllerState *)sharedState;

@end

@implementation PTSavedSignaturesViewControllerState

static PTSavedSignaturesViewControllerState *PTSavedSignaturesViewControllerState_singleton;

+ (PTSavedSignaturesViewControllerState *)sharedState
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PTSavedSignaturesViewControllerState_singleton = [[PTSavedSignaturesViewControllerState alloc] init];
    });
    
    return PTSavedSignaturesViewControllerState_singleton;
}

@end

typedef NS_ENUM(NSInteger, PTDigitalSignatureState) {
    PTDigitalSignatureStateEmpty,
    PTDigitalSignatureStateDigitallySigned,
    PTDigitalSignatureStatePathAppearanceOnly,
    PTDigitalSignatureStateImageAppearanceOnly,
};

typedef NS_ENUM(NSInteger, PTDigitalSignatureToolMode) {
    PTDigitalSignatureToolModeDigital,
    PTDigitalSignatureToolModeFloating,
};

@interface PTDigitalSignatureTool ()<PTSavedSignaturesViewControllerDelegate>
{
	CGRect m_MenuFrame;
	BOOL m_exiting;
	BOOL m_firstTap;
    BOOL m_dragging;
}

@property (nonatomic, assign) PTDigitalSignatureToolMode toolMode;

@property (nonatomic, strong) PTDigSigViewController *digSigViewController;
@property (nonatomic, strong) PTFloatingSigViewController *floatingSigViewController;

@property (nonatomic, strong) PTSignaturesManager *signaturesManager;

@property (nonatomic, strong) UINavigationController* savedSigsNavController;

@property (nonatomic, assign) CGFloat strokeThickness;
@property (nonatomic, strong) UIColor* strokeColor;
@property (nonatomic, assign) BOOL allowDigitalSigning;

@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTDigitalSignatureTool

-(instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)in_pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        // Initialization code
        self.strokeColor = UIColor.blackColor;
        self.strokeThickness = 2.0;
        
        _toolMode = PTDigitalSignatureToolModeDigital;
        self.allowDigitalSigning = NO;
        m_exiting = NO;
        
        _showsSavedSignatures = NO;
        
    }
    return self;
}

-(void)dealloc
{
    
    if (_digSigViewController) {
        [_digSigViewController dismissViewControllerAnimated:YES completion:nil];
    }
    if (_floatingSigViewController) {
        [_floatingSigViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
}

+(BOOL)createsAnnotation
{
	return YES;
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeSignature;
}

-(void)setCurrentAnnotation:(PTAnnot*)annotation
{
    [super setCurrentAnnotation:annotation];
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    NSString* message;
    if( [userData isKindOfClass:[NSString class]] )
    {
        message = (NSString*)userData;
    }
    
	if( m_exiting || ([message isEqualToString:@"CloseAnnotationToolbar"]))
	{
        if (self.digSigViewController) {
            [self.digSigViewController dismissViewControllerAnimated:YES completion:nil];
        }
        if (self.floatingSigViewController) {
            [self.floatingSigViewController dismissViewControllerAnimated:YES completion:nil];
        }
        
		return NO; // finished creating signature
	}
	else
	{
        NSError* error;
        __block BOOL annotIsLocked = NO;
        
        BOOL ranBlock = [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
            
            annotIsLocked = [self.currentAnnotation GetFlag:e_ptlocked];

        } error:&error];
        
        NSAssert(!error, @"Locking error");
        
        if( ranBlock && annotIsLocked )
        {
            return NO;
        }
        
        if (userData && [userData isEqual:[PTDigitalSignatureTool class]]
            && self.currentAnnotation) {
            
            [self showFloatingSignatureViewController];

        }
        else if( self.showsSavedSignatures == false)
        {
            [self showSignatureList];
        }
        else
        {
            m_MenuFrame = CGRectMake(self.longPressPoint.x, self.longPressPoint.y, 1, 1);
            [self attachMenuItems];
        }
	   return YES; // just opening this tool from pantool
	}
}

- (void)setShowDefaultSignature:(BOOL)showDefaultSignature
{
    self.showsSavedSignatures = showDefaultSignature;
}

- (BOOL)showDefaultSignature
{
    return self.showsSavedSignatures;
}

-(void)setShowsSavedSignatures:(BOOL)showsSavedSignatures
{
    
    if (_showsSavedSignatures == showsSavedSignatures) {
        return;
    }
    
    _showsSavedSignatures = showsSavedSignatures;
    
    // Update floating signature view controller.
    self.floatingSigViewController.showDefaultSignature = showsSavedSignatures;
}

-(PTElement *)getFirstElementUsingReader:(PTElementReader *)reader fromObj:(PTObj *)obj ofType:(PTElementType)type
{
	@try
	{
		[self.pdfViewCtrl DocLockRead];
        
        if (![obj IsValid]) {
            return nil;
        }

        [reader ReaderBeginWithSDFObj:obj resource_dict:nil ocg_context:nil];
        
        for( PTElement* element = [reader Next]; element != 0; element = [reader Next] )
        {
            if( [element GetType] == type )
            {
                return element;
            }
        }
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@", exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlockRead];
	}

	return nil;
}

-(PTDigitalSignatureState)signatureState
{
	@try {
		[self.pdfViewCtrl DocLockRead];

        PTWidget *widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
		PTField *field = [widget GetField];
        
        if( [field GetType] != e_ptsignature )
        {
            return -1;
        }
        
        PTDigitalSignatureField* digSigField = [[PTDigitalSignatureField alloc] initWithIn_field:field];
        
		
		if ( [digSigField HasCryptographicSignature] )
		{
			return PTDigitalSignatureStateDigitallySigned;
		}
        
        if( [digSigField HasVisibleAppearance] == NO )
        {
            return PTDigitalSignatureStateEmpty;
        }
        
		PTObj *appearance = [self.currentAnnotation GetAppearance:e_ptnormal app_state:0];
		
		PTElementReader *reader = [[PTElementReader alloc] init];
        
		// when the element reader is destroyed so is the element that it returned. It is therefore important
		// important to keep the reader alive until finished with the element
		PTElement *element = [self getFirstElementUsingReader:reader fromObj:appearance ofType:e_ptform];
		
		PTObj* xobj = [element GetXObject];
		
        if( [xobj IsValid] )
        {
        
            PTElementReader* objReader = [[PTElementReader alloc] init];
            
            [objReader ReaderBeginWithSDFObj:xobj resource_dict:nil ocg_context:nil];
            
            for(PTElement* el = [objReader Next]; el != 0; el = [objReader Next])
            {
                if( [el GetType] == e_ptpath )
                {
                    return PTDigitalSignatureStatePathAppearanceOnly;
                }
                if( [el GetType] == e_ptimage )
                {
                    return PTDigitalSignatureStateImageAppearanceOnly;
                }
            }
        }

	}
	@catch (NSException *exception) {
		
		NSLog(@"Exception: %@: %@", exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlockRead];
	}
	
	return PTDigitalSignatureStateEmpty;
}

-(void)attachMenuItems
{
	NSMutableArray<UIMenuItem *> *menuItems = [[NSMutableArray alloc] initWithCapacity:2];
	
	self.signaturesManager = [[PTSignaturesManager allocOverridden] init];
	
    // add menu items common to all annotations EXCEPT movies
	
    UIMenuItem* menuItem;
	
	PTDigitalSignatureState state = PTDigitalSignatureStateEmpty;
	
    if( self.currentAnnotation ) {
		state = [self signatureState];
    } else {
		state = PTDigitalSignatureStateEmpty;
    }
    
	if( !self.currentAnnotation || self.toolMode == PTDigitalSignatureToolModeFloating )
	{
        [self showSignatureList];

		return;
	}

	if( state == PTDigitalSignatureStateEmpty )
	{
		// pop up the signature dialog right away
		if( self.toolMode == PTDigitalSignatureToolModeFloating )
		{
			[self showFloatingSignatureViewController];
		}
		else if( self.toolMode == PTDigitalSignatureToolModeDigital )
		{
            [self showSignatureList];
            //[self showFloatingSignatureViewController];
			//[self showDigitalSignatureViewController];
		}
	}	
	else if( state == PTDigitalSignatureStatePathAppearanceOnly )
	{
		
		if( self.toolMode == PTDigitalSignatureToolModeFloating )
		{
			menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Delete", @"") action:@selector(deleteAppearance)];
			[menuItems addObject:menuItem];
			menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Thickness", @"") action:@selector(attachBorderThicknessMenuItems)];
			[menuItems addObject:menuItem];
		}
		else if( self.toolMode == PTDigitalSignatureToolModeDigital )
		{
			menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Thickness", @"") action:@selector(attachBorderThicknessMenuItems)];
			[menuItems addObject:menuItem];
			//menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Color", @"") action:@selector(showColorPicker)];
			//[menuItems addObject:menuItem];
            if( self.allowDigitalSigning )
            {
                menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Digitally Sign", @"Sign the document with a cryptographic certificate.") action:@selector(signAndSave)];
                [menuItems addObject:menuItem];
            }
			menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Delete", @"") action:@selector(deleteAppearance)];
			[menuItems addObject:menuItem];
		}
	}
	else if( state == PTDigitalSignatureStateDigitallySigned )
	{
		menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Digital Signature Information", @"Displays the digital signature's certificate information.") action:@selector(showSignatureInfo)];
		[menuItems addObject:menuItem];
	}
	else if( state == PTDigitalSignatureStateImageAppearanceOnly )
	{
		if( self.toolMode == PTDigitalSignatureToolModeDigital  && self.allowDigitalSigning )
		{
            menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Digitally Sign", @"Sign the document with a cryptographic certificate.") action:@selector(signAndSave)];
			[menuItems addObject:menuItem];
		}

		menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Delete", @"") action:@selector(deleteAppearance)];
		[menuItems addObject:menuItem];
	}
	
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    
    theMenu.menuItems = menuItems;
    
}

-(void)showSelectionMenu:(CGRect)targetRect
{
	[super showSelectionMenu:targetRect];
	
	UIMenuController *theMenu = [UIMenuController sharedMenuController];
	
	m_MenuFrame = theMenu.menuFrame;
}

-(void)showSelectionMenu:(CGRect)targetRect animated:(BOOL)animated
{
	[super showSelectionMenu:targetRect animated:animated];
	
	UIMenuController *theMenu = [UIMenuController sharedMenuController];
	
	m_MenuFrame = theMenu.menuFrame;
}

- (NSMutableArray<NSValue *> *)extractPointsFromPathData:(PTPathData *)pathData
{
    if (!pathData) {
        return nil;
    }
    
    NSMutableArray<NSValue *> *outputPoints = [NSMutableArray array];
    
    NSMutableArray<NSNumber *> *data = [pathData GetPoints];
    NSData *opr = [pathData GetOperators];
    
    NSUInteger opr_end = opr.length;
    NSUInteger data_index = 0;

    double x1, y1, /*x2, y2,*/ x3, y3;

    unsigned char* opr_data = (unsigned char*)opr.bytes;
    for (NSUInteger opr_index = 0; opr_index < opr_end; opr_index = opr_index + 1)
    {
        switch(opr_data[opr_index])
        {
            case e_ptmoveto:
                x1 = [data[data_index] doubleValue]; ++data_index;
                y1 = [data[data_index] doubleValue]; ++data_index;
                
                [outputPoints addObject:@(CGPointMake(x1, y1))];
                break;
            case e_ptlineto:
                x1 = [data[data_index] doubleValue]; ++data_index;
                y1 = [data[data_index] doubleValue]; ++data_index;
                
                [outputPoints addObject:@(CGPointMake(x1, y1))];
                break;
            case e_ptcubicto:
                //x1 = [data[data_index] doubleValue]; ++data_index;
                //y1 = [data[data_index] doubleValue]; ++data_index;
                //x2 = [data[data_index] doubleValue]; ++data_index;
                //y2 = [data[data_index] doubleValue]; ++data_index;
                x3 = [data[data_index] doubleValue]; ++data_index;
                y3 = [data[data_index] doubleValue]; ++data_index;
                
                [outputPoints addObject:@(CGPointMake(x3, y3))];
                break;
            case e_ptrect:
            case e_ptclosepath:
            default:
                break;
        }
    }

    return outputPoints;
}

- (void)extractSignaturePath
{
    PTAnnot *annot = self.currentAnnotation;
    if (!annot) {
        return;
    }
    
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        if (![annot IsValid]) {
            return;
        }
        
        if (annot.extendedAnnotType != PTExtendedAnnotTypeSignature) {
            return;
        }
        
        // NOTE: The path elements are down inside two levels of e_ptform elements.
        
        PTObj *appearance = [annot GetAppearance:e_ptnormal app_state:0];
        PTElementReader *reader = [[PTElementReader alloc] init];
        PTElement *element = [self getFirstElementUsingReader:reader fromObj:appearance ofType:e_ptform];
        if (element) {
            PTObj* xobj = [element GetXObject];
            PTElementReader* reader2 = [[PTElementReader alloc] init];
            element = [self getFirstElementUsingReader:reader2 fromObj:xobj ofType:e_ptform];
            
            if( element != nil ) {
                PTObj* xobj = [element GetXObject];
                
                NSMutableArray<NSValue *> *allPoints = [NSMutableArray array];
                CGRect boundingRect = CGRectZero;

                // Go over all the path elements in the object.
                PTElementReader* reader2 = [[PTElementReader alloc] init];
                [reader2 ReaderBeginWithSDFObj:xobj resource_dict:nil ocg_context:nil];
                
                for (PTElement *element2 = [reader2 Next]; element2 != 0; element2 = [reader2 Next]) {
                    if ([element2 GetType] == e_ptpath) {
                        PTPathData *pathData = [element2 GetPathData];
                        // Extract the path data end points (ignore control points).
                        NSMutableArray<NSValue *> *points = [self extractPointsFromPathData:pathData];
                        
                        [allPoints addObjectsFromArray:points];

                        // All strokes end with a zero-point.
                        [allPoints addObject:@(CGPointZero)];
                    }
                }
                
                if (allPoints.count > 0) {
                    
                    CGPoint minPoint = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
                    CGPoint maxPoint = CGPointMake(CGFLOAT_MIN, CGFLOAT_MIN);
                    
                    for (NSValue *value in allPoints) {
                        CGPoint point = value.CGPointValue;
                        if (CGPointEqualToPoint(point, CGPointZero)) {
                            continue;
                        }
                        
                        if (point.x < minPoint.x) {
                            minPoint.x = point.x;
                        }
                        if (point.y < minPoint.y) {
                            minPoint.y = point.y;
                        }
                        if (point.x > maxPoint.x) {
                            maxPoint.x = point.x;
                        }
                        if (point.y > maxPoint.y) {
                            maxPoint.y = point.y;
                        }
                    }
                    
                    if (minPoint.x < CGFLOAT_MAX && minPoint.y < CGFLOAT_MAX &&
                        maxPoint.x > CGFLOAT_MIN && maxPoint.y > CGFLOAT_MIN) {
                        
                        NSMutableArray<NSValue *> *flippedPoints = [NSMutableArray arrayWithCapacity:allPoints.count];

                        for (NSValue *value in allPoints) {
                            CGPoint point = value.CGPointValue;
                            if (CGPointEqualToPoint(point, CGPointZero)) {
                                [flippedPoints addObject:value];
                                continue;
                            }
                            
                            point.y = maxPoint.y - point.y;
                            
                            [flippedPoints addObject:@(point)];
                        }
                        
                        allPoints = flippedPoints;
                        
                        boundingRect = CGRectMake(minPoint.x, minPoint.y,
                                                  (maxPoint.x - minPoint.x), (maxPoint.y - minPoint.y));
                    }
                }
                
                self.floatingSigViewController.digSigView.points = allPoints;
                self.floatingSigViewController.digSigView.boundingRect = boundingRect;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
}

-(void)savedSignaturesControllerNewSignature:(PTSavedSignaturesViewController*)savedSignaturesController
{
    PTSavedSignaturesViewControllerState.sharedState.showOneTimeSignatureOnPresentation = NO;
    
    [self showFloatingSignatureViewController:YES];

}

-(void)savedSignaturesControllerOneTimeSignature:(PTSavedSignaturesViewController*)savedSignaturesController
{
    PTSavedSignaturesViewControllerState.sharedState.showOneTimeSignatureOnPresentation = YES;

    [self showFloatingSignatureViewController:NO];

}

-(void)savedSignaturesControllerWasDismissed:(PTSavedSignaturesViewController*)savedSignaturesController
{
    PTSavedSignaturesViewControllerState.sharedState.showOneTimeSignatureOnPresentation = NO;
    self.nextToolType = self.defaultClass;
    m_exiting = YES;
    [self.toolManager createSwitchToolEvent:nil];
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController{
    self.nextToolType = self.defaultClass;
    m_exiting = YES;
    [self.toolManager createSwitchToolEvent:nil];
}

// for backward compatibility
-(void)showFloatingSignatureViewController
{
    [self showFloatingSignatureViewController:YES];
}

// Does not offer to digitally sign, or use a built in image. Can save a new default signature presented to the user as "My Signature"
// Can save the signature anywhere on the document (as opposed to only a signature form field).
-(void)showFloatingSignatureViewController:(BOOL)saveSignatureForReuse
{
	self.floatingSigViewController = [[PTFloatingSigViewController allocOverridden] initWithNibName:nil bundle:nil];
    
    self.floatingSigViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	self.floatingSigViewController.delegate = self;
    self.floatingSigViewController.strokeColor = self.strokeColor;
    self.floatingSigViewController.strokeThickness = self.strokeThickness;
    self.floatingSigViewController.showDefaultSignature = NO;
    self.floatingSigViewController.saveSignatureForReuse = saveSignatureForReuse;
    
    if (self.currentAnnotation
        && [self currentAnnotationType] == PTExtendedAnnotTypeSignature
        && self.toolManager.signatureAnnotationOptions.canEditAppearance) {
        // Try to extract the existing signature data out of the annotation and into the canvas.
        [self extractSignaturePath];
    }
    

    

    if( self.savedSigsNavController )
    {
        [self.savedSigsNavController pushViewController:self.floatingSigViewController animated:YES];
        
    }

    else
    {
        UINavigationController* floatingSigNavController = [[UINavigationController alloc] initWithRootViewController:self.floatingSigViewController];
        
        floatingSigNavController.toolbarHidden = NO;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            floatingSigNavController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        floatingSigNavController.presentationController.delegate = self;
        
        [self.pt_viewController presentViewController:floatingSigNavController animated:YES completion:^{
            [floatingSigNavController.presentationController.presentedView.gestureRecognizers.firstObject setEnabled:NO];
        }];
    }
    
}

-(void)showSignatureList
{
    
    if( self.showsSavedSignatures )
    {
        // Prevent the saved-signatures nav. controller from being presented more than
        // once. When this happens, the old savedSigsNavController reference is lost and
        // the PTFloatingSigViewController cannot be pushed onto the correct nav. controller.
        if (self.savedSigsNavController.presentingViewController) {
            return;
        }
        
        PTSavedSignaturesViewController* savedSigsController = [[PTSavedSignaturesViewController allocOverridden] init];
        savedSigsController.delegate = self;
        self.savedSigsNavController = [[UINavigationController alloc] initWithRootViewController:savedSigsController];
        savedSigsController.title = PTLocalizedString(@"Signatures", @"Signatures for signing a document");
        
        self.savedSigsNavController.presentationController.delegate = self;
        
        if( PTSavedSignaturesViewControllerState.sharedState.showOneTimeSignatureOnPresentation )
        {
            [self showFloatingSignatureViewController:NO];
        }

        
        [self.pt_viewController presentViewController:self.savedSigsNavController animated:YES completion:Nil];
    }
    else
    {
        [self showFloatingSignatureViewController:NO];
    }
}

// Save a signature to a signature form field. Can use a certificate to digitally sign.
-(void)showDigitalSignatureViewController
{
    self.digSigViewController = [[PTDigSigViewController allocOverridden] initWithNibName:nil bundle:nil];
    self.digSigViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	self.digSigViewController.delegate = self;
    self.digSigViewController.strokeColor = self.strokeColor;
    self.digSigViewController.strokeThickness = self.strokeThickness;
    self.digSigViewController.allowDigitalSigning = self.allowDigitalSigning;
    
    UINavigationController* digSigNavController = [[UINavigationController alloc] initWithRootViewController:self.digSigViewController];
    
    digSigNavController.toolbarHidden = NO;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        digSigNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    digSigNavController.presentationController.delegate = self;
    
    [self.pt_viewController presentViewController:digSigNavController animated:YES completion:^{
        [digSigNavController.presentationController.presentedView.gestureRecognizers.firstObject setEnabled:NO];
    }];
}

-(void)stampWidgetWithDoc:(PTPDFDoc*)signatureDoc
{
    [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        
        PTWidget* widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
        [self.toolManager willModifyAnnotation:widget onPageNumber:self.annotationPageNumber];
        [widget SetFlag:e_pthidden value:YES];
        NSString* fieldID = [[widget GetField] GetName];
        [self.pdfViewCtrl UpdateWithAnnot:widget page_num:self.annotationPageNumber];
        [self.toolManager annotationModified:widget onPageNumber:self.annotationPageNumber];
        PTPDFRect* widgetRect = [self.currentAnnotation GetRect];

        PTStamper* stamper = [[PTStamper alloc] initWithSize_type:e_ptabsolute_size a:[widgetRect Width] b:[widgetRect Height]];

        [stamper SetAsAnnotation:YES];

        [stamper SetAlignment:e_pthorizontal_left vertical_alignment:e_ptvertical_bottom];

        [stamper SetPosition:[widgetRect GetX1] vertical_distance:[widgetRect GetY1] use_percentage:NO];

        [stamper StampPage:doc src_page:[signatureDoc GetPage:1] dest_pages:[[PTPageSet alloc] initWithOne_page:self.annotationPageNumber]];

        PTPage* signaturePage = [doc GetPage:self.annotationPageNumber];

        PTAnnot* signatureStamp = [signaturePage GetAnnot:[signaturePage GetNumAnnots]-1];

        PTPDFRect* signatureRect = [signatureStamp GetRect];

        double horizontalShift = ([widgetRect GetX1] + [widgetRect Width]/2) - ([signatureRect GetX1]+[signatureRect Width]/2);

        double verticalShift = ([widgetRect GetY1] + [widgetRect Height]/2) - ([signatureRect GetY1]+[signatureRect Height]/2);

        PTPDFRect* newPos = [[PTPDFRect alloc] initWithX1:[signatureRect GetX1]+horizontalShift
                                                       y1:[signatureRect GetY1]+verticalShift
                                                       x2:[signatureRect GetX2]+horizontalShift
                                                       y2:[signatureRect GetY2]+verticalShift];

        [signatureStamp Resize:newPos];
        
        [signatureStamp SetCustomData:PT_SIGNATURE_FIELD_ID value:fieldID];
        
        [self.toolManager annotationAdded:signatureStamp onPageNumber:self.annotationPageNumber];
        [self.pdfViewCtrl Update:YES];

        // associate this stamp with this field, and set the field to read-only.
        


        [self closeSignatureDialog];
        
    } error:Nil];
}


-(void)addToWidget:(PTPDFDoc*)doc
{
    if( self.toolManager.signatureAnnotationOptions.signSignatureFieldsWithStamps )
    {
        [self stampWidgetWithDoc:doc];
    }
    else
    {
        PTPDFDraw* draw = [[PTPDFDraw alloc] initWithDpi:72];
        
        PTPage* page = [doc GetPage:1];
        
        // First, we need to save the document to the apps sandbox.
        
        NSString* fullFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:@"SignatureTempFile.png"];
        
        PTPDFRect* cropBox = [page GetCropBox];
        int width = [cropBox Width];
        int height = [cropBox Height];

        [draw SetImageSize:width height:height preserve_aspect_ratio:false];

        [draw Export:page filename:fullFileName format:@"png"];

        [self saveAppearanceWithImageFromFilename:fullFileName];
        
        CGPoint sigPoint = CGPointMake(m_MenuFrame.origin.x+m_MenuFrame.size.width/2, m_MenuFrame.origin.y+m_MenuFrame.size.height);
        
        int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:sigPoint.x y:sigPoint.y];
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:pageNumber];
    }
}

-(void)addDefaultStamp
{
	PTPDFDoc* sigDoc = [self.signaturesManager savedSignatureAtIndex:0];
	if( !self.currentAnnotation )
		[self addStamp:sigDoc];
	else
		[self addToWidget:sigDoc];
	m_exiting = YES;
	
	// makes no sense to stay in this tool mode
	self.nextToolType = [PTPanTool class];

	[self.toolManager createSwitchToolEvent:nil];
}

-(void)savedSignaturesController:(PTSavedSignaturesViewController*)signaturesViewController addSignature:(PTPDFDoc*)signatureDoc
{
    if( self.toolManager.signatureAnnotationOptions.signSignatureFieldsWithStamps && self.toolMode == PTDigitalSignatureToolModeDigital && self.currentAnnotation)
    {
        [self stampWidgetWithDoc:signatureDoc];
    }
    else
    {
        PTSavedSignaturesViewControllerState.sharedState.showOneTimeSignatureOnPresentation = NO;
        if( self.toolMode == PTDigitalSignatureToolModeFloating || self.currentAnnotation == Nil)
        {
            [self addStamp:signatureDoc];
        }
        else
        {
            [self addToWidget:signatureDoc];
        }
    }
    
    [self.pt_viewController.presentedViewController dismissViewControllerAnimated:YES completion:Nil];
    
    self.nextToolType = self.defaultClass;
    m_exiting = YES;
    [self.toolManager createSwitchToolEvent:nil];
    
    
}

-(void)addStamp:(PTPDFDoc*)stampDoc
{
	PTPage* stampPage = [stampDoc GetPage:1];
	assert(stampPage);
	
	CGPoint sigPoint;
	
	sigPoint = self.longPressPoint;
	int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:sigPoint.x y:sigPoint.y];
	
	if (pageNumber <= 0)
	{
		// tool was envoked from a toolbar
		pageNumber = [self.pdfViewCtrl GetCurrentPage];
		sigPoint = CGPointMake(self.pdfViewCtrl.frame.size.width/2, self.pdfViewCtrl.frame.size.height/2);
	}
	
	@try
	{
		[self.pdfViewCtrl DocLock:YES];
		PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
		
		
		PTPage* page = [doc GetPage:pageNumber];

		PTPDFRect* stampRect = [stampPage GetCropBox];

		PTPDFRect* pageCropBox = [page GetCropBox];
        
        PTRotate viewRotation = [self.pdfViewCtrl GetRotation];
        PTRotate pageRotation = [page GetRotation];
        
        // If the page itself is rotated, we want to "rotate" width and height as well
        double pageWidth = [pageCropBox Width];
        if (pageRotation == e_pt90 || pageRotation == e_pt270) {
            pageWidth = [pageCropBox Height];
        }
        double pageHeight = [pageCropBox Height];
        if (pageRotation == e_pt90 || pageRotation == e_pt270) {
            pageHeight = [pageCropBox Width];
        }
        
        double maxWidth = 200;
        double maxHeight = 200;
		
		if (pageWidth < maxWidth)
		{
			maxWidth = pageWidth;
		}
		if (pageHeight < maxHeight)
		{
			maxHeight = pageHeight;
		}
		
		double stampWidth = [stampRect Width];
        double stampHeight = [stampRect Height];
        
        // if the viewer rotates pages, we want to treat it as if it's the stamp that's rotated
        if (viewRotation == e_pt90 || viewRotation == e_pt270) {
            double temp = stampWidth;
            stampWidth = stampHeight;
            stampHeight = temp;
        }
        
        double scaleFactor = MIN(maxWidth / stampWidth, maxHeight / stampHeight);
        stampWidth *= scaleFactor;
        stampHeight *= scaleFactor;
        
		PTStamper* stamper = [[PTStamper alloc] initWithSize_type:e_ptabsolute_size a:stampWidth b:stampHeight];
		[stamper SetAlignment:e_pthorizontal_left vertical_alignment:e_ptvertical_bottom];
		[stamper SetAsAnnotation:YES];
		
		CGFloat x = sigPoint.x;
		CGFloat y = sigPoint.y;

		[self ConvertScreenPtToPagePtX:&x Y:&y PageNumber:pageNumber];

        // Account for page rotation in the page-space touch point
        PTMatrix2D *mtx = [page GetDefaultMatrix:NO box_type:e_ptcrop angle:e_pt0];
        PTPDFPoint *sigPointPage = [[PTPDFPoint alloc] initWithPx:x py:y];
        sigPointPage = [mtx Mult:sigPointPage];

        
		double xPos = [sigPointPage getX] - (stampWidth / 2);
		double yPos = [sigPointPage getY] - (stampHeight / 2);

		if (xPos > pageWidth - stampWidth)
		{
			xPos = pageWidth - stampWidth;
		}
		if (xPos < 0)
		{
			xPos = 0;
		}

        if (yPos > pageHeight - stampHeight)
		{
			yPos = pageHeight - stampHeight;
		}
		if (yPos < 0)
		{
			yPos = 0;
		}
		
		[stamper SetPosition:xPos vertical_distance:yPos use_percentage:NO];
        
        int stampRotation = (4 - viewRotation) % 4; // 0 = 0, 90 = 1; 180 = 2, and 270 = 3
        [stamper SetRotation:(stampRotation * 90.0)];
        
		PTPageSet* pageSet = [[PTPageSet alloc] initWithOne_page:pageNumber];
		
		[stamper StampPage:doc src_page:stampPage dest_pages:pageSet];
		
		int numAnnots = [page GetNumAnnots];

		assert(numAnnots > 0);
		
		PTAnnot* annot = [page GetAnnot:numAnnots - 1];
		PTObj* obj = [annot GetSDFObj];
        [obj PutString:PTSignatureAnnotationIdentifier value:@""];
        
		// Set up to transfer to PTAnnotEditTool
		self.currentAnnotation = annot;
		
		self.annotationPageNumber = pageNumber;
		
		[self.pdfViewCtrl UpdateWithAnnot:annot page_num:pageNumber];
		
		self.nextToolType = [PTPanTool class];
		
	}
	@catch (NSException* e)
	{
		NSLog(@"Exception: %@:%@", e.name, e.reason);
	}
	@finally
	{
		[self.pdfViewCtrl DocUnlock];
	}
	
//	mToolManager.CreateTool(mNextToolMode, this);
//	if (mNextToolMode == ToolType.e_annot_edit)
//	{
//		AnnotEdit annotEdit = mToolManager.CurrentTool as AnnotEdit;
//		annotEdit.CreateAppearance();
//	}
	
    [self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];

}

//unused method, left for future reference
-(void)readdStamp:(PTPDFDoc *)stampDoc
{
    if (!self.currentAnnotation || self.annotationPageNumber < 1) {
        return;
    }
    
    PTPage *stampPage = [stampDoc GetPage:1];
    assert(stampPage);
    
    int pageNumber = self.annotationPageNumber;
    
    @try {
        [self.pdfViewCtrl DocLock:YES];
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        PTPage *destPage = [doc GetPage:pageNumber];
        
        PTPDFRect* stampRect = [stampPage GetCropBox];
        double stampWidth = [stampRect Width];
        double stampHeight = [stampRect Height];

        double widgetWidth = [[self.currentAnnotation GetRect]  Width];
        double widgetHeight = [[self.currentAnnotation GetRect] Height];
        
        PTPDFRect *destPageCropBox = [destPage GetCropBox];
        double maxWidth = fmin(widgetWidth, [destPageCropBox Width]);
        double maxHeight = fmin(widgetHeight, [destPageCropBox Height]);
        
        double scaleFactor = MIN(maxWidth / stampWidth, maxHeight / stampHeight);
        stampWidth *= scaleFactor;
        stampHeight *= scaleFactor;
        
        PTStamper* stamper = [[PTStamper alloc] initWithSize_type:e_ptabsolute_size a:stampWidth b:stampHeight];
        [stamper SetAlignment:e_pthorizontal_left vertical_alignment:e_ptvertical_bottom];
        [stamper SetAsAnnotation:YES];
        
        PTPDFRect *annotRect = [self.currentAnnotation GetRect];
        [annotRect Normalize];
        
        CGFloat x = [annotRect GetX2] - ([annotRect GetX2] - [annotRect GetX1]) / 2.0;
        CGFloat y = [annotRect GetY2] - ([annotRect GetY2] - [annotRect GetY1]) / 2.0;
        
        // Account for page rotation in the page-space touch point
        PTMatrix2D *mtx = [destPage GetDefaultMatrix:NO box_type:e_ptcrop angle:0];
        PTPDFPoint *sigPointPage = [[PTPDFPoint alloc] initWithPx:x py:y];
        sigPointPage = [mtx Mult:sigPointPage];
        
        double xPos = [sigPointPage getX] - (stampWidth / 2);
        double yPos = [sigPointPage getY] - (stampHeight / 2);
        
        double destPageWidth = [[destPage GetCropBox] Width];
        if (xPos > destPageWidth - stampWidth)
        {
            xPos = destPageWidth - stampWidth;
        }
        if (xPos < 0)
        {
            xPos = 0;
        }
        double destPageHeight = [[destPage GetCropBox] Height];
        if (yPos > destPageHeight - stampHeight)
        {
            yPos = destPageHeight - stampHeight;
        }
        if (yPos < 0)
        {
            yPos = 0;
        }
        
        [stamper SetPosition:xPos vertical_distance:yPos use_percentage:NO];
        
        PTPageSet* pageSet = [[PTPageSet alloc] initWithOne_page:pageNumber];
        
        PTAnnot* sigStamp = [stampPage GetAnnot:0];
        
        PTInk* inkAnnot = [[PTInk alloc] initWithAnn:sigStamp];
        

        PTPDFRect* inkRectOrg = [inkAnnot GetRect];
        PTPDFRect* inkRectNew = [inkAnnot GetRect];
        
        for(int pathi = 0; pathi < [inkAnnot GetPathCount]; pathi++)
        {
           for(int pointi = 0; pointi < [inkAnnot GetPointCount:pathi]; pointi++)
           {
               PTPDFPoint* point = [inkAnnot GetPoint:pathi pointindex:pointi];

               double x = [point getX];
               double y = [point getY];

               [point setX:x*0.15];
               [point setY:y*0.15];

               [inkAnnot SetPoint:pathi pointindex:pointi pt:point];
           }
        }
        
        [inkAnnot RefreshAppearance];
        
        double xRatio = widgetWidth/[inkRectOrg Width];
        double yRatio = widgetHeight/[inkRectOrg Height];

        [inkRectNew SetX2:[inkRectOrg GetX2]/xRatio];
        [inkRectNew SetY2:[inkRectOrg GetY2]/yRatio];
//
//        double newWidth = [inkRectNew Width];
//        double newHeight = [inkRectNew Height];
//
//        double x1 = widgetWidth/2-[inkRectNew Width]/2;
//        double y1 = widgetHeight/2-[inkRectNew Height]/2;
//
//        [inkRectNew SetX1:x1];
//        [inkRectNew SetY1:y1];
//
//        [inkRectNew SetX2:50+[inkRectNew GetX1]];
//        [inkRectNew SetY2:50+[inkRectNew GetY1]];
        
        double xOffset = widgetWidth/2/xRatio-[inkRectNew Width]/2;
        double yOffset = widgetHeight/2/yRatio-[inkRectNew Height]/2;
        [inkRectNew SetX1:[inkRectNew GetX1]+xOffset];
        [inkRectNew SetY1:[inkRectNew GetY1]+yOffset];
        [inkRectNew SetX2:[inkRectNew GetX2]+xOffset];
        [inkRectNew SetY2:[inkRectNew GetY2]+yOffset];
        
        [inkAnnot SetRect:inkRectNew];
        
    
//        [inkAnnot RefreshAppearance];
//        [inkAnnot RefreshAppearance];
        
//        PTPDFRect* crop = [stampPage GetCropBox];
//        [crop SetX2:[crop GetX2]*2];
//        [stampPage SetCropBox:crop];
        
//        [stampPage AnnotRemoveWithAnnot:sigStamp];
//        [stampPage AnnotPushBack:inkAnnot];
        
        //[sigStamp SetAppearance:[inkAnnot GetAppearance:e_ptnormal app_state:0] annot_state:e_ptnormal app_state:0];
        
        
        // STAMP!
        [stamper StampPage:doc src_page:stampPage dest_pages:pageSet];
        
        // Get the last annotation on the page (which will be the newly stamped annotation).
        int numAnnots = [destPage GetNumAnnots];
        assert(numAnnots > 0);
        PTAnnot* tempStampedAnnot = [destPage GetAnnot:numAnnots - 1];

        // Update the existing annotation's rect with the stamped annotation rect.
        PTPDFRect *bbox = [tempStampedAnnot GetRect];        

        
        [bbox Normalize];
        
        // Get the stamp annotation's appearance and "transfer" to the existing annotation.
        PTObj *appearance = [tempStampedAnnot GetAppearance:e_ptnormal app_state:0];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        [self.currentAnnotation SetAppearance:appearance annot_state:e_ptnormal app_state:0];
        
        // Remove the temporary stamp annotation.
        [destPage AnnotRemoveWithAnnot:tempStampedAnnot];
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:pageNumber];
        
        self.nextToolType = [PTPanTool class];
        
    }
    @catch (NSException* e)
    {
        NSLog(@"Exception: %@:%@", e.name, e.reason);
    }
    @finally
    {
        [self.pdfViewCtrl DocUnlock];
    }
    
    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    
    // leave this tool
    [self.toolManager createSwitchToolEvent:nil];
}


-(void)showSignatureInfo
{

	NSString* info;
	
	@try
	{
		[self.pdfViewCtrl DocLockRead];
		
		PTWidget* widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
		
		PTObj* sigDict = [[widget GetField] GetValue];
		
		if( [sigDict IsValid] )
		{
			NSString* locationWord = PTLocalizedString(@"Location", @"");
			NSString* reasonWord = PTLocalizedString(@"Reason", @"");
			NSString* nameWord = PTLocalizedString(@"Name", @"");
			
			NSString* location = [[sigDict FindObj:@"Location"] GetAsPDFText];
			NSString* reason = [[sigDict FindObj:@"Reason"] GetAsPDFText];
			NSString* name = [[sigDict FindObj:@"Name"] GetAsPDFText];
			info = [NSString stringWithFormat:@"%@: %@\n %@: %@\n %@: %@", locationWord, location, reasonWord, reason, nameWord, name];
		}
		
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlockRead];
	}
	
	if( !info )
	{
		info = PTLocalizedString(@"No Information", @"No digital signature information.");
	}
	
	UIAlertController *alertController = [UIAlertController
										  alertControllerWithTitle:PTLocalizedString(@"Digital Signature", @"")
										  message:info
										  preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *okAction = [UIAlertAction
								   actionWithTitle:PTLocalizedString(@"OK", @"")
								   style:UIAlertActionStyleDefault
							   handler:^(UIAlertAction *action){
                                   self->m_firstTap = NO;
							   }];

	
	[alertController addAction:okAction];
	
	[self.pt_viewController presentViewController:alertController animated:YES completion:nil];

}

-(void)deleteAppearance
{
	@try
	{
		[self.pdfViewCtrl DocLock:YES];
		
		PTWidget* widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
		
		[[widget GetSDFObj] EraseDictElementWithKey:@"AP"];
		
		[self.currentAnnotation RefreshAppearance];
		
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlock];
	}
	
	[self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
	
	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
	
	m_exiting = YES;
	self.nextToolType = self.defaultClass;
	[self.toolManager createSwitchToolEvent:nil];
}

- (void)colorPickerViewController:(UIViewController*)colorPicker didSelectColor:(UIColor *)color {
    
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
		
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
}

-(void)reSelectAnnotation
{
	if( ![self.currentAnnotation IsValid] )
		return;
	
	PTPDFRect* rect = [self.currentAnnotation GetRect];
	CGRect screenRect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
	[self showSelectionMenu:screenRect];
}

- (void) attachBorderThicknessMenuItems
{
	[self hideMenu];
	
    NSMutableArray<UIMenuItem*>* menuItems = [[NSMutableArray alloc] initWithCapacity:4];
    
    UIMenuItem* menuItem;
	
	NSString* pt = PTLocalizedString(@"pt", @"Abbreviation for point, as in font point size.");
	
	menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"0.5 %@", pt] action:@selector(setThickness05)];
	[menuItems addObject:menuItem];
	menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"1 %@", pt] action:@selector(setThickness10)];
	[menuItems addObject:menuItem];
	menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"3 %@", pt] action:@selector(setThickness30)];
	[menuItems addObject:menuItem];
	menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"5 %@", pt] action:@selector(setThickness50)];
    [menuItems addObject:menuItem];
	
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    theMenu.menuItems = menuItems;
	
	PTPDFRect* rect = [self.currentAnnotation GetRect];
	
	CGRect screenRect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
	
	[self showSelectionMenu:screenRect];
}

-(void)setThickness05
{
	[self setThickness:0.5];
}

-(void)setThickness10
{
	[self setThickness:1.0];
}

-(void)setThickness30
{
	[self setThickness:3.0];
}

-(void)setThickness50
{
	[self setThickness:5.0];
}

-(void)setThickness:(double)thickness
{
	@try
	{
		[self.pdfViewCtrl DocLock:YES];
		
		PTObj* app = [self.currentAnnotation GetAppearance:e_ptnormal app_state:nil];
		PTElementReader* reader = [[PTElementReader alloc] init];
		PTElement* element = [self getFirstElementUsingReader:reader fromObj:app ofType:e_ptform];
		
		if( element != nil )
		{
			PTObj* xobj = [element GetXObject];
			PTElementReader* reader2 = [[PTElementReader alloc] init];
			element = [self getFirstElementUsingReader:reader2 fromObj:xobj ofType:e_ptpath];
			
			if( element != nil )
			{
				PTElementWriter* writer = [[PTElementWriter alloc] init];
				
                [writer WriterBeginWithSDFObj:xobj compress:YES resources:nil];
				
				PTGState* gs = [element GetGState];
                
                [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
                
				[gs SetLineWidth:thickness];
				[writer WriteElement:element];
				[writer End];
				
				[self.currentAnnotation RefreshAppearance];
				[self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
			}
			
		}
		
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlock];
	}
	
	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    
    m_exiting = YES;
    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:nil];
}

-(NSData*)getNSDataFromUIImage:(UIImage*)image
{
	CGImageRef imageRef = image.CGImage;
	NSUInteger width = CGImageGetWidth(imageRef);
	NSUInteger height = CGImageGetHeight(imageRef);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	unsigned char *rawData = (unsigned char*) malloc(height * width * 4 * sizeof(unsigned char));
	NSUInteger bytesPerPixel = 4;
	NSUInteger bytesPerRow = bytesPerPixel * width;
	NSUInteger bitsPerComponent = 8;

	CGContextRef context = CGBitmapContextCreate(rawData, width, height,
												 bitsPerComponent, bytesPerRow, colorSpace,
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);

	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
	CGContextRelease(context);
	
	unsigned char *noAlpha = (unsigned char*) malloc(height * width * 3* sizeof(unsigned char));
	
	for(int pix = 0; pix < height * width * 4; pix += bytesPerPixel)
	{
		memcpy((noAlpha+pix/bytesPerPixel*3), (rawData+pix), 3);
	}
	
	NSData* data = [[NSData alloc] initWithBytesNoCopy:noAlpha length:height*width*3*sizeof(unsigned char) freeWhenDone:YES];
	
	free(rawData);
	
	return data;
}

-(void)digSigViewController:(PTDigSigViewController*)digSigViewController saveAppearanceWithPath:(NSMutableArray*)points withBoundingRect:(CGRect)boundingRect asDefault:(BOOL)asDefault
{
    self.strokeColor = self.digSigViewController.strokeColor;
    self.strokeThickness = self.digSigViewController.strokeThickness;
    [self saveAppearanceWithPath:points withBoundingRect:boundingRect asDefault:asDefault];
}

-(void)floatingSigViewController:(PTFloatingSigViewController *)digSigViewController saveAppearanceWithPath:(NSMutableArray*)points withBoundingRect:(CGRect)boundingRect asDefault:(BOOL)asDefault
{
    self.strokeColor = self.floatingSigViewController.strokeColor;
    self.strokeThickness = self.floatingSigViewController.strokeThickness;
    [self saveAppearanceWithPath:points withBoundingRect:boundingRect asDefault:asDefault];
}

- (PTExtendedAnnotType)currentAnnotationType
{
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        return self.currentAnnotation.extendedAnnotType;
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
}

-(void)saveAppearanceWithPath:(NSMutableArray*)points withBoundingRect:(CGRect)boundingRect asDefault:(BOOL)asDefault
{
    if(points.count > 0 )
    {
        
        if (!self.signaturesManager )
        {
            // tool was probably instantiated directly from a button, not via a touch even prior
            self.signaturesManager = [[PTSignaturesManager allocOverridden] init];
        }
        
        if( CGPointEqualToPoint(CGPointZero, self.longPressPoint) )
        {
            // put signature in middle of frame
            self.longPressPoint = CGPointMake(self.pdfViewCtrl.frame.size.width/2, self.pdfViewCtrl.frame.size.height/2);
        }
        
        
        if (!self.showsSavedSignatures) {
            asDefault = NO;
        }


        PTPDFDoc* doc = [self.signaturesManager createSignature:points withStrokeColor:self.strokeColor withStrokeThickness:self.strokeThickness withinRect:boundingRect saveSignature:asDefault];
        assert(doc);
        
        if (self.currentAnnotation /*&& [self currentAnnotationType] == PTExtendedAnnotTypeSignature*/) {
            [self addToWidget:doc];
            [self closeSignatureDialog];
        }
        else if( !self.currentAnnotation )
        {
            [self addStamp:doc];
            [self closeSignatureDialog];
        }
        else
            [self addToWidget:doc];
    }
    else
    {
        [self closeSignatureDialog];
    }
	
}

-(void)saveAppearanceWithImageFromFilename:(NSString*)fileName
{
	@try
	{
		[self.pdfViewCtrl DocLock:YES];
		
		PTSDFDoc* doc = [[self.pdfViewCtrl GetDoc] GetSDFDoc];
		
		PTImage* sigImg = [PTImage Create:doc filename:fileName];
		
		[self saveAppearanceWithTrnImage:sigImg];
		
	}
	@catch (NSException *exception)
	{
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally
	{
		[self.pdfViewCtrl DocUnlock];
	}
	
	
	
}

-(void)digSigViewController:(PTDigSigViewController*)digSigViewController saveAppearanceWithUIImage:(UIImage*)uiImage
{
	@try
	{
		[self.pdfViewCtrl DocLock:YES];
		
		PTSDFDoc* doc = [[self.pdfViewCtrl GetDoc] GetSDFDoc];
		
		NSData* data = [self getNSDataFromUIImage:uiImage];
		
		PTObj* o = [[PTObj alloc] init];
        
		PTImage* trnImage = [PTImage CreateWithData:doc buf:data buf_size:data.length width:uiImage.size.width height:uiImage.size.height bpc:8 color_space:[PTColorSpace CreateDeviceRGB] encoder_hints:o];
			
		[self saveAppearanceWithTrnImage:trnImage];
		
	}
	@catch (NSException *exception)
	{
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally
	{
		[self.pdfViewCtrl DocUnlock];
	}
	
	
}

-(void)saveAppearanceWithTrnImage:(PTImage*)trnImage
{
	[self closeSignatureDialog];
	
    if( [self.currentAnnotation GetType] == e_ptWidget )
    {
        PTWidget *widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
        PTField *field = [widget GetField];
        
        // Check for invalid or readonly field.
        if (![field IsValid] || [field GetFlag:e_ptread_only]) {
            return;
        }
        
        PTFieldType fieldType = [field GetType];
        
        if (fieldType == e_ptsignature) {
            
            PTSignatureWidget* sigWidget = [[PTSignatureWidget alloc] initWithAnn:self.currentAnnotation];
            
            [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            
            [sigWidget CreateSignatureAppearance:trnImage];
            
            [self.currentAnnotation RefreshAppearance];

            [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
            
            [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            
        }
    }

}

-(void)rotatePoints:(NSMutableArray<NSValue *> *)points forPageRotation:(PTRotate)rotation
{

    CGFloat radians = 0;
    
    if( rotation == e_pt0 )
    {
        return;
    }
    else if( rotation == e_pt90 )
    {
        radians = 3*M_PI/2;
    }
    else if( rotation == e_pt180 )
    {
        radians = M_PI;
    }
    else if( rotation == e_pt270 )
    {
        radians = M_PI/2;
    }
    
    // Calculate bounding box for points.
    CGFloat minX = CGFLOAT_MAX;
    CGFloat maxX = CGFLOAT_MIN;
    CGFloat minY = CGFLOAT_MAX;
    CGFloat maxY = CGFLOAT_MIN;
    
    for (NSValue *value in points) {

        CGPoint point = value.CGPointValue;
        
        if( point.x > 0 )
        {
            minX = MIN(minX, point.x);
            maxX = MAX(maxX, point.x);
        }
        
        if( point.y > 0 )
        {
            minY = MIN(minY, point.y);
            maxY = MAX(maxY, point.y);
        }
    }
        
    CGPoint center;
    center.x = minX + (maxX - minX) / 2;
    center.y = minY + (maxY - minY) / 2;
    
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(center.x, center.y);
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(radians);
    
    CGAffineTransform pointsRotation = CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformInvert(translateTransform), rotationTransform), translateTransform);
    
    NSUInteger pointCount = points.count;
    
    for (NSUInteger i = 0; i < pointCount; i++) {
        NSValue *value = points[i];
        CGPoint point = value.CGPointValue;
        
        if( !CGPointEqualToPoint(CGPointZero, point) )
        {
            point = CGPointApplyAffineTransform(point, pointsRotation);
            
            points[i] = @(point);
        }
    }
}

-(void)normalizePoints:(NSMutableArray<NSValue *> *)points onCanvasSize:(CGSize)canvasSize
{
    PTRotate rotation = [[[self.pdfViewCtrl GetDoc] GetPage:self.annotationPageNumber] GetRotation];
    [self rotatePoints:points forPageRotation:rotation];
    
	PTPDFRect* widgetRect = [self.currentAnnotation GetRect];
	[widgetRect InflateWithAmount:-1];
    
    double min_x = DBL_MAX;
    double min_y = DBL_MAX;
    double max_x = DBL_MIN;
    double max_y = DBL_MIN;
    
    for (int i = 0; i < points.count; i++) {
        NSValue* pointContainer = points[i];
        
        CGPoint point;
        [pointContainer getValue:&point];
        
        if( CGPointEqualToPoint(point, CGPointZero) )
            continue;
        
        min_x = MIN(min_x, point.x);
        min_y = MIN(min_y, point.y);
        
        max_x = MAX(max_x, point.x);
        max_y = MAX(max_y, point.y);
    }
    double width = max_x - min_x;
    double height = max_y - min_y;
    
    
    // scale points to fit rectangle
    double horizScale = [widgetRect Width] / width;
    double vertScale = [widgetRect Height] / height;
    
    if(rotation == e_pt90 || rotation == e_pt270)
    {
        horizScale = [widgetRect Height] / height;
        vertScale = [widgetRect Width] / width;
    }
    
    double outerScaleFactor = MIN(horizScale, vertScale);

	
	for (int i = 0; i < points.count; i++) {
		NSValue* pointContainer = points[i];
		
		CGPoint point;
		[pointContainer getValue:&point];
		point.x *= outerScaleFactor;
		point.y *= outerScaleFactor;
		
		// flip y, center y
		if (point.y != 0) {
            point.y -= min_y*outerScaleFactor;
            point.y = height*outerScaleFactor - point.y;
            point.y += [widgetRect Height]/2 - outerScaleFactor*height/2;
		}
		
		// center x
        if (point.x != 0) {
            point.x -= min_x*outerScaleFactor;
            point.x += [widgetRect Width]/2 - outerScaleFactor*width/2;
        }
		
		points[i] = [NSValue valueWithCGPoint:point];
	}
}

static CGPoint DigitalSignatureToolMidPoint(CGPoint a, CGPoint b)
{
    return CGPointMake((a.x + b.x) / 2, (a.y + b.y) / 2);
}

/**
 *
 * @param points - An array of NSValue objects that hold CGPoints, representing
 * points that are used to construct the signature path. CGPointZero denotes
 * the beginging of a new picewise linear curve.
 *
 */
-(void)digSigViewController:(PTDigSigViewController*)digSigViewController saveAppearanceWithPath:(NSMutableArray*)points fromCanvasSize:(CGSize)canvasSize
{
    if( points.count > 2 )
    {
        @try
        {
            [self normalizePoints:points onCanvasSize:canvasSize];
            
            [self.pdfViewCtrl DocLock:YES];

            PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];

            // Add the signature appearance
            PTElementWriter* apWriter = [[PTElementWriter alloc] init];
            PTElementBuilder* apBuilder = [[PTElementBuilder alloc] init];
            
            [apWriter WriterBeginWithSDFDoc:[doc GetSDFDoc] compress:YES];
            
            [apBuilder PathBegin];
            
            // Draw quadratic bezier curves between points.
            CGPoint previousPoint1 = CGPointZero;
            CGPoint previousPoint2 = CGPointZero;
            
            for (NSValue *value in points) {
                CGPoint currentPoint = value.CGPointValue;
                
                if (!CGPointEqualToPoint(currentPoint, CGPointZero)) {
                    
                    if (CGPointEqualToPoint(previousPoint1, CGPointZero)) {
                        previousPoint1 = currentPoint;
                    }
                    if (CGPointEqualToPoint(previousPoint2, CGPointZero)) {
                        previousPoint2 = currentPoint;
                    }
                    
                    CGPoint mid1 = DigitalSignatureToolMidPoint(previousPoint1, previousPoint2);
                    CGPoint mid2 = DigitalSignatureToolMidPoint(currentPoint, previousPoint1);
                    
                    [apBuilder MoveTo:mid1.x y:mid1.y];
                    
                    [apBuilder CurveTo:previousPoint1.x cy1:previousPoint1.y cx2:previousPoint1.x cy2:previousPoint1.y x2:mid2.x y2:mid2.y];
                    
                } else {
                    // End of stroke.
                    previousPoint1 = CGPointZero;
                }
                
                previousPoint2 = previousPoint1;
                previousPoint1 = currentPoint;
            }

            PTElement *element = [apBuilder PathEnd];
            [element SetPathStroke:YES];
            PTColorPt* color = [PTColorDefaults colorPtFromUIColor:digSigViewController.strokeColor];
            
            // Set default line color
            [[element GetGState] SetStrokeColorSpace: [PTColorSpace CreateDeviceRGB]];
            [[element GetGState] SetStrokeColorWithColorPt:color];
            [[element GetGState] SetLineWidth:1];
            [[element GetGState] SetLineCap:e_ptround_cap];
            [[element GetGState] SetLineJoin:e_ptround_join];
            
            [apWriter WriteElement:element];

            PTObj *obj = [apWriter End];
            [obj PutRect:@"BBox" x1:0 y1:0 x2:[[self.currentAnnotation GetRect] Width] y2:[[self.currentAnnotation GetRect] Height]];
            [obj PutName:@"Subtype" name:@"Form"];
            [obj PutName:@"Type" name:@"XObject"];
            [obj PutName:@"Name" name:@"Signature"];

            [apWriter WriterBeginWithSDFDoc:[doc GetSDFDoc] compress:YES];
            element = [apBuilder CreateFormWithObj:obj];
            [apWriter WritePlacedElement:element];

            obj = [apWriter End];
            [obj PutRect:@"BBox" x1:0 y1:0 x2:[[self.currentAnnotation GetRect] Width] y2:[[self.currentAnnotation GetRect] Height]];
            [obj PutName:@"Subtype" name:@"Form"];
            [obj PutName:@"Type" name:@"XObject"];
            [obj PutName:@"Name" name:@"Signature"];
            
            [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            
            [self.currentAnnotation SetAppearance:obj annot_state:e_ptnormal app_state:0];
            
            [self.currentAnnotation RefreshAppearance];
            
            [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        }
        @catch (NSException *exception)
        {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
        @finally
        {
            [self.pdfViewCtrl DocUnlock];
        }
        
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        
        [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    }
    
    [self closeSignatureDialog];

}

-(void)floatingSigViewControllerCloseSignatureDialog:(PTFloatingSigViewController*)floatingSigViewController
{    
    [self closeSignatureDialog];
}

-(void)digSigViewControllerCloseSignatureDialog:(PTDigSigViewController*)digSigViewController
{
    [self closeSignatureDialog];
}

-(void)closeSignatureDialog
{
    
	self.nextToolType = [PTPanTool class];
	m_exiting = YES;

	[self.toolManager createSwitchToolEvent:nil];
	
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if( gestureRecognizer.state != UIGestureRecognizerStateBegan )
        return YES;
    
	return [self selectDigSig:[gestureRecognizer locationInView:self.pdfViewCtrl]];
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    
    if( !(self.isPencilTouch == YES || self.toolManager.annotationsCreatedWithPencilOnly == NO) )
    {
        return YES;
    }
    
    CGPoint location = [gestureRecognizer locationInView:self.pdfViewCtrl];
    
    
    if( m_firstTap )
    {
        // if a second tap is handled (i.e. the user did not choose my signture or new signature)
        // then dismiss tool
        self.nextToolType = [PTPanTool class];
        m_exiting = YES;

        [self.toolManager createSwitchToolEvent:nil];
    }
    
    NSError* error;
    __block BOOL annotIsLocked = NO;
    
    BOOL ranBlock = [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        
        annotIsLocked = [self.currentAnnotation GetFlag:e_ptlocked];

    } error:&error];
    
    NSAssert(!error, @"Locking error");
    
    if( ranBlock && annotIsLocked )
    {
        self.nextToolType = [PTPanTool class];
        m_exiting = YES;

        [self.toolManager createSwitchToolEvent:nil];
    }
    else if( ![self selectDigSig:location] && !m_firstTap)
    {
        self.longPressPoint = location;
        self.currentAnnotation = nil;
        m_MenuFrame = CGRectMake(location.x, location.y, 1, 1);
        [self attachMenuItems];
    }
    

    m_firstTap = YES;

    return YES;
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    BOOL ret = [super pdfViewCtrl:pdfViewCtrl touchesShouldBegin:touches withEvent:event inContentView:view];

    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }

    return ret;

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        return !self.isPencilTouch;
    }
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // We have a confirmed drag.
    m_dragging = YES;
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    if( !(self.isPencilTouch == YES || self.toolManager.annotationsCreatedWithPencilOnly == NO) )
    {
        return YES;
    }
    
    // Ensure this gesture included a drag.
    if (m_dragging) {
        // Get touch location.
        UITouch *touch = touches.allObjects[0];
        CGPoint location = [touch locationInView:self.pdfViewCtrl];
        
        if (![self selectDigSig:location]) {
            self.longPressPoint = location;
            self.currentAnnotation = nil;
            m_MenuFrame = CGRectMake(location.x, location.y, 1, 1);
            [self attachMenuItems];
        }
    }
    
    m_dragging = NO;

    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    m_dragging = NO;
    
    return YES;
}

- (BOOL)selectDigSig:(CGPoint)down
{
	BOOL foundSignature = NO;
    
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
		
        self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
		
		if([self.currentAnnotation IsValid] && [self.currentAnnotation extendedAnnotType] == PTExtendedAnnotTypeWidget)
		{
			foundSignature = YES;
			PTWidget* wg4;
			PTField* f;
			
			@try
			{
				[self.pdfViewCtrl DocLockRead];
				wg4 = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
				f = [wg4 GetField];
				
				if( [f GetType] != e_ptsignature )
				{
					foundSignature = NO;
					self.currentAnnotation = nil;
					return foundSignature;
				}
			}
			@catch (NSException *exception) {
				NSLog(@"Exception: %@: %@",exception.name, exception.reason);
			}
			@finally {
				[self.pdfViewCtrl DocUnlockRead];
			}
			
			self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y];
		}
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    // Show menu if a signature/widget annotation was found.
    if (foundSignature) {
        PTPDFRect* rect = [self.currentAnnotation GetRect];
        CGRect screenRect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
        [self attachMenuItems];
        [self showSelectionMenu:screenRect];
    }
	
	self.nextToolType = [PTPanTool class];
	if( foundSignature )
		return YES;
	else
		return NO;
}
/// digital signature



-(void)digSigViewControllerSignAndSave:(PTDigSigViewController*)digSigViewController
{
    [self signAndSave];
}
    
-(void)signAndSave
{
	PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
	
    
    NSURL* digitalCertificateLocation = self.toolManager.digitalCertificateLocation;
    
    NSAssert( [digitalCertificateLocation isFileURL], @"URL must be a file URL" );
    
    NSString* fullPath;
    
    if( digitalCertificateLocation == Nil)
    {
        fullPath = [[NSBundle mainBundle] pathForResource:@"pdftron" ofType:@"pfx"];
    }
    else
    {
        fullPath = digitalCertificateLocation.path;
    }
   
    
	NSString* newFile;
	
	@try
	{
		[self.pdfViewCtrl DocLock:YES];
		
		SignatureHandlerId sigHandlerId =  [doc AddStdSignatureHandlerFromFile:fullPath pkcs12_keypass:@"password"];
		
		PTWidget* widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
		
		PTField* field = [widget GetField];
		
		PTObj* sigDict = [field UseSignatureHandler:sigHandlerId];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
		
		[sigDict PutName:@"SubFilter" name:@"adbe.pkcs7.detached"];
		[sigDict PutString:@"Name" value:@"PDFTron"];
		[sigDict PutString:@"Location" value:@"Vancouver, BC"];
		[sigDict PutString:@"Reason" value:@"Document Verification"];
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = paths[0];
		
		NSString* baseName = [[self.pdfViewCtrl GetDoc] GetFileName].lastPathComponent.stringByDeletingPathExtension;
		NSString* signedPDFName = [baseName stringByAppendingString:@"-signed.pdf"];
		
		newFile = [documentsDirectory stringByAppendingPathComponent:signedPDFName];
		
		unsigned int tries = 1;
		
		BOOL isDir;
		
		// append numbers as to not overwrite previously signed files with the same name
		while([[NSFileManager defaultManager] fileExistsAtPath:newFile isDirectory:&isDir])
		{
			signedPDFName = [baseName stringByAppendingString:[NSString stringWithFormat:@"-signed %u.pdf",tries]];
			newFile = [documentsDirectory stringByAppendingPathComponent:signedPDFName];
			tries++;
		}
		
		[doc SaveToFile:newFile flags:e_ptincremental];
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlock];
	}
	
	[self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
	
	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

@end
