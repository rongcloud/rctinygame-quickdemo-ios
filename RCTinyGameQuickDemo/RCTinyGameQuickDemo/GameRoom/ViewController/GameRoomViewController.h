#import <UIKit/UIKit.h>


@interface GameRoomViewController : UIViewController

@property (nonatomic, strong) NSMutableArray<RCGameInfo *> *gameList;

- (instancetype)initWithRoomId:(NSString *)roomId
                      roomInfo:(RCVoiceRoomInfo *)roomInfo
                      gameInfo:(RCGameInfo *)gameInfo;

@property (nonatomic, assign) BOOL showForSwitchGame;

@end

