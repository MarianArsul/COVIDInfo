//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleToolbar.h"

#import "PTAnnotationStyleManager.h"
#import "PTPanTool.h"
#import "PTAnnotEditTool.h"
#import "PTFreeTextCreate.h" // For commitAnnotation selector.
#import "PTSmartPen.h"
#import "PTToolsUtil.h"
#import "PTToolImages.h"
#import "PTSelectableBarButtonItem.h"
#import "PTSelectableBarButtonItemPrivate.h"
#import "PTAnnotationStyleIndicatorView.h"
#import "PTFreehandCreate.h"
#import "PTFreeHandHighlightCreate.h"
#import "PTPopoverNavigationController.h"

#import "UIBarButtonItem+PTAdditions.h"
#import "UIView+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStyleToolbar ()

@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotStyleToolbar

- (void)PTAnnotStyleToolbar_commonInit
{
    
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _toolManager = toolManager;
        
        [self PTAnnotStyleToolbar_commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTAnnotStyleToolbar_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTAnnotStyleToolbar_commonInit];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        [self beginObservingNotificationsForToolManager:self.toolManager];
    } else {
        [self endObservingNotificationsForToolManager:self.toolManager];
    }
}

#pragma mark - Annot style presets

- (void)setAnnotStylePresets:(PTAnnotationStylePresetsGroup *)annotStylePresets
{
    if (annotStylePresets == _annotStylePresets) {
        // No change.
        return;
    }
    
    _annotStylePresets = annotStylePresets;
    
    [self updateItems];
}

- (void)updateItems
{
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    
    NSUInteger presetIndex = 0;
    for (PTAnnotStyle *preset in self.annotStylePresets.styles) {
        if (presetIndex > 0) {
            [items addObject:[UIBarButtonItem pt_fixedSpaceItemWithWidth:10]];
        }
        
        PTAnnotationStyleIndicatorView *indicator = [[PTAnnotationStyleIndicatorView alloc] init];
        indicator.translatesAutoresizingMaskIntoConstraints = NO;
        
        indicator.disclosureIndicatorEnabled = YES;
        
        const BOOL selected = (preset == self.annotStylePresets.selectedStyle);
        indicator.selected = selected;
        indicator.disclosureIndicatorHidden = !selected;
        
        [indicator addTarget:self
                 action:@selector(presetActivated:)
       forControlEvents:UIControlEventPrimaryActionTriggered];
        
        indicator.style = preset;
        
        UIBarButtonItem *item = [[PTSelectableBarButtonItem alloc] initWithCustomView:indicator];
        item.tag = presetIndex;
        
        item.image = [PTToolImages imageForAnnotationType:preset.annotType];
        
        NSString *localizedFormat = PTLocalizedString(@"%@ Preset %lu",
                                                      @"<Annotation type> Preset <number>");
        item.title = [NSString localizedStringWithFormat:localizedFormat,
                      PTLocalizedAnnotationNameFromType(preset.annotType), (presetIndex + 1)];
        
        [items addObject:item];
        presetIndex++;
    }
    
    [self setItems:[[items copy] arrayByAddingObjectsFromArray:@[
        [UIBarButtonItem pt_flexibleSpaceItem],
        self.closeButtonItem,
    ]] animated:YES];
}

- (void)presetActivated:(id)sender
{
    if ([sender isKindOfClass:[PTAnnotationStyleIndicatorView class]]) {
        PTAnnotationStyleIndicatorView *indicator = (PTAnnotationStyleIndicatorView *)sender;
        
        if (indicator.style == self.annotStylePresets.selectedStyle) {
            [self showStylePickerForAnnotStyle:indicator.style
                                    fromSender:sender];
        } else {
            indicator.selected = YES;
            [indicator setDisclosureIndicatorHidden:NO animated:YES];

            self.annotStylePresets.selectedStyle = indicator.style;
            
            [indicator.style setCurrentValuesAsDefaults];
                        
            for (UIBarButtonItem *item in self.items) {
                PTAnnotationStyleIndicatorView *itemIndicator = nil;
                if ([item.customView isKindOfClass:[PTAnnotationStyleIndicatorView class]]) {
                    itemIndicator = (PTAnnotationStyleIndicatorView *)item.customView;
                }
                else if ([item isKindOfClass:[PTSelectableBarButtonItem class]]) {
                    PTSelectableBarButtonItem *selectableItem = (PTSelectableBarButtonItem *)item;
                    if ([selectableItem.barButtonView.view isKindOfClass:[PTAnnotationStyleIndicatorView class]]) {
                        itemIndicator = (PTAnnotationStyleIndicatorView *)selectableItem.barButtonView.view;
                    }
                }
                if (itemIndicator) {
                    if (itemIndicator.style != self.annotStylePresets.selectedStyle) {
                        itemIndicator.selected = NO;
                        [itemIndicator setDisclosureIndicatorHidden:YES
                                                           animated:YES];
                    }
                }
            }
        }
    }
}

#pragma mark - Close button

- (UIBarButtonItem *)closeButtonItem
{
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = nil;
        if (@available(iOS 13.0, *)) {
            closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                            target:self
                                                                            action:@selector(close:)];
        } else {
            UIImage *closeImage = [PTToolsUtil toolImageNamed:@"ic_ios_cancel_black_24px"];
            
            closeButtonItem = [[UIBarButtonItem alloc] initWithImage:closeImage
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(close:)];
            closeButtonItem.tintColor = UIColor.lightGrayColor;
        }
        
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

- (void)close:(UIBarButtonItem *)item
{
    
    if ([self.toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
        [self.toolManager.tool performSelector:@selector(commitAnnotation)];
    }
    
    [self.toolManager changeTool:[PTPanTool class]];
}

#pragma mark - Tool manager

- (void)setToolManager:(PTToolManager *)toolManager
{
    PTToolManager *previousToolManager = _toolManager;
    _toolManager = toolManager;
    
    if (self.window) {
        [self endObservingNotificationsForToolManager:previousToolManager];
        [self beginObservingNotificationsForToolManager:toolManager];
    }
}

- (void)beginObservingNotificationsForToolManager:(PTToolManager *)toolManager
{
    if (!toolManager) {
        return;
    }
        
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerToolDidChangeWithNotification:)
                                               name:PTToolManagerToolDidChangeNotification
                                             object:toolManager];
}

- (void)endObservingNotificationsForToolManager:(PTToolManager *)toolManager
{
    if (!toolManager) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTToolManagerToolDidChangeNotification
                                                object:toolManager];
}

#pragma mark Notifications

- (void)toolManagerToolDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self dismissStylePicker];
}

#pragma mark - Annotation style picker

- (void)showStylePickerForAnnotStyle:(PTAnnotStyle *)annotStyle fromSender:(id)sender
{
    [self dismissStylePicker];
    
    PTTool *tool = self.toolManager.tool;
    if ([tool isKindOfClass:[PTSmartPen class]]) {
        [((PTSmartPen *)tool) editAnnotationStyle:sender];
        return;
    }
    
    // Commit freehand ink annotations before editing style.
    if (tool.identifier
        && [tool isKindOfClass:[PTFreeHandCreate class]]
        && ![tool isKindOfClass:[PTFreeHandHighlightCreate class]]) {
        PTFreeHandCreate *freehandTool = (PTFreeHandCreate *)tool;
        
        [freehandTool commitAnnotation];
    }
    
    self.stylePicker = [[PTAnnotStyleViewController alloc] initWithToolManager:self.toolManager
                                                                    annotStyle:annotStyle];
    self.stylePicker.delegate = self;
    
    PTPopoverNavigationController *navigationController = [[PTPopoverNavigationController allocOverridden] initWithRootViewController:self.stylePicker];
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
        navigationController.presentationManager.popoverBarButtonItem = barButtonItem;
    } else if ([sender isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)sender;
        navigationController.presentationManager.popoverSourceView = view;
    }
    [self.pt_viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)dismissStylePicker
{
    [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
    self.stylePicker = nil;
}

#pragma mark <PTAnnotStyleViewControllerDelegate>

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didChangeStyle:(PTAnnotStyle *)annotStyle
{
    if (annotStyleViewController != self.stylePicker) {
        return;
    }
    
    [annotStyle setCurrentValuesAsDefaults];
}

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didCommitStyle:(PTAnnotStyle *)annotStyle
{
    if (annotStyleViewController != self.stylePicker) {
        return;
    }
    
    [annotStyle setCurrentValuesAsDefaults];
        
    [self dismissStylePicker];
}

@end
