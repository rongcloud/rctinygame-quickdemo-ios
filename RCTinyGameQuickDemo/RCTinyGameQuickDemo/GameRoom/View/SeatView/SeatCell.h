
#import <UIKit/UIKit.h>
#import "SeatDefine.h"


///  用来记录状态
@interface SeatModel : NSObject
@property (nonatomic, strong) RCVoiceSeatInfo *seatInfo;
@property (nonatomic, assign) BOOL       isCaptain;
@property (nonatomic, assign) GameState  gameState;

@end


@interface SeatCell : UICollectionViewCell
@property (nonatomic, strong) SeatModel   * seatModel;
/// 重置
- (void)reload;

@end
