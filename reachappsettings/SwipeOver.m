#import "SwipeOver.h"

@implementation ReachAppSwipeOverSettingsListController
- (UIView *)headerView {
  RAHeaderView *header = [[RAHeaderView alloc] initWithFrame:CGRectMake(0, 0, [self table].bounds.size.width, 50)];
  header.colors = @[
    (id)[UIColor colorWithRed:88/255.0f green:86/255.0f blue:214/255.0f alpha:1.0f].CGColor,
    (id)[UIColor colorWithRed:198/255.0f green:68/255.0f blue:252/255.0f alpha:1.0f].CGColor,
  ];
  header.shouldBlend = NO;
  header.image = [[RAPDFImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ReachAppSettings.bundle/SwipeOverHeader.pdf"] imageWithOptions:[RAPDFImageOptions optionsWithSize:CGSizeMake(54, 32)]];

  UIView *notHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [self table].bounds.size.width, 70)];
  [notHeader addSubview:header];

  return notHeader;
}

- (NSString *)customTitle {
  return LOCALIZE(@"SWIPE_OVER", @"Root");
}

- (UIColor *)tintColor {
  return [UIColor colorWithRed:88/255.0f green:86/255.0f blue:214/255.0f alpha:1.0f];
}

- (UIColor *)switchTintColor {
  return [[UISwitch alloc] init].tintColor;
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
    @{ @"footerText": LOCALIZE(@"ENABLED_FOOTER", @"SwipeOver") },
    @{
      @"cell": @"PSSwitchCell",
      @"default": @YES,
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"key": @"swipeOverEnabled",
      @"label": LOCALIZE(@"ENABLED", @"Root"),
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },

    @{ @"label": LOCALIZE(@"SWIPE_IN_FROM", @"SwipeOver")},
    @{
      @"cell": @"PSSegmentCell",
      @"validTitles": @[LOCALIZE(@"ANYWHERE", @"SwipeOver"), LOCALIZE(@"TOP", @"SwipeOver"), LOCALIZE(@"MIDDLE", @"SwipeOver"), LOCALIZE(@"BOTTOM", @"SwipeOver")],
      @"validValues": @[@(RAGrabAreaSideAnywhere), @(RAGrabAreaSideTopThird), @(RAGrabAreaSideMiddleThird), @(RAGrabAreaSideBottomThird)],
      @"default": @(RAGrabAreaSideAnywhere),
      @"key": @"swipeOverGrabArea",
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },

    @{ @"footerText": LOCALIZE(@"ALWAYS_SHOW_GRABBER_FOOTER", @"SwipeOver") },
    @{
      @"cell": @"PSSwitchCell",
      @"default": @NO,
      @"defaults": @"com.efrederickson.reachapp.settings",
      @"key": @"alwaysShowSOGrabber",
      @"label": LOCALIZE(@"ALWAYS_SHOW_GRABBER", @"SwipeOver"),
      @"PostNotification": @"com.efrederickson.reachapp.settings/reloadSettings",
    },
  ];
}
@end
