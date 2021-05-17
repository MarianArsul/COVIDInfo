//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolGroup.h"

#import "PTAutoCoding.h"

@implementation PTToolGroup

- (void)PTToolGroup_commonInit
{
    _editable = YES;
    _favorite = NO;
}

- (instancetype)init
{
    return [self initWithTitle:nil image:nil barButtonItems:@[]];
}

- (instancetype)initWithTitle:(NSString *)title barButtonItems:(NSArray<UIBarButtonItem *> *)barButtonItems
{
    return [self initWithTitle:title image:nil barButtonItems:barButtonItems];
}

- (instancetype)initWithImage:(UIImage *)image barButtonItems:(NSArray<UIBarButtonItem *> *)barButtonItems
{
    return [self initWithTitle:nil image:image barButtonItems:barButtonItems];
}

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image barButtonItems:(NSArray<UIBarButtonItem *> *)barButtonItems
{
    self = [super init];
    if (self) {
        [self PTToolGroup_commonInit];

        _title = [title copy];
        _image = image;
        _barButtonItems = [barButtonItems copy];
    }
    return self;
}

+ (instancetype)groupWithTitle:(NSString *)title image:(UIImage *)image barButtonItems:(NSArray<UIBarButtonItem *> *)barButtonItems
{
    return [[self alloc] initWithTitle:title
                                 image:image
                        barButtonItems:barButtonItems];
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        [self PTToolGroup_commonInit];
        
        [PTAutoCoding autoUnarchiveObject:self
                                  ofClass:[PTToolGroup class]
                                withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [PTAutoCoding autoArchiveObject:self
                            ofClass:[PTToolGroup class]
                            forKeys:nil
                          withCoder:coder];
}

@end
