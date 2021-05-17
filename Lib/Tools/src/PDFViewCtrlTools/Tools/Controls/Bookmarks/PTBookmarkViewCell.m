//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTBookmarkViewCell.h"

@implementation PTBookmarkViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _textField = [[UITextField alloc] initWithFrame:UIEdgeInsetsInsetRect(self.contentView.bounds, self.contentView.layoutMargins)];
        _textField.font = [UIFont systemFontOfSize:14.0];
        _textField.returnKeyType = UIReturnKeyDone;
        
        _textField.delegate = self;
        
        _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                
        [self.contentView addSubview:_textField];
        
        self.accessoryType = UITableViewCellAccessoryNone;
        
        [self reset];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.textField.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, self.contentView.layoutMargins);
}

- (void)reset
{
    self.editing = NO;
}

- (void)configureWithText:(NSString *)text
{
    self.textField.text = text;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.editing = NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.textFieldEditable = editing;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state.
}

- (void)setTextFieldEditable:(BOOL)editable
{
    _textFieldEditable = editable;
    
    self.textField.userInteractionEnabled = editable;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return [self isTextFieldEditable];
}

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
        if ([self.delegate respondsToSelector:@selector(bookmarkViewCell:didCommitText:)]) {
            [self.delegate bookmarkViewCell:self didCommitText:textField.text];
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
    if ([self.delegate respondsToSelector:@selector(bookmarkViewCell:didChangeText:)]) {
        [self.delegate bookmarkViewCell:self didChangeText:self.textField.text];
    }
}

@end
