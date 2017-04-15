//
//  AMCView.m
//  AMCTest
//
//  Created by Andrew Chang on 13-11-7.
//  Copyright (c) 2013年 Andrew Chang. All rights reserved.
//

#import "AMCView.h"
#import "AMCTools.h"

enum{
	AMCViewDelgateAvailability_None = 0,
	
	AMCViewDelgateAvailability_MouseDown			= (1 << 0),
	AMCViewDelgateAvailability_MouseDragged			= (1 << 1),
	AMCViewDelgateAvailability_MouseUp				= (1 << 2),
	AMCViewDelgateAvailability_MouseMoved			= (1 << 3),
	AMCViewDelgateAvailability_MouseEntered			= (1 << 4),
	AMCViewDelgateAvailability_MouseExited			= (1 << 5),
	AMCViewDelgateAvailability_RightMouseDragged	= (1 << 6),
	AMCViewDelgateAvailability_RightMouseUp			= (1 << 7),
	AMCViewDelgateAvailability_RightMouseDown		= (1 << 8),
	AMCViewDelgateAvailability_OtherMouseDown		= (1 << 9),
	AMCViewDelgateAvailability_OtherMouseDragged	= (1 << 10),
	AMCViewDelgateAvailability_OtherMouseUp			= (1 << 11),
	
	AMCViewDelgateAvailability_ScrollWheel			= (1 << 12),
	AMCViewDelgateAvailability_KeyDown				= (1 << 13),
	AMCViewDelgateAvailability_KeyUp				= (1 << 14),
	AMCViewDelgateAvailability_FlagsChanged			= (1 << 15),
	AMCViewDelgateAvailability_TabletPoint			= (1 << 16),
	AMCViewDelgateAvailability_TabletProximity		= (1 << 17),
	
	AMCViewDelgateAvailability_SetFrame				= (1 << 18),
	
	AMCViewDelgateAvailability_MagnifyWithEvent		= (1 << 19),
	AMCViewDelgateAvailability_RotateWithEvent		= (1 << 20),
	AMCViewDelgateAvailability_SwipeWithEvent		= (1 << 21),
	
	AMCViewDelgateAvailability_DrawRect				= (1 << 22),
	
	AMCViewDelgateAvailability_AppResignActive		= (1 << 23),
	AMCViewDelgateAvailability_AppBecomeActive		= (1 << 24),
	
	AMCViewDelgateAvailability_TrackMouseMove		= (1 << 25),
	AMCViewDelgateAvailability_TrackAppActive		= (1 << 26)
};

typedef NSUInteger AMCViewDelgateAvailability_t;

@implementation AMCView
{
	BOOL _shouldAcceptsFirstResponder;
	BOOL _shouldDrawsBackground;
	NSColor *_backGroundColor;
	AMCViewDelgateAvailability_t _delegateAvailability;
	
	NSTrackingArea *_TrackingArea;
	
	BOOL _isAppBecomeActNotifyAdded;
	BOOL _isAppResignActNotifyAdded;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		[self _generalAMCViewInit];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self _generalAMCViewInit];
    }
    
    return self;
}

- (void)_generalAMCViewInit
{
//	AMCDebug(@"_generalAMCViewInit from %@", [AMCTools descriptionForCallerOfCurrentMethod]);
	
	/* init delegate */
	[self _initDelegateSetting];
	
	_shouldAcceptsFirstResponder = NO;
	_shouldDrawsBackground = NO;
	_backGroundColor = nil;
	_delegateAvailability = AMCViewDelgateAvailability_None;
	_TrackingArea = nil;
	_isAppBecomeActNotifyAdded = NO;
	_isAppResignActNotifyAdded = NO;
	
	[self setAlphaValue:1.0];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	if (_shouldDrawsBackground && _backGroundColor)
	{
		[_backGroundColor set];
		NSRectFill(dirtyRect);
	}
	
	if (_delegateAvailability & AMCViewDelgateAvailability_DrawRect)
	{
		[_delegate viewDidDrawInRect:dirtyRect];
	}
}

- (void)awakeFromNib
{
//	[self _generalAMCViewInit];
}


- (void)dealloc
{
	if (_TrackingArea)
	{
		[self removeTrackingArea:_TrackingArea];
		_TrackingArea = nil;
	}
	
	if (_isAppBecomeActNotifyAdded)
	{
		[self _removeBecomeActiveNotification];
	}
	
	if (_isAppResignActNotifyAdded)
	{
		[self _removeResignActiveNotification];
	}
}


/********/
#pragma mark - custom methods

- (void)_checkDelegate:(id<AMCViewDelegate>)delegate
{
//	AMCDebug(@"Check delegate: %@ from %@", delegate, [AMCTools descriptionForCallerOfCurrentMethod]);
	
	/********/
	AMCViewDelgateAvailability_t oldAvailability = _delegateAvailability;
	
	/* mouseDown */
	if ([delegate respondsToSelector:@selector(handleMouseDownAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_MouseDown;
	}
	
	/* mouseDragged */
	if ([delegate respondsToSelector:@selector(handleMouseDraggedAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_MouseDragged;
	}
	
	/* mouseUp */
	if ([delegate respondsToSelector:@selector(handleMouseUpAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_MouseUp;
	}
	
	/* mouseMoved */
	if ([delegate respondsToSelector:@selector(handleMouseMovedAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_MouseMoved;
	}
	
	/* mouseEntered */
	if ([delegate respondsToSelector:@selector(handleMouseEnteredAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_MouseEntered;
	}
	
	/* mouseExited */
	if ([delegate respondsToSelector:@selector(handleMouseExitedAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_MouseExited;
	}
	
	/* rightMouseDragged */
	if ([delegate respondsToSelector:@selector(handleRightMouseDraggedAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_RightMouseDragged;
	}
	
	/* rightMouseUp */
	if ([delegate respondsToSelector:@selector(handleRightMouseUpAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_RightMouseUp;
	}
	
	/* rightMouseDown */
	if ([delegate respondsToSelector:@selector(handleRightMouseDownAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_RightMouseDown;
	}
	
	/* otherMouseDown */
	if ([delegate respondsToSelector:@selector(handleOtherMouseDownAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_OtherMouseDown;
	}
	
	/* otherMouseDragged */
	if ([delegate respondsToSelector:@selector(handleOtherMouseDraggedAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_OtherMouseDragged;
	}
	
	/* otherMouseUp */
	if ([delegate respondsToSelector:@selector(handleOtherMouseUpAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_OtherMouseUp;
	}
	
	/* scrollWheel */
	if ([delegate respondsToSelector:@selector(handleScrollWheelAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_ScrollWheel;
	}
	
	/* keyDown */
	if ([delegate respondsToSelector:@selector(handleKeyDownAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_KeyDown;
	}
	
	/* keyUp */
	if ([delegate respondsToSelector:@selector(handleKeyUpAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_KeyUp;
	}
	
	/* flagsChanged */
	if ([delegate respondsToSelector:@selector(handleFlagsChangedAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_FlagsChanged;
	}
	
	/* tabletPoint */
	if ([delegate respondsToSelector:@selector(handleTabletPointAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_TabletPoint;
	}
	
	/* tabletProximity */
	if ([delegate respondsToSelector:@selector(handleTabletProximityAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_TabletProximity;
	}
	
	/* setFrame */
	if ([delegate respondsToSelector:@selector(handleSetFrameAtView:withRect:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_SetFrame;
	}
	
	/* magnifyWithEvent */
	if ([delegate respondsToSelector:@selector(handleMagnifyAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_MagnifyWithEvent;
	}
	
	/* rotateWithEvent */
	if ([delegate respondsToSelector:@selector(handleRotateAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_RotateWithEvent;
	}
	
	/* swipeWithEvent */
	if ([delegate respondsToSelector:@selector(handleSwipeAtView:event:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_SwipeWithEvent;
	}
	
	/* drawRect */
	if ([delegate respondsToSelector:@selector(viewDidDrawInRect:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_DrawRect;
	}
	
	/* become active */
	if ([delegate respondsToSelector:@selector(handleAppDidBecomeActionAtView:notification:isMouseIn:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_AppBecomeActive;
	}
	
	/* resign active */
	if ([delegate respondsToSelector:@selector(handleAppDidResignActiveAtView:notification:isMouseIn:)])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_AppResignActive;
	}
	
	/********/
	/* tracking area */
	if ([self shouldForceEnableMouseTracking])
	{
		_delegateAvailability |= AMCViewDelgateAvailability_TrackMouseMove;
	}
	else if (0 != (_delegateAvailability &
			  (AMCViewDelgateAvailability_MouseMoved |
			   AMCViewDelgateAvailability_MouseEntered |
			   AMCViewDelgateAvailability_MouseExited
			   )))
	{
		_delegateAvailability |= AMCViewDelgateAvailability_TrackMouseMove;
	}
	else
	{}
	
	//
	if (_delegateAvailability & AMCViewDelgateAvailability_TrackMouseMove)
	{
		if (_TrackingArea)
		{
			[self removeTrackingArea:_TrackingArea];
			_TrackingArea = nil;
		}
		
		_TrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
													 options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingMouseMoved)
													   owner:self userInfo:nil];
		[self addTrackingArea:_TrackingArea];
	}
	else
	{
		if (_TrackingArea)
		{
			[self removeTrackingArea:_TrackingArea];
			_TrackingArea = nil;
		}
	}
	
	/********/
	/* NSApp application */
	if ([self shouldForceEnableAppFocusObservation])
	{
		//
		if (NO == _isAppBecomeActNotifyAdded)
		{
			[self _addBecomeActiveNotification];
		}
		
		//
		if (NO == _isAppResignActNotifyAdded)
		{
			[self _addResignActiveNotification];
		}
	}
	else
	{
		/* become active */
		if (oldAvailability & AMCViewDelgateAvailability_AppBecomeActive)
		{
			if (0 == (_delegateAvailability & AMCViewDelgateAvailability_AppBecomeActive))
			{
				[self _removeBecomeActiveNotification];
			}
		}
		else
		{
			if (_delegateAvailability & AMCViewDelgateAvailability_AppBecomeActive)
			{
				[self _addBecomeActiveNotification];
			}
		}
		
		/* resign active */
		if (oldAvailability & AMCViewDelgateAvailability_AppResignActive)
		{
			if (0 == (_delegateAvailability & AMCViewDelgateAvailability_AppResignActive))
			{
				[self _removeResignActiveNotification];
			}
		}
		else
		{
			if (_delegateAvailability & AMCViewDelgateAvailability_AppResignActive)
			{
				[self _addResignActiveNotification];
			}
		}
	}
}

- (void)_initDelegateSetting
{
	_delegate = nil;
	
	_shouldAcceptsFirstResponder = NO;
	_delegateAvailability = AMCViewDelgateAvailability_None;
	_delegate = nil;

	
	if (_TrackingArea &&
		(NO == [self shouldForceEnableMouseTracking]))
	{
		[self removeTrackingArea:_TrackingArea];
		_TrackingArea = nil;
	}
	else
	{}
	
	[self _checkDelegate:[self delegate]];
}


- (void)setDelegate:(id<AMCViewDelegate>)delegate
{
    BOOL responseCopy = _shouldAcceptsFirstResponder;
    
	if (nil == delegate)
	{
		_shouldAcceptsFirstResponder = NO;
		_delegateAvailability = AMCViewDelgateAvailability_None;
        _delegate = nil;
        _shouldAcceptsFirstResponder = responseCopy;
		
		if (_isAppResignActNotifyAdded)
		{
			[self _removeResignActiveNotification];
		}
		
		if (_isAppBecomeActNotifyAdded)
		{
			[self _removeBecomeActiveNotification];
		}
		
		[self _checkDelegate:nil];
	}
	else if (delegate == _delegate)
	{
		/* do nothing */
	}
	else
	{
		/**********/
		/* assign new delegate */
        _shouldAcceptsFirstResponder = NO;
		_delegateAvailability = AMCViewDelgateAvailability_None;
        _delegate = delegate;
		
		/**********/
		/* check each methods */
		[self _checkDelegate:_delegate];
        
        /* ENDS */
        _shouldAcceptsFirstResponder = responseCopy;
	}
}

- (void)setAcceptsFirstResonder:(BOOL)flag
{
	_shouldAcceptsFirstResponder = flag;
}


- (BOOL)acceptsFirstResponder
{
	return _shouldAcceptsFirstResponder;
}

- (void)setDrawsBackground:(BOOL)flag
{
	_shouldDrawsBackground = flag;
}

- (void)setBackgroundColor:(NSColor *)color
{
	_backGroundColor = color;
}

- (NSColor *)backgroundColor
{
	return _backGroundColor;
}

- (BOOL)shouldDrawsBackground
{
	return _shouldDrawsBackground;
}


- (BOOL)shouldForceEnableMouseTracking
{
	return NO;
}


- (BOOL)shouldForceEnableAppFocusObservation
{
	return NO;
}

/**********/
#pragma mark - mouse events
- (void)mouseDown:(NSEvent *)theEvent
{
	BOOL flag = NO;
    if (_delegateAvailability & AMCViewDelgateAvailability_MouseDown)
    {
        flag = [_delegate handleMouseDownAtView:self event:theEvent];
    }
	
	if (NO == flag)
	{
		[super mouseDown:theEvent];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_MouseDragged)
	{
		flag = [_delegate handleMouseDraggedAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super mouseDragged:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_MouseUp)
	{
		flag = [_delegate handleMouseUpAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super mouseUp:theEvent];
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_MouseMoved)
	{
		flag = [_delegate handleMouseMovedAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super mouseMoved:theEvent];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_MouseEntered)
	{
		flag = [_delegate handleMouseEnteredAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super mouseEntered:theEvent];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_MouseExited)
	{
		flag = [_delegate handleMouseExitedAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super mouseExited:theEvent];
	}
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_MouseDragged)
	{
		flag = [_delegate handleRightMouseDraggedAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super rightMouseDragged:theEvent];
	}
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_RightMouseUp)
	{
		flag = [_delegate handleRightMouseUpAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super rightMouseUp:theEvent];
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_RightMouseDown)
	{
		flag = [_delegate handleRightMouseDownAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super rightMouseDown:theEvent];
	}
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_OtherMouseDown)
	{
		flag = [_delegate handleOtherMouseDownAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super otherMouseDown:theEvent];
	}
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_OtherMouseDragged)
	{
		flag = [_delegate handleOtherMouseDraggedAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super otherMouseDragged:theEvent];
	}
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_OtherMouseUp)
	{
		flag = [_delegate handleOtherMouseUpAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super otherMouseUp:theEvent];
	}
}


/********/
#pragma mark - some other events

- (void)scrollWheel:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_ScrollWheel)
	{
		flag = [_delegate handleScrollWheelAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super scrollWheel:theEvent];
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_KeyDown)
	{
		flag = [_delegate handleKeyDownAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super keyDown:theEvent];
	}
}

- (void)keyUp:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_KeyUp)
	{
		flag = [_delegate handleKeyUpAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super keyUp:theEvent];
	}
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_FlagsChanged)
	{
		flag = [_delegate handleFlagsChangedAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super flagsChanged:theEvent];
	}
}

- (void)tabletPoint:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_TabletPoint)
	{
		flag = [_delegate handleTabletPointAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super tabletPoint:theEvent];
	}
}

- (void)tabletProximity:(NSEvent *)theEvent
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_TabletProximity)
	{
		flag = [_delegate handleTabletProximityAtView:self event:theEvent];
	}
	
	if (NO == flag)
	{
		[super tabletProximity:theEvent];
	}
}


/********/
#pragma mark - set frame

- (void)setFrame:(NSRect)frameRect
{
	NSRect lastRect = [self frame];
	[super setFrame:frameRect];
	
//	NSLog(@"Frame changed as: (%.0f,%.0f), %.0fx%.0f",
//		  frameRect.origin.x, frameRect.origin.y,
//		  frameRect.size.width, frameRect.size.height);
	
	if (0 == memcmp(&frameRect, &lastRect, sizeof(NSRect)))
	{
		/* tracking area not changed */
		/* do nothing */
	}
	else
	{
		/* tracking area changed */
		if (_TrackingArea)
		{
			[self removeTrackingArea:_TrackingArea];
			_TrackingArea = nil;
			_TrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
														 options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingMouseMoved)
														   owner:self userInfo:nil];
			[self addTrackingArea:_TrackingArea];
		}
	}
	
	if (_delegateAvailability & AMCViewDelgateAvailability_SetFrame)
	{
		[_delegate handleSetFrameAtView:self withRect:frameRect];
	}
}


/********/
#pragma mark - touchpad events

- (void)magnifyWithEvent:(NSEvent *)event
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_MagnifyWithEvent)
	{
		flag = [_delegate handleMagnifyAtView:self event:event];
	}
	
	if (NO == flag)
	{
		[super magnifyWithEvent:event];
	}
}


- (void)rotateWithEvent:(NSEvent *)event
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_RotateWithEvent)
	{
		flag = [_delegate handleRotateAtView:self event:event];
	}
	
	if (NO == flag)
	{
		[super rotateWithEvent:event];
	}
}


- (void)swipeWithEvent:(NSEvent *)event
{
	BOOL flag = NO;
	if (_delegateAvailability & AMCViewDelgateAvailability_SwipeWithEvent)
	{
		flag = [_delegate handleSwipeAtView:self event:event];
	}
	
	if (NO == flag)
	{
		[super swipeWithEvent:event];
	}
}


/********/
#pragma mark - application switching operations
- (void)_addBecomeActiveNotification
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidBecomeActive:)
												 name:NSApplicationDidBecomeActiveNotification
											   object:NSApp];
	_isAppBecomeActNotifyAdded = YES;
}


- (void)_removeBecomeActiveNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSApplicationDidBecomeActiveNotification
												  object:NSApp];
	_isAppBecomeActNotifyAdded = NO;
}


- (void)_addResignActiveNotification
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidResignActive:)
												 name:NSApplicationDidResignActiveNotification
											   object:NSApp];
	_isAppResignActNotifyAdded = YES;
}


- (void)_removeResignActiveNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSApplicationDidResignActiveNotification
												  object:NSApp];
	_isAppResignActNotifyAdded = NO;
}


- (void)appDidResignActive:(NSNotification*)aNotification
{
	if (_delegate && [_delegate respondsToSelector:@selector(handleAppDidResignActiveAtView:notification:isMouseIn:)])
	{
		[_delegate handleAppDidResignActiveAtView:self notification:aNotification isMouseIn:[self isCurrentMouseIn]];
	}
}


- (void)appDidBecomeActive:(NSNotification*)aNotification
{
	if (_delegate && [_delegate respondsToSelector:@selector(handleAppDidBecomeActionAtView:notification:isMouseIn:)])
	{
		[_delegate handleAppDidBecomeActionAtView:self notification:aNotification isMouseIn:[self isCurrentMouseIn]];
	}
}


- (BOOL)isCurrentMouseIn
{
	BOOL isMouseIn;
	NSPoint mouseInScreen = [NSEvent mouseLocation];
	NSPoint mouseInSelf;
	NSRect windowRect = [self.window frame];
	
	mouseInScreen.x -= NSMinX(windowRect);
	mouseInScreen.y -= NSMinY(windowRect);
	
	mouseInSelf = [self convertPoint:mouseInScreen fromView:[self.window contentView]];
	
	isMouseIn = NSPointInRect(mouseInSelf, [self bounds]) ? YES : NO;
	
	return isMouseIn;
}


/********/
#pragma mark - view display operation events

#if 0
- (void)viewDidMoveToWindow
{
	NSLog(@"View did move to window %@", self.window);
	
	id delegate = self.delegate;
	
	if (self.window)
	{
		[self setDelegate:nil];
		[self setDelegate:delegate];
	}
}

- (void)viewDidMoveToSuperview
{
	NSLog(@"View did move to superview %@", self.superview);
}
#endif


@end
