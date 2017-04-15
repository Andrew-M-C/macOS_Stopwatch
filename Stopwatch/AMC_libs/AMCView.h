//
//  AMCView.h
//  AMCTest
//
//  Created by Andrew Chang on 13-11-7.
//  Copyright (c) 2013年 Andrew Chang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AMCView;
@protocol AMCViewDelegate <NSObject>

@optional
- (BOOL)handleMouseDownAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleMouseDraggedAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleMouseUpAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleMouseMovedAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleMouseEnteredAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleMouseExitedAtView:(AMCView*)view event:(NSEvent*)event;

- (BOOL)handleRightMouseDraggedAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleRightMouseUpAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleRightMouseDownAtView:(AMCView*)view event:(NSEvent*)event;

- (BOOL)handleOtherMouseDownAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleOtherMouseDraggedAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleOtherMouseUpAtView:(AMCView*)view event:(NSEvent*)event;

- (BOOL)handleScrollWheelAtView:(AMCView*)view event:(NSEvent*)event;

- (BOOL)handleKeyDownAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleKeyUpAtView:(AMCView*)view event:(NSEvent*)event;

- (BOOL)handleFlagsChangedAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleTabletPointAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleTabletProximityAtView:(AMCView*)view event:(NSEvent*)event;

- (void)handleSetFrameAtView:(AMCView*)view withRect:(NSRect)frame;

- (BOOL)handleMagnifyAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleRotateAtView:(AMCView*)view event:(NSEvent*)event;
- (BOOL)handleSwipeAtView:(AMCView*)view event:(NSEvent*)event;

- (void)handleAppDidResignActiveAtView:(AMCView*)view notification:(NSNotification*)notification isMouseIn:(BOOL)isMouseIn;
- (void)handleAppDidBecomeActionAtView:(AMCView*)view notification:(NSNotification*)notification isMouseIn:(BOOL)isMouseIn;

- (void)viewDidDrawInRect:(NSRect)rect;

@end


@interface AMCView : NSView
@property (nonatomic, assign) id<AMCViewDelegate> delegate;
- (BOOL)shouldForceEnableAppFocusObservation;
- (BOOL)shouldForceEnableMouseTracking;
- (void)setBackgroundColor:(NSColor*)color;
- (NSColor*)backgroundColor;
- (void)setDrawsBackground:(BOOL)flag;
- (BOOL)shouldDrawsBackground;
- (void)setAcceptsFirstResonder:(BOOL)flag;

- (void)appDidResignActive:(NSNotification*)aNotification;		/* do not call this. This is for overwriting use */
- (void)appDidBecomeActive:(NSNotification*)aNotification;		/* do not call this. This is for overwriting use */

- (BOOL)isCurrentMouseIn;
@end
