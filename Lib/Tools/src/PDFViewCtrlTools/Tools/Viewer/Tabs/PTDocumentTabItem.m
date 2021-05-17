//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentTabItem.h"

#import "PTTabbedDocumentViewControllerPrivate.h"

#import "PTAutoCoding.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentTabItem ()

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentTabItem

- (void)PTDocumentTab_commonInit
{
    _lastAccessedDate = NSDate.distantPast;
}

- (instancetype)initWithSourceURL:(NSURL *)sourceURL
{
    self = [self init];
    if (self) {
        _sourceURL = sourceURL;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self PTDocumentTab_commonInit];
    }
    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        [PTAutoCoding autoUnarchiveObject:self
                                  ofClass:[PTDocumentTabItem class]
                                withCoder:coder];
        
        _sourceURL = [self decodeURLForKey:PT_SELF_KEY(sourceURL) withCoder:coder];
        _documentURL = [self decodeURLForKey:PT_SELF_KEY(documentURL) withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [PTAutoCoding autoArchiveObject:self
                            ofClass:[PTDocumentTabItem class]
                            forKeys:[PTDocumentTabItem autoEncodedKeys]
                          withCoder:coder];
    
    [self encodeURL:self.sourceURL forKey:PT_SELF_KEY(sourceURL) withCoder:coder];
    [self encodeURL:self.documentURL forKey:PT_SELF_KEY(documentURL) withCoder:coder];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (NSArray<NSString *> *)autoEncodedKeys
{
    return @[
        PT_CLASS_KEY(PTDocumentTabItem, displayName),
        PT_CLASS_KEY(PTDocumentTabItem, lastAccessedDate),
    ];
}

- (void)encodeURL:(NSURL *)url forKey:(NSString *)key withCoder:(NSCoder *)coder
{
    if (!url) {
        return;
    }
    
    const NSURLBookmarkCreationOptions options = (NSURLBookmarkCreationSuitableForBookmarkFile);

    NSError *error = nil;
    NSData *bookmark = [url bookmarkDataWithOptions:options
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil
                                              error:&error];
    if (!bookmark) {
        PTLog(@"Failed to create bookmark data for URL \"%@\": %@", url, error);
        return;
    }
    
    [coder encodeObject:bookmark forKey:key];
}

- (NSURL *)decodeURLForKey:(NSString *)key withCoder:(NSCoder *)coder
{
    NSData *bookmark = [coder decodeObjectForKey:key];
    if (!bookmark) {
        return nil;
    }
    
    // NSURLBookmarkResolutionWithSecurityScope unavailable and not needed on iOS
    const NSURLBookmarkResolutionOptions options = (NSURLBookmarkResolutionWithoutUI);
    
    BOOL bookmarkDataIsStale = NO;
    NSError *error = nil;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark
                                           options:options
                                     relativeToURL:nil
                               bookmarkDataIsStale:&bookmarkDataIsStale
                                             error:&error];
    if (!url) {
        PTLog(@"Failed to resolve URL bookmark data: %@", error);
        return nil;
    }
    
    
    if (!bookmarkDataIsStale) {
        PTLog(@"Need to handle stale bookmark");
    }
    
    if ([url isFileURL]) {
        const BOOL success = [url startAccessingSecurityScopedResource];
        if (!success) {
            PTLog(@"Failed to access security scoped resource with URL: %@", url);
            return nil;
        }
    }
    
    // Standardize and resolve symlinks in URL.
    //url = url.URLByStandardizingPath.URLByResolvingSymlinksInPath;
    
    return url;
}

#pragma mark - Header view

- (void)setHeaderView:(UIView *)headerView
{
    [self setHeaderView:headerView animated:NO];
}

- (void)setHeaderView:(UIView *)headerView animated:(BOOL)animated
{
    [self willChangeValueForKey:PT_SELF_KEY(headerView)];
    
    UIView *oldHeaderView = _headerView;
    _headerView = headerView;
    
    PTTabbedDocumentViewController *tabbedDocumentViewController = self.viewController.tabbedDocumentViewController;
    
    [tabbedDocumentViewController transitionFromHeaderView:oldHeaderView
                                              toHeaderView:headerView
                                                    forTab:self
                                                  animated:animated];
    
    [self didChangeValueForKey:PT_SELF_KEY(headerView)];
}

+ (BOOL)automaticallyNotifiesObserversOfHeaderView
{
    return NO;
}

@end
