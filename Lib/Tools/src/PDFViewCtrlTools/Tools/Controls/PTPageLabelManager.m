//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPageLabelManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTPageLabelManager ()

@end

NS_ASSUME_NONNULL_END

@implementation PTPageLabelManager

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super init];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
    }
    return self;
}

- (PTPageLabel *)pageLabelForPageNumber:(int)pageNumber
{
    __block PTPageLabel *pageLabel = nil;
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        pageLabel = [self PT_pageLabelForPageNumber:pageNumber
                                                doc:doc];
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    return pageLabel;
}

- (NSString *)pageLabelPrefixForPageNumber:(int)pageNumber
{
    __block NSString *prefix = nil;
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        PTPageLabel *pageLabel = [self PT_pageLabelForPageNumber:pageNumber
                                                             doc:doc];
        prefix = [pageLabel GetPrefix];
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    return prefix;

}

- (NSString *)pageLabelTitleForPageNumber:(int)pageNumber
{
    __block NSString *title = nil;
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        PTPageLabel *pageLabel = [self PT_pageLabelForPageNumber:pageNumber
                                                             doc:doc];
        title = [pageLabel GetLabelTitle:pageNumber];
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    return title;
}

- (int)pageNumberForPageLabelTitle:(NSString *)pageLabelTitle
{
    if (!pageLabelTitle) {
        return 0;
    }
    
    __block int foundPageNumber = 0;
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        [self PT_enumeratePageLabelsInDoc:doc
                     startingAtPageNumber:1
                                withBlock:^(PTPageLabel *pageLabel, int pageNumber, BOOL *stop) {
            NSString *title = [pageLabel GetLabelTitle:pageNumber];
            // Compare titles in the default locale.
            if ([title localizedStandardCompare:pageLabelTitle] == NSOrderedSame) {
                foundPageNumber = pageNumber;
                // Stop enumerating.
                *stop = YES;
                return;
            }
        }];
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }

    return foundPageNumber;
}

static BOOL PT_isPageLabelEqualToPageLabel(PTPageLabel *pageLabel1, PTPageLabel *pageLabel2)
{
    return ([[pageLabel1 GetPrefix] isEqualToString:[pageLabel2 GetPrefix]] &&
            [pageLabel1 GetFirstPageNum] == [pageLabel2 GetFirstPageNum] &&
            [pageLabel1 GetStyle] == [pageLabel2 GetStyle]);
}

- (PTPageLabel *)setPageLabelStyle:(PTPageLabelStyle)pageLabelStyle fromPageNumber:(int)firstPageNumber toPageNumber:(int)lastPageNumber
{
    return [self setPageLabelStyle:pageLabelStyle
                            prefix:nil
                        startValue:1
                    fromPageNumber:firstPageNumber
                      toPageNumber:lastPageNumber];
}

- (PTPageLabel *)setPageLabelStyle:(PTPageLabelStyle)pageLabelStyle prefix:(NSString *)prefix startValue:(int)startValue fromPageNumber:(int)firstPageNumber toPageNumber:(int)lastPageNumber
{
    __block PTPageLabel *createdPageLabel = nil;
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        const int pageCount = [doc GetPageCount];
        
        // Check to see if we are overriding any page labels.
        PTPageLabel *lastOverriddenPageLabel = nil;
        for (int pageNumber = firstPageNumber; pageNumber <= lastPageNumber; pageNumber++) {
            PTPageLabel *pageLabel = [doc GetPageLabel:pageNumber];
            if ([pageLabel IsValid]) {
                lastOverriddenPageLabel = pageLabel;
                // Remove all page labels within this range.
                if ([pageLabel GetFirstPageNum] >= firstPageNumber) {
                    [doc RemovePageLabel:pageNumber];
                }
            }
        }
        
        // Set the new page label.
        PTPageLabel *newPageLabel = [PTPageLabel Create:[doc GetSDFDoc]
                                                  style:pageLabelStyle
                                                 prefix:(prefix ?: @"")
                                               start_at:startValue];
        [doc SetPageLabel:firstPageNumber label:newPageLabel];
        newPageLabel = [doc GetPageLabel:firstPageNumber];
        
        createdPageLabel = newPageLabel;
        
        // Also set the page label for next pages if it does not have a page label.
        const int nextPageNumber = lastPageNumber + 1;
        if (nextPageNumber <= pageCount) {
            PTPageLabel *nextPageLabel = [doc GetPageLabel:nextPageNumber];
            if ([nextPageLabel IsValid] && PT_isPageLabelEqualToPageLabel(nextPageLabel,
                                                                          newPageLabel)) {
                // There is no old page label here so write a new one.
                if (!lastOverriddenPageLabel) {
                    // We did not override any page labels so just make a new one.
                    nextPageLabel = [PTPageLabel Create:[doc GetSDFDoc]
                                                  style:e_ptdecimal
                                                 prefix:@""
                                               start_at:firstPageNumber];
                } else {
                    // Place the last overridden page label after our new one.
                    const int nextStartPageNumber = ([lastOverriddenPageLabel GetStart]
                                                     + firstPageNumber
                                                     - [lastOverriddenPageLabel GetFirstPageNum]);
                    nextPageLabel = [PTPageLabel Create:[doc GetSDFDoc]
                                                  style:[lastOverriddenPageLabel GetStyle]
                                                 prefix:[lastOverriddenPageLabel GetPrefix]
                                               start_at:nextStartPageNumber];
                }
                [doc SetPageLabel:nextPageNumber label:nextPageLabel];
            }
        }
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    return createdPageLabel;
}

- (void)removeAllPageLabels
{
    NSError *error = nil;
    [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        PTObj *rootObj = [doc GetRoot];
        if ([rootObj IsValid]) {
            [rootObj EraseDictElementWithKey:@"PageLabels"];
        }
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
}

- (void)enumeratePageLabelsStartingAtPageNumber:(int)startPageNumber withBlock:(void (^)(PTPageLabel *pageLabel, int pageNumber, BOOL *stop))block
{
    if (startPageNumber < 1 || !block) {
        return;
    }
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        [self PT_enumeratePageLabelsInDoc:doc
                     startingAtPageNumber:startPageNumber
                                withBlock:block];
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
}

- (void)PT_enumeratePageLabelsInDoc:(PTPDFDoc *)doc startingAtPageNumber:(int)startPageNumber withBlock:(void (^)(PTPageLabel *pageLabel, int pageNumber, BOOL *stop))block
{
    const int pageCount = [doc GetPageCount];
    for (int pageNumber = startPageNumber; pageNumber <= pageCount; pageNumber++) {
        PTPageLabel *pageLabel = [doc GetPageLabel:pageNumber];
        if ([pageLabel IsValid]) {
            // Get the upper bound for the page label's range.
            const int lastPageNumber = MIN([pageLabel GetLastPageNum], pageCount);
            do {
                BOOL stop = NO;
                block(pageLabel, pageNumber, &stop);
                // Should we stop enumerating page labels?
                if (stop) {
                    return;
                }
                pageNumber++;
            } while (pageNumber <= lastPageNumber);
            // Reset page number to the page label upper bound, otherwise the page number will
            // skip over lastPageNumber+1 when the for-loop increments the loop index (page number).
            pageNumber = lastPageNumber;
        }
    }
}

- (PTPageLabel *)PT_pageLabelForPageNumber:(int)pageNumber doc:(PTPDFDoc *)doc
{
    PTPageLabel *pageLabel = [doc GetPageLabel:pageNumber];
    if ([pageLabel IsValid]) {
        return pageLabel;
    }
    return nil;
}

@end
