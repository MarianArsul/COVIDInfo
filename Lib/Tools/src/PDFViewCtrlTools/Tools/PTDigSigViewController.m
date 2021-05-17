//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDigSigViewController.h"

#import "PTDigSigView.h"
#import "PTToolsUtil.h"

@interface PTDigSigViewController ()

@property (nonatomic, strong) PTDigSigView *digSigView;

@property (nonatomic, strong) UIImage *image;

@end

@implementation PTDigSigViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _strokeThickness = 2;
        _strokeColor = UIColor.blackColor;
        _allowDigitalSigning = YES;
        _allowPhotoPicker = YES;
    }
    return self;
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:saveAppearance style:UIBarButtonItemStylePlain target:self action:@selector(saveAppearanceOnly)];
    
	
	// add button for digitally signing
    if( self.allowDigitalSigning )
    {
        NSString* digitallySign = PTLocalizedString(@"Digitally Sign", @"");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:digitallySign style:UIBarButtonItemStylePlain target:self action:@selector(digitallySign)];
        
    }
	
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSignatureDialog)];
    
    
    NSString* pickAPhoto = PTLocalizedString(@"Pick a Photo", @"For digital signatures.");
    
    UISwitch* saveSwitch = [[UISwitch alloc] init];
    [saveSwitch.widthAnchor constraintEqualToConstant:60.0].active = YES;
    [saveSwitch addTarget:self action:@selector(saveSignatureSwitchAction:) forControlEvents:UIControlEventValueChanged];
    
    UILabel* saveSwitchLabel = [[UILabel alloc] init];
    saveSwitchLabel.text = PTLocalizedString(@"Store Signature", @"Store the signature for later use.");
    saveSwitchLabel.font = [saveSwitchLabel.font fontWithSize:14];
    saveSwitchLabel.adjustsFontSizeToFitWidth = YES;

    
    //UIBarButtonItem* saveSwitchItem = [[UIBarButtonItem alloc] initWithCustomView:saveSwitch];
    //UIBarButtonItem* saveSwitchLabelItem = [[UIBarButtonItem alloc] initWithCustomView:saveSwitchLabel];
    
    NSMutableArray<UIBarButtonItem*>* barItems = [[NSMutableArray alloc] init];
    
    [barItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    if( self.allowPhotoPicker )
    {
        [barItems addObject:[[UIBarButtonItem alloc] initWithTitle:pickAPhoto style:UIBarButtonItemStylePlain target:self action:@selector(showPhotoPicker)]];
    }

    self.toolbarItems = [barItems copy];
    
}

-(void)saveSignatureSwitchAction:(UISwitch*)saveSwitch
{
    // not yet supported
}

-(void)closeSignatureDialog
{
    [self.delegate digSigViewControllerCloseSignatureDialog:self];
}

-(void)resetDigSigView
{
	// clears paths
	[self.digSigView.points removeAllObjects];
	
	// clears image
    for(UIView* subView in self.digSigView.subviews)
        if( [subView isMemberOfClass:[UIImageView class]])
        {
            [subView removeFromSuperview];
            break;
        }

	self.image = nil;
	
	[self.digSigView setNeedsDisplay];
	
	self.digSigView.userInteractionEnabled = YES;
}

-(UIImage*)correctForRotation:(UIImage*)src
{
    UIGraphicsBeginImageContext(src.size);
	
    [src drawAtPoint:CGPointMake(0, 0)];
	
    UIImage* img =  UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return img;
}



-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self resetDigSigView];
	
	self.image = [self correctForRotation:info[UIImagePickerControllerOriginalImage]];
	
	UIImageView* imageView = [[UIImageView alloc] initWithImage:self.image];
	imageView.frame = CGRectMake(0, 0, self.digSigView.frame.size.width, self.digSigView.frame.size.height);
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	
	self.digSigView.userInteractionEnabled = NO;
	[self.digSigView addSubview:imageView];
	

	[self dismissViewControllerAnimated:YES completion:nil];
	
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showPhotoPicker
{
	
	UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
	imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePickerController.delegate = self;
	imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
	
	[self presentViewController:imagePickerController animated:YES completion:nil];
	
	UIPopoverPresentationController *popController = imagePickerController.popoverPresentationController;
	
	popController.sourceRect = CGRectInset(self.digSigView.frame,self.digSigView.frame.size.width/2-1, self.digSigView.frame.size.height/2-1);
	popController.sourceView = self.view;
}

-(void)digitallySign
{
	[self saveAppearanceOnly];
	[self.delegate digSigViewControllerSignAndSave:self];
}

-(void)saveAppearanceOnly
{
    self.strokeColor = self.digSigView.strokeColor;
	@try
	{
		if( self.image )
			[self.delegate digSigViewController:self saveAppearanceWithUIImage:self.image];
		else
			[self.delegate digSigViewController:self saveAppearanceWithPath:self.digSigView.points fromCanvasSize:CGSizeMake(self.digSigView.frame.size.width, self.digSigView.frame.size.height)];
		
	}
	@catch (NSException *exception)
	{
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
