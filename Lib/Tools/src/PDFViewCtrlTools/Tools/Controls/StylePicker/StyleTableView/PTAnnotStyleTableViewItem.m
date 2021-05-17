//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleTableViewItem.h"

#pragma mark - AnnotStyleTableViewItem

@interface PTAnnotStyleTableViewItem ()

- (instancetype)initWithType:(PTAnnotStyleTableViewItemType)type title:(nonnull NSString *)title annotStyleKey:(nonnull PTAnnotStyleKey)annotStyleKey;

@end

@implementation PTAnnotStyleTableViewItem

- (instancetype)initWithType:(PTAnnotStyleTableViewItemType)type title:(NSString *)title annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [super init];
    if (self) {
        _type = type;
        _title = title;
        _annotStyleKey = annotStyleKey;
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewFontItem

@implementation PTAnnotStyleFontTableViewItem

- (instancetype)initWithTitle:(NSString *)title fontDescriptor:(UIFontDescriptor *)fontDescriptor annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [super initWithType:PTAnnotStyleTableViewItemTypeFont title:title annotStyleKey:annotStyleKey];
    if (self) {
        _fontDescriptor = fontDescriptor;
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewColorItem

@implementation PTAnnotStyleColorTableViewItem

- (instancetype)initWithTitle:(NSString *)title color:(UIColor *)color annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [super initWithType:PTAnnotStyleTableViewItemTypeColor title:title annotStyleKey:annotStyleKey];
    if (self) {
        _color = color;
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewScaleItem

@implementation PTAnnotStyleScaleTableViewItem

- (instancetype)initWithTitle:(NSString *)title measurementScale:(PTMeasurementScale *)measurementScale annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [super initWithType:PTAnnotStyleTableViewItemTypeScale title:title annotStyleKey:annotStyleKey];
    if (self) {
        _measurementScale = measurementScale;
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewPrecisionItem

@implementation PTAnnotStylePrecisionTableViewItem

- (instancetype)initWithTitle:(NSString *)title measurementScale:(PTMeasurementScale *)measurementScale annotStyleKey:(nonnull PTAnnotStyleKey)annotStyleKey
{
    self = [super initWithType:PTAnnotStyleTableViewItemTypePrecision title:title annotStyleKey:annotStyleKey];
    if (self) {
        _measurementScale = measurementScale;
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewSliderItem

@implementation PTAnnotStyleSliderTableViewItem

- (instancetype)initWithTitle:(NSString *)title minimumValue:(float)minimumValue maximumValue:(float)maximumValue value:(float)value indicatorText:(NSString *)indicatorText annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [self initWithType:PTAnnotStyleTableViewItemTypeSlider title:title annotStyleKey:annotStyleKey];
    if (self) {
        _minimumValue = minimumValue;
        _maximumValue = maximumValue;
        _value = value;
        _indicatorText = indicatorText;
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewTextFieldItem

@implementation PTAnnotStyleTextFieldTableViewItem

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [super initWithType:PTAnnotStyleTableViewItemTypeTextField title:title annotStyleKey:annotStyleKey];
    if (self) {
        _text = [text copy];
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewSwitchItem

@implementation PTAnnotStyleSwitchTableViewItem

- (instancetype)initWithTitle:(NSString *)title snappingEnabled:(BOOL)snappingEnabled annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [super initWithType:PTAnnotStyleTableViewItemTypeSwitch title:title annotStyleKey:annotStyleKey];
    if (self) {
        _snappingEnabled = snappingEnabled;
    }
    return self;
}

@end

#pragma mark - AnnotStyleTableViewFontItem

@implementation AnnotStyleTableViewFontItem

- (instancetype)initWithTitle:(NSString *)title fontDescriptor:(UIFontDescriptor*)fontDescriptor annotStyleKey:(PTAnnotStyleKey)annotStyleKey
{
    self = [super initWithType:PTAnnotStyleTableViewItemTypeFont title:title annotStyleKey:annotStyleKey];
    if (self) {
        _fontDescriptor = fontDescriptor;
    }
    return self;
}

@end
