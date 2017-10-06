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
#import <libactivator/libactivator.h>
#import <UIKit/UISearchBar.h>

@interface PSViewController (SettingsKit2)
- (UINavigationController *)navigationController;
@end

@interface ALApplicationTableDataSource (Private_ReachApp)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface PSListItemsController (tableView)
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)listItemSelected:(id)arg1;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end
