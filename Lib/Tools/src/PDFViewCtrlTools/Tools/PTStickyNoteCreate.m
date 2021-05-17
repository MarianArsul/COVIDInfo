//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTStickyNoteCreate.h"

#import "PTPanTool.h"

@interface PTStickyNoteCreate ()
{
    BOOL creating;
    BOOL m_initialSticky;
}
@end

@implementation PTStickyNoteCreate


- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        
		m_initialSticky = YES;
    }
    
    return self;
}

-(Class)annotClass
{
    return [PTText class];
}

+(PTExtendedAnnotType)annotType
{
	return PTExtendedAnnotTypeText;
}

+(BOOL)createsAnnotation
{
	return YES;
}

-(void)setFrame:(CGRect)frame
{
    self.backgroundColor = [UIColor clearColor];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
//    handled by touchesended

    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    creating = true;

    return [super pdfViewCtrl:pdfViewCtrl onTouchesBegan:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    return [super pdfViewCtrl:pdfViewCtrl onTouchesMoved:touches withEvent:event];
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    if( !m_initialSticky && self.backToPanToolAfterUse )
    {
        self.nextToolType = [PTPanTool class];
        return NO;
    }
	else if( m_initialSticky )
	{
		self.endPoint = self.startPoint = self.longPressPoint;
		_pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.startPoint.x y:self.startPoint.y];
		[super pdfViewCtrl:self.pdfViewCtrl onTouchesEnded:[NSSet set] withEvent:nil];
		m_initialSticky = NO;
		[self.toolManager createSwitchToolEvent:nil];
		return YES;
	}
    else
	{
        return YES;
	}
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    creating = false;
    UITouch *touch = touches.allObjects[0];

    
    self.endPoint = [touch locationInView:self.pdfViewCtrl];

    _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.endPoint.x y:self.endPoint.y];

    if( self.pageNumber < 1 )
    {
        self.hidden = YES;
        
        m_initialSticky = NO;
        return YES;
        
    }
    else
    {
        BOOL returning = [super pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
        
        self.hidden = YES;
        
        m_initialSticky = NO;
        
    return returning;
    }
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{

    creating = false;
	UITouch *touch = touches.allObjects[0];
    
    self.endPoint = [touch locationInView:self.pdfViewCtrl];
    
    self.endPoint = [super boundToPageScreenPoint:self.endPoint withPaddingLeft:0 right:STICKY_NOTE_SIZE bottom:STICKY_NOTE_SIZE top:0];

    
    BOOL returning = [super pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
    
    self.hidden = YES;
	
	m_initialSticky = NO;
    
    return returning;
}


@end
