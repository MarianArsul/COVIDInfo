//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPanelViewController.h"

#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTPDFViewCtrlViewController : UIViewController <PTPanelContentContainer>

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl;

@property (nonatomic, strong) PTPDFViewCtrl *pdfViewCtrl;

@end

NS_ASSUME_NONNULL_END
