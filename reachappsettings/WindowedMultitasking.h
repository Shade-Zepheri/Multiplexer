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


@interface RAApplicationTableDataSource : ALApplicationTableDataSource

@end
