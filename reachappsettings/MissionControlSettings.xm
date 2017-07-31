#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PSSpecifier.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "RAHeaderView.h"
#import "PDFImage.h"
#import <libactivator/libactivator.h>

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

@interface ReachAppMCSettingsListController: SKTintedListController <SKListControllerProtocol>
@end

@implementation ReachAppMCSettingsListController
- (UIView *)headerView {
  RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
  header.colors = @[
    (id) [UIColor colorWithRed:255/255.0f green:205/255.0f blue:2/255.0f alpha:1.0f].CGColor,
    (id) [UIColor colorWithRed:255/255.0f green:227/255.0f blue:113/255.0f alpha:1.0f].CGColor,
  ];
  header.shouldBlend = NO;
  header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/MissionControlHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(32, 32)]];

  UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
  [notHeader addSubview:header];

  return notHeader;
}

- (UIColor *)tintColor {
  return [UIColor colorWithRed:255/255.0f green:205/255.0f blue:2/255.0f alpha:1.0f];
}

- (UIColor *)switchTintColor {
  return [[UISwitch alloc] init].tintColor;
}

- (NSString *)customTitle {
  return LOCALIZE(@"MISSION_CONTROL", @"Root");
}

- (BOOL)showHeartImage {
  return NO;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [super performSelector:@selector(setupHeader)];
}

- (NSArray *)customSpecifiers {
    return @[
             @{ @"footerText": LOCALIZE(@"ENABLED_FOOTER", @"MissionControl") },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"missionControlEnabled",
                 @"label": LOCALIZE(@"ENABLED", @"Root"),
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

             @{ @"footerText": LOCALIZE(@"REPLACE_SWITCHER_FOOTER", @"MissionControl")},
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"replaceAppSwitcherWithMC",
                 @"label": LOCALIZE(@"REPLACE_SWITCHER", @"MissionControl"),
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

                 @{ @"label": LOCALIZE(@"CUSTOMIZATION", @"MissionControl"), @"footerText": LOCALIZE(@"CUSTOMIZATION_FOOTER", @"MissionControl") },
             @{
                 @"cell": @"PSSegmentCell",
                 @"validTitles": @[ LOCALIZE(@"DARKEN", @"MissionControl"), LOCALIZE(@"OUTLINE", @"MissionControl") ],
                 @"validValues": @[ @1, @0, ],
                 @"default": @1,
                 @"key": @"missionControlDesktopStyle",
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"missionControlPagingEnabled",
                 @"label": LOCALIZE(@"PAGED_SCROLLING", @"MissionControl"),
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },

                 @{ @"footerText": LOCALIZE(@"KILL_APP_FOOTER", @"MissionControl") },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.reachapp.settings",
                 @"key": @"mcKillApps",
                 @"label": LOCALIZE(@"KILL_APP", @"MissionControl"),
                 @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
                 },
                 @{ @"label": LOCALIZE(@"ACTIVATOR", @"Root") },
             @{
                    @"cell": @"PSLinkCell",
                    @"action": @"showActivatorAction",
                    @"label": LOCALIZE(@"SECONDARY_ACTIVATION", @"MissionControl"),
                    //@"enabled": objc_getClass("LAEventSettingsController") != nil,
                 },
             ];
}

- (void)showActivatorAction {
  id activator = %c(LAListenerSettingsViewController);
  if (!activator) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"Multiplexer", @"Localizable") message:LOCALIZE(@"ACTIVATOR_WARNING", @"Root") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    LAListenerSettingsViewController *vc = [[%c(LAListenerSettingsViewController) alloc] init];
    vc.listenerName = @"com.efrederickson.reachapp.missioncontrol.activatorlistener";
    [self.rootController pushController:vc animate:YES];
  }
}
@end
