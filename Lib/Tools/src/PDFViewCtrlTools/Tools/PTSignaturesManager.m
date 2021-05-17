//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSignaturesManager.h"

@interface PTSignaturesManager ()

@property (nonatomic, strong) NSArray<NSString*>* signatureArray;

@end


@implementation PTSignaturesManager

@synthesize signatureArray = _signatureArray;

static NSString * const PTSignaturesManager_signatureDirectory = @"PTSignaturesManager_signatureDirectory";
static NSString * const PTSignaturesManager_signatureArray = @"PTSignaturesManager_signatureArray.plist";
static NSString * const PTStampManager_signatureFileName = @"SignatureFile.CompleteReader.pdf";

-(NSArray<NSString *>*)signatureArray
{
    if( _signatureArray )
    {
        return _signatureArray;
    }
    else
    {
        _signatureArray = [self readSignatureArray];
        return _signatureArray;
    }
}

- (void)setSignatureArray:(NSArray<NSString *> *)signatureArray
{
    _signatureArray = signatureArray;
    [self saveSignatureArray];
}

-(NSURL*)signatureArrayUrl
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = paths[0];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@/%@", libraryDirectory, PTSignaturesManager_signatureDirectory, PTSignaturesManager_signatureArray];
    NSURL* signatureUrl = [NSURL fileURLWithPath:fullPath];
    return signatureUrl;
}

-(void)ensurePresenceOfSaveDirectory
{
    NSString* location = [[self signatureArrayUrl].path stringByDeletingLastPathComponent];
    
    BOOL isDir;
    
    if( [[NSFileManager defaultManager] fileExistsAtPath:location isDirectory:&isDir] == NO)
    {
        NSError* error;
        [[NSFileManager defaultManager] createDirectoryAtPath:location withIntermediateDirectories:YES attributes:Nil error:&error];
        if( error )
        {
            PTLog(@"Cound not create signature directory.");
            PTLog(@"%@", error.description);
        }
        NSLog(@"No");
    }
    
}

-(void)saveSignatureArray
{
    [self ensurePresenceOfSaveDirectory];
    
    NSURL* signtureDictUrl = [self signatureArrayUrl];
    
    NSError* errorObject;
    
    if (@available(iOS 11.0, *)) {
        BOOL error = [self.signatureArray writeToURL:signtureDictUrl error:&errorObject];
        
        if( !error )
        {
            PTLog(@"There was an error saving the signature array: %@", errorObject);
        }
    } else {
        // Fallback on earlier versions
        [self.signatureArray writeToURL:signtureDictUrl atomically:YES];
    }
}

-(NSArray*)readSignatureArray
{
    NSURL* signatureArrayUrl = [self signatureArrayUrl];
    NSArray* sigArray = [NSArray arrayWithContentsOfURL:signatureArrayUrl];
    if( sigArray )
    {
        return sigArray;
    }
    else
    {
        NSString* oldMySignature = [self GetSignatureDocPath];
        
        if( [[NSFileManager defaultManager] fileExistsAtPath:oldMySignature] )
        {
            NSString *savedSignatureDocPath = [self GetNewSignatureDocPath];
            NSError* error;
            
            [self ensurePresenceOfSaveDirectory];
            // old signature doc exists
            BOOL success = [[NSFileManager defaultManager] moveItemAtPath:oldMySignature toPath:savedSignatureDocPath error:&error];
            
            if( !success )
            {
                PTLog(@"Error copying signature file: %@", error.localizedFailureReason);
            }
            
            _signatureArray = [NSArray arrayWithObject:savedSignatureDocPath.lastPathComponent];
            
        }
        else
        {
            _signatureArray = @[];
        }
        
        [self saveSignatureArray];
        
        return _signatureArray;
    }
}

-(NSUInteger)numberOfSavedSignatures
{
    return self.signatureArray.count;
}

-(nullable PTPDFDoc*)savedSignatureAtIndex:(NSInteger)index
{
    if( index + 1 > [self numberOfSavedSignatures] )
    {
        return Nil;
    }

    PTPDFDoc* sigFile;
    
    NSString* fileName = self.signatureArray[index];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = paths[0];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@/%@", libraryDirectory, PTSignaturesManager_signatureDirectory, fileName];
    
    @try {
        sigFile = [[PTPDFDoc alloc] initWithFilepath:fullPath];
    } @catch (NSException *exception) {
        sigFile = Nil;
        PTLog(@"Error: Signature file could not be created. %s:%d", __FILE__, __LINE__);
    }
    
    return sigFile;
}

-(nullable UIImage*)imageOfSavedSignatureAtIndex:(NSInteger)index dpi:(NSUInteger)dpi
{
    PTPDFDraw* draw = [[PTPDFDraw alloc] initWithDpi:dpi];
    [draw SetPageTransparent:YES];
    [draw SetAntiAliasing:YES];
    
    PTPDFDoc* doc = [self savedSignatureAtIndex:index];
    
    if( !doc )
    {
        return Nil;
    }
    
    PTPage* page = [doc GetPage:1];
    
    PTBitmapInfo* bitmapInfoObject = [draw GetBitmap:page pix_fmt:e_ptbgra demult:NO];
    
    NSData* data = [bitmapInfoObject GetBuffer];
    UIImage* image = [PTSignaturesManager imageFromRawBGRAData:data width:[bitmapInfoObject getWidth] height:[bitmapInfoObject getHeight]];
    
    return image;
}

-(NSString*)GetSignatureDocPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *libraryDirectory = paths[0];
	return [libraryDirectory stringByAppendingPathComponent:PTStampManager_signatureFileName];
}

-(NSString*)GetNewSignatureDocPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = paths[0];

    NSString* fullPath = [NSString stringWithFormat:@"%@/%@/%@", libraryDirectory, PTSignaturesManager_signatureDirectory, [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"pdf"]];
    return fullPath;
    
    
    
}

-(PTPDFDoc*)GetStampDoc
{
	PTPDFDoc* doc = nil;
	
	if( [self HasDefaultSignature] )
	{
		doc = [[PTPDFDoc alloc] initWithFilepath:[self GetSignatureDocPath]];
	}
	else
		doc = [[PTPDFDoc alloc] init];
	
	return doc;
}



-(BOOL)HasDefaultSignature
{
	NSString* savedSignatureDocPath = [self GetSignatureDocPath];
	return [[NSFileManager defaultManager] fileExistsAtPath:savedSignatureDocPath];
}

-(PTPDFDoc*)GetDefaultSignature
{
	PTPDFDoc* sigFile = nil;
	
	if( [self HasDefaultSignature] )
	{
		NSString* savedSignatureDocPath = [self GetSignatureDocPath];

		sigFile = [[PTPDFDoc alloc] initWithFilepath:savedSignatureDocPath];

	}
	if( [sigFile GetPageCount] > 0)
		return sigFile;
	else
		return nil;

}


-(BOOL)deleteSignatureAtIndex:(NSInteger)index
{
    if( index + 1 > [self numberOfSavedSignatures] )
    {
        return NO;
    }
    
    NSString* fileName = self.signatureArray[index];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = paths[0];
    NSString* fullPath = [NSString stringWithFormat:@"%@/%@/%@", libraryDirectory, PTSignaturesManager_signatureDirectory, fileName];
    
    NSError* error;
    
    if( [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error] )
    {
        NSMutableArray* mutableArray = [self.signatureArray mutableCopy];
        [mutableArray removeObjectAtIndex:index];
        self.signatureArray = [mutableArray copy];
        return YES;
    }
    
    return NO;
}

-(BOOL)moveSignatureAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    @try {
        NSString* object = [self.signatureArray objectAtIndex:fromIndex];
        
        NSMutableArray* mutableArray = [self.signatureArray mutableCopy];
        
        [mutableArray removeObjectAtIndex:fromIndex];
        [mutableArray insertObject:object atIndex:toIndex];
        
        self.signatureArray = [mutableArray copy];
        
    } @catch (NSException *exception) {
        return NO;
    }
    
    return YES;
    
}

-(PTPDFDoc*)createSignature:(NSMutableArray*)points withStrokeColor:(UIColor*)strokeColor withStrokeThickness:(CGFloat)thickness withinRect:(CGRect)rect saveSignature:(BOOL)makeDefault
{
	NSString *savedSignatureDocPath = [self GetNewSignatureDocPath];
	
	PTPDFDoc* doc;
	
	// create a new page with a buffer of 20 on each side.
	if (makeDefault)
	{
		doc = [self GetStampDoc];
		[doc Lock];
		if( [doc GetPageCount] > 0)
		{
			[doc PageRemove:[doc GetPageIterator:1]];
		}
	}
	else
	{
		doc = [[PTPDFDoc alloc] init];
		[doc Lock];
	}
	assert(doc);
	double strokeWidth = thickness;
	PTPage* page = [doc PageCreate:[[PTPDFRect alloc] initWithX1:0 y1:0 x2:rect.size.width+strokeWidth*2 y2:rect.size.height+strokeWidth*2]];
				  
	[doc PagePushBack:page];
	assert([doc GetPageCount] > 0 );

	@try
	{
		
		// create the annotation in the middle of the page.
		PTInk* ink = [PTInk Create:[doc GetSDFDoc] pos:[[PTPDFRect alloc] initWithX1:strokeWidth y1:strokeWidth x2:rect.size.width+strokeWidth*2 y2:rect.size.height+strokeWidth*2]];
		PTBorderStyle* borderStyle = [ink GetBorderStyle];
		[borderStyle SetWidth:strokeWidth];
		
		[ink SetBorderStyle:borderStyle oldStyleOnly:NO];
		
		// Shove the points to the ink annotation
		PTPDFPoint* pdfp = [[PTPDFPoint alloc] init];
		
		int stroke = 0;
		int pointNumber = 0;
		
		for (NSValue* pointValue in points) {
			
			CGPoint point = pointValue.CGPointValue;
			if( CGPointEqualToPoint(point, CGPointZero) )
			{
				stroke++;
				pointNumber = 0;
				continue;
			}

			[pdfp setX:point.x - rect.origin.x + strokeWidth];
			[pdfp setY: rect.size.height-(point.y - rect.origin.y) + strokeWidth];
			[ink SetPoint:stroke pointindex:pointNumber pt:pdfp];

			pointNumber++;
		}
		
        CGFloat red, green, blue, alpha;
        
        [strokeColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        [ink SetColor:[[PTColorPt alloc] initWithX:red y:green z:blue w:alpha] numcomp:3];
		
		[ink RefreshAppearance];
		
		[page AnnotPushBack:ink];
		
		if (makeDefault)
		{
            [self ensurePresenceOfSaveDirectory];
			[doc SaveToFile:savedSignatureDocPath flags:0];
            self.signatureArray = [self.signatureArray arrayByAddingObject:savedSignatureDocPath.lastPathComponent];
		}
		
	}
	@catch (NSException* ex)
	{
		
	}
	@finally
	{
		[doc Unlock];
	}
	
	assert(doc);
	assert([doc GetPage:1]);
	PTPage* myPage = [doc GetPage:1];
	assert(myPage);
	
	PTPDFRect* rct = [myPage GetCropBox];
	assert(rct);
    (void)rct;
	return doc;
}

+(UIImage*)imageFromRawBGRAData:(NSData*)data width:(int)width height:(int)height
{
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    const int bitsPerComponent = 8;
    const int bitsPerPixel = 4 * bitsPerComponent;
    const int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    double screenScale = [[UIScreen mainScreen] scale];
    
    UIImage *myImage = [UIImage imageWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    return myImage;
}

@end
