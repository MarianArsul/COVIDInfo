//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotStyle.h"

#import <UIKit/UIKit.h>
#import "PTMeasurementScale.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PTAnnotStyleTableViewItemType) {
    PTAnnotStyleTableViewItemTypeColor,
    PTAnnotStyleTableViewItemTypeSlider,
    PTAnnotStyleTableViewItemTypeTextField,
    PTAnnotStyleTableViewItemTypeScale,
    PTAnnotStyleTableViewItemTypePrecision,
    PTAnnotStyleTableViewItemTypeSwitch,
    PTAnnotStyleTableViewItemTypeFont
};

@interface PTAnnotStyleTableViewItem : NSObject

@property (nonatomic, readonly) PTAnnotStyleTableViewItemType type;
@property (nonatomic, copy) NSString *title;

@property (nonatomic, readonly, copy) PTAnnotStyleKey annotStyleKey;

@end

@interface PTAnnotStyleFontTableViewItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title fontDescriptor:(UIFontDescriptor *)fontDescriptor annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic, strong) UIFontDescriptor *fontDescriptor;

@end

@interface PTAnnotStyleColorTableViewItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title color:(UIColor *)color annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic, strong) UIColor *color;

@end

@interface PTAnnotStyleScaleTableViewItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title measurementScale:(PTMeasurementScale *)measurementScale annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic, strong) PTMeasurementScale *measurementScale;

@end

@interface PTAnnotStylePrecisionTableViewItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title measurementScale:(PTMeasurementScale *)measurementScale annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic, strong) PTMeasurementScale *measurementScale;

@end

@interface PTAnnotStyleSliderTableViewItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title minimumValue:(float)minimumValue maximumValue:(float)maximumValue value:(float)value indicatorText:(NSString *)indicatorText annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic) float minimumValue;
@property (nonatomic) float maximumValue;
@property (nonatomic) float value;

@property (nonatomic, copy) NSString *indicatorText;

@end

@interface PTAnnotStyleTextFieldTableViewItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title text:(nullable NSString *)text annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic, copy, nullable) NSString *text;

@end

@interface PTAnnotStyleSwitchTableViewItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title snappingEnabled:(BOOL)snappingEnabled annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic) BOOL snappingEnabled;

@end

@interface AnnotStyleTableViewFontItem : PTAnnotStyleTableViewItem

- (instancetype)initWithTitle:(NSString *)title fontDescriptor:(UIFontDescriptor*)fontDescriptor annotStyleKey:(PTAnnotStyleKey)annotStyleKey;

@property (nonatomic, strong) UIFontDescriptor* fontDescriptor;

@end

NS_ASSUME_NONNULL_END
