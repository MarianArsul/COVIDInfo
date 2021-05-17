//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTNoteEditController.h"

#import "PTToolsUtil.h"

@interface PTNoteEditController ()

// delegate is strong because it needs to hold onto the object as long
// as it exists itself.
@property (nonatomic, strong) id<PTNoteEditControllerDelegate> delegate;

@property (nonatomic) PTExtendedAnnotType annotType;

@property (nonatomic, readwrite, strong) UITextView *textView;

@end

@implementation PTNoteEditController

- (instancetype)initWithDelegate:(id<PTNoteEditControllerDelegate>)delegate annotType:(PTExtendedAnnotType)annotType
{
	self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _delegate = delegate;
        _annotType = annotType;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIBarButtonItem *cancelButton;
    
    // Show a "Delete" button for text (sticky note) annotations.
    if (self.annotType == PTExtendedAnnotTypeText && ![self isReadonly])
    {
        cancelButton = [[UIBarButtonItem alloc] initWithTitle:PTLocalizedString(@"Delete", @"") style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonPressed)];
    }
    else {
        cancelButton = [[UIBarButtonItem alloc] initWithTitle:PTLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    }
    
    [self.navigationItem setLeftBarButtonItem:cancelButton animated:NO];
    
    self.navigationItem.title = PTLocalizedString(@"Note", @"The note associated with the PDF annotation.");
	
	// now save via popover dismissal on iPad
	if( [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone && ![self isReadonly])
	{
		UIBarButtonItem *okButton = [[UIBarButtonItem alloc] initWithTitle:PTLocalizedString(@"Save", @"") style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonPressed)];
		[self.navigationItem setRightBarButtonItem:okButton animated:NO];
	}

    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.font = [UIFont fontWithName:@"Helvetica" size:16];
    
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.textView];
    
    if (@available(iOS 11, *)) {
        // The below behavior should handle safe area content insets,
        // but when there is no text the leading inset disappears.
        //tv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
        
        // Workaround for the issue described above.
        UIEdgeInsets safeInsets = self.view.safeAreaInsets;
        UIEdgeInsets oldInsets = self.textView.contentInset;
        [self.textView setContentInset:UIEdgeInsetsMake(oldInsets.top, safeInsets.left, oldInsets.bottom, safeInsets.right)];
    }
    
    // Disable editing in readonly mode.
    self.textView.editable = !self.readonly;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardWillShowOrHide:)
                                                 name: UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardWillShowOrHide:)
                                                 name: UIKeyboardWillHideNotification object:nil];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    
    // Update safe area content insets manually.
    // This is a workaround for the issue described in -viewDidLoad.
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    UIEdgeInsets oldInsets = self.textView.contentInset;
    [self.textView setContentInset:UIEdgeInsetsMake(oldInsets.top, safeInsets.left, oldInsets.bottom, safeInsets.right)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.textView becomeFirstResponder];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)isPopover
{
    
    // https://stackoverflow.com/a/31656088

    if (self.navigationController.popoverPresentationController.barButtonItem || (self.navigationController.popoverPresentationController.sourceView && !CGRectIsEmpty(self.navigationController.popoverPresentationController.sourceRect))) {
        return YES;
    }
    return NO;
}

-(void)keyboardWillShowOrHide:(NSNotification *)notification
{
    CGRect cursorRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.start];

    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;

    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    CGRect convertedEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.window];
    CGFloat heightDelta = CGRectGetMinY(convertedEndFrame) - CGRectGetMaxY(self.view.bounds);
    if (@available(iOS 11, *)) {
        heightDelta += heightDelta < 0 ? self.view.safeAreaInsets.bottom : 0;
    }

    if (![self isPopover]) {
        UIEdgeInsets contentInsets = self.textView.contentInset;
        contentInsets.bottom  = -heightDelta + 10;
        self.textView.contentInset = contentInsets;
        self.textView.scrollIndicatorInsets = self.textView.contentInset;
    }
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | animationCurve animations:^{
        [self.textView scrollRectToVisible:cursorRect animated:NO];
    } completion:nil];
}

- (UITextView *)textView
{
    if (!_textView) {
        [self loadViewIfNeeded];
    }
    NSAssert(_textView != nil, @"Failed to set up text view");
    
    return _textView;
}

- (void)setReadonly:(BOOL)readonly
{
    _readonly = readonly;
    
    // Disable editing in readonly mode.
    self.textView.editable = !readonly;
}

#pragma mark - Note contents

- (void)setNoteString:(NSString *)noteString
{
    self.textView.text = noteString;
}

- (NSString *)noteString
{
    return self.textView.text;
}

#pragma mark - Button actions

- (void)cancelButtonPressed
{
    [self.textView resignFirstResponder];
    
    // callback to have it closed
    if ([self.delegate respondsToSelector:@selector(noteEditController:cancelButtonPressed:)]) {
        [self.delegate noteEditController:self cancelButtonPressed:YES];
    }
}

- (void)deleteButtonPressed
{
    [self.textView resignFirstResponder];
    
    if (![self isReadonly]) {
        if ([self.delegate respondsToSelector:@selector(noteEditControllerDeleteSelectedAnnotation:)]) {
            [self.delegate noteEditControllerDeleteSelectedAnnotation:self];
        }
    }

    // callback to have it closed
    if ([self.delegate respondsToSelector:@selector(noteEditController:cancelButtonPressed:)]) {
        [self.delegate noteEditController:self cancelButtonPressed:NO];
    }
}

- (void)saveButtonPressed
{
    if ([self.delegate respondsToSelector:@selector(noteEditController:saveNewNoteForMovingAnnotationWithString:)]) {
        [self.delegate noteEditController:self saveNewNoteForMovingAnnotationWithString:self.noteString];
    }
}

@end
