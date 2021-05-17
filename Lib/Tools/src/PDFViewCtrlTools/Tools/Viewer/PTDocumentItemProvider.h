//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <PDFNet/PDFNet.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentItemProvider : UIActivityItemProvider

- (instancetype)initWithPDFDoc:(PTPDFDoc *)pdfDoc NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithDocumentURL:(NSURL *)documentURL;
- (instancetype)initWithDocumentURL:(NSURL *)documentURL password:(nullable NSString *)password NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPlaceholderItem:(id)placeholderItem NS_UNAVAILABLE;

@property (nonatomic, strong, nullable) PTPDFDoc *pdfDoc;
@property (nonatomic, strong, nullable) NSURL *documentURL;
@property (nonatomic, copy, nullable) NSString *password;

@end

NS_ASSUME_NONNULL_END
