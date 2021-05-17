//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCustomStampOption.h"
#import "PTRubberStampManager.h"
#import "PTToolsUtil.h"
#import "UIColor+PTHexString.h"

@implementation PTCustomStampOption

- (instancetype)initWithText:(NSString *)text secondText:(NSString *)secondText bgColorStart:(UIColor *)bgColorStart bgColorEnd:(UIColor *)bgColorEnd textColor:(UIColor *)textColor borderColor:(UIColor *)borderColor fillOpacity:(CGFloat)fillOpacity pointingLeft:(BOOL)pointingLeft pointingRight:(BOOL)pointingRight{
    self = [super init];
    if (self) {
        _text = text;
        _secondText = secondText;
        _bgColorStart = bgColorStart;
        _bgColorEnd = bgColorEnd;
        _textColor = textColor;
        _borderColor = borderColor;
        _fillOpacity = fillOpacity;
        _pointingLeft = pointingLeft;
        _pointingRight = pointingRight;
    }
    return self;
}

-(instancetype)initWithFormXObject:(PTObj*)stampObj{
    self = [super init];
    if (self) {
        PTObj *found = [stampObj FindObj:PTRubberStampKeyText];
        if (found == nil || !found.IsString) {
            NSString *reason = [NSString stringWithFormat:@"%@ is mandatory in a custom rubber stamp's SDF Obj", PTRubberStampKeyText];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:reason
                                         userInfo:nil];
        }
        self.text = found.GetAsPDFText;
        found = [stampObj FindObj:PTRubberStampKeyTextBelow];
        if (found != nil && found.IsString) {
            self.secondText = found.GetAsPDFText;
        }
        found = [stampObj FindObj:PTRubberStampKeyFillColorStart];
        if (found != nil && found.IsArray && (found.Size == 3 || found.Size == 4)) {
            self.bgColorStart = [self getColorFromObject:found];
        }
        found = [stampObj FindObj:PTRubberStampKeyFillColorEnd];
        if (found != nil && found.IsArray && (found.Size == 3 || found.Size == 4)) {
            self.bgColorEnd = [self getColorFromObject:found];
        }
        found = [stampObj FindObj:PTRubberStampKeyTextColor];
        if (found != nil && found.IsArray && (found.Size == 3 || found.Size == 4)) {
            self.textColor = [self getColorFromObject:found];
        }
        found = [stampObj FindObj:PTRubberStampKeyBorderColor];
        if (found != nil && found.IsArray && (found.Size == 3 || found.Size == 4)) {
            self.borderColor = [self getColorFromObject:found];
        }
        found = [stampObj FindObj:PTRubberStampKeyFillOpacity];
        if (found != nil && found.IsNumber)  {
            self.fillOpacity = found.GetNumber;
        }
        found = [stampObj FindObj:PTRubberStampKeyPointingLeft];
        if (found != nil && found.IsBool)  {
            self.pointingLeft = found.GetBool;
        }
        found = [stampObj FindObj:PTRubberStampKeyPointingRight];
        if (found != nil && found.IsBool)  {
            self.pointingLeft = found.GetBool;
        }
    }
    return self;
}

- (void)configureStampObject:(PTObj *)stampObj{
    [stampObj PutText:PTRubberStampKeyText value:self.text];
    [self addColorToOption:stampObj arrayName:PTRubberStampKeyFillColorStart color:self.bgColorStart];
    [self addColorToOption:stampObj arrayName:PTRubberStampKeyFillColorEnd color:self.bgColorEnd];
    [self addColorToOption:stampObj arrayName:PTRubberStampKeyTextColor color:self.textColor];
    [self addColorToOption:stampObj arrayName:PTRubberStampKeyBorderColor color:self.borderColor];
    [stampObj PutNumber:PTRubberStampKeyFillOpacity value:self.fillOpacity];
    [stampObj PutBool:PTRubberStampKeyPointingLeft value:self.pointingLeft];
    [stampObj PutBool:PTRubberStampKeyPointingRight value:self.pointingRight];
}

-(void)addColorToOption:(PTObj*)stampObj arrayName:(NSString*)arrayName color:(UIColor*)color{
    PTObj *objColor = [stampObj PutArray:arrayName];
    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:nil];

    [objColor PushBackNumber:red];
    [objColor PushBackNumber:green];
    [objColor PushBackNumber:blue];
}

-(UIColor*)getColorFromObject:(PTObj*)object{
    double red = [[object GetAt:0] GetNumber];
    double green = [[object GetAt:0] GetNumber];
    double blue = [[object GetAt:0] GetNumber];
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end
