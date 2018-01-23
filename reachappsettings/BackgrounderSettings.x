#import "BackgrounderSettings.h"

@implementation ReachAppBackgrounderSettingsListController

- (UIView *)headerView {
  RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self table].bounds.size.width, 50)];
  header.colors = @[
    (id)[UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f].CGColor,
    (id)[UIColor colorWithRed:255/255.0f green:111/255.0f blue:124/255.0f alpha:1.0f].CGColor
  ];
  header.shouldBlend = NO;
  header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/BackgrounderHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(15, 33)]];

  UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [self table].bounds.size.width, 70)];
  [notHeader addSubview:header];

  return notHeader;
}

- (UIColor *)tintColor {
  return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f];
}

- (UIColor *)switchTintColor {
  return [[UISwitch alloc] init].tintColor;
}

- (NSString *)customTitle {
  return LOCALIZE(@"AURA", @"Root");
}

- (BOOL)showHeartImage {
  return NO;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [super setupHeader];
}

- (NSArray *)customSpecifiers {
  return @[
    @{ @"footerText": LOCALIZE(@"ENABLED_FOOTER", @"Aura") },
    @{
      @"cell": @"PSSwitchCell",
      @"default": @YES,
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"key": @"backgrounderEnabled",
      @"label": LOCALIZE(@"ENABLED", @"Root"),
    },

    @{ @"label": LOCALIZE(@"ACTIVATOR", @"Root"),
       @"footerText": LOCALIZE(@"ACTIVATOR_FOOTER", @"Aura"),},
    @{
      @"cell": @"PSLinkCell",
      @"action": @"showActivatorAction",
      @"label": LOCALIZE(@"ACTIVATION_METHOD", @"Aura"),
      //@"enabled": objc_getClass("LAEventSettingsController") != nil,
    },
    @{
      @"cell": @"PSSwitchCell",
      @"label": LOCALIZE(@"EXIT_AFTER_MENU", @"Aura"),
      @"default": @YES,
      @"key": @"exitAppAfterUsingActivatorAction",
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },

    @{ @"label": LOCALIZE(@"GLOBAL", @"Aura"), @"footerText": @"" },

    @{
      @"cell": @"PSLinkListCell",
      @"label": LOCALIZE(@"BACKGROUND_MODE", @"Aura"),
      @"key": @"globalBackgroundMode",
      @"validTitles": @[LOCALIZE(@"NATIVE", @"Aura"), LOCALIZE(@"UNLIMITED_BACKGROUND", @"Aura"), LOCALIZE(@"FORCE_FOREGROUND", @"Aura"), LOCALIZE(@"KILL_ON_EXIT", @"Aura"), LOCALIZE(@"SUSPEND_IMMEDIATELY", @"Aura")],
      @"validValues": @[@(RABackgroundModeNative), @(RABackgroundModeUnlimitedBackgroundingTime), @(RABackgroundModeForcedForeground), @(RABackgroundModeForceNone), @(RABackgroundModeSuspendImmediately)],
      @"shortTitles": @[@"Native", @"∞", @"Forced", @"Disabled", @"SmartClose" ],
      @"default": @(RABackgroundModeNative),
      @"detail": @"RABackgroundingListItemsController",
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
      @"staticTextMessage": LOCALIZE(@"BACKGROUND_MODE_FOOTER", @"Aura")
    },
    @{
      @"cell": @"PSLinkListCell",
      @"detail": @"RABackgrounderIconIndicatorOptionsListController",
      @"label": LOCALIZE(@"ICON_OPTIONS", @"Aura"),
    },
    @{
      @"cell": @"PSLinkListCell",
      @"detail": @"RABackgrounderStatusbarOptionsListController",
      @"label": LOCALIZE(@"STATUSBAR_OPTIONS", @"Aura"),
    },
    @{ @"label": LOCALIZE(@"SPECIFIC", @"Aura") },
    @{
      @"cell": @"PSLinkCell",
      @"label": LOCALIZE(@"PER_APP", @"Aura"),
      @"detail": @"RABGPerAppController",
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
    vc.listenerName = @"com.efrederickson.reachapp.backgrounder.togglemode";
    [self.rootController pushController:vc animate:YES];
  }
}

@end

@implementation RABackgrounderIconIndicatorOptionsListController

- (UIColor *)navigationTintColor {
  return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f];
}

- (BOOL)showHeartImage {
  return NO;
}

- (NSArray *)customSpecifiers {
  return @[
    @{
      @"cell": @"PSSwitchCell",
      @"label": LOCALIZE(@"SHOW_ICON_INDICATORS", @"Aura"),
      @"default": @YES,
      @"key": @"showIconIndicators",
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
    @{
      @"cell": @"PSSwitchCell",
      @"label": LOCALIZE(@"SHOW_NATIVE_INDICATORS", @"Aura"),
      @"default": @NO,
      @"key": @"showNativeStateIconIndicators",
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
  ];
}

@end

@implementation RABackgrounderStatusbarOptionsListController

- (UIColor *)navigationTintColor {
  return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f];
}

- (BOOL)showHeartImage {
  return NO;
}

- (NSArray *)customSpecifiers {
  return @[
    @{
      @"cell": @"PSSwitchCell",
      @"label": LOCALIZE(@"SHOW_STATUSBAR_ICONS", @"Aura"),
      @"default": @YES,
      @"key": @"shouldShowStatusBarIcons",
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
    @{
      @"cell": @"PSSwitchCell",
      @"label": LOCALIZE(@"SHOW_NATIVE_STATUSBAR", @"Aura"),
      @"default": @NO,
      @"key": @"shouldShowStatusBarNativeIcons",
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
  ];
}

@end
