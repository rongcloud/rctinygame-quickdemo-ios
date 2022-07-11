
#import "GameListTableViewCell.h"
#import "GameListViewController.h"
#import "GameRoomViewController.h"

#import "UIColor+Hex.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+MD5.h"
#import "CreateRoomResponse.h"
#import "LoginResponse.h"
#import <RongRTCLib/RongRTCLib.h>
#import "RCAppDelegate.h"
#import "RCAppDelegate.h"


@interface GameListViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<RCGameInfo *> *gameList;

@end

static NSString * const gameCellIdentifier = @"GameListTableViewCell";
@implementation GameListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildLayout];
    
    RCGameConfig *gconfig = [[RCGameConfig alloc] init];
    
    [[RCGameEngine shared] initWithAppId:@"1496435759618818049" appKey:@"YS7NZ6rUAnbi0DruJJiUCmcH1AkCrQk6" config:gconfig callBack:^(int retCode, const NSString * _Nullable retMsg, const NSString * _Nullable dataJson) {
        if (retCode == 0) {
            [[RCGameEngine shared] getGameList:^(NSArray<RCGameInfo *> * _Nullable gameInfos, NSError * _Nullable error) {
                if (error) {
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"游戏列表数据获取失败 %@",error]];
                } else {
                    [self.gameList addObjectsFromArray:gameInfos];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }
            }];
        }
    }];
    
  

    if ([UserManager isGameEngineLogin] == NO) {
        NSLog(@"UserManager: %@",[UserManager userId]);
        [RCGameService loginGameWithUserId:[UserManager userId] responseClass:[GameLoginResponse class] success:^(id  _Nullable responseObject) {
            GameLoginResponse *res = (GameLoginResponse *)responseObject;
            [UserManager sharedManager].currentUser.gameSDKCode = res.data.code;
            [[UserManager sharedManager].currentUser save];
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            NSLog(@"get micphone access");
        }
    }];
}

- (void)buildLayout {
    self.title = @"游戏列表";
    self.view.backgroundColor = [UIColor colorFromHexString:@"#F6F8F9"];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}


#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.gameList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GameListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:gameCellIdentifier];
    RCGameInfo *gameInfo = self.gameList[indexPath.row];
    [cell updateCellWithName:gameInfo.gameName gameDesc:gameInfo.gameDesc gameImg:gameInfo.thumbnail];
    cell.createRoomAction = ^(UITableViewCell *cell) {
        NSInteger actionInRowIndex = [tableView indexPathForCell:cell].row;
        [self createRoomWithGameInfo:self.gameList[actionInRowIndex]];
    };
    cell.joinRoomAction = ^(UITableViewCell *cell) {
        NSInteger actionInRowIndex = [tableView indexPathForCell:cell].row;
        [self joinRoomWithGameInfo:self.gameList[actionInRowIndex]];
    };
    return cell;
}

- (void)createRoomWithGameInfo:(RCGameInfo *)gameInfo
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"创建游戏房间" message:nil preferredStyle: UIAlertControllerStyleAlert];
    [actionSheet addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入房间ID";
    }];
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"创建房间" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *roomIdField = actionSheet.textFields[0];
        NSString *roomId = roomIdField.text;
        [self createGameRoomRequestWithInfo:gameInfo roomId:roomId];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [actionSheet addAction:createAction];
    [actionSheet addAction:cancelAction];
    [self presentViewController:actionSheet animated:YES completion:nil];
}


- (void)createGameRoomRequestWithInfo:(RCGameInfo *)gameInfo roomId:(NSString *)roomId {
    NSInteger seatCount = gameInfo.maxSeat;
    NSString *password = @"1234";
    NSString *imageUrl = gameInfo.thumbnail;
    [RCGameService createRoomWithName:roomId isPrivate:0 backgroundUrl:imageUrl themePictureUrl:imageUrl password:password type:RoomTypeVoice kv:@[] responseClass:[CreateRoomResponse class] success:^(id  _Nullable responseObject) {
        if (responseObject) {
            Log(@"network create room success")
            CreateRoomResponse *res = (CreateRoomResponse *)responseObject;
            if (res.data != nil) {
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"create_room_success")];
                
                RCVoiceRoomInfo *roomInfo = [[RCVoiceRoomInfo alloc] init];
                roomInfo.roomName = roomId;
                roomInfo.seatCount = seatCount;
                roomInfo.isFreeEnterSeat = YES;
                GameRoomViewController *vc = [[GameRoomViewController alloc] initWithRoomId:roomId roomInfo:roomInfo gameInfo:gameInfo];
                vc.gameList = self.gameList;
                [self.navigationController pushViewController:vc animated:YES];
            } else {
                Log(@"network error code: %ld, msg: %@",(long)res.code, res.msg);
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ code: %ld",LocalizedString(@"network_error"),res.code]];
            }

        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ code: %ld",LocalizedString(@"create_room_fail"),(long)error.code]];
    }];
}


- (void)joinRoomWithGameInfo:(RCGameInfo *)gameInfo
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"加入游戏房间" message:nil preferredStyle: UIAlertControllerStyleAlert];
    [actionSheet addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入房间ID";
    }];
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"加入房间" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *roomIdField = actionSheet.textFields[0];
        NSString *roomId = roomIdField.text;
        GameRoomViewController *vc = [[GameRoomViewController alloc] initWithRoomId:roomId roomInfo:nil gameInfo:gameInfo];
        vc.gameList = self.gameList;
        [self.navigationController pushViewController:vc animated:YES];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [actionSheet addAction:createAction];
    [actionSheet addAction:cancelAction];
    [self presentViewController:actionSheet animated:YES completion:nil];
}



#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - Lazy Init

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.rowHeight = 110;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:[GameListTableViewCell class] forCellReuseIdentifier:gameCellIdentifier];
    }
    return _tableView;
}

- (NSMutableArray *)gameList {
    if (!_gameList) {
        _gameList = [NSMutableArray array];
    }
    return _gameList;
}

@end
