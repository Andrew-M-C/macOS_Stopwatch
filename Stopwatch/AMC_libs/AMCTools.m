//
//  AMCTools.m
//  TPLibraryTest
//
//  Created by TP-LINK on 13-3-13.
//  Copyright (c) 2013年 Andrew Chang. All rights reserved.
//

#import "AMCTools.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#include <errno.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#import <arpa/inet.h>
#include <signal.h>


/* Codes to fix a bug of QTMovie from Xcode */
#if CFG_FRAMEWORK_QTKIT
@interface NSObject (AMCTools)
- (NSSliderType)sliderType;
- (NSInteger)numberOfTickMarks;
@end

// Add C implementations of missing methods that we’ll add
// to the StdMovieUISliderCell class later.
static NSSliderType SliderType(id self, SEL _cmd)
{
	return NSLinearSlider;
}

static NSInteger NumberOfTickMarks(id self, SEL _cmd)
{
	return 0;
}

// rot13, just to be extra safe.
static NSString *ResolveName(NSString *aName)
{
	const char *_string = [aName cStringUsingEncoding:NSASCIIStringEncoding];
	NSUInteger stringLength = [aName length];
	char newString[stringLength+1];
	
	NSUInteger x;
	for(x = 0; x < stringLength; x++)
	{
		unsigned int aCharacter = _string[x];
		
		if( 0x40 < aCharacter && aCharacter < 0x5B ) // A - Z
			newString[x] = (((aCharacter - 0x41) + 0x0D) % 0x1A) + 0x41;
		else if( 0x60 < aCharacter && aCharacter < 0x7B ) // a-z
			newString[x] = (((aCharacter - 0x61) + 0x0D) % 0x1A) + 0x61;
		else  // Not an alpha character
			newString[x] = aCharacter;
	}
	newString[x] = '\0';
	
	return [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
}
#endif


@implementation AMCTools
/* block alloc method */
+ (id)alloc
{
	NSLog(@"*** WARNING: %s should NEVER be called!", __FUNCTION__);
	return nil;
}


/* AMCIntegerRect_st tools */
+ (NSRect)NSRectFromAMCRect:(AMCIntegerRect_st)rect
{
	return NSMakeRect((CGFloat)rect.x,
					  (CGFloat)rect.y,
					  (CGFloat)rect.width,
					  (CGFloat)rect.height);
}

+ (AMCIntegerRect_st)AMCRectFromNSRect:(NSRect)rect
{
	AMCIntegerRect_st amcRect;
	amcRect.x = (NSInteger)(rect.origin.x);
	amcRect.y = (NSInteger)(rect.origin.y);
	amcRect.width = (NSInteger)(rect.size.width);
	amcRect.height = (NSInteger)(rect.size.height);
	return amcRect;
}

+ (AMCIntegerRect_st)AMCZeroRect
{
	AMCIntegerRect_st rect;
	memset(&rect, 0, sizeof(rect));
	return rect;
}

+ (AMCIntegerRect_st)AMCMakeRectX:(NSInteger)x
								Y:(NSInteger)y
							width:(NSInteger)width
						   height:(NSInteger)height
{
	AMCIntegerRect_st rect;
	rect.x = x;
	rect.y = y;
	rect.width = width;
	rect.height = height;
	return rect;
}


+ (NSString *)descriptionWithAMCRect:(AMCIntegerRect_st)rect
{
	return [NSString stringWithFormat:@"(%ld,%ld), %ld*%ld", rect.x, rect.y, rect.width, rect.height];
}


/* Locolization Tools */
+(NSString *)localize:(NSString *)key
{
	return NSLocalizedString(key, nil);
}


/* NSOpenPanel Tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+(NSString *)getOpenPanelPath:(NSOpenPanel *)panel
					  AtIndex:(NSUInteger)index
{
	if (!panel)
	{
		return nil;
	}
	
	if (index >= [[panel URLs] count])
	{
		return nil;
	}
	else
	{
		return [[[panel URLs] objectAtIndex:index] path];
	}
}
#endif


/* PWD Tools */
+(NSString *)pwd
{
	return [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
}


+ (NSString *)pwdWithAppName
{
	return [[NSBundle mainBundle] bundlePath];
}


+ (NSString *)homeDirectory
{
	return NSHomeDirectory();
}


/* NSImage and CGImage Conversion Tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSImage *)nsImageFromCGImageRef:(CGImageRef)cgImageRef
{
	NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);	
	CGContextRef imageContext = nil;	
	NSImage* newImage = nil;

    // Get the image dimensions.
	imageRect.size.height = CGImageGetHeight(cgImageRef);
	imageRect.size.width = CGImageGetWidth(cgImageRef);
	
	// Create a new image to receive the Quartz image data.
	newImage = [[NSImage alloc] initWithSize:imageRect.size];
	[newImage lockFocus];
	
	// Get the Quartz context and draw.
	imageContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGContextDrawImage(imageContext, *(CGRect*)&imageRect, cgImageRef);
	[newImage unlockFocus];
	
	return newImage;
}

+ (CGImageRef)cgImageRefFromNSImage:(NSImage *)image
{
	NSData *imageData = [image TIFFRepresentation];
	CGImageRef imageRef = NULL;
	if (imageData)
	{
		CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
		imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		AMCRelease(imageData);
	}
	return imageRef;
}
#endif



/* QTKit Tools */
#if CFG_FRAMEWORK_QTKIT
+(QTMovieLoadState)getQTMovieStat:(QTMovie *)movie
{
	if (movie)
	{
		return [[movie attributeForKey:QTMovieLoadStateAttribute] longValue];
	}
	else
	{
		return QTMovieLoadStateError;
	}
}

+(CGImageRef)cgImageRefFromNSImage:(NSImage *)nsImage
{
	NSData * imageData = [nsImage TIFFRepresentation];
    CGImageRef imageRef;
    if(imageData)
    {
        CGImageSourceRef imageSource =
		CGImageSourceCreateWithData((__bridge CFDataRef)imageData,  NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
    return imageRef;
}

+(CGImageRef)getMovieFrame:(QTMovie*)movie
					atTime:(QTTime)time
{
	NSDictionary *attributes;
	attributes = [NSDictionary dictionaryWithObject:QTMovieFrameImageTypeCGImageRef forKey:QTMovieFrameImageType];
	return [movie frameImageAtTime:time
					withAttributes:attributes
							 error:NULL];
}

+ (void)fixSliderCellBug
{
	Class MovieSliderCell = NSClassFromString(ResolveName(@"FgqZbivrHVFyvqrePryy"));
	
	if (!class_getInstanceMethod(MovieSliderCell, @selector(sliderType)))
	{
		const char *types = [[NSString stringWithFormat:@"%s%s%s",
							  @encode(NSSliderType), @encode(id), @encode(SEL)] UTF8String];
		class_addMethod(MovieSliderCell, @selector(sliderType),
						(IMP)SliderType, types);
	}
	if (!class_getInstanceMethod(MovieSliderCell, @selector(numberOfTickMarks)))
	{
		const char *types = [[NSString stringWithFormat: @"%s%s%s",
							  @encode(NSInteger), @encode(id), @encode(SEL)] UTF8String];
		class_addMethod(MovieSliderCell, @selector(numberOfTickMarks),
						(IMP)NumberOfTickMarks, types);
	}
}

+(QTCaptureDevice *)allocateACamera:(NSError *__autoreleasing *)errorPtr
{
	QTCaptureDevice *videoDevice;
	videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	if (videoDevice)
	{
		[videoDevice open:errorPtr];
	}
	
	return videoDevice;
}

+(void)setMovieOutputFile:(QTCaptureMovieFileOutput *)movieFileOutput
			  videoOption:(NSString *)videoOpt
			  audioOption:(NSString *)audioOpt
{
	if (!movieFileOutput)
	{
		return;
	}
	
	NSEnumerator *connectEnum = [[movieFileOutput connections] objectEnumerator];
	if (!connectEnum)
	{
		NSLog(@"*** WARNING: objectEnumerator NULL");
		return;
	}
	
	QTCaptureConnection *connection;
	while (connection = [connectEnum nextObject])
	{
		@autoreleasepool {
			//NSLog(@"%@", connection);
			NSString *mediaType = [connection mediaType];
			QTCompressionOptions *options = nil;
			if ([mediaType isEqualToString:QTMediaTypeVideo])
			{
				if (videoOpt)
				{
					options = [QTCompressionOptions compressionOptionsWithIdentifier:videoOpt];
				}
			}
			else if ([mediaType isEqualToString:QTMediaTypeSound])
			{
				if (audioOpt)
				{
					options = [QTCompressionOptions compressionOptionsWithIdentifier:audioOpt];
				}
			}
			
			if (options)
			{
				[movieFileOutput setCompressionOptions:options forConnection:connection];
			}
		}
	}
}
#endif

/* OSStatus to NSError */
+(NSError*)errorFromOSStatus:(OSStatus) status
{
	NSError *error;
	error = [NSError errorWithDomain:NSOSStatusErrorDomain
								code:status
							userInfo:nil];
	return error;
}


/* NSApplication Tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)

+ (void)terminateApplication:(id)sender
{
	[[NSApplication sharedApplication] terminate:self];
}


+ (BOOL)checkAppDuplicateAndBringToFrontWithBundle:(NSBundle *)bundle
{
	NSRunningApplication *app;
	NSArray *appArray;
	NSUInteger tmp;
	pid_t selfPid;
	BOOL ret = NO;
	
	
	selfPid = [[NSRunningApplication currentApplication] processIdentifier];
	appArray = [NSRunningApplication runningApplicationsWithBundleIdentifier:[bundle bundleIdentifier]];
	
	for (tmp = 0; tmp < [appArray count]; tmp++)
	{
		app = [appArray objectAtIndex:tmp];
		
		if ([app processIdentifier] == selfPid)
		{
			/* do nothing */
		}
		else
		{
			[[NSWorkspace sharedWorkspace] launchApplication:[[app bundleURL] path]];
			ret = YES;
		}
		
		AMCRelease(app);
	}
	
	
	AMCRelease(appArray);
	return ret;
}

+ (BOOL)checkAppDuplicateAndKillOthersWithBundle:(NSBundle *)bundle
{
	NSRunningApplication *app;
	NSArray *appArray;
	NSUInteger tmp;
	pid_t selfPid;
	BOOL ret = NO;
	
	
	selfPid = [[NSRunningApplication currentApplication] processIdentifier];
	appArray = [NSRunningApplication runningApplicationsWithBundleIdentifier:[bundle bundleIdentifier]];
	
	for (tmp = 0; tmp < [appArray count]; tmp++)
	{
		app = [appArray objectAtIndex:tmp];
		
		if ([app processIdentifier] == selfPid)
		{
			/* do nothing */
		}
		else
		{
			kill([app processIdentifier], SIGTERM);
			ret = YES;
		}
		
		AMCRelease(app);
	}
	
	
	AMCRelease(appArray);
	return ret;
}

#endif


/* NSWindow Tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+(void)windowSetCentered:(NSWindow*)window
{
	/* get screen and window information */
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect windowRect = [window frame];
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	CGFloat toolbarY = screenVisibleRect.origin.y + screenVisibleRect.size.height;

	/* culculate center position */
	windowRect.origin.x = (screenRect.size.width - windowRect.size.width) / 2.0;
	windowRect.origin.y = (screenRect.size.height - windowRect.size.height) / 2.0;
	
	/* check if window exceed title bar */
	if (windowRect.origin.y > toolbarY)
	{
		windowRect.origin.y = toolbarY;
	}
	
	/* apply config */
	[window setFrame:windowRect display:YES];
}

+(void)windowSetCenteredInVisableScreen:(NSWindow *)window
{
	/* get screen and window information */
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	CGFloat toolbarY = screenVisibleRect.origin.y + screenVisibleRect.size.height;
	
	/* culculate center position */
	windowRect.origin.x = (screenVisibleRect.size.width - windowRect.size.width) / 2.0;
	windowRect.origin.y = (screenVisibleRect.size.height - windowRect.size.height) / 2.0 + screenVisibleRect.origin.y;
	
	/* check if window exceed title bar */
	if (windowRect.origin.y > toolbarY)
	{
		windowRect.origin.y = toolbarY;
	}
	
	/* apply config */
	[window setFrame:windowRect display:YES];
}

+(void)windowSetTopLeft:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	CGFloat toolbarY = screenVisibleRect.origin.y + screenVisibleRect.size.height;
	
	windowRect.origin.x = 0.0;
	windowRect.origin.y = toolbarY - windowRect.size.height;
	
	[window setFrame:windowRect display:YES];
}

+(void)windowSetTopRight:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	CGFloat toolbarY = screenVisibleRect.origin.y + screenVisibleRect.size.height;
	
	windowRect.origin.x = screenVisibleRect.size.width - windowRect.size.width;
	windowRect.origin.y = toolbarY - windowRect.size.height;
	
	[window setFrame:windowRect display:YES];
}

+(void)windowSetBottomLeftInVisableScreen:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	
	windowRect.origin.x = 0.0;
	windowRect.origin.y = screenVisibleRect.origin.y;
	
	[window setFrame:windowRect display:YES];
}

+(void)windowSetBottomRightInVisableScreen:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	
	windowRect.origin.x = screenVisibleRect.size.width - windowRect.size.width;
	windowRect.origin.y = screenVisibleRect.origin.y;
	
	[window setFrame:windowRect display:YES];
}

+(void)windowSetTopCenter:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	CGFloat toolbarY = screenVisibleRect.origin.y + screenVisibleRect.size.height;
	
	windowRect.origin.x = (screenVisibleRect.size.width - windowRect.size.width) / 2.0;
	windowRect.origin.y = toolbarY - windowRect.size.height;
	
	[window setFrame:windowRect display:YES];
}

+(void)windowSetBottomCenterInVisableScreen:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	
	windowRect.origin.x = (screenVisibleRect.size.width - windowRect.size.width) / 2.0;
	windowRect.origin.y = screenVisibleRect.origin.y;
	
	[window setFrame:windowRect display:YES];
}

+(void)windowSetCenterLeftInVisableScreen:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	
	windowRect.origin.x = 0;
	windowRect.origin.y = (screenVisibleRect.size.height - windowRect.size.height) / 2.0 + screenVisibleRect.origin.y;
	
	[window setFrame:windowRect display:YES];
}

+(void)windowSetCenterRightInVisableScreen:(NSWindow *)window
{
	NSRect screenVisibleRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	
	windowRect.origin.x = screenVisibleRect.size.width - windowRect.size.width;
	windowRect.origin.y = (screenVisibleRect.size.height - windowRect.size.height) / 2.0 + screenVisibleRect.origin.y;
	
	[window setFrame:windowRect display:YES];
}


+ (void)window:(NSWindow *)window setInScreenRatioX:(CGFloat)x ratioY:(CGFloat)y
{
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect windowRect = [window frame];
	NSPoint windowCenter;
	
	windowCenter.x = NSMinX(screenRect) + NSWidth(screenRect) * x;
	windowCenter.y = NSMinY(screenRect) + NSHeight(screenRect) * y;
	
	windowRect.origin.x = windowCenter.x - NSWidth(windowRect) * 0.5;
	windowRect.origin.y = windowCenter.y - NSHeight(windowRect) * 0.5;
	
	[window setFrame:windowRect display:YES];
}


+ (void)window:(NSWindow *)window setInVisableScreenRatioX:(CGFloat)x ratioY:(CGFloat)y
{
	NSRect screenRect = [[NSScreen mainScreen] visibleFrame];
	NSRect windowRect = [window frame];
	NSPoint windowCenter;
	
	windowCenter.x = NSMinX(screenRect) + NSWidth(screenRect) * x;
	windowCenter.y = NSMinY(screenRect) + NSHeight(screenRect) * y;
	
	windowRect.origin.x = windowCenter.x - NSWidth(windowRect) * 0.5;
	windowRect.origin.y = windowCenter.y - NSHeight(windowRect) * 0.5;
	
	[window setFrame:windowRect display:YES];
}


+ (void)window:(NSWindow *)subWindow
dragInToWindow:(NSWindow *)superWindow
{
	[NSApp beginSheet:subWindow
	   modalForWindow:superWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:NULL];
}

+ (void)windowDragOut:(NSWindow *)subWindow
{
	[NSApp endSheet:subWindow];
	[subWindow orderOut:nil];
}

+ (void)window:(NSWindow *)window setResizeEnable:(BOOL)flag
{
	[[window standardWindowButton:NSWindowZoomButton] setEnabled:flag];
	
	NSUInteger styleMark = [window styleMask];
	if (flag)
	{
		styleMark |= NSResizableWindowMask;
	}
	else
	{
		styleMark &=~(NSResizableWindowMask);
	}
	[window setStyleMask:styleMark];
}


+ (void)window:(NSWindow *)window setMinimumEnable:(BOOL)flag
{
	[[window standardWindowButton:NSWindowMiniaturizeButton] setEnabled:flag];
	
	NSUInteger styleMark = [window styleMask];
	if (flag)
	{
		styleMark |= NSMiniaturizableWindowMask;
	}
	else
	{
		styleMark &=~NSMiniaturizableWindowMask;
	}
	[window setStyleMask:styleMark];
}


+ (void)window:(NSWindow *)window setCloseEnable:(BOOL)flag
{
	[[window standardWindowButton:NSWindowCloseButton] setEnabled:flag];
	
	NSUInteger styleMask = [window styleMask];
	if (flag)
	{
		styleMask |= NSClosableWindowMask;
	}
	else
	{
		styleMask &=~NSClosableWindowMask;
	}
	[window setStyleMask:styleMask];
}


+ (NSArray *)firstResponderTrainForWindow:(NSWindow *)window
{
	NSArray *ret;
	NSMutableArray *responderArray = [NSMutableArray array];
	NSResponder *currentResponder = [window firstResponder];
	
	while (nil != currentResponder)
	{
		[responderArray addObject:currentResponder];
		currentResponder = [currentResponder nextResponder];
	}
	
	ret = [NSArray arrayWithArray:responderArray];
	AMCRelease(responderArray);
	return ret;
}

+ (void)window:(NSWindow *)window setFirstResponderTrain:(NSArray *)firstResponders
{
	if (0 == [firstResponders count])
	{
		return;
	}
	
	NSResponder *first = [firstResponders objectAtIndex:0];
	NSUInteger tmp;
	for (tmp = 1; tmp < [firstResponders count]; tmp++)
	{
		[first setNextResponder:[firstResponders objectAtIndex:tmp]];
		first = [first nextResponder];
	}

	[window makeFirstResponder:[firstResponders objectAtIndex:0]];
}

+ (void)window:(NSWindow *)window setCanToggleFullScreen:(BOOL)flag
{
	if (flag)
	{
		[window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	}
	else
	{
		[window setCollectionBehavior:NSWindowCollectionBehaviorDefault];
	}
}

#endif


/* popover tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
/** popover a NSWindow */
+ (NSPopover*)popoverWindow:(NSWindow *)window
			 relativeToView:(NSView *)view
				 controller:(NSViewController *)controller
				 appearance:(NSPopoverAppearance)appearance
			  preferredEdge:(NSRectEdge)edge
					 offset:(NSPoint)offset
				   delegate:(id<NSPopoverDelegate>)delegate
{
	if (window && view && controller)
	{}
	else
	{
		return nil;
	}
	
	NSRect showRect = [view bounds];
	NSPopover *ret;
	
	showRect.origin = NSMakePoint(offset.x, offset.y);
	ret = [[NSPopover alloc] init];
	
	if (ret)
	{
		if (delegate) {
			[ret setDelegate:delegate];
		}
		
		[ret setContentViewController:controller];
		[ret setAppearance:appearance];
		[ret setAnimates:YES];
		[ret setBehavior:NSPopoverBehaviorTransient];
		
		
		[ret showRelativeToRect:showRect ofView:view preferredEdge:edge];
	}
	
	return ret;
}
#endif


/* UNIX tools */
+(const char *)cStrError
{
	int errnoCopy = errno;
	return strerror(errnoCopy);
}

+(NSString *)strError
{
	int errnoCopy = errno;
	return [NSString stringWithUTF8String:strerror(errnoCopy)];
}

+(NSString *)configValueFromFileURL:(NSURL *)pathURL
					  withParameter:(NSString *)parameter
{
	return [AMCTools configValueFromFile:[pathURL path]
						   withParameter:parameter];
}

+(NSString *)configValueFromBundleFile:(NSString *)fileName
							 extension:(NSString *)extension
							 parameter:(NSString *)parameter
{
	NSURL *fileURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:extension];
	return [AMCTools configValueFromFileURL:fileURL
							  withParameter:parameter];
}

+(NSString *)configValueFromFile:(NSString *)path
				   withParameter:(NSString *)parameter
{
	const char *cPath = [path UTF8String];
	const char *cPara = [[parameter uppercaseString] UTF8String];
	char buff[CFG_CONFIG_READ_TOOL_BUFFER_LEN];
	size_t paraLen = [parameter length];
	size_t lineLen;
	FILE *fileFd = NULL;
	//struct stat dummyFileStat;
	BOOL isValueFound = NO;
	
	NSString *ret = nil;
	
	/* open file *//*
	if (0 != stat(cPath, &dummyFileStat))
	{
		NSLog(@"stat() %@: %@", path, [AMCTools strError]);
		return nil;
	}*/
	
	
	fileFd = fopen(cPath, "r");
	if(!fileFd)
	{
		NSLog(@"fopen() %@: %@", path, [AMCTools strError]);
		return nil;
	}
	
	/* read configuration */
	while((!feof(fileFd)) && (!isValueFound))
	{
		@autoreleasepool {
			size_t tmp;
			
			fgets(buff, sizeof(buff), fileFd);
			if ('\0' == buff[sizeof(buff) - 1])
			{
				break;
			}
			
			/* get a line */
			lineLen = strlen(buff);
			if ((0 == lineLen) || ('#' == buff[0]))
			{
				continue;	/* !!!!!!! */
			}
			
			while(('\n' == buff[lineLen - 1]) ||
				  ('\r' == buff[lineLen - 1]))
			{
				buff[lineLen - 1] = '\0';
				lineLen --;
			}
			
			//NSLog(@"Get line: %s", buff);
			
			/* upper case the parameter */
			for (tmp = 0;
				 (tmp < lineLen) || ('=' != buff[tmp]);
				 tmp++)
			{
				if ((buff[tmp] >= 'a') && (buff[tmp] <= 'z'))
				{
					buff[tmp] += 'A' - 'a';
				}
			}
			
			/* compare */
			if (0 == strncmp(cPara, buff, paraLen))
			{
				isValueFound = YES;
				
				/* fetch value sector */
				for (tmp = paraLen; tmp < lineLen; tmp++)
				{
					if ('=' == buff[tmp])
					{
						tmp++;
						break;
					}
				}	// end: for (tmp = paraLen...)
				
				if (tmp >= lineLen)
				{
					/* no parameter values */
					ret = @"";
				}
				else
				{
					/* skip blank */
					for (/**/; tmp < lineLen; tmp++)
					{
						if ((' ' != buff[tmp]) &&
							('\t' != buff[tmp]))
						{
							break;
						}
					}
					ret = [NSString stringWithUTF8String:buff+tmp];
				}
			}	// end: compare
		}	// end: autoreleasepool
	}	//end: while(...)
	
	
ENDS:
	if (fileFd)
	{
		fclose(fileFd);
	}
	return ret;
}

/* NSString Tools */
+ (BOOL)stringIsEmpty:(NSString *)string
{
	if (nil == string)
	{
		return YES;
	}
	else if ([string isKindOfClass:[NSAttributedString class]] ||
			 [string isKindOfClass:[NSString class]])
	{
		/* continue */
	}
	else
	{
		return YES;
	}
	
	if (0 == [string length])
	{
		return YES;
	}
	
	if ('\n' == [string characterAtIndex:0])
	{
		return YES;
	}
	
	if ('\r' == [string characterAtIndex:0])
	{
		return YES;
	}
	
	return NO;
}

+ (BOOL)stringIsValid:(NSString *)string
{
	return (![AMCTools stringIsEmpty:string]);
}

+ (BOOL)stringIsValidIPv4:(NSString *)IP
{
	/**********/
	/* variables */
	NSArray *IPParts;
	NSString *part;
	NSUInteger tmp;
	NSInteger integerPart;
	BOOL isOK;
	
	/**********/
	/* basic check */
	if (!IP)
	{
		return NO;
	}
	else if (NO == [IP isKindOfClass:[NSString class]])
	{
		return NO;
	}
	else
	{
		/* continue */
	}
	
	/**********/
	/* IP components amount check */
	IPParts = [IP componentsSeparatedByString:@"."];
	if (4 != [IPParts count])
	{
		AMCRelease(IPParts);
		return NO;
	}
	else
	{
		/* continue */
	}
	
	/**********/
	/* parts check */
	for (tmp = 0, isOK = YES;
		 (tmp < 4) && (YES == isOK);
		 tmp++)
	{
		part = [IPParts objectAtIndex:tmp];
		integerPart = [part integerValue];
		if (NO == [part isEqualToString:[NSString stringWithFormat:@"%ld", integerPart]])
		{
			isOK = NO;
		}
		else if ((integerPart < 0) ||
				 (integerPart > 255))
		{
			isOK = NO;
		}
		else
		{
			/* continue */
		}
		AMCRelease(part);
	}
	
	/**********/
	/* ENDS */
	AMCRelease(IPParts);
	return isOK;
}

+(BOOL)stringIsValidMAC:(NSString*)MACString
				 MACInt:(uint64_t*)pMacInt;
{
	/**********/
	/* variables */
	NSArray *MACParts;
	NSString *part;
	uint64_t intPart;
	BOOL isOK;
	NSUInteger tmp;
	uint64_t macInteger;
	NSScanner *scanner;
	
	/**********/
	/* basic check */
	if (!MACString)
	{
		return NO;
	}
	else if (17 != [MACString length])
	{
		return NO;
	}
	else
	{
		/* continue */
	}
	
	/**********/
	/* fetch components */
	MACParts = [MACString componentsSeparatedByString:@"-"];
	if (6 != [MACParts count])
	{
		AMCRelease(MACParts);
		MACParts = [MACString componentsSeparatedByString:@":"];
		if (6 != [MACParts count])
		{
			AMCRelease(MACParts);
			return NO;
		}
	}
	
	/**********/
	/* analyze cameras */
	for (tmp = 0, isOK = YES, macInteger = 0;
		 (NO != isOK) && (tmp < 6);
		 tmp++)
	{
		part = [[MACParts objectAtIndex:tmp] uppercaseString];
		scanner = [NSScanner scannerWithString:part];
		[scanner scanHexLongLong:&intPart];
		
		if ([part isEqualToString:[NSString stringWithFormat:@"%02llX", intPart]])
		{
			macInteger += (intPart << (40 - tmp * 8));
		}
		else
		{
			macInteger = 0;
			isOK = NO;
		}
		
		AMCRelease(part);
		AMCRelease(scanner);
	}
	
	/**********/
	/* return */
	if (isOK && pMacInt)
	{
		*pMacInt = macInteger;
	}
	
	return isOK;
}

+ (BOOL)string:(NSString*)str
isContainsSubString:(NSString*)subStr;
{
	if ((nil == str) ||
		(nil == subStr))
	{
		return NO;
	}
	
	if (NSNotFound == [str rangeOfString:subStr].location)
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

+ (BOOL)isIPv4:(NSString *)firstIP andIPv4:(NSString *)secondIP atTheSameSubnetMask:(NSString *)subnetMask
{
	NSUInteger ip01Integer, ip02Integer, maskInteger;
	
//	if ((NO == [AMCTools stringIsValidIPv4:firstIP]) ||
//		(NO == [AMCTools stringIsValidIPv4:secondIP] ||
//		 (NO == [AMCTools stringIsValidIPv4:subnetMask])))
//	{
//		return NO;
//	}
//	else
//	{}
	
	ip01Integer = [AMCTools integerFromIPString:firstIP];
	ip02Integer = [AMCTools integerFromIPString:secondIP];
	maskInteger = [AMCTools integerFromIPString:subnetMask];

	if ((ip01Integer & maskInteger) == (ip02Integer & maskInteger))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

+ (NSUInteger)integerFromIPString:(NSString*)anIP
{
	NSUInteger ret = 0;
	NSArray *numberPart = [anIP componentsSeparatedByString:@"."];
	if ([numberPart count] < 4)
	{
		return 0;
	}
	
	ret += ([(NSString*)[numberPart objectAtIndex:0] integerValue] & 0xFF) << 24;
	ret += ([(NSString*)[numberPart objectAtIndex:1] integerValue] & 0xFF) << 16;
	ret += ([(NSString*)[numberPart objectAtIndex:2] integerValue] & 0xFF) << 8;
	ret += ([(NSString*)[numberPart objectAtIndex:3] integerValue] & 0xFF) << 0;
	
	return ret;
}

+ (NSRange)findSubString:(NSString *)subString inString:(NSString *)string
{
	return [string rangeOfString:subString];
}

+ (NSString *)subStringIn:(NSString *)string
	  withStartIdentifier:(NSString *)start
		 endingIdentifier:(NSString *)ending
{
	/**********/
	/* lets check whether there are identifiers */
	NSRange startRange, endRange;
	startRange = [string rangeOfString:start];
	endRange = [string rangeOfString:ending];
	
	if ((NSNotFound == startRange.location) ||
		(NSNotFound == startRange.location))
	{
		return nil;
	}
	else if ((startRange.location + startRange.length) > endRange.location)
	{
		return nil;
	}
	else
	{
		startRange = [AMCTools _getRangeInString:string
							 withStartIdentifier:start
								endingIdentifier:ending];
		if (NSNotFound == startRange.location)
		{
			return nil;
		}
		else
		{
			return [string substringWithRange:startRange];
		}
	}
}

+ (NSRange)rangeOfSubStringIn:(NSString *)string
		  withStartIdentifier:(NSString *)start
			 endingIdentifier:(NSString *)ending
{
	NSRange startRange, endRange;
	startRange = [string rangeOfString:start];
	endRange = [string rangeOfString:ending];
	
	if ((NSNotFound == startRange.location) ||
		(NSNotFound == startRange.location))
	{
		return NSMakeRange(NSNotFound, 0);
	}
	else if ((startRange.location + startRange.length) > endRange.location)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	else
	{
		return [AMCTools _getRangeInString:string
					   withStartIdentifier:start
						  endingIdentifier:ending];
	}
}


+ (NSDictionary *)dictionaryWithXMLLikeString:(NSString *)inputString
{
	NSDictionary *ret = nil;
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	NSString *stringWithoutWhite = [AMCTools stringWithoutWhitespaceAndReturns:inputString];
	NSRange nextKeyValueRange = NSMakeRange(0, 0);
	NSString *key, *value;
	NSDictionary *valueDict;

	if ([AMCTools stringIsEmpty:stringWithoutWhite])
	{
		AMCRelease(stringWithoutWhite);
		return nil;
	}
	else
	{
		/* continue */
	}
	
	/* start analyzing */
	do
	{@autoreleasepool {
		nextKeyValueRange = [self _searchStringToFindValidKeyValue:stringWithoutWhite
													  fromLocation:nextKeyValueRange.location
															   key:&key
															 value:&value];
		if (NSNotFound == nextKeyValueRange.location)
		{
			/* searching ends */
		}
		else
		{
			/* is attribute an dictionary? */
			NSRange internalSearch;
			internalSearch = [self _searchStringToFindValidKeyValue:stringWithoutWhite
													   fromLocation:nextKeyValueRange.location + [key length] + 2
																key:nil
															  value:nil];
			if (NSNotFound == internalSearch.location)
			{
				/* append an attribute */
				[dictionary setObject:value forKey:key];
			}
			else
			{
				/* append an dictionary */
				valueDict = [AMCTools dictionaryWithXMLLikeString:value];
				[dictionary setObject:valueDict forKey:key];
			}
			
			AMCRelease(valueDict);
			AMCRelease(value);
			AMCRelease(key);
			
			/* prepare for next search */
			nextKeyValueRange.location += nextKeyValueRange.length;
		}
	}} while (NSNotFound != nextKeyValueRange.location);
	
	ret = [NSDictionary dictionaryWithDictionary:dictionary];
	AMCRelease(stringWithoutWhite);
	AMCRelease(dictionary);
	return ret;
}


+ (NSRange)_searchStringToFindValidKeyValue:(NSString*)string
							   fromLocation:(NSUInteger)location
										key:(NSString*__autoreleasing*)pKey
									  value:(NSString*__autoreleasing*)pValue
{
	/**********/
	/* variables */
	NSString *stringToSearch;
	NSRange startRange, valueRange;
	NSUInteger tmp;
	NSString *key;
	
	/**********/
	/* get sub-string */
	if (location >= [string length])
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	stringToSearch = [[NSString alloc] initWithBytesNoCopy:(void*)([string UTF8String] + location)
													length:([string length] - location)
												  encoding:NSUTF8StringEncoding
											  freeWhenDone:NO];
	if (!stringToSearch)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	/**********/
	/* search for first keys */
	startRange = [stringToSearch rangeOfString:@"<"];
	
	valueRange.location = startRange.location + startRange.length;
	valueRange.length = 0;
	
	if (NSNotFound == valueRange.location)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	/* search until '>' found */
	for (tmp = valueRange.location;
		 ('>' != [stringToSearch UTF8String][tmp]) && (tmp < [stringToSearch length]);
		 valueRange.location ++, tmp++)
	{
		/* nothing to do in the loop */
	}
	valueRange.location ++;
	
	/* check range */
	if (valueRange.location < [stringToSearch length])
	{
		/* OK, continue */
	}
	else
	{
		AMCRelease(stringToSearch);
		return NSMakeRange(NSNotFound, 0);
	}
	
	/**********/
	/* fetch the key */
	key = [stringToSearch substringWithRange:NSMakeRange(startRange.location + startRange.length,
														 valueRange.location - startRange.location - startRange.length - 1)];
	valueRange = [AMCTools rangeOfSubStringIn:stringToSearch
						  withStartIdentifier:[NSString stringWithFormat:@"<%@>", key]
							 endingIdentifier:[NSString stringWithFormat:@"</%@>", key]];
	if (NSNotFound == valueRange.location)
	{
		AMCRelease(key);
		AMCRelease(stringToSearch);
		return valueRange;		/* RETURN !!! */
	}
	else
	{
		/* continue */
	}
	
	/**********/
	/* assign key and value */
	if (pKey)
	{
		*pKey = key;
	}
	
	if (pValue)
	{
		*pValue = [stringToSearch substringWithRange:valueRange];
	}
	
	/* convert local "startRange" to global one comparaing to "string" */
	startRange.location += location;
	startRange.length = 0;
	startRange.length += [key length] + 2;		/* starting identifier */
	startRange.length += startRange.length + 1;				/* ending identifier */
	startRange.length += valueRange.length;					/* value length */
	
	/**********/
	/* successful ENDING */
	return startRange;
}


+ (NSDictionary *)dictionaryWithJsonString:(NSString *)string
{
	return [NSJSONSerialization JSONObjectWithData:[AMCTools dataWithString:string]
										   options:kNilOptions
											 error:NULL];
}


+ (NSDictionary *)dictionaryWithJsonData:(NSData *)data
{
	return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:NULL];
}


+(NSString *)stringWithoutWhitespaceAndReturns:(NSString *)string
{
	/* http://http://stackoverflow.com/questions/10978795/remove-n-from-nsstring */
	NSScanner *scanner = [[NSScanner alloc] initWithString:string];
	NSMutableString *result = [NSMutableString stringWithCapacity:[string length]];
	NSString *tmpString = nil;
	NSCharacterSet *charsToDelete = [NSCharacterSet characterSetWithCharactersInString:
									 [NSString stringWithFormat:@"\t\n\r%C%C%C%C",
									  (unichar)0x0085, (unichar)0x000C, (unichar)0x2028, (unichar)0x2029]];
	NSString *finalString = nil;
	
	while (NO == [scanner isAtEnd])
	{
		[scanner scanUpToCharactersFromSet:charsToDelete intoString:&tmpString];
		
		if (tmpString)
		{
			[result appendString:tmpString];
			AMCRelease(tmpString);
		}
		
		if ([scanner scanCharactersFromSet:charsToDelete intoString:NULL])
		{
			if (([result length] > 0) &&
				(NO == [scanner isAtEnd]))
			{
				/* do nothing or append whitespace */
			}
		}
	}
	
	finalString = [NSString stringWithString:result];
	AMCRelease(result);
	AMCRelease(scanner);
	AMCRelease(charsToDelete);
	
	return finalString;
}


+ (NSString *)string:(NSString *)string withoutSpecifiedCharecterIn:(NSString *)characters
{
	/* http://http://stackoverflow.com/questions/10978795/remove-n-from-nsstring */
	NSScanner *scanner = [[NSScanner alloc] initWithString:string];
	NSMutableString *result = [NSMutableString stringWithCapacity:[string length]];
	NSString *tmpString = nil;
	NSCharacterSet *charsToDelete = [NSCharacterSet characterSetWithCharactersInString:characters];
	NSString *finalString = nil;
	
	while (NO == [scanner isAtEnd])
	{
		[scanner scanUpToCharactersFromSet:charsToDelete intoString:&tmpString];
		
		if (tmpString)
		{
			[result appendString:tmpString];
			AMCRelease(tmpString);
		}
		
		if ([scanner scanCharactersFromSet:charsToDelete intoString:NULL])
		{
			if (([result length] > 0) &&
				(NO == [scanner isAtEnd]))
			{
				/* do nothing or append whitespace */
			}
		}
	}
	
	finalString = [NSString stringWithString:result];
	AMCRelease(result);
	AMCRelease(scanner);
	AMCRelease(charsToDelete);
	
	return finalString;
}


+ (NSRange)_getRangeInString:(NSString*)string
		 withStartIdentifier:(NSString*)start
			endingIdentifier:(NSString*)ending
{
	NSRange currentRange, subRange, endingRange;
	const char *bytes = [string UTF8String];
	NSString *stringToSearch;
	
	/* get starting string firstly */
	currentRange = [string rangeOfString:start];
	
	/* check whether there are any other starting string secondly */
	stringToSearch = [[NSString alloc] initWithBytesNoCopy:(void*)(bytes + currentRange.location + currentRange.length)
													length:([string length] - currentRange.location - currentRange.length)
												  encoding:NSUTF8StringEncoding
											  freeWhenDone:NO];
	subRange = [stringToSearch rangeOfString:start];
	endingRange = [stringToSearch rangeOfString:ending];
	
	if ((NSNotFound != subRange.location) &&
		(subRange.location < endingRange.location))
	{
		/* find string in next nest */
		subRange = [AMCTools _getRangeInString:stringToSearch
						   withStartIdentifier:start
							  endingIdentifier:ending];
		if (NSNotFound == subRange.location)
		{
			AMCRelease(stringToSearch);
			return NSMakeRange(NSNotFound, 0);		/* RETURN !!! */
		}
		else
		{
			subRange.length += [ending length];
		}
	}
	else
	{
		/* no more nested identifiers, continue */
		subRange.location = 0;
		subRange.length = 0;
	}
	
	/* find ending range */
	stringToSearch = [[NSString alloc] initWithBytesNoCopy:(void*)([stringToSearch UTF8String] + subRange.location + subRange.length)
													length:([stringToSearch length] - subRange.location - subRange.length)
												  encoding:NSUTF8StringEncoding
											  freeWhenDone:NO];
	endingRange = [stringToSearch rangeOfString:ending];
	
	
	/* return */
	if (NSNotFound == endingRange.location)
	{
		currentRange = NSMakeRange(NSNotFound, 0);
	}
	else
	{
		currentRange = NSMakeRange(currentRange.location + currentRange.length,
								   endingRange.location + subRange.location + subRange.length);
//		AMCDebug(@"Get string: \"%@\"", [string substringWithRange:currentRange]);
	}
	AMCRelease(stringToSearch);
	return currentRange;
}


+ (BOOL)data:(NSData *)data
isContainsSubData:(NSData *)subData
	 inRange:(NSRange)range
{
	if ((nil == data) ||
		(nil == subData))
	{
		return NO;
	}
	
	if (NSNotFound == [data rangeOfData:subData options:0 range:range].location)
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

+ (NSRange)findSubData:(NSData *)subData inData:(NSData *)data
{
	return [data rangeOfData:subData options:0 range:NSMakeRange(0, [data length])];
}

+ (NSData *)dataWithString:(NSString *)string
{
	return [string dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)stringWithData:(NSData *)data
{
	return  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSData *)dataBigEndianUnicodeWithString:(NSString *)string
{
	unichar *bytes = malloc([string length] * sizeof(unichar) + 16);
	NSData *retData;
	NSUInteger unicharCount = 0;
	NSUInteger tmp;
	
	if (NULL == bytes)
	{
		return nil;
	}
	
	/* generate bytes */
	for (tmp = 0; tmp < [string length]; tmp++, unicharCount++)
	{
		bytes[tmp] = htons([string characterAtIndex:tmp]);
	}
	bytes[unicharCount] = '\0';
	unicharCount ++;
	
	/* return data */
	retData = [[NSData alloc] initWithBytesNoCopy:bytes
										   length:(unicharCount * sizeof(unichar))
									 freeWhenDone:YES];
	if (retData)
	{
		return retData;
	}
	else
	{
		free(bytes);
		return nil;
	}
}

+ (NSData *)dataLittleEndianUnicodeWithString:(NSString *)string
{
	unichar *bytes = malloc([string length] * sizeof(unichar) + 16);
	NSData *retData;
	NSUInteger unicharCount = 0;
	NSUInteger tmp;
	
	if (NULL == bytes)
	{
		return nil;
	}
	
	/* generate bytes */
	if ([AMCTools isSystemLittleEndian])
	{
		for (tmp = 0; tmp < [string length]; tmp++, unicharCount++)
		{
			bytes[tmp] = [string characterAtIndex:tmp];
		}
	}
	else
	{
		for (tmp = 0; tmp < [string length]; tmp++, unicharCount++)
		{
			bytes[tmp] = htons([string characterAtIndex:tmp]);
		}
	}
	
	bytes[unicharCount] = '\0';
	unicharCount ++;
	
	/* return data */
	retData = [[NSData alloc] initWithBytesNoCopy:bytes
										   length:(unicharCount * sizeof(unichar))
									 freeWhenDone:YES];
	if (retData)
	{
		return retData;
	}
	else
	{
		free(bytes);
		return nil;
	}
}


+ (BOOL)writeData:(NSData *)data withFileHandle:(NSFileHandle *)fileHandle
{
	BOOL ret = YES;
	
	if ((nil == fileHandle) ||
		(nil == data))
	{
		return NO;
	}
	
	@try
	{
		[fileHandle writeData:data];
	}
	@catch (NSException *exception)
	{
		ret = NO;
	}

	return ret;
}


+ (BOOL)string:(NSString *)string matchesRegularExpression:(NSString *)regex
{
	if (string && regex)
	{
		NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
		BOOL ret = [pred evaluateWithObject:string];
		pred = nil;
		return ret;
	}
	else
	{
		return NO;
	}
}



+ (NSSize)string:(NSString *)str sizeWithSystemFontSize:(CGFloat)size
{
	NSSize textSize;
	NSDictionary *attribute;
	NSFont *font;
	
	font = [NSFont systemFontOfSize:size];
	attribute = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	textSize = [str sizeWithAttributes:attribute];
	
	font = nil;
	attribute = nil;
	return textSize;
}


+ (NSSize)string:(NSString *)str sizeWithFontName:(NSString *)name size:(CGFloat)size
{
	NSSize textSize;
	NSDictionary *attribute;
	NSFont *font;
	
	font = [NSFont fontWithName:name size:size];
	attribute = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	textSize = [str sizeWithAttributes:attribute];
	
	font = nil;
	attribute = nil;
	return textSize;
}

+ (NSSize)string:(NSString *)str sizeWithFont:(NSFont *)font
{
	NSSize textSize;
	NSDictionary *attribute;
	
	attribute = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	textSize = [str sizeWithAttributes:attribute];
	
	font = nil;
	attribute = nil;
	return textSize;
}


+(NSString *)string:(NSString *)string cutShortInSystemFontWithWidth:(CGFloat)width size:(CGFloat)fontSize
{
	NSSize textSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
	NSFont *font = [NSFont systemFontOfSize:fontSize];
	NSUInteger length;
	NSString *subString;
	
	/* Firstly, check if the width is too short */
	textSize = [AMCTools string:@"..." sizeWithSystemFontSize:fontSize];
	if (textSize.width > width)
	{
		AMCRelease(font);
		return @"...";
	}
	
	/* Secondly, check if the input string is short enough */
	textSize = [AMCTools string:string sizeWithSystemFontSize:fontSize];
	if (textSize.width < width)
	{
		AMCRelease(font);
		return string;
	}
	
	/* Thirdly, find the closest sub-string of the string */
	/* Note: This algorithm is not smart enough */
	length = [string length];
	length = (NSInteger)((CGFloat)length * (width / textSize.width));
	
	subString = [string substringWithRange:NSMakeRange(0, length)];
	textSize = [AMCTools string:subString sizeWithSystemFontSize:fontSize];
	if (textSize.width > width)
	{
		while (textSize.width > width)
		{@autoreleasepool {
			length --;
			AMCRelease(subString);
			subString = [string substringWithRange:NSMakeRange(0, length)];
			textSize = [AMCTools string:subString sizeWithSystemFontSize:fontSize];
		}}
	}
	else
	{
		while (textSize.width < width)
		{@autoreleasepool {
			length ++;
			AMCRelease(subString);
			subString = [string substringWithRange:NSMakeRange(0, length)];
			textSize = [AMCTools string:subString sizeWithSystemFontSize:fontSize];
		}}
	}
	
	/* calculate string size with "..." */
	subString = [NSString stringWithFormat:@"%@...", subString];
	textSize = [AMCTools string:subString sizeWithSystemFontSize:fontSize];
	while (textSize.width > width)
	{@autoreleasepool {
		length --;
		subString = [NSString stringWithFormat:@"%@...", [string substringWithRange:NSMakeRange(0, length)]];
		textSize = [AMCTools string:subString sizeWithSystemFontSize:fontSize];
	}}
	
	/* END */
	AMCRelease(font);
	return subString;
}


+ (NSString *)string:(NSString *)string cutShortWithWidth:(CGFloat)width inFontName:(NSString *)fontName size:(CGFloat)fontSize
{
	NSSize textSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
	NSFont *font = [NSFont fontWithName:fontName size:fontSize];
	NSUInteger length;
	NSString *subString;
	
	/* Firstly, check if the width is too short */
	textSize = [AMCTools string:@"..." sizeWithFontName:fontName size:fontSize];
	if (textSize.width > width)
	{
		AMCRelease(font);
		return @"...";
	}
	
	/* Secondly, check if the input string is short enough */
	textSize = [AMCTools string:string sizeWithFontName:fontName size:fontSize];
	if (textSize.width < width)
	{
		AMCRelease(font);
		return string;
	}
	
	/* Thirdly, find the closest sub-string of the string */
	/* Note: This algorithm is not smart enough */
	length = [string length];
	length = (NSInteger)((CGFloat)length * (width / textSize.width));
	
	subString = [string substringWithRange:NSMakeRange(0, length)];
	textSize = [AMCTools string:subString sizeWithFontName:fontName size:fontSize];
	if (textSize.width > width)
	{
		while (textSize.width > width)
		{@autoreleasepool {
			length --;
			AMCRelease(subString);
			subString = [string substringWithRange:NSMakeRange(0, length)];
			textSize = [AMCTools string:subString sizeWithFontName:fontName size:fontSize];
		}}
	}
	else
	{
		while (textSize.width < width)
		{@autoreleasepool {		
			length ++;
			AMCRelease(subString);
			subString = [string substringWithRange:NSMakeRange(0, length)];
			textSize = [AMCTools string:subString sizeWithFontName:fontName size:fontSize];
		}}
	}
	
	/* calculate string size with "..." */
	subString = [NSString stringWithFormat:@"%@...", subString];
	textSize = [AMCTools string:subString sizeWithFontName:fontName size:fontSize];
	while (textSize.width > width)
	{@autoreleasepool {
		length --;
		subString = [NSString stringWithFormat:@"%@...", [string substringWithRange:NSMakeRange(0, length)]];
		textSize = [AMCTools string:subString sizeWithFontName:fontName size:fontSize];
	}}
	
	/* END */
	AMCRelease(font);
	return subString;
}


+ (BOOL)keyIsReturnKey:(unichar)key
{
	switch (key)
	{
		case '\r':
		case '\n':
		case (unichar)3:
			return YES;
			break;
			
		default:
			return NO;
			break;
	}
}

+ (BOOL)keyIsEscapeKey:(unichar)key
{
	switch (key)
	{
		case (unichar)27:
			return YES;
			break;
			
		default:
			return NO;
			break;
	}
}


+ (NSData*)_sha256:(NSData*)bytes
{
	NSMutableData *md = [NSMutableData dataWithLength:32];
	unsigned char *result = [md mutableBytes];
	if (result != CC_SHA256([bytes bytes], (CC_LONG)[bytes length], result))
	{
		AMCRelease(md);
		return nil;
	}
	else
	{
		return md;
	}
}

+ (NSData*)_dataCipheredFrom:(NSData*)dataIn
					 withKey:(NSData*)aKey
				   operation:(CCOperation)operation
{
	const CCOptions options = kCCOptionPKCS7Padding;
	NSData *key = aKey;
	NSUInteger dataLength = [dataIn length];
	NSUInteger capacity = (dataLength / kCCBlockSizeAES128 + 1) * kCCBlockSizeAES128;
	NSMutableData *dataRet;
	CCCryptorStatus ccStatus;
	size_t dataOutMoved;
	
	/* check key length */
	if ([key length] > kCCKeySizeAES256)
	{
		AMCRelease(key);
		return nil;
	}
	else if ([key length] < kCCKeySizeAES256)
	{
		AMCRelease(key);
		key = [AMCTools _sha256:aKey];
		if (!key)
		{
			NSLog(@"AES: Failed to convert key.");
			return nil;
		}
	}
	else
	{
		/* null */
	}
	//AMCDebug(@"Key: %@", [AMCTools descriptionReadableForNSData:key]);
	
	/* allocate return data */
	dataRet = [NSMutableData dataWithCapacity:capacity];
	[dataRet setLength:capacity];
	
	/* encryption */
	ccStatus = CCCrypt(operation,
					   kCCAlgorithmAES128,
					   options,
					   [key bytes],
					   [key length],
					   [[NSMutableData dataWithLength:kCCBlockSizeAES128] bytes],
					   [dataIn bytes],
					   [dataIn length],
					   [dataRet mutableBytes],
					   capacity,
					   &dataOutMoved);
	if (dataOutMoved < [dataRet length])
	{
		[dataRet setLength:dataOutMoved];
	}
	
	/* final check */
	if (kCCSuccess == ccStatus)
	{
		AMCRelease(key);
		return dataRet;
	}
	else
	{
		switch (ccStatus)
		{
			case kCCParamError:
				NSLog(@"AES: Illegal parameter.");
				break;
				
			case kCCBufferTooSmall:
				NSLog(@"AES: Buffer size si too small.");
				break;
				
			case kCCMemoryFailure:
				NSLog(@"AES: Fail to allocate memory.");
				break;
				
			case kCCAlignmentError:
				NSLog(@"AES: Size is not aligned correctly.");
				break;
				
			case kCCDecodeError:
				NSLog(@"AES: Failed to encrypt data.");
				break;
				
			case kCCUnimplemented:
				NSLog(@"AES: Unsupported operation.");
				break;
				
			default:
				NSLog(@"AES: Unknown error.");
				break;
		}
		
		AMCRelease(key);
		return nil;
	}
}

+ (NSData *)dataEncrypedFrom:(NSData *)plainData withKey:(NSData *)key
{	
	return [AMCTools _dataCipheredFrom:plainData withKey:key operation:kCCEncrypt];
}

+ (NSData *)dataDecrypedFrom:(NSData *)encrypedData withKey:(NSData *)key
{
	return [AMCTools _dataCipheredFrom:encrypedData withKey:key operation:kCCDecrypt];
}

+ (NSAttributedString *)string:(NSString *)string withColor:(NSColor *)color
{
	return [[NSAttributedString alloc] initWithString:string
										   attributes:[NSDictionary dictionaryWithObject:color
																				  forKey:NSForegroundColorAttributeName]];
}

#if CFG_FRAMEWORK_SECURITY
+ (BOOL)authorize
{
    BOOL returnFlag;
    AuthorizationItem authItem[1];
    AuthorizationRights authRights;
    AuthorizationFlags authFlags;
    AuthorizationRef authRef = NULL;
    OSStatus authStatus;
    
    authItem[0].name = "com.laplacezhang.www.AMCTest.testRight";
    authItem[0].valueLength = 0;
    authItem[0].value = NULL;
    authItem[0].flags = 0;
    
    authRights.count = 1;
    authRights.items = authItem;
    
    authFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
    
    authStatus = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, authFlags, &authRef);
    
    AMCDebug(@"Auth Status: %@", [[AMCTools errorFromOSStatus:authStatus] description]);
    
    if (errAuthorizationSuccess == authStatus)
    {
        returnFlag = YES;
    }
    else
    {
        returnFlag = NO;
    }
    
    if (authRef)
    {
        AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
    }
    
    return returnFlag;
}
#endif

/* save/open panel tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSURL *)fileSaveURLWithExtension:(NSString*)extension
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	NSInteger panelRet;
	
	if ([AMCTools stringIsEmpty:extension])
	{
		extension = nil;
		return nil;
	}
	
	// check extension
	if ('.' == [extension characterAtIndex:0])
	{
		extension = [extension substringFromIndex:1];
	}
	if (extension)
	{
		[panel setAllowedFileTypes:[NSArray arrayWithObject:extension]];
	}
	[panel setShowsHiddenFiles:NO];
	[panel setExtensionHidden:YES];
	
	panelRet = [panel runModal];
	if (NSModalResponseOK == panelRet)
	{
		return [panel URL];
	}
	else
	{
		return nil;
	}
}

+ (NSURL *)fileSaveURLWithExtension:(NSString *)extension
						   delegate:(id<NSOpenSavePanelDelegate>)delegate
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	NSInteger panelRet;
	
	if ([AMCTools stringIsEmpty:extension])
	{
		extension = nil;
		return nil;
	}
	
	// check extension
	if ('.' == [extension characterAtIndex:0])
	{
		extension = [extension substringFromIndex:1];
	}
	if (extension)
	{
		[panel setAllowedFileTypes:[NSArray arrayWithObject:extension]];
	}
	[panel setShowsHiddenFiles:NO];
	[panel setExtensionHidden:YES];
	[panel setDelegate:delegate];
	
	panelRet = [panel runModal];
	if (NSModalResponseOK == panelRet)
	{
		return [panel URL];
	}
	else
	{
		return nil;
	}
}

+ (NSURL *)fileOpenURLWithDelegate:(id<NSOpenSavePanelDelegate>)delegate
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	[panel setDelegate:delegate];
	
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	
	if (NSModalResponseOK == [panel runModal])
	{
		return [[panel URLs] objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}

+ (NSURL *)fileOpenURLDirectoryWithDelegate:(id<NSOpenSavePanelDelegate>)delegate;
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setDelegate:delegate];
	
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	
	if (NSModalResponseOK == [panel runModal])
	{
		return [[panel URLs] objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}


+ (NSURL *)fileOpenURLDirectoryWithBeginDirectory:(NSString *)directoryPath delegate:(id<NSOpenSavePanelDelegate>)delegate
{
	if (nil == directoryPath)
	{
		return [AMCTools fileOpenURLDirectoryWithDelegate:delegate];
	}
	else
	{
		NSOpenPanel *panel = [NSOpenPanel openPanel];
		[panel setDirectoryURL:[NSURL fileURLWithPath:directoryPath]];
		[panel setDelegate:delegate];
		
		[panel setCanChooseDirectories:YES];
		[panel setCanChooseFiles:NO];
		[panel setAllowsMultipleSelection:NO];
		
		if (NSModalResponseOK == [panel runModal])
		{
			return [[panel URLs] objectAtIndex:0];
		}
		else
		{
			return nil;
		}
	}
}


+ (NSURL *)fileOpenURLDirectoryWithBeginDirectory:(NSString *)directoryPath
							 canCreateDirectories:(BOOL)flag
										 delegate:(id<NSOpenSavePanelDelegate>)delegate
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	if (directoryPath)
	{
		[panel setDirectoryURL:[NSURL fileURLWithPath:directoryPath]];
	}
	
	[panel setCanCreateDirectories:flag];
	[panel setDelegate:delegate];
	
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	
	if (NSModalResponseOK == [panel runModal])
	{
		return [[panel URLs] objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}


#endif

/* NSTextField Set color tool */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (void)setTextField:(NSTextField *)textField
		  textColor:(NSColor *)color
{
	NSMutableAttributedString *preStr = [[NSMutableAttributedString alloc] initWithAttributedString:[textField attributedStringValue]];
	[preStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [[preStr string] length])];
	
	NSAttributedString *newStr = [[NSAttributedString alloc] initWithAttributedString:preStr];
	
	[textField setAttributedStringValue:newStr];
	
	[textField setTextColor:color];
	
	preStr = nil;
	newStr = nil;
}

+ (NSTextField *)makeATextFieldInLabelAppearance
{
	NSTextField *text = [[NSTextField alloc] init];
	[text setEditable:NO];
	[text setSelectable:NO];
	[text setBezeled:NO];
	[text setBordered:NO];
//	[text setAllowsEditingTextAttributes:YES];
//	[text setStringValue:@"00"];
//	[text setFrame:NSMakeRect(0.0, 0.0, 50.0, 13.0)];
	[text setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
	[text setDrawsBackground:NO];
//	[text setAlignment:NSCenterTextAlignment];
	[text setRefusesFirstResponder:YES];
	return text;
}

+ (NSRange)selectionForTextField:(NSTextField *)textField
{
	NSText *textEditor = [textField.window fieldEditor:YES forObject:textField];
	NSRange selection = [textEditor selectedRange];
	
	AMCRelease(textEditor);
	return selection;
}


+ (void)setTextField:(NSTextField *)textField selection:(NSRange)selection
{
	NSText *textEditor = [textField.window fieldEditor:YES forObject:textField];
	[textEditor setSelectedRange:selection];
	
	AMCRelease(textEditor);
	return;
}

#endif

/* NSButton set color tool */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (void)setButton:(NSButton *)button
	   titleColor:(NSColor *)color
{
	NSMutableAttributedString *preStr = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitle]];
	[preStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [[preStr string] length])];
	
	NSAttributedString *newStr = [[NSAttributedString alloc] initWithAttributedString:preStr];
	
	[button setAttributedTitle:newStr];
	
	preStr = nil;
	newStr = nil;
}
#endif

/* NSDate Tools */
+ (NSTimeInterval)time
{
	return [[NSDate date] timeIntervalSince1970];
}

+ (NSTimeInterval)timeDifferenceBetween:(NSTimeInterval)time1
								andTime:(NSTimeInterval)time2
{
	NSDate *date01, *date02;
	NSTimeInterval timeDiff;
	date01 = [NSDate dateWithTimeIntervalSince1970:time1];
	date02 = [NSDate dateWithTimeIntervalSince1970:time2];
	timeDiff = [date01 timeIntervalSinceDate:date02];
	date01 = nil;
	date02 = nil;
	
	return timeDiff;
}

+ (NSString *)timeStringForDate:(NSDate *)date
				 withDateFormat:(NSString *)format
{
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:format];
	NSString *dateString = [dateFormat stringFromDate:date];
	AMCRelease(dateFormat);
	return dateString;
}

+ (NSString *)timeStringForCurrentTimeWithDateFormat:(NSString *)format
{
	return [AMCTools timeStringForDate:[NSDate date]
						withDateFormat:format];
}


+ (void)addSystemClockChangeObserver:(id)target selector:(SEL)aSelector object:(id)anObject
{
	[[NSNotificationCenter defaultCenter] addObserver:target
											 selector:aSelector
												 name:NSSystemClockDidChangeNotification
											   object:anObject];
}

+ (void)removeSystemClockChangeObserver:(id)target object:(id)anObject
{
	[[NSNotificationCenter defaultCenter] removeObserver:target name:NSSystemClockDidChangeNotification object:anObject];
}


+ (NSTimeInterval)systemUpTime
{
	return [[NSProcessInfo processInfo] systemUptime];
}



+ (void)sleep:(NSTimeInterval)time
{
	if (time <= 0)
	{
		return;
	}
	
	unsigned int sec;
	useconds_t usec;
	sec = (unsigned int)time;
	usec = (useconds_t)([AMCTools timeDifferenceBetween:time
								   andTime:(NSTimeInterval)sec] * 1000000);
	
	usleep(usec);
	sleep(sec);
}

+ (void)sleepToNextSecond
{
	NSDate *date = [NSDate date];
	NSString *microSecString = [AMCTools timeStringForDate:date withDateFormat:@"SSSSSS"];
	NSUInteger microSeconds = 1001000 - [microSecString integerValue];
//	AMCPrintf("%s", [miliSecString UTF8String]);
	AMCRelease(date);
	AMCRelease(microSecString);
	usleep((useconds_t)microSeconds);
}


+ (void)sleepUntilSeconds:(NSUInteger)seconds
{
	if (0 == seconds)
	{}
	else if (1 == seconds)
	{
		[AMCTools sleepToNextSecond];
	}
	else
	{
		sleep((unsigned int)(seconds - 1));
		[AMCTools sleepToNextSecond];
	}
}


/* NSTableView tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (void)setTableView:(NSTableView *)tableView
withColumnIdentifier:(NSString *)identifier
			   title:(NSString *)title
{
	NSTableColumn *cell = nil;
	cell = [tableView tableColumnWithIdentifier:identifier];
	
	if (cell)
	{
		[[cell headerCell] setStringValue:title];
	}
	
	cell = nil;
}


#endif


/** NSView tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSView*) subViewWithIdentifier:(NSString*)identifier inView:(NSView*)superview
{
	NSArray *subviews = [superview subviews];
	NSView *ret;
	NSUInteger tmp;
	
	for (tmp = 0; tmp < [subviews count]; tmp++)
	{@autoreleasepool {
		ret = [subviews objectAtIndex:tmp];
		
		if ([identifier isEqualToString:[ret identifier]])
		{
			break;
		}
		else
		{
			AMCRelease(ret);
		}
	}}
	
	
	AMCRelease(subviews);
	return ret;
}


+ (NSImage *)screenshotPdfForView:(NSView *)view
{
	return [[NSImage alloc] initWithData:[view dataWithPDFInsideRect:[view bounds]]];
}


+ (void)drawLineFromPoint:(NSPoint)start toPoint:(NSPoint)end
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	path.lineWidth = 1.0;
	[path moveToPoint:start];
	[path lineToPoint:end];
	[path stroke];
	
	AMCRelease(path);
	return;
}


#endif



/** Status bar tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (CGFloat)statusBarThickness
{
	return [[NSStatusBar systemStatusBar] thickness];
}
#endif

/** Base-64 tools */
#if CFG_FRAMEWORK_SECURITY
// private method
+ (NSData*)base64Helper:(NSData*)input
			transformer:(SecTransformRef)transform;
{
	NSData *output = nil;
	
	if (!transform)
	{
		return nil;
	}
	
	if (SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFTypeRef)(input), NULL))
	{
		// !!!!!!! Check whether needs ownership in ARC
		output = (NSData*)CFBridgingRelease(SecTransformExecute(transform, NULL));
	}
	
	CFRelease(transform);
	
	return output;
}

#if 0
static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};
#endif

+ (NSString *)base64EncodeWith:(NSData *)input
{
#if 0
	const unsigned char * objRawData = [input bytes];
	char * objPointer;
	char * strResult;
	
	// Get the Raw Data length and ensure we actually have data
	NSUInteger intLength = [input length];
	if (intLength == 0) return nil;
	
	// Setup the String-based Result placeholder and pointer within that placeholder
	strResult = (char *)calloc(((intLength + 2) / 3) * 4, sizeof(char));
	objPointer = strResult;
	
	// Iterate through everything
	while (intLength > 2) { // keep going until we have less than 24 bits
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
		*objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
		*objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
		
		// we just handled 3 octets (24 bits) of data
		objRawData += 3;
		intLength -= 3;
	}
	
	// now deal with the tail end of things
	if (intLength != 0) {
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		if (intLength > 1) {
			*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
			*objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
			*objPointer++ = '=';
		} else {
			*objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
			*objPointer++ = '=';
			*objPointer++ = '=';
		}
	}
	
	// Terminate the string-based result
	*objPointer = '\0';
	
	// Return the results as an NSString object
	return [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
#endif
	
#if 1
	SecTransformRef transform = SecEncodeTransformCreate(kSecBase64Encoding, NULL);
	NSString *ret = nil;
	
	ret = [[NSString alloc] initWithData:[AMCTools base64Helper:input transformer:transform]
								encoding:NSASCIIStringEncoding];
	return ret;
#endif
}

+ (NSData *)base64DecodeWith:(NSString *)input
{
	SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
	NSData *ret = nil;
	
	ret = [AMCTools base64Helper:[input dataUsingEncoding:NSASCIIStringEncoding]
					 transformer:transform];
	return ret;
}

+ (NSString *)stringBase64EncodeWith:(NSString *)input
{
	return [AMCTools base64EncodeWith:[AMCTools dataWithString:input]];
}
			
+ (NSString *)stringBase64DecodeWith:(NSString *)input
{
	return [AMCTools stringWithData:[AMCTools base64DecodeWith:input]];
}
#endif


/* MD5 calculation */
+ (NSString *)MD5ChecksumStringWithData:(NSData *)data
{
	if ((nil == data) ||
		(NO == [data isKindOfClass:[NSData class]]) ||
		([data length] >= (NSUInteger)(0x100000000)))
	{
		return nil;
	}
	
	unsigned char resultCString[16];
	NSString *ret;
	
	CC_MD5([data bytes], (CC_LONG)[data length], resultCString);
	
	ret = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		   resultCString[0], resultCString[1], resultCString[2], resultCString[3],
		   resultCString[4], resultCString[5], resultCString[6], resultCString[7],
		   resultCString[8], resultCString[9], resultCString[10],resultCString[11],
		   resultCString[12],resultCString[13],resultCString[14],resultCString[15]];
	return ret;
}


+ (NSData *)MD5ChecksumDataWithData:(NSData *)data
{
	if ((nil == data) ||
		(NO == [data isKindOfClass:[NSData class]]) ||
		([data length] >= (NSUInteger)(0x100000000)))
	{
		return nil;
	}
	
	unsigned char resultCString[16];
	NSData *ret;
	
	CC_MD5([data bytes], (CC_LONG)[data length], resultCString); 
	
	ret = [NSData dataWithBytes:resultCString length:16];
	return ret;
}


+ (BOOL)data:(NSData *)data conformsMD5ChecksumString:(NSString *)md5String
{
	if (md5String && data)
	{}
	else
	{
		return NO;
	}
	
	BOOL ret;
	@autoreleasepool {
		ret = [md5String.lowercaseString isEqualToString:[AMCTools MD5ChecksumStringWithData:data]] ? YES : NO;
	}
	return ret;
}


+ (BOOL)data:(NSData *)data conformsMD5ChecksumData:(NSData *)md5Data
{
	if (data && md5Data)
	{}
	else
	{
		return NO;
	}
	
	BOOL ret;
	@autoreleasepool {
		ret = [md5Data isEqualToData:[AMCTools MD5ChecksumDataWithData:data]] ? YES : NO;
	}
	return ret;
}




+ (BOOL)isInMainThread
{
	return [[NSThread currentThread] isMainThread];
}

+ (BOOL)isSystemBigEndian
{
	union {
		uint32_t i;
		char c[4];
	}bint = {0x01020304};
	return bint.c[0] == 1;
}

+ (BOOL)isSystemLittleEndian
{
	return ![self isSystemBigEndian];
}

+ (NSString *)descriptionWithNSRect:(NSRect)rect
{
	return [NSString stringWithFormat:@"(%.1f, %.1f), %.1f*%.1f",
			rect.origin.x, rect.origin.y,
			rect.size.width, rect.size.height];
}

+ (NSString *)descriptionWithNSSize:(NSSize)size
{
	return [NSString stringWithFormat:@"%.1f*%.1f",
			size.width, size.height];
}

+ (NSString *)descriptionWithNSPoint:(NSPoint)point
{
	return [NSString stringWithFormat:@"(%.1f,%.1f)",
			point.x, point.y];
}

+ (NSString *)descriptionReadableForNSData:(NSData *)data
{
	NSMutableString *stringForData = [NSMutableString stringWithCapacity:[data length] * 8];
	NSMutableString *lineString, *tailString;
	NSUInteger tmp, column, dataLen;
	uint8_t *cData = (uint8_t*)[data bytes];
	uint8_t byte;
	
	if (!data)
	{
		return @"NSData <NULL>, length: 0\n";
	}
	
	[stringForData appendFormat:@"NSData <0x%08lX>, length: %ld\n", (NSUInteger)data, [data length]];
	dataLen = [data length];
	for (tmp = 0; (tmp + 16) <= dataLen; tmp += 16)
	{
		lineString = [NSMutableString stringWithCapacity:16*8];
		tailString = [NSMutableString stringWithCapacity:32];
		[lineString appendFormat:@"%08lX: ", tmp];
		for (column = 0; column < 16; column ++)
		{
			byte = cData[tmp + column];
			[lineString appendFormat:@"%02X ", byte];
			
			if (7 == column)
			{
				[lineString appendString:@" "];
			}
			
			//
			if ((byte >= '!') && (byte <= 0x7F))
			{
				[tailString appendFormat:@"%c", byte];
			}
			else if ('\n' == byte)
			{
				[tailString appendString:@"↲"];
			}
			else if ('\r' == byte)
			{
				[tailString appendString:@"↙"];
			}
			else if (' ' == byte)
			{
				[tailString appendFormat:@" "];
			}
			else
			{
				[tailString appendString:@"."];
			}
		}	/* ENDS: "for (column = 0; column < 16; column ++)" */
		
		[stringForData appendFormat:@"%@ %@\n", lineString, tailString];
		AMCRelease(lineString);
		AMCRelease(tailString);
	}
	
	/* last line */
	if (tmp < dataLen)
	{
		lineString = [NSMutableString stringWithCapacity:16*8];
		tailString = [NSMutableString stringWithCapacity:32];
		
		/* normal data */
		[lineString appendFormat:@"%08lX: ", tmp];
		for (/* null */; tmp < dataLen; tmp++)
		{
			byte = cData[tmp];
			[lineString appendFormat:@"%02X ", byte];
			
			if (0 == (tmp + 1) % 8)
			{
				[lineString appendString:@" "];
			}
			
			//
			if ((byte >= '!') && (byte <= 0x7F))
			{
				[tailString appendFormat:@"%c", byte];
			}
			else if ('\n' == byte)
			{
				[tailString appendString:@"↲"];
			}
			else if ('\r' == byte)
			{
				[tailString appendString:@"↙"];
			}
			else if (' ' == byte)
			{
				[tailString appendFormat:@" "];
			}
			else
			{
				[tailString appendString:@"."];
			}
		}
		
		/* remaining blanks */
		tmp = 16 - (tmp % 16);
		if (tmp > 7)
		{
			[lineString appendString:@"  "];
		}
		for (/* null */; tmp > 0; tmp --)
		{
			[lineString appendString:@"   "];
		}
		
		[stringForData appendFormat:@"%@ %@\n", lineString, tailString];
		AMCRelease(lineString);
		AMCRelease(tailString);
	}
	
	
	return stringForData;
}

+ (NSString *)descriptionReadableForBytes:(const void *)bytes
								   length:(NSUInteger)length
{
	NSMutableString *stringForData = [NSMutableString stringWithCapacity:length * 8];
	NSString *ret;
	NSMutableString *lineString, *tailString;
	NSUInteger tmp, column, dataLen;
	uint8_t *cData = (uint8_t*)bytes;
	uint8_t byte;
	
	[stringForData appendFormat:@"Bytes <0x%08lX>, length: %ld\n", (NSUInteger)bytes, length];
	dataLen = length;
	for (tmp = 0; (tmp + 16) <= dataLen; tmp += 16)
	{
		lineString = [NSMutableString stringWithCapacity:16*8];
		tailString = [NSMutableString stringWithCapacity:32];
		[lineString appendFormat:@"%08lX: ", tmp];
		for (column = 0; column < 16; column ++)
		{
			byte = cData[tmp + column];
			[lineString appendFormat:@"%02X ", byte];
			
			if (7 == column)
			{
				[lineString appendString:@" "];
			}
			
			//
			if ((byte >= '!') && (byte <= 0x7F))
			{
				[tailString appendFormat:@"%c", byte];
			}
			else if ('\n' == byte)
			{
				[tailString appendString:@"↲"];
			}
			else if ('\r' == byte)
			{
				[tailString appendString:@"↙"];
			}
			else
			{
				[tailString appendString:@"."];
			}
		}	/* ENDS: "for (column = 0; column < 16; column ++)" */
		
		[stringForData appendFormat:@"%@ %@\n", lineString, tailString];
		AMCRelease(lineString);
		AMCRelease(tailString);
	}
	
	/* last line */
	if (tmp < dataLen)
	{
		lineString = [NSMutableString stringWithCapacity:16*8];
		tailString = [NSMutableString stringWithCapacity:32];
		
		/* normal data */
		[lineString appendFormat:@"%08lX: ", tmp];
		for (/* null */; tmp < dataLen; tmp++)
		{
			byte = cData[tmp];
			[lineString appendFormat:@"%02X ", byte];
			
			if (0 == (tmp + 1) % 8)
			{
				[lineString appendString:@" "];
			}
			
			//
			if ((byte >= '!') && (byte <= 0x7F))
			{
				[tailString appendFormat:@"%c", byte];
			}
			else if ('\n' == byte)
			{
				[tailString appendString:@"↲"];
			}
			else if ('\r' == byte)
			{
				[tailString appendString:@"↙"];
			}
			else
			{
				[tailString appendString:@"."];
			}
		}
		
		/* remaining blanks */
		tmp = 16 - (tmp % 16);
		if (tmp > 7)
		{
			[lineString appendString:@" "];
		}
		for (/* null */; tmp > 0; tmp --)
		{
			[lineString appendString:@"   "];
		}
		
		[stringForData appendFormat:@"%@ %@\n", lineString, tailString];
		AMCRelease(lineString);
		AMCRelease(tailString);
	}
	
	ret = [NSString stringWithString:stringForData];
	AMCRelease(stringForData);
	return ret;
}


+ (NSString *)descriptionWithNSRange:(NSRange)range
{
	return [NSString stringWithFormat:@"(%ld -> %ld <%ld>)",
			range.location,
			range.location + range.length,
			range.length];
}


+ (NSString *)descriptionReadableAppleCharForNSData:(NSData *)data
{
	return [AMCTools descriptionReadableForBytes:(void*)[data bytes] length:[data length]];
}

+ (NSString *)descriptionReadableAppleCharForBytes:(void *)bytes length:(NSUInteger)length
{
	NSMutableString *stringForData = [NSMutableString stringWithCapacity:length * 8];
	NSString *ret;
	NSMutableString *lineString, *tailString;
	NSUInteger tmp, column, dataLen;
	uint8_t *cData = (uint8_t*)bytes;
	uint8_t byte;
	
	[stringForData appendFormat:@"Bytes <0x%08lX>, length: %ld\n", (NSUInteger)bytes, length];
	dataLen = length;
	for (tmp = 0; (tmp + 16) < dataLen; tmp += 16)
	{
		lineString = [NSMutableString stringWithCapacity:16*8];
		tailString = [NSMutableString stringWithCapacity:32];
		[lineString appendFormat:@"%08lX: ", tmp];
		for (column = 0; column < 16; column ++)
		{
			byte = cData[tmp + column];
			[lineString appendFormat:@"%02X ", byte];
			
			if (7 == column)
			{
				[lineString appendString:@" "];
			}
			
			//
			if ((byte >= '!') && (byte <= 0xFF))
			{
				[tailString appendFormat:@"%c", byte];
			}
			else if ('\n' == byte)
			{
				[tailString appendString:@"↲"];
			}
			else if ('\r' == byte)
			{
				[tailString appendString:@"↙"];
			}
			else
			{
				[tailString appendString:@"."];
			}
		}	/* ENDS: "for (column = 0; column < 16; column ++)" */
		
		[stringForData appendFormat:@"%@ %@\n", lineString, tailString];
		AMCRelease(lineString);
		AMCRelease(tailString);
	}
	
	/* last line */
	if (tmp < dataLen)
	{
		lineString = [NSMutableString stringWithCapacity:16*8];
		tailString = [NSMutableString stringWithCapacity:32];
		
		/* normal data */
		[lineString appendFormat:@"%08lX: ", tmp];
		for (/* null */; tmp < dataLen; tmp++)
		{
			byte = cData[tmp];
			[lineString appendFormat:@"%02X ", byte];
			
			if (0 == (tmp + 1) % 8)
			{
				[lineString appendString:@" "];
			}
			
			//
			if ((byte >= '!') && (byte <= 0xFF))
			{
				[tailString appendFormat:@"%c", byte];
			}
			else if ('\n' == byte)
			{
				[tailString appendString:@"↲"];
			}
			else if ('\r' == byte)
			{
				[tailString appendString:@"↙"];
			}
			else
			{
				[tailString appendString:@"."];
			}
		}
		
		/* remaining blanks */
		tmp = 16 - (tmp % 16);
		if (tmp > 7)
		{
			[lineString appendString:@"  "];
		}
		for (/* null */; tmp > 0; tmp --)
		{
			[lineString appendString:@"   "];
		}
		
		[stringForData appendFormat:@"%@ %@\n", lineString, tailString];
		AMCRelease(lineString);
		AMCRelease(tailString);
	}
	
	ret = [NSString stringWithString:stringForData];
	AMCRelease(stringForData);
	return ret;
}


+ (NSString *)descriptionWithSelector:(SEL)selector
{
	return NSStringFromSelector(selector);
}



+ (NSString *)descriptionWithMACLong:(uint64_t)MACInt separator:(NSString *)separator
{
	if (nil == separator)
	{
		separator = @"";
	}
	
	return [NSString stringWithFormat:@"%02llX%@%02llX%@%02llX%@%02llX%@%02llX%@%02llX",
			(MACInt & 0xFF0000000000) >> 40, separator,
			(MACInt & 0x00FF00000000) >> 32, separator,
			(MACInt & 0x0000FF000000) >> 24, separator,
			(MACInt & 0x000000FF0000) >> 16, separator,
			(MACInt & 0x00000000FF00) >> 8,  separator,
			(MACInt & 0x0000000000FF) >> 0];
}


+ (NSString *)bitMaskDescriptionWithUnsignedInteger:(NSUInteger)bits
{
	NSInteger startingBit, tmp;
	NSMutableString *string;
	NSString *ret;
	
	/* check length of the bits */
	if      (bits >= 0x0001000000000000)
	{
		startingBit = 64;
	}
	else if (bits >= 0x000100000000)
	{
		startingBit = 48;
	}
	else if (bits >= 0x00010000)
	{
		startingBit = 32;
	}
	else
	{
		startingBit = 16;
	}
		
	
	/* generate string */
	string = [NSMutableString stringWithCapacity:128];
	
	for (tmp = startingBit - 1;
		 tmp >= 0;
		 tmp--)
	{
		if (0 == (tmp + 1) % 8)
		{
			[string appendFormat:@"\n\t%02ld-%02ld: ", tmp, tmp - 7];
		}
		else if (0 == (tmp + 1) % 4)
		{
			[string appendString:@" "];
		}
		
		if (0 == (bits & (1 << tmp)))
		{
			[string appendString:@"."];
		}
		else
		{
			[string appendString:@"1"];
		}
	}
	
	/* return */
	ret = [NSString stringWithFormat:@"0x%08lX:\n{%@\n}", bits, string];
	AMCRelease(string);
	return ret;
}


+ (uint64_t)htonll:(uint64_t)data
{
	union {
		uint32_t u32[2];
		uint64_t u64;
	} ret;
	
	if ([AMCTools isSystemBigEndian])
	{
		return data;
	}
	else
	{
		ret.u32[0] = htonl((uint32_t)(data >> 32));
		ret.u32[1] = htonl((uint32_t)(data & 0x00000000FFFFFFFF));
		return ret.u64;
	}
}


+ (uint64_t)ntohll:(uint64_t)data
{
	union {
		uint32_t u32[2];
		uint64_t u64;
	} ret;
	
	if ([AMCTools isSystemBigEndian])
	{
		return data;
	}
	else
	{
		ret.u32[0] = ntohl((uint32_t)(data >> 32));
		ret.u32[1] = ntohl((uint32_t)(data & 0x00000000FFFFFFFF));
		return ret.u64;
	}
}

+ (uint16_t)htoles:(uint16_t)data
{
	if ([AMCTools isSystemBigEndian])
	{
		return [AMCTools ntoles:data];
	}
	else
	{
		return data;
	}
}

+ (uint16_t)ntoles:(uint16_t)data
{
	union {
		uint8_t  u8[2];
		uint16_t u16;
	} ret;
	
	ret.u8[0] = ((uint8_t*)(&data))[1];
	ret.u8[1] = ((uint8_t*)(&data))[0];
	return ret.u16;
}

+ (uint32_t)htolel:(uint32_t)data
{
	if ([AMCTools isSystemBigEndian])
	{
		return [AMCTools ntolel:data];
	}
	else
	{
		return data;
	}
}

+ (uint32_t)ntolel:(uint32_t)data
{
	union {
		uint8_t  u8[4];
		uint32_t u32;
	} ret;
	
	ret.u8[0] = ((uint8_t*)(&data))[3];
	ret.u8[1] = ((uint8_t*)(&data))[2];
	ret.u8[2] = ((uint8_t*)(&data))[1];
	ret.u8[3] = ((uint8_t*)(&data))[0];
	return ret.u32;
}

+ (uint64_t)htolell:(uint64_t)data
{
	if ([AMCTools isSystemBigEndian])
	{
		return [AMCTools ntolell:data];
	}
	else
	{
		return data;
	}
}

+ (uint64_t)ntolell:(uint64_t)data
{
	union {
		uint8_t  u8[8];
		uint64_t u64;
	} ret;
	
	ret.u8[0] = ((uint8_t*)(&data))[7];
	ret.u8[1] = ((uint8_t*)(&data))[6];
	ret.u8[2] = ((uint8_t*)(&data))[5];
	ret.u8[3] = ((uint8_t*)(&data))[4];
	ret.u8[4] = ((uint8_t*)(&data))[3];
	ret.u8[5] = ((uint8_t*)(&data))[2];
	ret.u8[6] = ((uint8_t*)(&data))[1];
	ret.u8[7] = ((uint8_t*)(&data))[0];
	return ret.u64;
}

+ (uint16_t)letohs:(uint16_t)data
{
	if ([AMCTools isSystemBigEndian])
	{
		return [AMCTools letons:data];
	}
	else
	{
		return data;
	}
}

+ (uint16_t)letons:(uint16_t)data
{
	return [AMCTools ntoles:data];
}

+ (uint32_t)letohl:(uint32_t)data
{
	if ([AMCTools isSystemBigEndian])
	{
		return [AMCTools letonl:data];
	}
	else
	{
		return data;
	}
}

+ (uint32_t)letonl:(uint32_t)data
{
	return [AMCTools ntoles:data];
}

+ (uint64_t)letohll:(uint64_t)data
{
	if ([AMCTools isSystemBigEndian])
	{
		return [AMCTools letonll:data];
	}
	else
	{
		return data;
	}
}

+ (uint64_t)letonll:(uint64_t)data
{
	return [AMCTools ntolell:data];
}

+ (BOOL)isPoint:(NSPoint)point inRect:(NSRect)rect
{
	return CGRectContainsPoint(rect, point);
}


+ (NSString *)weblocContentWithWebLocation:(NSString *)webLoc
{
	NSString *targetPath, *ret;
	
	/* check path format */
	if ([AMCTools string:webLoc isContainsSubString:@"https://"])
	{
		targetPath = webLoc;
	}
	else if ([AMCTools string:webLoc isContainsSubString:@"http://"])
	{
		targetPath = webLoc;
	}
	else
	{
		targetPath = [NSString stringWithFormat:@"http://%@", webLoc];
	}
	
	/* generate format */
	ret = [NSString stringWithFormat:@""
		   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		   "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
		   "<plist version=\"1.0\">\n"
		   "<dict>\n"
		   "\t<key>URL</key>\n"
		   "\t<string>%@</string>\n"
		   "</dict>\n"
		   "</plist>\n"
		   "",
		   targetPath];
	
	/* return */
	AMCRelease(targetPath);
	return ret;
}


+ (BOOL)isSelector:(SEL)selectorA equalTo:(SEL)selectorB
{
	NSString *stringA, *stringB;
	BOOL ret;
	
	if ((NULL == selectorA) ||
		(NULL == selectorB))
	{
		return NO;
	}
	else
	{
		stringA = NSStringFromSelector(selectorA);
		stringB = NSStringFromSelector(selectorB);
		
		if ([stringA isEqualToString:stringB])
		{
			ret = YES;
		}
		else
		{
			ret = NO;
		}
		
		AMCRelease(stringA);
		AMCRelease(stringB);
		return ret;
	}
}

#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSString *)descriptionForOS
{
	NSDictionary *systemDict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	NSString *osVersionString = [NSString stringWithFormat:@"%@ %@",
								 [systemDict objectForKey:@"ProductName"],
								 [systemDict objectForKey:@"ProductVersion"]];
	AMCRelease(systemDict);
	return osVersionString;
}

+ (NSString *)versionForOS
{
	NSDictionary *systemDict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	NSString *osVersionString = [systemDict objectForKey:@"ProductVersion"];
	AMCRelease(systemDict);
	return osVersionString;
}

+ (BOOL)isOSXYosemiteOrLater
{
	static BOOL ret = NO;
	static BOOL isCheckedBefore = NO;
	
	if (isCheckedBefore)
	{}
	else
	{@autoreleasepool {
		NSString *versionString = [AMCTools versionForOS];
		NSArray *versionPart = nil;
		
		if (versionString)
		{
			versionPart = [versionString componentsSeparatedByString:@"."];
			if ([versionPart count] >= 2)
			{
				if ([(NSString*)[versionPart objectAtIndex:0] integerValue] <= 10)
				{
					if ([(NSString*)[versionPart objectAtIndex:1] integerValue] >= 10)
					{
						ret = YES;
					}
					else
					{
						ret = NO;
					}
				}
				else
				{
					ret = YES;
				}
			}
		}
		else
		{
			ret = NO;
		}
		
		AMCRelease(versionString);
		AMCRelease(versionPart);
		isCheckedBefore = YES;
	}}
	
	return ret;
}
#endif


+ (NSString *)descriptionForCallerOfCurrentMethod
{
	NSString *description = [[[NSThread callStackSymbols] objectAtIndex:2] description];
	NSInteger idxFirstChar = [description rangeOfString:@"["].location;
	NSString *ret;
	
	if (NSNotFound == idxFirstChar)
	{
		ret = description;
	}
	else
	{
		ret = [description substringFromIndex:idxFirstChar];
	}
	
	AMCRelease(description);
	return ret;
}

+ (void)openWebSite:(NSString *)webPathWithHttpLeading
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:webPathWithHttpLeading]];
}


+(CGFloat)fastInverseSquareRoot:(CGFloat)input
{
#if 0
	return (1.0 / sqrt(input));
#else
	CGFloat ret = 0.0F;
	
	if (0.0 == input)
	{
		ret = CGFLOAT_MAX;
	}
	else
	{
		if (4 == sizeof(CGFloat))
		{
			long i;
			CGFloat x2, y;
			const CGFloat threeHalfs = 1.5F;
			
			x2= input * 0.5F;
			y = input;
			i = *(long*)&y;
			i = 0x5F375A86 - (i >> 1);
			y = *(CGFloat*)&i;
			y = y * (threeHalfs - (x2 * y * y));
			y = y * (threeHalfs - (x2 * y * y));
			
			ret = y;
		}
		else if (8 == sizeof(CGFloat))
		{
			int32_t i;
			float x2, y;
			const float threeHalfs = 1.5F;
			
			y = ((float)input);
			x2= y * ((float)0.5F);
			i = *(int32_t*)&y;
			i = 0x5F375A86 - (i >> 1);
			y = *(float*)&i;
			y = y * (threeHalfs - (x2 * y * y));
//			y = y * (threeHalfs - (x2 * y * y));
			
			ret = (CGFloat)y;
		}
		else
		{
			AMCDebug(@"Fast inverse square root invalid");
			ret = 1.0 / sqrtf((double)input);
		}
	}
		
	return ret;
#endif
}


+ (CGFloat)fastSquareRoot:(CGFloat)input
{
#if 0
	return sqrt(input);
#else
	if (0.0F == input)
	{
		return 0.0F;
	}
	else if (8 == sizeof(CGFloat))
	{
		return (1.0F / [AMCTools fastInverseSquareRoot:input]);
	}
	else if (4 == sizeof(CGFloat))
	{
		return (1.0F / [AMCTools fastInverseSquareRoot:input]);
	}
	else
	{
		return sqrt((double)input);
	}
#endif
}

+ (CGFloat)floatRound:(CGFloat)input
{
	NSInteger doubleIntNum = (NSInteger)(input * 2.0);
	
	if (0.0 == input)
	{
		return 0.0;
	}
	else if (input > 0.0)
	{
		if (0 == (doubleIntNum & 0x1)) {
			return [AMCTools floatRoundDown:input];
		}
		else {
			return [AMCTools floatRoundUp:input];
		}
	}
	else
	{
		if (0 == (doubleIntNum & 0x1)) {
			return [AMCTools floatRoundUp:input];
		}
		else {
			return [AMCTools floatRoundDown:input];
		}
	}
}

+ (CGFloat)floatRoundUp:(CGFloat)input
{
	NSInteger intNum = (NSInteger)input;
	
	if (((CGFloat)intNum) == input)
	{
		return input;
	}
	else if (input > 0.0)
	{
		return [AMCTools _floatRoundCut:(input + 1.0)];
	}
	else
	{
		return [AMCTools _floatRoundCut:input];
	}
}

+ (CGFloat)_floatRoundCut:(CGFloat)input
{
	NSInteger intNum = (NSInteger)input;
	return (CGFloat)intNum;
}

+ (CGFloat)floatRoundDown:(CGFloat)input
{
	if (0.0 == input)
	{
		return 0.0;
	}
	else if (input > 0.0)
	{
		return [AMCTools _floatRoundCut:input];
	}
	else
	{
		return [AMCTools _floatRoundCut:(input - 1.0)];
	}
}


+ (void)barrelIncreaseUInt:(void*)pNum
					  UInt:(size_t)numSize
				 increment:(NSUInteger)increment
				barrelSize:(NSUInteger)barrelSize
{
	if (1 == numSize)
	{
		[AMCTools barrelIncreaseUInt8:pNum increment:(uint8_t)increment barrelSize:(uint8_t)barrelSize];
	}
	else if (2 == numSize)
	{
		[AMCTools barrelIncreaseUInt16:pNum increment:(uint16_t)increment barrelSize:(uint16_t)barrelSize];
	}
	else if (4 == numSize)
	{
		[AMCTools barrelIncreaseUInt32:pNum increment:(uint32_t)increment barrelSize:(uint32_t)barrelSize];
	}
	else if (8 == numSize)
	{
		[AMCTools barrelIncreaseUInt64:pNum increment:(uint64_t)increment barrelSize:(uint64_t)barrelSize];
	}
	else
	{}
}


+ (void)barrelIncreaseUInt8:(uint8_t *)pUint8 increment:(uint8_t)increment barrelSize:(uint8_t)barrelSize
{
	if (increment > barrelSize)
	{
		increment = increment % barrelSize;
	}
	
	(*pUint8) += increment;
	if ((*pUint8) >= barrelSize)
	{
		(*pUint8) -= barrelSize;
	}
}


+ (void)barrelIncreaseUInt16:(uint16_t *)pUint16 increment:(uint16_t)increment barrelSize:(uint16_t)barrelSize
{
	if (increment > barrelSize)
	{
		increment = increment % barrelSize;
	}
	
	(*pUint16) += increment;
	if ((*pUint16) >= barrelSize)
	{
		(*pUint16) -= barrelSize;
	}
}


+ (void)barrelIncreaseUInt32:(uint32_t *)pUint32 increment:(uint32_t)increment barrelSize:(uint32_t)barrelSize
{
	if (increment > barrelSize)
	{
		increment = increment % barrelSize;
	}
	
	(*pUint32) += increment;
	if ((*pUint32) >= barrelSize)
	{
		(*pUint32) -= barrelSize;
	}
}


+ (void)barrelIncreaseUInt64:(uint64_t *)pUint64 increment:(uint64_t)increment barrelSize:(uint64_t)barrelSize
{
	if (increment > barrelSize)
	{
		increment = increment % barrelSize;
	}
	
	(*pUint64) += increment;
	if ((*pUint64) >= barrelSize)
	{
		(*pUint64) -= barrelSize;
	}
}


+ (void)barrelIncreaseUInteger:(NSUInteger *)pUinteger increment:(NSUInteger)increment barrelSize:(NSUInteger)barrelSize
{
	return [AMCTools barrelIncreaseUInt:pUinteger UInt:sizeof(NSUInteger) increment:increment barrelSize:barrelSize];
}


/* File tools */
+ (BOOL)isFileExist:(NSString *)path
{
	struct stat dummyStat;
	if (0 == stat([path UTF8String], &dummyStat))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

+ (BOOL)isFilePathDirectory:(NSString *)path
{
	BOOL isDir;
	NSFileManager *fileMgr = [[NSFileManager alloc] init];
	
	if (![fileMgr fileExistsAtPath:path isDirectory:&isDir])
	{
		AMCRelease(fileMgr);
		return NO;
	}
	else
	{
		AMCRelease(fileMgr);
		return isDir;
	}
}

+ (BOOL)isFilePathFile:(NSString *)path
{
	BOOL isDir;
	NSFileManager *fileMgr = [[NSFileManager alloc] init];
	
	if (NO == [fileMgr fileExistsAtPath:path isDirectory:&isDir])
	{
		AMCRelease(fileMgr);
		return NO;
	}
	else
	{
		AMCRelease(fileMgr);
		return (!isDir);
	}
}

+ (BOOL)removeFileAtPath:(NSString *)path error:(NSError *__autoreleasing *)errorPtr
{
	if (NO == [AMCTools isFileExist:path])
	{
		/* nothing to do */
		return YES;
	}
	else
	{
		/* if it is not in the main thread, we should NOT use defaultManager */
		NSFileManager *fileMng = [[NSFileManager alloc] init];
		
		if (NO == [fileMng removeItemAtPath:path error:errorPtr])
		{
			AMCRelease(fileMng);
			return NO;
		}
		else
		{
			AMCRelease(fileMng);
			return YES;
		}
	}
}

+ (BOOL)removeFileAtPath:(NSString *)path
{
	return [AMCTools removeFileAtPath:path error:NULL];
}

+ (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)errorPtr
{
	if ([AMCTools isFileExist:path])
	{
		if ([AMCTools isFilePathDirectory:path])
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	else
	{
		NSFileManager *fileMng = [[NSFileManager alloc] init];
		BOOL status;
		
		status = [fileMng createDirectoryAtPath:path
					withIntermediateDirectories:YES
									 attributes:nil
										  error:errorPtr];
		AMCRelease(fileMng);
		return status;
	}
}

+ (BOOL)createDirectoryAtPath:(NSString *)path
{
	return [AMCTools createDirectoryAtPath:path error:NULL];
}


+ (NSArray *)fileListInFolder:(NSString *)folder withExtension:(NSString *)extension
{
	NSArray *fileArray = [AMCTools fileListInFolder:folder];
	
	if (nil == fileArray)
	{
		return nil;
	}
	else if (0 == [fileArray count])
	{
		return fileArray;
	}
	else
	{
		NSArray *allFiles = [AMCTools fileListInFolder:folder];
		NSString *trueExtension = [extension uppercaseString];
		NSString *fileItem;
		NSUInteger tmp, count;
		NSMutableArray *chosenFiles = [NSMutableArray arrayWithCapacity:[allFiles count]];
		NSArray *ret;
		
		for (tmp = 0, count = [allFiles count];
			 tmp < count;
			 tmp++)
		{
			fileItem = [allFiles objectAtIndex:tmp];
			if ([fileItem.uppercaseString isEqualToString:trueExtension])
			{
				[chosenFiles addObject:fileItem];
			}
			
			AMCRelease(fileItem);
		}
		
		ret = [NSArray arrayWithArray:chosenFiles];
		
		AMCRelease(allFiles);
		AMCRelease(trueExtension);
		AMCRelease(chosenFiles);
		
		return ret;
	}
}

+ (NSArray *)fileListInFolder:(NSString *)folder
{
	if (NO == [AMCTools isFilePathDirectory:folder])
	{
		return [NSArray array];
	}	/* ENDS: "if (NO == [AMCTools isFilePathDirectory:folder])" */
	else
	{
		NSFileManager *fileMng = [[NSFileManager alloc] init];
		NSArray *fileArray = [fileMng contentsOfDirectoryAtPath:folder error:NULL];
		
		AMCRelease(fileMng);
		return fileArray;
	}	/* ENDS: "ELSE (NO == [AMCTools isFilePathDirectory:folder])" */
}


+ (BOOL)makeSureIsDirectoryInPath:(NSString *)path
{
	BOOL isDir, ret;
	NSError *error;
	
	if (NO == [NSDefaultFileManager fileExistsAtPath:path isDirectory:&isDir])
	{
		/* create directory */
		ret = [NSDefaultFileManager createDirectoryAtPath:path
							  withIntermediateDirectories:YES
											   attributes:nil
													error:&error];
		if (NO == ret)
		{
			AMCSysError(@"Failed to create directory at \"%@\":\n%@", path, error);
		}
		
		AMCRelease(error);
		return ret;
	}
	else if (NO == isDir)
	{
		/* remove item */
		ret = [NSDefaultFileManager removeItemAtPath:path error:&error];
		
		if (NO == ret)
		{
			AMCSysError(@"Failed to remove item at \"%@\":\n%@", path, error);
			AMCRelease(error);
			return NO;
		}
		
		/* create directory */
		ret = [NSDefaultFileManager createDirectoryAtPath:path
							  withIntermediateDirectories:YES
											   attributes:nil
													error:&error];
		if (NO == ret)
		{
			AMCSysError(@"Failed to create directory at \"%@\":\n%@", path, error);
		}
		
		AMCRelease(error);
		return ret;
	}
	else
	{
		return YES;
	}
}


+ (BOOL)makeSureIsFileInPath:(NSString *)path
{
	BOOL isDir, ret;
	NSError *error;
	
	if (NO == [NSDefaultFileManager fileExistsAtPath:path isDirectory:&isDir])
	{
		/* create the file */
		ret = [NSDefaultFileManager createFileAtPath:path
											contents:nil
										  attributes:nil];
		return ret;
	}
	else if (YES == isDir)
	{
		/* remove the directory */
		ret = [NSDefaultFileManager removeItemAtPath:path error:&error];
		if (NO == ret)
		{
			AMCSysError(@"Failed to remove \"%@\":\n%@", path, error);
			AMCRelease(error);
			return ret;
		}
		else
		{
			/* create the file */
			ret = [NSDefaultFileManager createFileAtPath:path
												contents:nil
											  attributes:nil];
			return ret;
		}
	}
	else
	{
		return YES;
	}
}


+ (BOOL)makeTargetURL:(NSURL *)fromURL toAliasURL:(NSURL *)toURL
{
	BOOL ret;
	
	if (fromURL && toURL)
	{
		NSError *error;
		
//		AMCDebug(@"Src: %@\nDst: %@", fromURL, toURL);
//		[AMCTools makeSureIsFileInPath:[toURL path]];
		NSData *bookmarkData = [fromURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
								 includingResourceValuesForKeys:nil
												  relativeToURL:nil
														  error:&error];
		if (bookmarkData)
		{
			ret = [NSURL writeBookmarkData:bookmarkData
									 toURL:toURL
								   options:NSURLBookmarkCreationSuitableForBookmarkFile
									 error:&error];
			
			if (NO == ret)
			{
				NSLog(@"Failed to generate alias: %@", error);
			}
		}
		else
		{
			NSLog(@"Failed to generate alias: %@", error);
			ret = NO;
		}
	}
	else
	{
		ret = NO;
	}
	
	return ret;
}


+ (BOOL)moveContentsFromFolder:(NSString *)from toFolder:(NSString *)to
{@autoreleasepool {
	NSFileManager *fileMgr = [[NSFileManager alloc] init];
	BOOL isOK = YES;
	NSUInteger tmp;
	NSArray *allItems = nil;
	NSString *item = nil;
	BOOL isDir, isExist;
	
	/* check parameter */
	if ((nil == from) || (nil == to))
	{
		isOK = NO;
	}
	
	
	/******/
	/* check from dir */
	if (isOK)
	{
		isExist = [fileMgr fileExistsAtPath:from isDirectory:&isDir];
		
		if (NO == isExist)
		{
			isOK = NO;
		}
		else if (NO == isDir)
		{
			isOK = NO;
		}
		else
		{}
	}
	
	
	/******/
	/* check to dir */
	if (isOK)
	{
		isExist = [fileMgr fileExistsAtPath:to isDirectory:&isDir];
		
		if (NO == isExist)
		{
			[fileMgr createDirectoryAtPath:to withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		else if (NO == isDir)
		{
			isOK = NO;
		}
		else
		{}
	}
	
	
	/******/
	/* move contents */
	if (isOK)
	{
		allItems = [fileMgr contentsOfDirectoryAtPath:from error:NULL];
		
		if (allItems)
		{
			for (tmp = 0; tmp < [allItems count]; tmp++)
			{
				item = [allItems objectAtIndex:tmp];
				
				[fileMgr moveItemAtPath:[NSString stringWithFormat:@"%@/%@", from, item]
								 toPath:[NSString stringWithFormat:@"%@/%@", to, item]
								  error:NULL];
				
				AMCRelease(item);
			}
		}
	}	
	
	
	/******/
	/* return */
	AMCRelease(allItems);
	AMCRelease(fileMgr);
	return isOK;
}}


#if CFG_FRAMEWORK_CORE_FOUNDATION
+ (BOOL)isFilePathAlias:(NSString *)path
{
	if (NO == [AMCTools isFileExist:path])
	{
		return NO;
	}
	else
	{
		BOOL success;
		BOOL isAlias;
		NSURL *url = [NSURL fileURLWithPath:path];
		
		CFURLRef cfUrl = (__bridge CFURLRef)url;
		CFBooleanRef cfIsAlias = kCFBooleanFalse;
		
		success = CFURLCopyResourcePropertyForKey(cfUrl, kCFURLIsAliasFileKey, &cfIsAlias, NULL);
		isAlias = CFBooleanGetValue(cfIsAlias);
		
		AMCRelease(url);
		return (isAlias && success);
	}
}
#endif


/* NSURL tools */
+ (BOOL)isURLWritable:(NSURL *)url
{
	return [[NSFileManager defaultManager] isWritableFileAtPath:[url path]];
}

+ (BOOL)isPathWritable:(NSString *)path
{
	return [[NSFileManager defaultManager] isWritableFileAtPath:path];
}

+ (NSURL *)URLWithPath:(NSString *)path
{
	NSString *actualPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return [NSURL URLWithString:actualPath];
}

/* NSTextView tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (void)textViewScrollToEnd:(NSTextView*)view
{
	BOOL shouldScroll = (NSMaxY(view.visibleRect) == NSMaxY(view.bounds)) ? NO : YES;
	if (shouldScroll)
	{
//		AMCPrintf("Scroll");
		[view scrollRangeToVisible:NSMakeRange(view.string.length, 0)];
	}
	else
	{
//		AMCPrintf("No scroll");
	}
}
#endif

/* NSColor tools */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSColor *)colorWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue
{
	NSUInteger r = (NSUInteger)red;
	NSUInteger g = (NSUInteger)green;
	NSUInteger b = (NSUInteger)blue;
	return [NSColor colorWithCalibratedRed:(((CGFloat)r) / 255.0F)
									 green:(((CGFloat)g) / 255.0F)
									  blue:(((CGFloat)b) / 255.0F)
									 alpha:1.0F];
}
#endif


/* Network interfaces tools */
#if CFG_FRAMEWORK_SYSTEM_CONFIGURATION
+ (NSDictionary*)localIPInformation
{
	NSDictionary *ret = nil;
	
	SCDynamicStoreRef storeRef = SCDynamicStoreCreate(NULL, (CFStringRef)@"FindCurrentInterfaceIpMac", NULL, NULL);
	
	CFPropertyListRef global = SCDynamicStoreCopyValue(storeRef, CFSTR("State:/Network/Global/IPv4"));
	id primaryInterface = [(__bridge NSDictionary*)global valueForKey:@"PrimaryInterface"];
	
	NSString *interfaceState = [NSString stringWithFormat:
								@"State:/Network/Interface/%@/IPv4",
								(NSString*)primaryInterface];
	
	CFPropertyListRef ipv4 = SCDynamicStoreCopyValue(storeRef, (__bridge CFStringRef)interfaceState);
	
	ret = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary*)ipv4];
	
	AMCCFRelease(storeRef);
	AMCCFRelease(ipv4);
	AMCCFRelease(global);
	
	AMCRelease(interfaceState);
	
	return ret;
}

+ (NSUInteger)ipCountInIPInformation:(NSDictionary *)info
{
	if (NO == [info isKindOfClass:[NSDictionary class]])
	{
		return 0;
	}
	
	NSUInteger ret;
	NSArray *IPArray = [info objectForKey:AMCTools_LocalNetworkAddressKey];
	if (IPArray)
	{
		ret = [IPArray count];
		AMCRelease(IPArray);
	}
	else
	{
		ret = 0;
	}
	
	return ret;
}

+ (NSString *)ipAddressInInformation:(NSDictionary *)info atIndex:(NSUInteger)index
{
	NSUInteger count;
	count = [AMCTools ipCountInIPInformation:info];
	NSArray *ipArray;
	NSString *ret = nil;
	
	if (index >= count)
	{
		return nil;
	}
	else
	{}
	
	ipArray = [info objectForKey:AMCTools_LocalNetworkAddressKey];
	if ([ipArray isKindOfClass:[NSArray class]])
	{
		ret = [ipArray objectAtIndex:index];
		AMCRelease(ipArray);
		
		if ([AMCTools stringIsValidIPv4:ret])
		{
			/* OK */
		}
		else
		{
			AMCRelease(ret);
		}
	}
	else
	{
		AMCRelease(ipArray);
		ret = nil;
	}
	
	return ret;
}

+ (NSString *)broadcastAddressInInformation:(NSDictionary *)info atIndex:(NSUInteger)index
{
	NSUInteger count;
	count = [AMCTools ipCountInIPInformation:info];
	NSArray *broadcastArray;
	NSString *ret = nil;
	
	if (index >= count)
	{
		return nil;
	}
	else
	{}
	
	broadcastArray = [info objectForKey:AMCTools_LocalNetworkBroadcastKey];
	if ([broadcastArray isKindOfClass:[NSArray class]])
	{
		ret = [broadcastArray objectAtIndex:index];
		AMCRelease(broadcastArray);
		
		if ([AMCTools stringIsValidIPv4:ret])
		{
			/* OK */
		}
		else
		{
			AMCRelease(ret);
		}
	}
	else
	{
		AMCRelease(broadcastArray);
		ret = nil;
	}
	
	return ret;
}

+ (NSString *)subnetMaskAddressInInformation:(NSDictionary *)info atIndex:(NSUInteger)index
{
	NSUInteger count;
	count = [AMCTools ipCountInIPInformation:info];
	NSArray *maskArray;
	NSString *ret = nil;
	
	if (index >= count)
	{
		return nil;
	}
	else
	{}
	
	maskArray = [info objectForKey:AMCTools_LocalNetworkSubnetMaskKey];
	if ([maskArray isKindOfClass:[NSArray class]])
	{
		ret = [maskArray objectAtIndex:index];
		AMCRelease(maskArray);
		
		if ([AMCTools stringIsValidIPv4:ret])
		{
			/* OK */
		}
		else
		{
			AMCRelease(ret);
		}
	}
	else
	{
		AMCRelease(maskArray);
		ret = nil;
	}
	
	return ret;
}

#endif


/* layout constraints tools */
#pragma mark - Layout constraint
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
//+ (NSArray *)layoutConstraintsForView:(NSView *)subview superView:(NSView *)superview
//						 leftDistance:(CGFloat)left rightDistance:(CGFloat)right
//						  topDistance:(CGFloat)top bottomDistance:(CGFloat)bottom
//{
//	NSLayoutConstraint *leftCon, *rightCon, *topCon, *bottomCon;
//	NSArray *ret = nil;
//	
//	leftCon = [NSLayoutConstraint constraintWithItem:subview
//										   attribute:NSLayoutAttributeLeft
//										   relatedBy:NSLayoutRelationEqual
//											  toItem:superview
//										   attribute:NSLayoutAttributeLeft
//										  multiplier:1.0 constant:left];
//	rightCon = [NSLayoutConstraint constraintWithItem:subview
//											attribute:NSLayoutAttributeRight
//											relatedBy:NSLayoutRelationEqual
//											   toItem:superview
//											attribute:NSLayoutAttributeRight
//										   multiplier:1.0 constant:(0.0 - right)];
//
//	
//	return nil;
//}

+ (NSLayoutConstraint*)constraintWithTarget:(NSView*)target width:(CGFloat)width
{
	return [NSLayoutConstraint constraintWithItem:target
										attribute:NSLayoutAttributeWidth
										relatedBy:NSLayoutRelationEqual
										   toItem:nil
										attribute:NSLayoutAttributeNotAnAttribute
									   multiplier:0.0
										 constant:width];
}

+ (NSLayoutConstraint*)constraintWithTarget:(NSView*)target height:(CGFloat)height
{
	return [NSLayoutConstraint constraintWithItem:target
										attribute:NSLayoutAttributeHeight
										relatedBy:NSLayoutRelationEqual
										   toItem:nil
										attribute:NSLayoutAttributeNotAnAttribute
									   multiplier:0.0
										 constant:height];
}

#endif


@end
