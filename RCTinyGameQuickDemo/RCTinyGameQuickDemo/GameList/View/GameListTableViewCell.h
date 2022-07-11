
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^createBlock)(UITableViewCell *);
typedef void (^joinBlock)(UITableViewCell *);


@interface GameListTableViewCell : UITableViewCell

- (void)updateCellWithName:(NSString *)gameName gameDesc:(NSString *)gameDesc gameImg:(NSString *)imgUrl;

@property (nonatomic, copy) createBlock createRoomAction;
@property (nonatomic, copy) joinBlock joinRoomAction;

@end

NS_ASSUME_NONNULL_END
