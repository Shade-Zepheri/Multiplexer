#import "Main.h"
#import "RAHeaderView.h"
#import "PDFImage.h"
#import "RASettings.h"

@interface ReachAppWindowSettingsListController : SKTintedListController <SKListControllerProtocol>

@end

@interface RADisabledAppsSelectorView : PSViewController <UITableViewDelegate> {
  UITableView *_tableView;
  ALApplicationTableDataSource *_dataSource;
}
@end

@interface RAApplicationTableDataSource : ALApplicationTableDataSource

@end
