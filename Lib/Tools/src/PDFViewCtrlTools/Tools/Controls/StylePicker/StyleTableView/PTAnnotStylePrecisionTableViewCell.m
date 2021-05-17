//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStylePrecisionTableViewCell.h"

static const NSInteger PT_rowsInPicker = 5;

@interface PTAnnotStylePrecisionTableViewCell () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, strong) UIPickerView *precisionPickerView;

@property (nonatomic) BOOL didSetupConstraints;

@end

@implementation PTAnnotStylePrecisionTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentFill;
        _stackView.distribution = UIStackViewDistributionFillProportionally;
        _stackView.spacing = 10.0;
        
        _stackView.preservesSuperviewLayoutMargins = YES;
        _stackView.layoutMarginsRelativeArrangement = YES;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_stackView];
        
        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentNatural;
        [_stackView addArrangedSubview:_label];

        _precisionLabel = [[UILabel alloc] init];
        _precisionPickerView = [[UIPickerView alloc] init];
        _precisionPickerView.delegate = self;
        _precisionPickerView.dataSource = self;

        [_stackView addArrangedSubview:_precisionLabel];

        // Cell is not selectable.
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Schedule constraints update.
        [self setNeedsUpdateConstraints];

    }
    return self;
}

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
    if (editing) {
        if(self.precisionLabel.superview){
            [self.precisionLabel removeFromSuperview];
        }
        [self.stackView addArrangedSubview:self.precisionPickerView];
    }else{
        if(self.precisionPickerView.superview){
            [self.precisionPickerView removeFromSuperview];
        }
        [self.stackView addArrangedSubview:self.precisionLabel];
    }
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
           [self.stackView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
           [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
           [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
           [self.label.widthAnchor constraintEqualToConstant:100.0]
           ]];
        
        // Constraints are set up.
        self.didSetupConstraints = YES;
    }
    
    [super updateConstraints];
}

- (void)configureWithItem:(PTAnnotStylePrecisionTableViewItem *)item
{
    self.label.text = item.title;
    self.measurementScale = item.measurementScale;
    NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
    format.minimumIntegerDigits = 1;
    format.maximumFractionDigits = 4;
    double mPrecision = 1.0f/(double)self.measurementScale.precision;
    NSString *precisionString = [format stringFromNumber:[NSNumber numberWithDouble:mPrecision]];
    self.precisionLabel.text = precisionString;
    int idx = log10(self.measurementScale.precision);
    // if the precision is higher than the last entry in the picker, select the last entry
    idx = MIN(idx,(int)[self.precisionPickerView numberOfRowsInComponent:0]-1);
    [self.precisionPickerView selectRow:idx inComponent:0 animated:NO];
}

#pragma mark - UIPickerView Delegate

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return PT_rowsInPicker;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
    format.minimumIntegerDigits = 1;
    format.maximumFractionDigits = 4;
    double mPrecision = 1.0/pow(10.0, row);
    NSString *precisionString = [format stringFromNumber:[NSNumber numberWithDouble:mPrecision]];
    return precisionString;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    double precision = pow(10.0, row);
    self.measurementScale.precision = (int)precision;
    [self measurementScaleChanged];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{

    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        [pickerLabel setFont:[UIFont systemFontOfSize:self.precisionLabel.font.pointSize]];
        pickerLabel.textAlignment = NSTextAlignmentCenter;

    }
    // Fill the label text here
    NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
    format.minimumIntegerDigits = 1;
    format.maximumFractionDigits = 4;
    double mPrecision = 1.0/pow(10.0, row);
    NSString *precisionString = [format stringFromNumber:[NSNumber numberWithDouble:mPrecision]];
    pickerLabel.text = precisionString;

    return pickerLabel;
}

#pragma mark - Report Changes

- (void)measurementScaleChanged
{
    if ([self.delegate respondsToSelector:@selector(stylePrecisionTableViewCell:measurementScaleDidChange:)]) {
        [self.delegate stylePrecisionTableViewCell:self measurementScaleDidChange:self.measurementScale];
    }
}

@end
