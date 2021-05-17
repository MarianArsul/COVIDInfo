//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTEditToolbar.h"

#import "PTCreateToolBase.h"
#import "PTToolsUtil.h"

#import "UIBarButtonItem+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTEditToolbar ()

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *undoButton;
@property (nonatomic, strong) UIBarButtonItem *redoButton;
@property (nonatomic, strong) UIBarButtonItem *styleButton;

@property (nonatomic, assign, getter=isObservingToolManagerNotifications) BOOL observingToolManagerNotifications;

@property (nonatomic, readonly, weak, nullable) NSUndoManager *toolUndoManager;

@end

NS_ASSUME_NONNULL_END

@implementation PTEditToolbar

// Synthesized by UIToolbar superclass.
@dynamic delegate;

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self initWithFrame:CGRectZero];
    if (self) {
        _toolManager = toolManager;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                      target:self
                                                                      action:@selector(cancelEditing:)];
        
        _saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(commitEdits:)];
        
        UIImage* undoImage;
        UIImage* redoImage;

        if (@available(iOS 13.0, *)) {
            undoImage = [UIImage systemImageNamed:@"arrow.uturn.left.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleUnspecified]];
            redoImage = [UIImage systemImageNamed:@"arrow.uturn.right.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleUnspecified]];
        }
        else {
            undoImage = [PTToolsUtil toolImageNamed:@"ic_undo_black_24dp"];
            redoImage = [PTToolsUtil toolImageNamed:@"ic_redo_black_24dp"];
        }
        
        _undoButton = [[UIBarButtonItem alloc] initWithImage:undoImage
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(undoEdit:)];
        
        _redoButton = [[UIBarButtonItem alloc] initWithImage:redoImage
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(redoEdit:)];
        
        _styleButton = [[UIBarButtonItem alloc] initWithImage:[PTToolsUtil toolImageNamed:@"Annotation/Ink/Icon"]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(toggleStylePicker:)];
        _undoButton.enabled = NO;
        _redoButton.enabled = NO;
        
        _styleButtonHidden = NO;

        [self updateItems];
    }
    return self;
}

- (void)updateItems
{
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    
    [items addObject:self.cancelButton];
    
    UIBarButtonItem* fixedSpaceToSaveButton = [UIBarButtonItem pt_fixedSpaceItemWithWidth:30];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        fixedSpaceToSaveButton.width = 15;
    } else {
        fixedSpaceToSaveButton.width = 30;
    }
    
    if (!self.styleButtonHidden) {
        [items addObjectsFromArray:@[
            fixedSpaceToSaveButton,
            _styleButton
        ]];
    }
    
    [items addObjectsFromArray: @[
        [UIBarButtonItem pt_flexibleSpaceItem],
    ]];
    
    if (!self.undoRedoHidden) {
        
        UIBarButtonItem* fixedSpaceBetweenUndoRedo = [UIBarButtonItem pt_fixedSpaceItemWithWidth:15];

        [items addObjectsFromArray:@[
            _undoButton,
            fixedSpaceBetweenUndoRedo,
            _redoButton,
            fixedSpaceToSaveButton,
        ]];
    }
    
    [items addObject:self.saveButton];
    
    if ([self.toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)self.toolManager.tool;
        if ([createTool isUndoManagerEnabled]) {
            self.undoButton.enabled = [createTool.undoManager canUndo];
            self.redoButton.enabled = [createTool.undoManager canRedo];
        }
    }
    
    self.items = items;
}

#pragma mark - UIView

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        [self beginObservingNotificationsForToolManager:self.toolManager];
        self.observingToolManagerNotifications = YES;
        
        [self updateItems];
    } else {
        [self endObservingNotificationsForToolManager:self.toolManager];
        self.observingToolManagerNotifications = NO;
    }
}

#pragma mark - Tool manager

- (void)setToolManager:(PTToolManager *)toolManager
{
    PTToolManager *previousToolManager = _toolManager;

    _toolManager = toolManager;
    
    if ([self isObservingToolManagerNotifications]) {
        [self endObservingNotificationsForToolManager:previousToolManager];
        [self beginObservingNotificationsForToolManager:toolManager];
    }
    
    [self updateItems];
}

- (void)beginObservingNotificationsForToolManager:(PTToolManager *)toolManager
{
    if (!toolManager) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerToolWillChangeWithNotification:)
                                               name:PTToolManagerToolWillChangeNotification
                                             object:toolManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(toolManagerToolDidChangeWithNotification:)
                                               name:PTToolManagerToolDidChangeNotification
                                             object:toolManager];
    
    if ([toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)toolManager.tool;
        if ([createTool isUndoManagerEnabled]) {
            [self beginObservingNotificationsForUndoManager:createTool.undoManager];
        }
    }
}

- (void)endObservingNotificationsForToolManager:(PTToolManager *)toolManager
{
    if (!toolManager) {
        return;
    }

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTToolManagerToolWillChangeNotification
                                                object:toolManager];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTToolManagerToolDidChangeNotification
                                                object:toolManager];
    
    if ([toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)toolManager.tool;
        if ([createTool isUndoManagerEnabled]) {
            [self endObservingNotificationsForUndoManager:createTool.undoManager];
        }
    }
}

#pragma mark Notifications

- (void)toolManagerToolWillChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }

    PTTool *previousTool = self.toolManager.tool;
    if ([previousTool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)previousTool;
        
        if ([createTool isUndoManagerEnabled]) {
            [self endObservingNotificationsForUndoManager:createTool.undoManager];
        }
    }
}

- (void)toolManagerToolDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    PTTool *tool = self.toolManager.tool;
    if ([tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)tool;
        
        if ([createTool isUndoManagerEnabled]) {
            [self beginObservingNotificationsForUndoManager:createTool.undoManager];
        }
    }
    
    [self updateItems];
}

#pragma mark - Undo manager

- (NSUndoManager *)toolUndoManager
{
    if ([self.toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)self.toolManager.tool;
        if ([createTool isUndoManagerEnabled]) {
            return createTool.undoManager;
        }
    }
    return nil;
}

- (void)beginObservingNotificationsForUndoManager:(NSUndoManager *)undoManager
{
    if (!undoManager) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                                               name:NSUndoManagerDidCloseUndoGroupNotification
                                             object:undoManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                                               name:NSUndoManagerDidUndoChangeNotification
                                             object:undoManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(undoManagerStateDidChangeWithNotification:)
                                               name:NSUndoManagerDidRedoChangeNotification
                                             object:undoManager];
}

- (void)endObservingNotificationsForUndoManager:(NSUndoManager *)undoManager
{
    if (!undoManager) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSUndoManagerDidCloseUndoGroupNotification
                                                object:undoManager];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSUndoManagerDidUndoChangeNotification
                                                object:undoManager];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSUndoManagerDidRedoChangeNotification
                                                object:undoManager];
}

- (void)undoManagerStateDidChangeWithNotification:(NSNotification *)notification
{
    NSUndoManager *undoManager = notification.object;
    if (undoManager != self.toolUndoManager) {
        return;
    }
    
    self.undoButton.enabled = [undoManager canUndo];
    self.redoButton.enabled = [undoManager canRedo];
}

#pragma mark - Button actions

- (void)cancelEditing:(UIBarButtonItem *)button
{
    if ([self.delegate respondsToSelector:@selector(editToolbarDidCancel:)]) {
        [self.delegate editToolbarDidCancel:self];
    }
}

- (void)commitEdits:(UIBarButtonItem *)button
{
    if ([self.delegate respondsToSelector:@selector(editToolbarDidCommit:)]) {
        [self.delegate editToolbarDidCommit:self];
    }
}

- (void)undoEdit:(UIBarButtonItem *)button
{
    if ([self.delegate respondsToSelector:@selector(editToolbarUndoChange:)]) {
        [self.delegate editToolbarUndoChange:self];
    }
    
    [self.toolUndoManager undo];
}

- (void)redoEdit:(UIBarButtonItem *)button
{
    if ([self.delegate respondsToSelector:@selector(editToolbarRedoChange:)]) {
        [self.delegate editToolbarRedoChange:self];
    }
    
    [self.toolUndoManager redo];
}

- (void)toggleStylePicker:(UIBarButtonItem *)button
{
    if ([self.delegate respondsToSelector:@selector(editToolbarToggleStylePicker:)]) {
        [self.delegate editToolbarToggleStylePicker:button];
    }
}

- (void)setUndoRedoHidden:(BOOL)hidden
{
    _undoRedoHidden = hidden;
    
    [self updateItems];
}

- (void)setStyleButtonHidden:(BOOL)hidden
{
    _styleButtonHidden = hidden;

    [self updateItems];
}

#pragma mark - Undo/redo enabled

- (void)setUndoEnabled:(BOOL)enabled
{
    self.undoButton.enabled = enabled;
}

- (BOOL)isUndoEnabled
{
    return [self.undoButton isEnabled];
}

- (void)setRedoEnabled:(BOOL)enabled
{
    self.redoButton.enabled = enabled;
}

- (BOOL)isRedoEnabled
{
    return [self.redoButton isEnabled];
}

@end
