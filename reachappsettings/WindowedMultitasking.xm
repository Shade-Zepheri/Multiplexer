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
#import "RASettings.h"
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

@interface ReachAppWindowSettingsListController: SKTintedListController <SKListControllerProtocol>
@end

@implementation ReachAppWindowSettingsListController
- (UIView *)headerView {
  RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
  header.colors = @[
    (id) [UIColor colorWithRed:255/255.0f green:94/255.0f blue:58/255.0f alpha:1.0f].CGColor,
    (id) [UIColor colorWithRed:255/255.0f green:149/255.0f blue:0/255.0f alpha:1.0f].CGColor,
  ];
  header.shouldBlend = NO;
  header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/EmpoleonHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(32, 32)]];

  UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
  [notHeader addSubview:header];

  return notHeader;
}

- (UIColor *)tintColor {
  return [UIColor colorWithRed:255/255.0f green:94/255.0f blue:58/255.0f alpha:1.0f];
}

- (UIColor *)switchTintColor {
  return [[UISwitch alloc] init].tintColor;
}

- (NSString *)customTitle {
  return LOCALIZE(@"EMPOLEON", @"Root");
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
               @{ @"footerText": LOCALIZE(@"ENABLED_FOOTER", @"Empoleon") },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @YES,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"windowedMultitaskingEnabled",
               @"label": LOCALIZE(@"ENABLED", @"Root"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },

           @{ @"label": LOCALIZE(@"SWIPE_UP_FROM", @"Empoleon"), @"footerText": LOCALIZE(@"SWIPE_UP_FROM_FOOTER", @"Empoleon") },
           @{
               @"cell": @"PSSegmentCell",
               @"validTitles": @[LOCALIZE(@"LEFT", @"Empoleon"), LOCALIZE(@"MIDDLE", @"Empoleon"), LOCALIZE(@"RIGHT", @"Empoleon")],
               @"validValues": @[@(RAGrabAreaBottomLeftThird), @(RAGrabAreaBottomMiddleThird), @(RAGrabAreaBottomRightThird),],
               @"default": @(RAGrabAreaBottomLeftThird),
               @"key": @"windowedMultitaskingGrabArea",
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },
           @{
               @"cell": @"PSLinkListCell",
               @"detail": @"RADisabledAppsSelectorView",
               @"label": LOCALIZE(@"DISABLED_APPS", @"Empoleon"),
               },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @NO,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"launchIntoWindows",
               @"label": LOCALIZE(@"LAUNCH_INTO_WINDOW", @"Empoleon"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },

           @{ @"footerText": LOCALIZE(@"ALWAYS_EASY_TAP_FOOTER", @"Empoleon") },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @YES,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"alwaysEnableGestures",
               @"label": LOCALIZE(@"ALWAYS_ENABLE_GESTURES", @"Empoleon"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @NO,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"onlyShowWindowBarIconsOnOverlay",
               @"label": LOCALIZE(@"ALWAYS_EASY_TAP", @"Empoleon"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },

           @{ @"footerText": LOCALIZE(@"COMPLETE_ANIMATIONS_FOOTER", @"Empoleon") },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @NO,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"windowedMultitaskingCompleteAnimations",
               @"label": LOCALIZE(@"COMPLETE_ANIMATIONS", @"Empoleon"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },

           @{ @"label": LOCALIZE(@"SNAPPING", @"Empoleon") },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @YES,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"snapWindows",
               @"label": LOCALIZE(@"SNAP_WINDOWS", @"Empoleon"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @YES,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"snapRotation",
               @"label": LOCALIZE(@"ROTATION_SNAPPING", @"Empoleon"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },
           @{
               @"cell": @"PSSwitchCell",
               @"default": @NO,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"showSnapHelper",
               @"label": LOCALIZE(@"SHOW_SNAP_HELPER", @"Empoleon"),
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },

           @{ @"label": LOCALIZE(@"LOCK_BUTTON_ACTION", @"Empoleon") },
           @{
               @"cell": @"PSSegmentCell",
               @"validTitles": @[ LOCALIZE(@"LOCK_ALL_ROTATION", @"Empoleon"), LOCALIZE(@"LOCK_APP_ROTATION", @"Empoleon") ],
               @"validValues": @[ @0, @1 ],
               @"default": @0,
               @"key": @"windowRotationLockMode",
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },

           @{ @"label": LOCALIZE(@"ACTIVATOR", @"Root") },
           @{
              @"cell": @"PSLinkCell",
              @"action": @"showActivatorAction",
              @"label": LOCALIZE(@"SORT_WINDOWS_ACTIVATION", @"Empoleon"),
              //@"enabled": objc_getClass("LAEventSettingsController") != nil,
           },
           @{
              @"cell": @"PSLinkCell",
              @"action": @"showActivatorAction2",
              @"label": LOCALIZE(@"EASY_TAP_ACTIVATION", @"Empoleon"),
              //@"enabled": objc_getClass("LAEventSettingsController") != nil,
           },
           @{
              @"cell": @"PSLinkCell",
              @"action": @"showActivatorAction3",
              @"label": LOCALIZE(@"CREATE_WINDOW_ACTIVATION", @"Empoleon"),
              //@"enabled": objc_getClass("LAEventSettingsController") != nil,
           },

               /*
           @{
               @"cell": @"PSSwitchCell",
               @"default": @NO,
               @"defaults": @"com.efrederickson.reachapp.settings",
               @"key": @"openLinksInWindows",
               @"label": @"Open links in windows",
               @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
               },
               */
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
    vc.listenerName = @"com.efrederickson.reachapp.windowedmultitasking.sortWindows";
    [self.rootController pushController:vc animate:YES];
  }
}

- (void)showActivatorAction2 {
  id activator = %c(LAListenerSettingsViewController);
  if (!activator) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"Multiplexer", @"Localizable") message:LOCALIZE(@"ACTIVATOR_WARNING", @"Root") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    LAListenerSettingsViewController *vc = [[%c(LAListenerSettingsViewController) alloc] init];
    vc.listenerName = @"com.efrederickson.reachapp.windowedmultitasking.toggleEditMode";
    [self.rootController pushController:vc animate:YES];
  }
}

- (void)showActivatorAction3 {
  id activator = %c(LAListenerSettingsViewController);
  if (!activator) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"Multiplexer", @"Localizable") message:LOCALIZE(@"ACTIVATOR_WARNING", @"Root") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    LAListenerSettingsViewController *vc = [[%c(LAListenerSettingsViewController) alloc] init];
    vc.listenerName = @"com.efrederickson.reachapp.windowedmultitasking.createWindow";
    [self.rootController pushController:vc animate:YES];
  }
}
@end

@interface RADisabledAppsSelectorView : PSViewController <UITableViewDelegate> {
  UITableView *_tableView;
  ALApplicationTableDataSource *_dataSource;
}
@end

@interface RAApplicationTableDataSource : ALApplicationTableDataSource
@end

@interface ALApplicationTableDataSource (Private_ReachApp)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation RAApplicationTableDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSInteger row = indexPath.row;
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

  NSDictionary *prefs = nil;

  CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
  CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (!keyList) {
    return cell;
  }
  prefs = (__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (!prefs) {
    return cell;
  }
  CFRelease(keyList);

  if ([cell isKindOfClass:[ALCheckCell class]]) {
    NSString *dn = [self displayIdentifierForIndexPath:indexPath];
    NSString *key = [NSString stringWithFormat:@"Disabled-%@",dn];
    BOOL value = [prefs[key] boolValue];
    [(ALCheckCell *)cell loadValue:@(value)];
  }
  return cell;
}
@end

@implementation RADisabledAppsSelectorView

-(void)updateDataSource:(NSString *)searchText {
  _dataSource.sectionDescriptors = @[@{ALSectionDescriptorTitleKey: @"", ALSectionDescriptorCellClassNameKey: @"ALCheckCell", ALSectionDescriptorIconSizeKey: @29, ALSectionDescriptorSuppressHiddenAppsKey: @YES, ALSectionDescriptorPredicateKey: @"not bundleIdentifier in { }"}];
  [_tableView reloadData];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    CGRect bounds = [UIScreen mainScreen].bounds;

    _dataSource = [[RAApplicationTableDataSource alloc] init];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height) style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = _dataSource;
    _dataSource.tableView = _tableView;
    [self updateDataSource:nil];
  }

  return self;
}

- (void)viewDidLoad {
  ((UIViewController *)self).title = LOCALIZE(@"APPLICATIONS", @"Root");
  [self.view addSubview:_tableView];
  [super viewDidLoad];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:true];
  ALCheckCell *cell = (ALCheckCell *)[tableView cellForRowAtIndexPath:indexPath];
  [cell didSelect];

  UITableViewCellAccessoryType type = [cell accessoryType];
  BOOL selected = type == UITableViewCellAccessoryCheckmark;

  NSString *identifier = [_dataSource displayIdentifierForIndexPath:indexPath];
  CFPreferencesSetAppValue((__bridge CFStringRef)[NSString stringWithFormat:@"Disabled-%@", identifier], (CFPropertyListRef)(@(selected)), CFSTR("com.efrederickson.reachapp.settings"));

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), nil, nil, YES);
  });
}
@end
