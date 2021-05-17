//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTColorPickerViewController.h"

#import "PTStandardColorsViewController.h"

#import "UIViewController+PTAdditions.h"

@interface PTColorPickerViewController () <PTStandardColorsViewControllerDelegate>

@property (nonatomic, strong) PTStandardColorsViewController *standardColorsViewController;

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@end

@implementation PTColorPickerViewController

- (NSArray<UIColor *> *)colors
{
    return self.standardColorsViewController.colors;
}

- (void)setColors:(NSArray<UIColor *> *)colors
{
    self.standardColorsViewController.colors = colors;
}

- (instancetype)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(nullable NSDictionary<UIPageViewControllerOptionsKey, id> *)options colors:(nullable NSArray<UIColor *> *)colors
{
    self = [super initWithTransitionStyle:style navigationOrientation:navigationOrientation options:options];
    if (self) {
        _standardColorsViewController = [[PTStandardColorsViewController alloc] initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]
                                                                                                      colors:colors];
        _standardColorsViewController.colorPickerDelegate = self;
        _standardColorsViewController.selectedColor = _color;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = self;
    
    // Set initial view controller.
    [self setViewControllers:@[self.standardColorsViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self updateDoneButton:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateDoneButton:animated];
}

#pragma mark - Done button

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
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateDoneButton:NO];
}

#pragma mark - <UIContentContainer>

- (void)preferredContentSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container
{
    [super preferredContentSizeDidChangeForChildContentContainer:container];
    
    CGSize maxSize = CGSizeZero;
    for (UIViewController *viewController in self.viewControllers) {
        CGSize preferredContentSize = viewController.preferredContentSize;
        if (preferredContentSize.width > maxSize.width || preferredContentSize.height > maxSize.height) {
            maxSize = preferredContentSize;
        }
    }
    if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
        self.preferredContentSize = maxSize;
    }
}

#pragma mark - <UIPageViewControllerDataSource>

- (nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController {
    return nil;
}

- (nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerBeforeViewController:(nonnull UIViewController *)viewController {
    return nil;
}

#pragma mark - <StandardColorsViewControllerDelegate>

- (void)standardColorsViewController:(PTStandardColorsViewController *)standardColorsViewController didSelectColor:(UIColor *)color
{
    self.color = color;
    
    if ([self.colorPickerDelegate respondsToSelector:@selector(colorPickerController:didSelectColor:)]) {
        [self.colorPickerDelegate colorPickerController:self didSelectColor:color];
    }
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    
    self.standardColorsViewController.selectedColor = color;
}

@end

