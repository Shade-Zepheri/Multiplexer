#import "headers.h"
#import "RASettings.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"

extern BOOL launchNextOpenIntoWindow;
BOOL override = NO;
BOOL allowOpenApp = NO;

%hook SBIconController
- (void)iconWasTapped:(__unsafe_unretained SBApplicationIcon*)icon {
	if ([[RASettings sharedInstance] windowedMultitaskingEnabled] && [[RASettings sharedInstance] launchIntoWindows] && icon.application) {
		[[RADesktopManager sharedInstance].currentDesktop createAppWindowForSBApplication:icon.application animated:YES];
		override = YES;
	}
	%orig;
}

- (void)_launchIcon:(unsafe_id)icon {
	if (!override) {
		%orig;
	} else {
		override = NO;
	}
}
%end

%hook SBUIController
- (void)activateApplicationAnimated:(__unsafe_unretained SBApplication*)application {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([[RASettings sharedInstance] windowedMultitaskingEnabled] && [[RASettings sharedInstance] launchIntoWindows] && !allowOpenApp) {
		[[RADesktopManager sharedInstance].currentDesktop createAppWindowForSBApplication:application animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[[RADesktopManager sharedInstance] removeAppWithIdentifier:application.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}

- (void)activateApplication:(__unsafe_unretained SBApplication*)application {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([[RASettings sharedInstance] windowedMultitaskingEnabled] && [[RASettings sharedInstance] launchIntoWindows] && !allowOpenApp) {
		[[RADesktopManager sharedInstance].currentDesktop createAppWindowForSBApplication:application animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[[RADesktopManager sharedInstance] removeAppWithIdentifier:application.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}
%end

%group iOS9
%hook SBApplication
- (NSArray *)staticShortcutItems {
	NSMutableArray *mutableItems = [%orig mutableCopy];

	NSString *title = LOCALIZE(@"CREATE_WINDOW_TITLE");
	NSString *subtitle = LOCALIZE(@"CREATE_WINDOW_SUBTITLE");
	NSDictionary *info = @{@"UIApplicationShortcutItemTitle": title, @"UIApplicationShortcutItemSubtitle": subtitle, @"UIApplicationShortcutItemType": @"com.efrederickson.reachapp.windowedmultitasking.3dtouchgesture"};

	SBSApplicationShortcutItem *windowItem = [%c(SBSApplicationShortcutItem) staticShortcutItemWithDictionary:info localizationHandler:nil];
	windowItem.icon = [(SBSApplicationShortcutSystemIcon *)[%c(SBSApplicationShortcutSystemIcon) alloc] initWithType:UIApplicationShortcutIconTypeAdd];
	windowItem.bundleIdentifierToLaunch = self.bundleIdentifier;

	[mutableItems addObject:windowItem];

	return mutableItems;
}
%end

%hook SBApplicationShortcutMenu
- (void)menuContentView:(SBApplicationShortcutMenuContentView *)view activateShortcutItem:(SBSApplicationShortcutItem *)item index:(NSUInteger)index {
	if (![item.type isEqualToString:@"com.efrederickson.reachapp.windowedmultitasking.3dtouchgesture"] || ![[RASettings sharedInstance] windowedMultitaskingEnabled]) {
		%orig;
		return;
	}

	[[RADesktopManager sharedInstance].currentDesktop createAppWindowWithIdentifier:item.bundleIdentifierToLaunch animated:YES];
}
%end
%end

%group iOS10
%hook SBApplication
- (NSArray *)staticApplicationShortcutItems {
	NSMutableArray *mutableItems = [%orig mutableCopy];

	NSString *title = LOCALIZE(@"CREATE_WINDOW_TITLE");
	NSString *subtitle = LOCALIZE(@"CREATE_WINDOW_SUBTITLE");
	NSDictionary *info = @{@"UIApplicationShortcutItemTitle": title, @"UIApplicationShortcutItemSubtitle": subtitle, @"UIApplicationShortcutItemType": @"com.efrederickson.reachapp.windowedmultitasking.3dtouchgesture"};

	SBSApplicationShortcutItem *windowItem = [%c(SBSApplicationShortcutItem) staticShortcutItemWithDictionary:info localizationHandler:nil];
	windowItem.icon = [(SBSApplicationShortcutSystemIcon *)[%c(SBSApplicationShortcutSystemIcon) alloc] initWithType:UIApplicationShortcutIconTypeAdd];
	windowItem.bundleIdentifierToLaunch = self.bundleIdentifier;

	[mutableItems addObject:windowItem];

	return mutableItems;
}
%end

%hook SBIconController
- (BOOL)appIconForceTouchController:(SBUIAppIconForceTouchController *)controller shouldActivateApplicationShortcutItem:(SBSApplicationShortcutItem *)item atIndex:(NSUInteger)index forGestureRecognizer:(id)recognizer {
	if (![item.type isEqualToString:@"com.efrederickson.reachapp.windowedmultitasking.3dtouchgesture"] || ![[RASettings sharedInstance] windowedMultitaskingEnabled]) {
		return %orig;
	} else {
		[[RADesktopManager sharedInstance].currentDesktop createAppWindowWithIdentifier:item.bundleIdentifierToLaunch animated:YES];

		return NO;
	}
}
%end
%end

%ctor {
	if (IS_IOS_OR_NEWER(iOS_10_0)) {
		%init(iOS10);
	} else if (IS_IOS_BETWEEN(iOS_9_0, iOS_9_3)) {
		%init(iOS9);
	}

	%init;
}
