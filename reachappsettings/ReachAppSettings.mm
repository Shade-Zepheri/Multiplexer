#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSSpecifier.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <SettingsKit/SKStandardController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "RAHeaderView.h"
#import "PDFImage.h"
#import "headers.h"
#import "RAThemeManager.h"
#import "RASettings.h"

@interface PSViewController (Protean)
- (void)viewDidLoad;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
@end

@interface PSViewController (SettingsKit2)
- (UINavigationController *)navigationController;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
@end

@interface ALApplicationTableDataSource (Private)
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
@end

@interface ReachAppSettingsListController: SKTintedListController <SKListControllerProtocol, MFMailComposeViewControllerDelegate>
@end

@implementation ReachAppSettingsListController
- (UIView *)headerView {
  RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 95)];
  header.colors = @[
    (id) [UIColor colorWithRed:234/255.0f green:152/255.0f blue:115/255.0f alpha:1.0f].CGColor,
    (id) [UIColor colorWithRed:190/255.0f green:83/255.0f blue:184/255.0f alpha:1.0f].CGColor
  ];
#if DEBUG
  if (arc4random_uniform(1000000) == 11) {
    header.title = @"卐卐 TWEAK SUPREMACY 卍卍";
  } else if (arc4random_uniform(1000000) >= 300000) {
    header.title = @"dank memes";
  }
#endif
  header.blendMode = kCGBlendModeSoftLight;
  header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/MainHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(109.33, 41)]];

  UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 115)];
  [notHeader addSubview:header];

  return notHeader;
}

- (UIColor *)navigationTintColor {
  return [UIColor colorWithRed:190/255.0f green:83/255.0f blue:184/255.0f alpha:1.0f];
}

- (NSString *)customTitle {
  return LOCALIZE(@"Multiplexer", @"Localizable");
}

- (BOOL)showHeartImage {
  return YES;
}

- (NSString *)shareMessage {
  return @"I'm multitasking with Multiplexer, by @daementor and @drewplex";
}

- (NSArray *)customSpecifiers {
  return @[
           @{ @"footerText": LOCALIZE(@"ENABLED_FOOTER", @"Root") },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @YES,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"enabled",
               @"label": LOCALIZE(@"ENABLED", @"Root"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               @"icon": @"ra_enabled.png",
               },
#if DEBUG
           @{
               @"cell": @"PSSwitchCell",
               @"default": @YES,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"debug_showIPCMessages",
               @"label": LOCALIZE(@"SHOW_IPC", @"Root"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               @"icon": @"ra_enabled.png",
               },
#endif
           @{ @"footerText": LOCALIZE(@"THEME_FOOTER", @"Root") },

           @{
              @"cell": @"PSLinkListCell",
              @"default": [[RASettings sharedInstance] currentThemeIdentifier],
              @"defaults": @"com.efrederickson.reachapp.settings",
              @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
              @"label": LOCALIZE(@"THEME", @"Root"),
              @"icon": @"theme.png",
              @"key": @"currentThemeIdentifier",
              @"detail": @"RAListItemsController",
              @"valuesDataSource": @"getThemeValues:",
              @"titlesDataSource": @"getThemeTitles:",
              @"enabled": @([self getEnabledForPane:0])
           },

           @{ @"footerText": LOCALIZE(@"AURA_FOOTER", @"Root") },
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"AURA", @"Root"),
               @"detail": @"ReachAppBackgrounderSettingsListController",
               @"icon": @"aura.png",
               @"enabled": @([self getEnabledForPane:1])
               },
           @{ @"footerText": LOCALIZE(@"EMPOLEON_FOOTER", @"Root") },
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"EMPOLEON", @"Root"),
               @"detail": @"ReachAppWindowSettingsListController",
               @"icon": @"empoleon.png",
               @"enabled": @([self getEnabledForPane:2])
               },
           @{ @"footerText": LOCALIZE(@"MISSION_CONTROL_FOOTER", @"Root") },
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"MISSION_CONTROL", @"Root"),
               @"detail": @"ReachAppMCSettingsListController",
               @"icon": @"missioncontrol.png",
               @"enabled": @([self getEnabledForPane:3])
               },
           @{ @"footerText": LOCALIZE(@"QUICK_ACCESS_FOOTER", @"Root") },
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"QUICK_ACCESS", @"Root"),
               @"detail": @"ReachAppNCAppSettingsListController",
               @"icon": @"quickaccess.png",
               @"enabled": @([self getEnabledForPane:4])
               },
          @{ @"footerText": LOCALIZE(@"REACHAPP_FOOTER", @"Root") },
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"REACHAPP", @"Root"),
               @"detail": @"ReachAppReachabilitySettingsListController",
               @"icon": @"reachapp.png",
               @"enabled": @([self getEnabledForPane:5])
               },
           @{ @"footerText": LOCALIZE(@"SWIPE_OVER_FOOTER", @"Root") },
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"SWIPE_OVER", @"Root"),
               @"detail": @"ReachAppSwipeOverSettingsListController",
               @"icon": @"swipeover.png",
               @"enabled": @([self getEnabledForPane:6])
               },
           @{ @"footerText": [NSString stringWithFormat:@"%@%@",
#if DEBUG
                  arc4random_uniform(10000) == 9901 ? @"2fast5me" :
#endif
                  @"© 2015 Elijah Frederickson & Andrew Abosh.",
#if DEBUG
                  @"\n**DEBUG** "
#else
                  @""
#endif
                   ]},
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"CREATORS", @"Root"),
               @"detail": @"RAMakersController",
               @"icon": @"ra_makers.png"
               },
           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"SUPPORT", @"Root"),
               @"action": @"showSupportDialog",
               @"icon": @"ra_support.png"
               },

           @{
               @"cell": @"PSLinkCell",
               @"label": LOCALIZE(@"TUTORIAL", @"Root"),
               @"action": @"showTutorial",
               @"icon": @"tutorial.png",
               //@"enabled": @NO,
               },/*
           @{
               @"cell": @"PSLinkCell",
               @"label": @"Theming Documentation",
               @"action": @"openThemingDocumentation",
               @"icon": @"tutorial.png",
               },*/
           @{
               @"cell": @"PSButtonCell",
               @"action": @"resetData",
               @"label": LOCALIZE(@"RESET_ALL", @"Root"),
               @"icon": @"Reset.png"
               }
           ];
}

- (void)resetData {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"Multiplexer", @"Localizable") message:LOCALIZE(@"RESET_WARNING", @"Root") preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *resetAction = [UIAlertAction actionWithTitle:LOCALIZE(@"YES", @"Root") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.resetSettings"), nil, nil, YES);
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LOCALIZE(@"CANCEL", @"Localizable") style:UIAlertActionStyleCancel handler:nil];

  [alert addAction:resetAction];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)openThemingDocumentation {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://elijahandandrew.com/multiplexer/ThemingDocumentation.html"]];
}

- (NSArray *)getThemeTitles:(id)target {
  NSArray *themes = [[RAThemeManager sharedInstance] allThemes];
  NSMutableArray *ret = [NSMutableArray array];
  for (RATheme *theme in themes) {
    [ret addObject:theme.themeName];
  }
  return ret;
}

- (NSArray *)getThemeValues:(id)target {
  NSArray *themes = [[RAThemeManager sharedInstance] allThemes];
  NSMutableArray *ret = [NSMutableArray array];
  for (RATheme *theme in themes) {
    [ret addObject:theme.themeIdentifier];
  }
  return ret;
}

- (void)showSupportDialog {
  MFMailComposeViewController *mailViewController;
  if ([MFMailComposeViewController canSendMail]) {
    mailViewController = [[MFMailComposeViewController alloc] init];
    mailViewController.mailComposeDelegate = self;
    [mailViewController setSubject:@"Multiplexer"];

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *sysInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    NSString *msg = [NSString stringWithFormat:@"\n\n%@ %@\nModel: %@\n", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion, sysInfo];
    [mailViewController setMessageBody:msg isHTML:NO];
    [mailViewController setToRecipients:@[@"ziroalpha@gmail.com"]];

    [self.rootController presentViewController:mailViewController animated:YES completion:nil];
  }
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
  [super setPreferenceValue:value specifier:specifier];
  [self reloadSpecifiers];
}

- (BOOL)getEnabledForPane:(NSInteger)pane {
  CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
  CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (!keyList) {
    return YES;
  }
  NSDictionary *_settings = (__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  CFRelease(keyList);
  if (!_settings) {
    return YES;
  }

  BOOL enabled = ![_settings objectForKey:@"enabled"] ? YES : [_settings[@"enabled"] boolValue];

  if (pane != 0) {
    switch (pane) {
      case 1:
        return enabled && [RASettings isAuraInstalled];
      case 2:
        return enabled && [RASettings isEmpoleonInstalled];
      case 3:
        return enabled && [RASettings isMissionControlInstalled];
      case 4:
        return enabled && [RASettings isQuickAccessInstalled];
      case 5:
        return enabled && [RASettings isReachAppInstalled];
      case 6:
        return enabled && [RASettings isSwipeOverInstalled];
    }
  }

  return enabled;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)showTutorial {
  [[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.andrewabosh.Multiplexer" suspended:NO];
}
@end
