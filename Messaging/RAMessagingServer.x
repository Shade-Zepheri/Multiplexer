#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "RAMessagingServer.h"
#import "RASpringBoardKeyboardActivation.h"
#import "dispatch_after_cancel.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#import "RAKeyboardStateListener.h"
#import "RASettings.h"
#import "RAAppKiller.h"
#import "RADesktopManager.h"
#import "RAWindowSnapDataProvider.h"
#import "RAHostManager.h"
#import "Multiplexer.h"
#import "UIAlertController+Window.h"

BOOL launchNextOpenIntoWindow = NO;

//hack so I can compile
RAWindowSnapLocation RAWindowSnapLocationGetLeftOfScreen() {
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationUnknown:
		case UIInterfaceOrientationPortrait:
			return RAWindowSnapLocationLeft;
		case UIInterfaceOrientationLandscapeRight:
			return RAWindowSnapLocationTop;
		case UIInterfaceOrientationLandscapeLeft:
			return RAWindowSnapLocationBottom;
		case UIInterfaceOrientationPortraitUpsideDown:
			return RAWindowSnapLocationRight;
	}
	return RAWindowSnapLocationLeft;
}

RAWindowSnapLocation RAWindowSnapLocationGetRightOfScreen() {
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationUnknown:
		case UIInterfaceOrientationPortrait:
			return RAWindowSnapLocationRight;
		case UIInterfaceOrientationLandscapeRight:
			return RAWindowSnapLocationBottom;
		case UIInterfaceOrientationLandscapeLeft:
			return RAWindowSnapLocationTop;
		case UIInterfaceOrientationPortraitUpsideDown:
			return RAWindowSnapLocationLeft;
	}
	return RAWindowSnapLocationRight;
}

@interface RAMessagingServer () {
	NSMutableDictionary *asyncHandles;
}
@end

@implementation RAMessagingServer
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RAMessagingServer,
		[sharedInstance loadServer];
		sharedInstance->dataForApps = [NSMutableDictionary dictionary];
		sharedInstance->contextIds = [NSMutableDictionary dictionary];
		sharedInstance->waitingCompletions = [NSMutableDictionary dictionary];
		sharedInstance->asyncHandles = [NSMutableDictionary dictionary];
	);
}

- (void)loadServer {
	messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.efrederickson.reachapp.messaging.server"];

	void *handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
	if (handle) {
		void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter *) = (void(*)(CPDistributedMessagingCenter *))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
		rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
		dlclose(handle);
	}

	[messagingCenter runServerOnCurrentThread];

	[messagingCenter registerForMessageName:RAMessagingShowKeyboardMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingHideKeyboardMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingUpdateKeyboardContextIdMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingRetrieveKeyboardContextIdMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingUpdateAppInfoMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];

	[messagingCenter registerForMessageName:RAMessagingUpdateKeyboardSizeMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingOpenURLKMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];

	[messagingCenter registerForMessageName:RAMessagingGetFrontMostAppInfoMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingChangeFrontMostAppMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];

	[messagingCenter registerForMessageName:RAMessagingSnapFrontMostWindowLeftMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingSnapFrontMostWindowRightMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingGoToDesktopOnTheLeftMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingGoToDesktopOnTheRightMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingMaximizeAppMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingAddNewDesktopMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingCloseAppMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
	[messagingCenter registerForMessageName:RAMessagingDetachCurrentAppMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
}

- (NSDictionary *)handleMessageNamed:(NSString *)identifier userInfo:(NSDictionary *)info {
	if ([identifier isEqualToString:RAMessagingShowKeyboardMessageName]) {
		[self receiveShowKeyboardForAppWithIdentifier:info[@"bundleIdentifier"]];
	} else if ([identifier isEqualToString:RAMessagingHideKeyboardMessageName]) {
		[self receiveHideKeyboard];
	} else if ([identifier isEqualToString:RAMessagingUpdateKeyboardContextIdMessageName]) {
		[self setKeyboardContextId:[info[@"contextId"] integerValue] forIdentifier:info[@"bundleIdentifier"]];
	} else if ([identifier isEqualToString:RAMessagingRetrieveKeyboardContextIdMessageName]) {
		return @{ @"contextId": @([self getStoredKeyboardContextIdForApp:info[@"bundleIdentifier"]]) };
	} else if ([identifier isEqualToString:RAMessagingUpdateKeyboardSizeMessageName]) {
		CGSize size = CGSizeFromString(info[@"size"]);
		[[RAKeyboardStateListener sharedInstance] _setSize:size];
	} else if ([identifier isEqualToString:RAMessagingUpdateAppInfoMessageName]) {
		NSString *identifier = info[@"bundleIdentifier"];
		RAMessageAppData data = [self getDataForIdentifier:identifier];

		if ([waitingCompletions objectForKey:identifier]) {
			RAMessageCompletionCallback callback = (RAMessageCompletionCallback)waitingCompletions[identifier];
			[waitingCompletions removeObjectForKey:identifier];
			callback(YES);
		}

		// Got the message, cancel the re-sender
		if ([asyncHandles objectForKey:identifier]) {
			dispatch_async_handle *handle = (dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
			dispatch_after_cancel(handle);
			[asyncHandles removeObjectForKey:identifier];
		}

		return @{
			@"data": [NSData dataWithBytes:&data length:sizeof(data)],
		};
	} else if ([identifier isEqualToString:RAMessagingOpenURLKMessageName]) {
		//NSURL *url = [NSURL URLWithString:info[@"url"]];
		BOOL openInWindow = [[RASettings sharedInstance] openLinksInWindows]; // [info[@"openInWindow"] boolValue];
		if (openInWindow) {
			launchNextOpenIntoWindow = YES;
		}

		//BOOL success = [[UIApplication sharedApplication] openURL:url];
		return @{ @"success": @(YES) };
	} else if ([identifier isEqualToString:RAMessagingGetFrontMostAppInfoMessageName]) {
		if ([UIApplication sharedApplication]._accessibilityFrontMostApplication) {
			return nil;
		}
		RAWindowBar *window = [[%c(RADesktopManager) sharedInstance] lastUsedWindow];
		if (window) {
			SBApplication *app = window.attachedView.app;
			if (app.pid) {
				return @{
					@"pid": @(app.pid),
					@"bundleIdentifier": app.bundleIdentifier
				};
			}
		}
	} else if ([identifier isEqualToString:RAMessagingChangeFrontMostAppMessageName]) {
		NSString *bundleIdentifier = info[@"bundleIdentifier"];
		RAWindowBar *window = [[%c(RADesktopManager) sharedInstance] windowForIdentifier:bundleIdentifier];
		if (window) {
			[[%c(RADesktopManager) sharedInstance] setLastUsedWindow:window];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.frontmostAppDidUpdate"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": bundleIdentifier }, YES);
		}
	}

	return nil;
}

- (void)handleKeyboardEvent:(NSString *)identifier userInfo:(NSDictionary *)info {
	if ([identifier isEqualToString:RAMessagingDetachCurrentAppMessageName]) {
		SBApplication *topApp = [[UIApplication sharedApplication] _accessibilityFrontMostApplication];

		if (topApp) {
		  [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];
		  [[%c(SBUIController) sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];

		  UIView *appView = [RAHostManager systemHostViewForApplication:topApp].superview;

		 	[UIView animateWithDuration:0.2 animations:^{
		  	appView.transform = CGAffineTransformMakeScale(0.5, 0.5);
		  } completion:^(BOOL _) {
				[[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
				FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
					SBDeactivationSettings *deactiveSets = [[%c(SBDeactivationSettings) alloc] init];
				  [deactiveSets setFlag:YES forDeactivationSetting:20];
				  [deactiveSets setFlag:NO forDeactivationSetting:2];
				  [topApp _setDeactivationSettings:deactiveSets];

				  SBAppToAppWorkspaceTransaction *transaction = [Multiplexer createSBAppToAppWorkspaceTransactionForExitingApp:topApp];
				  [transaction begin];
				}];
				[(FBWorkspaceEventQueue *)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
				[[[%c(RADesktopManager) sharedInstance] currentDesktop] createAppWindowForSBApplication:topApp animated:YES];
		  }];
		}
	} else if ([identifier isEqualToString:RAMessagingGoToDesktopOnTheLeftMessageName]) {
		NSInteger newIndex = [[%c(RADesktopManager) sharedInstance] currentDesktopIndex] - 1;
		BOOL isValid = newIndex >= 0 && newIndex <= [[%c(RADesktopManager) sharedInstance] numberOfDesktops];
		if (isValid) {
			[[%c(RADesktopManager) sharedInstance] switchToDesktop:newIndex];
		}
	} else if ([identifier isEqualToString:RAMessagingGoToDesktopOnTheRightMessageName]) {
		NSInteger newIndex = [[%c(RADesktopManager) sharedInstance] currentDesktopIndex] + 1;
		BOOL isValid = newIndex >= 0 && newIndex < [[%c(RADesktopManager) sharedInstance] numberOfDesktops];
		if (isValid)
			[[%c(RADesktopManager) sharedInstance] switchToDesktop:newIndex];
	} else if ([identifier isEqualToString:RAMessagingAddNewDesktopMessageName]) {
		[[%c(RADesktopManager) sharedInstance] addDesktop:YES];
	}

	RAWindowBar *window = [[%c(RADesktopManager) sharedInstance] lastUsedWindow];
	if (!window) {
		return;
	}
	if ([identifier isEqualToString:RAMessagingSnapFrontMostWindowLeftMessageName]) {
		[%c(RAWindowSnapDataProvider) snapWindow:window toLocation:RAWindowSnapLocationGetLeftOfScreen() animated:YES];
	} else if ([identifier isEqualToString:RAMessagingSnapFrontMostWindowRightMessageName]) {
		[%c(RAWindowSnapDataProvider) snapWindow:window toLocation:RAWindowSnapLocationGetRightOfScreen() animated:YES];
	} else if ([identifier isEqualToString:RAMessagingMaximizeAppMessageName]) {
		[window maximize];
	} else if ([identifier isEqualToString:RAMessagingCloseAppMessageName]) {
		[window close];
	}
}

- (void)alertUser:(NSString *)description {
#if DEBUG
	if (![[RASettings sharedInstance] debug_showIPCMessages]) {
		return;
	}

	UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"MULTIPLEXER", @"Localizable") message:description preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[alert show];
#endif
}

- (RAMessageAppData)getDataForIdentifier:(NSString *)identifier {
	RAMessageAppData ret;
	if ([dataForApps objectForKey:identifier]) {
		[dataForApps[identifier] getValue:&ret];
	} else {
		// Initialize with some default values
		ret.shouldForceSize = NO;
		ret.wantedClientOriginX = -1;
		ret.wantedClientOriginY = -1;
		ret.wantedClientWidth = -1;
		ret.wantedClientHeight = -1;
		ret.statusBarVisibility = YES;
		ret.shouldForceStatusBar = NO;
		ret.canHideStatusBarIfWanted = NO;
		ret.forcedOrientation = UIInterfaceOrientationPortrait;
		ret.shouldForceOrientation = NO;
		ret.forcePhoneMode = NO;
		ret.shouldUseExternalKeyboard = NO;
		ret.isBeingHosted = NO;
	}
	return ret;
}

- (void)setData:(RAMessageAppData)data forIdentifier:(NSString *)identifier {
	if (!identifier) {
		return;
	}

	dataForApps[identifier] = [NSValue valueWithBytes:&data objCType:@encode(RAMessageAppData)];
}

- (void)checkIfCompletionStillExitsForIdentifierAndFailIt:(NSString *)identifier {
	if (![waitingCompletions objectForKey:identifier]) {
		return;
	}
	// We timed out, remove the re-sender
	if ([asyncHandles objectForKey:identifier]) {
		dispatch_async_handle *handle = (dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
		dispatch_after_cancel(handle);
		[asyncHandles removeObjectForKey:identifier];
	}

	RAMessageCompletionCallback callback = (RAMessageCompletionCallback)waitingCompletions[identifier];
	[waitingCompletions removeObjectForKey:identifier];

	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
	[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app %@ (%@)", app.displayName, identifier]];
	callback(NO);
}

- (void)sendDataWithCurrentTries:(NSInteger)tries toAppWithBundleIdentifier:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
	if (!app.isRunning || ![app mainScene]) {
		if (tries > 4) {
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app that isn't running: %@ (%@)", app.displayName, identifier]];
			if (callback) {
				callback(NO);
			}
			return;
		}

		if ([asyncHandles objectForKey:identifier]) {
			dispatch_async_handle *handle = (dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
			dispatch_after_cancel(handle);
			[asyncHandles removeObjectForKey:identifier];
		}

		dispatch_async_handle *handle = dispatch_after_cancellable(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendDataWithCurrentTries:tries + 1 toAppWithBundleIdentifier:identifier completion:callback];
		});
		asyncHandles[identifier] = [NSValue valueWithPointer:handle];
		return;
	}

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[NSString stringWithFormat:@"com.efrederickson.reachapp.clientupdate-%@", identifier], nil, nil, YES);

	if (tries <= 4) {
		if ([asyncHandles objectForKey:identifier]) {
			dispatch_async_handle *handle = (dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
			dispatch_after_cancel(handle);
			[asyncHandles removeObjectForKey:identifier];
		}

		dispatch_async_handle *handle = dispatch_after_cancellable(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendDataWithCurrentTries:tries + 1 toAppWithBundleIdentifier:identifier completion:callback];
		});
		asyncHandles[identifier] = [NSValue valueWithPointer:handle];

		if (![waitingCompletions objectForKey:identifier]) {
			//if (callback == nil)
			//	callback = ^(BOOL _) { };
			if (callback) {
				waitingCompletions[identifier] = [callback copy];
			}
		}
		// Reset failure checker
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkIfCompletionStillExitsForIdentifierAndFailIt:) object:identifier];
		[self performSelector:@selector(checkIfCompletionStillExitsForIdentifierAndFailIt:) withObject:identifier afterDelay:4];
	}


/*
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier];

	if (!app.isRunning || [app mainScene] == nil)
	{
		if (tries > 4)
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app that isn't running: %@ (%@)", app.displayName, identifier]];
			if (callback)
				callback(NO);
			return;
		}

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendData:data toApp:center withCurrentTries:tries + 1 bundleIdentifier:identifier completion:callback];
		});
		return;
	}

	NSDictionary *success = [center sendMessageAndReceiveReplyName:RAMessagingUpdateAppInfoMessageName userInfo:data];

	if (!success || [success objectForKey:@"success"] == nil || [success[@"success"] boolValue] == NO)
	{
		if (tries <= 4)
		{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[self sendData:data toApp:center withCurrentTries:tries + 1 bundleIdentifier:identifier completion:callback];
			});
		}
		else
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app %@ (%@)\n\nadditional info: %@", app.displayName, identifier, success]];
			if (callback)
				callback(NO);
		}
	}
	else
		if (callback)
			callback(YES);
*/
}

- (void)sendStoredDataToApp:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	if (!identifier || identifier.length == 0) {
		return;
	}

	[self sendDataWithCurrentTries:0 toAppWithBundleIdentifier:identifier completion:callback];
}

- (void)resizeApp:(NSString *)identifier toSize:(CGSize)size completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.wantedClientWidth = size.width;
	data.wantedClientHeight = size.height;
	data.shouldForceSize = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)moveApp:(NSString *)identifier toOrigin:(CGPoint)origin completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.wantedClientOriginX = (float)origin.x;
	data.wantedClientOriginY = (float)origin.y;
	data.shouldForceSize = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)endResizingApp:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	//data.wantedClientSize = CGSizeMake(-1, -1);
	data.shouldForceSize = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)rotateApp:(NSString *)identifier toOrientation:(UIInterfaceOrientation)orientation completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];

	if (data.forcePhoneMode) {
		return;
	}

	data.forcedOrientation = orientation;
	data.shouldForceOrientation = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)unRotateApp:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.forcedOrientation = [UIApplication sharedApplication].statusBarOrientation;
	data.shouldForceOrientation = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)forceStatusBarVisibility:(BOOL)visibility forApp:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldForceStatusBar = YES;
	data.statusBarVisibility = visibility;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)unforceStatusBarVisibilityForApp:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldForceStatusBar = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)setShouldUseExternalKeyboard:(BOOL)value forApp:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldUseExternalKeyboard = value;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)setHosted:(BOOL)value forIdentifier:(NSString *)identifier completion:(RAMessageCompletionCallback)callback {
	RAMessageAppData data = [self getDataForIdentifier:identifier];
	data.isBeingHosted = value;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

- (void)forcePhoneMode:(BOOL)value forIdentifier:(NSString *)identifier andRelaunchApp:(BOOL)relaunch {
	RAMessageAppData data = [self getDataForIdentifier:identifier];

	data.forcePhoneMode = value;
	[self setData:data forIdentifier:identifier];

	if (relaunch) {
		[RAAppKiller killAppWithIdentifier:identifier completion:^{
			[[%c(RADesktopManager) sharedInstance] updateWindowSizeForApplication:identifier];
		}];
	}
}

- (void)receiveShowKeyboardForAppWithIdentifier:(NSString *)identifier {
	[[RASpringBoardKeyboardActivation sharedInstance] showKeyboardForAppWithIdentifier:identifier];
}

- (void)receiveHideKeyboard {
	[[RASpringBoardKeyboardActivation sharedInstance] hideKeyboard];
}

- (void)setKeyboardContextId:(NSUInteger)id forIdentifier:(NSString *)identifier {
	LogDebug(@"[ReachApp] got c id %tu", id);
	contextIds[identifier] = @(id);
}

- (NSUInteger)getStoredKeyboardContextIdForApp:(NSString *)identifier {
	return ![contextIds objectForKey:identifier] ? 0 : [contextIds[identifier] unsignedIntValue];
}
@end

%ctor {
	IF_NOT_SPRINGBOARD {
		return;
	}

	[RAMessagingServer sharedInstance];
}