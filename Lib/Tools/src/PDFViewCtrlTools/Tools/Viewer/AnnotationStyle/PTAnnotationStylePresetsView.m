//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationStylePresetsView.h"

#import "PTAnnotationStyleIndicatorView.h"
#import "PTKeyValueObserving.h"
#import "PTSelectableBarButtonItem.h"
#import "PTToolImages.h"
#import "PTToolbarContentView.h"
#import "PTToolsUtil.h"

#import "NSLayoutConstraint+PTPriority.h"
#import "UIBarButtonItem+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationStylePresetsView ()

@property (nonatomic, readwrite, strong) UIView *contentView;

@property (nonatomic) UIView *backgroundView;

@property (nonatomic) BOOL constraintsLoaded;

@property (nonatomic, strong, nullable) NSArray<PTAnnotationStyleIndicatorView *> *indicators;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotationStylePresetsView

- (void)PTAnnotationStylePresetsView_commonInit
{
    _backgroundView = ({
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                 UIViewAutoresizingFlexibleHeight);
                
        (view);
    });
    [self addSubview:_backgroundView];
    
    _contentView = ({
        PTToolbarContentView *view = [[PTToolbarContentView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.layoutMargins = UIEdgeInsetsZero;
        
        view.stackView.spacing = 0;
        
        (view);
    });
    [self addSubview:_contentView];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTAnnotationStylePresetsView_commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self pt_removeAllObservations];
}

#pragma mark - Constraints

- (void)loadConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    ]];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Presets

- (void)setPresets:(PTAnnotationStylePresetsGroup *)presets
{
    PTAnnotationStylePresetsGroup *previousPresets = _presets;
    [self endObservingPresets:previousPresets];
    
    _presets = presets;
    [self beginObservingPresets:presets];
    
    [self updateContentView];
}

#pragma mark Observation

- (void)beginObservingPresets:(PTAnnotationStylePresetsGroup *)presets
{
    if (!presets) {
        return;
    }
    
    [self pt_observeObject:presets
                forKeyPath:PT_KEY(presets, selectedStyle)
                  selector:@selector(selectedPresetDidChange:)];
}

- (void)selectedPresetDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.presets) {
        return;
    }
    
    [self updateSelection];
}

- (void)endObservingPresets:(PTAnnotationStylePresetsGroup *)presets
{
    if (!presets) {
        return;
    }
    
    [self pt_removeObservationsForObject:presets];
}

#pragma mark - Content view

- (void)updateContentView
{
    NSMutableArray<PTAnnotationStyleIndicatorView *> *indicators = [NSMutableArray array];
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    
    NSUInteger presetIndex = 0;
    for (PTAnnotStyle *preset in self.presets.styles) {
        PTAnnotationStyleIndicatorView *indicator = [[PTAnnotationStyleIndicatorView alloc] init];
        indicator.translatesAutoresizingMaskIntoConstraints = NO;
        
        indicator.disclosureIndicatorEnabled = YES;
        
        [indicator addTarget:self
                      action:@selector(presetActivated:)
            forControlEvents:(UIControlEventPrimaryActionTriggered)];
        
        indicator.style = preset;
        
        [indicators addObject:indicator];
        
        // Wrap indicator in a selectable bar button item.
        UIBarButtonItem *item = [[PTSelectableBarButtonItem alloc] initWithCustomView:indicator];
        
        item.image = [PTToolImages imageForAnnotationType:preset.annotType];
        
        NSString *localizedFormat = PTLocalizedString(@"%@ Preset %lu",
                                                      @"<Annotation type> Preset <number>");
        item.title = [NSString localizedStringWithFormat:localizedFormat,
                      PTLocalizedAnnotationNameFromType(preset.annotType), (presetIndex + 1)];
        
        [items addObject:item];
        presetIndex++;
    }
    
    self.indicators = [indicators copy];
    
    if ([self.contentView isKindOfClass:[PTToolbarContentView class]]) {
        ((PTToolbarContentView *)self.contentView).items = [items copy];
    }
    
    [self updateSelection];
}

- (void)presetActivated:(id)sender
{
    if ([sender isKindOfClass:[PTAnnotationStyleIndicatorView class]]) {
        PTAnnotationStyleIndicatorView *indicator = (PTAnnotationStyleIndicatorView *)sender;
        
        if (indicator.style == self.presets.selectedStyle) {
            // Delegate should edit this preset.
            if ([self.delegate respondsToSelector:@selector(presetsView:
                                                            editPresetForStyle:
                                                            fromView:)]) {
                [self.delegate presetsView:self
                        editPresetForStyle:indicator.style
                                  fromView:indicator.disclosureIndicatorView];
            }
        } else {
            // Select this style.
            self.presets.selectedStyle = indicator.style;
            
            [indicator.style setCurrentValuesAsDefaults];
        }
    }
}

- (void)updateSelection
{
    for (PTAnnotationStyleIndicatorView *indicator in self.indicators) {
        const BOOL selected = (indicator.style == self.presets.selectedStyle);
        indicator.selected = selected;
        [indicator setDisclosureIndicatorHidden:!selected animated:YES];
    }
}

@end
