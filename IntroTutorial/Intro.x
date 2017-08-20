#import "headers.h"
#import "RASettings.h"

%hook SBLockScreenViewController
- (void)finishUIUnlockFromSource:(NSInteger)source {
	%orig;
	if (![[RASettings sharedInstance] isFirstRun]) {
		return;
	}

	BBBulletinRequest *request = [[%c(BBBulletinRequest) alloc] init];
	request.title = LOCALIZE(@"MULTIPLEXER", @"Localizable");
	request.message = LOCALIZE(@"THANK_YOU_TEXT", @"Localizable");
	request.sectionID = @"com.andrewabosh.Multiplexer";
	request.date = [NSDate date];
	request.defaultAction = [%c(BBAction) actionWithLaunchBundleID:@"com.andrewabosh.Multiplexer" callblock:nil];
	request.expirationDate = [[NSDate date] dateByAddingTimeInterval:10];
	SBBulletinBannerController *bannerController = [%c(SBBulletinBannerController) sharedInstance];
	if ([bannerController respondsToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]) {
		[bannerController observer:nil addBulletin:request forFeed:2 playLightsAndSirens:YES withReply:nil];
	} else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		[bannerController observer:nil addBulletin:request forFeed:2];
#pragma GCC diagnostic pop
	}

	[[RASettings sharedInstance] setFirstRun:NO];
}
%end
