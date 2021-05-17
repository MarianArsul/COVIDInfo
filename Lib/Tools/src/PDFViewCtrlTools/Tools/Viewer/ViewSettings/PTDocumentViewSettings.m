//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentViewSettings.h"

#import "PTAutoCoding.h"

@implementation PTDocumentViewSettings

- (void)PTDocumentViewSettings_commonInit
{
    _pagePresentationMode = e_trn_single_continuous;
    _reflowEnabled = NO;
    
    _colorPostProcessMode = e_ptpostprocess_none;
    _colorPostProcessWhiteColor = nil;
    _colorPostProcessBlackColor = nil;
    
    _pageRotation = e_pt0;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self PTDocumentViewSettings_commonInit];
    }
    return self;
}

#pragma mark - Night mode

- (BOOL)isNightModeEnabled
{
    return (self.colorPostProcessMode == e_ptpostprocess_night_mode);
}

- (void)setNightModeEnabled:(BOOL)enabled
{
    if (enabled) {
        self.colorPostProcessMode = e_ptpostprocess_night_mode;
    } else {
        self.colorPostProcessMode = e_ptpostprocess_none;
    }
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        [self PTDocumentViewSettings_commonInit];
        
        [PTAutoCoding autoUnarchiveObject:self withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [PTAutoCoding autoArchiveObject:self withCoder:coder];
}

#pragma mark - <NSCopying>

- (instancetype)copyWithZone:(NSZone *)zone
{
    PTDocumentViewSettings *other = [[PTDocumentViewSettings alloc] init];
    
    other->_pagePresentationMode = self->_pagePresentationMode;
    other->_reflowEnabled = self->_reflowEnabled;
    other->_colorPostProcessMode = self->_colorPostProcessMode;
    other->_colorPostProcessWhiteColor = [self->_colorPostProcessWhiteColor copy];
    other->_colorPostProcessBlackColor = [self->_colorPostProcessBlackColor copy];
    other->_pageRotation = self->_pageRotation;

    return other;
}

@end
