//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFloatingSigViewController.h"

#import "PTDigSigView.h"
#import "PTToolsUtil.h"

@interface PTFloatingSigViewController ()

@property (nonatomic, strong) UILabel *defaultLabel;

@property (nonatomic, strong) UISwitch *defaultSwitch;

@end

@implementation PTFloatingSigViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _strokeThickness = 2;
        _strokeColor = UIColor.blackColor;
        _showDefaultSignature = YES;
    }
    return self;
}

- (PTDigSigView *)digSigView
{
    [self loadViewIfNeeded];
    
    return _digSigView;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if( self.navigationController.viewControllers.firstObject == self )
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSignatureDialog)];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIColor *bgColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    if (@available(iOS 11.0, *)) {
        bgColor = [UIColor colorNamed:@"UIBGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
    }
    self.view.backgroundColor = bgColor;

    CGRect frame = self.view.frame;
    frame.size.width += 100;
    self.view.frame = frame;
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:container];
    
    if (@available(iOS 11, *)) {
        // iPhone X - respect safe area.
        UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:
         @[
           [container.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
           [container.widthAnchor constraintEqualToAnchor:safeArea.widthAnchor],
           [container.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
           [container.heightAnchor constraintEqualToAnchor:safeArea.heightAnchor],
           ]];
    } else {
        [NSLayoutConstraint activateConstraints:
         @[
           [container.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
           [container.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
           [container.topAnchor constraintEqualToAnchor:self.view.topAnchor],
           [container.heightAnchor constraintEqualToAnchor:self.view.heightAnchor],
           ]];
    }
    
    self.digSigView = [[PTDigSigView alloc] initWithFrame:CGRectZero withColour:_strokeColor withStrokeThickness:_strokeThickness];
    
    [container addSubview:self.digSigView];
    
    self.digSigView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [container addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-10-[_digSigView]-10-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(_digSigView)]];
    
    [container addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-10-[_digSigView]-10-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(_digSigView)]];
    
    NSString* saveAppearance = PTLocalizedString(@"Sign", @"Save signature appearance.");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:saveAppearance style:UIBarButtonItemStylePlain target:self action:@selector(saveAppearance)];

    
    
    self.defaultSwitch = [[UISwitch alloc] init];
    [self.defaultSwitch.widthAnchor constraintEqualToConstant:60.0].active = YES;
    [self.defaultSwitch addTarget:self action:@selector(defaultSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.defaultLabel = [[UILabel alloc] init];
    self.defaultLabel.text = PTLocalizedString(@"Store Signature", @"Store the signature for later use.");
    self.defaultLabel.font = [self.defaultLabel.font fontWithSize:14];
    self.defaultLabel.adjustsFontSizeToFitWidth = YES;
    
    
    UIBarButtonItem* saveSwitchItem = [[UIBarButtonItem alloc] initWithCustomView:self.defaultSwitch];
    UIBarButtonItem* saveSwitchLabelItem = [[UIBarButtonItem alloc] initWithCustomView:self.defaultLabel];
    
    
    self.toolbarItems = @[
                           saveSwitchItem,
                           saveSwitchLabelItem,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
}



- (void)setShowDefaultSignature:(BOOL)showDefaultSignature
{
    if (_showDefaultSignature == showDefaultSignature) {
        return;
    }
    
    _showDefaultSignature = showDefaultSignature;
    
    [self loadViewIfNeeded];
    
    // Update label and switch visibility.
    self.defaultLabel.hidden = !showDefaultSignature;
    self.defaultSwitch.hidden = !showDefaultSignature;
}

-(void)closeSignatureDialog
{
    [self.delegate floatingSigViewControllerCloseSignatureDialog:self];
}

-(void)defaultSwitchChanged:(UISwitch*)mySwitch
{
	self.saveSignatureForReuse = mySwitch.on;
}

-(void)saveAppearance
{
	@try
	{
        self.strokeColor = self.digSigView.strokeColor;
		// no m_moving_annotation, delegate method needs to be changed
		[self.delegate floatingSigViewController:self saveAppearanceWithPath:self.digSigView.points withBoundingRect:self.digSigView.boundingRect asDefault:self.saveSignatureForReuse];
	}
	@catch (NSException *exception)
	{
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
}

-(void)setDelegate:(id<PTFloatingSigViewControllerDelegate>)delegate
{
    _delegate = delegate;
}

-(void)resetDigSigView
{
	// clears paths
	[self.digSigView.points removeAllObjects];
	
	[self.digSigView setNeedsDisplay];
	
	self.digSigView.userInteractionEnabled = YES;
}

@end
