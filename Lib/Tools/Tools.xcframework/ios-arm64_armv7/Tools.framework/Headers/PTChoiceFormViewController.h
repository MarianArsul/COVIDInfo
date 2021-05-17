//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTChoiceFormViewController;

/**
 * The PTChoiceFormDataSource protocol is adopted by an object that mediates a choice
 * field's choices for a ChoiceFormViewController object. The data source provides the
 * ChoiceFormViewController with the information it needs display the choices.
 */
@protocol PTChoiceFormDataSource <NSObject>
@required

/**
 * The choice field's number of choices
 */
-(NSInteger)choiceFormNumberOfChoices:(PTChoiceFormViewController*)choiceFormViewController;

/**
 * The title of a choice for a given index.
 *
 * @param num the index number of a choice
 */
-(NSString*)choiceForm:(PTChoiceFormViewController*)choiceFormViewController titleOfChoiceAtIndex:(NSUInteger)num;

/**
 * The items that are current selected.
 */
-(NSMutableArray*)choiceFromGetSelectedItemsInActiveListbox:(PTChoiceFormViewController*)choiceFormViewController;

@end

/**
 * Allows the user to interact with and set values of choice fields (list boxes).
 */
@interface PTChoiceFormViewController: UIViewController<UITableViewDelegate, UITableViewDataSource>

/**
 * The object that acts as the delegate of the ChoiceFormViewController.
 */
@property (nonatomic, weak, nullable) id<PTChoiceFormDataSource, UITableViewDelegate> delegate;

/**
 * Set to true if used on a choice field that is multi-select. The default is false.
 */
@property (nonatomic, assign) BOOL isMultiSelect;

@end

NS_ASSUME_NONNULL_END
