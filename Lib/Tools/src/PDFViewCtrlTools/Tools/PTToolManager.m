//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolManager.h"

#import "PTAnnotEditTool.h"
#import "PTDigitalSignatureTool.h"
#import "PTPanTool.h"
#import "PTEraser.h"
#import "PTPolylineEditTool.h"
#import "PTTextMarkupEditTool.h"
#import "PTFreeHandCreate.h"
#import "PTPencilDrawingCreate.h"
#import "PTToolsUtil.h"
#import "PTErrors.h"
#import "UIView+PTAdditions.h"
#import "NSObject+PTAdditions.h"
#import "NSString+PTAdditions.h"
#import "NSObject+PTKeyValueObserving.h"
#import "PTAnalyticsManager.h"

#import <CoreBluetooth/CoreBluetooth.h>

#pragma mark - Notifications

#pragma mark Tools

const NSNotificationName PTToolManagerToolWillChangeNotification = @"PTToolManagerToolWillChangeNotification";
const NSNotificationName PTToolManagerToolDidChangeNotification = @"PTToolManagerToolDidChangeNotification";

#pragma mark Annotations

const NSNotificationName PTToolManagerAnnotationAddedNotification = @"PTToolManagerAnnotationAddedNotification";
const NSNotificationName PTToolManagerAnnotationWillModifyNotification = @"PTToolManagerAnnotationWillModifyNotification";
const NSNotificationName PTToolManagerAnnotationModifiedNotification = @"PTToolManagerAnnotationModifiedNotification";
const NSNotificationName PTToolManagerAnnotationWillRemoveNotification = @"PTToolManagerAnnotationWillRemoveNotification";
const NSNotificationName PTToolManagerAnnotationRemovedNotification = @"PTToolManagerAnnotationRemovedNotification";

#pragma mark Form fields

const NSNotificationName PTToolManagerFormFieldDataModifiedNotification = @"PTToolManagerFormFieldDataModifiedNotification";

#pragma mark Annotation options

const NSNotificationName PTToolManagerAnnotationOptionsDidChangeNotification = @"PTToolManagerAnnotationOptionsDidChangeNotification";

#pragma mark Pages

const NSNotificationName PTToolManagerPageAddedNotification = @"PTToolManagerPageAddedNotification";
const NSNotificationName PTToolManagerPageMovedNotification = @"PTToolManagerPageMovedNotification";
const NSNotificationName PTToolManagerPageRemovedNotification = @"PTToolManagerPageRemovedNotification";

#pragma mark - Notification User Info Keys

static NSString * const PTToolManagerBluetoothInfoKey = @"PTToolManagerBluetoothInfoKey";

NSString * const PTToolManagerToolUserInfoKey = @"PTToolManagerToolUserInfoKey";

NSString * const PTToolManagerPreviousToolUserInfoKey = @"PTToolManagerPreviousToolUserInfoKey";

NSString * const PTToolManagerAnnotationUserInfoKey = @"PTToolManagerAnnotationUserInfoKey";
NSString * const PTToolManagerPageNumberUserInfoKey = @"PTToolManagerPageNumberUserInfoKey";

NSString * const PTToolManagerAnnotationNamesUserInfoKey = @"PTToolManagerAnnotationNamesUserInfoKey";

NSString * const PTToolManagerPreviousPageNumberUserInfoKey = @"PTToolManagerPreviousPageNumberUserInfoKey";

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Annotation options

static NSString * const PTToolManager_annotationOptionsSuffix = @"AnnotationOptions";

@interface PTToolManager ()<CBCentralManagerDelegate>

// Redeclare as readwrite (original declaration in UIResponder).
@property (nonatomic, readwrite, strong) NSUndoManager *undoManager;

@property (nonatomic, strong) NSMutableDictionary<NSString *, PTKeyValueObservation *> *annotationOptionsObservations;

@property (nonatomic, strong) CBCentralManager* bluetoothCentralManager;

typedef NS_ENUM(NSUInteger, PTBluetoothStatus) {
    PTBluetoothStatusNotAsked,
    PTBluetoothStatusAuthorized,
    PTBluetoothStatusUnauthorized,
};

@property (nonatomic, readwrite, assign) PTBluetoothStatus *bluetoothRequestStatus;

@end

NS_ASSUME_NONNULL_END

// pragma sliences warning regarding incomplete implementation because most
// relevant selectors are automatically forwarded to tool via forwardingTargetForSelector:
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation PTToolManager

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
		_tool = [[PTPanTool alloc] initWithPDFViewCtrl:pdfViewCtrl];

        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

        if (![defaults valueForKey:PTToolManagerBluetoothInfoKey]) {

            [defaults setValue:@(PTBluetoothStatusNotAsked) forKey:PTToolManagerBluetoothInfoKey];
        }
        
        
        PTBluetoothStatus currentStatus = [[defaults valueForKey:PTToolManagerBluetoothInfoKey] intValue];
        
        if( currentStatus != PTBluetoothStatusNotAsked )
        {
            // attempt to power it up
            [self powerOnBluetoothManager];
        }
        
  
        [self pt_observeObject:PTToolsSettingsManager.sharedManager forKeyPath:PT_CLASS_KEY(PTToolsSettingsManager, pencilInteractionMode) selector:@selector(pencilSettingsDidChange:) options:NSKeyValueObservingOptionNew];
        
        
        _annotationAuthor = nil;
        _showMenuOnTap = NO;
        _showDefaultSignature = YES;
        _pageIndicatorEnabled = NO;
        _allowBluetoothPermissionPrompt = YES;

        _readonly = NO;

        // Default annotation options.
        _textAnnotationOptions = [PTTextAnnotationOptions options];
        _linkAnnotationOptions = [PTAnnotationOptions options];
        _freeTextAnnotationOptions = [PTFreeTextAnnotationOptions options];
        _lineAnnotationOptions = [PTAnnotationOptions options];
        _squareAnnotationOptions = [PTAnnotationOptions options];
        _circleAnnotationOptions = [PTAnnotationOptions options];
        _polygonAnnotationOptions = [PTAnnotationOptions options];
        _polylineAnnotationOptions = [PTAnnotationOptions options];
        _highlightAnnotationOptions = [PTTextMarkupAnnotationOptions options];
        _underlineAnnotationOptions = [PTTextMarkupAnnotationOptions options];
        _squigglyAnnotationOptions = [PTTextMarkupAnnotationOptions options];
        _strikeOutAnnotationOptions = [PTTextMarkupAnnotationOptions options];
        _stampAnnotationOptions = [PTAnnotationOptions options];
        _caretAnnotationOptions = [PTAnnotationOptions options];
        _inkAnnotationOptions = [PTAnnotationOptions options];
        _popupAnnotationOptions = [PTAnnotationOptions options];
        _fileAttachmentAnnotationOptions = [PTAnnotationOptions options];
        _soundAnnotationOptions = [PTAnnotationOptions options];
        _movieAnnotationOptions = [PTAnnotationOptions options];
        _widgetAnnotationOptions = [PTWidgetAnnotationOptions options];
        _screenAnnotationOptions = [PTAnnotationOptions options];
        _printerMarkAnnotationOptions = [PTAnnotationOptions options];
        _trapNetAnnotationOptions = [PTAnnotationOptions options];
        _watermarkAnnotationOptions = [PTAnnotationOptions options];
        _threeDimensionalAnnotationOptions = [PTAnnotationOptions options];
        _redactAnnotationOptions = [PTAnnotationOptions options];
        _projectionAnnotationOptions = [PTAnnotationOptions options];
        _richMediaAnnotationOptions = [PTAnnotationOptions options];
        _arrowAnnotationOptions = [PTAnnotationOptions options];
        _signatureAnnotationOptions = [PTSignatureAnnotationOptions options];
        _cloudyAnnotationOptions = [PTAnnotationOptions options];
        _imageStampAnnotationOptions = [PTImageStampAnnotationOptions options];
        _rulerAnnotationOptions = [PTAnnotationOptions options];
        _perimeterAnnotationOptions = [PTAnnotationOptions options];
        _areaAnnotationOptions = [PTAnnotationOptions options];
        _pencilDrawingAnnotationOptions = [PTAnnotationOptions options];
        _freehandHighlightAnnotationOptions = [PTAnnotationOptions options];
        _calloutAnnotationOptions = [PTAnnotationOptions options];
        
        _textSelectionEnabled = YES;
        _linkFollowingEnabled = YES;
        _eraserEnabled = YES;
        _autoResizeFreeTextEnabled = YES;
        _snapToDocumentGeometryEnabled = NO;
        _annotationsSnapToAspectRatio = YES;
        
        _selectAnnotationAfterCreation = PTToolsSettingsManager.sharedManager.selectAnnotationAfterCreation;
        _freehandUsesPencilKit = PTToolsSettingsManager.sharedManager.freehandUsesPencilKit;
        _pencilHighlightMultiplyBlendModeEnabled = PTToolsSettingsManager.sharedManager.pencilHighlightMultiplyBlendModeEnabled;
        _pencilInteractionMode = PTToolsSettingsManager.sharedManager.pencilInteractionMode;

        if ([self usingPencilKit]) {
            if (@available(iOS 13.1, *) ) {
             _pencilTool = [PTPencilDrawingCreate class];
            }
        } else {
            _pencilTool = [PTFreeHandCreate class];
        }

        _annotationOptionsObservations = [NSMutableDictionary dictionary];

        // Get all the PTAnnotationOptions property names.
        NSSet<NSString *> *annotationOptionsKeys = [[self class] pt_propertyNamesForKindOfClass:[PTAnnotationOptions class]];

        // Observe the canCreate and canEdit properties of all annotation options.
        for (NSString *annotationOptionsKey in annotationOptionsKeys) {
            // Check for the correct suffix (don't observe the deprecated "permission" properties).
            if (![annotationOptionsKey hasSuffix:PTToolManager_annotationOptionsSuffix]) {
                continue;
            }

            NSArray<NSString *> *keyPaths =
            @[
              [annotationOptionsKey stringByAppendingPathExtension:@"canCreate"],
              [annotationOptionsKey stringByAppendingPathExtension:@"canEdit"],
              ];
            
            SEL selector = @selector(annotationOptionsDidChange:);
          
            // Include old and new values in change dictionary.
            NSKeyValueObservingOptions options = (NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew);

            for (NSString *keyPath in keyPaths) {
                [self pt_observeObject:self
                            forKeyPath:keyPath
                              selector:selector
                               options:options];
            }
        }

        // Enable undo/redo support.
        @try {
            [_pdfViewCtrl EnableUndoRedo];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        }
        _undoRedoManager = [[PTUndoRedoManager alloc] initWithToolManager:self];
        
        _pageLabelManager = [[PTPageLabelManager allocOverridden] initWithPDFViewCtrl:pdfViewCtrl];

        [self newToolSetup];
    }

    return self;
}

-(BOOL)usingPencilKit
{
    if (@available(iOS 13.1, *)) {
        return self.freehandUsesPencilKit;
    }
    
    return NO;
}

// this selector exists so that classes that use it do not need to hold an instance
// of pdfviewctrl.
- (PTTool *)changeTool:(Class)toolType
{
    PTTool *newTool = [[toolType alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
	self.tool = newTool;
	return newTool;
}

- (void)setTool:(PTTool *)tool
{
    if ([_tool isEqual:tool]) {
        // No change.
        return;
    }

    // Check with delegate if the change should occur.
    if ([self.delegate respondsToSelector:@selector(toolManager:shouldSwitchToTool:)]) {
        if (![self.delegate toolManager:self shouldSwitchToTool:tool]) {
            return;
        }
    }

    // Check that the tool has a valid PTPDFViewCtrl reference.
	if (tool) {
        if (!tool.pdfViewCtrl) {
            NSString *reason = [NSString stringWithFormat:@"The tool %@ does not have a valid %@ reference",
                                tool, NSStringFromClass([PTPDFViewCtrl class])];

            NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                             reason:reason
                                                           userInfo:nil];
            @throw exception;
            return;
        }

        // Check that the tool has the same PTPDFViewCtrl as the tool manager.
        if (![tool.pdfViewCtrl isEqual:self.pdfViewCtrl]) {
            NSString *reason = [NSString stringWithFormat:@"The tool %@ does not reference the same %@ instance as the tool manager %@",
                                tool, NSStringFromClass([PTPDFViewCtrl class]), self];

            NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                             reason:reason
                                                           userInfo:nil];
            @throw exception;
            return;
        }
	}

    // Wrap in autorelease pool to help the previous tool deallocate as soon as possible.
    @autoreleasepool {
        PTTool *previousTool = _tool;
        
        [self willChangeToTool:tool];
        
        // Remove previous tool.
        [previousTool removeFromSuperview];

        // Tell the new tool what the previous tool type was.
        if ([tool isKindOfClass:[PTTool class]]) {
            ((PTTool *)tool).previousToolType = [previousTool class];
        }

        _tool = tool;
        [self newToolSetup];

        [self didChangeFromTool:previousTool];
    }

}

- (void)willChangeToTool:(nullable PTTool *)tool
{
    // Notify delegate of imminent tool change.
    if ([self.delegate respondsToSelector:@selector(toolManager:willSwitchToTool:)]) {
        [self.delegate toolManager:self willSwitchToTool:tool];
    }

    // Include the next tool in the notification, if present.
    NSDictionary<NSString *, id> *userInfo = nil;
    if (tool) {
        userInfo = @{
            PTToolManagerToolUserInfoKey: tool,
        };
    }
    
    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerToolWillChangeNotification
                                                      object:self
                                                    userInfo:userInfo];
}

- (void)newToolSetup
{
    // Add tool to the PTPDFViewCtrl's (tool) overlay view.
    if (_tool) {
        _tool.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self.pdfViewCtrl.toolOverlayView addSubview:_tool];
    }

    _tool.toolManager = self;

    // Pass tool-specific settings to the tool.

    if (_tool.annotationAuthor.length == 0) {
        _tool.annotationAuthor = self.annotationAuthor;
    }

    if ([_tool isKindOfClass:[PTPanTool class]]) {
        ((PTPanTool*)_tool).showMenuOnTap = self.showMenuOnTap;
    }

    if ([_tool isKindOfClass:[PTDigitalSignatureTool class]]) {
        ((PTDigitalSignatureTool*)_tool).showsSavedSignatures = self.showDefaultSignature;
    }

    _tool.pageIndicatorIsVisible = self.pageIndicatorEnabled;
}

- (void)didChangeFromTool:(nullable PTTool *)previousTool
{
    // Notify delegate of tool change.
    if ([self.delegate respondsToSelector:@selector(toolManagerToolChanged:)]) {
        [self.delegate toolManagerToolChanged:self];
    }

    // Include the previous tool class in the notification, if present.
    NSDictionary<NSString *, id> *userInfo = nil;
    if (previousTool) {
        userInfo = @{
            PTToolManagerPreviousToolUserInfoKey: [previousTool class],
        };
    }

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerToolDidChangeNotification
                                                      object:self
                                                    userInfo:userInfo];

}

- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    if (!annotation) {
        if (self.tool.defaultClass) {
            [self changeTool:self.tool.defaultClass];
        } else {
            [self changeTool:[PTPanTool class]];
        }
    }
    
    PTExtendedAnnotType annotType;
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        if (![annotation IsValid]) {
            return NO;
        }

        annotType = [annotation extendedAnnotType];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        return NO;
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    switch (annotType) {
        case PTExtendedAnnotTypeWidget:
            // Not implemented.
            break;
            
        case PTExtendedAnnotTypeRichMedia:
            // Not implemented.
            break;
            
        case PTExtendedAnnotTypeHighlight:
        case PTExtendedAnnotTypeUnderline:
        case PTExtendedAnnotTypeStrikeOut:
        case PTExtendedAnnotTypeSquiggly:
        {
            PTTextMarkupEditTool *tool = (PTTextMarkupEditTool *)[self changeTool:[PTTextMarkupEditTool class]];
            if (tool != self.tool) {
                // Could not switch to tool.
                return NO;
            }
            
            if ([tool selectTextMarkupAnnotation:annotation onPageNumber:(unsigned int)pageNumber]) {
                return YES;
            }
            
            // Could not select annotation: switch back to default tool.
            [self changeTool:tool.defaultClass];
        }
            break;
            
        case PTExtendedAnnotTypePolyline:
        case PTExtendedAnnotTypePolygon:
        case PTExtendedAnnotTypePerimeter:
        case PTExtendedAnnotTypeArea:
        case PTExtendedAnnotTypeCloudy:
        case PTExtendedAnnotTypeLine:
        case PTExtendedAnnotTypeRuler:
        case PTExtendedAnnotTypeArrow:
        {
            PTPolylineEditTool *tool = (PTPolylineEditTool *)[self changeTool:[PTPolylineEditTool class]];
            if (tool != self.tool) {
                // Could not switch to tool.
                return NO;
            }
            
            if ([tool selectAnnotation:annotation onPageNumber:(unsigned int)pageNumber]) {
                return YES;
            }
            
            // Could not select annotation: switch back to default tool.
            [self changeTool:tool.defaultClass];
        }
            break;
            
        default:
        {
            PTAnnotEditTool *tool = (PTAnnotEditTool *)[self changeTool:[PTAnnotEditTool class]];
            if (tool != self.tool) {
                // Could not switch to tool.
                return NO;
            }
            
            if ([tool selectAnnotation:annotation onPageNumber:(unsigned int)pageNumber]) {
                return YES;
            }
            
            // Could not select annotation: switch back to default tool.
            [self changeTool:tool.defaultClass];
        }
            break;
    }
    
    return NO;
}

-(void)setShowMenuOnTap:(BOOL)showMenuOnTap
{
    _showMenuOnTap = showMenuOnTap;
    if( [_tool isKindOfClass:[PTPanTool class]])
    {
        ((PTPanTool*)_tool).showMenuOnTap = _showMenuOnTap;
    }
}

- (UIViewController *)viewController
{
    if (!self.delegate) {
        NSString *reason = [NSString stringWithFormat:@"The instance of the tool manager %@, %@, (from PDFTron's Tools.framework), has a nil delegate. The tool manager requires a delegate for correct operation. Please assign the tool manager's delegate to a conforming object, as described in our documentation: https://www.pdftron.com/api/ios/Classes/PTToolManager.html#/c:objc(cs)PTToolManager(py)delegate", NSStringFromClass([self class]), self];

        NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                         reason:reason
                                                       userInfo:nil];
        @throw exception;
        return nil;
    }
    return [self.delegate viewControllerForToolManager:self];
}

#pragma mark - Tool Loop

-(BOOL)runToolLoop:(BOOL (^)(PTTool *))toolEventBlock
{
	if( !self.tool )
	{
		// cannot run if we have no tool to forward the event to.
        return YES;
	}

    const int maximumToolSwitches = 10;
    int numToolSwitches = 0;
    BOOL handled = YES;
    do {

		@try {
			handled = toolEventBlock(self.tool);
		}
		@catch (NSException *exception) {
			return YES;
		}
		@finally {

		}

		// did tool finish processing this event?
        if( !handled )
        {
			// no, so create a new instance of a tool that it should be forwarded to
            PTTool* tempTool = [self.tool getNewTool];

            if ( [self.delegate respondsToSelector:@selector(toolManager:shouldSwitchToTool:)])
            {
                if( ![self.delegate toolManager:self shouldSwitchToTool:tempTool] )
                    break;
            }
            
			// set the new tool as tool
			self.tool = tempTool;

			// keep track of how many switches to prevent an accidental infinite loop
            numToolSwitches++;
        }

    } while (!handled && numToolSwitches < maximumToolSwitches);

    if( numToolSwitches >= maximumToolSwitches)
    {
        // there was an error condition in one of the tools, and we are escaping a likely infinite loop
        return YES;
    }

    return handled;
}

#pragma mark - Events that need to be looped

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self runToolLoop:^BOOL(PTTool *aTool){
		return [aTool pdfViewCtrl:pdfViewCtrl onTouchesBegan:touches withEvent:event];
	}];

	return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self runToolLoop:^BOOL(PTTool *aTool){
		return [aTool pdfViewCtrl:pdfViewCtrl onTouchesMoved:touches withEvent:event];
	}];

	return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self runToolLoop:^BOOL(PTTool *aTool){
		return [aTool pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
	}];

	return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[self runToolLoop:^BOOL(PTTool *aTool){
		return [aTool  pdfViewCtrl:pdfViewCtrl onTouchesCancelled:touches withEvent:event];
	}];

	return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if ([self.delegate respondsToSelector:@selector(toolManager:handleLongPress:)]) {
        if ([self.delegate toolManager:self handleLongPress:gestureRecognizer]) {
            return YES;
        }
    }

	[self runToolLoop:^BOOL(PTTool *aTool){
		return [aTool pdfViewCtrl:pdfViewCtrl handleLongPress:gestureRecognizer];
	}];

	return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if ([self.delegate respondsToSelector:@selector(toolManager:handleTap:)]) {
        if ([self.delegate toolManager:self handleTap:gestureRecognizer]) {
            return YES;
        }
    }

	[self runToolLoop:^BOOL(PTTool *aTool){
		return [aTool pdfViewCtrl:pdfViewCtrl handleTap:gestureRecognizer];
	}];

	return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if ([self.delegate respondsToSelector:@selector(toolManager:handleDoubleTap:)]) {
        if ([self.delegate toolManager:self handleDoubleTap:gestureRecognizer]) {
            return YES;
        }
    }

	[self runToolLoop:^BOOL(PTTool *aTool){
		return [aTool pdfViewCtrl:pdfViewCtrl handleDoubleTap:gestureRecognizer];
	}];

	return YES;
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pencilInteractionDidTap:(UIPencilInteraction *)interaction
API_AVAILABLE(ios(12.1)){
    BOOL isPencilTool = NO;
    if (@available(iOS 13.1, *)) {
        isPencilTool = [self.tool isKindOfClass:[PTPencilDrawingCreate class]];
    }

    if ((isPencilTool && !self.tool.backToPanToolAfterUse) ||
        [self.tool isKindOfClass:[PTFreeHandCreate class]]) {
        return;
    }

    switch (UIPencilInteraction.preferredTapAction) {
        case UIPencilPreferredActionSwitchEraser:
            if ([self.tool isKindOfClass:[PTEraser class]]) {
                [self changeTool:self.tool.previousToolType];
            }else{
                if ([self.tool isKindOfClass:[PTCreateToolBase class]] &&
                    ((PTCreateToolBase *)self.tool).requiresEditSupport &&
                    !isPencilTool){
                    return;
                }
                if ([self.tool isKindOfClass:[PTAnnotEditTool class]]) {
                    // Maintain the previous tool flow
                    [self changeTool:self.tool.previousToolType];
                }
                PTEraser* eraser = (PTEraser*)[self changeTool:[PTEraser class]];
                eraser.backToPanToolAfterUse = NO;
                eraser.acceptPencilTouchesOnly = YES;
            }
            break;
        case UIPencilPreferredActionSwitchPrevious:{
            [self changeTool:self.tool.previousToolType];
            break;
        }
        case UIPencilPreferredActionShowColorPalette:
            break;
        case UIPencilPreferredActionIgnore:
            break;
        default:
            break;
    }
}

#if TARGET_OS_MACCATALYST
- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location configuration:(UIContextMenuConfiguration * _Nullable __autoreleasing *)configuration
{
    [self runToolLoop:^BOOL(PTTool *aTool){
        return [aTool pdfViewCtrl:pdfViewCtrl contextMenuInteraction:interaction configurationForMenuAtLocation:location configuration:configuration];
    }];

    return YES;
}
#endif

- (BOOL)onSwitchToolEvent:(id)userData
{
    [self runToolLoop:^BOOL(PTTool *aTool){
        return [aTool onSwitchToolEvent:userData];
    }];

    return YES;
}

#pragma mark - Create a new looped event

-(void)createSwitchToolEvent:(id)userData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onSwitchToolEvent:userData];
    });
}

#pragma mark - Events that do NOT need to be looped

-(void)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl javascriptCallback:(const char*)event_type json:(const char*)json
{
    NSString* type = @(event_type);
    NSString* message = @(json);
    if([type isEqualToString:@"alert"])
    {
        NSData* jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSError* e;
        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&e];
        NSString* alert_message = dict[@"cMsg"];
        NSString* title = dict[@"cTitle"] ? dict[@"cTitle"] : PTLocalizedString(@"JavaScript Alert", @"JavaScript Alert.");
        
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:title
                                              message:alert_message
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:PTLocalizedString(@"OK", @"")
                                   style:UIAlertActionStyleDefault
                                   handler:nil];
        
        
        [alertController addAction:okAction];
        
        [self.pt_viewController presentViewController:alertController animated:YES completion:nil];
    }
}


// return YES if tool manager or current tool responds to the selector
-(BOOL)respondsToSelector:(SEL)aSelector
{
	// if the tool manager itself implements it (i.e. the method needs to be run in runToolLoop)
	if ([[self class] instancesRespondToSelector:aSelector] ) return YES;

	// if the active tool implements it
	if ([[self.tool class] instancesRespondToSelector:aSelector] ) return YES;

	return NO;
}

// this will directly forward all other tool delegate methods to the active tool
-(id)forwardingTargetForSelector:(SEL)aSelector
{
	// allows methods not called explicitly by the tool manager on the tool (as is done in runToolLoop)
	// to be automatically forwarded
	return self.tool;
}

#pragma mark - UIResponder

// Synthesize undoManager property (not synthesized by UIResponder because the default property
// getter walks the responder chain to find an NSUndoManager).
@synthesize undoManager = _undoManager;

- (NSUndoManager *)undoManager
{
    if (!_undoManager) {
        _undoManager = [[NSUndoManager alloc] init];

        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(undoManagerWillUndoChangeWithNotification:)
                                                   name:NSUndoManagerWillUndoChangeNotification
                                                 object:_undoManager];

        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(undoManagerWillRedoChangeWithNotification:)
                                                   name:NSUndoManagerWillRedoChangeNotification
                                                 object:_undoManager];
    }
    return _undoManager;
}

#pragma mark - Annotation Events

- (void)tool:(PTTool *)tool annotationAdded:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    [self annotationAdded:annotation onPageNumber:(int)pageNumber];
}

- (void)annotationAdded:(PTAnnot*)annotation onPageNumber:(int)pageNumber
{
    // Track change in undo-redo manager.
    // NOTE: This must be done *before* notifying the delegate or posting the notification since
    // the document could be modified by the delegate and/or observers.
    [self.undoRedoManager annotationAdded:annotation onPageNumber:(int)pageNumber];

    // Notify delegate of added annotation.
    if ([self.delegate respondsToSelector:@selector(toolManager:annotationAdded:onPageNumber:)]) {
        [self.delegate toolManager:self annotationAdded:annotation onPageNumber:pageNumber];
    }

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerAnnotationAddedNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerAnnotationUserInfoKey: annotation,
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}


- (void)willModifyAnnotation:(PTAnnot*)annotation onPageNumber:(int)pageNumber
{
    if ([self.delegate respondsToSelector:@selector(toolManager:willModifyAnnotation:onPageNumber:)]) {
        [self.delegate toolManager:self willModifyAnnotation:annotation onPageNumber:pageNumber];
    }
    
    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerAnnotationWillModifyNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerAnnotationUserInfoKey: annotation,
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}

- (void)tool:(PTTool *)tool annotationModified:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
    [self annotationModified:annotation onPageNumber:(int)pageNumber];
}

- (void)annotationModified:(PTAnnot*)annotation onPageNumber:(int)pageNumber
{
    // Update annotation modification date.
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;

        PTDate* date = [[PTDate alloc] init];
        [date SetCurrentTime];
        [annotation SetDate:date];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }

    // Track change in undo-redo manager.
    // NOTE: This must be done *before* notifying the delegate or posting the notification since
    // the document could be modified by the delegate and/or observers.
    [self.undoRedoManager annotationModified:annotation onPageNumber:(int)pageNumber];

    // Notify delegate of modified annotation.
	if ([self.delegate respondsToSelector:@selector(toolManager:annotationModified:onPageNumber:)]) {
		[self.delegate toolManager:self annotationModified:annotation onPageNumber:pageNumber];
	}

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerAnnotationModifiedNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerAnnotationUserInfoKey: annotation,
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}

- (void)willRemoveAnnotation:(PTAnnot*)annotation onPageNumber:(int)pageNumber
{
    if ([self.delegate respondsToSelector:@selector(toolManager:willRemoveAnnotation:onPageNumber:)]) {
        [self.delegate toolManager:self willRemoveAnnotation:annotation onPageNumber:pageNumber];
    }
    
    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerAnnotationWillRemoveNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerAnnotationUserInfoKey: annotation,
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}

- (void)tool:(PTTool *)tool annotationRemoved:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    [self annotationRemoved:annotation onPageNumber:(int)pageNumber];
}

- (void)annotationRemoved:(PTAnnot*)annotation onPageNumber:(int)pageNumber
{
    // Track change in undo-redo manager.
    // NOTE: This must be done *before* notifying the delegate or posting the notification since
    // the document could be modified by the delegate and/or observers.
    [self.undoRedoManager annotationRemoved:annotation onPageNumber:(int)pageNumber];

    // Notify delegate of removed annotation.
    if ([self.delegate respondsToSelector:@selector(toolManager:annotationRemoved:onPageNumber:)]) {
        [self.delegate toolManager:self annotationRemoved:annotation onPageNumber:pageNumber];
    }

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerAnnotationRemovedNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerAnnotationUserInfoKey: annotation,
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}

- (void)tool:(PTTool *)tool formFieldDataModified:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
    [self formFieldDataModified:annotation onPageNumber:(int)pageNumber];
}

- (void)formFieldDataModified:(PTAnnot*)annotation onPageNumber:(int)pageNumber
{
    // Track change in undo-redo manager.
    // NOTE: This must be done *before* notifying the delegate or posting the notification since
    // the document could be modified by the delegate and/or observers.
    [self.undoRedoManager formFieldDataModified:annotation onPageNumber:pageNumber];

    // Notify delegate of modified form field.
    if ( [self.delegate respondsToSelector:@selector(toolManager:formFieldDataModified:onPageNumber:)])
    {
        [self.delegate toolManager:self formFieldDataModified:annotation onPageNumber:pageNumber];
    }

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerFormFieldDataModifiedNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerAnnotationUserInfoKey: annotation,
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}


-(BOOL)tool:(PTTool *)tool shouldHandleLinkAnnotation:(PTAnnot*)annotation orLinkInfo:(PTLinkInfo*)linkInfo onPageNumber:(unsigned long)pageNumber
{
    if ( [self.delegate respondsToSelector:@selector(toolManager:shouldHandleLinkAnnotation:orLinkInfo:onPageNumber:)])
    {
        return [self.delegate toolManager:self shouldHandleLinkAnnotation:annotation orLinkInfo:(PTLinkInfo*)linkInfo onPageNumber:pageNumber];
    }

    return YES;
}

- (void)tool:(PTTool *)tool handleFileAttachment:(PTFileAttachment *)fileAttachment onPageNumber:(unsigned long)pageNumber
{
    if ([self.delegate respondsToSelector:@selector(toolManager:handleFileAttachment:onPageNumber:)]) {
        [self.delegate toolManager:self handleFileAttachment:fileAttachment onPageNumber:pageNumber];
    }
}

- (BOOL)tool:(PTTool *)tool handleFileSelected:(NSString *)filePath
{
    if ([self.delegate respondsToSelector:@selector(toolManager:handleFileSelected:)]) {
        return [self.delegate toolManager:self handleFileSelected:filePath];
    }
    return NO;
}


-(BOOL)tool:(PTTool *)tool shouldInteractWithForm:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
    if ( [self.delegate respondsToSelector:@selector(toolManager:shouldInteractWithForm:onPageNumber:)])
    {
        return [self.delegate toolManager:self shouldInteractWithForm:annotation onPageNumber:pageNumber];
    }

    return YES;
}

-(BOOL)tool:(PTTool *)tool shouldSelectAnnotation:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
    if ( [self.delegate respondsToSelector:@selector(toolManager:shouldSelectAnnotation:onPageNumber:)])
    {
        return [self.delegate toolManager:self shouldSelectAnnotation:annotation onPageNumber:pageNumber];
    }

    return YES;
}

-(void)tool:(PTTool *)tool didSelectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    if ( [self.delegate respondsToSelector:@selector(toolManager:didSelectAnnotation:onPageNumber:)] )
    {
        [self.delegate toolManager:self didSelectAnnotation:annotation onPageNumber:pageNumber];
    }
}

-(BOOL)tool:(PTTool *)tool shouldShowMenu:(UIMenuController *)menuController forAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    if ( [self.delegate respondsToSelector:@selector(toolManager:shouldShowMenu:forAnnotation:onPageNumber:)])
    {
        return [self.delegate toolManager:self shouldShowMenu:menuController forAnnotation:annotation onPageNumber:pageNumber];
    }

    return YES;
}

#pragma mark - Page events

- (void)pageAddedForPageNumber:(int)pageNumber
{
    // Track change in undo-redo manager.
    // NOTE: This must be done *before* notifying the delegate or posting the notification since
    // the document could be modified by the delegate and/or observers.
    [self.undoRedoManager pageAddedAtPageNumber:pageNumber];

    // Notify delegate of page addition.
    if ([self.delegate respondsToSelector:@selector(toolManager:pageAddedForPageNumber:)]) {
        [self.delegate toolManager:self pageAddedForPageNumber:pageNumber];
    }

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerPageAddedNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}

- (void)pageMovedFromPageNumber:(int)oldPageNumber toPageNumber:(int)newPageNumber
{
    // Track change in undo-redo manager.
    // NOTE: This must be done *before* notifying the delegate or posting the notification since
    // the document could be modified by the delegate and/or observers.
    [self.undoRedoManager pageMovedFromPageNumber:oldPageNumber toPageNumber:newPageNumber];

    // Notify delegate of page move.
    if ([self.delegate respondsToSelector:@selector(toolManager:pageMovedFromPageNumber:toPageNumber:)]) {
        [self.delegate toolManager:self pageMovedFromPageNumber:oldPageNumber toPageNumber:newPageNumber];
    }

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerPageMovedNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerPreviousPageNumberUserInfoKey: @(oldPageNumber),
                                                               PTToolManagerPageNumberUserInfoKey: @(newPageNumber),
                                                               }];
}

- (void)pageRemovedForPageNumber:(int)pageNumber
{
    // Track change in undo-redo manager.
    // NOTE: This must be done *before* notifying the delegate or posting the notification since
    // the document could be modified by the delegate and/or observers.
    [self.undoRedoManager pageRemovedForPageNumber:pageNumber];

    // Notify delegate of page removal.
    if ([self.delegate respondsToSelector:@selector(toolManager:pageRemovedForPageNumber:)]) {
        [self.delegate toolManager:self pageRemovedForPageNumber:pageNumber];
    }

    // Post notification.
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerPageRemovedNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerPageNumberUserInfoKey: @(pageNumber),
                                                               }];
}

#pragma mark - Annotation author

- (void)setAnnotationAuthor:(NSString *)annotationAuthor
{
    if ([_annotationAuthor isEqualToString:annotationAuthor]) {
        // No change.
        return;
    }

    _annotationAuthor = [annotationAuthor copy];

    // Update current tool's annotation author.
    self.tool.annotationAuthor = annotationAuthor;
}

#pragma mark - Readonly

- (void)setReadonly:(BOOL)readonly
{
    if (_readonly == readonly) {
        // No change.
        return;
    }

    _readonly = readonly;

    if (readonly) {
        // Switch to PTPanTool.
        [self changeTool:[PTPanTool class]];
    }

    

    [self postAnnotationOptionsChangedNotificationWithAnnotNames:@[]];
}

#pragma mark - Apple Pencil behavior


- (BOOL)annotationsCreatedWithPencilOnly
{
    if( UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad )
    {
        return NO;
    }
    
    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
    
    PTBluetoothStatus currentStatus = [[defaults valueForKey:PTToolManagerBluetoothInfoKey] intValue];
    
    PTPencilInteractionMode mode = ((PTToolManager*)self.pdfViewCtrl.toolDelegate).pencilInteractionMode;
    
    if( mode == PTPencilInteractionModeFingerAndPencil && currentStatus != PTBluetoothStatusNotAsked)
    {
        return NO;
    }
    
    if (@available(iOS 14, *)) {
        if( mode == PTPencilInteractionModeSystem && UIPencilInteraction.prefersPencilOnlyDrawing == NO && currentStatus != PTBluetoothStatusNotAsked)
        {
            return NO;
        }
    } else {
        // nothing to check
    }
    

    // we don't want to ask on tool switch, only on pencil touch
    if( currentStatus == PTBluetoothStatusAuthorized || currentStatus == PTBluetoothStatusUnauthorized)
    {
        return [self applePencilIsPaired];
    }
    
    return NO;
    
}

#pragma mark - Annotation options

- (PTAnnotationOptions *)annotationOptionsForAnnotType:(PTExtendedAnnotType)annotType
{
    

    PTExtendedAnnotName annotName = PTExtendedAnnotNameFromType(annotType);
    if (!annotName) {
        return nil;
    }

    NSString *prefix = [[annotName substringToIndex:1].lowercaseString stringByAppendingString:[annotName substringFromIndex:1]];

    NSString *propertyName = [prefix stringByAppendingString:PTToolManager_annotationOptionsSuffix];
    if (![self respondsToSelector:NSSelectorFromString(propertyName)]) {
        return nil;
    }

    return [self valueForKey:propertyName];
}

- (nullable PTExtendedAnnotName)annotNameForAnnotationOptionsPropertyName:(NSString *)propertyName
{
    if (!propertyName) {
        return nil;
    }

    NSRange suffixRange = [propertyName rangeOfString:PTToolManager_annotationOptionsSuffix
                                              options:(NSAnchoredSearch | NSBackwardsSearch)];
    if (suffixRange.location == NSNotFound) {
        return nil;
    }

    NSString *lowercaseName = [propertyName substringToIndex:suffixRange.location];
    return lowercaseName.pt_sentenceCapitalizedString;
}

- (BOOL)canCreateExtendedAnnotType:(PTExtendedAnnotType)annotType
{
    if ([self isReadonly]) {
        return NO;
    }

    PTAnnotationOptions *options = [self annotationOptionsForAnnotType:annotType];
    if (!options) {
        // Bad annot type or options clobbered.
        return YES;
    }
    return options.canCreate;
}

- (BOOL)canEditExtendedAnnotType:(PTExtendedAnnotType)annotType
{
    PTAnnotationOptions *options = [self annotationOptionsForAnnotType:annotType];
    if (!options) {
        // Bad annot type or options clobbered.
        return YES;
    }
    return options.canEdit;
}

- (BOOL)canEditAnnotation:(PTAnnot *)annotation
{
    return [self canEditExtendedAnnotType:annotation.extendedAnnotType];
}

#pragma mark - Annotation permissions

- (BOOL)hasEditPermissionForAnnot:(PTAnnot *)annot
{
    if (self.readonly) {
        return NO;
    }
    if (![self isAnnotationPermissionCheckEnabled] && ![self isAnnotationAuthorCheckEnabled]) {
        return YES;
    }

    BOOL hasPermission = YES;

    if (hasPermission && [self isAnnotationAuthorCheckEnabled]) {
        // Check the annotation author.
        NSString *currentAuthor = self.annotationAuthor;

        BOOL shouldUnlockRead = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlockRead = YES;

            // Only markup annotations have authors.
            if ([annot IsMarkup]) {
                PTMarkup *markup = [[PTMarkup alloc] initWithAnn:annot];
                if ([markup IsValid]) {
                    // Check if the markup's author (title) matches the current author.
                    NSString *author = [markup GetTitle];
                    if (author && currentAuthor) {
                        hasPermission = [author isEqualToString:currentAuthor];
                    }
                }
            }
        } @catch (NSException *exception) {
            hasPermission = YES;
        } @finally {
            if (shouldUnlockRead) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
    }

    if (hasPermission && [self isAnnotationPermissionCheckEnabled]) {
        // Check the annotation's flags.
        BOOL shouldUnlockRead = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlockRead = YES;

            // Check if one of the read_only or locked flags is set.
            if ([annot GetFlag:e_ptannot_read_only] || [annot GetFlag:e_ptlocked]) {
                hasPermission = NO;
            }
        } @catch (NSException *exception) {
            hasPermission = YES;
        } @finally {
            if (shouldUnlockRead) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
    }

    return hasPermission;
}

#pragma mark - Interaction features

- (BOOL)isFormFillingEnabled
{
    return self.widgetAnnotationOptions.canEdit;
}

- (void)setFormFillingEnabled:(BOOL)enabled
{
    self.widgetAnnotationOptions.canEdit = enabled;
}

- (BOOL)autoResizeFreeText
{
    return [self isAutoResizeFreeTextEnabled];
}

- (void)setAutoResizeFreeText:(BOOL)enabled
{
    self.autoResizeFreeTextEnabled = enabled;
}

- (BOOL)snapToDocumentGeometry
{
    return [self isSnapToDocumentGeometryEnabled];
}

- (void)setSnapToDocumentGeometry:(BOOL)enabled
{
    self.snapToDocumentGeometryEnabled = enabled;
}

#pragma mark - <PTToolOptionsDelegate>

- (BOOL)tool:(PTTool *)tool canCreateExtendedAnnotType:(PTExtendedAnnotType)annotType
{
    return [self canCreateExtendedAnnotType:annotType];
}

- (BOOL)tool:(PTTool *)tool canEditExtendedAnnotType:(PTExtendedAnnotType)annotType
{
    return [self canEditExtendedAnnotType:annotType];
}

- (BOOL)tool:(PTTool *)tool canEditAnnotation:(PTAnnot *)annotation
{
    return [self canEditAnnotation:annotation];
}

- (BOOL)tool:(PTTool *)tool hasEditPermissionForAnnot:(PTAnnot *)annot
{
    return [self hasEditPermissionForAnnot:annot];
}

- (BOOL)isTextSelectionEnabledForTool:(PTTool *)tool
{
    return [self isTextSelectionEnabled];
}

- (BOOL)isFormFillingEnabledForTool:(PTTool *)tool
{
    return [self isFormFillingEnabled];
}

- (BOOL)isLinkFollowingEnabledForTool:(PTTool *)tool
{
    return [self isLinkFollowingEnabled];
}

- (BOOL)isEraserEnabledForTool:(PTTool *)tool
{
    return [self isEraserEnabled];
}

#pragma mark - Annotation options updates

- (void)postAnnotationOptionsChangedNotificationWithAnnotNames:(NSArray<PTExtendedAnnotName> *)annotNames
{
    [NSNotificationCenter.defaultCenter postNotificationName:PTToolManagerAnnotationOptionsDidChangeNotification
                                                      object:self
                                                    userInfo:@{
                                                               PTToolManagerAnnotationNamesUserInfoKey: annotNames,
                                                               }];
}

#pragma mark - Observation

- (void)annotationOptionsDidChange:(PTKeyValueObservedChange *)change
{
    if (self != change.object) {
        return;
    }
    
    NSArray<NSString *> *keyPathComponents = change.keyPath.pt_keyPathComponents;
  
    // Check if value actually changed.
    id oldValue = change.oldValue;
    if (oldValue) {
        id newValue = change.newValue;
        if (!newValue) {
            newValue = [change.object valueForKeyPath:change.keyPath];
        }
        if ([oldValue isEqual:newValue]) {
            // No change.
            return;
        }
    }

    NSString *propertyName = keyPathComponents.firstObject;
    PTExtendedAnnotName annotName = [self annotNameForAnnotationOptionsPropertyName:propertyName];
    if (!annotName) {
        PTLog(@"Failed to get annotation name from property: %@", propertyName);
        return;
    }

    [self postAnnotationOptionsChangedNotificationWithAnnotNames:@[annotName]];
}

#pragma mark - Notifications

- (void)undoManagerWillUndoChangeWithNotification:(NSNotification *)notification
{
    // Check notification object.
    if (notification.object != self.undoManager) {
        return;
    }

    // Change the tool before undo-ing because it could remove a currently selected annotation.
    [self changeTool:[PTPanTool class]];
}

- (void)undoManagerWillRedoChangeWithNotification:(NSNotification *)notification
{
    // Check notification object.
    if (notification.object != self.undoManager) {
        return;
    }

    // Change the tool before redo-ing because it could remove a currently selected annotation.
    [self changeTool:[PTPanTool class]];
}

#pragma mark - Bluetooth management for Apple Pencil

-(void)powerOnBluetoothManager
{
    if( UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad )
    {
        return;
    }
    
    if( self.bluetoothCentralManager == Nil && self.allowBluetoothPermissionPrompt == YES)
    {
                
        self.bluetoothCentralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                    queue:nil
                                                                  options:nil];
        
    }
}


-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
    
    PTBluetoothStatus previousStatus = [[defaults valueForKey:PTToolManagerBluetoothInfoKey] intValue];
    
    if (central.state == CBManagerStatePoweredOn)
    {
        
        [defaults setValue:@(PTBluetoothStatusAuthorized) forKey:PTToolManagerBluetoothInfoKey];

        if( previousStatus == PTBluetoothStatusNotAsked )
        {
            
            [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Permission] Bluetooth YES"];
            
            // if the user just gave us bluetooth permission, let's go into pencil mode
            PTToolsSettingsManager* settingsManager = PTToolsSettingsManager.sharedManager;
            if (@available(iOS 14, *)) {
                
                if( UIPencilInteraction.prefersPencilOnlyDrawing == YES )
                {
                    settingsManager.pencilInteractionMode = PTPencilInteractionModeSystem;
                }
                else
                {
                    settingsManager.pencilInteractionMode = PTPencilInteractionModePencilOnly;
                }
            }
            else
            {
                settingsManager.pencilInteractionMode = PTPencilInteractionModePencilOnly;
            }
        }
        
        self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.annotationsCreatedWithPencilOnly;
        
        
        
    }
    else if(central.state == CBManagerStateUnknown)
    {
        
    }
    else if(central.state == CBManagerStateUnauthorized)
    {
        [defaults setValue:@(PTBluetoothStatusUnauthorized) forKey:PTToolManagerBluetoothInfoKey];
        
        if( previousStatus == PTBluetoothStatusNotAsked )
        {
            [PTAnalyticsManager.defaultManager sendCustomEventWithTag:@"[Permission] Bluetooth NO"];
        }
        
    }

}

-(void)promptForBluetoothPermission
{
    if( UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad )
    {
        return;
    }

    [self powerOnBluetoothManager];

}

-(BOOL)applePencilIsPaired
{

    if( UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad )
    {
        return NO;
    }

    if ([self.bluetoothCentralManager state] == CBManagerStatePoweredOn)
    {
        // Device information UUID
        NSArray* myArray = [NSArray arrayWithObject:[CBUUID UUIDWithString:@"180A"]];

        NSArray* peripherals =
          [self.bluetoothCentralManager retrieveConnectedPeripheralsWithServices:myArray];
        for (CBPeripheral* peripheral in peripherals)
        {
            if ([[peripheral name] isEqualToString:@"Apple Pencil"])
            {
                // The Apple pencil is connected
                return YES;
            }
        }
        return NO;
    }
    
    // we don't know
    return NO;
}

-(void)pencilSettingsDidChange:(PTKeyValueObservedChange*)change
{
    if( [self.tool createsAnnotation] )
    {
        self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.annotationsCreatedWithPencilOnly;
    }
    
}

#pragma mark - Other

//-(void)pdfViewCtrlOnSetDoc:(PTPDFViewCtrl *)pdfViewCtrl
//{
//    if( [self.tool isKindOfClass:[PTPanTool class]] == NO)
//    {
//        UIView* cleanRemoveTool = self.tool;
//        if( [cleanRemoveTool superview] )
//            [cleanRemoveTool removeFromSuperview];
//        [self changeTool:[PTPanTool class]];
//    }
//}

- (void)dealloc
{
    // Remove all annotation options observers.
    for (PTKeyValueObservation *observation in self.pt_observations) {
        [observation invalidate];
    }

    // Remove tool.
    if (_tool.superview) {
        [_tool removeFromSuperview];
    }
}

@end

#pragma clang diagnostic pop

PT_CONSTRUCTOR
static void PT_dyLibLoaded(void)
{
    @try {
        PTLog(@"Auto-initializing PDFNet in demo mode");
        
        [PTPDFNet Initialize:@"demo:demo@pdftron.com:73b0e0bd01e77b55b3c29607184e8750c2d5e94da67da8f1d0"];
    }
    @catch (NSException *exception) {
        PTLog(@"Exception auto-initializing PDFNet: %@, %@", exception.name, exception.reason);
    }
}

#pragma mark - Convenience categories

#pragma mark - PTPDFViewCtrl convenience categories

@implementation PTPDFViewCtrl (Locking)

- (BOOL)DocLock:(BOOL)cancelThreads withBlock:(void (NS_NOESCAPE ^)(PTPDFDoc * _Nullable))block error:(NSError * _Nullable __autoreleasing *)error
{
    BOOL success = NO;
    BOOL shouldUnlock = NO;
    
    @try {
        [self DocLock:cancelThreads];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [self GetDoc];
        
        if (block) {
            block(doc);
        }
        success = YES;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = exception.pt_error;
        }
        success = NO;
    }
    @finally {
        if (shouldUnlock) {
            @try {
                [self DocUnlock];
            }
            @catch (NSException *exception) {
                if (error) {
                    *error = exception.pt_error;
                }
                success = NO;
            }
        }
    }
    
    return success;
}

- (BOOL)DocLockReadWithBlock:(void (NS_NOESCAPE ^)(PTPDFDoc * _Nullable))block error:(NSError * _Nullable __autoreleasing *)error
{
    BOOL success = NO;
    BOOL shouldUnlock = NO;
    
    @try {
        [self DocLockRead];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [self GetDoc];
        
        if (block) {
            block(doc);
        }
        success = YES;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = exception.pt_error;
        }
        success = NO;
    }
    @finally {
        if (shouldUnlock) {
            @try {
                [self DocUnlockRead];
            }
            @catch (NSException *exception) {
                if (error) {
                    *error = exception.pt_error;
                }
                success = NO;
            }
        }
    }
    
    return success;
}

@end

#pragma mark - PTAnnot convenience categories

@implementation PTAnnot (UniqueID)

- (NSString *)GetUniqueIDAsString
{
    PTObj *obj = [self GetUniqueID];
    if ([obj IsValid] && [obj IsString]) {
        return [obj GetAsPDFText];
    }
    return nil;
}

@end

#pragma mark - PTFreeText convenience categories

@implementation PTFreeText (SetFont)

- (NSString*)getFontName
{
    PTObj* annotObj = [self GetSDFObj];
    PTObj* drDict = [annotObj FindObj:@"DR"];
    
    if( [drDict IsValid] && [drDict IsDict] )
    {
        PTObj* fontDict = [drDict FindObj:@"Font"];
        if( [fontDict IsValid] && [fontDict IsDict] )
        {
            PTDictIterator* fItr = [fontDict GetDictIterator];
            if ([fItr HasNext]) {
                PTFont* f = [[PTFont alloc] initWithFont_dict:[fItr Value]];
                NSString* name = [f GetName];
                return name;
            }
        }
    }
    
    return nil;
}

- (void)setFontWithName:(NSString*)fontName pdfDoc:(PTPDFDoc*)doc
{
    
    if (fontName.length > 0) {
        
        NSString* fontDRName = @"F0";

        // Create a DR entry for embedding the font
        PTObj* annotObj = [self GetSDFObj];
        PTObj* drDict = [annotObj PutDict:@"DR"];

        // Embed the font
        PTObj* fontDict = [drDict PutDict:@"Font"];
        PTFont* font = [PTFont CreateFromName:[doc GetSDFDoc] name:fontName char_set:[self GetContents]];
        
        [fontDict Put:fontDRName obj:[font GetSDFObj]];
        
        // Set DA string
        NSString* DA = [self GetDefaultAppearance];
        

        NSRange slashPosition = [DA rangeOfString:@"/"];

        // if DR string contains '/' which it always should.
        if (slashPosition.location > 0)
        {
            NSString* beforeSlash = [DA substringToIndex:slashPosition.location];
            NSString* afterSlash = [DA substringFromIndex:slashPosition.location];
            NSString* afterFont =  [afterSlash substringFromIndex:[afterSlash rangeOfString:@" " ].location];
            
            NSString* updatedDA = [beforeSlash stringByAppendingString:@"/"];
            updatedDA = [updatedDA stringByAppendingString:fontDRName];
            updatedDA = [updatedDA stringByAppendingString:afterFont];
            
            [self SetDefaultAppearance:updatedDA];
        }

    }
}

@end
