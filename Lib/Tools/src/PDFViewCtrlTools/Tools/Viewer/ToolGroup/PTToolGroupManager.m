//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolGroupManager.h"

#import "PTAnnotationStyleManager.h"
#import "PTOverrides.h"
#import "PTSelectableBarButtonItem.h"
#import "PTTimer.h"
#import "PTToolBarButtonItem.h"
#import "PTToolsUtil.h"

#import "PTSmartPen.h"
#import "PTAnnotSelectTool.h"
#import "PTAreaCreate.h"
#import "PTArrowCreate.h"
#import "PTCloudCreate.h"
#import "PTDigitalSignatureTool.h"
#import "PTEllipseCreate.h"
#import "PTEraser.h"
#import "PTFileAttachmentCreate.h"
#import "PTFreehandCreate.h"
#import "PTFreeHandHighlightCreate.h"
#import "PTFreeTextCreate.h"
#import "PTImageStampCreate.h"
#import "PTLineCreate.h"
#import "PTPanTool.h"
#import "PTPencilDrawingCreate.h"
#import "PTPerimeterCreate.h"
#import "PTPolygonCreate.h"
#import "PTPolylineCreate.h"
#import "PTRectangleCreate.h"
#import "PTRubberStampCreate.h"
#import "PTRulerCreate.h"
#import "PTStickyNoteCreate.h"
#import "PTTextHighlightCreate.h"
#import "PTTextSquigglyCreate.h"
#import "PTTextStrikeoutCreate.h"
#import "PTTextUnderlineCreate.h"

#import "PTAutoCoding.h"
#import "PTKeyValueObserving.h"
#import "NSArray+PTAdditions.h"
#import "UIBarButtonItem+PTAdditions.h"
#import "UIButton+PTAdditions.h"

#define PT_TOOL_GROUPS_DEFAULTS_KEY @"annotationToolGroups"

#define PTToolImage(imageName) ([PTToolsUtil toolImageNamed:(imageName)])

NS_ASSUME_NONNULL_BEGIN

const NSNotificationName PTToolGroupDidChangeNotification = PT_NS_STRINGIFY(PTToolGroupDidChangeNotification);

@interface PTToolGroupManager ()

// Re-declare as readwrite internally.
@property (nonatomic, readwrite, strong, nullable) PTAnnotationStylePresetsGroup *annotStylePresets;

@property (nonatomic, strong, nullable) PTTimer *annotationStylePresetsSaveTimer;

@end

NS_ASSUME_NONNULL_END

@implementation PTToolGroupManager

- (void)PTToolGroupManager_commonInit
{
    _editingEnabled = YES;
    
    // "View" group.
    _viewItemGroup = [PTToolGroup groupWithTitle:PTLocalizedString(@"View",
                                                                       @"View mode title")
                                               image:PTToolImage(@"ToolGroup/View")
                                      barButtonItems:@[]];
    _viewItemGroup.identifier = @"view";
    _viewItemGroup.editable = NO;
    
    // "Annotate" group.
    _annotateItemGroup = [PTToolGroup groupWithTitle:PTLocalizedString(@"Annotate",
                                                                           @"Annotate mode title")
                                                   image:PTToolImage(@"ToolGroup/Annotate")
                                          barButtonItems:[self createItemsForToolClasses:@[
        [PTTextHighlightCreate class],
        [PTFreeHandHighlightCreate class],
        (^ Class {
            if (@available(iOS 13.1, *)) {
                return [PTPencilDrawingCreate class];
            } else {
                return [PTFreeHandCreate class];
            }
        }()),
        [PTFreeTextCreate class],
        [PTSmartPen class],
        [PTStickyNoteCreate class],
        [PTTextUnderlineCreate class],
        [PTTextSquigglyCreate class],
        [PTTextStrikeoutCreate class],
        [PTAnnotSelectTool class],
    ]]];
    _annotateItemGroup.identifier = @"Annotate";
    
    // "Draw" group.
    _drawItemGroup = [PTToolGroup groupWithTitle:PTLocalizedString(@"Draw",
                                                                       @"Draw mode title")
                                               image:PTToolImage(@"ToolGroup/Draw")
                                      barButtonItems:[self createItemsForToolClasses:({
        NSMutableArray<Class> *classes = [NSMutableArray array];
        
        if (@available(iOS 13.1, *)) {
            [classes addObject:[PTPencilDrawingCreate class]];
        }
        
        [classes addObjectsFromArray:@[
            [PTFreeHandCreate class],
            [PTEraser class],
            [PTRectangleCreate class],
            [PTEllipseCreate class],
            [PTPolygonCreate class],
            [PTCloudCreate class],
            [PTLineCreate class],
            [PTArrowCreate class],
            [PTPolylineCreate class],
            [PTAnnotSelectTool class],
        ]];
        ([classes copy]);
    })]];
    _drawItemGroup.identifier = @"Draw";
    
    _insertItemGroup = [PTToolGroup groupWithTitle:PTLocalizedString(@"Insert",
                                                                         @"Insert mode title")
                                                 image:PTToolImage(@"ToolGroup/Insert")
                                        barButtonItems:[self createItemsForToolClasses:@[
        [PTDigitalSignatureTool class],
        [PTImageStampCreate class],
        [PTRubberStampCreate class],
        [PTFileAttachmentCreate class],
        [PTAnnotSelectTool class],
    ]]];
    _insertItemGroup.identifier = @"Insert";
    
    _measureItemGroup = [PTToolGroup groupWithTitle:PTLocalizedString(@"Measure",
                                                                          @"Measure mode title")
                                                  image:PTToolImage(@"ToolGroup/Measure")
                                         barButtonItems:[self createItemsForToolClasses:@[
        [PTRulerCreate class],
        [PTPerimeterCreate class],
        [PTAreaCreate class],
        [PTAnnotSelectTool class],
    ]]];
    _measureItemGroup.identifier = @"Measure";
    
    _pensItemGroup = [PTToolGroup groupWithTitle:PTLocalizedString(@"Pens",
                                                                       @"Pens mode title")
                                               image:PTToolImage(@"ToolGroup/Pens")
                                      barButtonItems:[self createItemsForToolClasses:@[
        [PTFreeHandCreate class],
        [PTFreeHandCreate class],
        [PTFreeHandHighlightCreate class],
        [PTFreeHandHighlightCreate class],
        [PTAnnotSelectTool class],
    ]]];
    _pensItemGroup.identifier = @"Pens";
    
    _favoritesItemGroup = [PTToolGroup groupWithTitle:PTLocalizedString(@"Favorites",
                                                                            @"Favorites mode title")
                                                    image:PTToolImage(@"ToolGroup/Favorite")
                                           barButtonItems:@[]];
    _favoritesItemGroup.favorite = YES;
    _favoritesItemGroup.identifier = @"Favorites";
    
    _groups = @[
        _viewItemGroup,
        _annotateItemGroup,
        _drawItemGroup,
        _insertItemGroup,
        _measureItemGroup,
        _pensItemGroup,
        _favoritesItemGroup,
    ];
    
    // Select the Annotate group by default.
    NSAssert([_groups containsObject:_annotateItemGroup],
             @"Initial selectedGroup could not be set");	
    _selectedGroup = _annotateItemGroup;
    
    [self restoreGroups];
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self init];
    if (self) {
        _toolManager = toolManager;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self PTToolGroupManager_commonInit];
    }
    return self;
}

- (void)dealloc
{
    [_annotationStylePresetsSaveTimer invalidate];
    
    [self pt_removeAllObservations];
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        [PTAutoCoding autoUnarchiveObject:self
                                  ofClass:[PTToolGroupManager class]
                                withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [PTAutoCoding autoArchiveObject:self
                            ofClass:[PTToolGroupManager class]
                            forKeys:nil
                          withCoder:coder];
}

#pragma mark - Tool manager

- (void)setToolManager:(PTToolManager *)toolManager
{
    PTToolManager *previousToolManager = _toolManager;
    _toolManager = toolManager;
    
    if ([self isEnabled]) {
        [self endObservingToolManager:previousToolManager];
        [self beginObservingToolManager:toolManager];
    }
    
    [self updateItems];
}

- (void)beginObservingToolManager:(PTToolManager *)toolManager
{
    if (!toolManager) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(toolManagerToolWillChange:)
                   name:PTToolManagerToolWillChangeNotification
                 object:toolManager];
    [center addObserver:self
               selector:@selector(toolManagerToolDidChange:)
                   name:PTToolManagerToolDidChangeNotification
                 object:toolManager];
    
    [self beginObservingUndoManager:toolManager.undoManager];
    
    if ([toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)toolManager.tool;
        if ([createTool isUndoManagerEnabled]) {
            [self beginObservingUndoManager:createTool.undoManager];
        }
    } else if ([toolManager.tool isKindOfClass:[PTFreeTextCreate class]]) {
        [self beginObservingUndoManager:toolManager.tool.undoManager];
    }
}

- (void)endObservingToolManager:(PTToolManager *)toolManager
{
    if (!toolManager) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center removeObserver:self
                      name:PTToolManagerToolWillChangeNotification
                    object:toolManager];
    [center removeObserver:self
                      name:PTToolManagerToolDidChangeNotification
                    object:toolManager];
    
    [self endObservingUndoManager:toolManager.undoManager];
    
    if ([toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)toolManager.tool;
        if ([createTool isUndoManagerEnabled]) {
            [self endObservingUndoManager:createTool.undoManager];
        }
    } else if ([toolManager.tool isKindOfClass:[PTFreeTextCreate class]]) {
        [self endObservingUndoManager:toolManager.tool.undoManager];
    }
}

- (void)toolManagerToolWillChange:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self saveAnnotationStylePresets];
    
    PTTool *previousTool = self.toolManager.tool;
    if ([previousTool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)previousTool;
        if ([createTool isUndoManagerEnabled]) {
            [self endObservingUndoManager:createTool.undoManager];
        }
    } else if ([previousTool isKindOfClass:[PTFreeTextCreate class]]) {
        [self endObservingUndoManager:previousTool.undoManager];
    }
}

- (void)toolManagerToolDidChange:(NSNotification *)notification
{
    if (notification.object != self.toolManager) {
        return;
    }
    
    [self updateAnnotationStylePresets];
    
    PTTool *tool = self.toolManager.tool;
    if ([tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)tool;
        if ([createTool isUndoManagerEnabled]) {
            [self beginObservingUndoManager:createTool.undoManager];
        }
    } else if ([tool isKindOfClass:[PTFreeTextCreate class]]) {
        [self beginObservingUndoManager:tool.undoManager];
    }
    
    [self updateItems];
}

#pragma mark - Undo manager

- (NSUndoManager *)undoManager
{
    if ([self.toolManager.tool isKindOfClass:[PTCreateToolBase class]]) {
        PTCreateToolBase *createTool = (PTCreateToolBase *)self.toolManager.tool;
        if ([createTool isUndoManagerEnabled]) {
            return createTool.undoManager;
        }
    } else if ([self.toolManager.tool isKindOfClass:[PTFreeTextCreate class]]) {
        return self.toolManager.tool.undoManager;
    }
    return self.toolManager.undoManager;
}

- (void)beginObservingUndoManager:(NSUndoManager *)undoManager
{
    if (!undoManager) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(undoManagerStateDidChange:)
                   name:NSUndoManagerDidCloseUndoGroupNotification
                 object:undoManager];
    [center addObserver:self
               selector:@selector(undoManagerStateDidChange:)
                   name:NSUndoManagerDidUndoChangeNotification
                 object:undoManager];
    [center addObserver:self
               selector:@selector(undoManagerStateDidChange:)
                   name:NSUndoManagerDidRedoChangeNotification
                 object:undoManager];
    
    [self updateUndoRedoItems];
}

- (void)endObservingUndoManager:(NSUndoManager *)undoManager
{
    if (!undoManager) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center removeObserver:self
                      name:NSUndoManagerDidCloseUndoGroupNotification
                    object:undoManager];
    [center removeObserver:self
                      name:NSUndoManagerDidUndoChangeNotification
                    object:undoManager];
    [center removeObserver:self
                      name:NSUndoManagerDidRedoChangeNotification
                    object:undoManager];
}

- (void)undoManagerStateDidChange:(NSNotification *)notification
{
    NSUndoManager *undoManager = notification.object;
    if (undoManager != self.undoManager) {
        return;
    }
    
    [self updateUndoRedoItems];
}

#pragma mark - Enabled

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled == enabled) {
        // No change.
        return;
    }
    
    _enabled = enabled;
    
    if (enabled) {
        [self beginObservingToolManager:self.toolManager];
        [self beginObservingAnnotationStylePresets:self.annotStylePresets];
    } else {
        [self endObservingToolManager:self.toolManager];
        [self endObservingAnnotationStylePresets:self.annotStylePresets];
    }
}

#pragma mark - Groups

- (void)setGroups:(NSArray<PTToolGroup *> *)groups
{
    PTToolGroup *previousSelectedGroup = self.selectedGroup;
    const NSUInteger previousSelectedGroupIndex = self.selectedGroupIndex;
        
    _groups = [groups copy]; // @property (copy) semantics.
        
    if (groups) {
        // Attempt to re-select the previous selected group.
        const NSUInteger newSelectedGroupIndex = [groups indexOfObject:previousSelectedGroup];
        if (newSelectedGroupIndex != NSNotFound) {
            // Previous selected group is in the new array.
            NSAssert(({
                NSSet<NSString *> *keyPaths = [[self class] keyPathsForValuesAffectingSelectedGroupIndex];
                ([keyPaths containsObject:PT_SELF_KEY(groups)]);
            }), @"groups must trigger change notifications for selectedGroupIndex");
            // Change notifications for selectedGroupIndex will be triggered automatically.
        } else if (previousSelectedGroupIndex < groups.count) {
            // Select the group at the same index in the array as the previous selected group.
            _selectedGroup = groups[previousSelectedGroupIndex];
        } else if (groups.count > 0) {
            // Select the group at index 0.
            _selectedGroup = groups[0];
        } else {
            // There is no selected group.
            _selectedGroup = nil;
        }
    } else {
        // There is no selected group.
        _selectedGroup = nil;
    }
}

#pragma mark Selected group index

- (NSUInteger)selectedGroupIndex
{
    if (!self.selectedGroup) {
        return NSNotFound;
    }
    return [self.groups indexOfObject:self.selectedGroup];
}

- (void)setSelectedGroupIndex:(NSUInteger)selectedGroupIndex
{
    self.selectedGroup = self.groups[selectedGroupIndex];
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedGroupIndex
{
    // Setting selectedGroup will trigger change notifications for selectedGroupIndex
    // because it is listed as "affecting" selectedGroupIndex.
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedGroupIndex
{
    // Changes to the following properties should trigger change notifications
    // for the selectedGroupIndex property.
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTToolGroupManager, selectedGroup),
        PT_CLASS_KEY(PTToolGroupManager, groups),
    ]];
}

#pragma mark - Selected group

- (void)setSelectedGroup:(PTToolGroup *)selectedGroup
{
    if (!selectedGroup) {
        // A nil selected group is only allowed with a group count of 0.
        if (self.groups.count != 0) {
            NSString *reason = [NSString stringWithFormat:@"selected group cannot be nil with a group count of %lu",
                                (unsigned long)self.groups.count];
            
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                             reason:reason
                                                           userInfo:nil];
            @throw exception;
            return;
        }
    }
    // Ensure selected group is in groups.
    else if (![self.groups containsObject:selectedGroup]) {
        NSString *reason = [NSString stringWithFormat:@"selected group %@ is not in the list of groups",
                            selectedGroup];
        
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:reason
                                                       userInfo:nil];
        @throw exception;
        return;
    }
    
    PTToolGroup *previousSelectedGroup = _selectedGroup;
    if (selectedGroup == previousSelectedGroup) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_SELF_KEY(selectedGroup)];
    
    _selectedGroup = selectedGroup;
    
    [self updateItems];
    
    [self didChangeValueForKey:PT_SELF_KEY(selectedGroup)];
    
    [self postSelectedGroupDidChangeNotification];
}

- (void)postSelectedGroupDidChangeNotification
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center postNotificationName:PTToolGroupDidChangeNotification
                          object:self
                        userInfo:nil];
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedGroup
{
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedGroup
{
    // Changes to the following properties should trigger change notifications
    // for the selectedGroup property.
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTToolGroupManager, groups),
    ]];
}

#pragma mark - Items

- (void)updateItems
{
    [self updateToolItems];
    [self updateUndoRedoItems];
}

- (void)updateToolItems
{
    PTTool *tool = self.toolManager.tool;
    
    // Don't update button states with a non-creation tool (other than the pan tool).
    if (![tool isKindOfClass:[PTPanTool class]] && !tool.createsAnnotation) {
        // When in continuous annotation mode, don't update the button states.
        // The next tool should be a creation tool.
        // This prevents the selected tool from being deselected when a newly
        // created annotation is selected (PTAnnotEditTool).
        if (!tool.backToPanToolAfterUse && [tool.defaultClass createsAnnotation]) {
            return;
        }
    }
    
    for (PTToolGroup *group in self.groups) {
        for (UIBarButtonItem *item in group.barButtonItems) {
            if ([item isKindOfClass:[PTToolBarButtonItem class]]) {
                PTToolBarButtonItem *toolItem = (PTToolBarButtonItem *)item;
                
                [self selectToolItem:toolItem forTool:tool];
            }
        }
    }    
}

- (void)selectToolItem:(PTToolBarButtonItem *)toolItem forTool:(PTTool *)tool
{
    if ([toolItem.toolClass isEqual:[tool class]] &&
        (tool.identifier && [toolItem.identifier isEqual:tool.identifier])) {
        toolItem.selected = YES;
    } else {
        toolItem.selected = NO;
    }
}

#pragma mark - Item creation

- (NSArray<UIBarButtonItem *> *)createItemsForToolClasses:(NSArray<Class> *)toolClasses
{
    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    
    for (Class toolClass in toolClasses) {
        UIBarButtonItem *item = [self createItemForToolClass:toolClass];
        [items addObject:item];
    }
    
    return [items copy];
}

- (UIBarButtonItem *)createItemForToolClass:(Class)toolClass
{
    // Use the overridden class if available.
    toolClass = [PTOverrides overriddenClassForClass:toolClass] ?: toolClass;
    
    PTToolBarButtonItem *item = [[PTToolBarButtonItem alloc] initWithToolClass:toolClass
                                                                        target:self
                                                                        action:@selector(itemTriggered:)];
    // Give the item a unique identifier string to differentiate it from other tool items
    // with the same tool class.
    item.identifier = [NSUUID UUID].UUIDString;
    
    return item;
}

- (void)itemTriggered:(UIBarButtonItem *)item
{
    if ([item isKindOfClass:[PTSelectableBarButtonItem class]]) {
        PTSelectableBarButtonItem *selectableItem = (PTSelectableBarButtonItem *)item;
        const BOOL isSelected = [selectableItem isSelected];
        
        if (!isSelected && [item isKindOfClass:[PTToolBarButtonItem class]]) {
            // Find the item's containing group.
            PTToolGroup *selectedItemGroup = nil;
            for (PTToolGroup *group in self.groups) {
                if ([group.barButtonItems containsObject:selectableItem]) {
                    selectedItemGroup = group;
                    break;
                }
            }
            // Deselect all other items in the group.
            for (UIBarButtonItem *otherItem in selectedItemGroup.barButtonItems) {
                if (otherItem == selectableItem) {
                    continue;
                }
                if ([otherItem isKindOfClass:[PTToolBarButtonItem class]]) {
                    ((PTToolBarButtonItem *)otherItem).selected = NO;
                }
            }
        }
        selectableItem.selected = !isSelected;
        
        if ([selectableItem isSelected]) {
            if ([selectableItem isKindOfClass:[PTToolBarButtonItem class]]) {
                PTToolBarButtonItem *toolItem = (PTToolBarButtonItem *)selectableItem;
                
                
                PTTool *previousTool = self.toolManager.tool;
                if ([previousTool respondsToSelector:@selector(commitAnnotation)]) {
                    [previousTool performSelector:@selector(commitAnnotation)];
                }
                
                PTTool *tool = [[toolItem.toolClass alloc] initWithPDFViewCtrl:self.toolManager.pdfViewCtrl];
                tool.identifier = toolItem.identifier;
                tool.backToPanToolAfterUse = NO;
                
                if ([tool isKindOfClass:[PTFreeHandCreate class]] && ![tool isKindOfClass:[PTFreeHandHighlightCreate class]]) {
                    ((PTFreeHandCreate *)tool).multistrokeMode = YES;
                }
                
                if (@available(iOS 13.1, *)) {
                    if ([tool isKindOfClass:[PTPencilDrawingCreate class]]) {
                        ((PTPencilDrawingCreate *)tool).shouldShowToolPicker = YES;
                    }
                }
                
                self.toolManager.tool = tool;
            }
        } else {
            if ([selectableItem isKindOfClass:[PTToolBarButtonItem class]]) {
                
                
                PTTool *previousTool = self.toolManager.tool;
                if ([previousTool respondsToSelector:@selector(commitAnnotation)]) {
                    [previousTool performSelector:@selector(commitAnnotation)];
                }
                
                [self.toolManager changeTool:[PTPanTool class]];
            }
        }
    }
}

#pragma mark - Undo/redo

@synthesize undoButtonItem = _undoButtonItem;

- (UIBarButtonItem *)undoButtonItem
{
    if (!_undoButtonItem) {
        UIImage *image = [PTToolsUtil toolImageNamed:@"ic_undo_black_24dp"];
        
        _undoButtonItem = [[PTSelectableBarButtonItem alloc] initWithImage:image
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(undo:)];
        _undoButtonItem.title = PTLocalizedString(@"Undo",
                                                  @"Undo button title");
    }
    return _undoButtonItem;
}

@synthesize redoButtonItem = _redoButtonItem;

- (UIBarButtonItem *)redoButtonItem
{
    if (!_redoButtonItem) {
        UIImage *image = [PTToolsUtil toolImageNamed:@"ic_redo_black_24dp"];
        
        _redoButtonItem = [[PTSelectableBarButtonItem alloc] initWithImage:image
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(redo:)];
        _redoButtonItem.title = PTLocalizedString(@"Redo",
                                                  @"Redo button title");
    }
    return _redoButtonItem;
}

- (void)undo:(id)sender
{
    [self.undoManager undo];
}

- (void)redo:(id)sender
{
    [self.undoManager redo];
}

- (void)updateUndoRedoItems
{
    self.undoButtonItem.enabled = self.undoManager.canUndo;
    self.redoButtonItem.enabled = self.undoManager.canRedo;
}

#pragma mark - Favorites

@synthesize addFavoriteToolButtonItem = _addFavoriteToolButtonItem;

- (UIBarButtonItem *)addFavoriteToolButtonItem
{
    if (!_addFavoriteToolButtonItem) {
        _addFavoriteToolButtonItem = ({
            NSString *title = PTLocalizedString(@"Add Tool",
                                                @"Add Tool button title");
            
            UIButton *button = nil;
            if (@available(iOS 13.0, *)) {
                button = [UIButton buttonWithType:UIButtonTypeSystem];
                
                UIImage *image = [UIImage systemImageNamed:@"plusminus.circle"];
                [button setImage:image forState:UIControlStateNormal];
            } else {
                button = [UIButton buttonWithType:UIButtonTypeContactAdd];
            }
            [button setTitle:title forState:UIControlStateNormal];
            
            [button pt_setInsetsForContentPadding:UIEdgeInsetsZero
                                imageTitleSpacing:5];
            
            [button addTarget:self
                       action:@selector(addFavoriteTool:)
             forControlEvents:UIControlEventPrimaryActionTriggered];
            
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
            
            item.title = [button titleForState:UIControlStateNormal];
            item.image = [button imageForState:UIControlStateNormal];
            
            (item);
        });
    }
    return _addFavoriteToolButtonItem;
}

- (void)addFavoriteTool:(id)sender
{
    
    if ([self.delegate respondsToSelector:@selector(toolGroupManager:
                                                    editItemsForGroup:)]) {
        [self.delegate toolGroupManager:self
                           editItemsForGroup:self.favoritesItemGroup];
    }
}

#pragma mark - Edit group

@synthesize editGroupButtonItem = _editGroupButtonItem;

- (UIBarButtonItem *)editGroupButtonItem
{
    if (!_editGroupButtonItem) {
        _editGroupButtonItem = ({
            UIImage *image = nil;
            if (@available(iOS 13.0, *)) {
                UIImageConfiguration *configuration = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightMedium];
                image = [UIImage systemImageNamed:@"slider.horizontal.3"
                                withConfiguration:configuration];
            } else {
                image = [PTToolsUtil toolImageNamed:@"ic_settings_white_24dp"];
            }
            
            UIBarButtonItem *item = [[PTSelectableBarButtonItem alloc] initWithImage:image
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(editSelectedGroup:)];
            item.title = PTLocalizedString(@"Edit Items",
                                           @"Edit Items button title");
            
            (item);
        });
    }
    return _editGroupButtonItem;
}

- (void)editSelectedGroup:(id)sender
{
    if (!self.selectedGroup) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(toolGroupManager:
                                                    editItemsForGroup:)]) {
        [self.delegate toolGroupManager:self
                           editItemsForGroup:self.selectedGroup];
    }
}

#pragma mark - Annotation style presets

- (void)updateAnnotationStylePresets
{
    PTTool *tool = self.toolManager.tool;
    
    if (![tool isKindOfClass:[PTPanTool class]] && !tool.createsAnnotation) {
        return;
    }
    
    const PTExtendedAnnotType annotType = tool.annotType;
    if (annotType == PTExtendedAnnotTypeUnknown) {
        return;
    }
    
    NSString *identifier = tool.identifier;
    
    PTAnnotationStyleManager *manager = PTAnnotationStyleManager.defaultManager;
    self.annotStylePresets = [manager stylePresetsForAnnotationType:annotType
                                                         identifier:identifier];
    
    [self.annotStylePresets.selectedStyle setCurrentValuesAsDefaults];
}

- (void)saveAnnotationStylePresets
{
    if (!self.annotStylePresets) {
        return;
    }
    
    PTTool *tool = self.toolManager.tool;
    
    const PTExtendedAnnotType annotType = tool.annotType;
    if (annotType != PTExtendedAnnotTypeUnknown) {
        PTAnnotationStyleManager *manager = PTAnnotationStyleManager.defaultManager;
        [manager setStylePresets:self.annotStylePresets
               forAnnotationType:annotType];
        
        [self PT_startAnnotationStylePresetsSaveTimer];
    }
}

- (void)PT_startAnnotationStylePresetsSaveTimer
{
    if (self.annotationStylePresetsSaveTimer) {
        return;
    }
    
    // Save the annotation style presets after a short delay.
    // The timer will wait for the run loop to become idle (no user interaction, scroll, etc. occurring)
    // before firing.
    // This prevents the presets from being saved too often when requested quickly.
    self.annotationStylePresetsSaveTimer = [PTTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(PT_saveAnnotationStylePresets:) userInfo:nil repeats:NO];
}

- (void)PT_saveAnnotationStylePresets:(NSTimer *)timer
{
    if (timer != self.annotationStylePresetsSaveTimer.timer) {
        return;
    }
    
    PTAnnotationStyleManager *manager = PTAnnotationStyleManager.defaultManager;
    [manager saveStylePresets];
    
    self.annotationStylePresetsSaveTimer = nil;
}

- (void)PT_stopAnnotaitonStylePresetsSaveTimer
{
    [self.annotationStylePresetsSaveTimer invalidate];
    self.annotationStylePresetsSaveTimer = nil;
}

- (void)setAnnotStylePresets:(PTAnnotationStylePresetsGroup *)annotStylePresets
{
    if (annotStylePresets == _annotStylePresets) {
        return;
    }
    
    PTAnnotationStylePresetsGroup *previousPresets = _annotStylePresets;
    _annotStylePresets = annotStylePresets;

    [self endObservingAnnotationStylePresets:previousPresets];
    if ([self isEnabled]) {
        [self beginObservingAnnotationStylePresets:annotStylePresets];
    }
}

- (void)beginObservingAnnotationStylePresets:(PTAnnotationStylePresetsGroup *)presets
{
    if (!presets) {
        return;
    }
    
    [self pt_observeObject:presets
                forKeyPath:PT_KEY(presets, selectedStyle)
                  selector:@selector(selectedPresetStyleDidChange:)
                   options:(NSKeyValueObservingOptionPrior)];
}

- (void)selectedPresetStyleDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.annotStylePresets) {
        return;
    }
    
    if ([change isPrior]) {
        PTTool *tool = self.toolManager.tool;
        
        // Commit freehand ink annotations when the selected preset changes.
        if (tool.identifier
            && [tool isKindOfClass:[PTFreeHandCreate class]]
            && ![tool isKindOfClass:[PTFreeHandHighlightCreate class]]) {
            PTFreeHandCreate *freehandTool = (PTFreeHandCreate *)tool;
            
            [freehandTool commitAnnotation];
            
            
            [self updateUndoRedoItems];
        }
    }
}

- (void)endObservingAnnotationStylePresets:(PTAnnotationStylePresetsGroup *)presets
{
    if (!presets) {
        return;
    }
    
    [self pt_removeObservationsForObject:presets
                                 keyPath:PT_KEY(presets, selectedStyle)];
}

#pragma mark - Persistence

#define PT_SAVED_ITEM_GROUPS_FILENAME @"annotationToolGroups.plist"

+ (NSURL *)savedGroupsURL
{
    NSURL *resourcesDirectoryURL = PTToolsUtil.toolsResourcesDirectoryURL;
    NSAssert(resourcesDirectoryURL != nil,
             @"Failed to get tools resources directory URL");
    
    return [resourcesDirectoryURL URLByAppendingPathComponent:PT_SAVED_ITEM_GROUPS_FILENAME];
}

#define PT_GROUPS_VERSION 1
#define PT_GROUPS_VERSION_KEY @"version"

- (void)saveGroups
{
    NSURL *savedGroupsURL = [self class].savedGroupsURL;

    [self saveGroupsToURL:savedGroupsURL];
}

- (void)saveGroupsToURL:(NSURL *)savedGroupsURL
{
    NSKeyedArchiver *archiver = nil;
    if (@available(iOS 11.0, *)) {
        archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    } else {
        archiver = [[NSKeyedArchiver alloc] init];
    }
    
    [self encodeGroupsWithCoder:archiver];
    
    NSData *data = archiver.encodedData;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *writeError = nil;
        const BOOL writeSuccess = [data writeToURL:savedGroupsURL
                                           options:(NSDataWritingAtomic)
                                             error:&writeError];
        if (!writeSuccess) {
            NSLog(@"Failed to save groups: %@", writeError);
        }
    });
}

- (void)encodeGroupsWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:PT_GROUPS_VERSION
                    forKey:PT_GROUPS_VERSION_KEY];
    [encoder encodeObject:self.groups
                   forKey:PT_SELF_KEY(groups)];
    [encoder encodeConditionalObject:self.selectedGroup
                              forKey:PT_SELF_KEY(selectedGroup)];
}

- (void)restoreGroups
{
    NSURL *savedGroupsURL = [self class].savedGroupsURL;

    [self restoreGroupsFromURL:savedGroupsURL];
}

- (void)restoreGroupsFromURL:(NSURL *)savedGroupsURL
{
    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:savedGroupsURL options:0 error:&readError];
    if (!data) {
        // An NSFileReadNoSuchFileError error is allowed.
        const BOOL fileNotFound = ([readError.domain isEqual:NSCocoaErrorDomain] &&
                                   readError.code == NSFileReadNoSuchFileError);
        if (!fileNotFound) {
            NSLog(@"Failed to load saved groups: %@", readError);
        }
        return;
    }
    
    NSKeyedUnarchiver *unarchiver = nil;
    if (@available(iOS 11.0, *)) {
        NSError *unarchiveError = nil;
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data
                                                                 error:&unarchiveError];
        if (unarchiveError) {
            NSLog(@"Failed to load saved groups: %@", unarchiveError);
            return;
        }
        unarchiver.requiresSecureCoding = NO;
    } else {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    }
    
    [self decodeGroupsWithCoder:unarchiver];
}

- (void)decodeGroupsWithCoder:(NSCoder *)decoder
{
    NSArray<PTToolGroup *> *savedGroups = nil;
    PTToolGroup *savedSelectedGroup = nil;
    
    const NSInteger version = [decoder decodeIntegerForKey:PT_GROUPS_VERSION_KEY];
    
    if (version >= 1) {
        savedGroups = [decoder decodeObjectForKey:PT_SELF_KEY(groups)];
        savedSelectedGroup = [decoder decodeObjectForKey:PT_SELF_KEY(selectedGroup)];
    } else {
        NSError *decodeError = nil;
        id object = [decoder decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey
                                                error:&decodeError];
        if (!object) {
            NSLog(@"Failed to load saved groups: %@", decodeError);
            return;
        }
        
        PTToolGroupManager *savedManager = nil;
        if ([object isKindOfClass:[PTToolGroupManager class]]) {
            savedManager = (PTToolGroupManager *)object;
        } else {
            return;
        }
        
        savedGroups = savedManager.groups;
        savedSelectedGroup = savedManager.selectedGroup;
    }
    
    // Sort groups based on the saved order.
    [self sortGroupsWithSavedGroups:savedGroups
                 savedSelectedGroup:savedSelectedGroup];
}

- (void)sortGroupsWithSavedGroups:(NSArray<PTToolGroup *> *)savedGroups savedSelectedGroup:(PTToolGroup *)savedSelectedGroup
{
    NSMutableArray<PTToolGroup *> *unsortedGroups = [self.groups mutableCopy];
    NSMutableArray<PTToolGroup *> *sortedGroups = [NSMutableArray array];
    
    for (PTToolGroup *savedGroup in savedGroups) {
        // Find this group in the unsorted groups list.
        const NSUInteger groupIndex = [unsortedGroups indexOfObjectPassingTest:^BOOL(PTToolGroup *group, NSUInteger index, BOOL *stop) {
            return [group.identifier isEqualToString:savedGroup.identifier];
        }];
        if (groupIndex != NSNotFound) {
            PTToolGroup *group = unsortedGroups[groupIndex];
            
            // Sort the group's items.
            NSMutableArray<UIBarButtonItem *> *unsortedItems = [group.barButtonItems mutableCopy];
            NSMutableArray<UIBarButtonItem *> *sortedItems = [NSMutableArray array];
            
            for (UIBarButtonItem *savedItem in savedGroup.barButtonItems) {
                // Find this item in the unsorted items list.
                NSString *itemIdentifierKey = nil;
                if ([savedItem isKindOfClass:[PTToolBarButtonItem class]]) {
                    itemIdentifierKey = PT_CLASS_KEY(PTToolBarButtonItem, toolClass);
                } else {
                    itemIdentifierKey = PT_CLASS_KEY(UIBarButtonItem, title);
                }
                
                const NSUInteger itemIndex = [unsortedItems indexOfObjectPassingTest:^BOOL(UIBarButtonItem *item, NSUInteger index, BOOL *stop) {
                    if (![item isMemberOfClass:[savedItem class]]) {
                        return NO;
                    }
                    id firstValue = [savedItem valueForKey:itemIdentifierKey];
                    id secondValue = [item valueForKey:itemIdentifierKey];
                    return [firstValue isEqual:secondValue];
                }];
                if (itemIndex != NSNotFound) {
                    UIBarButtonItem *item = unsortedItems[itemIndex];
                    
                    if ([savedItem isKindOfClass:[PTToolBarButtonItem class]] &&
                        [item isKindOfClass:[PTToolBarButtonItem class]]) {
                        PTToolBarButtonItem *savedToolItem = (PTToolBarButtonItem *)savedItem;
                        PTToolBarButtonItem *toolItem = (PTToolBarButtonItem *)item;
                        
                        // Copy the saved identifier to the item.
                        toolItem.identifier = savedToolItem.identifier;
                    }
                    
                    // Item is now sorted.
                    [sortedItems addObject:item];
                    [unsortedItems removeObjectAtIndex:itemIndex];
                } else {
                    if ([savedGroup isFavorite] &&
                        [savedItem isKindOfClass:[PTToolBarButtonItem class]]) {
                        PTToolBarButtonItem *savedToolItem = (PTToolBarButtonItem *)savedItem;
                        
                        UIBarButtonItem *item = [self createItemForToolClass:savedToolItem.toolClass];
                        
                        [sortedItems addObject:item];
                    }
                }
            }
            
            if (unsortedItems.count > 0) {
                [sortedItems addObjectsFromArray:unsortedItems];
                [unsortedItems removeAllObjects];
            }
            
            group.barButtonItems = [sortedItems copy];
            
            // Group is now sorted.
            [sortedGroups addObject:group];
            [unsortedGroups removeObjectAtIndex:groupIndex];
        }
    }
    
    // Add any remaining unsorted groups.
    if (unsortedGroups.count > 0) {
        [sortedGroups addObjectsFromArray:unsortedGroups];
        [unsortedGroups removeAllObjects];
    }
    
    self.groups = [sortedGroups copy];
    
    // Restore the saved selected group.
    NSString *savedSelectedGroupIdentifier = savedSelectedGroup.identifier;
    if (savedSelectedGroupIdentifier) {
        // Find the index of the saved selected group, by its identifier.
        const NSUInteger selectedGroupIndex = [self.groups indexOfObjectPassingTest:^BOOL(PTToolGroup *group, NSUInteger index, BOOL *stop) {
            return [group.identifier isEqualToString:savedSelectedGroupIdentifier];
        }];
        if (selectedGroupIndex != NSNotFound) {
            self.selectedGroupIndex = selectedGroupIndex;
        }
    }
}

@end
