//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTSavedSignaturesViewController.h"
#import "PTToolsUtil.h"

@interface PTSavedSignaturesViewController () <UITableViewDelegate, UITableViewDataSource>


@property (nonatomic, strong) UITableView* savedSignatureTableView;
@property (nonatomic, readonly) CGFloat cellHeight;
@property (nonatomic) BOOL newSignatureRequested;

@end

@implementation PTSavedSignaturesViewController

-(instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

        [self PTSavedSignaturesViewController_commonInit:[[PTSignaturesManager allocOverridden] init]];
    }
    return self;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self PTSavedSignaturesViewController_commonInit:[[PTSignaturesManager allocOverridden] init]];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTSavedSignaturesViewController_commonInit:[[PTSignaturesManager allocOverridden] init]];
    }
    return self;
}

- (instancetype)initWithSignaturesManager:(PTSignaturesManager*)signaturesManager
{
    self = [super initWithNibName:Nil bundle:Nil];
    if (self) {

        [self PTSavedSignaturesViewController_commonInit:signaturesManager];
    }
    return self;
}

-(instancetype)init{
    self = [super initWithNibName:Nil bundle:Nil];
    if (self) {
        [self PTSavedSignaturesViewController_commonInit:[[PTSignaturesManager allocOverridden] init]];
    }
    return self;
}

-(void)PTSavedSignaturesViewController_commonInit:(PTSignaturesManager*)signaturesManager
{
    _signaturesManager = signaturesManager;
    _cellHeight = 88;
    _newSignatureRequested = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if( self.newSignatureRequested == NO && [self.delegate conformsToProtocol:@protocol(PTSavedSignaturesViewControllerDelegate) ] && [self.delegate respondsToSelector:@selector(savedSignaturesControllerWasDismissed:)] )
    {
        [self.delegate savedSignaturesControllerWasDismissed:self];
    }
}

-(void)doneButtonTapped:(UIBarButtonItem*)item
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:Nil];
}


-(void)newSignature:(UIButton* )button
{
    if( [self.delegate respondsToSelector:@selector(savedSignaturesControllerNewSignature:)] )
    {
        self.newSignatureRequested = YES;
        [self.delegate savedSignaturesControllerNewSignature:self];
    }
}

-(void)tempSignature:(UIButton* )button
{
    if( [self.delegate respondsToSelector:@selector(savedSignaturesControllerOneTimeSignature:)] )
    {
        self.newSignatureRequested = YES;
        [self.delegate savedSignaturesControllerOneTimeSignature:self];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.signaturesManager numberOfSavedSignatures];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 66.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 66)];

    headerView.backgroundColor = self.tableView.backgroundColor;

    
    UIButton* newSignature = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [newSignature setTitle:PTLocalizedString(@"New Signature", @"Create a new signature that will be saved for resue.") forState:UIControlStateNormal];
    
    if (@available(iOS 13.0, *)) {
        newSignature.backgroundColor = UIColor.tertiarySystemFillColor;
    } else {
        // Fallback on earlier versions
        newSignature.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.10];
    }
    
    newSignature.layer.cornerRadius = 12.0;
    
    [newSignature addTarget:self action:@selector(newSignature:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton* tempSignature = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [tempSignature setTitle:PTLocalizedString(@"One Time Signature", @"Create a new signature that won't be saved for reuse.") forState:UIControlStateNormal];
    
    if (@available(iOS 13.0, *)) {
        tempSignature.backgroundColor = UIColor.tertiarySystemFillColor;
    } else {
        // Fallback on earlier versions
        tempSignature.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.10];
    }
    
    tempSignature.layer.cornerRadius = 12.0;
    
    [tempSignature addTarget:self action:@selector(tempSignature:) forControlEvents:UIControlEventTouchUpInside];
    
    UIStackView* stackView = [[UIStackView alloc] initWithArrangedSubviews:@[newSignature, tempSignature]];
    
    stackView.axis = UILayoutConstraintAxisHorizontal;

    stackView.frame = headerView.bounds;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.layoutMarginsRelativeArrangement = YES;
    stackView.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    stackView.spacing = 10;
    stackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [headerView addSubview:stackView];
    
    return headerView;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage* image = [self.signaturesManager imageOfSavedSignatureAtIndex:indexPath.row dpi:72];
       
        dispatch_async( dispatch_get_main_queue(), ^{
           
            NSIndexPath* cellIndexPath = [tableView indexPathForCell:cell];
            if( cellIndexPath.row == indexPath.row )
            {
                UIImageView* signatureImageView = [[UIImageView alloc] initWithImage:image];

                if( image.size.height > self.cellHeight )
                {
                    float height = self.cellHeight;
                    float width = height/image.size.height*image.size.width;
                    signatureImageView.frame = CGRectMake(0, 0, width, height);
                }
                signatureImageView.center = cell.contentView.center;
                [cell.contentView addSubview:signatureImageView];
                
            }
            
        });
        
    });
    
    return cell;
    
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return self.cellHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.newSignatureRequested = YES;
    [self.delegate savedSignaturesController:self addSignature:[self.signaturesManager savedSignatureAtIndex:indexPath.row]];
}

-(void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BOOL success = [self.signaturesManager deleteSignatureAtIndex:indexPath.row];
        
        if( success )
        {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    [self.signaturesManager moveSignatureAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.navigationItem.leftBarButtonItem.enabled = !editing;
}

@end
