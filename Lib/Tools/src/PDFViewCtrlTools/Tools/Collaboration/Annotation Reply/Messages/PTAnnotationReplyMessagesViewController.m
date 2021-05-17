//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationReplyMessagesViewController.h"

#import "PTBaseCollaborationManager+Private.h"

#import "PTCollaborationAnnotationDataSource.h"
#import "PTAnnotationReplyHeaderView.h"
#import "PTAnnotationReplyTableViewCell.h"
#import "PTToolsUtil.h"

#import "NSArray+PTAdditions.h"

@interface PTAnnotationReplyMessagesViewController () <PTCollaborationAnnotationDataSourceDelegate>

@property (nonatomic, strong) PTCollaborationAnnotationDataSource *dataSource;

@property (nonatomic, strong) PTAnnotationReplyHeaderView *headerView;

@end

@implementation PTAnnotationReplyMessagesViewController

- (instancetype)initWithCollaborationManager:(PTBaseCollaborationManager *)collaborationManager
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _collaborationManager = collaborationManager;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = [[PTCollaborationAnnotationDataSource alloc] initWithTableView:self.tableView];
    self.dataSource.annotationManager = self.collaborationManager.annotationManager;
    self.dataSource.delegate = self;
    
    // Register cell and header classes.
    [self.tableView registerClass:[PTAnnotationReplyTableViewCell class] forCellReuseIdentifier:@"cell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.dataSource.cellReuseIdentifier = @"cell";
    
    self.headerView = [[PTAnnotationReplyHeaderView alloc] initWithReuseIdentifier:@"header"];
    self.headerView.frame = CGRectMake(0, 0, 100, 44.0);
    
    // Remove extra row separators at bottom of table view.
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.dataSource.paused = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self deregisterForKeyboardNotifications];
    
    self.dataSource.paused = YES;
}

#pragma mark - Header

- (BOOL)shouldShowHeaderForAnnotationType:(PTExtendedAnnotType)type
{
    // Show header for text markup and freetext annotations.
    switch (type) {
        case PTExtendedAnnotTypeHighlight:
        case PTExtendedAnnotTypeUnderline:
        case PTExtendedAnnotTypeSquiggly:
        case PTExtendedAnnotTypeStrikeOut:
        case PTExtendedAnnotTypeFreeText:
        case PTExtendedAnnotTypeCallout:
            return YES;
        default:
            return NO;
    }
}

- (void)reloadHeader
{
    if ([self shouldShowHeaderForAnnotationType:(PTExtendedAnnotType)self.annotation.type]) {
        self.tableView.tableHeaderView = self.headerView;
        
        [self.headerView configureWithAnnotation:self.annotation];
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)setAnnotation:(PTManagedAnnotation *)annotation
{
    if (_annotation == annotation) {
        // No change.
        return;
    }
    
    PTManagedAnnotation *oldAnnotation = _annotation;
    
    _annotation = annotation;
    
    if (![oldAnnotation isEqual:annotation]) {
        // Reload data source and table view.
        self.dataSource.annotation = annotation;
        [self.tableView reloadData];
    }
    
    // Reload the table header view.
    [self reloadHeader];
}

#pragma mark - <PTAnnotationTableDataSourceDelegate>

- (void)collaborationAnnotationDataSource:(PTCollaborationAnnotationDataSource *)dataSource configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath withAnnotation:(PTManagedAnnotation *)annotation
{
    PTAnnotationReplyTableViewCell *replyCell = (PTAnnotationReplyTableViewCell *)cell;
    [replyCell configureWithAnnotation:annotation];
}

- (void)collaborationAnnotationDataSourceDidChangeContent:(PTCollaborationAnnotationDataSource *)dataSource
{
    
}

#pragma mark - <UITableViewDelegate>

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
//{
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//    
//    // "Edit" action.
//    [alertController addAction:[UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        
//    }]];
//    
//    // "Delete" action.
//    [alertController addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//        
//    }]];
//    
//    // "Cancel" action.
//    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
//    
//    [self presentViewController:alertController animated:YES completion:nil];
//}

#pragma mark - Notifications

- (void)registerForKeyboardNotifications
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillShowWithNotification:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
}

- (void)deregisterForKeyboardNotifications
{
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
}

- (void)keyboardWillShowWithNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    // Check if keyboard notification is for the current app.
    BOOL isLocal = ((NSNumber *)userInfo[UIKeyboardIsLocalUserInfoKey]).boolValue;
    if (!isLocal) {
        return;
    }
    
    UIView *superview = self.tableView.superview;
    if (!superview) {
        return;
    }
    
    CGRect scrollFrame = self.tableView.frame;
    CGPoint contentOffset = self.tableView.contentOffset;
    CGSize contentSize = self.tableView.contentSize;
    
    // Get the table view content rect in the table view's superview coordinates.
    CGRect contentRect = CGRectMake(CGRectGetMinX(scrollFrame) - contentOffset.x,
                                    CGRectGetMinY(scrollFrame) - contentOffset.y,
                                    contentSize.width, contentSize.height);
    
    // Convert content rect to screen (window) coordinates.
    contentRect = [superview convertRect:contentRect toView:nil];
    
    CGRect keyboardFrameEnd = ((NSValue *)userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;
    
    CGRect intersection = CGRectIntersection(contentRect, keyboardFrameEnd);
    if (CGRectIsNull(intersection)) {
        // Table view content does not intersect with keyboard frame.
        return;
    }
    
    // Scroll up by the intersection amount.
    contentOffset.y += CGRectGetHeight(intersection);
    
    double duration = ((NSNumber *)userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
    UIViewAnimationCurve animationCurve = ((NSNumber *)userInfo[UIKeyboardAnimationCurveUserInfoKey]).integerValue;
    
    [UIView animateWithDuration:duration delay:0.0 options:(animationCurve << 16) animations:^{
        self.tableView.contentOffset = contentOffset;
    } completion:^(BOOL finished) {
        
    }];
}

@end
