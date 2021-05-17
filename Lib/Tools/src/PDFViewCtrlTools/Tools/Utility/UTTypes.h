//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * kPTUTTypeMarkdown
 *
 * Markdown file
 *
 * UTI: net.daringfireball.markdown
 * conforms to: public.plain-text
 */
PT_LOCAL const CFStringRef kPTUTTypeMarkdown;

/**
 * kPTUTTypeXPS
 *
 * XML Paper Specification file
 *
 * UTI: com.microsoft.xps
 * conforms to: public.data, public.composite-content
*/
PT_LOCAL const CFStringRef kPTUTTypeXPS;

/**
 * kPTUTTypeXOD
 *
 * XOD file
 *
 * UTI: com.pdftron.xod
 * conforms to: com.microsoft.xps
*/
PT_LOCAL const CFStringRef kPTUTTypeXOD;

/**
 * Returns the uniform type identifier (UTI) for the given URL.
 *
 * @param url the URL for which a UTI will be determined
 *
 * @return the uniform type identifier (UTI) for the given URL, or `NULL` if the UTI could not be
 * determined
 */
PT_LOCAL  NSString * _Nullable PTUTTypeForURL(NSURL *url);

/**
 * Asynchronously determines the uniform type identifier for the given URL. For HTTP(S) URLs, if the
 * UTI cannot be determined directly from the URL then the MIME type of the resource is fetched and
 * used to determine the UTI.
 *
 * @param url the URL for which a UTI will be determined
 *
 * @param resultHandler a block that will be called asynchronously with the UTI of the given URL,
 * or `NULL` if the UTI could not be determined
 */
PT_LOCAL void PTFetchUTTypeForHTTPURL(NSURL *url, NSDictionary<NSString *, NSString *> * _Nullable HTTPHeaders, void (^resultHandler)(NSString * _Nullable type));

/**
 * Returns the filename extension for the given MIME type.
 *
 * @param mimeType the MIME type whose file extension to determine
 *
 * @return the filename extension for the given MIME type, or `nil` if the extension cannot be
 * determined
 */
PT_LOCAL NSString * _Nullable PTFilenameExtensionForMIMEType(NSString * _Nullable mimeType);

/**
 * Returns whether the uniform type identifier conforms to any of the specified types.
 *
 * @param type the uniform type identifier
 *
 * @param conformsToUTIs the types to check for conformance
 *
 * @return `YES` if the uniform type identifier conforms to any of the specified types, `NO` otherwise
*/
PT_LOCAL BOOL PTUTTypeConformsToAny(CFStringRef type, NSArray<NSString *> *conformsToUTIs);

NS_ASSUME_NONNULL_END
