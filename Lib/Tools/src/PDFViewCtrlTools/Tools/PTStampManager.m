//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTStampManager.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation PTStampManager
#pragma clang diagnostic pop


static NSString * const PTStampManager_signatureFileName = @"SignatureFile.CompleteReader.pdf";

-(NSString*)GetSignatureDocPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *libraryDirectory = paths[0];
	return [libraryDirectory stringByAppendingPathComponent:PTStampManager_signatureFileName];
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

-(void)DeleteDefaultSignatureFile
{
	NSString* savedSignatureDocPath = [self GetSignatureDocPath];
	if ([[NSFileManager defaultManager] isDeletableFileAtPath:savedSignatureDocPath]) {
		NSError *error;
		BOOL success = [[NSFileManager defaultManager] removeItemAtPath:savedSignatureDocPath error:&error];
		if (!success) {
			NSLog(@"Error removing signature file: %@", error.localizedDescription);
		}
	}
}

-(PTPDFDoc*)CreateSignature:(NSMutableArray*)points withStrokeColor:(UIColor*)strokeColor withStrokeThickness:(CGFloat)thickness withinRect:(CGRect)rect makeDefault:(BOOL)makeDefault
{
	NSString *savedSignatureDocPath = [self GetSignatureDocPath];
	
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
		
		// Make the page crop box the same as the annotation bounding box, so that there's no gaps.
		
//		PTPDFRect* newBoundRect = [ink GetRect];
//		[page SetCropBox:newBoundRect];
		
		[ink RefreshAppearance];
		
		[page AnnotPushBack:ink];
		
		if (makeDefault)
		{
			[doc SaveToFile:savedSignatureDocPath flags:0];
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



@end
