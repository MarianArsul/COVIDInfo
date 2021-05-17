//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTFreeTextInputAccessoryView.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "PTColorPickerViewController.h"
#import "PTFreeTextCreate.h"
#import "PTAnnotEditTool.h"
#import "PTAnnotStyle.h"
#import "PTAnnotationStyleManager.h"
#import "PTColorDefaults.h"
#import "UIView+PTAdditions.h"
#import "PTTool.h"
#import "PTToolsUtil.h"
#import "PTKeyValueObserving.h"

@interface PTFreeTextInputAccessoryView () <UIFontPickerViewControllerDelegate, UIPopoverPresentationControllerDelegate, PTAnnotStyleDelegate, PTColorPickerViewControllerDelegate>


@property (nonatomic, strong) PTAnnotStyle *annotStyle;
@property (nonatomic, strong) UIStepper *fontSizeStepper;
@property (nonatomic, strong) UILabel *fontSizeLabel;
@property (nonatomic, strong) UIButton *fontSizeButton;
@property (nonatomic, strong) UIButton *fontColorButton;
@property (nonatomic, strong) UIStackView *fontSizeStackView;
@property (nonatomic, strong) PTAnnotationStylePresetsGroup * annotStylePresets;
@end

@implementation PTFreeTextInputAccessoryView

- (instancetype)initWithToolManager:(PTToolManager *)toolManager textView:(nonnull UITextView *)textView
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _toolManager = toolManager;
        _textView = textView;
        PTTool *tool = _toolManager.tool;
        const PTExtendedAnnotType annotType = tool.annotType;
        if (annotType != PTExtendedAnnotTypeUnknown) {
            NSString *identifier = tool.identifier;
            self.annotStylePresets = [PTAnnotationStyleManager.defaultManager stylePresetsForAnnotationType:annotType identifier:identifier];
            _annotStyle = self.annotStylePresets.selectedStyle;
        }else{
            if (_toolManager.tool.currentAnnotation != nil) {
                _annotStyle = [[PTAnnotStyle alloc] initWithAnnot:_toolManager.tool.currentAnnotation];
                _annotStyle.delegate = self;
            }
        }

        _fontPickerButtonItem = [[UIBarButtonItem alloc] initWithTitle:_annotStyle.fontName style:UIBarButtonItemStylePlain target:self action:@selector(showFontPicker:)];
        _fontColorButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.fontColorButton];
        _fontSizeButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%.0fpt", self.annotStyle.textSize] style:UIBarButtonItemStylePlain target:self action:@selector(fontSizeButtonTapped:)];
        _fontSizeStepperButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.fontSizeStepper];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss:)];

        NSMutableArray *defaultItems = [NSMutableArray array];
        if (@available(iOS 13.0, *)) {
            if (self.fontPickerButtonItem != nil) {
                [defaultItems addObject:self.fontPickerButtonItem];
            }
        }
        [defaultItems addObjectsFromArray:@[[UIBarButtonItem pt_flexibleSpaceItem], self.fontColorButtonItem, [UIBarButtonItem pt_fixedSpaceItemWithWidth:15], self.fontSizeButtonItem, self.fontSizeStepperButtonItem, doneButton]];
        self.items = [defaultItems copy];
    }
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (@available(iOS 11.0, *)) {

        if( self.window )
        {
            [self.bottomAnchor constraintLessThanOrEqualToSystemSpacingBelowAnchor:self.window.safeAreaLayoutGuide.bottomAnchor multiplier:1.0].active = YES;
        }
    }
}


- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    [self updateUI];
}

- (UIButton *)fontColorButton
{
    if (!_fontColorButton) {
        _fontColorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fontColorButton addTarget:self
                            action:@selector(showColorPicker:)
         forControlEvents:UIControlEventPrimaryActionTriggered];
        UIImage *image;
        if (@available(iOS 13.0, *)) {
            image = [UIImage systemImageNamed:@"circle.fill"];
        }else{
            image = [PTToolsUtil toolImageNamed:@"ic_circle_black_24dp"];
        }

        [_fontColorButton setImage:image forState:UIControlStateNormal];
        [_fontColorButton.imageView setTintColor:self.annotStyle.textColor];
    }
    return _fontColorButton;
}

- (UIStepper *)fontSizeStepper
{
    if (!_fontSizeStepper) {
        _fontSizeStepper = [[UIStepper alloc] init];
        _fontSizeStepper.value = self.annotStyle.textSize;
        _fontSizeStepper.minimumValue = 1;
        [_fontSizeStepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _fontSizeStepper;
}

-(void)stepperValueChanged:(UIStepper*)stepper
{
    self.annotStyle.textSize = (int)stepper.value;
}

-(void)fontSizeButtonTapped:(UIBarButtonItem*)sender
{
    

}

#pragma mark - UI

- (void)setItems:(NSArray<UIBarButtonItem *> *)items
{
    [super setItems:items];
    [self sizeToFit];
}

- (void)updateUI
{
    UIFont *font = [UIFont fontWithName:self.annotStyle.fontName size:self.annotStyle.textSize*[self.toolManager.pdfViewCtrl GetZoom]];
    self.textView.font = font;
    self.textView.textColor = self.annotStyle.textColor;

    if (@available(iOS 13.0, *)) {
        if (self.fontPickerButtonItem != nil) {
            NSString *buttonString = font.familyName;
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone || self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) {
                // Truncate string if it's longer than 12 chars on compact screens
                NSRange stringRange = {0, MIN([font.familyName length], 12)};
                stringRange = [font.familyName rangeOfComposedCharacterSequencesForRange:stringRange];
                buttonString = [font.familyName substringWithRange:stringRange];
                if (buttonString.length < font.familyName.length) {
                    buttonString = [buttonString stringByAppendingString:@"…"];
                }
            }
            self.fontPickerButtonItem.title = buttonString;
        }
    }
    self.fontSizeButtonItem.title = [NSString stringWithFormat:@"%.0fpt", self.annotStyle.textSize];
    self.fontSizeStepper.value = self.annotStyle.textSize;
    [self.fontColorButton.imageView setTintColor:self.annotStyle.textColor];
}

- (void)showFontPicker:(UIBarButtonItem*)sender
{
    if (@available(iOS 13.0, *)) {
        UIFontPickerViewControllerConfiguration *config = [[UIFontPickerViewControllerConfiguration alloc] init];
        config.includeFaces = YES;

        UIFontPickerViewController *fpvc = [[UIFontPickerViewController alloc] initWithConfiguration:config];
        fpvc.selectedFontDescriptor = [UIFontDescriptor fontDescriptorWithName:self.annotStyle.fontName size:self.annotStyle.textSize];
        fpvc.delegate = self;
        fpvc.title = PTLocalizedString(@"Choose Font", @"Choose Font title");

        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:fpvc];
        navVC.modalPresentationStyle = UIModalPresentationPopover;
        navVC.popoverPresentationController.barButtonItem = sender;
        navVC.popoverPresentationController.delegate = self;

        [self.pt_viewController presentViewController:navVC animated:YES completion:nil];
    }
}

- (void)showColorPicker:(UIButton*)sender
{
    PTColorPickerViewController *cpvc = [[PTColorPickerViewController alloc]
                                         initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                         navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                         options:nil
                                         colors:nil];
    cpvc.colorPickerDelegate = self;
    cpvc.color = self.annotStyle.textColor;
    cpvc.title = PTLocalizedString(@"Text Color", @"");
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:cpvc];
    navVC.modalPresentationStyle = UIModalPresentationPopover;
    navVC.popoverPresentationController.barButtonItem = self.fontColorButtonItem;
    navVC.popoverPresentationController.delegate = self;

    [self.pt_viewController presentViewController:navVC animated:YES completion:nil];
}

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}

- (void)dismiss:(UIBarButtonItem*)sender
{
    if(!self.textView || [self.textView.text isEqualToString:@""]){
        if( self.textView != nil )
        {
            [self.textView resignFirstResponder];
        }

        if( self.toolManager.tool.backToPanToolAfterUse )
        {
            self.toolManager.tool.nextToolType = [self.toolManager.tool.defaultClass class];
        }
        return;
    }
    if ([self.toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
        [self.toolManager.tool performSelector:@selector(commitAnnotation)];
    }
    [self.textView resignFirstResponder];
    if ([self.toolManager.tool respondsToSelector:@selector(deselectAnnotation)]) {
        [self.toolManager.tool performSelector:@selector(deselectAnnotation)];
    }

    [self.toolManager changeTool:self.toolManager.tool.defaultClass];
}

#pragma mark - <UIFontPickerViewControllerDelegate>

- (void)fontPickerViewControllerDidPickFont:(UIFontPickerViewController *)viewController
API_AVAILABLE(ios(13.0)){
    self.annotStyle.fontName = viewController.selectedFontDescriptor.postscriptName;
    [viewController.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <PTColorPickerViewControllerDelegate>
- (void)colorPickerController:(PTColorPickerViewController *)colorPickerController didSelectColor:(UIColor *)color
{
    self.annotStyle.textColor = color;
    [colorPickerController.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <PTAnnotationStylePresetsGroup>

- (void)setAnnotStylePresets:(PTAnnotationStylePresetsGroup *)annotStylePresets
{
    if (annotStylePresets == _annotStylePresets) {
        return;
    }

    PTAnnotationStylePresetsGroup *previousPresets = _annotStylePresets;
    _annotStylePresets = annotStylePresets;

    [self endObservingAnnotationStylePresets:previousPresets];
    [self beginObservingAnnotationStylePresets:annotStylePresets];
}

- (void)beginObservingAnnotationStylePresets:(PTAnnotationStylePresetsGroup *)presets
{
    if (!presets) {
        return;
    }

    [self pt_observeObject:presets
                forKeyPath:PT_KEY(presets, selectedStyle)
                  selector:@selector(selectedPresetStyleDidChange:)
                   options:(NSKeyValueObservingOptionPrior)];
    [self pt_observeObject:presets
                forKeyPath:PT_KEY(presets, selectedStyle.fontName)
                  selector:@selector(selectedPresetStyleDidChange:)
                   options:(NSKeyValueObservingOptionPrior)];
    [self pt_observeObject:presets
                forKeyPath:PT_KEY(presets, selectedStyle.textSize)
                  selector:@selector(selectedPresetStyleDidChange:)
                   options:(NSKeyValueObservingOptionPrior)];
    [self pt_observeObject:presets
                forKeyPath:PT_KEY(presets, selectedStyle.textColor)
                  selector:@selector(selectedPresetStyleDidChange:)
                   options:(NSKeyValueObservingOptionPrior)];
}

- (void)selectedPresetStyleDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.annotStylePresets) {
        return;
    }
    
    self.annotStyle = self.annotStylePresets.selectedStyle;
    
    // Update the current annotation, if any, with the updated style.
    [self updateAnnot];
    
    // Always save the selected annotation style as default.
    [self.annotStyle setCurrentValuesAsDefaults];
    
    [self updateUI];
}

- (void)endObservingAnnotationStylePresets:(PTAnnotationStylePresetsGroup *)presets
{
    if (!presets) {
        return;
    }

    [self pt_removeObservationsForObject:presets
                                 keyPath:PT_KEY(presets, selectedStyle)];
}

#pragma mark - PTAnnotStyleDelegate

- (void)annotStyle:(PTAnnotStyle *)annotStyle fontNameDidChange:(NSString *)fontName
{
    [self updateAnnot];
    [self updateUI];
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle textSizeDidChange:(CGFloat)textSize
{
    [self updateAnnot];
    [self updateUI];
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle textColorDidChange:(nonnull UIColor *)textColor
{
    [self updateAnnot];
    [self updateUI];
}

-(void)updateAnnot
{
    PTAnnot *annotation = self.toolManager.tool.currentAnnotation;
    if (!annotation) {
        return;
    }

    PTPDFViewCtrl *pdfViewCtrl = self.toolManager.pdfViewCtrl;

    NSError *error = nil;
    [self.toolManager willModifyAnnotation:annotation onPageNumber:self.toolManager.tool.annotationPageNumber];
    [pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        [self.annotStyle applyToAnnotation:annotation doc:doc];
    } error:&error];
    if (error) {
        NSLog(@"Error updating annotation: %@", error);
    }
    [self.toolManager annotationModified:annotation onPageNumber:self.toolManager.tool.annotationPageNumber];

}

- (void)dealloc
{
    [self pt_removeAllObservations];
}

@end
