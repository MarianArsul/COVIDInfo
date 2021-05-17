//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTRichMediaTool.h"
#import "PTPanTool.h"

#import "UIView+PTAdditions.h"

@interface PTRichMediaTool ()

// Redeclare properties as readwrite internally.
@property (nonatomic, readwrite, strong, nullable) AVPlayerViewController *moviePlayer;
@property (nonatomic, readwrite, copy, nullable) NSString *moviePath;

@end

@implementation PTRichMediaTool

-(BOOL)supportedMediaType:(NSString *)extension
{
    NSArray<NSString *> *supportedFormats = @[@"mov", @"mp4", @"m4v", @"3gp"];
    return [supportedFormats containsObject:extension];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    @try {
        [self.pdfViewCtrl DocLockRead];
        
        
        if (self.currentAnnotation) {
            self.currentAnnotation = 0;
        }
        
        CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
        
        self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
        self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:down.x y:down.y];
        
        PTObj* annotObj = [self.currentAnnotation GetSDFObj];
        PTObj* content = [annotObj FindObj:@"RichMediaContent"];
        
        if( [content IsValid] )
        {
            
            PTObj* assetsObj = [content FindObj:@"Assets"];
            
            if( [assetsObj IsValid] )
            {
                
                PTNameTree* assets = [[PTNameTree alloc] initWithName_tree:assetsObj];
                
                for(PTDictIterator* itr = [assets GetIterator]; [itr HasNext]; [itr Next] )
                {
                    NSString* asset_name = [[itr Key] GetAsPDFText];
                    
                    // prefix file name so that files with no name such as ".mp4" will still play
                    asset_name = [@"a" stringByAppendingString:asset_name];
                    
                    BOOL supportedType = [self supportedMediaType:asset_name.pathExtension];
                    
                    if( !supportedType )
                    {
                        continue;
                    }
                    else
                    {
                        if( self.moviePlayer )
                        {
                            [self resetPlayer];
                        }
                        
                        self.moviePath = [NSTemporaryDirectory() stringByAppendingPathComponent:asset_name];
                        
                        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.moviePath];
                        
                        if( !fileExists )
                        {
                            PTFileSpec* fileSpec = [[PTFileSpec alloc] initWithF:[itr Value]];
                            PTFilter* data = [fileSpec GetFileData];
                            [data WriteToFile:self.moviePath append:false];
                        }
                        
                        PTPDFRect* rect = [self.currentAnnotation GetRect];
                        
                        CGRect screenRect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
                        
                        screenRect.origin.x += [self.pdfViewCtrl GetHScrollPos];
                        screenRect.origin.y += [self.pdfViewCtrl GetVScrollPos];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.moviePlayer.player.currentItem];
                        
                        self.moviePlayer = [[AVPlayerViewController alloc] init];
                        self.moviePlayer.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.moviePath]];
                        
                        if (@available(iOS 11.0, *)) {
                            [self.moviePlayer setExitsFullScreenWhenPlaybackEnds:YES];
                        }

                        UIViewController *viewController = [self pt_viewController];
                        [viewController addChildViewController:self.moviePlayer];
                        (self.moviePlayer.view).frame = CGRectMake(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height);

                        [self.pdfViewCtrl.toolOverlayView addSubview:self.moviePlayer.view];
                        [self.moviePlayer didMoveToParentViewController:viewController];
                        [self.moviePlayer.player play];

                        break;
                    }
                    
                }
            }
            
            return YES;
        }
        
        return NO;
    }
    @catch (NSException *exception) {
        //log
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    return YES;
}

-(void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl*)pdfViewCtrl
{
    PTPDFRect* rect;
    CGRect screenRect;
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        rect = [self.currentAnnotation GetRect];
        
        screenRect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    screenRect.origin.x += [self.pdfViewCtrl GetHScrollPos];
    screenRect.origin.y += [self.pdfViewCtrl GetVScrollPos];
    
    (self.moviePlayer.view).frame = CGRectMake(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height);
    
    [super pdfViewCtrlOnLayoutChanged:pdfViewCtrl];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
    [self.toolManager createSwitchToolEvent:nil];
    [super pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:oldPageNumber To:newPageNumber];
}

-(BOOL) onSwitchToolEvent:(id)userData
{
    self.nextToolType = [PTPanTool class];
    return NO;
}

-(void)endPlayback
{
    [self.moviePlayer willMoveToParentViewController:nil];
    [self.toolManager createSwitchToolEvent:nil];
}

-(void)playerDidFinishPlaying:(NSNotification *)notification
{
    // This function only seems to be called when not in full screen mode on iOS13+
    if (@available(iOS 13.0, *)) {
        // Disable auto exit in non-fullscreen mode as it dismisses the parent VC instead of just the video player on iOS13+
        [self.moviePlayer setExitsFullScreenWhenPlaybackEnds:NO];
    }
    [self endPlayback];
}

-(void)resetPlayer
{
    [self.moviePlayer.player pause];
    [self.moviePlayer.view removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.moviePlayer.player.currentItem];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.moviePath error:NULL];
    
    self.moviePlayer = nil;
    [self.moviePlayer removeFromParentViewController];
}

-(void)dealloc
{
    if( self.moviePlayer )
    {
        [self resetPlayer];
    }
    
}

@end
