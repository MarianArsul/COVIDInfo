//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "UTTypes.h"

#import "NSURL+PTAdditions.h"

#import <MobileCoreServices/MobileCoreServices.h>

const CFStringRef kPTUTTypeMarkdown = CFSTR("net.daringfireball.markdown");

const CFStringRef kPTUTTypeXPS = CFSTR("com.microsoft.xps");

const CFStringRef kPTUTTypeXOD = CFSTR("com.pdftron.xod");

static void PT_DispatchUTTypeResult(NSString * _Nullable type, void (^resultHandler)(NSString * _Nullable type))
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (resultHandler) {
            resultHandler(type);
        }
    });
}

NSString *PTUTTypeForURL(NSURL *url)
{
    if ([url isFileURL]) {
        // Get UTI directly from file URL.
        NSString *type = nil;

        NSError *error = nil;
        [url getResourceValue:&type forKey:NSURLTypeIdentifierKey error:&error];
        if (error) {
            PTLog(@"Failed to determine UTI for resource at URL \"%@\": %@", url, error);
        }

        return type;
    }

    // Try to get UTI from non-file URL's path extension.
    NSString *pathExtension = url.pathExtension;
    if (pathExtension.length == 0) {
        // No path extension.
        return nil;
    }
    
    CFStringRef typeRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                (__bridge CFStringRef)pathExtension,
                                                                NULL /* No conformance requirements. */);
    
    return (__bridge_transfer NSString *)typeRef;
}

void PTFetchUTTypeForHTTPURL(NSURL *url, NSDictionary<NSString *, NSString *> * _Nullable HTTPHeaders, void (^resultHandler)(NSString *type))
{
    // Try the synchronous approach first.
    NSString *type = PTUTTypeForURL(url);
    if (type) {
        if (resultHandler) {
            resultHandler(type);
        }
        return;
    }
    
    if (!([url pt_isHTTPURL] || [url pt_isHTTPSURL])) {
        // Unsupported URL scheme.
        if (resultHandler) {
            resultHandler(nil);
        }
        return;
    }
    
    // Fetch http(s) header fields to determine the UTI.
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    mutableRequest.HTTPMethod = @"HEAD";
    
    if (HTTPHeaders) {
        // Apply additional HTTP headers.
        for (NSString *header in HTTPHeaders) {
            NSString *value = HTTPHeaders[header];
            
            [mutableRequest addValue:value forHTTPHeaderField:header];
        }
    }
    
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:[mutableRequest copy] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Check for error.
        if (error) {
            PT_DispatchUTTypeResult(nil, resultHandler);
            return;
        }
        
        // Get the response MIME type (or Content-Type).
        NSString *mimeType = response.MIMEType;
        if (!mimeType && [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            // Get response "Content-Type" header field.
            id contentType = httpResponse.allHeaderFields[@"Content-Type"];
            if ([contentType isKindOfClass:[NSString class]]) {
                mimeType = (NSString *)contentType;
            }
        }
        if (!mimeType) {
            PTLog(@"Failed to determine MIME type of resource at URL \"%@\"", url);
            PT_DispatchUTTypeResult(nil, resultHandler);
            return;
        }
        
        PTLog(@"Retrieved MIME type \"%@\" for resource at URL \"%@\"", mimeType, url);
        
        // Get the UTI for the given MIME type.
        CFStringRef typeRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
                                                                    (__bridge CFStringRef)mimeType,
                                                                    NULL /* No conformance requirements. */);
        NSString *type = (__bridge_transfer NSString *)typeRef;
        if (!type) {
            PTLog(@"Failed to determine UTI for MIME type \"%@\" for resource at URL \"%@\"",
                  mimeType, url);
        }
        
        PT_DispatchUTTypeResult(type, resultHandler);
    }];
    // Start task.
    [task resume];
}

NSString *PTFilenameExtensionForMIMEType(NSString *mimeType)
{
    if (!mimeType) {
        return nil;
    }
    
    // Get the UTI for the given MIME type.
    CFStringRef typeRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
                                                                (__bridge CFStringRef)mimeType,
                                                                NULL /* No conformance requirements. */);
    NSString *type = (__bridge_transfer NSString *)typeRef;
    if (!type) {
        PTLog(@"Failed to determine UTI for MIME type \"%@\"", mimeType);
        return nil;
    }

    // Get the filename extension for the UTI.
    CFStringRef extension = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)type,
                                                            kUTTagClassFilenameExtension);
    if (!extension) {
        PTLog(@"Failed to determine filename extension for UTI \"%@\" and MIME type \"%@\"",
              type, mimeType);
        return nil;
    }
    
    return (__bridge_transfer NSString *)extension;
}

BOOL PTUTTypeConformsToAny(CFStringRef type, NSArray<NSString *> *conformsToUTIs)
{
    if (!type) {
        return NO;
    }
    
    for (NSString *conformsToUTI in conformsToUTIs) {
        if (UTTypeConformsTo(type, (__bridge CFStringRef)conformsToUTI)) {
            return YES;
        }
    }
    
    return NO;
}
