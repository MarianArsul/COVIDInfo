//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFormFillTool.h"

#import "PTFormFillInputAccessoryView.h"
#import "PTChoiceFormViewController.h"
#import "PTPanTool.h"
#import "PTDigitalSignatureTool.h"
#import "PTToolsUtil.h"

#import "PTFont+PTAdditions.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "UIView+PTAdditions.h"

#include <tgmath.h>

// Enumeration for the form field advance direction: previous, next.
typedef NS_ENUM(NSUInteger, PTFormFillToolAdvanceDirection) {
    PTFormFillToolAdvanceDirectionPrevious,
    PTFormFillToolAdvanceDirectionNext,
};

// Enumeration for the text form field types: Text, Date, Time, Numeric
typedef NS_ENUM(NSUInteger, PTTextFormFieldType) {
    /// A text field
    PTTextFormFieldTypeText,
    /// A date field
    PTTextFormFieldTypeDate,
    /// A time field
    PTTextFormFieldTypeTime,
    /// A numeric field
    PTTextFormFieldTypeNumeric,
};


@interface PTFormFillTool () <UIPopoverPresentationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UITableViewDelegate, PTChoiceFormDataSource, PTFormFillInputAccessoryViewDelegate>
{
    UIView* responder;
    BOOL keyboardOnScreen;
    NSMutableArray* choices;
    int characterLimit;
    NSInteger selectionStart;
    NSInteger selectionEnd;
    NSString* originalText;
    UITextRange *originalRange;
    UITextField *activeTextField;
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, assign) CGRect annotRect;

@property (nonatomic) CGRect fontRect;

@property (nonatomic) PTTextFormFieldType fieldType;

@end

@implementation PTFormFillTool

-(instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        _displaysInputAccessoryView = YES;
    }
    return self;
}

-(void)executeActionWithFieldIfAvailable:(PTField*)fld Type:(PTFieldActionTriggerEvent) type
{
    PTObj* aa = [fld GetTriggerAction:type];
    if(aa)
    {
        PTAction* a =[[PTAction alloc] initWithIn_obj:aa];
        PTActionParameter* action_parameter = [[PTActionParameter alloc] initWithAction:a field:fld];
        [self executeAction:action_parameter];
    }
}

-(void)executeActionWithAnnotIfAvailable:(PTAnnot*)annot Type:(PTAnnotActionTriggerEvent) type
{
    PTObj* aa = [annot GetTriggerAction:type];
    if(aa)
    {
        PTAction* a =[[PTAction alloc] initWithIn_obj:aa];
        PTActionParameter* action_parameter = [[PTActionParameter alloc] initWithAction:a annot:annot];
        [self executeAction:action_parameter];
    }
}

-(void)executeMouseUpAction:(PTAnnot*)annot
{
    [self executeActionWithAnnotIfAvailable:annot Type:e_ptaction_trigger_activate];
    [self executeActionWithAnnotIfAvailable:annot Type:e_ptaction_trigger_annot_up];
	[self executeActionWithAnnotIfAvailable:self.currentAnnotation Type:e_ptaction_trigger_annot_exit];
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview) {
        self.frame = newSuperview.bounds;
    } else {
        [self deselectAnnotation];
    }
    
    [super willMoveToSuperview:newSuperview];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber
{
    BOOL hasReadLock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        hasReadLock = YES;
        
        // Check for a valid annotation and page number.
        if (![annotation IsValid] || pageNumber == 0) {
            return NO;
        }
        
        // This tool is only for widget annotations.
        PTExtendedAnnotType annotType = [annotation extendedAnnotType];
        if (annotType != PTExtendedAnnotTypeWidget) {
            return NO;
        }
        
        self.currentAnnotation = annotation;
        self.annotationPageNumber = pageNumber;
        
        // Check if form filling is enabled.
        if (![self.toolManager isFormFillingEnabledForTool:self]) {
            return NO;
        }
        
        // Check if annotation can be edited.
        if (![self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
            return NO;
        }
        
        if ( ![self shouldInteractWithForm:annotation onPageNumber:pageNumber] )
        {
            return NO;
        }
        
        
        // Get the annotation rect, in canvas coordinates.
        PTPDFRect *screen_rect = [self.pdfViewCtrl GetScreenRectForAnnot:self.currentAnnotation
                                                                page_num:self.annotationPageNumber];

        self.annotRect = [self PDFRectScreen2CGRectScreen:screen_rect PageNumber:self.annotationPageNumber];
        
        self.annotRect = CGRectOffset(self.annotRect,
                                      [self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos]);
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (hasReadLock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }

    BOOL hasWriteLock = NO;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        hasWriteLock = YES;
        
        // Execute "enter" form actions.
        [self executeActionWithAnnotIfAvailable:self.currentAnnotation Type:e_ptaction_trigger_annot_enter];
        [self executeActionWithAnnotIfAvailable:self.currentAnnotation Type:e_ptaction_trigger_annot_down];
        [self executeActionWithAnnotIfAvailable:self.currentAnnotation Type:e_ptaction_trigger_annot_focus];
        
        PTWidget *widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
        PTField *field = [widget GetField];
        
        // Check for invalid or readonly field.
        if (![field IsValid] || [field GetFlag:e_ptread_only]) {
            return NO;
        }
        
        PTFieldType fieldType = [field GetType];
        
        if (fieldType == e_ptsignature) {
            self.nextToolType = [PTDigitalSignatureTool class];
            [self executeMouseUpAction:self.currentAnnotation];
            return NO;
        }
        else if (fieldType == e_ptcheck) {
            // Toggle check field.
            PTViewChangeCollection *view_change = [field SetValueWithBool:![field GetValueAsBool]];
            [self.pdfViewCtrl RefreshAndUpdate:view_change];
            
            [self formFieldDataModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            
            self.nextToolType = [PTPanTool class];
            [self.toolManager createSwitchToolEvent:nil];
            [self executeMouseUpAction:self.currentAnnotation];
            return YES;
        }
        else if(fieldType == e_ptradio) {
            // Activate radio button.
            PTViewChangeCollection *view_change = [field SetValueWithBool:YES];
            [self.pdfViewCtrl RefreshAndUpdate:view_change];
            
            [self formFieldDataModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            
            self.nextToolType = [PTPanTool class];
            [self.toolManager createSwitchToolEvent:nil];
            [self executeMouseUpAction:self.currentAnnotation];
            return YES;
        }
        else if (fieldType == e_pttext) {
            // used to prevent iOS from scrolling the PDFView when the widget beceomes the first responder.
            UIScrollView* sv;
            
            [responder removeFromSuperview];
            responder = nil;
            
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector (keyboardWillShow:)
                                                       name:UIKeyboardWillShowNotification object:nil];
            
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector (keyboardWillHide:)
                                                       name:UIKeyboardWillHideNotification object:nil];
            
            if( [field GetFlag:e_ptmultiline] )
            {
                UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(0, 0,
                                                                              self.annotRect.size.width,
                                                                              self.annotRect.size.height)];
                tv.delegate = self;

                sv = [[UIScrollView alloc] initWithFrame:self.annotRect];
                responder = sv;
                tv.contentInset = UIEdgeInsetsZero;
                
                tv.textContainerInset = UIEdgeInsetsZero;
                tv.textContainer.lineFragmentPadding = 4;
                
                [sv addSubview:tv];
                // Add scroll view to toolOverlayView.
                // NOTE: Adding the scroll view as a subview of self (the form fill tool) messes
                // up touch forwarding, causing the PDFViewCtrl to get the touches instead.
                [self.pdfViewCtrl.toolOverlayView addSubview:sv];
                
                tv.text = [field GetValueAsString];
                tv.backgroundColor = [UIColor whiteColor];
                
                PTGState* gs = [field GetDefaultAppearance];
                
                CGFloat displayFontSize;
                
                double fontSize = [gs GetFontSize];
                if( fontSize != 0 ) {
                    displayFontSize = fontSize * [self.pdfViewCtrl GetZoom];
                } else {
                    displayFontSize = 12 * [self.pdfViewCtrl GetZoom];
                }
                
                UIFont *textViewFont = nil;
                @try {
                    PTFont *font = [gs GetFont];
                    if (font) {
                        textViewFont = [font UIFontWithSize:displayFontSize];
                    }
                } @catch (NSException *exception) {
                    PTLog(@"Bad font.");
                }
                
                if (!textViewFont) {
                    textViewFont = [UIFont fontWithName:@"Helvetica" size:displayFontSize];
                }
                
                tv.font = textViewFont;
                
                CGRect displayFontRect = [tv.text boundingRectWithSize:tv.bounds.size
                                                               options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                            attributes:@{NSFontAttributeName: textViewFont} context:nil];
                
                self.fontRect = CGRectMake(sv.frame.origin.x, sv.frame.origin.y,
                                           displayFontRect.size.width, displayFontRect.size.height);
                
                characterLimit = [field GetMaxLen]-1;
                
                PTColorPt* fontColour = [gs GetFillColor];
                
                fontColour = [[gs GetFillColorSpace] Convert2RGB:fontColour];
                
                CGFloat r , g, b, a = 1;
                
                r = [fontColour Get:0];
                g = [fontColour Get:1];
                b = [fontColour Get:2];
                
                tv.textColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
                
                tv.backgroundColor = [self getWidgetBackgroundColor:self.currentAnnotation];
                
                PTTextJustification justification = [field GetJustification];
                switch (justification) {
                    case e_ptleft_justified:
                        tv.textAlignment = NSTextAlignmentLeft;
                        break;
                    case e_ptright_justified:
                        tv.textAlignment = NSTextAlignmentRight;
                        break;
                    case e_ptcentered:
                        tv.textAlignment = NSTextAlignmentCenter;
                        break;
                }

                if (self.displaysInputAccessoryView) {
                    PTFormFillInputAccessoryView *accessoryView = [[PTFormFillInputAccessoryView alloc] init];
                    accessoryView.delegate = self;
                    tv.inputAccessoryView = accessoryView;
                }
                
                // Scroll the PDFViewCtrl if necessary.
                CGRect viewport = CGRectMake([self.pdfViewCtrl GetHScrollPos],
                                             [self.pdfViewCtrl GetVScrollPos],
                                             CGRectGetWidth(self.pdfViewCtrl.bounds),
                                             CGRectGetHeight(self.pdfViewCtrl.bounds));
                // Inset viewport by safe area insets (for navigation bar, etc.).
                if (@available(iOS 11.0, *)) {
                    viewport = UIEdgeInsetsInsetRect(viewport, self.safeAreaInsets);
                }
                
                if (CGRectGetMinX(self.annotRect) < CGRectGetMinX(viewport)) {
                    // Need to scroll left.
                    CGFloat pos = CGRectGetMinX(self.annotRect) - 12;
                    [self.pdfViewCtrl SetHScrollPos:pos Animated:NO];
                } else if (CGRectGetMaxX(self.annotRect) > CGRectGetMaxX(viewport)) {
                    // Need to scroll right.
                    CGFloat pos = CGRectGetMaxX(self.annotRect) - CGRectGetWidth(viewport) + 12;
                    [self.pdfViewCtrl SetHScrollPos:pos Animated:NO];
                }
                
                if (CGRectGetMinY(self.annotRect) < CGRectGetMinY(viewport)) {
                    // Need to scroll up.
                    CGFloat pos = CGRectGetMinY(self.annotRect) - 12;
                    
                    if (@available(iOS 11.0, *)) {
                        pos -= self.safeAreaInsets.top;
                    }
                    
                    [self.pdfViewCtrl SetVScrollPos:pos Animated:NO];
                }
                [tv becomeFirstResponder];
            }
            else {
                UITextField *fv = [[UITextField alloc] initWithFrame:CGRectMake(0, 0,
                                                                                CGRectGetWidth(self.annotRect),
                                                                                CGRectGetHeight(self.annotRect))];
                fv.delegate = self;
                fv.returnKeyType = UIReturnKeyDone;
                UIDatePicker *datePicker = [[UIDatePicker alloc] init];
                [datePicker addTarget:self action:@selector(datePickerDidChange:) forControlEvents:UIControlEventValueChanged];
                dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = [self getDateTimeFormatFromField:field];
                NSDate *date = [NSDate date];
                NSError *error = nil;
                NSDataDetector* dataDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeDate error:&error];
                NSString *fieldText = [field GetValueAsString];
                if (fieldText.length > 0) {
                    if (dateFormatter.dateFormat != nil) {
                        date = [dateFormatter dateFromString:fieldText];
                    }else{
                        NSDate *detectedDate = [dataDetector matchesInString:fieldText options:0 range:NSMakeRange(0, [fieldText length])].firstObject.date;
                        if (detectedDate) {
                            date = detectedDate;
                        }
                    }
                }
                
                PTWidgetAnnotationOptions *widgetAnnotationOptions = self.toolManager.widgetAnnotationOptions;
                if (@available(iOS 13.4, *)) {
                    datePicker.preferredDatePickerStyle = widgetAnnotationOptions.preferredDatePickerStyle;
                }

                switch ([self typeForTextFormField:field]) {
                    case PTTextFormFieldTypeDate:
                    {
                        datePicker.datePickerMode = UIDatePickerModeDate;
                        datePicker.date = date;
                        fv.inputView = datePicker;
                        break;
                    }
                    case PTTextFormFieldTypeTime:
                    {
                        datePicker.datePickerMode = UIDatePickerModeTime;
                        datePicker.date = date;
                        fv.inputView = datePicker;
                        break;
                    }
                    case PTTextFormFieldTypeNumeric:
                    {
                        fv.keyboardType = UIKeyboardTypeDecimalPad;
                        break;
                    }
                    default:
                        break;
                }
                sv = [[UIScrollView alloc] initWithFrame:self.annotRect];
                responder = sv;
                
                
                // Get the maximum character count.
                characterLimit = [field GetMaxLen]-1;
                
                [sv addSubview:fv];
                // Add scroll view to toolOverlayView.
                // NOTE: Adding the scroll view as a subview of self (the form fill tool) messes
                // up touch forwarding, causing the PDFViewCtrl to get the touches instead.
                [self.pdfViewCtrl.toolOverlayView addSubview:sv];
                
                fv.text = [field GetValueAsString];
                
                // consider setting a different colour if you wish to "highlight" the field that is being edited
                fv.backgroundColor = [UIColor whiteColor];
                
                fv.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                
                // Set up the field's appearance.
                PTGState *gs = [field GetDefaultAppearance];
                
                // Get the font size for the field.
                CGFloat displayFontSize;
                
                double fontSize = [gs GetFontSize];
                if (fontSize != 0) {
                    displayFontSize = fontSize * [self.pdfViewCtrl GetZoom];
                } else {
                    displayFontSize = CGRectGetHeight(self.annotRect);
                }
                
                fv.font = [UIFont fontWithName:@"Helvetica" size:displayFontSize];
                
                CGRect displayFontRect = [fv.text boundingRectWithSize:fv.bounds.size
                                                               options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:displayFontSize]}
                                                               context:nil];
                
                self.fontRect = CGRectMake(sv.frame.origin.x, sv.frame.origin.y,
                                           CGRectGetWidth(displayFontRect), CGRectGetHeight(displayFontRect));
                
                PTColorPt* fontColour = [gs GetFillColor];
                
                fontColour = [[gs GetFillColorSpace] Convert2RGB:fontColour];
                
                CGFloat r , g, b, a = 1;
                
                r = [fontColour Get:0];
                g = [fontColour Get:1];
                b = [fontColour Get:2];
                
                fv.textColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
                
                fv.backgroundColor = [self getWidgetBackgroundColor:self.currentAnnotation];
                
                if ([field GetFlag:e_ptpassword] ) {
                    fv.secureTextEntry = YES;
                }
                
                // Set text justification.
                PTTextJustification justification = [field GetJustification];
                switch (justification) {
                    case e_ptleft_justified:
                        fv.textAlignment = NSTextAlignmentLeft;
                        break;
                    case e_ptright_justified:
                        fv.textAlignment = NSTextAlignmentRight;
                        break;
                    case e_ptcentered:
                        fv.textAlignment = NSTextAlignmentCenter;
                        break;
                }
                
                if (self.displaysInputAccessoryView) {
                    // Attach input accessory toolbar.
                    PTFormFillInputAccessoryView *accessoryView = [[PTFormFillInputAccessoryView alloc] init];
                    accessoryView.delegate = self;
                    fv.inputAccessoryView = accessoryView;
                }

                // Scroll the PDFViewCtrl if necessary.
                CGRect viewport = CGRectMake([self.pdfViewCtrl GetHScrollPos],
                                             [self.pdfViewCtrl GetVScrollPos],
                                             CGRectGetWidth(self.pdfViewCtrl.bounds),
                                             CGRectGetHeight(self.pdfViewCtrl.bounds));
                // Inset viewport by safe area insets (for navigation bar, etc.).
                if (@available(iOS 11.0, *)) {
                    viewport = UIEdgeInsetsInsetRect(viewport, self.safeAreaInsets);
                }
                
                if (CGRectGetMinX(self.annotRect) < CGRectGetMinX(viewport)) {
                    // Need to scroll left.
                    CGFloat pos = CGRectGetMinX(self.annotRect) - 12;
                    [self.pdfViewCtrl SetHScrollPos:pos Animated:NO];
                } else if (CGRectGetMaxX(self.annotRect) > CGRectGetMaxX(viewport)) {
                    // Need to scroll right.
                    CGFloat pos = CGRectGetMaxX(self.annotRect) - CGRectGetWidth(viewport) + 12;
                    [self.pdfViewCtrl SetHScrollPos:pos Animated:NO];
                }
                
                if (CGRectGetMinY(self.annotRect) < CGRectGetMinY(viewport)) {
                    // Need to scroll up.
                    CGFloat pos = CGRectGetMinY(self.annotRect) - 12;
                    
                    if (@available(iOS 11.0, *)) {
                        pos -= self.safeAreaInsets.top;
                    }
                    
                    [self.pdfViewCtrl SetVScrollPos:pos Animated:NO];
                }
                
                // Become first responder and show virtual keyboard.
                activeTextField = fv;
                [fv becomeFirstResponder];
            }
            [self executeMouseUpAction:self.currentAnnotation];
            return YES;
        }
        else if (fieldType == e_ptbutton) {
            // Simulate "mouse up" action on button field.
            [self executeMouseUpAction:self.currentAnnotation];
            
            self.nextToolType = [PTPanTool class];
            [self.toolManager createSwitchToolEvent:nil];
            return YES;
        }
        else if (fieldType == e_ptchoice) {
            // Choice list.
            PTChoiceFormViewController *cfvc = [[PTChoiceFormViewController alloc] init];
            cfvc.delegate = self;
            
            if ([field GetFlag:e_ptmultiselect]) {
                [cfvc setIsMultiSelect:YES];
            }
            
            cfvc.modalPresentationStyle = UIModalPresentationPopover;
            
            [self.pt_viewController presentViewController:cfvc animated:YES completion:nil];
            
            UIPopoverPresentationController *popController = cfvc.popoverPresentationController;
            
            //                PTPDFRect* rect = [self.currentAnnotation GetRect];
            //                CGRect annotRect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
            
            popController.sourceRect = self.annotRect;
            popController.sourceView = self.pdfViewCtrl.toolOverlayView;
            popController.delegate = self;
        }
        
        // Execute form "exit" actions.
        [self executeMouseUpAction:self.currentAnnotation];
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        if (hasWriteLock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }

    return YES;
}

-(void)deselectAnnotation
{
    [responder endEditing:NO];
    [responder removeFromSuperview];
    responder = nil;

    self.currentAnnotation = nil;
}

- (nullable PTAnnot *)neighboringFieldForAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber direction:(PTFormFillToolAdvanceDirection)direction
{
    if (!annotation || pageNumber == 0) {
        return nil;
    }
    
    PTAnnot *targetAnnotation = nil;
    
    BOOL hasReadLock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        hasReadLock = YES;
        
        // Check that the current annotation is valid.
        if (![annotation IsValid]) {
            return nil;
        }
        unsigned int annotObjNum = [[annotation GetSDFObj] GetObjNum];
        
        PTPage *page = [[self.pdfViewCtrl GetDoc] GetPage:pageNumber];
        if (![page IsValid]) {
            return nil;
        }
        
        const unsigned int annotCount = [page GetNumAnnots];
        if (annotCount == 0) {
            return nil;
        }
        // Loop over all annotations on the page to find the previous/next field.
        BOOL foundAnnot = NO;
        for (unsigned int i = 0; i < annotCount; i++) {
            PTAnnot *currentAnnotation;
            if (direction == PTFormFillToolAdvanceDirectionNext) {
                currentAnnotation = [page GetAnnot:i];
            } else { // PTFormFillToolAdvanceDirectionPrevious
                // Iterate in reverse.
                currentAnnotation = [page GetAnnot:((annotCount - 1) - i)];
            }
            if (![currentAnnotation IsValid]) {
                continue;
            }
            
            // Check if this is the current annotation.
            unsigned int currentAnnotObjNum = [[currentAnnotation GetSDFObj] GetObjNum];
            if (annotObjNum == currentAnnotObjNum) {
                foundAnnot = YES;
                continue;
            }
            // Check if we have seen the current annotation yet.
            if (!foundAnnot) {
                continue;
            }
            // Now we are looking for the "next" field after the current annotation.
            // Check for a widget annotation.
            if ([currentAnnotation GetType] != e_ptWidget) {
                continue;
            }
            PTWidget *widget = [[PTWidget alloc] initWithAnn:currentAnnotation];
            PTField *field = [widget GetField];
            // Check the field properties.
            if ([field IsValid] && ![field GetFlag:e_ptread_only] && [field GetType] == e_pttext) {
                // Found the next annotation.
                targetAnnotation = currentAnnotation;
                break;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);

        return nil;
    } @finally {
        if (hasReadLock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    return targetAnnotation;
}

- (BOOL)selectPreviousFieldBeforeAnnotation:(PTAnnot *)currentAnnotation onPageNumber:(unsigned int)pageNumber
{
    PTAnnot *previousAnnotation = [self neighboringFieldForAnnotation:currentAnnotation
                                                         onPageNumber:pageNumber
                                                            direction:PTFormFillToolAdvanceDirectionPrevious];
    if (previousAnnotation) {
        [self deselectAnnotation];
        // Select the next annotation.
        return [self selectAnnotation:previousAnnotation onPageNumber:pageNumber];
    }
    
    return NO;
}

- (BOOL)selectNextFieldAfterAnnotation:(PTAnnot *)currentAnnotation onPageNumber:(unsigned int)pageNumber
{
    PTAnnot *nextAnnotation = [self neighboringFieldForAnnotation:currentAnnotation
                                                     onPageNumber:pageNumber
                                                        direction:PTFormFillToolAdvanceDirectionNext];
    if (nextAnnotation) {
        [self deselectAnnotation];
        // Select the next annotation.
        return [self selectAnnotation:nextAnnotation onPageNumber:pageNumber];
    }
    
    return NO;
}

-(PTTextFormFieldType)typeForTextFormField:(PTField*)field
{
    PTObj *triggerAction = [field GetTriggerAction:e_ptaction_trigger_keystroke];
    if (triggerAction != nil && [triggerAction IsDict]) {
        PTObj *js = [triggerAction FindObj:@"JS"];
        if (js != nil && [js IsString]) {
            NSString *jsStr = [js GetAsPDFText];
            if ([jsStr rangeOfString:@"AFNumber"].location != NSNotFound || [jsStr rangeOfString:@"AFPercent"].location != NSNotFound){
                self.fieldType = PTTextFormFieldTypeNumeric;
                return PTTextFormFieldTypeNumeric;
            }
            if ([jsStr rangeOfString:@"AFDate"].location != NSNotFound){
                self.fieldType = PTTextFormFieldTypeDate;
                return PTTextFormFieldTypeDate;
            }
            if ([jsStr rangeOfString:@"AFTime"].location != NSNotFound){
                self.fieldType = PTTextFormFieldTypeTime;
                return PTTextFormFieldTypeTime;
            }
        }
    }
    return PTTextFormFieldTypeText;
}

-(nullable NSString*)getDateTimeFormatFromField:(PTField*)field{
    PTObj *triggerAction = [field GetTriggerAction:e_ptaction_trigger_keystroke];
    if (triggerAction != nil && [triggerAction IsDict]) {
        PTObj *js = [triggerAction FindObj:@"JS"];
        if (js != nil && [js IsString]) {
            NSString *fieldValue = [js GetAsPDFText];
            BOOL isDate = ([fieldValue rangeOfString:@"AFDate"].location != NSNotFound);
            NSString *stringToFind = isDate ? @"AFDate_Keystroke" : @"AFTime_Keystroke";
            NSRange dateFormatRange = [fieldValue rangeOfString:stringToFind];
            if (dateFormatRange.location != NSNotFound) {
                NSString *dateFormatString = [fieldValue substringFromIndex:dateFormatRange.location+dateFormatRange.length];
                NSUInteger firstQuoteIndex = [dateFormatString rangeOfString:@"\""].location;
                // Extract format information
                if (firstQuoteIndex != NSNotFound) {
                    dateFormatString = [dateFormatString substringFromIndex:firstQuoteIndex+1];
                    NSUInteger secondQuoteIndex = [dateFormatString rangeOfString:@"\""].location;
                    if (secondQuoteIndex != NSNotFound) {
                        dateFormatString = [dateFormatString substringToIndex:secondQuoteIndex];
                        // Convert PDF date (AFDate) formats to ISO
                        dateFormatString = [dateFormatString stringByReplacingOccurrencesOfString:@"tt" withString:@"a"];
                        if (isDate) {
                            dateFormatString = [dateFormatString stringByReplacingOccurrencesOfString:@"YYYY" withString:@"yyyy"];
                            dateFormatString = [dateFormatString stringByReplacingOccurrencesOfString:@"DD" withString:@"dd"];
                            dateFormatString = [dateFormatString stringByReplacingOccurrencesOfString:@"m" withString:@"M"];
                        }else{
                            dateFormatString = [dateFormatString stringByReplacingOccurrencesOfString:@"M" withString:@"m"];
                        }
                        return dateFormatString;
                    }
                }
            }
        }
    }
    return nil;
}

-(UIColor*)getWidgetBackgroundColor:(PTAnnot*)annot
{
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        
        PTObj* o =[[annot GetSDFObj] FindObj:@"MK"];
        
        if(o)
        {
            PTObj* bgc = [o FindObj:@"BG"];
            
            if( bgc && [bgc IsArray] )
            {
                int sz = (int)[bgc Size];
                
                switch (sz) {
                    case 1:
                    {
                        PTObj* n = [bgc GetAt:0];
                        if( [n IsNumber] )
                        {
                            return [UIColor colorWithRed:[n GetNumber] green:[n GetNumber] blue:[n GetNumber] alpha:1.0];
                        }
                        break;
                    }
                    case 3:
                    {
                        PTObj* r = [bgc GetAt:0];
                        PTObj* g = [bgc GetAt:1];
                        PTObj* b = [bgc GetAt:2];
                        
                        if( [r IsNumber] && [g IsNumber] && [b IsNumber])
                        {
                            return [UIColor colorWithRed:[r GetNumber] green:[g GetNumber] blue:[b GetNumber] alpha:1.0];
                        }
                        break;
                    }
                    case 4:
                    {
                        PTObj* c = [bgc GetAt:0];
                        PTObj* m = [bgc GetAt:1];
                        PTObj* y = [bgc GetAt:2];
                        PTObj* k = [bgc GetAt:3];
                        
                        if( [c IsNumber] && [m IsNumber] && [y IsNumber] && [k IsNumber])
                        {
                            PTColorPt* cp = [[PTColorPt alloc] initWithX:[c GetNumber] y:[m GetNumber] z:[y GetNumber] w:[k GetNumber]];
                            
                            PTColorSpace* cs = [PTColorSpace CreateDeviceCMYK];
                            PTColorPt* cp_rgb = [cs Convert2RGB:cp];
                            
                            return [UIColor colorWithRed:[cp_rgb Get:0] green:[cp_rgb Get:1] blue:[cp_rgb Get:2] alpha:1.0];
                        }
                        break;
                    }
                    default:
                        break;
                }
            }
            
        }
        
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    return [UIColor whiteColor];
    
    
}

- (BOOL)fillForm:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
    
    [self deselectAnnotation];

    if (self.currentAnnotation) {
        [self deselectAnnotation];
        [self.pdfViewCtrl setNeedsDisplay];
    }
    
    @try {
        [self.pdfViewCtrl DocLockRead];
        
        self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y
                                                 distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD
                                                 minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
        
        self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    if ([self.currentAnnotation IsValid]) {
        return [self selectAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    }
    else {
        self.currentAnnotation = nil;
        self.annotationPageNumber = 0;
    }
    
    self.nextToolType = [PTPanTool class];
    return NO;
}


// used to limit number of characters that can be entered
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    if( string.length == 0 )
    {
        // user is deleting characters
        return YES;
    }
    
    NSString* str = textField.text;
    UITextRange *selRange = textField.selectedTextRange;
    UITextPosition *selStart = selRange.start;
    UITextPosition *selEnd = selRange.end;
    originalRange = selRange;
    NSInteger start = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selStart];
    NSInteger end = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selEnd];
    originalText = str;
    selectionStart = start;
    selectionEnd = end;
    
    BOOL isInCharacterLimit = YES;
    if( characterLimit >= 0 ) {
        isInCharacterLimit = !((textField.text).length > characterLimit && string.length > range.length);
    }
    
    if (!isInCharacterLimit) {
        return NO;
    }
    

    if( self.fieldType == PTTextFormFieldTypeNumeric )
    {

        NSMutableCharacterSet* nonNumbers = [[[NSCharacterSet decimalDigitCharacterSet] invertedSet] mutableCopy];
        [nonNumbers removeCharactersInString:@"., "];
        NSRange r = [string rangeOfCharacterFromSet:nonNumbers];
        if( (r.location == NSNotFound && string.length > 0) == NO)
        {
            return NO;
        }
    }
    
    if (self.textFieldContentsFitBounds) {
        NSString *proposedString = [str stringByReplacingCharactersInRange:range
                                                                withString:string];
        
        // Calculate the drawn size of the string, using the text field's font.
        CGSize size = [proposedString sizeWithAttributes:@{
            NSFontAttributeName: textField.font,
        }];
        // Raise fractional sizes to the nearest higher integer, as per documentation.
        size.width = ceil(size.width);
        size.height = ceil(size.height);
        
        // Reject the proposed change if it would exceed the text field's width.
        if (size.width > CGRectGetWidth(textField.bounds)) {
            return NO;
        }
    }
    
    return YES;
}

// used to limit number of characters that can be entered
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    if( text.length == 0 )
    {
        // user is deleting characters
        return YES;
    }
    
    NSString* str = textView.text;
    UITextRange *selRange = textView.selectedTextRange;
    UITextPosition *selStart = selRange.start;
    UITextPosition *selEnd = selRange.end;
    originalRange = selRange;
    NSInteger start = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selStart];
    NSInteger end = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selEnd];
    originalText = str;
    selectionStart = start;
    selectionEnd = end;

    BOOL isInCharacterLimit = YES;
    if( characterLimit >= 0 )
        isInCharacterLimit = !((textView.text).length > characterLimit && text.length > range.length);

    if (!isInCharacterLimit) {
        return NO;
    }
    
    if( self.fieldType == PTTextFormFieldTypeNumeric )
    {

        NSMutableCharacterSet* nonNumbers = [[[NSCharacterSet decimalDigitCharacterSet] invertedSet] mutableCopy];
        [nonNumbers removeCharactersInString:@"., "];
        NSRange r = [text rangeOfCharacterFromSet:nonNumbers];
        if( (r.location == NSNotFound && text.length > 0) == NO)
        {
            return NO;
        }
    }
    
    if (self.textFieldContentsFitBounds) {
        // The proposed text string for the text view.
        NSString *proposedString = [str stringByReplacingCharactersInRange:range
                                                                withString:text];
        // Create a text storage object with the proposed string.
        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:proposedString];
        
        // Remove the text view's inset around its text container, to get the text container bounds.
        CGRect insetTextContainerBounds = UIEdgeInsetsInsetRect(textView.bounds,
                                                                textView.textContainerInset);
        // Match the width of the text view's text container, but set the height to a huge value to
        // avoid placing any height constraints on the laid-out (proposed) text.
        CGSize textContainerSize = CGSizeMake(CGRectGetWidth(insetTextContainerBounds),
                                              CGFLOAT_MAX);
        // Create a text container with the calculated size, and a layout manager to handle the text
        // layout.
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:textContainerSize];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        
        // Hook up the text storage, container, and layout manager.
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        
        // Add the text view's font as an attribute to the text storage.
        // This is the minimum required set of attributes to calculate the proposed text rect/size.
        NSDictionary<NSAttributedStringKey, id> *attributes = @{
            NSFontAttributeName: textView.font,
        };
        [textStorage addAttributes:attributes
                             range:NSMakeRange(0, textStorage.length)];
        
        // Add the line fragment padding for the beginning and end of each line.
        textContainer.lineFragmentPadding = textView.textContainer.lineFragmentPadding;
        
        // Force layout manager to layout the text. Return value is ignored.
        (void)[layoutManager glyphRangeForTextContainer:textContainer];
        // Ask the layout manager for the rect of the laid-out text.
        CGRect proposedUsedRect = [layoutManager usedRectForTextContainer:textContainer];
        
        CGSize oneLineHeight = [@"|" sizeWithAttributes:@{
            NSFontAttributeName: textView.font,
        }];
        
        // Would the proposed text exceed the height of the text view (container)?
        if (CGRectGetHeight(proposedUsedRect)-oneLineHeight.height*0.03 > CGRectGetHeight(insetTextContainerBounds)) {
            return NO;
        }
    }
    
    return YES;
}

-(void)datePickerDidChange:(UIDatePicker*)datePicker
{
    NSString *dateString = [self dateStringFromDatePicker:datePicker];
    if (dateString) {
        activeTextField.text = dateString;
    }
}

-(NSString*)dateStringFromDatePicker:(UIDatePicker*)datePicker
{
    UIDatePickerMode datePickerMode = datePicker.datePickerMode;
    if (dateFormatter.dateFormat == nil) {
        dateFormatter.dateStyle = (datePickerMode == UIDatePickerModeDate) ? NSDateFormatterShortStyle : NSDateFormatterNoStyle;
        dateFormatter.timeStyle = (datePickerMode == UIDatePickerModeTime) ? NSDateFormatterShortStyle : NSDateFormatterNoStyle;
    }
    return [dateFormatter stringFromDate:datePicker.date];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.nextToolType = [PTPanTool class];
    return NO;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    return [self fillForm:gestureRecognizer];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if( gestureRecognizer.state == UIGestureRecognizerStateBegan )
    {
        return [self fillForm:gestureRecognizer];
    }
    
    return YES;
}


-(void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl*)pdfViewCtrl
{
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        
        PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];
        
        if( ![self.currentAnnotation IsValid] || annotType != PTExtendedAnnotTypeWidget )
        {
            return;
        }
        
        
        PTPDFRect* rect = [self.currentAnnotation GetRect];
        
        CGRect annnot_rect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
        
        annnot_rect.origin.x = annnot_rect.origin.x + [self.pdfViewCtrl GetHScrollPos];
        annnot_rect.origin.y = annnot_rect.origin.y + [self.pdfViewCtrl GetVScrollPos];
        
        if( annotType == PTExtendedAnnotTypeWidget )
        {
            if( responder && responder.subviews.count > 0)
            {
                responder.frame = annnot_rect;
                responder.subviews[0].frame = CGRectMake(0, 0, annnot_rect.size.width, annnot_rect.size.height);
                
                PTWidget* wg4 = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
                PTField* f = [wg4 GetField];
                PTGState* gs = [f GetDefaultAppearance];
                
                // responder is a UIScrollView and its only subview is the actual widget, a UITextView or UITextField
                
                int fontSize = [gs GetFontSize];
                
                if( fontSize == 0 )
                {
                    if( [responder isKindOfClass:[UITextView class]] )
                    {
                        UITextView* tempView = [[UITextView alloc] init];
                        
                        fontSize  = tempView.font.pointSize;
                    }
                    else
                    {
                        UITextField* tempView = [[UITextField alloc] init];
                        
                        fontSize  = tempView.font.pointSize;
                    }
                }
                
                [[[responder subviews] objectAtIndex:0] setFont:[UIFont fontWithName:@"Helvetica" size:fontSize*[self.pdfViewCtrl GetZoom]]];
                
            }
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
}

- (void)pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
    TrnPagePresentationMode mode = [self.pdfViewCtrl GetPagePresentationMode];
    if( mode == e_ptsingle_page || mode == e_ptfacing || mode == e_ptfacing_cover )
    {
        if(responder)
        {
            [responder endEditing:NO];
        }
        [responder removeFromSuperview];
        responder = nil;
    }
    [super pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:oldPageNumber To:newPageNumber];
    
    if( mode == e_ptsingle_page || mode == e_ptfacing || mode == e_ptfacing_cover )
    {
        self.nextToolType = [PTPanTool class];
        [self.toolManager createSwitchToolEvent:nil];
    }
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    return NO;
}

#pragma mark - Form Filling

-(int)GetOptionIndexStr:(PTObj*)str_val Opt:(PTObj*)opt
{
    if( ![str_val IsString] ) return -1;
    if( ![opt IsArray] ) return -1;
    
    unsigned long sz = [opt Size];
    
    for( int i =0; i < sz; ++i )
    {
        PTObj* v = [opt GetAt:i];
        
        if( [v IsString] && [str_val Size] == [v Size] )
        {
            if( !memcmp([str_val GetBuffer].bytes, [v GetBuffer].bytes, [v Size]))
            {
                return i;
            }
        }
        else if( [v IsArray] && [v Size] >=2 && [[v GetAt:1] IsString] && [str_val Size] == [[v GetAt:1] Size])
        {
            v = [v GetAt:1];
            
            if( !memcmp([str_val GetBuffer].bytes, [v GetBuffer].bytes, (int)[v Size]) )
            {
                return i;
            }
        }
    }
    
    return -1;
}

-(NSMutableArray*)choiceFromGetSelectedItemsInActiveListbox:(PTChoiceFormViewController*)choiceFormViewController
{
    PTWidget* wg4 = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
    PTField* f = [wg4 GetField];
    
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:10];
    
    if( ![f IsValid] )
        return arr;
    
    PTObj* val = [f GetValue];
    
    if( [val IsString] )
    {
        PTObj* o = [[self.currentAnnotation GetSDFObj] FindObj:@"Opt"];
        if( !o )
            return arr;
        
        [arr addObject:@([self GetOptionIndexStr:val Opt:o])];
    }
    else if( [val IsArray] )
    {
        int sz = (int)[val Size];
        for(int i = 0;i < sz;i++)
        {
            PTObj* entry = [val GetAt:i];
            PTObj* o = [[self.currentAnnotation GetSDFObj] FindObj:@"Opt"];
            if( !o )
                return arr;
            
            [arr addObject:@([self GetOptionIndexStr:entry Opt:o])];
        }
    }
    
    return arr;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger num = [indexPath indexAtPosition:1];
    
    PTWidget* wg4;
    PTField* f;
    
    @try {
        [self.pdfViewCtrl DocLockRead];
        wg4 = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
        f = [wg4 GetField];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }

    // combo box and single selection list
    if( !([self.pt_viewController isMemberOfClass:[PTChoiceFormViewController class]] && ((PTChoiceFormViewController*)self.pt_viewController).isMultiSelect) )
    {
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            PTViewChangeCollection* view_change = [f SetValueWithString:choices[num]];
            [self.pdfViewCtrl RefreshAndUpdate:view_change];
            [self formFieldDataModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
        
        [self.pdfViewCtrl UpdateWithField:f];
		
		[self.pt_viewController dismissViewControllerAnimated:YES completion:nil]; // iOS 5
        
        //change back to default pan tool.
        self.nextToolType = [PTPanTool class];
        [self.toolManager createSwitchToolEvent:nil];
        
    }
    else
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
        [tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
        if( [tableView cellForRowAtIndexPath:indexPath].accessoryType != UITableViewCellAccessoryCheckmark )
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        else
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
    }
}

-(void)keyboardWillShow:(NSNotification *)notification
{
    [self.pdfViewCtrl keyboardWillShow:notification rectToNotOverlapWith:self.fontRect];
    
    keyboardOnScreen = true;
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [self.pdfViewCtrl keyboardWillHide:notification];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    keyboardOnScreen = false;
    
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Dismiss virtual keyboard.
    [textField resignFirstResponder];
    return NO;
}

- (void)didEndEditing:(UIView *)view
{
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        
        PTWidget* wg4 = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
        PTField* f = [wg4 GetField];
        NSString* textString;
        
        //view will be a textView or a textField so warnings here are not applicable
        if( [view isKindOfClass:[UITextView class]] )
        {
            textString = ((UITextView*)view).text;
        }
        else if( [view isKindOfClass:[UITextField class]] )
        {
            textString = ((UITextField*)view).text;
        }
        else
        {
            textString = @"";
        }
        
        // no need to refresh if string hasn't changed value
        BOOL changed = ![[f GetValueAsString] isEqualToString:textString];
        if (changed) {
            PTViewChangeCollection* view_change = [f SetValueWithString:textString];
            [self.pdfViewCtrl RefreshAndUpdate:view_change];
        }

        // Apply text view appearance.
        if ([view isKindOfClass:[UITextView class]] && self.useTextViewAppearance) {
            [self applyAppearanceOfTextView:((UITextView *)view)];
            [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation
                                     page_num:self.annotationPageNumber];
        }
        
        if (changed) {
            [self formFieldDataModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        }
        
        [self executeActionWithAnnotIfAvailable:self.currentAnnotation Type:e_ptaction_trigger_annot_blur];
        
        [responder removeFromSuperview];
        responder = nil;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
}

- (void)applyAppearanceOfTextView:(UITextView *)textView
{
    PTRotate viewRotation = self.pdfViewCtrl.rotation;
    PTRotate pageRotation = e_pt0;
    
    BOOL shouldUnlock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        PTPage *page = [doc GetPage:self.annotationPageNumber];
        if ([page IsValid]) {
            pageRotation = [page GetRotation];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        pageRotation = e_pt0;
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    PTRotate rotation = (pageRotation + viewRotation) % 4;
    
    CGFloat appearanceRectWidth = CGRectGetWidth(textView.bounds);
    CGFloat appearanceRectHeight = CGRectGetHeight(textView.bounds);
    
    if (rotation == e_pt90 || rotation == e_pt270) {
        CGFloat temp = appearanceRectWidth;
        appearanceRectWidth = appearanceRectHeight;
        appearanceRectHeight = temp;
    }
    
    // Render only the top portion of the text view (if its contents exceed its bounds' height).
    CGRect appearanceRect = CGRectMake(0, 0, appearanceRectWidth, appearanceRectHeight);
    
    // Create a text storage object with the text view's string.
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:textView.text];

    // Remove the text view's inset around its text container, to get the text container bounds.
    CGRect insetTextContainerBounds = UIEdgeInsetsInsetRect(textView.bounds,
                                                            textView.textContainerInset);
    // Rotate the text container rect.
    if (rotation == e_pt90 || rotation == e_pt270) {
        CGPoint origin = insetTextContainerBounds.origin;
        insetTextContainerBounds = CGRectApplyAffineTransform(insetTextContainerBounds,
                                                              CGAffineTransformMakeRotation(M_PI_2));
        insetTextContainerBounds.origin = origin;
    }
    
    // Match the width of the text view's text container, but set the height to a huge value to
    // avoid placing any height constraints on the laid-out (proposed) text.
    CGSize textContainerSize = CGSizeMake(CGRectGetWidth(insetTextContainerBounds),
                                          CGFLOAT_MAX);
    // Create a text container with the calculated size, and a layout manager to handle the text
    // layout.
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:textContainerSize];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    layoutManager.delegate = textView.layoutManager.delegate;
    
    // Hook up the text storage, container, and layout manager.
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    // Add the text view's font as an attribute to the text storage.
    // This is the minimum required set of attributes to calculate the proposed text rect/size.
    NSDictionary<NSAttributedStringKey, id> *attributes = @{
        NSFontAttributeName: textView.font,
    };
    [textStorage addAttributes:attributes
                         range:NSMakeRange(0, textStorage.length)];
    
    // Add the line fragment padding for the beginning and end of each line.
    textContainer.lineFragmentPadding = textView.textContainer.lineFragmentPadding;
    
    NSMutableData *pdfData = [NSMutableData data];
    
    UIGraphicsBeginPDFContextToData(pdfData, appearanceRect, nil);
    UIGraphicsBeginPDFPage();
    
    // Get the glyph range for the appearance rect.
    CGRect glyphBoundingRect = insetTextContainerBounds;
    NSRange glyphRange = [layoutManager glyphRangeForBoundingRect:glyphBoundingRect
                                                           inTextContainer:textContainer];
    // Draw the text view's glyphs into the PDF context.
    [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:CGPointZero];
    
    UIGraphicsEndPDFContext();
    
    @try {
        PTPDFDoc *doc = [[PTPDFDoc alloc] initWithBuf:pdfData buf_size:pdfData.length];
        [self setCustomWidgetAppearanceWithDoc:doc];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
}

- (void)setCustomWidgetAppearanceWithDoc:(PTPDFDoc *)appearanceDoc
{
    @try {
        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        
        PTWidget *widget = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
        
        PTPage *page = [appearanceDoc GetPage:1];
        if (![page IsValid]) {
            return;
        }
        PTObj *contents = [page GetContents];
        PTObj *importedContents = [[doc GetSDFDoc] ImportObj:contents deep_copy:YES];
        PTPDFRect *bbox = [page GetMediaBox];
        [importedContents PutRect:@"BBox"
                               x1:[bbox GetX1] y1:[bbox GetY1] x2:[bbox GetX2] y2:[bbox GetY2]];
        [importedContents PutName:@"Subtype" name:@"Form"];
        [importedContents PutName:@"Type" name:@"XObject"];
        
        PTObj *res = [page GetResourceDict];
        if ([res IsValid]) {
            PTObj *importedRes = [[doc GetSDFDoc] ImportObj:res deep_copy:YES];
            [importedContents Put:@"Resources" obj:importedRes];
        }
        
        [widget SetAppearance:importedContents annot_state:e_ptnormal app_state:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self didEndEditing:textView];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (activeTextField == textField) {
        activeTextField = nil;
    }
    [self didEndEditing:textField];
}

-(NSInteger)choiceFormNumberOfChoices:(PTChoiceFormViewController*)choiceFormViewController
{
    [choices removeAllObjects];
    
    if( choices == 0 )
        choices =  [[NSMutableArray alloc] initWithCapacity:10];
    
    PTWidget* wg4 = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
    PTField* f = [wg4 GetField];
    
    NSInteger total = [f GetOptCount];
    
    for(int i = 0; i < total; i++)
    {
        NSString* option = [f GetOpt:i];
        
        if( option == Nil )
        {
            option = @"";
        }
        
        [choices addObject:option];
        
    }
    
    return total;
}

-(NSString*)choiceForm:(PTChoiceFormViewController*)choiceFormViewController titleOfChoiceAtIndex:(NSUInteger)num
{
    return choices[num];
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
    if ([presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
        [self popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)presentationController];
    }
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{

								  
    // only relevant for multiselect
    if( ([popoverPresentationController.presentedViewController isMemberOfClass:[PTChoiceFormViewController class]] && ((PTChoiceFormViewController*)popoverPresentationController.presentedViewController).isMultiSelect) )
    {
        
        UITableView* tv = ((UITableView*)(self.pt_viewController.presentedViewController.view));
        
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            PTWidget* wg4 = [[PTWidget alloc] initWithAnn:self.currentAnnotation];
            PTField* f = [wg4 GetField];
            
            PTObj* arr = [[self.pdfViewCtrl GetDoc] CreateIndirectArray];
            
            for (int i = 0; i < [tv numberOfRowsInSection:0]; ++i)
            {
                
                if( [tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].accessoryType == UITableViewCellAccessoryCheckmark )
                {
                    NSString* str = choices[i];
                    [arr PushBackText:str];
                }
            }
            
            PTViewChangeCollection* view_change = [f SetValueWithObj:arr];
            
            [self.pdfViewCtrl RefreshAndUpdate:view_change];
            [self formFieldDataModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    self.nextToolType = [PTPanTool class];
    [self.toolManager createSwitchToolEvent:nil];
    
}

-(BOOL)moveToNextField
{
    return [self selectNextFieldAfterAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

-(BOOL)moveToPreviousField
{
    return [self selectPreviousFieldBeforeAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

#pragma mark - <PTFormFillInputAccessoryViewDelegate>

- (void)formFillInputAccessoryView:(PTFormFillInputAccessoryView *)formFillInputAccesoryView didPressPreviousButtonItem:(UIBarButtonItem *)item
{
    [self selectPreviousFieldBeforeAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

- (void)formFillInputAccessoryView:(PTFormFillInputAccessoryView *)formFillInputAccesoryView didPressNextButtonItem:(UIBarButtonItem *)item
{
    [self selectNextFieldAfterAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

- (void)formFillInputAccessoryView:(PTFormFillInputAccessoryView *)formFillInputAccesoryView didPressDoneButtonItem:(UIBarButtonItem *)item
{
    if( [formFillInputAccesoryView.inputView isKindOfClass:[UIDatePicker class]] ) {
        NSString *dateString = [self dateStringFromDatePicker:(UIDatePicker*)formFillInputAccesoryView.inputView];
        if (dateString) {
            activeTextField.text = dateString;
        }
    }
    // Hide virtual keyboard.
    BOOL editingEnded = [responder endEditing:NO];
    if (!editingEnded) {
        [responder endEditing:YES];
    }
}


@end
