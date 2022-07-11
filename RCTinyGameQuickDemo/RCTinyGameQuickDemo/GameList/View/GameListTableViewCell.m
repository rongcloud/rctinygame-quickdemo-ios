
#import "GameListTableViewCell.h"


@interface GameListTableViewCell ()

@property (nonatomic, strong) UIImageView *gameImageView;
@property (nonatomic, strong) UILabel *gameNameLabel;
@property (nonatomic, strong) UILabel *gameDescLabel;


@property (nonatomic, strong) UIButton *createButton;
@property (nonatomic, strong) UIButton *joinButton;

@end

@implementation GameListTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self buildLayout];
    }
    return self;
}

- (void)buildLayout {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self.contentView addSubview:self.gameImageView];
    [self.contentView addSubview:self.gameNameLabel];
    [self.contentView addSubview:self.gameDescLabel];
    
    [self.contentView addSubview:self.createButton];
    [self.contentView addSubview:self.joinButton];

    [self.gameImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(25);
        make.size.mas_equalTo(CGSizeMake(45, 45));
    }];
    
    [self.gameNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.gameImageView);
        make.left.equalTo(self.gameImageView.mas_right).offset(16);
    }];
    
    [self.gameDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.gameNameLabel.mas_bottom).offset(5);
        make.left.equalTo(self.gameNameLabel);
    }];
    
    [self.createButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(15);
        make.right.equalTo(self.contentView).offset(-15);
        make.width.mas_equalTo(55);
    }];
    
    
    [self.joinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.contentView).offset(-15);
        make.right.equalTo(self.contentView).offset(-15);
        make.width.mas_equalTo(55);
    }];
    
}

#pragma mark - Lazy Init
- (UIImageView *)gameImageView {
    if (!_gameImageView) {
        _gameImageView = [[UIImageView alloc] init];
    }
    return _gameImageView;
}

- (UILabel *)gameNameLabel {
    if (!_gameNameLabel) {
        _gameNameLabel = [[UILabel alloc] init];
        _gameNameLabel.textColor = [UIColor blackColor];
        _gameNameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    }
    return _gameNameLabel;
}

- (UILabel *)gameDescLabel {
    if (!_gameDescLabel) {
        _gameDescLabel = [[UILabel alloc] init];
        _gameDescLabel.textColor = [UIColor blackColor];
        _gameDescLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    }
    return _gameDescLabel;
}


- (UIButton *)createButton {
    if (!_createButton) {
        _createButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_createButton setTitle:@"创建" forState:UIControlStateNormal];
        _createButton.titleLabel.textColor = [UIColor whiteColor];
        _createButton.titleLabel.font = [UIFont systemFontOfSize:13];
        _createButton.backgroundColor = [UIColor purpleColor];
        [_createButton addTarget:self action:@selector(createButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _createButton;
}

- (UIButton *)joinButton {
    if (!_joinButton) {
        _joinButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_joinButton setTitle:@"加入" forState:UIControlStateNormal];
        _joinButton.titleLabel.textColor = [UIColor whiteColor];
        _joinButton.titleLabel.font = [UIFont systemFontOfSize:13];
        _joinButton.backgroundColor = [UIColor purpleColor];
        [_joinButton addTarget:self action:@selector(joinButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _joinButton;
}

- (void)createButtonClick:(UIButton *)btn {
    self.createRoomAction ? self.createRoomAction(self) : nil;
}

- (void)joinButtonClick:(UIButton *)btn {
    self.joinRoomAction ? self.joinRoomAction(self) : nil;
}

- (void)updateCellWithName:(NSString *)gameName gameDesc:(NSString *)gameDesc gameImg:(NSString *)imgUrl
{
    self.gameNameLabel.text = [@"游戏名称：" stringByAppendingString:gameName];
    self.gameDescLabel.text = [@"游戏描述：" stringByAppendingString:gameDesc];
    [self.gameImageView sd_setImageWithURL:[NSURL URLWithString:imgUrl]];
}

@end
