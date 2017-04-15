//
//  AppDelegate.m
//  Stopwatch
//
//  Created by Andrew's MAC on 2017-15-04.
//  Copyright © 2017 Andrew Chang. All rights reserved.
//

#import "AppDelegate.h"
#import "AMCView.h"
#import "StwRootController.h"
#import "AMCTools.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
	StwRootController *_rootCtrl;
	CGFloat _windowTitleHeight;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	
	if ([self.window.contentView isKindOfClass:[AMCView class]]) {
		_rootCtrl = [[StwRootController alloc] init];
		[(AMCView*)[self.window contentView] setDelegate:_rootCtrl];
		[_rootCtrl setView:[self.window contentView]];
	}
	
	[_window setDelegate:self];
	_windowTitleHeight = NSHeight([_window frame]) - NSHeight([_window.contentView frame]);
	AMCDebug(@"Windows title height: %f", _windowTitleHeight);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}


/********/
#pragma mark - NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification
{
	NSRect frame = [_window frame];
	frame.size.height -= _windowTitleHeight;
	frame.origin = NSZeroPoint;
	
	[_window.contentView setFrame:frame];
}


@end
