//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolsUtil.h"

#import <CoreBluetooth/CoreBluetooth.h>

static NSString * const PTToolsBundleIdentifier = @"com.pdftron.Tools";

/**
 * This key is used as the default localized string value when checking if a string definition has
 * been overridden in the main (app) bundle, in the "PTLocalizable" string table. If this value is
 * returned from that check then it means that the string definition was not found and the Tools
 * bundle should be searched next.
 */
static NSString * const PT_LocalizedStringNotFound = @"PT_LocalizedStringNotFound";

#define PT_OVERRIDDEN_STRINGS_TABLE @"PTLocalizable"

@implementation PTToolsUtil

static NSBundle *PTToolsUtil_toolsBundle;

//static CBCentralManager* PTToolsUtil_centralManager;

static UIImage* makeImageNegative(UIImage* originalImage)
{
    UIGraphicsBeginImageContext(originalImage.size);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
    CGRect imageRect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    [originalImage drawInRect:imageRect];
    
    
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, originalImage.size.height);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    //mask the image
    CGContextClipToMask(UIGraphicsGetCurrentContext(), imageRect,  originalImage.CGImage);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, originalImage.size.width, originalImage.size.height));
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}

+ (UIImage*)toolImageNamed:(NSString*)name inverted:(BOOL)inverted
{
    if( !inverted )
        return [PTToolsUtil toolImageNamed:name];
    else
        return makeImageNegative([PTToolsUtil toolImageNamed:name]);
}

+ (UIImage*)toolImageNamed:(NSString*)name
{
    // Check in Asset catalogs first.
    UIImage *assetCatalogImage = [UIImage imageNamed:name
                                            inBundle:PTToolsUtil.toolsBundle
                       compatibleWithTraitCollection:nil];
    
    if (assetCatalogImage) {
        return assetCatalogImage;
    }
    
	NSArray<NSString *> *imageExtensions = @[
        @"png", @"jpg", @"jpeg", @"tif", @"tiff", @"gif", @"bmp", @"BMP", @"ico", @"cur", @"xbm"
    ];
	
    NSString *nameNoExtension = name.stringByDeletingPathExtension;

	for (NSString *extension in imageExtensions) {
        NSString *path = [PTToolsUtil.toolsBundle pathForResource:[@"Images" stringByAppendingPathComponent:nameNoExtension] ofType:extension];
        if (path.length > 0) {
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            if (image) {
                // Always use the image as a template (for tinting).
				return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
		}
	}
    
    NSLog(@"Could not find Tools image named \"%@\"", name);

	return nil;
}

+ (NSBundle *)findToolsBundle
{
    // Bundle of the enclosing class (for Tools framework bundle).
    NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
    if ([classBundle.bundleIdentifier isEqualToString:PTToolsBundleIdentifier]) {
        return classBundle;
    }
    
    // Tools.bundle in the enclosing bundle.
    NSURL *bundleURL = [classBundle URLForResource:@"Tools" withExtension:@"bundle"];
    if (bundleURL) {
        NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
        if ([bundle.bundleIdentifier isEqualToString:PTToolsBundleIdentifier]) {
            return bundle;
        }
    }
    
    // Bundle with Tools identifier located in the enclosing bundle.
    NSArray<NSURL *> *bundleURLs = [classBundle URLsForResourcesWithExtension:@"bundle"
                                                                 subdirectory:nil];
    for (NSURL *url in bundleURLs) {
        NSBundle *bundle = [NSBundle bundleWithURL:url];
        if ([bundle.bundleIdentifier isEqualToString:PTToolsBundleIdentifier]) {
            return bundle;
        }
    }
    
    return nil;
}

+ (NSBundle *)toolsBundle
{
	if (!PTToolsUtil_toolsBundle) {
        NSBundle *bundle = [self findToolsBundle];
        if (!bundle) {
            // Failed to find Tools bundle: Using main bundle.
            bundle = NSBundle.mainBundle;
        }
        NSAssert(bundle != nil, @"Failed to find suitable Tools bundle");
        
        PTToolsUtil_toolsBundle = bundle;
	}
	
	return PTToolsUtil_toolsBundle;
}

+ (NSURL *)toolsResourcesDirectoryURL
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSError *error = nil;

    NSURL *applicationSupportURL = [fileManager URLsForDirectory:NSApplicationSupportDirectory
                                                       inDomains:NSUserDomainMask].firstObject;
    
    // Create "Library/Application Support" directory (or ensure that it exists).
    BOOL applicationSupportExists = [fileManager createDirectoryAtURL:applicationSupportURL
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&error];
    if (!applicationSupportExists) {
        NSLog(@"The \"%@\" directory could not be found or created: %@",
              @"Library/Application Support", error);
        return nil;
    }
    
    NSURL *resourcesDirectoryURL = nil;
    
    // Use the Tools bundle identifier as the framework-specific directory inside
    // the Application Support directory.
    NSString *bundleIdentifier = self.toolsBundle.bundleIdentifier;
    if (bundleIdentifier.length > 0) {
        resourcesDirectoryURL = [applicationSupportURL URLByAppendingPathComponent:bundleIdentifier];
        
        BOOL resourcesDirectoryCreated = [fileManager createDirectoryAtURL:resourcesDirectoryURL
                                               withIntermediateDirectories:YES
                                                                attributes:nil
                                                                     error:&error];
        if (!resourcesDirectoryCreated) {
            NSLog(@"Failed to create directory \"%@\": %@",
                  resourcesDirectoryURL, error);

            // Use the Application Support directory.
            resourcesDirectoryURL = applicationSupportURL;
        }
    } else {
        // Use the Application Support directory.
        resourcesDirectoryURL = applicationSupportURL;
    }

    return resourcesDirectoryURL;
}

+(PTPDFDoc*)createPTPDFDocFromFromUIView:(UIView*)aView
{
    // Creates a mutable data object for updating with binary data, like a byte array
    NSMutableData *pdfData = [NSMutableData data];

    // Points the pdf converter to the mutable data object and to the UIView to be converted
    UIGraphicsBeginPDFContextToData(pdfData, aView.bounds, Nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();


    // draws rect to the view and thus this is captured by UIGraphicsBeginPDFContextToData

    aView.layer.sublayers = Nil;
    [aView.layer renderInContext:pdfContext];
    

    // remove PDF rendering context
    UIGraphicsEndPDFContext();
    
    PTPDFDoc* doc = [[PTPDFDoc alloc] initWithBuf:pdfData buf_size:[pdfData length]];

    return doc;
}

@end

static BOOL PT_isStringNotFound(NSString *string)
{
    static NSString *PT_LocalizedStringNotFoundValue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *stringNotFoundValue = PT_LocalizedStringNotFound;
        
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        
        NSDictionary<NSString *, id> *arguments = [defaults volatileDomainForName:NSArgumentDomain];
        
        id doubleLocalizedValue = arguments[@"NSDoubleLocalizedStrings"];
        if ([doubleLocalizedValue isKindOfClass:[NSString class]]) {
            const BOOL doubleLocalized = ((NSString *)doubleLocalizedValue).boolValue;
            if (doubleLocalized) {
                stringNotFoundValue = [NSString stringWithFormat:@"%@ %@",
                                       stringNotFoundValue, stringNotFoundValue];
            }
        }
        
        id showNonLocalizedValue = arguments[@"NSShowNonLocalizedStrings"];
        if ([showNonLocalizedValue isKindOfClass:[NSString class]]) {
            const BOOL showNonLocalized = ((NSString *)showNonLocalizedValue).boolValue;
            if (showNonLocalized) {
                stringNotFoundValue = stringNotFoundValue.uppercaseString;
            }
        }
        
        id forceRightToLeftLocalizedValue = arguments[@"NSForceRightToLeftLocalizedStrings"];
        if ([forceRightToLeftLocalizedValue isKindOfClass:[NSString class]]) {
            const BOOL forceRightToLeftLocalized = ((NSString *)forceRightToLeftLocalizedValue).boolValue;
            if (forceRightToLeftLocalized) {
                stringNotFoundValue = [NSString stringWithFormat:@"\U0000202e%@\U0000202c",
                                       stringNotFoundValue];
            }
        }
        
        PT_LocalizedStringNotFoundValue = stringNotFoundValue;
    });
    
    return [string isEqualToString:PT_LocalizedStringNotFoundValue];
}

NSString *PTLocalizedString(NSString *key, NSString *comment)
{
    NSString *string = [NSBundle.mainBundle localizedStringForKey:key
                                                             value:PT_LocalizedStringNotFound
                                                             table:PT_OVERRIDDEN_STRINGS_TABLE];
    if (!PT_isStringNotFound(string)) {
        return string;
    }
    return [PTToolsUtil.toolsBundle localizedStringForKey:key value:nil table:nil];
}

NSString *PTLocalizedStringFromTable(NSString *key, NSString *table, NSString *comment)
{
    NSString *string = [NSBundle.mainBundle localizedStringForKey:key
                                                             value:PT_LocalizedStringNotFound
                                                             table:table];
    if (!PT_isStringNotFound(string)) {
        return string;
    }
    return [PTToolsUtil.toolsBundle localizedStringForKey:key value:nil table:table];
}


