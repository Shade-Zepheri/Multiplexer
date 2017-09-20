#import "Main.h"
#import "RAHeaderView.h"
#import "PDFImage.h"

@interface ReachAppNCAppSettingsListController : SKTintedListController <SKListControllerProtocol>

@end


@interface RANCAppSelectorView : PSViewController <UITableViewDelegate> {
  UITableView *_tableView;
  ALApplicationTableDataSource *_dataSource;
}
@end

@interface RANCApplicationTableDataSource : ALApplicationTableDataSource

@end
