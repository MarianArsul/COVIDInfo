//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleTableViewController.h"

#import "PTAnnotStyleColorTableViewCell.h"
#import "PTAnnotStyleSliderTableViewCell.h"
#import "PTAnnotStyleTextFieldTableViewCell.h"
#import "PTAnnotStyleScaleTableViewCell.h"
#import "PTAnnotStylePrecisionTableViewCell.h"
#import "PTAnnotStyleSwitchTableViewCell.h"
#import "PTAnnotStyleFontTableViewCell.h"

#import "PTHalfModalPresentationController.h"
#import "PTToolsUtil.h"

#import "UIViewController+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStyleTableViewController () <PTAnnotStyleSliderTableViewCellDelegate, PTAnnotStyleTextFieldTableViewCellDelegate, PTAnnotStyleScaleTableViewCellDelegate, PTAnnotStylePrecisionTableViewCellDelegate, PTAnnotStyleSwitchTableViewCellDelegate>

@property (nonatomic, assign) BOOL editingScale;
@property (nonatomic, assign) BOOL editingPrecision;
@property (nonatomic, strong, nullable) NSIndexPath* scaleIndexPath;
@property (nonatomic, strong, nullable) NSIndexPath* precisionIndexPath;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotStyleTableViewController

static NSString * const PT_colorCellReuseIdentifier = @"ColorCell";
static NSString * const PT_sliderCellReuseIdentifier = @"SliderCell";
static NSString * const PT_textFieldCellReuseIdentifier = @"TextFieldCell";
static NSString * const PT_scaleCellReuseIdentifier = @"ScaleCell";
static NSString * const PT_precisionCellReuseIdentifier = @"PrecisionCell";
static NSString * const PT_switchCellReuseIdentifier = @"SwitchCell";
static NSString * const PT_fontCellReuseIdentifier = @"FontCell";

- (PTAnnotStyleTableViewItem *)tableViewItemForAnnotStyleKey:(PTAnnotStyleKey)key
{
    for (NSArray<PTAnnotStyleTableViewItem *> *section in self.items) {
        for (PTAnnotStyleTableViewItem *item in section) {
            if ([item.annotStyleKey isEqualToString:key]) {
                return item;
            }
        }
    }
    return nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.editingScale = NO;
    self.editingPrecision = NO;

    self.tableView.alwaysBounceVertical = NO;
    
    // Register table view cell classes and reuse identifiers.
    NSDictionary<NSString *, Class> * const cellClassReuseIdentifiers = @{
        PT_colorCellReuseIdentifier: [PTAnnotStyleColorTableViewCell class],
        PT_sliderCellReuseIdentifier: [PTAnnotStyleSliderTableViewCell class],
        PT_textFieldCellReuseIdentifier: [PTAnnotStyleTextFieldTableViewCell class],
        PT_scaleCellReuseIdentifier: [PTAnnotStyleScaleTableViewCell class],
        PT_precisionCellReuseIdentifier: [PTAnnotStylePrecisionTableViewCell class],
        PT_switchCellReuseIdentifier: [PTAnnotStyleSwitchTableViewCell class],
        PT_fontCellReuseIdentifier: [PTAnnotStyleFontTableViewCell class],
    };
    for (NSString *reuseIdentifier in cellClassReuseIdentifiers) {
        const Class cellClass = cellClassReuseIdentifiers[reuseIdentifier];
        
        [self.tableView registerClass:cellClass forCellReuseIdentifier:reuseIdentifier];
    }
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    [self updateBackground];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateBackground];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Hide virtual keyboard.
    [self.view endEditing:NO];
}

#pragma mark - Background color

- (BOOL)isInHalfModalPresentation
{
    if (!self.presentingViewController) {
        return NO;
    }
    
    UIViewController * const outermostViewController = self.pt_outermostViewController;
    
    if ((outermostViewController.modalPresentationStyle != UIModalPresentationCustom) ||
        !outermostViewController.transitioningDelegate) {
        return NO;
    }
    
    UIPresentationController * const presentationController = outermostViewController.presentationController;
    
    return [presentationController isKindOfClass:[PTHalfModalPresentationController class]];
}

- (BOOL)showsBackground
{
    return !([self pt_isInPopover] || [self isInHalfModalPresentation]);
}

- (UIColor *)backgroundColorForTableViewStyle:(UITableViewStyle)style
{
    switch (style) {
        case UITableViewStylePlain:
            if (@available(iOS 13.0, *)) {
                return UIColor.systemBackgroundColor;
            } else {
                return UIColor.whiteColor;
            }
        case UITableViewStyleGrouped:
        case UITableViewStyleInsetGrouped:
            if (@available(iOS 13.0, *)) {
                return UIColor.systemGroupedBackgroundColor;
            } else {
                return UIColor.groupTableViewBackgroundColor;
            }
    }
    return nil;
}

- (void)updateBackground
{
    if ([self showsBackground]) {
        self.tableView.backgroundColor = [self backgroundColorForTableViewStyle:self.tableView.style];
    } else {
        self.tableView.backgroundColor = nil;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateBackground];
}

- (void)setItems:(NSArray<NSArray<PTAnnotStyleTableViewItem *> *> *)items
{
    _items = items;

    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PTAnnotStyleTableViewItem *item = self.items[indexPath.section][indexPath.row];
    switch (item.type) {
        case PTAnnotStyleTableViewItemTypeFont:
        {
            PTAnnotStyleFontTableViewCell *cell = (PTAnnotStyleFontTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PT_fontCellReuseIdentifier forIndexPath:indexPath];
            [cell configureWithItem:(PTAnnotStyleFontTableViewItem *)item];
            return cell;
            break;
        }
        case PTAnnotStyleTableViewItemTypeColor:
        {
            PTAnnotStyleColorTableViewCell *cell = (PTAnnotStyleColorTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PT_colorCellReuseIdentifier forIndexPath:indexPath];
            [cell configureWithItem:(PTAnnotStyleColorTableViewItem *)item];
            return cell;
            break;
        }
        case PTAnnotStyleTableViewItemTypeSlider:
        {
            PTAnnotStyleSliderTableViewCell *cell = (PTAnnotStyleSliderTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PT_sliderCellReuseIdentifier forIndexPath:indexPath];
            [cell configureWithItem:(PTAnnotStyleSliderTableViewItem *)item];
            cell.delegate = self;
            return cell;
            break;
        }
        case PTAnnotStyleTableViewItemTypeTextField:
        {
            PTAnnotStyleTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PT_textFieldCellReuseIdentifier forIndexPath:indexPath];
            PTAnnotStyleTextFieldTableViewItem *textItem = (PTAnnotStyleTextFieldTableViewItem *)item;
            [cell configureWithItem:textItem];
            cell.delegate = self;
            return cell;
            break;
        }
        case PTAnnotStyleTableViewItemTypeScale:
        {
            PTAnnotStyleScaleTableViewCell *cell = (PTAnnotStyleScaleTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PT_scaleCellReuseIdentifier forIndexPath:indexPath];
            [cell configureWithItem:(PTAnnotStyleScaleTableViewItem *)item];
            cell.delegate = self;
            cell.editing = self.editingScale;
            self.scaleIndexPath = indexPath;
            return cell;
            break;
        }
        case PTAnnotStyleTableViewItemTypePrecision:
        {
            PTAnnotStylePrecisionTableViewCell *cell = (PTAnnotStylePrecisionTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PT_precisionCellReuseIdentifier forIndexPath:indexPath];
            [cell configureWithItem:(PTAnnotStylePrecisionTableViewItem *)item];
            cell.delegate = self;
            cell.editing = self.editingPrecision;
            self.precisionIndexPath = indexPath;
            return cell;
            break;
        }
        case PTAnnotStyleTableViewItemTypeSwitch:
        {
            PTAnnotStyleSwitchTableViewCell *cell = (PTAnnotStyleSwitchTableViewCell *) [tableView dequeueReusableCellWithIdentifier:PT_switchCellReuseIdentifier forIndexPath:indexPath];
            [cell configureWithItem:(PTAnnotStyleSwitchTableViewItem *)item];
            cell.delegate = self;
            return cell;
            break;
        }
    }
    // NOTE: There is no default case in the switch above to ensure that each item type is handled
    // and newly added types are not missed.
    
    // This should never be executed.
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[PTTableViewCell class]]) {
        // Disable the cell's background (color) - use the table view's background color instead.
        cell.backgroundColor = UIColor.clearColor;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Notify delegate of selection.
    if ([self.delegate respondsToSelector:@selector(tableViewController:didSelectItemAtIndexPath:)]) {
        [self.delegate tableViewController:self didSelectItemAtIndexPath:indexPath];
    }
    PTAnnotStyleTableViewItem *item = self.items[indexPath.section][indexPath.row];

    NSMutableArray *indexPaths = [NSMutableArray array];
    if (self.scaleIndexPath != nil) {
        [indexPaths addObject:self.scaleIndexPath];
    }
    if (self.precisionIndexPath != nil) {
        [indexPaths addObject:self.precisionIndexPath];
    }
    self.editingScale = (item.type == PTAnnotStyleTableViewItemTypeScale) ? !self.editingScale : NO;
    self.editingPrecision = (item.type == PTAnnotStyleTableViewItemTypePrecision) ? !self.editingPrecision : NO;

    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    if (item.type == PTAnnotStyleTableViewItemTypeScale || item.type == PTAnnotStyleTableViewItemTypePrecision) {
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // Notify delegate of selection.
    if ([self.delegate respondsToSelector:@selector(tableViewController:didSelectItemAtIndexPath:)]) {
        [self.delegate tableViewController:self didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark - <StyleSliderTableViewCellDelegate>

- (void)styleSliderTableViewCellSliderBeganSliding:(PTAnnotStyleSliderTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    // Notify delegate of slide start.
    if ([self.delegate respondsToSelector:@selector(tableViewController:sliderDidBeginSlidingForItemAtIndexPath:)]) {
        [self.delegate tableViewController:self sliderDidBeginSlidingForItemAtIndexPath:indexPath];
    }
}

- (void)styleSliderTableViewCell:(PTAnnotStyleSliderTableViewCell *)cell sliderValueDidChange:(float)value
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(tableViewController:sliderValueDidChange:forItemAtIndexPath:)]) {
        [self.delegate tableViewController:self sliderValueDidChange:value forItemAtIndexPath:indexPath];
    }

    // Update cell with value.
    PTAnnotStyleSliderTableViewItem *item = (PTAnnotStyleSliderTableViewItem *) self.items[indexPath.section][indexPath.row];
    [cell configureWithItem:item];
}

- (void)styleSliderTableViewCellSliderEndedSliding:(PTAnnotStyleSliderTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    // Notify delegate of slide end.
    if ([self.delegate respondsToSelector:@selector(tableViewController:sliderDidEndSlidingForItemAtIndexPath:)]) {
        [self.delegate tableViewController:self sliderDidEndSlidingForItemAtIndexPath:indexPath];
    }
}

#pragma mark - <PTAnnotStyleTextFieldTableViewCellDelegate>

- (void)styleTextFieldCell:(PTAnnotStyleTextFieldTableViewCell *)cell didChangeText:(NSString *)text
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    // Notify delegate of text field contents change.
    if ([self.delegate respondsToSelector:@selector(tableViewController:textFieldContentsDidChange:forItemAtIndexPath:)]) {
        [self.delegate tableViewController:self textFieldContentsDidChange:cell.textField.text forItemAtIndexPath:indexPath];
    }
}

- (void)styleTextFieldCell:(PTAnnotStyleTextFieldTableViewCell *)cell didCommitText:(NSString *)text
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    // Notify delegate of text field contents change.
    if ([self.delegate respondsToSelector:@selector(tableViewController:textFieldContentsDidChange:forItemAtIndexPath:)]) {
        [self.delegate tableViewController:self textFieldContentsDidChange:cell.textField.text forItemAtIndexPath:indexPath];
    }
}

#pragma mark - <StyleScaleTableViewCellDelegate>

- (void)styleScaleTableViewCell:(PTAnnotStyleScaleTableViewCell *)cell measurementScaleDidChange:(PTMeasurementScale *)ruler
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    // Notify delegate of ruler change.
    if ([self.delegate respondsToSelector:@selector(tableViewController:scaleDidChange:forItemAtIndexPath:)]) {
        [self.delegate tableViewController:self scaleDidChange:ruler forItemAtIndexPath:indexPath];
    }
    // Update cell with ruler.
    PTAnnotStyleScaleTableViewItem *item = (PTAnnotStyleScaleTableViewItem *) self.items[indexPath.section][indexPath.row];
    [cell configureWithItem:item];
}

#pragma mark - <StylePrecisionTableViewCellDelegate>

- (void)stylePrecisionTableViewCell:(PTAnnotStylePrecisionTableViewCell *)cell measurementScaleDidChange:(PTMeasurementScale *)ruler
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    // Notify delegate of ruler change.
    if ([self.delegate respondsToSelector:@selector(tableViewController:precisionDidChange:forItemAtIndexPath:)]) {
        [self.delegate tableViewController:self precisionDidChange:ruler forItemAtIndexPath:indexPath];
    }
    // Update cell with ruler.
    PTAnnotStylePrecisionTableViewItem *item = (PTAnnotStylePrecisionTableViewItem *) self.items[indexPath.section][indexPath.row];
    [cell configureWithItem:item];
}

#pragma mark - <StyleSwitchTableViewCellDelegate>

- (void)styleSwitchTableViewCell:(PTAnnotStyleSwitchTableViewCell *)cell snappingToggled:(BOOL)snappingEnabled
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    // Notify delegate of ruler change.
    if ([self.delegate respondsToSelector:@selector(tableViewController:snappingToggled:forItemAtIndexPath:)]) {
        [self.delegate tableViewController:self snappingToggled:snappingEnabled forItemAtIndexPath:indexPath];
    }
    PTAnnotStyleSwitchTableViewItem *item = (PTAnnotStyleSwitchTableViewItem *) self.items[indexPath.section][indexPath.row];
    [cell configureWithItem:item];
}

@end
