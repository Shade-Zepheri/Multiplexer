#import "NCApp.h"

@implementation ReachAppNCAppSettingsListController
- (UIView *)headerView {
  RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
  header.colors = @[
    (id) [UIColor colorWithRed:90/255.0f green:212/255.0f blue:39/255.0f alpha:1.0f].CGColor,
    (id) [UIColor colorWithRed:164/255.0f green:231/255.0f blue:134/255.0f alpha:1.0f].CGColor,
  ];
  header.shouldBlend = NO;
  header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/NCAppHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(53, 32)]];

  UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 70)];
  [notHeader addSubview:header];

  return notHeader;
}

- (UIColor *)tintColor {
  return [UIColor colorWithRed:90/255.0f green:212/255.0f blue:39/255.0f alpha:1.0f];
}

- (UIColor *)switchTintColor {
  return [[UISwitch alloc] init].tintColor;
}

- (NSString *)customTitle {
  return LOCALIZE(@"QUICK_ACCESS", @"Root");
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
    @{ @"footerText": LOCALIZE(@"ENABLED_FOOTER", @"QuickAccess") },
    @{
      @"cell": @"PSSwitchCell",
      @"default": @YES,
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"key": @"ncAppEnabled",
      @"label": LOCALIZE(@"ENABLED", @"Root"),
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
    @{ @"footerText": LOCALIZE(@"USE_GENERIC_TAB_FOOTER", @"QuickAccess") },
    @{
      @"cell": @"PSSwitchCell",
      @"default": @NO,
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"key": @"quickAccessUseGenericTabLabel",
      @"label": LOCALIZE(@"USE_GENERIC_TAB", @"QuickAccess"),
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
    @{ @"footerText": LOCALIZE(@"HIDE_ON_LOCK_FOOTER", @"QuickAccess") },
    @{
      @"cell": @"PSSwitchCell",
      @"default": @NO,
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"key": @"ncAppHideOnLS",
      @"label": LOCALIZE(@"HIDE_ON_LOCK", @"QuickAccess"),
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
    @{ },
    @{
      @"cell": @"PSLinkListCell",
      @"detail": @"RANCAppSelectorView",
      @"label": LOCALIZE(@"SELECTED_APP", @"QuickAccess"),
    },
  ];
}
@end

@implementation RANCApplicationTableDataSource
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
    NSString *key = @"NCApp";// [NSString stringWithFormat:@"NCApp-%@",dn];
    //BOOL value = [prefs[key] boolValue];
    BOOL value = [dn isEqualToString:prefs[key] ? : @"com.apple.Preferences"];
    [(ALCheckCell *)cell loadValue:@(value)];
  }

  return cell;
}
@end

@implementation RANCAppSelectorView
- (void)updateDataSource:(NSString *)searchText {
  _dataSource.sectionDescriptors = @[@{ALSectionDescriptorTitleKey: @"", ALSectionDescriptorCellClassNameKey: @"ALCheckCell", ALSectionDescriptorIconSizeKey: @29, ALSectionDescriptorSuppressHiddenAppsKey: @YES, ALSectionDescriptorPredicateKey: @"not bundleIdentifier in { }", @"ALSingleEnabledMode": @YES}];
  [_tableView reloadData];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    CGRect bounds = [[UIScreen mainScreen] bounds];

    _dataSource = [[RANCApplicationTableDataSource alloc] init];

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
  ((UIViewController *)self).title = LOCALIZE(@"APPLICATION", @"Root");
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
  if (selected) {
    CFPreferencesSetAppValue((__bridge CFStringRef)@"NCApp", (CFPropertyListRef)(identifier), CFSTR("com.efrederickson.reachapp.settings"));
  }

  [self updateDataSource:nil];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.settings/reloadSettings"), nil, nil, YES);
  });

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOCALIZE(@"QUICK_ACCESS", @"Root") message:LOCALIZE(@"RESPRING_WARNING", @"QuickAccess") preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *respringAction = [UIAlertAction actionWithTitle:LOCALIZE(@"YES", @"Root") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.respring"), nil, nil, YES);
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LOCALIZE(@"NO", @"Root") style:UIAlertActionStyleCancel handler:nil];

  [alert addAction:respringAction];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
}
@end
