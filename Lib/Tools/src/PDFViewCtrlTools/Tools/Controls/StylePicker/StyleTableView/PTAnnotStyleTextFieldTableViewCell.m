//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleTextFieldTableViewCell.h"

@interface PTAnnotStyleTextFieldTableViewCell ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, assign) BOOL needsConstraintsSetup;

@end

@implementation PTAnnotStyleTextFieldTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Set up stack view container.
        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentFill;
        _stackView.distribution = UIStackViewDistributionFill;
        _stackView.spacing = 10.0;
        
        _stackView.preservesSuperviewLayoutMargins = YES;
        _stackView.layoutMarginsRelativeArrangement = YES;
        // Must be done *before* adding to content view, otherwise the stack view will get its
        // autoresizing-mask constraints added (with zero width/height) before the updateConstraints
        // method is called to add the real constraints.
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_stackView];

        // Label.
        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentNatural;
        [_stackView addArrangedSubview:_label];
        
        // Text field.
        _textField = [[UITextField alloc] initWithFrame:UIEdgeInsetsInsetRect(self.contentView.bounds, self.contentView.layoutMargins)];
        _textField.font = [UIFont systemFontOfSize:14.0];
        _textField.returnKeyType = UIReturnKeyDone;
        
        _textField.delegate = self;
        
        [_stackView addArrangedSubview:_textField];
        
        self.needsConstraintsSetup = YES;
        [self setNeedsUpdateConstraints];
        
        // Cell is not selectable.
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)updateConstraints
{
    if (self.needsConstraintsSetup) {
        // Set up constraints.
        self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.textField.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
           [self.stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
           [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
           [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
           
           [self.label.widthAnchor constraintEqualToConstant:100.0],
           ]];

        self.needsConstraintsSetup = NO;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

- (void)configureWithItem:(PTAnnotStyleTextFieldTableViewItem *)item
{
    self.label.text = item.title;
    
    self.textField.placeholder = item.title;
    self.textField.text = item.text;
}

#pragma mark - <UITextFieldDelegate>

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Start observing text changes.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(textFieldTextDidChange:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Dismiss keyboard.
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason
{
    // Stop observing text changes.
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:textField];
    
    if (reason == UITextFieldDidEndEditingReasonCommitted) {
        // Notify delegate of text commitment.
        if ([self.delegate respondsToSelector:@selector(styleTextFieldCell:didCommitText:)]) {
            [self.delegate styleTextFieldCell:self didCommitText:textField.text];
        }
    }
}

#pragma mark - UITextField notifications

- (void)textFieldTextDidChange:(NSNotification *)notification
{
    if (notification.object != self.textField) {
        return;
    }
    
    // Notify delegate of text change.
    if ([self.delegate respondsToSelector:@selector(styleTextFieldCell:didChangeText:)]) {
        [self.delegate styleTextFieldCell:self didChangeText:self.textField.text];
    }
}

@end
