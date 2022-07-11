
#import <UIKit/UIKit.h>
#import "SeatDefine.h"
#import "SeatCell.h"

NS_ASSUME_NONNULL_BEGIN

#define ITEM_SIZE               40.f
#define UISCREEN_WIDTH          [UIScreen mainScreen].bounds.size.width
#define UISCREEN_HEIGHT         [UIScreen mainScreen].bounds.size.height
#define COLLECTIONVIEW_FRAME    CGRectMake(0, 100, UISCREEN_WIDTH, ITEM_SIZE + 30)

typedef void(^clickSeatBlock)(SeatModel *seat, NSInteger index);


@interface SeatView : UIView

- (instancetype)initWithSeatCount:(NSInteger)count;

@property(nonatomic, copy) clickSeatBlock clickSeatBlock;

- (void)updateSeats:(NSMutableArray<RCVoiceSeatInfo *> *)seats;

- (void)setUserId:(NSString *)userId gameState:(GameState)gameState;

- (void)setUserId:(NSString *)userId isCaptain:(BOOL)isCaptain;

- (void)removeSeatWithUserId:(NSString *)userId;

- (BOOL)isCaptain:(NSString *)userId;


@end

NS_ASSUME_NONNULL_END
