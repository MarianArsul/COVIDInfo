//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFDFDoc+PTAdditions.h"

static NSString * const PT_FDFDocEmptyXFDF = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?><xfdf xmlns=\"http://ns.adobe.com/xfdf/\" xml:space=\"preserve\"><fields/><annots/></xfdf>";

@implementation PTFDFDoc (PTAdditions)

- (NSArray<PTAnnot *> *)annots
{
    @try {
        PTObj *rootObj = [self GetRoot];
        if (![rootObj IsValid]) {
            return nil;
        }
        
        PTObj *fdfObj = [rootObj FindObj:@"FDF"];
        if (![fdfObj IsValid]) {
            return nil;
        }
        
        PTObj *annotsObj = [fdfObj FindObj:@"Annots"];
        if (![annotsObj IsValid] || ![annotsObj IsArray]) {
            return nil;
        }
        
        const unsigned long annotsCount = [annotsObj Size];
        NSMutableArray<PTAnnot *> *mutableAnnots = [NSMutableArray arrayWithCapacity:annotsCount];
        
        for (unsigned long i = 0; i < annotsCount; i++) {
            PTObj *annotObj = [annotsObj GetAt:i];
            if (![annotObj IsValid]) {
                continue;
            }
            
            PTAnnot *annot = [[PTAnnot alloc] initWithD:annotObj];
            [mutableAnnots addObject:annot];
        }
        
        return [mutableAnnots copy];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    
    return nil;
}

+ (instancetype)createWithAnnot:(PTAnnot *)annot
{
    if (![annot IsValid]) {
        return nil;
    }
    
    // Create an FDF doc from a "empty" XFDF string (has valid structure).
    PTFDFDoc *tempFDFDoc = [PTFDFDoc CreateFromXFDF:PT_FDFDocEmptyXFDF];
    PTSDFDoc *sdfDoc = [tempFDFDoc GetSDFDoc];
    
    // Create an array to hold the annot obj.
    PTObj *annotsArrayObj = [sdfDoc CreateIndirectArray];
    
    // Push back a copy of the annot obj into the array.
    PTObj *annotObjCopy = [sdfDoc ImportObj:[annot GetSDFObj] deep_copy:YES];
    [annotsArrayObj PushBack:annotObjCopy];
    
    // Attach the array to the "Annots" key.
    PTObj *fdfObj = [tempFDFDoc GetFDF];
    [fdfObj Put:@"Annots" obj:annotsArrayObj];
    
    return tempFDFDoc;
}

+ (NSString *)XFDFStringFromAnnot:(PTAnnot *)annot
{
    if (![annot IsValid]) {
        return nil;
    }

    // Get the XFDF string from the annot's FDF doc.
    PTFDFDoc *fdfDoc = [self createWithAnnot:annot];
    NSString *xfdfString = [fdfDoc SaveAsXFDFToString];
    [fdfDoc Close];
    
    return xfdfString;
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTFDFDoc, PTAdditions)
