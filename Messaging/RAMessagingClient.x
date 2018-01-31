#import "RAMessagingClient.h"
#import "UIAlertController+Window.h"

BOOL allowClosingReachabilityNatively = NO;;

@interface RAMessagingClient ()

+ (BOOL)isProcessIsEligible;

@end

@implementation RAMessagingClient

+ (instancetype)defaultAppClient {
	IF_SPRINGBOARD {
		@throw [NSException exceptionWithName:@"IsSpringBoardException" reason:@"Cannot use RAMessagingClient in SpringBoard" userInfo:nil];
	}

  if (![RAMessagingClient isProcessIsEligible]) {
    LogError(@"Not a valid process for RAMessagingClient");
    return nil;
  }

	SHARED_INSTANCE2(RAMessagingClient,
		[sharedInstance loadMessagingCenter];
		sharedInstance.hasRecievedData = NO;
	);
}

+ (BOOL)isProcessIsEligible {
	//Much cleaner check (i hope)
	NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
	LSApplicationProxy *applicationProxy = [%c(LSApplicationProxy) applicationProxyForIdentifier:bundleIdentifier];
	return [applicationProxy isInstalled]; //no dot syntax because property name changes on iOS 11
}

- (void)loadMessagingCenter {
	RAMessageAppData data;

	data.shouldForceSize = NO;
	data.wantedClientOriginX = -1;
	data.wantedClientOriginY = -1;
	data.wantedClientWidth = -1;
	data.wantedClientHeight = -1;
	data.statusBarVisibility = YES;
	data.shouldForceStatusBar = NO;
	data.canHideStatusBarIfWanted = NO;
	data.forcedOrientation = UIInterfaceOrientationPortrait;
	data.shouldForceOrientation = NO;
	data.shouldUseExternalKeyboard = NO;
	data.forcePhoneMode = NO;
	data.isBeingHosted = NO;

	_currentData = data; // Initialize data

	_serverCenter = [CPDistributedMessagingCenter centerNamed:@"com.efrederickson.reachapp.messaging.server"];
  rocketbootstrap_distributedmessagingcenter_apply(_serverCenter);
}

- (void)alertUser:(NSString *)description {
#if DEBUG
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"MULTIPLEXER", @"Localizable") message:description preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[alert show];
#endif
}

- (void)_requestUpdateFromServerWithTries:(NSInteger)tries {
	NSDictionary *dict = @{ @"bundleIdentifier": [NSBundle mainBundle].bundleIdentifier };
	NSDictionary *data = [_serverCenter sendMessageAndReceiveReplyName:RAMessagingUpdateAppInfoMessageName userInfo:dict];
	if (data && [data objectForKey:@"data"]) {
		RAMessageAppData actualData;
		[data[@"data"] getBytes:&actualData length:sizeof(actualData)];
		[self updateWithData:actualData];
		self.hasRecievedData = YES;
	} else {
		if (tries <= 4) {
			[self _requestUpdateFromServerWithTries:tries + 1];
		} else {
			[self alertUser:[NSString stringWithFormat:@"App \"%@\" is unable to communicate with messaging server", [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"] ?: [NSBundle mainBundle].bundleIdentifier]];
		}
	}
}

- (void)requestUpdateFromServer {
	[self _requestUpdateFromServerWithTries:0];
}

- (void)updateWithData:(RAMessageAppData)data {
	BOOL didStatusBarVisibilityChange = _currentData.shouldForceStatusBar != data.shouldForceStatusBar;
	BOOL didOrientationChange = _currentData.shouldForceOrientation != data.shouldForceOrientation;
	BOOL didSizingChange  =_currentData.shouldForceSize != data.shouldForceSize;

	/* THE REAL IMPORTANT BIT */
	_currentData = data;

	if (didStatusBarVisibilityChange && !data.shouldForceStatusBar) {
		[[UIApplication sharedApplication] RA_forceStatusBarVisibility:_currentData.statusBarVisibility orRevert:YES];
	} else if (data.shouldForceStatusBar) {
		[[UIApplication sharedApplication] RA_forceStatusBarVisibility:_currentData.statusBarVisibility orRevert:NO];
	}

	if (didSizingChange && !data.shouldForceSize) {
		[[UIApplication sharedApplication] RA_updateWindowsForSizeChange:CGSizeMake(data.wantedClientWidth, data.wantedClientHeight) isReverting:YES];
	} else if (data.shouldForceSize) {
		[[UIApplication sharedApplication] RA_updateWindowsForSizeChange:CGSizeMake(data.wantedClientWidth, data.wantedClientHeight) isReverting:NO];
	}

	if (didOrientationChange && !data.shouldForceOrientation) {
		[[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:data.forcedOrientation isReverting:YES];
	} else if (data.shouldForceOrientation) {
		[[UIApplication sharedApplication] RA_forceRotationToInterfaceOrientation:data.forcedOrientation isReverting:NO];
	}

	allowClosingReachabilityNatively = YES;
}

- (void)notifyServerWithKeyboardContextId:(NSUInteger)cid {
	NSDictionary *dict = @{ @"contextId": @(cid), @"bundleIdentifier": [NSBundle mainBundle].bundleIdentifier };
	[_serverCenter sendMessageName:RAMessagingUpdateKeyboardContextIdMessageName userInfo:dict];
}

- (void)notifyServerToShowKeyboard {
	NSDictionary *dict = @{ @"bundleIdentifier": [NSBundle mainBundle].bundleIdentifier };
	[_serverCenter sendMessageName:RAMessagingShowKeyboardMessageName userInfo:dict];
}

- (void)notifyServerToHideKeyboard {
	[_serverCenter sendMessageName:RAMessagingHideKeyboardMessageName userInfo:nil];
}

- (void)notifyServerOfKeyboardSizeUpdate:(CGSize)size {
	NSDictionary *dict = @{ @"size": NSStringFromCGSize(size) };
	[_serverCenter sendMessageName:RAMessagingUpdateKeyboardSizeMessageName userInfo:dict];
}

- (BOOL)notifyServerToOpenURL:(NSURL *)url openInWindow:(BOOL)openWindow {
	NSDictionary *dict = @{
		@"url": url.absoluteString,
		@"openInWindow": @(openWindow)
	};
	return [[_serverCenter sendMessageAndReceiveReplyName:RAMessagingOpenURLKMessageName userInfo:dict][@"success"] boolValue];
}

- (void)notifySpringBoardOfFrontAppChangeToSelf {
	NSString *ident = [NSBundle mainBundle].bundleIdentifier;
	if (!ident) {
		return;
	}

	if ([self isBeingHosted] && (!self.knownFrontmostApp || ![self.knownFrontmostApp isEqualToString:ident])) {
		[_serverCenter sendMessageName:RAMessagingChangeFrontMostAppMessageName userInfo:@{ @"bundleIdentifier": ident }];
	}
}

- (BOOL)shouldUseExternalKeyboard {
	return _currentData.shouldUseExternalKeyboard;
}

- (BOOL)shouldResize {
	return _currentData.shouldForceSize;
}

- (CGSize)resizeSize {
	return CGSizeMake(_currentData.wantedClientWidth, _currentData.wantedClientHeight);
}

- (BOOL)shouldHideStatusBar {
	return _currentData.shouldForceStatusBar && !_currentData.statusBarVisibility;
}

- (BOOL)shouldShowStatusBar {
	return _currentData.shouldForceStatusBar && _currentData.statusBarVisibility;
}

- (UIInterfaceOrientation)forcedOrientation {
	return _currentData.forcedOrientation;
}

- (BOOL)shouldForceOrientation {
	return _currentData.shouldForceOrientation;
}

- (BOOL)isBeingHosted {
	return _currentData.isBeingHosted;
}

@end

static inline void reloadClientData(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[RAMessagingClient defaultAppClient] requestUpdateFromServer];
}

static inline void updateFrontmostApp(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[RAMessagingClient defaultAppClient].knownFrontmostApp = ((__bridge NSDictionary *)userInfo)[@"bundleIdentifier"];
}

%ctor {
	IF_SPRINGBOARD {
		return;
	}

	[RAMessagingClient defaultAppClient];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadClientData, (__bridge CFStringRef)[NSString stringWithFormat:@"com.efrederickson.reachapp.clientupdate-%@",[NSBundle mainBundle].bundleIdentifier], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, &updateFrontmostApp, CFSTR("com.efrederickson.reachapp.frontmostAppDidUpdate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
