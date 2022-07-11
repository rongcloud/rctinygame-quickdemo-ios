
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RWTableViewDidSelectRowAtIndexPathBlock)(UITableView *tableView, NSIndexPath *indexPath);
typedef CGFloat (^RWTableViewHeightForRowAtIndexPathBlock)(UITableView *tableView, NSIndexPath *indexPath);
typedef NSInteger (^RWTableViewNumberOfSectionsInTableViewBlock)(UITableView *tableView);
typedef NSInteger (^RWTableViewNumberOfRowsInSectionBlock)(UITableView *tableView, NSInteger section);
typedef __kindof UITableViewCell * (^RWTableViewCellForRowAtIndexPathBlock)(UITableView *tableView, NSIndexPath *indexPath);
typedef CGFloat (^RWTableViewHeightForHeaderInSection)(UITableView *tableView, NSInteger section);
typedef UIView * (^RWTableViewViewForHeaderInSection)(UITableView *tableView, NSInteger section);

@interface RWTableView : UITableView
- (void)setNumberOfSectionsInTableViewCb:(RWTableViewNumberOfSectionsInTableViewBlock)numberOfSectionsInTableViewCb
                 numberOfRowsInSectionCb:(RWTableViewNumberOfRowsInSectionBlock)numberOfRowsInSectionCb
               heightForRowAtIndexPathCb:(RWTableViewHeightForRowAtIndexPathBlock)heightForRowAtIndexPathCb
                 cellForRowAtIndexPathCb:(RWTableViewCellForRowAtIndexPathBlock)cellForRowAtIndexPathCb
               didSelectRowAtIndexPathCb:(RWTableViewDidSelectRowAtIndexPathBlock)didSelectRowAtIndexPathCb
              heightForHeaderInSectionCb:(RWTableViewHeightForHeaderInSection)heightForHeaderInSectionCb
                viewForHeaderInSectionCb:(RWTableViewViewForHeaderInSection)viewForHeaderInSectionCb;
@end

NS_ASSUME_NONNULL_END
