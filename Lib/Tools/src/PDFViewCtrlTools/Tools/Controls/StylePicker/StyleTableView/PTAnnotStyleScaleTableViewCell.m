//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotStyleScaleTableViewCell.h"
#import "PTMeasurementUtil.h"
#import "PTToolsUtil.h"

@interface PTAnnotStyleScaleTableViewCell () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIStackView *scaleStackView;

@property (nonatomic, strong) UIToolbar *toolbar;

@property (nonatomic, strong) UIPickerView *baseUnitPickerView;
@property (nonatomic, strong) NSArray *baseUnitsArray;

@property (nonatomic, strong) UIPickerView *translateUnitPickerView;
@property (nonatomic, strong) NSArray *translateUnitsArray;

@property (nonatomic, strong) UILabel *baseValueLabel;
@property (nonatomic, strong) UILabel *baseUnitLabel;
@property (nonatomic, strong) UILabel *equalsLabel;
@property (nonatomic, strong) UILabel *translateValueLabel;
@property (nonatomic, strong) UILabel *translateUnitLabel;

@property (nonatomic) BOOL isArea;

@property (nonatomic) UITextField *activeTextField;

@property (nonatomic) BOOL didSetupConstraints;

@end

@implementation PTAnnotStyleScaleTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentFill;
        _stackView.distribution = UIStackViewDistributionFill;
        _stackView.spacing = 10.0;
        
        _stackView.preservesSuperviewLayoutMargins = YES;
        _stackView.layoutMarginsRelativeArrangement = YES;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_stackView];

        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentNatural;
        [_stackView addArrangedSubview:_label];
        
        _toolbar = [[UIToolbar alloc] init];
        [_toolbar sizeToFit];
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissInput)];
        [_toolbar setItems:@[flex, done]];
        
        _baseValueTextField = [[UITextField alloc] init];
        _baseValueTextField.keyboardType = UIKeyboardTypeDecimalPad;
        _baseValueTextField.delegate = self;
        _baseValueTextField.inputAccessoryView = _toolbar;
        _baseValueTextField.textAlignment = NSTextAlignmentCenter;
        
        _baseUnitPickerView = [[UIPickerView alloc] init];
        _baseUnitPickerView.delegate = self;
        _baseUnitPickerView.dataSource = self;
        
        _translateValueTextField = [[UITextField alloc] init];
        _translateValueTextField.keyboardType = UIKeyboardTypeDecimalPad;
        _translateValueTextField.delegate = self;
        _translateValueTextField.inputAccessoryView = _toolbar;
        _translateValueTextField.textAlignment = NSTextAlignmentCenter;
        
        _translateUnitPickerView = [[UIPickerView alloc] init];
        _translateUnitPickerView.delegate = self;
        _translateUnitPickerView.dataSource = self;

        _baseValueLabel = [[UILabel alloc] init];
        _baseUnitLabel = [[UILabel alloc] init];
        _translateValueLabel = [[UILabel alloc] init];
        _translateUnitLabel = [[UILabel alloc] init];
        _equalsLabel = [[UILabel alloc] init];
        _equalsLabel.text = @"=";

        _scaleStackView = [[UIStackView alloc] init];
        _scaleStackView.axis = UILayoutConstraintAxisHorizontal;
        _scaleStackView.alignment = UIStackViewAlignmentFill;
        _scaleStackView.distribution = UIStackViewDistributionFillEqually;
        _scaleStackView.spacing = 10.0;
        
        _scaleStackView.preservesSuperviewLayoutMargins = YES;
        _scaleStackView.layoutMarginsRelativeArrangement = YES;
        [_stackView addArrangedSubview:_scaleStackView];
        
        [self setPickerData];
        [self configureStackView:_scaleStackView editing:NO];

        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
        [_baseValueTextField setUserInteractionEnabled:NO];
        [_baseUnitPickerView setUserInteractionEnabled:NO];
        [_translateValueTextField setUserInteractionEnabled:NO];
        [_translateUnitPickerView setUserInteractionEnabled:NO];
    }
    return self;
}

-(void)configureStackView:(UIStackView*)stackView editing:(BOOL)editing
{
    for (UIView *view in stackView.subviews) {
        [view removeFromSuperview];
    }
    if (editing) {
        [stackView addArrangedSubview:self.baseValueTextField];
        [stackView addArrangedSubview:self.baseUnitPickerView];
    }else{
        [stackView addArrangedSubview:self.baseValueLabel];
        [stackView addArrangedSubview:self.baseUnitLabel];
    }
    [stackView addArrangedSubview:self.equalsLabel];
    if (editing) {
        [stackView addArrangedSubview:self.translateValueTextField];
        [stackView addArrangedSubview:self.translateUnitPickerView];
    }else{
        [stackView addArrangedSubview:self.translateValueLabel];
        [stackView addArrangedSubview:self.translateUnitLabel];
    }
}

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    [self.baseValueTextField setUserInteractionEnabled:editing];
    [self.baseUnitPickerView setUserInteractionEnabled:editing];
    [self.translateValueTextField setUserInteractionEnabled:editing];
    [self.translateUnitPickerView setUserInteractionEnabled:editing];
    [self configureStackView:self.scaleStackView editing:editing];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.toolbar.tintColor = self.tintColor;
    self.baseValueTextField.textColor = self.tintColor;
    self.translateValueTextField.textColor = self.tintColor;
}

-(void)setPickerData{
     self.baseUnitsArray = @[@"pt",
                             @"in",
                             @"mm",
                             @"cm"];
    
    self.translateUnitsArray = [PTMeasurementUtil realWorldUnits];
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        // Perform setup of constraints.
        self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:
         @[
           [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
           [self.stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
           [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
           [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
           
           [self.label.widthAnchor constraintEqualToConstant:100.0],
           ]];
        
        // Constraints are set up.
        self.didSetupConstraints = YES;
    }
    
    [super updateConstraints];
}

- (void)configureWithItem:(PTAnnotStyleScaleTableViewItem *)item
{
    self.label.text = item.title;
    self.measurementScale = item.measurementScale;
    self.isArea = NO;
    
    // If this is an area measurement then we need to ignore the 'sq ' part of the unit to match to the picker data.
    NSArray *unitComponents = [self.measurementScale.translateUnit componentsSeparatedByString:@" "];
    self.isArea = unitComponents.count > 1;

    NSString *mTranslateUnit = [self.measurementScale.translateUnit componentsSeparatedByString:@" "].lastObject;

    NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
    format.minimumIntegerDigits = 1;
    format.minimumFractionDigits = 1;
    format.maximumFractionDigits = 2;
    self.baseValueTextField.text = [format stringFromNumber:[NSNumber numberWithDouble:self.measurementScale.baseValue]];
    self.baseValueLabel.text = [format stringFromNumber:[NSNumber numberWithDouble:self.measurementScale.baseValue]];

    self.baseUnitLabel.text = self.measurementScale.baseUnit;
    self.translateValueTextField.text = [format stringFromNumber:[NSNumber numberWithDouble:self.measurementScale.translateValue]];
    self.translateValueLabel.text = [format stringFromNumber:[NSNumber numberWithDouble:self.measurementScale.translateValue]];
    self.translateUnitLabel.text = mTranslateUnit;
    NSInteger baseIdx = [self.baseUnitsArray indexOfObject:self.measurementScale.baseUnit];
    NSInteger translateIdx = [self.translateUnitsArray indexOfObject:mTranslateUnit];
    [self.baseUnitPickerView selectRow:baseIdx inComponent:0 animated:NO];
    [self.translateUnitPickerView selectRow:translateIdx inComponent:0 animated:NO];
}

#pragma mark - UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *entry = [textField.text stringByAppendingString:string];
    // Only allow numbers
    if (textField == self.baseValueTextField || textField == self.translateValueTextField) {
        NSNumber* value = nil;
        NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
        value  = [format numberFromString:entry];
        // NSNumberFormatter will return nil if it can't parse the string into a valid number
        if (value == nil && ![entry isEqualToString:@"."]){
            return NO;
        }
    }
    // Limit the scale to a maximum of 4 characters
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
    double baseValue = [[format numberFromString:self.baseValueTextField.text] doubleValue];
    self.measurementScale.baseValue = MAX(baseValue, 0.01);
    double translateValue = [[format numberFromString:self.translateValueTextField.text] doubleValue];
    self.measurementScale.translateValue = MAX(translateValue, 0.01);
    [self measurementScaleChanged];
    self.activeTextField = nil;
}

#pragma mark - UIPickerView Delegate

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.translateUnitPickerView) {
        return self.translateUnitsArray.count;
    }
    return self.baseUnitsArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (pickerView == self.translateUnitPickerView) {
        return [self.translateUnitsArray objectAtIndex:row];
    }
    return [self.baseUnitsArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.measurementScale.baseUnit = [self.baseUnitsArray objectAtIndex:[self.baseUnitPickerView selectedRowInComponent:0]];
    NSString *translateUnit = [self.translateUnitsArray objectAtIndex:[self.translateUnitPickerView selectedRowInComponent:0]];
    if (self.isArea) {
        translateUnit = [@"sq " stringByAppendingString:translateUnit];
    }
    self.measurementScale.translateUnit = translateUnit;
    [self measurementScaleChanged];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{

    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        [pickerLabel setFont:[UIFont systemFontOfSize:self.baseValueTextField.font.pointSize]];
        pickerLabel.textAlignment = NSTextAlignmentCenter;

    }
    // Fill the label text here
    pickerLabel.text = (pickerView == self.translateUnitPickerView) ? [self.translateUnitsArray objectAtIndex:row] :  [self.baseUnitsArray objectAtIndex:row];

    return pickerLabel;
}

#pragma mark - Report Changes

- (void)measurementScaleChanged
{
    if ([self.delegate respondsToSelector:@selector(styleScaleTableViewCell:measurementScaleDidChange:)]) {
        [self.delegate styleScaleTableViewCell:self measurementScaleDidChange:self.measurementScale];
    }
}

#pragma mark - Toolbar Actions

-(void)dismissInput {
    [self.activeTextField endEditing:YES];
}

@end
