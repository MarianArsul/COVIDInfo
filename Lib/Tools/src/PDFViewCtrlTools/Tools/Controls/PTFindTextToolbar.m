//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFindTextToolbar.h"

#import "PTToolsUtil.h"

@interface PTFindTextToolbar() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) UIButton *previousButton;

@property (nonatomic, strong) UIView *buttonHolder;

@end

@implementation PTFindTextToolbar

@dynamic delegate;

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // Initialization code.
        _pdfViewCtrl = pdfViewCtrl;
        
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.delegate = self;
        _searchBar.placeholder = PTLocalizedString(@"Text Search", @"Placeholder for text search bar");
        _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        BOOL isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
        
        UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
        UIBarButtonItem *flexSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        // Left-align search bar for phones, right-align for others.
        self.items =
        @[
          (isPhone ? searchBarItem : flexSpaceItem),
          (isPhone ? flexSpaceItem : searchBarItem),
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doCancel:)],
          ];
        
        CGFloat deviceWidth = [UIScreen mainScreen].bounds.size.width-77;
        
        if (@available(iOS 11, *)) {
            
            NSLayoutConstraint *widthConstraint = [_searchBar.widthAnchor constraintGreaterThanOrEqualToConstant:deviceWidth];
            widthConstraint.priority = UILayoutPriorityDefaultHigh;
            widthConstraint.active = YES;
        } else {
            _searchBar.frame = CGRectMake(0.0, 0.0, deviceWidth, self.frame.size.height);
            _searchBar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        }
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    if (!newSuperview) {
        // Removed from superview.
        [self removeButtons:YES];
    }
}

-(void)searchBarBecomeFirstResponder
{
    [self.pdfViewCtrl CancelFindText];
    
    [self.searchBar becomeFirstResponder];
}

- (void)doCancel: (UIBarButtonSystemItem*)barButton
{
    [self.searchBar resignFirstResponder];
    
    [self removeButtons:YES];
    
    if ([self.delegate respondsToSelector:@selector(findTextToolbarDidCancel:)]) {
        [self.delegate findTextToolbarDidCancel:self];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
    
    [self.pdfViewCtrl FindText:self.searchBar.text MatchCase:NO MatchWholeWord:NO SearchUp:NO RegExp:NO];
    [self addPreviousAndNextButtons];
}

-(void)addPreviousAndNextButtons
{
    [self removeButtons:NO];
    
    self.buttonHolder = [[UIView alloc] init];
    self.buttonHolder.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.previousButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UITapGestureRecognizer *previousTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(findTextPrevious)];
    previousTapGestureRecognizer.delegate = self;
    [self.previousButton addGestureRecognizer:previousTapGestureRecognizer];
    
    UIImage *prevImage = [[PTToolsUtil toolImageNamed:@"search_prev_normal.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.previousButton setImage:prevImage forState:UIControlStateNormal];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UITapGestureRecognizer *nextTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(findTextNext)];
    nextTapGestureRecognizer.delegate = self;
    [self.nextButton addGestureRecognizer:nextTapGestureRecognizer];
    
    UIImage* nextImage = [[PTToolsUtil toolImageNamed:@"search_next_normal.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.nextButton setImage:nextImage forState:UIControlStateNormal];
    
    [self.buttonHolder addSubview:self.previousButton];
    [self.buttonHolder addSubview:self.nextButton];
    
    [self.pdfViewCtrl addSubview:self.buttonHolder];
    
    int spacing;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        spacing = 50;
    } else {
        spacing = 100;
    }
    
    // Create and activate constraints between views.
    [NSLayoutConstraint activateConstraints:
     @[
       [self.buttonHolder.centerXAnchor constraintEqualToAnchor:self.buttonHolder.superview.centerXAnchor],
       
       [self.previousButton.leadingAnchor constraintEqualToAnchor:self.previousButton.superview.leadingAnchor],
       [self.previousButton.widthAnchor constraintEqualToConstant:spacing],
       [self.previousButton.topAnchor constraintEqualToAnchor:self.previousButton.superview.topAnchor],
       [self.previousButton.heightAnchor constraintEqualToConstant:spacing],
       [self.previousButton.bottomAnchor constraintEqualToAnchor:self.previousButton.superview.bottomAnchor],
       
       [self.nextButton.leadingAnchor constraintEqualToAnchor:self.previousButton.trailingAnchor constant:(spacing / 2)],
       [self.nextButton.trailingAnchor constraintEqualToAnchor:self.nextButton.superview.trailingAnchor],
       [self.nextButton.widthAnchor constraintEqualToAnchor:self.previousButton.widthAnchor], // Match previous button.
       [self.nextButton.centerYAnchor constraintEqualToAnchor:self.previousButton.centerYAnchor],
       [self.nextButton.heightAnchor constraintEqualToAnchor:self.previousButton.heightAnchor],
       ]];
    
    if (@available(iOS 11, *)) {
        [self.buttonHolder.bottomAnchor constraintEqualToAnchor:self.buttonHolder.superview.safeAreaLayoutGuide.bottomAnchor constant:(-spacing)].active = YES;
    } else {
        [self.buttonHolder.bottomAnchor constraintEqualToAnchor:self.buttonHolder.superview.bottomAnchor constant:(-spacing)].active = YES;
    }
}

-(void)findTextNext
{
    [self.pdfViewCtrl FindText:self.searchBar.text MatchCase:NO MatchWholeWord:NO SearchUp:NO RegExp:NO];
}

-(void)findTextPrevious
{
    [self.pdfViewCtrl FindText:self.searchBar.text MatchCase:NO MatchWholeWord:NO SearchUp:YES RegExp:NO];
}

-(void)removeButtons:(BOOL)animated
{
    [self.pdfViewCtrl hideSelectedTextHighlights];
    
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^(void) {
            self.buttonHolder.alpha = 0;
            self.previousButton.alpha = 0;
            self.nextButton.alpha = 0;
        } completion:^(BOOL finished) {
            [self.buttonHolder removeFromSuperview];
            [self.previousButton removeFromSuperview];
            [self.nextButton removeFromSuperview];
            self.previousButton = nil;
            self.nextButton = nil;
            self.buttonHolder = nil;
        }];
    } else {
        [self.buttonHolder removeFromSuperview];
        [self.previousButton removeFromSuperview];
        [self.nextButton removeFromSuperview];
        self.previousButton = nil;
        self.nextButton = nil;
        self.buttonHolder = nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Previous and next button tap gesture recognizers get priority.
    if ((gestureRecognizer.view == self.previousButton || gestureRecognizer.view == self.nextButton)
        && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]){
        return YES;
    }
    
    return NO;
}

@end
