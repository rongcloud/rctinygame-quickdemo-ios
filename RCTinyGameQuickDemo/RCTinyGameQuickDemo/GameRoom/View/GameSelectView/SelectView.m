
#import "SelectView.h"
#import "RWTableView.h"
#import <Masonry/Masonry.h>

#define kSelectViewTableViewCellHeight 40
#define kSelectViewTableViewHeight     (self.games.count > 5 ? kSelectViewTableViewCellHeight * 5 : self.games.count * kSelectViewTableViewCellHeight)
#define kSelectViewTableViewCellReUse  @"kSelectViewTableViewCellReUse"
#define kPlaceHoldColor [UIColor colorWithRed:233/255. green:233/255. blue:233/255. alpha:1]

@interface SelectView ()
@property (nonatomic, strong) UIButton       * selectBtn;
@property (nonatomic, strong) RWTableView    * selectTableView;
@property (nonatomic, strong) NSMutableArray<RCGameInfo *> *games;
@end

@implementation SelectView


- (instancetype)initWithGameInfos:(NSArray *)gameInfos {
    self = [super init];
    if (self) {
        if (gameInfos.count > 0) {
            [self.games addObjectsFromArray:gameInfos];
            [self.selectBtn setTitle:@"切换游戏" forState:UIControlStateNormal];
        }
        [self subViewSetup];
    }
    return self;
}


- (void)subViewSetup {
    [self selectBtnSetup];
    [self selectTableViewSetup];
}

- (void)selectBtnSetup {
    [self addSubview:self.selectBtn];
    [self.selectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self);
        make.left.right.equalTo(self);
        make.height.equalTo(@(35));
    }];
}

- (void)selectTableViewSetup {
    self.selectTableView.hidden = YES;
    self.selectTableView.backgroundColor = kPlaceHoldColor;
    self.selectTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.selectTableView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.selectTableView];
    [self.selectTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kSelectViewTableViewCellReUse];
    [self.selectTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.selectBtn.mas_top);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(kSelectViewTableViewHeight);
    }];
    __weak SelectView * wkSelf = self;
    [self.selectTableView setNumberOfSectionsInTableViewCb:^NSInteger(UITableView * _Nonnull tableView) {
        return wkSelf.games.count > 0 ? 1 : 0;
    } numberOfRowsInSectionCb:^NSInteger(UITableView * _Nonnull tableView, NSInteger section) {
        return wkSelf.games.count;
    } heightForRowAtIndexPathCb:^CGFloat(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        return kSelectViewTableViewCellHeight;
    } cellForRowAtIndexPathCb:^__kindof UITableViewCell *(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:kSelectViewTableViewCellReUse];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSelectViewTableViewCellReUse];
        }
        cell.backgroundColor = kPlaceHoldColor;
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        
        RCGameInfo *game = wkSelf.games[indexPath.row];
        cell.textLabel.text = game.gameName;
        return cell;
    } didSelectRowAtIndexPathCb:^(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        RCGameInfo *game = wkSelf.games[indexPath.row];
        /// 事件回调
        if (wkSelf.selectBtnDidClickedCb) {
            wkSelf.selectBtnDidClickedCb(game);
            [wkSelf hideTableView];
        }
        
    }heightForHeaderInSectionCb:^CGFloat(UITableView * _Nonnull tableView, NSInteger section) {
        return 0.01;
    } viewForHeaderInSectionCb:^UIView *(UITableView * _Nonnull tableView, NSInteger section) {
        return [UIView new];
    }];
}

- (void)selectBtnClick:(UIButton *)btn {
    if (self.selectTableView.hidden == YES) {
        [self showTableView];
    }else {
        [self hideTableView];
    }
}

- (void)showTableView {
    self.selectTableView.hidden = NO;
    if (self.superview == nil) {
        return;
    }
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(kSelectViewTableViewHeight + kSelectViewTableViewCellHeight);
    }];
    [self layoutIfNeeded];
}

- (void)hideTableView {
    self.selectTableView.hidden = YES;
    if (self.superview == nil) {
        return;
    }
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(kSelectViewTableViewCellHeight);
    }];
    [self layoutIfNeeded];
}

- (NSString *)selectString {
    return self.selectBtn.titleLabel.text;
}

- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectBtn.layer.cornerRadius = 8;
        _selectBtn.clipsToBounds = YES;
        _selectBtn.layer.borderWidth = 1;
        _selectBtn.layer.borderColor = [UIColor clearColor].CGColor;
        _selectBtn.titleLabel.font    = [UIFont systemFontOfSize:14];
        _selectBtn.backgroundColor = [UIColor colorWithRed:255/255. green:186/255. blue:41/255. alpha:1];
        [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_selectBtn addTarget:self action:@selector(selectBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectBtn;
}


- (RWTableView *)selectTableView {
    if (!_selectTableView) {
        _selectTableView = [[RWTableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _selectTableView.layer.cornerRadius = 15;
        _selectTableView.clipsToBounds = YES;
    }
    return _selectTableView;
}

- (NSMutableArray *)games {
    if (!_games) {
        _games = [[NSMutableArray alloc]init];
    }
    return _games;
}

@end
