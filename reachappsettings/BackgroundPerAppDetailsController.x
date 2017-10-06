#import "Main.h"
#import "BackgroundPerAppDetailsController.h"
#import "RABackgrounder.h"
#import "headers.h"

extern void RA_BGAppsControllerNeedsToReload();

@implementation RABGPerAppDetailsController
- (instancetype)initWithAppName:(NSString *)appName identifier:(NSString *)identifier {
	_appName = appName;
	_identifier = identifier;
	return [self init];
}

- (NSString *)customTitle {
	return self.appName;
}

- (BOOL)showHeartImage {
	return NO;
}

- (UIColor *)navigationTintColor {
	return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f];
}

- (id)isBackgroundModeActive:(NSString *)mode withAppInfo:(NSArray *)info {
	return [info containsObject:mode] ? @YES : @NO;
}

- (NSArray *)customSpecifiers {
	LSApplicationProxy *appInfo = [%c(LSApplicationProxy) applicationProxyForIdentifier:self.identifier];
	NSArray *bgModes = appInfo.UIBackgroundModes;

	BOOL exitsOnSuspend = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/Info.plist", appInfo.bundleURL.absoluteString]]][@"UIApplicationExitsOnSuspend"] boolValue];

	BOOL preventDeath = [[self getActualPrefValue:@"preventDeath"] boolValue]; // Default is NO so it should work fine

	return @[
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"ENABLED", @"Root"),
			@"key": @"enabled",
			@"default": @NO,
		},

		@{ @"label": @""},
		@{
			@"cell": @"PSLinkListCell",
			@"label": LOCALIZE(@"BACKGROUND_MODE", @"Aura"),
			@"key": @"backgroundMode",
			@"validTitles": @[LOCALIZE(@"NATIVE", @"Aura"), LOCALIZE(@"UNLIMITED_BACKGROUND", @"Aura"), LOCALIZE(@"FORCE_FOREGROUND", @"Aura"), LOCALIZE(@"KILL_ON_EXIT", @"Aura"), LOCALIZE(@"SUSPEND_IMMEDIATELY", @"Aura")],
			@"validValues": @[@(RABackgroundModeNative), @(RABackgroundModeUnlimitedBackgroundingTime), @(RABackgroundModeForcedForeground), @(RABackgroundModeForceNone), @(RABackgroundModeSuspendImmediately)],
			@"shortTitles": @[@"Native", @"∞", @"Forced", @"Disabled", @"SmartClose"],
			@"default": @(RABackgroundModeNative),
			@"detail": @"RABackgroundingListItemsController"
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"AUTO_LAUNCH", @"Aura"),
			@"key": @"autoLaunch",
			@"default": @NO,
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"AUTO_RELAUNCH", @"Aura"),
			@"key": @"autoRelaunch",
			@"default": @NO,
		},

		@{ @"footerText": LOCALIZE(@"SWITCHER_FOOTER", @"Aura") },
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"REMOVE_FROM_SWITCHER", @"Aura"),
			@"key": @"removeFromSwitcher",
			@"default": @NO,
		},

		@{ @"footerText": LOCALIZE(@"PREVENT_DEATH_FOOTER", @"Aura") },
		@{
			@"cell": @"PSSwitchCell",
			@"key": @"preventDeath",
			@"default": @NO,
			@"label": LOCALIZE(@"PREVENT_DEATH", @"Aura"),
			@"enabled": @(!exitsOnSuspend),
			@"reloadSpecifiersXX": @YES,
		},
		@{ @"footerText": LOCALIZE(@"EXIT_ON_SUSPEND_FOOTER", @"Aura") },
		@{
			@"cell": @"PSSwitchCell",
			@"key": @"UIApplicationExitsOnSuspend",
			@"default": @(exitsOnSuspend),
			@"label": LOCALIZE(@"EXIT_ON_SUSPEND", @"Aura"),
			@"enabled": @(!preventDeath),
			@"reloadSpecifiersXX": @YES,
		},
		@{
			@"cell": @"PSGroupCell",
			@"label": LOCALIZE(@"NATIVE_MODES", @"Aura"),
			@"footerText": LOCALIZE(@"NATIVE_MODES_FOOTER", @"Aura"),
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"TASK_COMPLETION", @"Aura"),
			@"key": kBKSBackgroundModeUnboundedTaskCompletion,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeUnboundedTaskCompletion withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"CONTINUOUS", @"Aura"),
			@"key": kBKSBackgroundModeContinuous,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeContinuous withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"FETCH", @"Aura"),
			@"key": kBKSBackgroundModeFetch,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeFetch withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"REMOTE_NOTIFICATION", @"Aura"),
			@"key": kBKSBackgroundModeRemoteNotification,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeRemoteNotification withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"EXTERNAL_ACCESSORY", @"Aura"),
			@"key": kBKSBackgroundModeExternalAccessory,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeExternalAccessory withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"VOIP", @"Aura"),
			@"key": kBKSBackgroundModeVoIP,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeVoIP withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"LOCATION", @"Aura"),
			@"key": kBKSBackgroundModeLocation,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeLocation withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"AUDIO", @"Aura"),
			@"key": kBKSBackgroundModeAudio,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeAudio withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"BLUETOOTH_CENTRAL", @"Aura"),
			@"key": kBKSBackgroundModeBluetoothCentral,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeBluetoothCentral withAppInfo:bgModes],
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"BLUETOOTH_PERIPHERAL", @"Aura"),
			@"key": kBKSBackgroundModeBluetoothPeripheral,
			@"prefix": @"backgroundmodes",
			@"default": [self isBackgroundModeActive:kBKSBackgroundModeBluetoothPeripheral withAppInfo:bgModes],
		},

		@{ @"footerText": LOCALIZE(@"NATIVE_MODES_FOOTER", @"Aura"), },
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"SHOW_ICON_INDICATORS", @"Aura"),
			@"key": @"showIndicatorOnIcon",
			@"default": @YES,
		},
		@{
			@"cell": @"PSSwitchCell",
			@"label": LOCALIZE(@"SHOW_STATUSBAR_ICONS", @"Aura"),
			@"key": @"showStatusBarIcon",
			@"default": @YES,
		},
	];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	//[super setPreferenceValue:value specifier:specifier];

	if ([[specifier propertyForKey:@"key"] isEqualToString:@"UIApplicationExitsOnSuspend"]) {
		LSApplicationProxy *appInfo = [%c(LSApplicationProxy) applicationProxyForIdentifier:self.identifier];
		NSString *path = [NSString stringWithFormat:@"%@/Info.plist",appInfo.bundleURL.absoluteString];
		NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:path]];
		infoPlist[@"UIApplicationExitsOnSuspend"] = value;
		BOOL success = [infoPlist writeToURL:[NSURL URLWithString:path] atomically:YES];

		if (!success) {
			NSMutableDictionary *daemonDict = [NSMutableDictionary dictionary];
			daemonDict[@"bundleIdentifier"] = self.identifier;
			daemonDict[@"UIApplicationExitsOnSuspend"] = value;
			[daemonDict writeToFile:@"/var/mobile/Library/.reachapp.uiappexitsonsuspend.wantstochangerootapp" atomically:YES];
		}

		if ([[specifier propertyForKey:@"reloadSpecifiers"] boolValue]) {
			[self reloadSpecifiers];
		}

		return;
	}

	CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");

	NSString *key = [NSString stringWithFormat:@"backgrounder-%@-%@",self.identifier,[specifier propertyForKey:@"key"]];
	if ([specifier propertyForKey:@"prefix"]) {
		key = [NSString stringWithFormat:@"backgrounder-%@-%@-%@",self.identifier,[specifier propertyForKey:@"prefix"],[specifier propertyForKey:@"key"]];
	}
	CFPreferencesSetAppValue((__bridge CFStringRef)key, (const void*)value, appID);

	CFPreferencesAppSynchronize(appID);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), nil, nil, YES);
	RA_BGAppsControllerNeedsToReload();

	if ([[specifier propertyForKey:@"reloadSpecifiers"] boolValue]) {
		[self reloadSpecifiers];
	}
}

- (id)getActualPrefValue:(NSString *)basename {
	CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
	NSString *key = [NSString stringWithFormat:@"backgrounder-%@-%@",self.identifier,basename];

	CFPropertyListRef value = CFPreferencesCopyValue((__bridge CFStringRef)key, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

	return (__bridge id)value;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
	CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!keyList) {
		return [specifier propertyForKey:@"default"];
	}
	NSDictionary *_settings = (__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFRelease(keyList);
	if (!_settings) {
		return [specifier propertyForKey:@"default"];
	}

	NSString *key = [specifier propertyForKey:@"prefix"] ?[NSString stringWithFormat:@"backgrounder-%@-%@-%@",self.identifier,[specifier propertyForKey:@"prefix"],[specifier propertyForKey:@"key"]] :[NSString stringWithFormat:@"backgrounder-%@-%@",self.identifier,[specifier propertyForKey:@"key"]];
	return ![_settings objectForKey:key] ?[specifier propertyForKey:@"default"] : _settings[key];
}
@end
