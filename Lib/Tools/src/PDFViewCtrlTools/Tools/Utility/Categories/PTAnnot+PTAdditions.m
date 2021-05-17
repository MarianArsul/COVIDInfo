//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnot+PTAdditions.h"
#import "PTColorDefaults.h"
#import "PTToolsUtil.h"

@implementation PTAnnot (PTAdditions)

#pragma mark - Annot properties

- (NSString *)IRTAsNSString
{
    PTObj *annotSDFObj = [self GetSDFObj];
    if ([annotSDFObj IsValid]) {
        PTObj *irt = [annotSDFObj FindObj:@"IRT"];
        if ([irt IsValid]) {
            if ([irt IsString]) {
                return [irt GetAsPDFText];
            }
            if ([irt IsDict]) {
                PTObj *nm = [irt FindObj:@"NM"];
                if ([nm IsValid] && [nm IsString]) {
                    return [nm GetAsPDFText];
                }
            }
        }
    }
    return nil;
}

- (BOOL)hasReplyTypeGroup
{
    PTObj *annotSDFObj = [self GetSDFObj];
    if ([annotSDFObj IsValid]) {
        PTObj *irt = [annotSDFObj FindObj:@"IRT"];
        PTObj *rt = [annotSDFObj FindObj:@"RT"];
        if ([irt IsValid] && [rt IsValid] && [rt IsName]) {
            NSString *rtVal = [rt GetName];
            return [rtVal isEqualToString:@"Group"];
        }
    }
    return NO;
}

- (BOOL)isInGroup
{
    return self.annotationsInGroup.count > 1;
}

- (UIColor *)colorPrimary
{
    if( [self extendedAnnotType] == PTExtendedAnnotTypePencilDrawing )
    {
        UIColor *pencilDrawingIconColor = [UIColor blackColor];
        if (@available(iOS 13.0, *)) {
            pencilDrawingIconColor = [UIColor colorNamed:@"UIFGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:nil];
        }
        return pencilDrawingIconColor;
    }
    UIColor *color = [PTColorDefaults uiColorFromColorPt:[self GetColorAsRGB] compNum:3];
    
    PTAnnotType annotType = [self GetType];
    if (annotType == e_ptFreeText) {
        PTFreeText *freeText = [[PTFreeText alloc] initWithAnn:self];
        color =  [PTColorDefaults uiColorFromColorPt:[freeText GetTextColor] compNum:[freeText GetTextColorCompNum]];
    }
    else if ([self IsMarkup]) {
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self];
        if ([markup GetInteriorColorCompNum] == 3) {
            UIColor *fillColor = [PTColorDefaults uiColorFromColorPt:[markup GetInteriorColor] compNum:3];
            if (CGColorGetAlpha(fillColor.CGColor) != 0.0) {
                color = fillColor;
            }
        }
    }
    
    return color;
}

#pragma mark - Group

- (NSArray<PTAnnot *> *)annotationsInGroup
{
    if (![self IsValid]) {
        return nil;
    }
    PTPage *page = [self GetPage];
    if (![page IsValid]) {
        // Page entry is not always valid
        return @[self];
    }

    PTAnnot *mainAnnot = nil;
    NSString *mainAnnotID = nil;
    if ([self hasReplyTypeGroup]) {
        mainAnnotID = [self IRTAsNSString];
    } else if (self.uniqueID != nil) {
        mainAnnot = self;
        mainAnnotID = self.uniqueID;
    }
    
    if (!mainAnnotID) {
        return @[self];
    }
    
    NSMutableArray *annotations = [NSMutableArray array];
    
    const unsigned int annotationCount = [page GetNumAnnots];
    for (unsigned int a = 0; a < annotationCount; a++) {
        PTAnnot *annot = [page GetAnnot:a];
        if (![annot IsValid]) {
            continue;
        }
        NSString *annotID = annot.uniqueID;
        NSString *irt = annot.IRTAsNSString;
        if (!mainAnnot &&
            [annotID isEqualToString:mainAnnotID]) {
            mainAnnot = annot;
        } else if (annot.hasReplyTypeGroup && irt != nil && [irt isEqualToString:mainAnnotID]){
            [annotations addObject:annot];
        }
    }
    if ([mainAnnot IsValid]) {
        [annotations insertObject:mainAnnot atIndex:0];
    }
    if (annotations.count == 0) {
        [annotations addObject:self];
    }
    return [annotations copy];
}

#pragma mark - uniqueID

- (NSString *)uniqueID
{
    PTObj *obj = [self GetUniqueID];
    if ([obj IsValid] && [obj IsString]) {
        return [obj GetAsPDFText];
    }
    return nil;
}

- (void)setUniqueID:(NSString *)uniqueID
{
    [self SetUniqueID:uniqueID id_buf_sz:0];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTAnnot, PTAdditions)
