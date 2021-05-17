//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/AnnotTypes.h>

#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

@class PTNoteEditController;

/**
 * Describes the methods that are called when the user wishes to save or cancel their
 * changes to the annotations' note.
 */
@protocol PTNoteEditControllerDelegate <NSObject>

/**
 * Called when the user cancels any changes to the annotation's note.
 */
-(void)noteEditController:(PTNoteEditController*)noteEditController cancelButtonPressed:(BOOL)showSelectionMenu;

/**
 * Called when the user wishes to delete the annotation.
 */
-(void)noteEditControllerDeleteSelectedAnnotation:(PTNoteEditController*)noteEditController;

/**
 * Called when the user wishes to save the changes to the annotation's note.
 */
-(void)noteEditController:(PTNoteEditController*)noteEditController saveNewNoteForMovingAnnotationWithString:(NSString*)str;

@end

/**
 * A view controller that displays and allows editing of an annotation's popup note.
 */
@interface PTNoteEditController : UIViewController

/**
 * The UITextView that displays the contents of the note.
 */
@property (nonatomic, readonly, strong) UITextView *textView;

/**
 * The contents of the note.
 */
@property (nonatomic, copy) NSString *noteString;

/**
 * Whether the note is readonly and editing is disabled. The default value is `NO`.
 */
@property (nonatomic, assign, getter=isReadonly) BOOL readonly;

/**
 * Returns a PTNoteEditController.
 */
- (instancetype)initWithDelegate:(id<PTNoteEditControllerDelegate>)delegate annotType:(PTExtendedAnnotType)annotType NS_DESIGNATED_INITIALIZER;


-(instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;


-(instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;


-(instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
