//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleViewController.h"

#import "PTAnnotStylePreview.h"
#import "PTAnnotStyleTableViewController.h"
#import "PTColorPickerViewController.h"
#import "PTToolsUtil.h"
#import "PTMeasurementScale.h"
#import "PTColorDefaults.h"
#import "UIColor+PTHexString.h"

#import "UIScrollView+PTAdditions.h"
#import "UIViewController+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStyleViewController () <UINavigationControllerDelegate, PTAnnotStyleTableViewControllerDelegate, PTColorPickerViewControllerDelegate, UIFontPickerViewControllerDelegate, UIToolbarDelegate>

@property (nonatomic, strong, nullable) PTToolManager *toolManager;

// The subview of the view controller's root view that contains the main content.
// (This is the stack view).
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIToolbar *annotPreviewContainer;
@property (nonatomic, strong) PTAnnotStylePreview *annotPreviewView;

@property (nonatomic, strong) PTAnnotStyleTableViewController *tableViewController;

@property (nonatomic, strong) PTColorPickerViewController *colorPickerViewController;

@property (nonatomic) BOOL constraintsLoaded;

@property (nonatomic) BOOL needsAnnotPreviewContainerUpdate;

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotStyleViewController

- (instancetype)initWithAnnotStyle:(PTAnnotStyle *)annotStyle
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _annotStyle = annotStyle;
        _annotStyle.delegate = self;

        if (@available(iOS 13.0, *)) {
            _fontPickerConfiguration = [[UIFontPickerViewControllerConfiguration alloc] init];
            
            _fontPickerConfiguration.includeFaces = YES;
        }
    }
    return self;
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager annotStyle:(PTAnnotStyle *)annotStyle
{
    self = [self initWithAnnotStyle:annotStyle];
    if (self) {
        _toolManager = toolManager;
    }
    return self;
}

- (void)configureWithAnnotStyle:(PTAnnotStyle *)annotStyle
{
    NSMutableArray *sections = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];

    for (PTAnnotStyleKey key in annotStyle.availableStyleKeys) {
        PTAnnotStyleTableViewItem *item = nil;

        if ([key isEqualToString:PTAnnotStyleKeyFont]) {
            NSString *title = PTLocalizedString(@"Font", nil);
            
            UIFontDescriptor* fontDescriptor = [UIFontDescriptor fontDescriptorWithName:annotStyle.fontName size:annotStyle.textSize];
            
            item = [[AnnotStyleTableViewFontItem alloc] initWithTitle:title fontDescriptor:fontDescriptor annotStyleKey:PTAnnotStyleKeyFont];
            
            self.annotPreviewView.fontDescriptor = fontDescriptor;
        }
        if ([key isEqualToString:PTAnnotStyleKeyColor]) {
            NSString *title = PTLocalizedString(@"Color", nil);

            item = [[PTAnnotStyleColorTableViewItem alloc] initWithTitle:title
                                                                 color:annotStyle.color
                                                         annotStyleKey:PTAnnotStyleKeyColor];

            self.annotPreviewView.color = annotStyle.color;
        }
        if ([key isEqualToString:PTAnnotStyleKeyStrokeColor]) {
            NSString *title = PTLocalizedString(@"Stroke Color", nil);

            if (self.annotStyle.annotType == PTExtendedAnnotTypeFreeText) {
                title = PTLocalizedString(@"Border Color", nil);
            }

            item = [[PTAnnotStyleColorTableViewItem alloc] initWithTitle:title
                                                                 color:annotStyle.strokeColor
                                                         annotStyleKey:PTAnnotStyleKeyStrokeColor];

            self.annotPreviewView.color = annotStyle.strokeColor;
        }
        if ([key isEqualToString:PTAnnotStyleKeyFillColor]) {
            NSString *title = PTLocalizedString(@"Fill Color", nil);

            item = [[PTAnnotStyleColorTableViewItem alloc] initWithTitle:title
                                                                 color:annotStyle.fillColor
                                                         annotStyleKey:PTAnnotStyleKeyFillColor];

            self.annotPreviewView.fillColor = annotStyle.fillColor;
        }
        if ([key isEqualToString:PTAnnotStyleKeyTextColor]) {
            NSString *title = PTLocalizedString(@"Text Color", nil);

            item = [[PTAnnotStyleColorTableViewItem alloc] initWithTitle:title
                                                                 color:annotStyle.textColor
                                                         annotStyleKey:PTAnnotStyleKeyTextColor];

            self.annotPreviewView.textColor = annotStyle.textColor;
        }

        if ([key isEqualToString:PTAnnotStyleKeyThickness]) {
            // HACK: Don't show the thickness slider for redaction annotations.
            if (annotStyle.annotType != PTExtendedAnnotTypeRedact) {
                NSString *title = PTLocalizedString(@"Thickness", nil);
                
                CGFloat minimumValue = 1.0;
                
                CGFloat maximumValue = 12.0;
                if (annotStyle.annotType == PTExtendedAnnotTypeFreehandHighlight) {
                    maximumValue = 20.0;
                }
                
                // Consult delegate for minimum value.
                if ([self.delegate respondsToSelector:@selector(annotStyleViewController:minimumValue:forStyle:key:)]) {
                    [self.delegate annotStyleViewController:self minimumValue:&minimumValue forStyle:annotStyle key:key];
                }

                // Consult delegate for maximum value.
                if ([self.delegate respondsToSelector:@selector(annotStyleViewController:maximumValue:forStyle:key:)]) {
                    [self.delegate annotStyleViewController:self maximumValue:&maximumValue forStyle:annotStyle key:key];
                }

                item = [[PTAnnotStyleSliderTableViewItem alloc] initWithTitle:title
                                                                 minimumValue:minimumValue
                                                                 maximumValue:maximumValue
                                                                        value:annotStyle.thickness
                                                                indicatorText:annotStyle.thicknessIndicatorString
                                                                annotStyleKey:PTAnnotStyleKeyThickness];
            }

            self.annotPreviewView.thickness = annotStyle.thickness;
        }
        if ([key isEqualToString:PTAnnotStyleKeyOpacity]) {
            NSString *title = PTLocalizedString(@"Opacity", nil);

            CGFloat minimumValue = 10.0;
            CGFloat maximumValue = 100.0;
            
            // Consult delegate for minimum value.
            if ([self.delegate respondsToSelector:@selector(annotStyleViewController:minimumValue:forStyle:key:)]) {
                [self.delegate annotStyleViewController:self minimumValue:&minimumValue forStyle:annotStyle key:key];
            }

            // Consult delegate for maximum value.
            if ([self.delegate respondsToSelector:@selector(annotStyleViewController:maximumValue:forStyle:key:)]) {
                [self.delegate annotStyleViewController:self maximumValue:&maximumValue forStyle:annotStyle key:key];
            }
            
            item = [[PTAnnotStyleSliderTableViewItem alloc] initWithTitle:title
                                                           minimumValue:minimumValue
                                                           maximumValue:maximumValue
                                                                  value:(annotStyle.opacity * 100.0)
                                                          indicatorText:annotStyle.opacityIndicatorString
                                                          annotStyleKey:PTAnnotStyleKeyOpacity];

            self.annotPreviewView.opacity = annotStyle.opacity;
        }
        if ([key isEqualToString:PTAnnotStyleKeyTextSize]) {
            NSString *title = PTLocalizedString(@"Text Size", nil);
            
            CGFloat minimumValue = 4.0;
            CGFloat maximumValue = 72.0;
            
            // Consult delegate for minimum value.
            if ([self.delegate respondsToSelector:@selector(annotStyleViewController:minimumValue:forStyle:key:)]) {
                [self.delegate annotStyleViewController:self minimumValue:&minimumValue forStyle:annotStyle key:key];
            }

            // Consult delegate for maximum value.
            if ([self.delegate respondsToSelector:@selector(annotStyleViewController:maximumValue:forStyle:key:)]) {
                [self.delegate annotStyleViewController:self maximumValue:&maximumValue forStyle:annotStyle key:key];
            }

            item = [[PTAnnotStyleSliderTableViewItem alloc] initWithTitle:title
                                                           minimumValue:minimumValue
                                                           maximumValue:maximumValue
                                                                  value:annotStyle.textSize
                                                          indicatorText:annotStyle.textSizeIndicatorString
                                                          annotStyleKey:PTAnnotStyleKeyTextSize];

            self.annotPreviewView.textSize = annotStyle.textSize;
        }
        if ([key isEqualToString:PTAnnotStyleKeyLabel]) {
            NSString *title = nil;
            if (annotStyle.annotType == PTExtendedAnnotTypeRedact) {
                title = PTLocalizedString(@"Overlay text", @"Overlay text for redaction annot");
            } else {
                title = PTLocalizedString(@"Label", nil);
            }

            item = [[PTAnnotStyleTextFieldTableViewItem alloc] initWithTitle:title
                                                                        text:annotStyle.label
                                                               annotStyleKey:PTAnnotStyleKeyLabel];

            self.annotPreviewView.textSize = annotStyle.textSize;
        }
        if ([key isEqualToString:PTAnnotStyleKeyScale]) {
            NSString *title = PTLocalizedString(@"Scale", @"Scale style view controller cell title");

            item = [[PTAnnotStyleScaleTableViewItem alloc] initWithTitle:title
                                                                         measurementScale:annotStyle.measurementScale
                                                                 annotStyleKey:PTAnnotStyleKeyScale];
        }
        if ([key isEqualToString:PTAnnotStyleKeyPrecision]) {
            NSString *title = PTLocalizedString(@"Precision", @"Precision style view controller cell title");
            
            item = [[PTAnnotStylePrecisionTableViewItem alloc] initWithTitle:title
                                                                   measurementScale:annotStyle.measurementScale
                                                           annotStyleKey:PTAnnotStyleKeyPrecision];
        }
        if ([key isEqualToString:PTAnnotStyleKeySnapping]) {
            NSString *title = PTLocalizedString(@"Snapping", @"Measurement tool snapping switch label");

            item = [[PTAnnotStyleSwitchTableViewItem alloc] initWithTitle:title
                                                          snappingEnabled:self.toolManager.snapToDocumentGeometryEnabled
                                                            annotStyleKey:PTAnnotStyleKeySnapping];
        }
        if (item) {
            [items addObject:item];
        }
    }

    // Add style controls section.
    [sections addObject:items];

    self.annotPreviewView.annotType = annotStyle.annotType;
    
    // Hide annotation preview when editing style of an existing annotation.
    self.annotPreviewContainer.hidden = (annotStyle.annot != nil);

    self.tableViewController.items = sections;
    
    NSString *localizedAnnotationName = PTLocalizedAnnotationNameFromType(annotStyle.annotType);
    if (localizedAnnotationName.length > 0) {
        self.title = localizedAnnotationName;
    } else {
        self.title = PTLocalizedString(@"Style",
                                       @"Annotation style");
    }
}

- (void)selectStyle
{
    // Notify delegate of current style selection.
    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didCommitStyle:)]) {
        [self.delegate annotStyleViewController:self didCommitStyle:self.annotStyle];
    }
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight);
    
    // Stack view (vertical).
    self.stackView = [[UIStackView alloc] init];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.alignment = UIStackViewAlignmentFill;
    self.stackView.distribution = UIStackViewDistributionFill;
    
    [self.view addSubview:self.stackView];

    // Initialize style preview.
    self.annotPreviewContainer = [[UIToolbar alloc] init];
    self.annotPreviewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.annotPreviewContainer.delegate = self;
    
    self.annotPreviewView = [[PTAnnotStylePreview alloc] init];
    self.annotPreviewView.translatesAutoresizingMaskIntoConstraints = NO;
    self.annotPreviewView.textColor = UIColor.blackColor;
    
    [self.annotPreviewContainer addSubview:self.annotPreviewView];
    
    [self.stackView addArrangedSubview:self.annotPreviewContainer];
    
    // Initialize style list view controller.
    self.tableViewController = [[PTAnnotStyleTableViewController alloc] init];
    self.tableViewController.delegate = self;
    self.tableViewController.tableView.tableFooterView = [[UIView alloc] init];
    
    [self pt_addChildViewController:self.tableViewController withBlock:^{
        [self.stackView addArrangedSubview:self.tableViewController.view];
    }];
    
    [self.stackView bringSubviewToFront:self.annotPreviewContainer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentView = self.stackView;
        
    [self updateDoneButton:NO];
    
    // Schedule constraints update.
    [self.view setNeedsUpdateConstraints];

    [self configureWithAnnotStyle:self.annotStyle];
}

- (void)loadViewConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor constraintEqualToAnchor:self.pt_safeTopAnchor],
        [self.stackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.stackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        
        [self.annotPreviewContainer.heightAnchor constraintEqualToConstant:94.0],
        
        [self.annotPreviewView.centerXAnchor constraintEqualToAnchor:self.annotPreviewContainer.centerXAnchor],
        [self.annotPreviewView.widthAnchor constraintEqualToConstant:250.0],
        
        [self.annotPreviewView.centerYAnchor constraintEqualToAnchor:self.annotPreviewContainer.centerYAnchor],
        [self.annotPreviewView.heightAnchor constraintEqualToAnchor:self.annotPreviewContainer.heightAnchor
                                                           constant:-20.0],
    ]];
}

- (void)updateViewConstraints
{
    if (!self.constraintsLoaded) {
        [self loadViewConstraints];
        
        // Constraints are loaded.
        self.constraintsLoaded = YES;
    }
    // Call super implementation as final step.
    [super updateViewConstraints];
}

- (void)updatePreferredContentSize
{
    NSAssert(self.contentView != nil, @"Cannot calculate the preferred content size");
    
    const CGSize targetSize = UILayoutFittingCompressedSize;
    const CGSize size = [self.contentView systemLayoutSizeFittingSize:targetSize];
    
    self.preferredContentSize = size;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self updatePreferredContentSize];
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.needsAnnotPreviewContainerUpdate = YES;

    [self updateDoneButton:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.needsAnnotPreviewContainerUpdate) {
        [self updateAnnotationPreviewContainer];
        
        self.needsAnnotPreviewContainerUpdate = NO;
    }
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateDoneButton:NO];
}

#pragma mark - Annotation preview container

- (void)updateAnnotationPreviewContainer
{
    if (!self.navigationController) {
        return;
    }
    
    // Synchronize toolbar appearance with navigation bar.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    self.annotPreviewContainer.barStyle = navigationBar.barStyle;
    self.annotPreviewContainer.barTintColor = navigationBar.barTintColor;
    self.annotPreviewContainer.tintColor = navigationBar.tintColor;
    self.annotPreviewContainer.translucent = navigationBar.translucent;
}

#pragma mark - Done button(s)

- (UIBarButtonItem *)doneButtonItem
{
    if (!_doneButtonItem) {
        if (@available(iOS 13.0, *)) {
            _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                            target:self
                                                                            action:@selector(done:)];
        } else {
            _doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                            target:self
                                                                            action:@selector(done:)];
        }
    }
    return _doneButtonItem;
}

- (void)done:(id)sender
{
    // Notify delegate of current style selection.
    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didCommitStyle:)]) {
        [self.delegate annotStyleViewController:self didCommitStyle:self.annotStyle];
    } else {
        // Dismiss manually.
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)showsDoneButton
{
    // Don't show the "Done" button when editing or in a popover presentation.
    return !([self isEditing] || [self pt_isInPopover]);
}

- (void)updateDoneButton:(BOOL)animated
{
    UIBarButtonItem *rightBarButtonItem = nil;
    if ([self showsDoneButton]) {
        rightBarButtonItem = self.doneButtonItem;
    }
    
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem
                                      animated:animated];
}

#pragma mark - <AnnotStyleTableViewControllerDelegate>

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTAnnotStyleTableViewItem *item = self.tableViewController.items[indexPath.section][indexPath.row];

    if( item.type == PTAnnotStyleTableViewItemTypeColor)
    {
        PTAnnotStyleColorTableViewItem *colorItem = (PTAnnotStyleColorTableViewItem *) item;
        
        // Show color picker (prevent pushing onto stack more than once with fast taps).
        if (![self.navigationController.viewControllers containsObject:self.colorPickerViewController]) {
            self.colorPickerViewController.color = colorItem.color;
            self.colorPickerViewController.title = colorItem.title;
            self.colorPickerViewController.tag = colorItem.annotStyleKey;
            
            [self.navigationController pushViewController:self.colorPickerViewController animated:YES];
        } else {
            NSLog(@"Color picker view controller already on navigation stack");
        }

    }
    else if (item.type == PTAnnotStyleTableViewItemTypeFont )
    {
        if (@available(iOS 13.0, *)) {
            UIFontPickerViewController* fpvc;
            
            if( self.fontPickerConfiguration )
            {
                fpvc = [[UIFontPickerViewController alloc] initWithConfiguration:self.fontPickerConfiguration];
            }
            else
            {
                fpvc = [[UIFontPickerViewController alloc] init];
            }
            fpvc.delegate = self;
            
            fpvc.title = item.title;

            [self.navigationController pushViewController:fpvc animated:YES];
        }
    }
}

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController sliderDidBeginSlidingForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Do nothing.
}

- (float)tableViewController:(PTAnnotStyleTableViewController *)tableViewController sliderValueDidChange:(float)value forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTAnnotStyleTableViewItem *item = self.tableViewController.items[indexPath.section][indexPath.row];
    if (item.type != PTAnnotStyleTableViewItemTypeSlider ||
        ![item isKindOfClass:[PTAnnotStyleSliderTableViewItem class]]) {
        return value;
    }

    PTAnnotStyleSliderTableViewItem *sliderItem = (PTAnnotStyleSliderTableViewItem *) item;

    if ([item.annotStyleKey isEqualToString:PTAnnotStyleKeyThickness]) {
        // Round to nearest integer.
        NSInteger integerValue = (NSInteger) roundf(value);
        self.annotStyle.thickness = integerValue;

        sliderItem.value = integerValue;
        sliderItem.indicatorText = self.annotStyle.thicknessIndicatorString;
        return integerValue;
    }
    else if ([item.annotStyleKey isEqualToString:PTAnnotStyleKeyOpacity]) {
        // Round to nearest multiple of 5.
        NSInteger integerValue = (NSInteger) (5.0 * roundf(value / 5.0));
        self.annotStyle.opacity = integerValue / 100.0; // Convert to range [0.0, 1.0].

        sliderItem.value = integerValue;
        sliderItem.indicatorText = self.annotStyle.opacityIndicatorString;
        return integerValue;
    }
    else if ([item.annotStyleKey isEqualToString:PTAnnotStyleKeyTextSize]) {
        // Round to nearest integer.
        NSInteger integerValue = (NSInteger) roundf(value);
        self.annotStyle.textSize = integerValue;

        sliderItem.value = integerValue;
        sliderItem.indicatorText = self.annotStyle.textSizeIndicatorString;
        return integerValue;
    }
    else {
        return value;
    }
}

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController sliderDidEndSlidingForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didChangeStyle:)]) {
        [self.delegate annotStyleViewController:self didChangeStyle:self.annotStyle];
    }
}

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController textFieldContentsDidChange:(NSString *)text forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTAnnotStyleTableViewItem *item = self.tableViewController.items[indexPath.section][indexPath.row];
    if (item.type != PTAnnotStyleTableViewItemTypeTextField ||
        ![item isKindOfClass:[PTAnnotStyleTextFieldTableViewItem class]]) {
        return;
    }

    if ([item.annotStyleKey isEqualToString:PTAnnotStyleKeyLabel]) {
        self.annotStyle.label = text;
    }

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didChangeStyle:)]) {
        [self.delegate annotStyleViewController:self didChangeStyle:self.annotStyle];
    }
}

- (PTMeasurementScale *)tableViewController:(PTAnnotStyleTableViewController *)tableViewController scaleDidChange:(PTMeasurementScale *)measurementScale forItemAtIndexPath:(NSIndexPath *)indexPath
{
   PTAnnotStyleTableViewItem *item = self.tableViewController.items[indexPath.section][indexPath.row];
    if (item.type != PTAnnotStyleTableViewItemTypeScale ||
        ![item isKindOfClass:[PTAnnotStyleScaleTableViewItem class]]) {
        return measurementScale;
    }

    PTAnnotStyleScaleTableViewItem *scaleItem = (PTAnnotStyleScaleTableViewItem *) item;
    scaleItem.measurementScale = measurementScale;
    self.annotStyle.measurementScale = measurementScale;

    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didChangeStyle:)]) {
        [self.delegate annotStyleViewController:self didChangeStyle:self.annotStyle];
    }
    return measurementScale;
}

- (void)tableViewController:(PTAnnotStyleTableViewController *)tableViewController snappingToggled:(BOOL)snappingEnabled forItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    PTAnnotStyleTableViewItem *item = self.tableViewController.items[indexPath.section][indexPath.row];
    if (item.type != PTAnnotStyleTableViewItemTypeSwitch ||
        ![item isKindOfClass:[PTAnnotStyleSwitchTableViewItem class]]) {
        return;
    }

    PTAnnotStyleSwitchTableViewItem *switchItem = (PTAnnotStyleSwitchTableViewItem *) item;
    switchItem.snappingEnabled = snappingEnabled;
    self.annotStyle.snappingEnabled = snappingEnabled;

    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didChangeStyle:)]) {
        [self.delegate annotStyleViewController:self didChangeStyle:self.annotStyle];
    }
    return;
}

- (PTMeasurementScale *)tableViewController:(PTAnnotStyleTableViewController *)tableViewController precisionDidChange:(PTMeasurementScale *)measurementScale forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTAnnotStyleTableViewItem *item = self.tableViewController.items[indexPath.section][indexPath.row];
    if (item.type != PTAnnotStyleTableViewItemTypePrecision ||
        ![item isKindOfClass:[PTAnnotStylePrecisionTableViewItem class]]) {
        return measurementScale;
    }
    
    PTAnnotStylePrecisionTableViewItem *precisionItem = (PTAnnotStylePrecisionTableViewItem *) item;
    precisionItem.measurementScale = measurementScale;
    self.annotStyle.measurementScale = measurementScale;
    
    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didChangeStyle:)]) {
        [self.delegate annotStyleViewController:self didChangeStyle:self.annotStyle];
    }
    return measurementScale;
}
#pragma mark - <PTColorPickerViewControllerDelegate>

- (void)colorPickerController:(PTColorPickerViewController *)colorPickerController didSelectColor:(UIColor *)color
{
    PTAnnotStyleKey key = colorPickerController.tag;

    if ([key isEqualToString:PTAnnotStyleKeyColor]) {
        self.annotStyle.color = color;
    }
    else if ([key isEqualToString:PTAnnotStyleKeyStrokeColor]) {
        self.annotStyle.strokeColor = color;
    }
    else if ([key isEqualToString:PTAnnotStyleKeyFillColor]) {
        self.annotStyle.fillColor = color;
    }
    else if ([key isEqualToString:PTAnnotStyleKeyTextColor]) {
        self.annotStyle.textColor = color;
    }

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didChangeStyle:)]) {
        [self.delegate annotStyleViewController:self didChangeStyle:self.annotStyle];
    }
}

# pragma mark - <AnnotStyleDelegate>

- (void)annotStyle:(PTAnnotStyle *)annotStyle colorDidChange:(UIColor *)color
{
    self.annotPreviewView.color = color;

    PTAnnotStyleTableViewItem *item = [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeyColor];
    if (item && item.type == PTAnnotStyleTableViewItemTypeColor) {
        PTAnnotStyleColorTableViewItem *colorItem = (PTAnnotStyleColorTableViewItem *) item;

        colorItem.color = color;

        [self.tableViewController.tableView reloadData];
    }
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle strokeColorDidChange:(UIColor *)strokeColor
{
    self.annotPreviewView.color = strokeColor;

    PTAnnotStyleTableViewItem *item = [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeyStrokeColor];
    if (item && item.type == PTAnnotStyleTableViewItemTypeColor) {
        PTAnnotStyleColorTableViewItem *colorItem = (PTAnnotStyleColorTableViewItem *) item;

        colorItem.color = strokeColor;

        [self.tableViewController.tableView reloadData];
    }

}

- (void)annotStyle:(PTAnnotStyle *)annotStyle fillColorDidChange:(UIColor *)fillColor
{
    self.annotPreviewView.fillColor = fillColor;

    PTAnnotStyleTableViewItem *item = [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeyFillColor];
    if (item && item.type == PTAnnotStyleTableViewItemTypeColor) {
        PTAnnotStyleColorTableViewItem *colorItem = (PTAnnotStyleColorTableViewItem *) item;

        colorItem.color = fillColor;

        [self.tableViewController.tableView reloadData];
    }
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle textColorDidChange:(UIColor *)textColor
{
    self.annotPreviewView.textColor = textColor;

    PTAnnotStyleTableViewItem *item = [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeyTextColor];
    if (item && item.type == PTAnnotStyleTableViewItemTypeColor) {
        PTAnnotStyleColorTableViewItem *colorItem = (PTAnnotStyleColorTableViewItem *) item;

        colorItem.color = textColor;

        [self.tableViewController.tableView reloadData];
    }
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle thicknessDidChange:(CGFloat)thickness
{
    self.annotPreviewView.thickness = thickness;
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle opacityDidChange:(CGFloat)opacity
{
    self.annotPreviewView.opacity = opacity;
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle textSizeDidChange:(CGFloat)textSize
{
    self.annotPreviewView.textSize = textSize;
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle labelDidChange:(NSString *)label
{
    PTAnnotStyleTableViewItem *item = [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeyLabel];
    if (item && item.type == PTAnnotStyleTableViewItemTypeTextField) {
        PTAnnotStyleTextFieldTableViewItem *textItem = (PTAnnotStyleTextFieldTableViewItem *)item;

        textItem.text = label;

//        [self.tableViewController.tableView reloadData];
    }
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle measurementScaleDidChange:(PTMeasurementScale *)measurementScale
{
    PTAnnotStyleTableViewItem *item =  [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeyScale];
    if (item && item.type == PTAnnotStyleTableViewItemTypeScale) {
        PTAnnotStyleScaleTableViewItem *scaleItem = (PTAnnotStyleScaleTableViewItem *) item;

        scaleItem.measurementScale = measurementScale;

//        [self.tableViewController.tableView reloadData];
    }
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle snappingToggled:(BOOL)snappingEnabled
{
    PTAnnotStyleTableViewItem *item =  [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeySnapping];
    if (item && item.type == PTAnnotStyleTableViewItemTypeSwitch) {
        PTAnnotStyleSwitchTableViewItem *switchItem = (PTAnnotStyleSwitchTableViewItem *) item;
        self.toolManager.snapToDocumentGeometry = snappingEnabled;
        switchItem.snappingEnabled = snappingEnabled;
    }
}

- (void)annotStyle:(PTAnnotStyle *)annotStyle fontNameDidChange:(NSString *)fontName
{
    CGFloat size = [PTColorDefaults defaultFreeTextSize];
    
    UIFontDescriptor *newFontDescriptor = [UIFontDescriptor fontDescriptorWithName:fontName
                                                                              size:size];
    
    self.annotPreviewView.fontDescriptor = newFontDescriptor;
    
    PTAnnotStyleTableViewItem *item = [self.tableViewController tableViewItemForAnnotStyleKey:PTAnnotStyleKeyFont];
    
    if (item && item.type == PTAnnotStyleTableViewItemTypeFont) {
        PTAnnotStyleFontTableViewItem *fontItem = (PTAnnotStyleFontTableViewItem *)item;

        fontItem.fontDescriptor = newFontDescriptor;

        [self.tableViewController.tableView reloadData];
    }
}

#pragma mark - <UIFontPickerViewControllerDelegate>

- (void)fontPickerViewControllerDidPickFont:(UIFontPickerViewController *)viewController API_AVAILABLE(ios(13.0)){
    UIFontDescriptor* fontDescriptor = viewController.selectedFontDescriptor;
    self.annotStyle.fontName = fontDescriptor.postscriptName;
    
    [PTColorDefaults setDefaultFreeTextFontName:fontDescriptor.postscriptName];
    
    if ([self.delegate respondsToSelector:@selector(annotStyleViewController:didChangeStyle:)]) {
        [self.delegate annotStyleViewController:self didChangeStyle:self.annotStyle];
    }
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    if (bar == self.annotPreviewContainer) {
        return UIBarPositionTop;
    }
    return UIBarPositionBottom;
}

#pragma mark - Property accessors

- (void)setAnnotStyle:(PTAnnotStyle *)annotStyle
{
    _annotStyle = annotStyle;
    _annotStyle.delegate = self;

    [self configureWithAnnotStyle:annotStyle];
}

- (PTColorPickerViewController *)colorPickerViewController
{
    // Lazy load color picker.
    if (!_colorPickerViewController) {
        
        NSMutableArray<UIColor*>* colors;
        
        if(self.annotStyle.annotType == PTExtendedAnnotTypeHighlight ||
           self.annotStyle.annotType == PTExtendedAnnotTypeFreehandHighlight)
        {
            // Initialize with the standard color pallete.
            NSArray<NSString *> *hexColors =
            @[
              @"#ff0000", @"#ff7f02", @"#ffff00", @"#00ff00", @"#00ffff", @"#0000ff", @"#ff00ff",
              
              @"#ff6666", @"#ffb267", @"#ffff66", @"#66ff66", @"#6bfcfc", @"#6666ff", @"#ff66ff",
              
              @"#ff9999", @"#ffcb99", @"#ffff99", @"#99ff99", @"#b2ffff", @"#9999ff", @"#ff99ff",
              
              @"#ffcccc", @"#ffe5cc", @"#ffffcc", @"#ccffcc", @"#dcffff", @"#ccccff", @"#ffccff",
              ];
            
            colors = [NSMutableArray arrayWithCapacity:hexColors.count];
            for (NSString *hexColor in hexColors) {
                [colors addObject:[UIColor pt_colorWithHexString:hexColor]];
            }
        }
        
        _colorPickerViewController = [[PTColorPickerViewController allocOverridden]
                                       initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                       navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                       options:nil
                                       colors:[colors copy]];
        
        _colorPickerViewController.colorPickerDelegate = self;
    }
    return _colorPickerViewController;
}

@end
