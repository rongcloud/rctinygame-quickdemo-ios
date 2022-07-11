
#import "SeatView.h"
#import "RWCollectionView.h"

#define kSeatCellReuse @"SeatCellReuse"

@interface SeatView ()

@property (nonatomic, assign) NSInteger seatCount;

@property (nonatomic, strong) NSMutableArray  <SeatModel*>* seatModels;
@property (nonatomic, strong) RWCollectionView           *  collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *  layout;
/// 当前用户的麦位状态
@property (nonatomic, assign) GameState   currentUserGameState;
@property (nonatomic, strong) NSString  * currentUserId;
@property (nonatomic, assign) BOOL        isCaptaion;

@property (nonatomic, strong) NSMutableDictionary <NSString *,NSNumber *> *userGameState;
@property (nonatomic, strong) NSMutableDictionary <NSString *,NSNumber *> *userIsCaptain;


@end

@implementation SeatView

- (instancetype)initWithSeatCount:(NSInteger)count
{
    self = [super init];
    if (self) {
        self.seatCount = count;
        [self collectionViewSetup];
    }
    return self;
}

- (void)collectionViewSetup {

    [self addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.equalTo(self);
    }];
    [self.collectionView registerClass:[SeatCell class] forCellWithReuseIdentifier:kSeatCellReuse];
    self.collectionView.backgroundColor = [UIColor clearColor];
}

- (UICollectionViewFlowLayout *)layout {
    if (!_layout) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
        _layout.itemSize = CGSizeMake(ITEM_SIZE, ITEM_SIZE + 30);
        _layout.minimumLineSpacing = 20;
        _layout.minimumInteritemSpacing = 0;
        _layout.sectionInset = UIEdgeInsetsMake(0, ITEM_SIZE / 2, 0, 0);
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _layout;
}


// 加入新玩家（上麦）时候会走这里
- (void)updateSeats:(NSMutableArray<RCVoiceSeatInfo *> *)seats
{
    [self.seatModels removeAllObjects];
    
    for (NSInteger i = 0; i < seats.count; i ++) {
        SeatModel *model = [[SeatModel alloc] init];
        RCVoiceSeatInfo *seatInfo = seats[i];
        model.seatInfo = seatInfo;
        
        if (seatInfo.userId.length != 0) {
            GameState gc = (GameState)[self.userGameState[seatInfo.userId] integerValue];
            model.gameState = gc;
            
            BOOL isCaptain = [self.userIsCaptain[seatInfo.userId] boolValue];
            model.isCaptain = isCaptain;
        }
        [self.seatModels addObject:model];
    }
    
    [self.collectionView reloadData];
}

// 必须是上麦用户，才能查到
- (NSInteger)findIndexForUser:(NSString *)userId {
    NSInteger userIndex = -1;
    for (NSInteger i = 0; i < self.seatModels.count; i ++) {
        SeatModel *model = self.seatModels[i];
        if ([model.seatInfo.userId isEqualToString:userId]) {
            userIndex = i;
        }
    }
    return userIndex;
}

- (void)setUserId:(NSString *)userId gameState:(GameState)gameState {
    self.userGameState[userId] = @(gameState);
    
    NSInteger userIndex = [self findIndexForUser:userId];
    if (userIndex == -1) {
        return;
    }
  
    self.seatModels[userIndex].gameState = gameState;
    
    BOOL isCaptain = [self.userIsCaptain[userId] boolValue];
    if (gameState == GameState_unJoin && isCaptain) {
        self.userIsCaptain[userId] = @(NO);
        self.seatModels[userIndex].isCaptain = NO;
    }
    
    [self.collectionView reloadData];
}

- (void)setUserId:(NSString *)userId isCaptain:(BOOL)isCaptain {
    self.userIsCaptain[userId] = @(isCaptain);
    
    NSInteger userIndex = [self findIndexForUser:userId];
    if (userIndex == -1) {
        return;
    }
    self.seatModels[userIndex].isCaptain = isCaptain;
    [self.collectionView reloadData];
}


- (void)removeSeatWithUserId:(NSString *)userId {
    [self.userGameState removeObjectForKey:userId];
    [self.userIsCaptain removeObjectForKey:userId];
    
    NSInteger userIndex =  [self findIndexForUser:userId];
    if (userIndex >= 0) {
        self.seatModels[userIndex].seatInfo = nil;
    }
    [self.collectionView reloadData];
}

- (BOOL)isCaptain:(NSString *)userId {
    return [self.userGameState[userId] boolValue];
}


- (RWCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[RWCollectionView alloc]initWithFrame:COLLECTIONVIEW_FRAME collectionViewLayout:self.layout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        //设置回调
        __weak SeatView * wkSelf = self;
        [_collectionView setDidSelectItemAtIndexPathCb:^(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath) {
            if (wkSelf.seatModels.count == 0) {
                return;
            }
            wkSelf.clickSeatBlock ? wkSelf.clickSeatBlock(wkSelf.seatModels[indexPath.row], indexPath.row) : nil;
            
        } numberOfSectionsInCollectionViewCb:^NSInteger(UICollectionView * _Nonnull collectionView) {
            return 1;
        } numberOfItemsInSectionCb:^NSInteger(UICollectionView * _Nonnull collectionView, NSInteger section) {
            return wkSelf.seatModels.count;
        } cellForItemAtIndexPathCb:^__kindof UICollectionViewCell *(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath) {
            SeatCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSeatCellReuse forIndexPath:indexPath];
            cell.tag = indexPath.row;
            cell.seatModel = wkSelf.seatModels[indexPath.row];
            [cell reload];
            return cell;
        }];
    }
    return _collectionView;
}

- (NSMutableArray<SeatModel *> *)seatModels {
    if (!_seatModels) {
        _seatModels = [NSMutableArray array];
    }
    return _seatModels;
}


- (NSMutableDictionary<NSString *,NSNumber *> *)userGameState {
    if (!_userGameState) {
        _userGameState = [NSMutableDictionary dictionary];
    }
    return _userGameState;
}

- (NSMutableDictionary<NSString *,NSNumber *> *)userIsCaptain {
    if (!_userIsCaptain) {
        _userIsCaptain = [NSMutableDictionary dictionary];
    }
    return _userIsCaptain;
}

@end
