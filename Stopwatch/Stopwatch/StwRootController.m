//
//  StwRootController.m
//  Stopwatch
//
//  Created by Andrew's MAC on 2017-15-04.
//  Copyright © 2017 Andrew Chang. All rights reserved.
//

#import "StwRootController.h"
#import "AMCTools.h"

@implementation StwRootController
{
	NSTimeInterval _upTime;
	NSTextField __weak *_textTime;
}

- (void)_self_init
{
	if (0.0 == _upTime) {
		_upTime = [AMCTools systemUpTime];
		AMCDebug(@"%@ inited at sysup time: %lf", self, _upTime);
	}
}


- (instancetype)init
{
	self = [super init];
	if (self) {
		[self _self_init];
	}
	return self;
}


- (void)awakeFromNib
{
	[self _self_init];
}


- (void)setView:(AMCView *)view
{
	_view = view;
	if (view) {
		for (NSView __weak *eachView in [view subviews])
		{
			if ([@"Countdown" isEqualToString:[eachView identifier]] &&
				[eachView isKindOfClass:[NSTextField class]])
			{
				_textTime = (NSTextField *)eachView;
				[self _re_arrange_text];
				break;		/* !!! */
			}
		}
	}
	else {
		_textTime = nil;
	}
}


- (void)_re_arrange_text
{
	if (nil == _textTime) {
		return;
	}
	
	NSRect viewFrame = [self.view frame];
	NSString *text = [_textTime stringValue];
	NSFont *font = [_textTime font];
	NSSize strSize;
	
	if (nil == font) {
		font = [NSFont fontWithName:@"Monaco" size:20.0];
	}
	
	strSize = [AMCTools string:text sizeWithFont:font];
	AMCDebug("Str size: %@", [AMCTools descriptionWithNSSize:strSize]);
}


/********/
#pragma mark - AMCViewDelegate

- (void)handleSetFrameAtView:(AMCView *)view withRect:(NSRect)frame
{
	AMCDebug(@"View did set frame: %@", [AMCTools descriptionWithNSRect:frame]);
	[self _re_arrange_text];
}


- (BOOL)handleMouseDownAtView:(AMCView *)view event:(NSEvent *)event
{
	AMCDebug(@"Mouse down at %@", view);
	return NO;
}

@end
