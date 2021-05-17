//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTReflowPageContentViewController.h"

#import "PTToolsUtil.h"
#import "UIColor+PTHexString.h"

#import <objc/runtime.h>

static NSString * const kPTReflowContentAboutBlank = @"about:blank";

@interface NSURL (PTBlankURL)

@property (nonatomic, readonly, getter=pt_isBlankURL) BOOL pt_blankURL;

@end

@implementation NSURL (PTBlankURL)

- (BOOL)pt_isBlankURL
{
    //return [self.absoluteString isEqualToString:@""] || self.absoluteString == Nil;
    return [self.absoluteString isEqualToString:kPTReflowContentAboutBlank];
}

@end

@interface PTReflowPageContentViewController () <WKNavigationDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) WKWebView *webView;

@property (nonatomic, copy, readonly) NSString* blankHtml;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong, nullable) NSURL *requestedURL;

@property (nonatomic, assign, getter=isRequestedURLLoaded) BOOL requestedURLLoaded;

#pragma mark - User scripts

@property (nonatomic, readonly, strong) WKUserScript *viewportScaleScript;

@end

@implementation PTReflowPageContentViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _scale = 1.0;
        
        _backgroundColor = UIColor.whiteColor;
        
    }
    return self;
}

-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    CGFloat brightness;
    BOOL success = [backgroundColor getHue:Nil saturation:Nil brightness:&brightness alpha:Nil];
    
    if( success && brightness < 0.5 )
    {
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    }
    else
    {
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    }
}

-(NSString*)blankHtml
{
    NSString* hexColor = [UIColor pt_hexStringFromColor:self.backgroundColor];
    return [NSString stringWithFormat:@"<!DOCTYPE html><html><body style=\"background-color:%@\"></body></html>",hexColor];
}

#pragma mark - User scripts

- (WKUserScript *)viewportScaleScript
{
    NSString *jsSource = PT_NS_STRINGIFY(
        let viewportContent = "width=device-width, initial-scale=1.0";
        
        // Find viewport meta tag.
        let viewport = document.querySelector("meta[name=viewport]");
        if (viewport) {
            viewport.setAttribute("content", viewportContent);
        } else {
            // Create viewport meta tag.
            let metaTag = document.createElement("meta");
            metaTag.name = "viewport";
            metaTag.content = viewportContent;
            document.head.appendChild(metaTag);
        }
    );
    
    return [[WKUserScript alloc] initWithSource:jsSource injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
}

#pragma mark - View life cycle

-(void)refreshWebview
{
    [self unloadWebView];
    [self loadWebView];
}

- (void)loadWebView
{
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    [configuration.userContentController addUserScript:self.viewportScaleScript];
        
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    self.webView.opaque = NO;
    self.webView.navigationDelegate = self;
    
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view insertSubview:self.webView atIndex:0];
    
    // Detect unhandled taps in the web view.
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleWebViewTap:)];
    self.tapGestureRecognizer.delegate = self;
    [self.webView addGestureRecognizer:self.tapGestureRecognizer];
    
    // Attach double tap recognizer that will block all other double taps.
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    self.doubleTapGestureRecognizer.delegate = self;
    [self.webView addGestureRecognizer:self.doubleTapGestureRecognizer];
    
    // Attach pinch recognizer that will override all other pinches.
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleWebViewPinch:)];
    self.pinchGestureRecognizer.delegate = self;
    [self.webView addGestureRecognizer:self.pinchGestureRecognizer];
}

- (void)unloadWebView
{
    [self.webView removeFromSuperview];
}

// NOTE: Do *not* call super implementation.
- (void)loadView
{
    // Standard root view.
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.view = view;
    
    // Web view.
    [self loadWebView];
    
    // Activity indicator.
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    
    [self.view addSubview:self.activityIndicator];
    
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Center activity indicator in view.
    [NSLayoutConstraint activateConstraints:
     @[
       [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
       [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
       /* Use intrinsic UIActivityIndicatorView width and height. */
       ]];
    
    self.activityIndicator.hidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

#pragma mark - WebView

- (WKWebView *)webView
{
    [self loadViewIfNeeded];
    
    NSAssert(_webView != nil, @"Web view was not created successfully");
    
    return _webView;
}

- (void)handleWebViewTap:(UITapGestureRecognizer *)gestureRecognizer
{
    BOOL handled = NO;
    
    if (self.turnPageOnTap) {
        CGPoint location = [gestureRecognizer locationInView:self.view];
        
        CGFloat relativeX = location.x / CGRectGetWidth(self.view.bounds);
        
        if (relativeX < (1.0 / 7.0)) { // Left edge of screen.
            handled = YES;
            
            // Request page change.
            if ([self.delegate respondsToSelector:@selector(reflowContentViewController:changePageWithDirection:)]) {
                [self.delegate reflowContentViewController:self changePageWithDirection:PTReflowContentNavigationDirectionReverse];
            }
        } else if (relativeX > (6.0 / 7.0)) { // Right edge of screen.
            handled = YES;
            
            // Request page change.
            if ([self.delegate respondsToSelector:@selector(reflowContentViewController:changePageWithDirection:)]) {
                [self.delegate reflowContentViewController:self changePageWithDirection:PTReflowContentNavigationDirectionForward];
            }
        }
    }
    
    if (!handled) {
        if ([self.delegate respondsToSelector:@selector(reflowContentViewController:handleTap:)]) {
            [self.delegate reflowContentViewController:self handleTap:gestureRecognizer];
        }
    }
}

- (void)handleWebViewPinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(reflowContentViewController:didBeginScale:)]) {
                [self.delegate reflowContentViewController:self didBeginScale:gestureRecognizer.scale];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if ([self.delegate respondsToSelector:@selector(reflowContentViewController:didChangeScale:)]) {
                [self.delegate reflowContentViewController:self didChangeScale:gestureRecognizer.scale];
            }
            break;
        case UIGestureRecognizerStateEnded:
            if ([self.delegate respondsToSelector:@selector(reflowContentViewController:didEndScale:)]) {
                [self.delegate reflowContentViewController:self didEndScale:gestureRecognizer.scale];
            }
            break;
        case UIGestureRecognizerStateCancelled:
            if ([self.delegate respondsToSelector:@selector(reflowContentViewControllerDidCancelScale:)]) {
                [self.delegate reflowContentViewControllerDidCancelScale:self];
            }
            break;
        default:
            break;
    }
}

#pragma mark - State

- (void)setState:(PTReflowContentState)state
{
    _state = state;
    
    switch (state) {
        case PTReflowContentStateIdle:
            // Entering idle state.
            [self PT_enterIdleState];
            break;
        case PTReflowContentStateLoading:
            // Entering loading state.
            [self PT_enterLoadingState];
            break;
        case PTReflowContentStateComplete:
            // Entering complete state.
            [self PT_enterCompleteState];
            break;
    }
}

- (void)PT_enterIdleState
{
    self.requestedURL = nil;
    self.requestedURLLoaded = NO;
    
    // Clear web view.
    [self loadBlankURL];
    
    // Stop activity indicator.
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

- (void)PT_enterLoadingState
{
    self.requestedURL = nil;
    self.requestedURLLoaded = NO;
    
    // Clear web view.
    [self loadBlankURL];
    
    // Start activity indicator.
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)PT_enterCompleteState
{
    // Do nothing.
}

// Load "about:blank" in web view.
- (void)loadBlankURL
{
    
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kPTReflowContentAboutBlank]]];
    NSString* strToLoad = self.blankHtml;
    [self.webView loadHTMLString:strToLoad baseURL:[NSURL URLWithString:kPTReflowContentAboutBlank]];
}

#pragma mark - Load requested URL

- (void)loadURL:(NSURL *)requestedURL
{
    NSParameterAssert([requestedURL isFileURL]);
    
    self.requestedURL = requestedURL;
    self.requestedURLLoaded = NO;
    
    // Must allow WebKit read access to the containing directory. Allowing read access only to the
    // requested URL does work, but causes issues when the web view is reused (fails the provisional
    // navigation).
    //NSURL *directoryForRequestedURL = requestedURL.URLByDeletingLastPathComponent;
    
//    self.webView.backgroundColor = UIColor.yellowColor;
//    self.webView.scrollView.backgroundColor = UIColor.yellowColor;
    
    NSURL *cachesURL = [NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    
    [self.webView loadFileURL:requestedURL allowingReadAccessToURL:cachesURL];
}

#pragma mark - <WKNavigationDelegate>

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    
    // LOL
    // https://forums.developer.apple.com/thread/110072
    if (self.requestedURL)
    {
        [self loadURL:self.requestedURL];
    }
    else if( [[webView.URL absoluteString] isEqualToString:kPTReflowContentAboutBlank])
    {
        [self loadBlankURL];
    }
    else if( webView.URL )
    {
         [self loadURL:webView.URL];
    }
    else
    {
     NSLog(@"%@", error);
    }
}

// Started navigation (no content).
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if ([self.webView.URL pt_isBlankURL]) {
        return;
    }
    
    // Show & start activity indicator.
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if ([self.webView.URL pt_isBlankURL]) {
        return;
    }
    
    self.requestedURLLoaded = YES;
    
    // Manually apply webkitTextSizeAdjust attribute.
    // (A WKUserScript cannot be updated after being set)
    [self applyTextSizeAdjust];
    
    // Stop & hide activity indicator.
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURLRequest *request = navigationAction.request;
    NSAssert(request.URL != nil, @"Received a navigation action without a URL");
    
    if ([request.URL isFileURL]) {
        // Check for explicitly requested URL.
        if ([request.URL isEqual:self.requestedURL]) {
            if (decisionHandler) {
                decisionHandler(WKNavigationActionPolicyAllow);
            }
            return;
        }
        
        // Let delegate handle this possible internal link.
        if ([self.delegate respondsToSelector:@selector(reflowContentViewController:didSelectFileURL:)]) {
            [self.delegate reflowContentViewController:self didSelectFileURL:request.URL];
        }
        
        // Cancel WebKit navigation.
        if (decisionHandler) {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        return;
    }
    
    // Check for idle/loading page.
    if ([request.URL pt_isBlankURL]) {
        if (decisionHandler) {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
        return;
    }
    
    // Let the system handle the URL (asynchronously).
    [UIApplication.sharedApplication openURL:request.URL options:@{} completionHandler:nil];
    
    // Cancel WebKit navigation.
    if (decisionHandler) {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Recognize the same number of taps simultaneously.
    if ((self.tapGestureRecognizer == gestureRecognizer)
        && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
        && [otherGestureRecognizer.view isDescendantOfView:gestureRecognizer.view]
        && ((UITapGestureRecognizer *)otherGestureRecognizer).numberOfTapsRequired == ((UITapGestureRecognizer *)gestureRecognizer).numberOfTapsRequired) {
        return YES;
    }
    
    if (@available(iOS 13.0, *)) {
        // Need to recognize pinches simultaneously as builtin gesture recognizer.
        if ((self.pinchGestureRecognizer == gestureRecognizer)
            && [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]
            && [otherGestureRecognizer.view isDescendantOfView:gestureRecognizer.view]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Require double tap gesture recognizers to fail first.
    if ((self.tapGestureRecognizer == gestureRecognizer)
        && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
        && [otherGestureRecognizer.view isDescendantOfView:gestureRecognizer.view]
        && ((UITapGestureRecognizer *)otherGestureRecognizer).numberOfTapsRequired > ((UITapGestureRecognizer *)gestureRecognizer).numberOfTapsRequired) {
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Disable all other double (or more) tap gesture recognizers.
    if ((self.doubleTapGestureRecognizer == gestureRecognizer)
        && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
        && [otherGestureRecognizer.view isDescendantOfView:gestureRecognizer.view]
        && ((UITapGestureRecognizer *)otherGestureRecognizer).numberOfTapsRequired >= ((UITapGestureRecognizer *)gestureRecognizer).numberOfTapsRequired) {
        return YES;
    }
    
    // Disable all other pinch gesture recognizers.
    if ((self.pinchGestureRecognizer == gestureRecognizer)
        && [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]
        && [otherGestureRecognizer.view isDescendantOfView:gestureRecognizer.view]) {
        // Disable the scroll view's pinch gesture recognizer.
        // Otherwise, during a scroll decelerate the scroll view's recognizer will still fire.
        if (self.webView.scrollView.pinchGestureRecognizer == otherGestureRecognizer) {
            otherGestureRecognizer.enabled = NO;
        }
        return YES;
    }
    
    return NO;
}

#pragma mark - DEBUG

- (void)setScale:(CGFloat)scale
{
    if (_scale == scale) {
        // No change.
        return;
    }
    
    _scale = scale;
    
    if (![self isRequestedURLLoaded]) {
        // Scale will be applied when requested URL is loaded.
        return;
    }
    
    [self applyTextSizeAdjust];
}

- (void)applyTextSizeAdjust
{
    BOOL textSizeAdjustAvailable = YES;
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            textSizeAdjustAvailable = NO;
        }
    }
    
    NSString *jsSource = nil;
    if (textSizeAdjustAvailable) {
        jsSource = [NSString stringWithFormat:PT_NS_STRINGIFY(document.body.style.webkitTextSizeAdjust = "%f%%";),
                    (self.scale * 100.0)];
    }
    else {
        NSString *filePath = [PTToolsUtil.toolsBundle pathForResource:@"text-size-adjust" ofType:@"js"];
        NSString *sourceFormat = [NSString stringWithContentsOfFile:filePath
                                                           encoding:NSUTF8StringEncoding
                                                              error:nil];
        
        jsSource = [NSString stringWithFormat:sourceFormat, self.scale];
    }
    
    [self.webView evaluateJavaScript:jsSource completionHandler:^(id result, NSError *error) {
        if (result) {
            NSLog(@"Javascript evaluation result: %@", result);
        }
        
        if (error) {
            NSLog(@"Javascript error: %@", error);
        }
    }];
}

@end
