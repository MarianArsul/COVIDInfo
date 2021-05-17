//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <PDFNet/PDFNetOBJC.h>

@protocol PTPrintDelegate;

/**
 * The `PTPrint` class handles preparing a `PTPDFDoc` for printing with a system `UIPrintInteractionController`.
 */
@interface PTPrint : NSObject<UIPrintInteractionControllerDelegate>

/**
 * 
 * An asynchronous selector that prepares a document for printing and calls the `printDelegate`'s
 * `-[PTPrintDelegate PreparedToPrint:UserData:]` when preparation is complete.
 * It may take a moment to prepare the document, so it is recommended that the user be presented
 * with information to this effect.
 *
 * @param doc A valid `PTPDFDoc` object.
 * @param printDelegate An object that conforms to the `PTPrintDelegate` protocol.
 * @param userData User data that is provided to the delegate's callback selector. (Optional)
 *
 */
-(void)PrepareDocToPrint:(PTPDFDoc*)doc Delegate:(id<PTPrintDelegate>)printDelegate UserData:(id)userData;

/**
 * 
 * For iPad. A convenience method to print the PDF document located where the first parameter points.
 * Typically called from an implementation of the `-[PTPrintDelegate PreparedToPrint:UserData:]` method.
 *
 * (If called on an iPhone, then 2nd and 3rd parameters are ignored.)
 *
 * @param docFilePath Number of seconds between refreshes.
 * @param rect The rectangle from which to present the `UIPrintInteractionController`.
 * @param view The view that is the superview of the presented `UIPrintInteractionController`.
 * @param jobName The name of the print job. (Optional)
 * @param animated Whether the presented `UIPrintInteractionController` is animated.
 * @param completionHandler Function that is called when printing is complete.
 *
 */
-(void)PrintDoc:(NSString*)docFilePath FromRect:(CGRect)rect InView:(UIView*)view WithJobName:(NSString*)jobName Animated:(BOOL)animated CompletionHandler:(UIPrintInteractionCompletionHandler)completionHandler;

/**
 *
 * For iPad. A convenience method to print the PDF document located where the first parameter points.
 * Typically called from an implementation of the `-[PTPrintDelegate PreparedToPrint:UserData:]` method.
 *
 * (If called on an iPhone, then 2nd parameter is ignored.)
 *
 * @param docFilePath The file path of the PDF document that will be printed.
 * @param barButtonItem The `UIBarButtonItem` object that the user tapped for printing.
 * @param jobName The name of the print job. (Optional)
 * @param animated Whether the presented `UIPrintInteractionController` is animated.
 * @param completionHandler Function that is called when printing is complete.
 *
 */
-(void)PrintDoc:(NSString*)docFilePath FromBarButtonItem:(UIBarButtonItem*)barButtonItem WithJobName:(NSString*)jobName Animated:(BOOL)animated CompletionHandler:(UIPrintInteractionCompletionHandler)completionHandler;

/**
 *
 * For iPhone (and iPod Touch). A convenience method to print the PDF document located where the first parameter points.
 * Typically called from an implementation of the `-[PTPrintDelegate PreparedToPrint:UserData:]` method.
 *
 * @param docFilePath The file path of the PDF document that will be printed.
 * @param jobName The name of the print job. (Optional)
 * @param animated Whether the presented `UIPrintInteractionController` is animated.
 * @param completionHandler Function that is called when printing is complete.
 *
 */
-(void)PrintDoc:(NSString*)docFilePath WithJobName:(NSString*)jobName Animated:(BOOL)animated CompletionHandler:(UIPrintInteractionCompletionHandler)completionHandler;

@end

/**
 * Tells the delegate when the PDF is prepared for printing after a call to a `PTPrint` instance's `-[PTPrint PrepareDocToPrint:Delegate:UserData:]` method.
 */
@protocol PTPrintDelegate <NSObject>

@required

/**
 *
 * Selector called by `-[PTPrint PrepareDocToPrint:Delegate:UserData:]` when the document has been
 * prepared for printing.
 *
 * @param docFilePath The file path of the PDF document that will be printed.
 * @param userData User data provided in `-[PTPrint PrepareDocToPrint:Delegate:UserData:]`.
 *
 */
- (void)PreparedToPrint:(NSString*)docFilePath UserData:(id)userData;

@end
