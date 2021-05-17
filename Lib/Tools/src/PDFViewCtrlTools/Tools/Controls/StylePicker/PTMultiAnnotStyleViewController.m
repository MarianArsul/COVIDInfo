//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTMultiAnnotStyleViewController.h"

#import "PTToolsUtil.h"

#import "UIViewController+PTAdditions.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTMultiAnnotStyleViewController ()
{
    BOOL _needsLoadStyleViewControllerConstraints;
    
    __weak PTAnnotStyleViewController * _Nullable _selectedStyleViewController;
}

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) UIView *childViewControllerContainer;

@property (nonatomic, assign) BOOL viewConstraintsLoaded;

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@end

NS_ASSUME_NONNULL_END

@implementation PTMultiAnnotStyleViewController

- (instancetype)initWithStyles:(NSArray<PTAnnotStyle *> *)styles
{
    return [self initWithToolManager:nil styles:styles];
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager styles:(NSArray<PTAnnotStyle *> *)styles
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _toolManager = toolManager;
        
        _styles = [styles copy];
        _selectedStyle = _styles.firstObject;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight);
    
    self.stackView = [[UIStackView alloc] init];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.alignment = UIStackViewAlignmentFill;
    self.stackView.distribution = UIStackViewDistributionFill;
    self.stackView.spacing = 0;
    
    [self.view addSubview:self.stackView];
    
    // Header view used as the background for the segmented control.
    self.headerView = [[UIView alloc] init];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.headerView.layoutMargins = UIEdgeInsetsMake(8, 10, 8, 10);
    
    [self.stackView addArrangedSubview:self.headerView];
    
    // Navigation bar used as the background for the segmented control.
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:self.headerView.bounds];
    self.navigationBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight);
    
    [self.headerView addSubview:self.navigationBar];
    
    // Segmented control to choose the selected style.
    self.segmentedControl = [[UISegmentedControl alloc] init];
    self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Strongly hug content along vertical axis.
    [self.segmentedControl setContentHuggingPriority:(UILayoutPriorityDefaultHigh + 1)
                                             forAxis:UILayoutConstraintAxisVertical];
    
    [self.segmentedControl addTarget:self
                              action:@selector(selectedSegmentDidChange:)
                    forControlEvents:UIControlEventValueChanged];
    
    [self.headerView addSubview:self.segmentedControl];
    
    self.childViewControllerContainer = [[UIView alloc] init];
    self.childViewControllerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.stackView addArrangedSubview:self.childViewControllerContainer];
    
    [self.stackView bringSubviewToFront:self.headerView];
    
    // Schedule loadViewConstraints.
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentView = self.stackView;
    
    [self PT_updateTitle];
    [self PT_updateSegmentedControl];
    [self PT_updateAnnotationStyleViewControllers];
    
    [self updateDoneButton:NO];
}

#pragma mark - View constraints

- (void)loadViewConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor constraintEqualToAnchor:self.pt_safeTopAnchor],
        [self.stackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.stackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    ]];
    
    UILayoutGuide *headerMarginsGuide = self.headerView.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.segmentedControl.topAnchor constraintEqualToAnchor:headerMarginsGuide.topAnchor],
        [self.segmentedControl.centerXAnchor constraintEqualToAnchor:headerMarginsGuide.centerXAnchor],
        [self.segmentedControl.bottomAnchor constraintEqualToAnchor:headerMarginsGuide.bottomAnchor],
        [self.segmentedControl.widthAnchor constraintLessThanOrEqualToAnchor:headerMarginsGuide.widthAnchor],
    ]];
}

- (void)loadStyleViewControllerConstraints
{
    PTAnnotStyleViewController * const styleViewController = _selectedStyleViewController;
    if (!styleViewController) {
        return;
    }
    
    UIView * const styleView = styleViewController.view;
    
    [NSLayoutConstraint activateConstraints:@[
        [styleView.topAnchor constraintEqualToAnchor:self.childViewControllerContainer.topAnchor],
        [styleView.leftAnchor constraintEqualToAnchor:self.childViewControllerContainer.leftAnchor],
        [styleView.bottomAnchor constraintEqualToAnchor:self.childViewControllerContainer.bottomAnchor],
        [styleView.rightAnchor constraintEqualToAnchor:self.childViewControllerContainer.rightAnchor],
    ]];
}

- (void)updateViewConstraints
{
    if (!self.viewConstraintsLoaded) {
        [self loadViewConstraints];
        
        self.viewConstraintsLoaded = YES;
    }
    if (_needsLoadStyleViewControllerConstraints) {
        _needsLoadStyleViewControllerConstraints = NO;
        
        [self loadStyleViewControllerConstraints];
    }
    // Call super implementation as final step.
    [super updateViewConstraints];
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateDoneButton:NO];
}

#pragma mark - Preferred content size

- (void)updatePreferredContentSize
{
    NSAssert(self.contentView != nil, @"Cannot calculate the preferred content size");
    
    const CGSize targetSize = UILayoutFittingCompressedSize;
    const CGSize sizeThatFits = [self.contentView systemLayoutSizeFittingSize:targetSize];
    
    const CGSize size = CGSizeMake(fmax(320, sizeThatFits.width),
                                   sizeThatFits.height);
    
    self.preferredContentSize = size;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self updatePreferredContentSize];
}

- (void)viewLayoutMarginsDidChange
{
    [super viewLayoutMarginsDidChange];
    
    const UIEdgeInsets viewLayoutMargins = self.view.layoutMargins;
    
    UIEdgeInsets headerMargins = self.headerView.layoutMargins;
    headerMargins.left = fmax(10, viewLayoutMargins.left);
    headerMargins.right = fmax(10, viewLayoutMargins.right);
    self.headerView.layoutMargins = headerMargins;
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateDoneButton:animated];
}

#pragma mark - Done button item

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

#pragma mark - Styles

- (void)setStyles:(NSArray<PTAnnotStyle *> *)styles
{
    //NSArray<PTAnnotStyle *> * const previousStyles = _styles;
    _styles = [styles copy];
    
    _selectedStyle = _styles.firstObject;
    
    [self PT_updateSegmentedControl];
    
    [self PT_updateAnnotationStyleViewControllers];
}

- (NSString *)titleForStyle:(PTAnnotStyle *)style
{
    // Ask the delegate first for a custom style title.
    NSString *title = nil;
    if ([self.delegate respondsToSelector:@selector(multiAnnotStyleViewController:
                                                    titleForStyle:)]) {
        title = [self.delegate multiAnnotStyleViewController:self
                                               titleForStyle:style];
    }
    if (title) {
        return title;
    }

    NSString *localizedAnnotationName;
    
    if( style.annotType == PTExtendedAnnotTypeHighlight )
    {
        localizedAnnotationName = PTLocalizedString(@"Over Text", @"Combo tool active over text");
    }
    else
    {
        localizedAnnotationName = PTLocalizedAnnotationNameFromType(style.annotType);
    }
    if (localizedAnnotationName.length > 0) {
        return localizedAnnotationName;
    } else {
        return PTLocalizedString(@"Unknown",
                                 @"Unknown annotation type title");
    }
}

- (NSUInteger)selectedStyleIndex
{
    PTAnnotStyle *selectedStyle = self.selectedStyle;
    if (selectedStyle) {
        return [self.styles indexOfObjectIdenticalTo:selectedStyle];
    } else {
        return NSNotFound;
    }
}

- (void)setSelectedStyleIndex:(NSUInteger)index
{
    if (index >= self.styles.count) {
        NSString *reason = [NSString stringWithFormat:@"index %lu is beyond range of styles count %lu",
                            (unsigned long)index, (unsigned long)self.styles.count];
        @throw [NSException exceptionWithName:NSRangeException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    self.selectedStyle = self.styles[index];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedStyleIndex
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTMultiAnnotStyleViewController, selectedStyle),
    ]];
}

- (void)setSelectedStyle:(PTAnnotStyle *)style
{
    if (![self.styles containsObject:style]) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ is not in the list of styles: %@",
                            style, self.styles];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    _selectedStyle = style;
    
    [self PT_updateTitle];
    [self PT_updateSelectedSegmentIndex];
    [self PT_updateSelectedStyleViewController];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedStyle
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTMultiAnnotStyleViewController, styles),
    ]];
}

#pragma mark - Annotation style view controllers

@synthesize annotationStyleViewControllers = _annotationStyleViewControllers;

- (NSArray<PTAnnotStyleViewController *> *)annotationStyleViewControllers
{
    if (![self isViewLoaded]) {
        [self loadViewIfNeeded];
    }
    return _annotationStyleViewControllers;
}

- (void)PT_updateAnnotationStyleViewControllers
{
    if (self.annotationStyleViewControllers.count > 0) {
        for (PTAnnotStyleViewController *styleViewController in self.annotationStyleViewControllers) {
            [self pt_removeChildViewController:styleViewController withBlock:^{
                if ([styleViewController isViewLoaded]) {
                    [styleViewController.view removeFromSuperview];
                }
            }];
        }
    }
    
    NSMutableArray<PTAnnotStyleViewController *> *annotationStyleViewControllers = [NSMutableArray array];
    
    for (PTAnnotStyle *style in self.styles) {
        PTAnnotStyleViewController *styleViewController = nil;
        if (self.toolManager) {
            styleViewController = [[PTAnnotStyleViewController allocOverridden] initWithToolManager:self.toolManager
                                                                               annotStyle:style];
        } else {
            styleViewController = [[PTAnnotStyleViewController allocOverridden] initWithAnnotStyle:style];
        }
        
        [self pt_addChildViewController:styleViewController withBlock:^{
            // View will be added later for the selected style view controller.
        }];
        
        [annotationStyleViewControllers addObject:styleViewController];
    }
    
    _annotationStyleViewControllers = [annotationStyleViewControllers copy];
    
    [self PT_updateSelectedStyleViewController];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingAnnotationStyleViewControllers
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTMultiAnnotStyleViewController, styles),
    ]];
}

#pragma mark - Selected annotation style view controller

- (PTAnnotStyleViewController *)selectedAnnotationStyleViewController
{
    return _selectedStyleViewController;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedAnnotationStyleViewController
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTMultiAnnotStyleViewController, selectedStyle),
    ]];
}

- (void)PT_updateSelectedStyleViewController
{
    PTAnnotStyleViewController *previousSelectedStyleViewController = _selectedStyleViewController;
    if ([previousSelectedStyleViewController isViewLoaded]) {
        [previousSelectedStyleViewController.view removeFromSuperview];
    }
    
    _selectedStyleViewController = nil;
    
    const NSUInteger selectedIndex = self.selectedStyleIndex;
    if (selectedIndex == NSNotFound) {
        return;
    }
    
    PTAnnotStyleViewController *selectedStyleViewController = self.annotationStyleViewControllers[selectedIndex];
    
    _selectedStyleViewController = selectedStyleViewController;
    
    [self PT_attachStyleViewController:selectedStyleViewController];
}

- (void)PT_attachStyleViewController:(PTAnnotStyleViewController *)styleViewController
{
    styleViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.childViewControllerContainer addSubview:styleViewController.view];
    
    _needsLoadStyleViewControllerConstraints = YES;
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Segmented control

- (void)PT_updateSegmentedControl
{
    [self.segmentedControl removeAllSegments];
    
    for (PTAnnotStyle *style in self.styles.reverseObjectEnumerator) {
        NSString * const title = [self titleForStyle:style];
        [self.segmentedControl insertSegmentWithTitle:title
                                              atIndex:0
                                             animated:NO];
    }
    
    [self PT_updateSelectedSegmentIndex];
}

- (void)PT_updateSelectedSegmentIndex
{
    const NSUInteger selectedIndex = self.selectedStyleIndex;
    if (selectedIndex != NSNotFound) {
        self.segmentedControl.selectedSegmentIndex = (NSInteger)selectedIndex;
    } else {
        self.segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment;
    }
}

- (void)selectedSegmentDidChange:(UISegmentedControl *)segmentedControl
{
    if (segmentedControl != self.segmentedControl) {
        return;
    }
    
    const NSInteger selectedIndex = self.segmentedControl.selectedSegmentIndex;
    NSAssert(selectedIndex >= 0 && selectedIndex < self.styles.count,
             @"Selected segment index %ld must be in the range [0, %lu)",
             (long)selectedIndex, (unsigned long)self.styles.count);
    
    self.selectedStyleIndex = (NSUInteger)selectedIndex;
}

#pragma mark - Title

- (void)PT_updateTitle
{
    if (self.selectedStyle) {
        self.title = [self titleForStyle:self.selectedStyle];
    } else {
        self.title = nil;
    }
}

@end
