#import "Main.h"
#import "RAHeaderView.h"
#import "PDFImage.h"

@interface ReachAppReachabilitySettingsListController : SKTintedListController <SKListControllerProtocol>

@end

@interface RAAppChooserOptionsListController : SKTintedListController <SKListControllerProtocol>

@end

@interface RASwitchCell : PSSwitchTableCell //our class

@end

@interface RAFavoritesAppSelectorView : PSViewController <UITableViewDelegate> {
  UITableView *_tableView;
  ALApplicationTableDataSource *_dataSource;
}
@end

@interface RAFavoriteApplicationTableDataSource : ALApplicationTableDataSource

@end
