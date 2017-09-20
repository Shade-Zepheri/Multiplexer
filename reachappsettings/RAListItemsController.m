#import "RAListItemsController.h"

@implementation RAListItemsController
- (UIColor *)navigationTintColor {
  return [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self.navigationController.navigationBar.tintColor = self.navigationTintColor;
  [UIWindow keyWindow].tintColor = self.navigationTintColor;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [UIWindow keyWindow].tintColor = nil;
  self.navigationController.navigationBar.tintColor = nil;
}

- (NSArray *)specifiers {
  if (!_specifiers) {
    PSSpecifier *themeSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Documentation" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
    [themeSpecifier setProperty:SK_RSIMG(@"tutorial.png") forKey:@"iconImage"];
    [themeSpecifier setProperty:@"poop" forKey:@"isTheming"];
    _specifiers = [super specifiers];
    [(NSMutableArray *)_specifiers addObject:[PSSpecifier emptyGroupSpecifier]];
    [(NSMutableArray *)_specifiers addObject:themeSpecifier];
  }

  return _specifiers;
}

- (void)openThemingDocumentation {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://elijahandandrew.com/multiplexer/ThemingDocumentation.html"]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];

  PSTableCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
  if ([cell.specifier propertyForKey:@"isTheming"]) {
    [self openThemingDocumentation];
  }
}
@end

@implementation RABackgroundingListItemsController
- (UIColor *)navigationTintColor {
  return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self.navigationController.navigationBar.tintColor = self.navigationTintColor;
  [UIWindow keyWindow].tintColor = self.navigationTintColor;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [UIWindow keyWindow].tintColor = nil;
  self.navigationController.navigationBar.tintColor = nil;
}
@end
