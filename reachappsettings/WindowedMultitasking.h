#import "Main.h"
#import "RAHeaderView.h"
#import "PDFImage.h"
#import "RASettings.h"

@interface ReachAppWindowSettingsListController : SKTintedListController <SKListControllerProtocol>

@end

@interface RADisabledAppsSelectorView : PSViewController <UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) ALApplicationTableDataSource *dataSource;
@end

@interface RAAlwaysWindowedAppsSelectorView : PSViewController <UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) ALApplicationTableDataSource *dataSource;
@end

@interface RAAlwaysLockedAppsSelectorView : PSViewController <UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) ALApplicationTableDataSource *dataSource;
@end

@interface RAApplicationTableDataSource : ALApplicationTableDataSource

@end

@interface RAWindowedApplicationTableDataSource : ALApplicationTableDataSource

@end

@interface RALockedApplicationTableDataSource : ALApplicationTableDataSource

@end
