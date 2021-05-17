//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTDocumentViewSettings.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentViewSettingsManager : NSObject

@property (nonatomic, class, readonly, strong) PTDocumentViewSettingsManager *sharedManager;

- (int)lastReadPageNumberForDocumentAtURL:(NSURL *)url;
- (void)setLastReadPageNumber:(int)lastReadPageNumber forDocumentAtURL:(NSURL *)url;

- (nullable PTDocumentViewSettings *)viewSettingsForDocumentAtURL:(NSURL *)url;
- (void)setViewSettings:(PTDocumentViewSettings *)settings forDocumentAtURL:(NSURL *)url;

@property (nonatomic, strong) PTDocumentViewSettings *defaultViewSettings;

@end

NS_ASSUME_NONNULL_END
