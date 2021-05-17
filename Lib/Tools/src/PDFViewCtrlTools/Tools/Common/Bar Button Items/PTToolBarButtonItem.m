//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolBarButtonItem.h"

#import "PTTool.h"
#import "PTAnnotStyle.h"
#import "PTAnnotationStyleIndicatorView.h"
#import "PTAnnotationStyleManager.h"
#import "PTAutoCoding.h"

@interface PTToolBarButtonItem ()

@property (nonatomic, weak, nullable) PTAnnotationStyleIndicatorView *styleIndicatorView;

@end

@implementation PTToolBarButtonItem

- (instancetype)initWithToolClass:(Class)toolClass target:(id)target action:(SEL)action
{
    NSParameterAssert([toolClass isSubclassOfClass:[PTTool class]]);
    
    UIImage *image = [toolClass image];
    NSString *title = [toolClass localizedName];
    
    const PTExtendedAnnotType annotType = [toolClass annotType];
    
    if ([toolClass createsAnnotation] &&
        [toolClass canEditStyle] &&
        (annotType != PTExtendedAnnotTypeUnknown)) {
        
        PTAnnotationStyleIndicatorView *indicator = [[PTAnnotationStyleIndicatorView alloc] init];
        indicator.style = [[PTAnnotStyle allocOverridden] initWithAnnotType:annotType];
        
        self = [super initWithCustomView:indicator];
        if (self) {
            _toolClass = toolClass;

            self.image = image;
            self.title = title;
            
            self.target = target;
            self.action = action;
            
            [indicator addTarget:self
                          action:@selector(controlTriggered:)
                forControlEvents:UIControlEventPrimaryActionTriggered];
            
            _styleIndicatorView = indicator;
        }
    } else {
        self = [super initWithImage:image style:UIBarButtonItemStylePlain target:target action:action];
        if (self) {
            _toolClass = toolClass;
            
            self.title = title;
        }
    }
    return self;
}

- (void)controlTriggered:(id)sender
{
    if (!self.action) {
        return;
    }
    
    [UIApplication.sharedApplication sendAction:self.action
                                             to:self.target
                                           from:self
                                       forEvent:nil];
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [PTAutoCoding autoUnarchiveObject:self
                                  ofClass:[PTToolBarButtonItem class]
                                withCoder:coder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [PTAutoCoding autoArchiveObject:self
                            ofClass:[PTToolBarButtonItem class]
                            forKeys:nil
                          withCoder:coder];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithToolClass:self.toolClass
                                            target:self.target
                                            action:self.action];
}

- (void)setIdentifier:(NSString *)identifier
{
    _identifier = [identifier copy];
    
    if (self.styleIndicatorView) {
        const PTExtendedAnnotType annotType = [self.toolClass annotType];
        
        PTAnnotationStylePresetsGroup *presets = nil;
        if (identifier) {
            PTAnnotationStyleManager *manager = PTAnnotationStyleManager.defaultManager;
            
            presets =  [manager stylePresetsForAnnotationType:annotType
                                                   identifier:identifier];
        }
        if (presets) {
            self.styleIndicatorView.presetsGroup = presets;
        } else {
            self.styleIndicatorView.style = [[PTAnnotStyle allocOverridden] initWithAnnotType:annotType];
        }
    }
}

@end
