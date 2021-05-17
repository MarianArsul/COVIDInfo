//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTUserBookmark.h"

@implementation PTUserBookmark

- (instancetype)initWithPDFBookmark:(PTBookmark *)bookmark
{
    self = [super init];
    if (self) {
        _bookmark = bookmark;
        
        @try {
            _title = [bookmark GetTitle];
            
            PTAction *action = [bookmark GetAction];
            PTDestination *dest = [action GetDest];
            PTPage *page = [dest GetPage];
            
            _pageNumber = [page GetIndex];
            _pageObjNum = [[page GetSDFObj] GetObjNum];
        } @catch (NSException *exception) {
            // Ignored.
        }
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title pageNumber:(int)pageNumber
{
    return [self initWithTitle:title pageNumber:pageNumber pageObjNum:0];
}

- (instancetype)initWithTitle:(NSString *)title pageNumber:(int)pageNumber pageObjNum:(unsigned int)pageObjNum
{
    self = [super init];
    if (self) {
        _title = title;
        _pageNumber = pageNumber;
        _pageObjNum = pageObjNum;
        
        _edited = YES;
    }
    return self;
}

#pragma mark - Property setters

- (void)setTitle:(NSString *)title
{
    if ([_title isEqualToString:title]) {
        // No change.
        return;
    }
    
    _title = title;
    
    self.edited = YES;
}

- (void)setPageNumber:(int)pageNumber
{
    if (_pageNumber == pageNumber) {
        // No change.
        return;
    }
    
    _pageNumber = pageNumber;
    
    self.edited = YES;
}

- (void)setPageObjNum:(unsigned int)pageObjNum
{
    if (_pageObjNum == pageObjNum) {
        // No change.
        return;
    }
    
    _pageObjNum = pageObjNum;
    
    self.edited = YES;
}

@end
