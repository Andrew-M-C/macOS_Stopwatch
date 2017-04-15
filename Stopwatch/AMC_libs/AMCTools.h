//
//  AMCTools.h
//  TPLibraryTest
//
//  Created by TP-LINK on 13-3-13.
//  Copyright (c) 2013年 Andrew Chang. All rights reserved.
//

#import "AMCObjCTools.h"
#import <Cocoa/Cocoa.h>

/* AMCTool Configuration */
#define CFG_FRAMEWORK_SECURITY      1
#define CFG_FRAMEWORK_QTKIT			0
#define CFG_FRAMEWORK_QUARTZCORE	0
#define	CFG_FRAMEWORK_SYSTEM_CONFIGURATION	1
#define CFG_FRAMEWORK_CORE_FOUNDATION	1
#define CFG_CONFIG_READ_TOOL_BUFFER_LEN		(512)
/* Configuration ends. Please do NOT edit from this line on */


/* identify what SDK is */
#define SDK_TYPE_OS_X		0
#define SDK_TYPE_iOS		1
#define SDK_TYPE_WEB_OSX	2
#define CFG_SDK_TYPE		SDK_TYPE_OS_X


#import <Foundation/Foundation.h>

#if (CFG_FRAMEWORK_QUARTZCORE)
#import <QuartzCore/QuartzCore.h>
#endif

#if (CFG_FRAMEWORK_QTKIT)
#import <QTKit/QTKit.h>
#endif

#if (CFG_FRAMEWORK_SYSTEM_CONFIGURATION)
#import <SystemConfiguration/SystemConfiguration.h>
#define AMCTools_LocalNetworkAddressKey			@"Addresses"
#define AMCTools_LocalNetworkBroadcastKey		@"BroadcastAddresses"
#define AMCTools_LocalNetworkSubnetMaskKey		@"SubnetMasks"
#endif


/* A structure of rect with NSInteger and its contert tool */
typedef struct {
	NSInteger x;
	NSInteger y;
	NSInteger width;
	NSInteger height;
}AMCIntegerRect_st;

/* some definations */
/* QTCompressionOptions... */
//#define QTCompressionOptionsLosslessAppleIntermediateVideo	@"QTCompressionOptionsLosslessAppleIntermediateVideo"
#define QTCompressionOptionsLosslessAnimationVideo	@"QTCompressionOptionsLosslessAnimationVideo"
#define QTCompressionOptions120SizeH264Video	@"QTCompressionOptions120SizeH264Video"
#define QTCompressionOptions240SizeH264Video	@"QTCompressionOptions240SizeH264Video"
#define QTCompressionOptionsSD480SizeH264Video	@"QTCompressionOptionsSD480SizeH264Video"
//#define QTCompressionOptions120SizeMPEG4Video	@"QTCompressionOptions120SizeMPEG4Video"
//#define QTCompressionOptions240SizeMPEG4Video	@"QTCompressionOptions240SizeMPEG4Video"
//#define QTCompressionOptionsSD480SizeMPEG4Video	@"QTCompressionOptionsSD480SizeMPEG4Video"
#define QTCompressionOptionsLosslessALACAudio	@"QTCompressionOptionsLosslessALACAudio"
#define QTCompressionOptionsHighQualityAACAudio	@"QTCompressionOptionsHighQualityAACAudio"
#define QTCompressionOptionsVoiceQualityAACAudio	@"QTCompressionOptionsVoiceQualityAACAudio"
#define QTCompressionOptionsJPEGVideo	@"QTCompressionOptionsJPEGVideo"

/* CATransform3D key paths */
#define CATransform3DKeyPath_rotationX	@"transform.rotation.x"
#define CATransform3DKeyPath_rotationY	@"transform.rotation.y"
#define CATransform3DKeyPath_rotationZ	@"transform.rotation.z"
#define CATransform3DKeyPath_scaleX		@"transform.scale.x"
#define CATransform3DKeyPath_scaleY		@"transform.scale.y"
#define CATransform3DKeyPath_scaleZ		@"transform.scale.z"
#define CATransform3DKeyPath_scale		@"transform.scale"
#define CATransform3DKeyPath_translationX		@"transform.translation.x"
#define CATransform3DKeyPath_translationY		@"transform.translation.y"
#define CATransform3DKeyPath_translationZ		@"transform.translation.z"
#define CATransform3DKeyPath_translation		@"transform.translation"


@interface AMCTools : NSObject
/* tools for AMCIntegerRect_st */
#pragma mark - AMC integer based rectangle data type
+ (NSRect)NSRectFromAMCRect:(AMCIntegerRect_st)rect;
+ (AMCIntegerRect_st)AMCRectFromNSRect:(NSRect)rect;
+ (AMCIntegerRect_st)AMCZeroRect;
+ (AMCIntegerRect_st)AMCMakeRectX:(NSInteger)x
								Y:(NSInteger)y
							width:(NSInteger)width
						   height:(NSInteger)height;
+ (NSString*)descriptionWithAMCRect:(AMCIntegerRect_st)rect;

/* Locolization Tools */
#pragma mark - Localization
/** @name Section title */
/** Return localized string in specified key. */
+ (NSString*)localize:(NSString*)key;

/* PWD Tools */
#pragma mark - System file directory
/** Return PWD path string. */
+ (NSString*)pwd;
+ (NSString*)pwdWithAppName;
+ (NSString*)homeDirectory;

/* NSOpenPanel Tools */
#pragma mark - NSOpenPanel
/** Open a open panel and return a path string */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSString*)getOpenPanelPath:(NSOpenPanel*)panel
					  AtIndex:(NSUInteger)index;
#endif

/* NSImage and CGImage Conversion Tools */
#pragma mark - NSImage <--> CGImageRef
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
/** Convert VGImageRef to NSImage */
+ (NSImage*)nsImageFromCGImageRef:(CGImageRef)cgImageRef;
+ (CGImageRef)cgImageRefFromNSImage:(NSImage*)image;
//+ (CGImageRef)cgImageRefFromNSImage:(NSImage*)nsImage;
#endif

/* QTKit Tools */
#pragma mark - QTKit
#if CFG_FRAMEWORK_QTKIT
+(QTMovieLoadState) getQTMovieStat: (QTMovie*)movie;
+(CGImageRef) getMovieFrame:(QTMovie*)movie
					 atTime:(QTTime)time;
+(void)fixSliderCellBug;
+(QTCaptureDevice*)allocateACamera:(NSError *__autoreleasing *)errorPtr;
+(void)setMovieOutputFile:(QTCaptureMovieFileOutput*)movieFileOutput
			  videoOption:(NSString*)videoOpt
			  audioOption:(NSString*)audioOpt;
#endif


/* OSStatus to NSError */
#pragma mark - OSStatus --> NSError
+(NSError*)errorFromOSStatus:(OSStatus) status;


/* NSApplication Tools */
#pragma mark - Terminate self application
/** Terminate current application */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (void)terminateApplication:(id)sender;
+ (BOOL)checkAppDuplicateAndBringToFrontWithBundle:(NSBundle*)bundle;
+ (BOOL)checkAppDuplicateAndKillOthersWithBundle:(NSBundle *)bundle;
#endif

/* NSWindow Tools */
#pragma mark - NSWindow
/** Set a window centered in complete screen. */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+(void)windowSetCentered:(NSWindow*)window;
/** Set a window centered in visabe screen. */
+(void)windowSetCenteredInVisableScreen:(NSWindow*)window;
/** Set a window in top-left. */
+(void)windowSetTopLeft:(NSWindow*)window;
/** Set a window in top-right. */
+(void)windowSetTopRight:(NSWindow*)window;
/** Set a window in bottom-left of the visable screen. */
+(void)windowSetBottomLeftInVisableScreen:(NSWindow*)window;
/** Set a window in bottom right of the visable screen. */
+(void)windowSetBottomRightInVisableScreen:(NSWindow*)window;
/** Set a window top-centered. */
+(void)windowSetTopCenter:(NSWindow*)window;
/** Set a window bottom-centered of the visable screen. */
+(void)windowSetBottomCenterInVisableScreen:(NSWindow*)window;
/** Set a window centered-left of a visable screen. */
+(void)windowSetCenterLeftInVisableScreen:(NSWindow*)window;
/** Set a window centered-right of a visable screen. */
+(void)windowSetCenterRightInVisableScreen:(NSWindow*)window;
/** Set a window at specified ratio for the screen */
+ (void)window:(NSWindow*)window setInScreenRatioX:(CGFloat)x ratioY:(CGFloat)y;
/** Set a window at specified ratio for the visable screen */
+ (void)window:(NSWindow*)window setInVisableScreenRatioX:(CGFloat)x ratioY:(CGFloat)y;
/** modal in a window */
+ (void)window:(NSWindow *)subWindow
dragInToWindow:(NSWindow *)superWindow;
/** modal out a window */
+ (void)windowDragOut:(NSWindow*)subWindow;
/** Enable/disable window resize. */
+ (void)window:(NSWindow*)window setResizeEnable:(BOOL)flag;
/** Enabl/disable minimuming window */
+ (void)window:(NSWindow*)window setMinimumEnable:(BOOL)flag;
/** Enabl/disable slosing window */
+ (void)window:(NSWindow*)window setCloseEnable:(BOOL)flag;
/** get responder train */
+ (NSArray*)firstResponderTrainForWindow:(NSWindow*)window;
/** set first responder train */
+ (void)window:(NSWindow*)window setFirstResponderTrain:(NSArray*)firstResponders;
/** Enable/Disable full screen */
+ (void)window:(NSWindow*)window setCanToggleFullScreen:(BOOL)flag;
#endif

/* popover tools */
#pragma mark - popover
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
/** popover a NSWindow */
+ (NSPopover*)popoverWindow:(NSWindow *)window
			 relativeToView:(NSView *)view
				 controller:(NSViewController *)controller
				 appearance:(NSPopoverAppearance)appearance
			  preferredEdge:(NSRectEdge)edge
					 offset:(NSPoint)offset
				   delegate:(id<NSPopoverDelegate>)delegate;
#endif

/* UNIX tools */
#pragma mark - Some C tools
/** Get errno string in C string type. */
+(const char*)cStrError;
/** Get errno string in NSString type. */
+(NSString*)strError;
/** Get config value from a file. Not recommanded. */
+(NSString*)configValueFromFile:(NSString*)path
				  withParameter:(NSString*)parameter;
/** Get config value from a file. Not recommanded. */
+(NSString*)configValueFromFileURL:(NSURL *)pathURL
					 withParameter:(NSString *)parameter;
/** Get config value from a bundle file. Not recommanded. */
+(NSString*)configValueFromBundleFile:(NSString*)fileName
							extension:(NSString*)extension
							parameter:(NSString*)parameter;


/* NSString and NSData tools */
#pragma mark - NSData, NSString
/** Check whether a string is empty. */
+(BOOL)stringIsEmpty:(NSString*)string;
/** Check whether a string is NOT empty */
+(BOOL)stringIsValid:(NSString*)string;
/** Check whether a string is a valid IPv4 string */
+(BOOL)stringIsValidIPv4:(NSString*)IP;
/** Check whether a string is a valid MAC address string */
+(BOOL)stringIsValidMAC:(NSString*)MACString MACInt:(uint64_t*)pMacInt;
/** Check whether a string contains a sub-string. */
+(BOOL)string:(NSString*)str
isContainsSubString:(NSString*)subStr;
/** Check two IP is at same subnet */
+ (BOOL)isIPv4:(NSString*)firstIP
	   andIPv4:(NSString*)secondIP
atTheSameSubnetMask:(NSString*)subnetMask;
/** Search and locate sub-string in string */
+(NSRange)findSubString:(NSString*)subString
			   inString:(NSString*)string;
/** Get substring within two seperaters */
+(NSString*)subStringIn:(NSString*)string
	withStartIdentifier:(NSString*)start
	   endingIdentifier:(NSString*)ending;
/** get range of a sub-string in string */
+(NSRange)rangeOfSubStringIn:(NSString*)string
		 withStartIdentifier:(NSString*)start
			endingIdentifier:(NSString*)ending;
/** get an dictionary with string values */
+ (NSDictionary*)dictionaryWithXMLLikeString:(NSString*)string;
/** get an dictionary with json string */
+ (NSDictionary*)dictionaryWithJsonString:(NSString*)string;
/** get an dictionary with json data */
+ (NSDictionary*)dictionaryWithJsonData:(NSData*)data;
/** remove all whitespace(NOT including "space"), return, newline characters */
+(NSString*)stringWithoutWhitespaceAndReturns:(NSString*)string;
/** remove specified characters characters */
+(NSString*)string:(NSString*)string
withoutSpecifiedCharecterIn:(NSString*)characters;
/** Check whether a data contains a sub-data */
+(BOOL)data:(NSData*)data
isContainsSubData:(NSData*)subData
	inRange:(NSRange)range;
/** Search and locate sub-data in data */
+(NSRange)findSubData:(NSData*)subData
			   inData:(NSData*)data;
/** Convert NSString to NSData */
+(NSData*)dataWithString:(NSString*)string;
/** Convert NSData to NSString */
+(NSString*)stringWithData:(NSData*)data;
/** Convert NSString to big-endian unicode NSData */
+(NSData*)dataBigEndianUnicodeWithString:(NSString*)string;
/** Convert NSString to little-endian unicode NSData */
+(NSData*)dataLittleEndianUnicodeWithString:(NSString*)string;
/** detect writeToFile error */
+ (BOOL)writeData:(NSData*)data
   withFileHandle:(NSFileHandle*)fileHandle;
/** Regular Expression check */
+ (BOOL)string:(NSString*)string
matchesRegularExpression:(NSString*)regex;


/** Get text size in system font */
#pragma mark - NSFont
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+(NSSize)string:(NSString*)str
sizeWithSystemFontSize:(CGFloat)size;
/** Get text size in specified font */
+(NSSize)string:(NSString*)str
sizeWithFontName:(NSString*)name
		   size:(CGFloat)size;
/** Get text size in given font */
+(NSSize)string:(NSString*)str
   sizeWithFont:(NSFont*)font;
/** Return a cut down string within size */
+ (NSString*)string:(NSString *)string cutShortInSystemFontWithWidth:(CGFloat)width size:(CGFloat)fontSize;
+(NSString*)string:(NSString*)string
 cutShortWithWidth:(CGFloat)width
		inFontName:(NSString*)fontName
			  size:(CGFloat)fontSize;


#pragma mark - Key tools
/** Check whether a key is return key */
+(BOOL)keyIsReturnKey:(unichar)key;
/** Check wiether a key is escape key */
+(BOOL)keyIsEscapeKey:(unichar)key;
#endif


/** Encrypt NSData using AES */
#pragma mark - AES encryption tools
+(NSData*)dataEncrypedFrom:(NSData*)data
				   withKey:(NSData*)key;
/** Decrypt NSData using AES */
+(NSData*)dataDecrypedFrom:(NSData*)data
				   withKey:(NSData*)key;


/* colorful strings */
#pragma mark - NSAttriutedString
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+(NSAttributedString*)string:(NSString*)string
				   withColor:(NSColor*)color;
#endif

/* Security tools */
#pragma mark - Security
#if CFG_FRAMEWORK_SECURITY
/** Examie root permission. */
+(BOOL)authorize;
#endif

/* NSOpenSavePanel tools */
#pragma mark - NSOpenSavePanel
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
/** Open a save panel and return a file URL with specified extension. */
+ (NSURL*)fileSaveURLWithExtension:(NSString*)extension;
/** Open a save panel and return a file URL with specified extension and delegate. */
+ (NSURL*)fileSaveURLWithExtension:(NSString*)extension
						  delegate:(id<NSOpenSavePanelDelegate>)delegate;
/** Open an open panel and return a file URL. */
+ (NSURL*)fileOpenURLWithDelegate:(id<NSOpenSavePanelDelegate>)delegate;
+ (NSURL *)fileOpenURLDirectoryWithDelegate:(id<NSOpenSavePanelDelegate>)delegate;
+ (NSURL *)fileOpenURLDirectoryWithBeginDirectory:(NSString*)directoryPath
										 delegate:(id<NSOpenSavePanelDelegate>)delegate;
+ (NSURL *)fileOpenURLDirectoryWithBeginDirectory:(NSString*)directoryPath
							 canCreateDirectories:(BOOL)flag
										 delegate:(id<NSOpenSavePanelDelegate>)delegate;
#endif

/* NSTextField Set color tool */
#pragma mark - NSTextField
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
/** Set Text Field text color */
+ (void)setTextField:(NSTextField*)textField
		   textColor:(NSColor*)color;
+ (NSTextField*)makeATextFieldInLabelAppearance;
/** get text field selection range */
+ (NSRange)selectionForTextField:(NSTextField*)textField;
/** set text field selection range */
+ (void)setTextField:(NSTextField*)textField selection:(NSRange)selection;
#endif

/* NSButton set color tool */
#pragma mark  - NSButton
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
/** Set button text color */
+ (void)setButton:(NSButton*)button
	   titleColor:(NSColor*)color;
#endif

/* NSDate tools */
#pragma mark - NSDate
+ (NSTimeInterval) time;
+ (NSTimeInterval) timeDifferenceBetween:(NSTimeInterval)time1
								 andTime:(NSTimeInterval)time2;
+ (NSString*) timeStringForDate:(NSDate*)date
				 withDateFormat:(NSString*)format;
+ (NSString*) timeStringForCurrentTimeWithDateFormat:(NSString*)format;
+ (void) addSystemClockChangeObserver:(id)target
							 selector:(SEL)aSelector
							   object:(id)anObject;
+ (void) removeSystemClockChangeObserver:(id)target
								  object:(id)anObject;
+ (NSTimeInterval) systemUpTime;


/** Sleep for some time */
#pragma mark - Sleep by NSTimeInterval (double) value
+ (void)sleep:(NSTimeInterval)time;
+ (void)sleepToNextSecond;
+ (void)sleepUntilSeconds:(NSUInteger)seconds;

/* NSTableView tools */
#pragma mark - NSTableView
/** Set table view column titles */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (void)setTableView:(NSTableView*)tableView
withColumnIdentifier:(NSString*)identifier
			   title:(NSString*)title;
#endif


/* NSView tools */
#pragma mark - NSView
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSView*) subViewWithIdentifier:(NSString*)identifier inView:(NSView*)superview;
+ (NSImage*) screenshotPdfForView:(NSView*)view;
+ (void) drawLineFromPoint:(NSPoint)start toPoint:(NSPoint)end;
#endif


/* Status bar tools */
#pragma mark - NSStatusbar
/** Get height of status bar */
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (CGFloat)statusBarThickness;
#endif

/* Base-64 tools */
#pragma mark - Base-64
#if CFG_FRAMEWORK_SECURITY
/** Base-64 encoding */
+ (NSString*)base64EncodeWith:(NSData*)input;
/** Base-64 decoding */
+ (NSData*)base64DecodeWith:(NSString*)input;
/** Base-64 string encoding */
+ (NSString*)stringBase64EncodeWith:(NSString*)input;
/** Base-64 string deciding */
+ (NSString*)stringBase64DecodeWith:(NSString*)input;
#endif

/* MD5 tools */
/** MD5 calculation */
+ (NSString*)MD5ChecksumStringWithData:(NSData*)data;
+ (NSData*)MD5ChecksumDataWithData:(NSData*)data;
+ (BOOL)data:(NSData*)data conformsMD5ChecksumString:(NSString*)md5String;
+ (BOOL)data:(NSData*)data conformsMD5ChecksumData:(NSData*)md5Data;

/* NSThread tools */
#pragma mark - NSThread
+ (BOOL)isInMainThread;

/* Misc tools */
#pragma mark - Misc tools
+ (BOOL)isSystemBigEndian;
+ (BOOL)isSystemLittleEndian;
+ (NSString*)descriptionWithNSRect:(NSRect)rect;
+ (NSString*)descriptionWithNSSize:(NSSize)size;
+ (NSString*)descriptionWithNSPoint:(NSPoint)point;
+ (NSString*)descriptionReadableForNSData:(NSData*)data;
+ (NSString*)descriptionReadableForBytes:(const void*)bytes
								  length:(NSUInteger)length;
+ (NSString*)descriptionWithNSRange:(NSRange)range;
+ (NSString*)descriptionReadableAppleCharForNSData:(NSData *)data;
+ (NSString*)descriptionReadableAppleCharForBytes:(void *)bytes length:(NSUInteger)length;
+ (NSString*)descriptionWithSelector:(SEL)selector;
+ (NSString*)descriptionWithMACLong:(uint64_t)MACInt separator:(NSString*)separator;
+ (NSString*)bitMaskDescriptionWithUnsignedInteger:(NSUInteger)bits;
+ (uint64_t)htonll:(uint64_t)data;
+ (uint64_t)ntohll:(uint64_t)data;
+ (uint16_t)htoles:(uint16_t)data;
+ (uint16_t)ntoles:(uint16_t)data;
+ (uint32_t)htolel:(uint32_t)data;
+ (uint32_t)ntolel:(uint32_t)data;
+ (uint64_t)htolell:(uint64_t)data;
+ (uint64_t)ntolell:(uint64_t)data;
+ (uint16_t)letohs:(uint16_t)data;
+ (uint16_t)letons:(uint16_t)data;
+ (uint32_t)letohl:(uint32_t)data;
+ (uint32_t)letonl:(uint32_t)data;
+ (uint64_t)letohll:(uint64_t)data;
+ (uint64_t)letonll:(uint64_t)data;
+ (BOOL)isPoint:(NSPoint)point
		 inRect:(NSRect)rect;
+ (NSString *)weblocContentWithWebLocation:(NSString *)webLoc;
/** check whether two selector share a same name */
+ (BOOL)isSelector:(SEL)selectorA equalTo:(SEL)selectorB;
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
/** get system OS name and version string */
+ (NSString*)descriptionForOS;
+ (NSString *)versionForOS;
+ (BOOL)isOSXYosemiteOrLater;
#endif
/** get current caller in stack */
+ (NSString*)descriptionForCallerOfCurrentMethod;

/** open website */
+ (void)openWebSite:(NSString*)webPathWithHttpLeading;
/** Fast inverse Square Root */
+ (CGFloat)fastInverseSquareRoot:(CGFloat)input;
/** Fast Square Root */
+ (CGFloat)fastSquareRoot:(CGFloat)input;
/** float rounding */
+ (CGFloat)floatRound:(CGFloat)input;
/** float round-up */
+ (CGFloat)floatRoundUp:(CGFloat)input;
/** float round-down */
+ (CGFloat)floatRoundDown:(CGFloat)input;
/** Barrel increasing/decresing */
+ (void)barrelIncreaseUInt:(void*)pNum
					  UInt:(size_t)numSize
				 increment:(NSUInteger)increment
				barrelSize:(NSUInteger)barrelSize;
+ (void)barrelIncreaseUInt8:(uint8_t*)pUint8 increment:(uint8_t)increment barrelSize:(uint8_t)barrelSize;
+ (void)barrelIncreaseUInt16:(uint16_t*)pUint16 increment:(uint16_t)increment barrelSize:(uint16_t)barrelSize;
+ (void)barrelIncreaseUInt32:(uint32_t*)pUint32 increment:(uint32_t)increment barrelSize:(uint32_t)barrelSize;
+ (void)barrelIncreaseUInt64:(uint64_t*)pUint64 increment:(uint64_t)increment barrelSize:(uint64_t)barrelSize;
+ (void)barrelIncreaseUInteger:(NSUInteger*)pUinteger increment:(NSUInteger)increment barrelSize:(NSUInteger)barrelSize;

/* File tools */
#pragma mark - File operation
+ (BOOL)isFileExist:(NSString*)path;
+ (BOOL)isFilePathDirectory:(NSString*)path;
+ (BOOL)isFilePathFile:(NSString*)path;
+ (BOOL)removeFileAtPath:(NSString*)path error:(NSError *__autoreleasing *)errorPtr;
+ (BOOL)removeFileAtPath:(NSString*)path;
+ (BOOL)createDirectoryAtPath:(NSString*)path;
+ (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)errorPtr;
+ (NSArray*)fileListInFolder:(NSString*)folder withExtension:(NSString*)extension;
+ (NSArray*)fileListInFolder:(NSString*)folder;
+ (BOOL)makeSureIsDirectoryInPath:(NSString*)path;
+ (BOOL)makeSureIsFileInPath:(NSString*)path;
+ (BOOL)makeTargetURL:(NSURL*)fromURL toAliasURL:(NSURL*)toURL;
+ (BOOL)moveContentsFromFolder:(NSString*)from toFolder:(NSString*)to;
#if CFG_FRAMEWORK_CORE_FOUNDATION
+ (BOOL)isFilePathAlias:(NSString*)path;
#endif


/* NSURL tools */
#pragma mark - NSURL
+ (BOOL)isURLWritable:(NSURL*)url;
+ (BOOL)isPathWritable:(NSString*)path;
+ (NSURL*)URLWithPath:(NSString*)path;

/* NSTextView tools */
#pragma mark - NSTextView
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (void)textViewScrollToEnd:(NSTextView*)view;
#endif

/* NSColor tools */
#pragma mark - NSColor
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
+ (NSColor*)colorWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue;
#endif

/* Network interfaces tools */
#pragma mark - Network
#if CFG_FRAMEWORK_SYSTEM_CONFIGURATION
+ (NSDictionary*)localIPInformation;
+ (NSUInteger)ipCountInIPInformation:(NSDictionary*)info;
+ (NSString*)ipAddressInInformation:(NSDictionary*)info
							atIndex:(NSUInteger)index;
+ (NSString*)broadcastAddressInInformation:(NSDictionary*)info
								   atIndex:(NSUInteger)index;
+ (NSString*)subnetMaskAddressInInformation:(NSDictionary*)info
									atIndex:(NSUInteger)index;
#endif


/* layout constraints tools */
#pragma mark - Layout constraint
#if (CFG_SDK_TYPE == SDK_TYPE_OS_X)
//+ (NSArray*)layoutConstraintsForView:(NSView*)subview
//						   superView:(NSView*)superview
//						leftDistance:(CGFloat)left
//					   rightDistance:(CGFloat)right
//						 topDistance:(CGFloat)top
//					  bottomDistance:(CGFloat)bottom;
+ (NSLayoutConstraint*)constraintWithTarget:(NSView*)target width:(CGFloat)width;
+ (NSLayoutConstraint*)constraintWithTarget:(NSView*)target height:(CGFloat)height;
#endif

@end
