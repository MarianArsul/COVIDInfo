//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPDFViewCtrlViewController.h"

#import "CGGeometry+PTAdditions.h"

@interface PTPDFViewCtrlViewController ()

@property (nonatomic, assign, getter=isPanelTransitioning) BOOL panelTransitioning;

@end

@implementation PTPDFViewCtrlViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
    }
    return self;
}

- (PTPDFViewCtrl *)pdfViewCtrl
{
    if (!_pdfViewCtrl) {
        _pdfViewCtrl = [[PTPDFViewCtrl alloc] init];
    }
    return _pdfViewCtrl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pdfViewCtrl.frame = self.view.bounds;
    // Disable autoresizing - the PDFViewCtrl's frame is updated manually.
    self.pdfViewCtrl.autoresizingMask = UIViewAutoresizingNone;
    
    [self.view addSubview:self.pdfViewCtrl];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if ([self isPanelTransitioning]) {
        // Shift PDFViewCtrl center over to where it *should* be, the center of the target frame.
        self.pdfViewCtrl.center = PTCGRectGetCenter(self.view.bounds);
    } else {
        // PDFViewCtrl frame matches the view controller view's.
        self.pdfViewCtrl.frame = self.view.bounds;
    }
}

- (void)setPanelTransitioning:(BOOL)panelTransitioning
{
    _panelTransitioning = panelTransitioning;
    
    [self.view setNeedsLayout];
}

#pragma mark - <PTPanelContentContainer>

- (void)panelWillTransition
{
    self.panelTransitioning = YES;
    
    // Synchronize the view's background with the PDFViewCtrl's.
    // While transitioning to a close-panel configuration, the PDFViewCtrl's width will be smaller
    // than the view's. To avoid breaking the illusion, we need to match the background colors so it
    // looks like the PDFViewCtrl is actually animating the width change.
    self.view.backgroundColor = self.pdfViewCtrl.backgroundColor;
}

- (void)panelDidTransition
{
    self.panelTransitioning = NO;
}

@end
