#import "GameRoomViewController.h"
#import "UIColor+Hex.h"
#import "UserManager.h"
#import "SeatView.h"
#import "LoginResponse.h"
#import "RoomUserListResponse.h"
#import "GameMessage.h"
#import "SelectView.h"

static NSString * const cellIdentifier = @"SeatInfoCollectionViewCell";
@interface GameRoomViewController () <RCVoiceRoomDelegate, RCGameStateDelegate, RCGamePlayerStateDelegate, RCChatroomSceneToolBarDelegate>

@property (nonatomic, strong) UIView *gameContainer;

// 退出房间
@property (nonatomic, strong) UIButton *quitButton;
// 用户id label
@property (nonatomic, strong) UILabel *userLabel;


/// 麦位
@property (nonatomic, strong) SeatView *seatView;

@property (nonatomic, strong) SelectView *gameSelectView;

@property (nonatomic, strong) RCChatroomSceneMessageView *messageView;
@property (nonatomic, strong) RCChatroomSceneToolBar *toolbar;

@property (nonatomic, strong) UIButton *micButton;

@property (nonatomic, assign) BOOL isCreate;

@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *currentPlayerUserId;

@property (nonatomic, assign) RCGameState currentGameState;
@property (nonatomic, strong) RCGameInfo *currentGameInfo;
@property (nonatomic, copy) RCVoiceRoomInfo *roomInfo;

// 根据seatInfoDidUpdate 获取的最新麦位信息
@property (nonatomic, copy) NSMutableArray<RCVoiceSeatInfo *> *seatlist;

@end

@implementation GameRoomViewController

- (instancetype)initWithRoomId:(NSString *)roomId roomInfo:(RCVoiceRoomInfo *)roomInfo gameInfo:(RCGameInfo *)gameInfo {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.roomId = roomId;
        self.roomInfo = roomInfo;
        self.currentGameInfo = gameInfo;
        self.isCreate = (roomInfo == nil) ? NO : YES;
        [RCVoiceRoomEngine.sharedInstance setDelegate:self];
        [self updateRoomOnlineStatus];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.view.backgroundColor = [UIColor colorFromHexString:@"#F6F8F9"];
    
    [self.view addSubview:self.quitButton];
    [self.quitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).inset(10);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.size.equalTo(@(CGSizeMake(40, 40)));
    }];
    
    if (self.showForSwitchGame) { // 切换游戏进来，加载游戏 更新麦位状态
        [self loadGame];
        [RCVoiceRoomEngine.sharedInstance getLatestSeatInfo:^(NSArray<RCVoiceSeatInfo *> * _Nonnull seats) {
            self.seatlist = [seats mutableCopy];
            [self.seatView updateSeats:self.seatlist];
        } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
            
        }];
    } else {
        if (self.isCreate) {// 创建或者加入语聊房
            [self createVoiceRoom:_roomId info:_roomInfo];
        } else {
            [self joinVoiceRoom:_roomId];
        }
    }
}

- (void)updateRoomOnlineStatus {
    [RCGameService updateOnlineRoomStatusWithRoomId:self.roomId responseClass:nil success:^(id  _Nullable responseObject) {
        Log(@"update room online status success");
    } failure:^(NSError * _Nonnull error) {
        Log(@"update room online status fail code : %ld",error.code);
    }];
}


//创建加入房间
- (void)createVoiceRoom:(NSString *)roomId info:(RCVoiceRoomInfo *)roomInfo {
    [[RCVoiceRoomEngine sharedInstance] createAndJoinRoom:roomId room:roomInfo success:^{
        [SVProgressHUD showSuccessWithStatus:@"创建成功"];
        [self loadGame];
    } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
        [SVProgressHUD showSuccessWithStatus:@"创建失败"];
    }];
}

//加入房间
- (void)joinVoiceRoom:(NSString *)roomId {
    [[RCVoiceRoomEngine sharedInstance] joinRoom:roomId success:^{
        [SVProgressHUD showSuccessWithStatus:@"加入房间成功"];
        [self loadGame];
    } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.backgroundColor = [UIColor grayColor];
            [SVProgressHUD showSuccessWithStatus:@"加入房间失败"];
        });
    }];
}

// 离开房间
- (void)quitRoom {
    if (self.seatlist.count == 0) {
        [self popSelfToLeave];
        return;
    }
    void(^leaveVoiceRoomRoom)(void) = ^(void){
        [[RCVoiceRoomEngine sharedInstance] leaveRoom:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"离开房间成功"];
                [self popSelfToLeave];
            });
        } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"离开房间失败 code: %ld",(long)code]];
                [self popSelfToLeave];
            });
        }];
    };
    
    if (self.isCreate) { // 主播端调用业务接口销毁房间
        [RCGameService deleteRoomWithRoomId:self.roomId success:^(id  _Nullable responseObject) {
            leaveVoiceRoomRoom();
        } failure:^(NSError * _Nonnull error) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"销毁房间失败 code: %ld",error.code]];
            [self popSelfToLeave];
        }];
    } else { // 观众端直接离开
        leaveVoiceRoomRoom();
    }
}

- (void)popSelfToLeave {
    [[RCGameEngine shared] destroyEngine];
    if (self.showForSwitchGame) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:true];
    }
}

- (void)loadGame {
    self.currentPlayerUserId = UserManager.userId;
    
    [[RCGameEngine shared] setGameStateDelegate:self];
    [[RCGameEngine shared] setPlayerStateDelegate:self];
    
    RCGameOption *opt = [RCGameOption defaultOption];
    
    CGFloat scale = [[UIScreen mainScreen] nativeScale];
    UIEdgeInsets safeInset = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    CGFloat top = (safeInset.top + 102) * scale;
    CGFloat bottom =(safeInset.bottom + 150) * scale;
    
    opt.gameSafeRect = UIEdgeInsetsMake(top, 0, bottom, 0);
    
    opt.sound = [RCGameSound gameSoundControl:OPEN volume:100];
    [opt.gameUI lobbyPlayersCustom:NO hide:YES];
    [opt.gameUI versionHide:YES];


    RCGameRoomInfo *gameRoomInfo = [RCGameRoomInfo new];
    gameRoomInfo.appCode = [UserManager sharedManager].currentUser.gameSDKCode;
    gameRoomInfo.roomId = _roomId;
    gameRoomInfo.gameId = self.currentGameInfo.gameId;
    gameRoomInfo.userId = _currentPlayerUserId;
    
    [[RCGameEngine shared] loadGameWithView:self.view roomInfo:gameRoomInfo gameOption:opt];
}


- (void)switchGameWithInfo:(RCGameInfo *)info {
    if (self.currentGameState == PLAYING) {
        [SVProgressHUD showSuccessWithStatus:@"游戏中无法切换"];
        return;
    }
    if (info == nil) {
        return;
    }
    if ([info.gameId isEqualToString:self.currentGameInfo.gameId]) {
        return;
    }
//    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//    [[RCGameEngine shared] destroyEngine];
//    GameRoomViewController *gameVc = [[GameRoomViewController alloc] initWithRoomId:self.roomId roomInfo:nil gameInfo:info];
//    gameVc.showForSwitchGame = YES;
//    gameVc.gameList = self.gameList;
//    [self.navigationController pushViewController:gameVc animated:NO];
    
    [[RCGameEngine shared] switchGame:info.gameId gameCallback:^(int retCode, const NSString * _Nullable retMsg, const NSString * _Nullable dataJson) {
        
    }];
   
  
}

#pragma mark - RCGameStateDelegate

- (void)onExpireCode {
    [RCGameService loginGameWithUserId:_currentPlayerUserId responseClass:[GameLoginResponse class] success:^(id  _Nullable responseObject) {
        GameLoginResponse *res = (GameLoginResponse *)responseObject;
        [UserManager sharedManager].currentUser.gameSDKCode = res.data.code;
        [[UserManager sharedManager].currentUser save];
        [[RCGameEngine shared] updateCode:res.data.code];
    } failure:^(NSError * _Nonnull error) {
        
    }];
}
/** 游戏加载完成 */
- (void)onGameLoaded {
    [[RCVoiceRoomEngine sharedInstance] disableAudioRecording:YES];
    [self buildLayout];
    
}

/**  游戏销毁 */
- (void)onGameDestroyed {
    
}

/**
 * 游戏内消息通知
 */
- (void)onReceivePublicMessage:(NSAttributedString *)attributedMessage rawMessage:(NSString *)rawMessage {
    NSLog(@"game message: %@", attributedMessage);
    GameMessage *msg = [[GameMessage alloc] initWithAttributedMessage:attributedMessage];
    [self.messageView addMessage:msg];
}
/**
 * 游戏状态改变
 *
 * @param gameState (idle 状态，游戏未开始，空闲状态）；
 *                  （loading 状态，所有玩家都准备好，队长点击了开始游戏按钮，等待加载游戏场景开始游戏）；
 *                  （playing状态，游戏进行中状态）
 */
- (void)onGameStateChanged:(RCGameState)gameState {
    self.currentGameState = gameState;
}


- (void)onGameSettle:(RCGameSettle *)gameSettle {
    
}


// 根据玩家ID，上麦
- (void)enterSeatWithPlayUserId:(NSString *)playUserId isCurrentUser:(BOOL)isCurrentUser {
    if (isCurrentUser == NO) {
        return;
    }
    
    // 新玩家进入，开始游戏正在上麦, plyaerIn的回调先到这里
    BOOL newPlayerInAtSeat = NO;
    for (NSInteger i = 0; i < self.seatlist.count; i++) {
        RCVoiceSeatInfo *seaInfo = self.seatlist[i];
        if ([seaInfo.userId isEqualToString:playUserId]) {
            newPlayerInAtSeat = YES;
            break;
        }
    }
    
    if (newPlayerInAtSeat) {
        return;
    }
    
    // 根据语聊房麦位, 确定游戏index
    NSInteger canEnterIndex = 0;
    for (NSInteger i = 0; i < self.seatlist.count; i++) {
        RCVoiceSeatInfo *seaInfo = self.seatlist[i];
        if (seaInfo.status == RCSeatStatusEmpty) {
            canEnterIndex = i;
            break;
        }
    }
    
    RCVoiceSeatInfo *seatInfo = self.seatlist[canEnterIndex];
    
    if (seatInfo.status == RCSeatStatusUsing) {
        NSLog(@"当前座位已经上麦");
        return;
    }
    if (seatInfo.status == RCSeatStatusLocking) {
        [SVProgressHUD showErrorWithStatus:@"当前座位被锁定"];
        //增加 退出游戏操作
        return;
    }
    if (seatInfo.status == RCSeatStatusEmpty) {
        [[RCVoiceRoomEngine sharedInstance] enterSeat:canEnterIndex success:^{
            [SVProgressHUD showSuccessWithStatus:@"上麦成功"];
            [self.seatView setUserId:playUserId gameState:GameState_unPrepare];
            
        } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"上麦失败 code: %ld",(long)code]];
        }];
    }
}

#pragma mark - RCGamePlayerStateDelegate
/**
 * 玩家加入或退出游戏
 *
 * @param userId 玩家id
 * @param isIn   true：加入，false：退出
 * @param teamId 队伍id，默认1
 */
- (void)onPlayerIn:(NSString *)userId isIn:(BOOL)isIn teamId:(NSInteger)teamId {
    // 1.自己新创建的游戏房，无玩家
    
    // 2.进入游戏房，已经有玩家加入。
    // 2.1 进入游戏房，无玩家加入，但是有人在麦位上。
    [self.seatView setUserId:userId gameState:(isIn ? GameState_unPrepare : GameState_unJoin)];
    
    if (isIn) {
        BOOL isCurrent = [self.currentPlayerUserId isEqualToString:userId];
        [self enterSeatWithPlayUserId:userId isCurrentUser:isCurrent];
    } else {
        if ([userId isEqualToString:self.currentPlayerUserId]) { // 自己退出，隐藏切换按钮
            self.gameSelectView.hidden = YES;
        }
    }
}

/**
 * 队长变更
 *
 * @param userId    玩家id
 * @param isCaptain true：成为队长，false：失去队长身份
 */
- (void)onPlayerCaptain:(NSString *)userId isCaptain:(BOOL)isCaptain {
    [self.seatView setUserId:userId isCaptain:isCaptain];
    
    if ([userId isEqualToString:self.currentPlayerUserId]) { //当前用户
        if ([self.seatView isCaptain:self.currentPlayerUserId]) {
            self.gameSelectView.hidden = NO;
        } else {
            self.gameSelectView.hidden = YES;
        }
    }
    
}

/**
 * 玩家准备/取消准备
 *
 * @param userId  玩家id
 * @param isReady true：准备 false：取消准备
 */
- (void)onPlayerReady:(NSString *)userId isReady:(BOOL)isReady {
    [self.seatView setUserId:userId gameState:(isReady ? GameState_prepared: GameState_unPrepare)];
}
/**
 * 玩家游戏状态
 *
 * @param userId    玩家id
 * @param isPlaying true 正在游戏中， false游戏结束
 */
- (void)onPlayerPlaying:(NSString *)userId isPlaying:(BOOL)isPlaying {
    if (isPlaying) {
        [self.seatView setUserId:userId gameState:GameState_Playing];
    }
}

/**
 * 玩家换位置
 * @param userId 玩家id
 * @param from   之前的位置
 * @param to     之后的位置
 */
- (void)onPlayerChangeSeat:(NSString *)userId from:(NSInteger)from to:(NSInteger)to {
    
}

#pragma mark - VoiceRoom Control

//下麦
- (void)leaveSeatWithSeatInfo:(RCVoiceSeatInfo *)seatInfo {
    if (seatInfo.status == RCSeatStatusEmpty) {
        NSLog(@"麦位无人，无需下麦");
        return;
    }
    if (seatInfo.status == RCSeatStatusLocking) {
        [SVProgressHUD showErrorWithStatus:@"当前座位被锁定"];
        return;
    }
    
    if (seatInfo.status == RCSeatStatusUsing) {
        if ([seatInfo.userId isEqualToString:UserManager.userId]) {
            [[RCVoiceRoomEngine sharedInstance] leaveSeatWithSuccess:^{
                [SVProgressHUD showSuccessWithStatus:@"下麦成功"];
            } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"下麦失败 code: %ld",(long)code]];
            }];
        }
    }
}

//锁麦
- (void)lockSeatWithSeatInfo:(RCVoiceSeatInfo *)seatInfo seatIndex:(NSInteger)index {
    if (seatInfo.status == RCSeatStatusLocking) {
        //当前为锁定状态时进行解锁操作
        [[RCVoiceRoomEngine sharedInstance] lockSeat:index lock:NO success:^{
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"座位:%ld解锁成功",index]];
        } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"座位解锁失败 code: %ld",code]];
        }];
    } else {
        //锁定座位
        [[RCVoiceRoomEngine sharedInstance] lockSeat:index lock:YES success:^{
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"座位:%ld锁定成功",index]];
        } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"座位锁定失败 code: %ld",code]];
        }];
    }
}

//静音麦位
- (void)muteSeatWithSeatInfo:(RCVoiceSeatInfo *)seatInfo seatIndex:(NSInteger)index {
    if (seatInfo.status == RCSeatStatusUsing || seatInfo.status == RCSeatStatusEmpty) {
        [[RCVoiceRoomEngine sharedInstance] muteSeat:index mute:!seatInfo.isMuted success:^{
            NSString *string = seatInfo.isMuted ? @"解除静音成功" : @"静音成功";
            [SVProgressHUD showSuccessWithStatus:string];
        } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
            NSString *string = seatInfo.isMuted ? @"解除静音失败 code: %ld" : @"解除静音失败 code: %ld";
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:string,(long)code]];
        }];
    }  else if (seatInfo.status == RCSeatStatusLocking) {
        [SVProgressHUD showErrorWithStatus:@"当前座位被锁定"];
    }
}

//踢人
- (void)kickSeatWithSeatInfo:(RCVoiceSeatInfo *)seatInfo seatIndex:(NSInteger)index {
    if (seatInfo.status == RCSeatStatusUsing) {
        [[RCVoiceRoomEngine sharedInstance] kickUserFromSeat:seatInfo.userId success:^{
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"用户:%@已经被踢出座位",seatInfo.userId]];
        } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"踢出用户失败 code: %ld",(long)code]];
        }];
    } else if (seatInfo.status == RCSeatStatusEmpty) {
        [SVProgressHUD showErrorWithStatus:@"当前座位为空"];
    } else if (seatInfo.status == RCSeatStatusLocking) {
        [SVProgressHUD showErrorWithStatus:@"当前座位被锁定"];
    }
}

- (void)speakerEnable:(UIButton *)sender {
    [[RCVoiceRoomEngine sharedInstance] enableSpeaker:!sender.selected];
    sender.selected = !sender.selected;
}

- (void)muteAll:(UIButton *)sender {
    [[RCVoiceRoomEngine sharedInstance] muteOtherSeats:!sender.selected];
    sender.selected = !sender.selected;
}

- (void)lockAll:(UIButton *)sender {
    [[RCVoiceRoomEngine sharedInstance] lockOtherSeats:!sender.selected];
    sender.selected = !sender.selected;
}


#pragma mark - VoiceRoomLib Delegate
// 房间信息初始化完毕，可在此方法进行一些初始化操作，例如进入房间房主自动上麦等
- (void)roomKVDidReady {
    
}

// 任何麦位的变化都会触发此回调。
- (void)seatInfoDidUpdate:(NSArray<RCVoiceSeatInfo *> *)seatInfolist {
    self.seatlist = [seatInfolist mutableCopy];
    [self.seatView updateSeats:self.seatlist];
}

// 任何房间信息的修改都会触发此回调。
- (void)roomInfoDidUpdate:(RCVoiceRoomInfo *)roomInfo {
    self.roomInfo = roomInfo;
}


// 收到被下麦的回调
- (void)kickSeatDidReceive:(NSUInteger)seatIndex {
    [[RCVoiceRoomEngine sharedInstance] leaveSeatWithSuccess:^{
        [SVProgressHUD showSuccessWithStatus:@"被踢下麦"];
    } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
        [SVProgressHUD showErrorWithStatus:@"被踢下麦失败"];
    }];
}

// 聊天室消息回调
- (void)messageDidReceive:(nonnull RCMessage *)message {
    RCTextMessage *textMsg = (RCTextMessage *)message.content;
    Log(@"messageDidReceive %@",textMsg.content);
    if (textMsg.content.length == 0) { return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([textMsg.content containsString:@"gameId"]) {
            NSRange gameIdR = [textMsg.content rangeOfString:@"gameId:"];
            NSString *newGameId = [textMsg.content substringWithRange:NSMakeRange(gameIdR.length, textMsg.content.length - gameIdR.length)];
            RCGameInfo *newIdForInfo = nil;
            for (RCGameInfo *info in self.gameList) {
                if ([newGameId isEqualToString:info.gameId]) {
                    newIdForInfo = info;
                    break;
                }
            }
            [self switchGameWithInfo:newIdForInfo];
            return;
        }
        NSString *message = [NSString stringWithFormat:@"%@: %@",textMsg.senderUserInfo.name, textMsg.content];
        NSMutableAttributedString *attMsg = [[NSMutableAttributedString alloc] initWithString:message];
        [attMsg addAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:10]} range:NSMakeRange(0, attMsg.length)];
        GameMessage *gameMsg = [[GameMessage alloc] initWithAttributedMessage:attMsg];
        [self.messageView addMessage:gameMsg];
    });
}



// 房间发生了未知错误
- (void)roomDidOccurError:(RCVoiceRoomErrorCode)code {
    
}

// 通过
- (void)roomNotificationDidReceive:(nonnull NSString *)name content:(nonnull NSString *)content {
    
}

// 某个麦位被锁定时会触发此回调
- (void)seatDidLock:(NSInteger)index isLock:(BOOL)isLock {
    
}

// 某个麦位被静音或解除静音时会触发此回调
- (void)seatDidMute:(NSInteger)index isMute:(BOOL)isMute {
    
}

// 某个麦位有人说话时会触发此回调
- (void)speakingStateDidChange:(NSUInteger)seatIndex speakingState:(BOOL)isSpeaking {
    
}

// 用户进入房间时会触发此回调
- (void)userDidEnter:(nonnull NSString *)userId {
    
}

// 用户上了某个麦位时会触发此回调
- (void)userDidEnterSeat:(NSInteger)seatIndex user:(nonnull NSString *)userId {
    
}

// 用户离开房间时触发此回调
- (void)userDidExit:(nonnull NSString *)userId {
    
}

// 用户被踢出房间时触发此回调
- (void)userDidKickFromRoom:(nonnull NSString *)targetId byUserId:(nonnull NSString *)userId {
    
}

// 用户下麦某个麦位触发此回调
- (void)userDidLeaveSeat:(NSInteger)seatIndex user:(nonnull NSString *)userId {
    [self.seatView removeSeatWithUserId:userId];
}



#pragma mark RCChatroomSceneToolBarDelegate
/// 文本输入点击发送后调用
- (void)textInputViewSendText:(NSString *)text {
    if (text.length == 0) {
        return;
    }
    RCUserInfo *user = [[RCUserInfo alloc] init];
    user.userId = self.currentPlayerUserId;
    user.name = [UserManager userName];
    RCTextMessage *content = [RCTextMessage messageWithContent:text];
    content.senderUserInfo = user;
    [[RCVoiceRoomEngine sharedInstance] sendMessage:content success:^{
        
    } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
        
    }];
    
    NSString *message = [NSString stringWithFormat:@"%@: %@",[UserManager userName], text];
    NSMutableAttributedString *attMsg = [[NSMutableAttributedString alloc] initWithString:message];
    [attMsg addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]} range:NSMakeRange(0, attMsg.length)];
    GameMessage *gameMsg = [[GameMessage alloc] initWithAttributedMessage:attMsg];
    [self.messageView addMessage:gameMsg];
}

- (void)handleClickMySeat:(NSString *)userId index:(NSInteger)index isCaptain:(BOOL)isCaptain {
    if (isCaptain) { // 队长
        if (self.currentGameState == PLAYING) {
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"你确定要结束本局游戏吗？" message:nil preferredStyle: UIAlertControllerStyleAlert];
            UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[RCGameEngine shared] endGame:^(int retCode, const NSString * _Nonnull retMsg, const NSString * _Nonnull dataJson) {
                    
                }];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertVc addAction:createAction];
            [alertVc addAction:cancelAction];
            [self presentViewController:alertVc animated:YES completion:nil];
        } else {
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"你确定要下麦吗？" message:nil preferredStyle: UIAlertControllerStyleAlert];
            UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                RCVoiceSeatInfo *seaInfo = self.seatlist[index];
                [self leaveSeatWithSeatInfo:seaInfo];
                [[RCGameEngine shared] cancelReadyGame:^(int retCode, const NSString * _Nullable retMsg, const NSString * _Nullable dataJson) {
                    
                }];
                [[RCGameEngine shared] cancelJoinGame:^(int retCode, const NSString * _Nullable retMsg, const NSString * _Nullable dataJson) {
                    
                }];
                
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertVc addAction:createAction];
            [alertVc addAction:cancelAction];
            [self presentViewController:alertVc animated:YES completion:nil];
        }
    } else { // 普通玩家
        if (self.currentGameState == PLAYING) {
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"你确定要退出游戏吗？" message:nil preferredStyle: UIAlertControllerStyleAlert];
            UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[RCGameEngine shared] cancelPlayGame:^(int retCode, const NSString * _Nonnull retMsg, const NSString * _Nonnull dataJson) {
                    
                }];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertVc addAction:createAction];
            [alertVc addAction:cancelAction];
            [self presentViewController:alertVc animated:YES completion:nil];
        } else {
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"你确定要下麦吗？" message:nil preferredStyle: UIAlertControllerStyleAlert];
            UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                RCVoiceSeatInfo *seaInfo = self.seatlist[index];
                [self leaveSeatWithSeatInfo:seaInfo];
                [[RCGameEngine shared] cancelReadyGame:^(int retCode, const NSString * _Nullable retMsg, const NSString * _Nullable dataJson) {
                    
                }];
                [[RCGameEngine shared] cancelJoinGame:^(int retCode, const NSString * _Nonnull retMsg, const NSString * _Nonnull dataJson) {
                    
                }];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertVc addAction:createAction];
            [alertVc addAction:cancelAction];
            [self presentViewController:alertVc animated:YES completion:nil];
        }
    }
}

- (void)handleClickOtherSeat:(NSString *)userId index:(NSInteger)index {
    if (userId.length == 0) {
        return;
    }
    NSString *title = [NSString stringWithFormat:@"确定要踢出%@吗？",userId];
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[RCGameEngine shared] kickPlayer:userId gameCallback:^(int retCode, const NSString * _Nonnull retMsg, const NSString * _Nonnull dataJson) {
            
        }];
        RCVoiceSeatInfo *seaInfo = self.seatlist[index];
        [self kickSeatWithSeatInfo:seaInfo seatIndex:index];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVc addAction:createAction];
    [alertVc addAction:cancelAction];
    [self presentViewController:alertVc animated:YES completion:nil];
}



- (void)micButtonClicked:(UIButton *)btn {
    btn.selected = !btn.selected;
    [[RCVoiceRoomEngine sharedInstance] disableAudioRecording:!btn.selected];
}


#pragma mark -Layout Subviews

- (void)buildLayout {
    
    [self.view addSubview:self.userLabel];
    [self.userLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.quitButton);
        make.left.equalTo(self.view).offset(10);
        make.height.equalTo(self.quitButton);
    }];
    
    [self.view addSubview:self.seatView];
    [self.seatView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.top.equalTo(self.userLabel.mas_bottom);
        make.right.equalTo(self.view);
        make.height.equalTo(@70);
    }];
    
    [self.view addSubview:self.micButton];
    [self.micButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-15);
        make.left.equalTo(self.view).offset(15);
        make.width.equalTo(@30);
        make.height.equalTo(@30);
    }];
    
    [self.view addSubview:self.toolbar];
    [self.toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.micButton.mas_right).offset(5);
        make.centerY.equalTo(self.micButton);
        make.height.equalTo(@30);
    }];
    
    [self.view addSubview:self.gameSelectView];
    [self.gameSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-15);
        make.right.equalTo(self.view).offset(-15);
        make.width.equalTo(@100);
        make.height.equalTo(@30);
    }];
    
    [self.view addSubview:self.messageView];
    [self.messageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(-15);
        make.bottom.equalTo(self.micButton.mas_top).offset(-5);
        make.width.equalTo(@300);
        make.height.equalTo(@120);
    }];
    _gameSelectView.hidden = YES;
    
}

- (UIButton *)actionButtonFactory:(NSString *)title withAction:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor colorFromHexString:@"#EF499A"];
    button.layer.cornerRadius = 6;
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    [button setTitle:title forState: UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState: UIControlStateNormal];
    [button addTarget:self action:action forControlEvents: UIControlEventTouchUpInside];
    [[button.widthAnchor constraintGreaterThanOrEqualToConstant:70] setActive:YES];
    return button;
}

- (UIStackView *)stackViewWithViews:(NSArray *)views {
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:views];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 10;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    return stackView;
}

#pragma mark - lazy In

- (NSMutableArray<RCVoiceSeatInfo *> *)seatlist {
    if (!_seatlist) {
        _seatlist = [NSMutableArray array];
    }
    return _seatlist;
}

- (RCChatroomSceneToolBar *)toolbar {
    if (!_toolbar) {
        _toolbar = [[RCChatroomSceneToolBar alloc] init];
        _toolbar.delegate = self;
    }
    return _toolbar;
}

- (SeatView *)seatView {
    if (!_seatView) {
        NSInteger seatCount = self.currentGameInfo.maxSeat;
        _seatView = [[SeatView alloc] initWithSeatCount:seatCount];
        __weak typeof(self) wkSelf = self;
        _seatView.clickSeatBlock = ^(SeatModel *seat, NSInteger index) {
            if (seat.seatInfo.userId.length == 0 && seat.seatInfo.status == RCSeatStatusEmpty) {
                BOOL newPlayerInAtSeat = NO;
                for (NSInteger i = 0; i < wkSelf.seatlist.count; i++) {
                    RCVoiceSeatInfo *seaInfo = wkSelf.seatlist[i];
                    if ([seaInfo.userId isEqualToString:wkSelf.currentPlayerUserId]) {
                        newPlayerInAtSeat = YES;
                        break;
                    }
                }
                // 麦位无人，且当前用户已经没有上其他麦位，就执行上麦，开始游戏逻辑
                if (!newPlayerInAtSeat) {
                    [[RCVoiceRoomEngine sharedInstance] enterSeat:index success:^{
                        [SVProgressHUD showSuccessWithStatus:@"上麦成功"];
                        [[RCGameEngine shared] joinGame:^(int retCode, const NSString * _Nullable retMsg, const NSString * _Nullable dataJson) {
                        }];
                    } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
                        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"上麦失败 code: %ld",(long)code]];
                    }];
                }
            }
            
            if ([seat.seatInfo.userId isEqualToString:wkSelf.currentPlayerUserId]) {
                [wkSelf handleClickMySeat:seat.seatInfo.userId index:index isCaptain:seat.isCaptain];
            } else {
                if ([wkSelf.seatView isCaptain:wkSelf.currentPlayerUserId]) { // current usr is captain
                    [wkSelf handleClickOtherSeat:seat.seatInfo.userId index:index];
                }
            }
        };
    }
    return _seatView;
}

- (UIButton *)quitButton {
    if (!_quitButton) {
        _quitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_quitButton setImage:[UIImage imageNamed:@"white_quite_icon"] forState:UIControlStateNormal];
        [_quitButton addTarget:self action:@selector(quitRoom) forControlEvents:UIControlEventTouchUpInside];
    }
    return _quitButton;
}

- (UILabel *)userLabel {
    if (!_userLabel) {
        _userLabel = [[UILabel alloc] init];
        _userLabel.font = [UIFont systemFontOfSize:9.5];
        _userLabel.textColor = [UIColor whiteColor];
        _userLabel.numberOfLines = 0;
        _userLabel.text = [NSString stringWithFormat:@"当前用户：%@\n用户名：%@\n房间：%@", UserManager.userId, UserManager.userName, self.roomId];
    }
    return _userLabel;
}

- (UIButton *)micButton {
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_micButton setImage:[UIImage imageNamed:@"mic_close"] forState:UIControlStateNormal];
        [_micButton setImage:[UIImage imageNamed:@"mic_open"] forState:UIControlStateSelected];
        [_micButton addTarget:self action:@selector(micButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _micButton;
}

- (RCChatroomSceneMessageView *)messageView {
    if (!_messageView) {
        _messageView = [[RCChatroomSceneMessageView alloc] init];
    }
    return _messageView;
}

- (SelectView *)gameSelectView {
    if (!_gameSelectView) {
        _gameSelectView = [[SelectView alloc] initWithGameInfos:self.gameList];
        __weak typeof(self) wkSelf = self;
        _gameSelectView.selectBtnDidClickedCb = ^(RCGameInfo *gameInfo) { // 游戏中切换游戏
            NSLog(@"selectGameId:%@",gameInfo);
            [wkSelf switchGameWithInfo:gameInfo];
            NSString *switchGameMsg = [NSString stringWithFormat:@"gameId:%@",gameInfo.gameId];
            RCTextMessage *content = [RCTextMessage messageWithContent:switchGameMsg];
            [[RCVoiceRoomEngine sharedInstance] sendMessage:content success:^{
                
            } error:^(RCVoiceRoomErrorCode code, NSString * _Nonnull msg) {
                
            }];
        };
    }
    return _gameSelectView;
}

- (UIView *)gameContainer {
    if (!_gameContainer) {
        _gameContainer = [[UIView alloc] init];
    }
    return _gameContainer;;
}
@end
