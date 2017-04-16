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
	NSTimer *_timer;
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
	
	NSRect frame = [self.view frame];
	NSString *text = [_textTime stringValue];
	NSFont *font = [_textTime font];
	NSSize strSize;
	
	frame.origin.x = 30.0;
	frame.origin.y = NSHeight(frame) * 0.5;
	frame.size.width -= 60.0;
	frame.size.height = 30.0;
	
	if (nil == font) {
		font = [NSFont fontWithName:@"Monaco" size:20.0];
	}

	strSize = [AMCTools string:text sizeWithFont:font];
	if (strSize.width < NSWidth(frame))
	{
		/* increment mode */
		NSSize lastStrSize = strSize;
		NSSize nextStrSize = strSize;
		CGFloat nextFontSize = [font pointSize];
		CGFloat lastFontSize = lastFontSize;
		do {
			lastStrSize = nextStrSize;
			lastFontSize = nextFontSize;
			nextFontSize += 1.0;
			nextStrSize = [AMCTools string:text sizeWithFontName:@"Monaco" size:nextFontSize];
//			AMCPrintf(@"Try %@ of %f", [AMCTools descriptionWithNSSize:nextStrSize], nextFontSize);
		} while (nextStrSize.width < NSWidth(frame));
		
		frame.size.height = lastStrSize.height + 10.0;
		frame.size.width += 30.0;
		frame.origin.y -= NSHeight(frame) * 0.5;
		[_textTime setFont:[NSFont fontWithName:@"Monaco" size:lastFontSize]];
		[_textTime setFrame:frame];
		AMCDebug(@"Set text: %@, font size: %f", [AMCTools descriptionWithNSRect:frame], lastFontSize);
	}
	else {
		/* decrement mode */
		NSSize lastStrSize = strSize;
		NSSize nextStrSize = strSize;
		CGFloat nextFontSize = [font pointSize];
		CGFloat lastFontSize = lastFontSize;
		do {
			lastStrSize = nextStrSize;
			lastFontSize = nextFontSize;
			nextFontSize -= 1.0;
			nextStrSize = [AMCTools string:text sizeWithFontName:@"Monaco" size:nextFontSize];
//			AMCPrintf(@"Try %@ of %f", [AMCTools descriptionWithNSSize:nextStrSize], nextFontSize);
		} while (nextStrSize.width > NSWidth(frame));
		
		frame.size.height = lastStrSize.height + 10.0;
		frame.size.width += 30.0;
		frame.origin.y -= NSHeight(frame) * 0.5;
		[_textTime setFont:[NSFont fontWithName:@"Monaco" size:lastFontSize]];
		[_textTime setFrame:frame];
		AMCDebug(@"Set text: %@, font size: %f", [AMCTools descriptionWithNSRect:frame], lastFontSize);
	}
	
	[_view setNeedsDisplay:YES];
	[_textTime setNeedsDisplay:YES];
}


/********/
#pragma mark - Schedule control

- (void)_show_time:(NSTimeInterval)interval
{
	NSInteger secs = (NSInteger)interval;
	NSInteger hour = secs / 3600;
	NSInteger min  = (secs - (hour * 3600)) / 60;
	NSInteger sec  = (secs - (hour * 3600) - (min * 60));
	NSInteger milisec = (NSInteger)((interval - secs) * 1000);

	NSString *timeStr = [NSString stringWithFormat:@"%ld:%02ld:%02ld.%03ld",
						 hour, min, sec, milisec];
	timeStr = [timeStr stringByReplacingOccurrencesOfString:@"0" withString:@"O"];

//	AMCPrintf(@"%f, %ld", interval, secs);
	[_textTime setStringValue:timeStr];
}

- (void)_timer_routine:(id)arg
{
	NSTimeInterval interval = [AMCTools systemUpTime] - _upTime;
	[self _show_time:interval];

	UpdateSystemActivity(1);
}


- (void)_start_timer
{
	_upTime = [AMCTools systemUpTime];
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.003
											  target:self
											selector:@selector(_timer_routine:)
											userInfo:nil
											 repeats:YES];
}


- (void)_stop_timer
{
	NSTimeInterval stopTime = [AMCTools systemUpTime];
	[_timer invalidate];
	AMCRelease(_timer);

	[self _show_time:stopTime - _upTime];
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
	if (_timer) {
		[self _stop_timer];
	} else {
		[self _start_timer];
	}
	return NO;
}

@end
