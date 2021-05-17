//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTThumbnailSliderViewItem.h"

@implementation PTThumbnailSliderViewItem

- (instancetype)initWithPageNumber:(int)pageNumber size:(CGSize)size
{
    self = [super init];
    if (self) {
        _pageNumber = pageNumber;
        _size = size;
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    if (image) {
        self.size = image.size;
    }
}

@end
