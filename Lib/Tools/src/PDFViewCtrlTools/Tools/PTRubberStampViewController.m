//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTRubberStampViewController.h"
#import "PTRubberStampCell.h"

#import "PTToolsUtil.h"

#import "NSLayoutConstraint+PTPriority.h"
#import "UIViewController+PTAdditions.h"
#import "UIView+PTAdditions.h"
#import "UIBarButtonItem+PTAdditions.h"

static NSString * const PT_RubberStampCellIdentifier = @"rubberStampCellIdentifier";
static NSString * const PT_RubberStampHeaderIdentifier = @"rubberStampHeaderIdentifier";

NS_ASSUME_NONNULL_BEGIN

@interface PTRubberStampHeader : UICollectionReusableView <UIToolbarDelegate>

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UISegmentedControl* segmentedControl;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

@implementation PTRubberStampHeader

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Use a toolbar as the background view to get the same appearance as a UINavigationBar.
        _toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _toolbar.delegate = self;
        
        [self addSubview:_toolbar];
        
        self.layoutMargins = UIEdgeInsetsMake(8, 0, 8, 0);
        
        _segmentedControl = [[UISegmentedControl alloc] init];
        _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:_segmentedControl];
        
        // Schedule constraints load.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutMarginsGuide = self.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        // Center segmented control in superview.
        [self.segmentedControl.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.segmentedControl.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        // Pin segmented control to top and bottom of layout margins.
        [self.segmentedControl.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor],
        [self.segmentedControl.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
        
        // Leading and trailing edges must be within the layout margins area.
        [self.segmentedControl.leadingAnchor constraintGreaterThanOrEqualToAnchor:layoutMarginsGuide.leadingAnchor],
        [self.segmentedControl.trailingAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.trailingAnchor],
    ]];
    
    // Make segmented control as small as possible, respecting its intrinsicContentSize.
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.segmentedControl.widthAnchor constraintEqualToConstant:0],
        [self.segmentedControl.heightAnchor constraintEqualToConstant:0],
    ] withPriority:UILayoutPriorityDefaultLow];
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

#pragma mark - Hierarchy

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        [self updateToolbar];
    }
}

#pragma mark - Toolbar

- (void)updateToolbar
{
    // Find the view's containing navigation controller.
    UINavigationController *navigationController = self.pt_viewController.navigationController;
    if (!navigationController) {
        return;
    }
    
    // Synchronize toolbar appearance with navigation bar.
    UINavigationBar *navigationBar = navigationController.navigationBar;
    
    self.toolbar.barStyle = navigationBar.barStyle;
    self.toolbar.barTintColor = navigationBar.barTintColor;
    self.toolbar.tintColor = navigationBar.tintColor;
    self.toolbar.translucent = navigationBar.translucent;
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

@end

@interface PTRubberStampViewController ()

@property (nonatomic, readwrite, strong) UICollectionView *collectionView;

@property (nonatomic, assign) BOOL didSetupConstraints;

@property (nonatomic, assign) BOOL showingStandardStamps;

@property (nonatomic, strong) UIBarButtonItem *addStampButton;

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@end

@implementation PTRubberStampViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    _rubberStampManager = [[PTRubberStampManager allocOverridden] init];
    self.showingStandardStamps = YES;
    [self.navigationController setToolbarHidden:self.showingStandardStamps animated:YES];
    self.addStampButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addStampsButtonPressed:)];
    [self setToolbarItems:@[[UIBarButtonItem pt_flexibleSpaceItem], self.addStampButton] animated:NO];

    self.doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    [self.navigationItem setRightBarButtonItem:self.doneButtonItem animated:NO];

    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    collectionViewLayout.sectionHeadersPinToVisibleBounds = YES;
    const CGFloat spacing = 10.0;
    collectionViewLayout.minimumLineSpacing = spacing;
    collectionViewLayout.minimumInteritemSpacing = spacing;

    collectionViewLayout.sectionInset = UIEdgeInsetsMake(spacing, spacing,
                                                 spacing, spacing);

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:collectionViewLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.alwaysBounceVertical = YES;

    [self.collectionView registerClass:[PTRubberStampCell class] forCellWithReuseIdentifier:PT_RubberStampCellIdentifier];

//    collectionViewLayout.headerReferenceSize = CGSizeMake(100,46);
//    [self.collectionView registerClass:[PTRubberStampHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PT_RubberStampHeaderIdentifier];

    self.collectionView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    [self.view addSubview:self.collectionView];
   if (@available(iOS 11, *)) {
        // Inset sections (cells) from safe area.
        // NOTE: This does *not* inset the section headers/footers, unlike the
        // UIScrollView contentInsetAdjustmentBehavior.
        collectionViewLayout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    }

    NSString *title = PTLocalizedString(@"Rubber Stamps", @"Rubber Stamp browser title");;
    if (self.title.length == 0) {
        self.title = title;
    }
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.collectionView flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if ([self.delegate respondsToSelector:@selector(rubberStampControllerWasDismissed:)]) {
        [self.delegate rubberStampControllerWasDismissed:self];
    }
}

- (void)updateViewConstraints
{
    if (!self.didSetupConstraints) {
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
           [self.collectionView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
           [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
           [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
           ]];
        
        // Constraints are set up.
        self.didSetupConstraints = YES;
    }
    
    // Call super implementation as final step.
    [super updateViewConstraints];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Force layout invalidation when size changes because item sizes need to be updated.
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - header


//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
//{
//    return CGSizeMake(self.view.frame.size.width, 46.0);
//}
//
//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
//           viewForSupplementaryElementOfKind:(NSString *)kind
//                                 atIndexPath:(NSIndexPath *)indexPath
//{
//
//    PTRubberStampHeader* headerView = [collectionView dequeueReusableSupplementaryViewOfKind:
//                                         UICollectionElementKindSectionHeader withReuseIdentifier:PT_RubberStampHeaderIdentifier forIndexPath:indexPath];
//    [headerView.segmentedControl removeAllSegments];
//    [headerView.segmentedControl insertSegmentWithTitle:PTLocalizedString(@"Standard", @"Standard rubber stamps title") atIndex:0 animated:NO];
//    [headerView.segmentedControl insertSegmentWithTitle:PTLocalizedString(@"Custom", @"Custom rubber stamps title") atIndex:1 animated:NO];
//    headerView.segmentedControl.selectedSegmentIndex = self.showingStandardStamps ? 0 : 1;
//    [headerView.segmentedControl addTarget:self
//                                    action:@selector(segmentedControlValueChanged:)
//                          forControlEvents:UIControlEventValueChanged];
//    headerView.segmentedControl.enabled = !self.editing;
//
//    return headerView;
//}

-(void)segmentedControlValueChanged:(UISegmentedControl*)segmentedControl
{
    self.showingStandardStamps = !self.showingStandardStamps;
    [self.collectionView reloadData];
    [self.navigationController setToolbarHidden:self.showingStandardStamps animated:YES];
}

#pragma mark - Actions

-(void)doneButtonPressed:(UIBarButtonItem*)button
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)addStampsButtonPressed:(UIBarButtonItem*)button
{
    
}

#pragma mark - UICollectionViewDelegateFlowLayout methods

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect containerBounds = collectionView.bounds;
    
    // Inset bounds by contentInset.
    UIEdgeInsets contentInset = collectionView.contentInset;
    if (@available(iOS 11, *)) {
        contentInset = collectionView.adjustedContentInset;
    }
    
    containerBounds = UIEdgeInsetsInsetRect(containerBounds, contentInset);
    
    // Inset bounds by sectionInset.
    UIEdgeInsets sectionInset = UIEdgeInsetsZero;
    CGFloat interitemSpacing = 0;
    if ([collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
        
        sectionInset = flowLayout.sectionInset;
        
        interitemSpacing = flowLayout.minimumInteritemSpacing;
    }
    
    containerBounds = UIEdgeInsetsInsetRect(containerBounds, sectionInset);
    
    CGSize containerSize = containerBounds.size;
    containerSize.width -= interitemSpacing;
    
    return CGSizeMake(containerSize.width/2, 60);
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.rubberStampManager.numberOfStandardStamps;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTRubberStampCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PT_RubberStampCellIdentifier forIndexPath:indexPath];
    PTCustomStampOption *option = [self.rubberStampManager.standardStampOptions objectAtIndex:indexPath.item];
    CGRect rect = cell.bounds;
    cell.imageView.image = [PTRubberStampManager getBitMapForStampWithHeight:rect.size.height width:rect.size.width option:option];
    return cell;
}

#pragma mark - UICollectionViewDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PTCustomStampOption *option = [self.rubberStampManager.standardStampOptions objectAtIndex:indexPath.item];
    [self.delegate rubberStampController:self addStamp:option];
}

@end
NS_ASSUME_NONNULL_END
