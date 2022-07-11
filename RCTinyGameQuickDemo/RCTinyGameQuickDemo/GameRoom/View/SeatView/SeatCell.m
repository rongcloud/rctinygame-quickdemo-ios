
#import "SeatCell.h"
#import "UIImageView+AFNetworking.h"

@implementation SeatModel

- (NSString *)description {
    return [NSString stringWithFormat:@"userId: %@ isCaptain:%d gameState:%zd", self.seatInfo.userId, self.isCaptain, self.gameState];
}
@end

@interface SeatCell ()
@property (nonatomic, strong) UILabel     * nameLabel;
@property (nonatomic, strong) UIImageView * headImageView;
@property (nonatomic, strong) UILabel     * stateLabel;
@property (nonatomic, strong) UIImageView * gamingImageView;
@property (nonatomic, strong) UIImageView * captainView;
@property (nonatomic, strong) UIView      * placeHolderView;
@end

@implementation SeatCell

- (void)setUpUI {
    if (self.headImageView.superview == nil) {
        [self addSubview:self.headImageView];
        [self.headImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(12);
            make.left.right.equalTo(self);
            make.height.mas_equalTo(@40);
        }];
        NSString * url = [NSString stringWithFormat:@"https://dev-sud-static.sudden.ltd/avatar/%d.jpg", 1];
        [self.headImageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil];
    }
    
    if (self.placeHolderView.superview == nil) {
        [self addSubview:self.placeHolderView];
        [self.placeHolderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(12);
            make.left.right.equalTo(self);
            make.height.mas_equalTo(@40);
        }];
    }
    
    if (self.stateLabel.superview == nil) {
        [self addSubview:self.stateLabel];
        [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self.headImageView.mas_bottom);
            make.width.equalTo(@43);
            make.height.equalTo(@14);
        }];
    }
    
    if (self.gamingImageView.superview == nil) {
        [self addSubview:self.gamingImageView];
        [self.gamingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self.headImageView.mas_bottom);
            make.width.equalTo(@32);
            make.height.equalTo(@32);
        }];
    }
    if (self.nameLabel.superview == nil) {
        [self addSubview:self.nameLabel];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.equalTo(self.stateLabel.mas_bottom).offset(-1.5);
            make.height.equalTo(@14);
            make.width.equalTo(@60);
        }];
    }
    
    if (self.captainView.superview == nil) {
        [self addSubview:self.captainView];
        [self.captainView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.headImageView.mas_top).offset(15);
            make.right.equalTo(self.headImageView.mas_left).offset(13);
            make.height.equalTo(@20);
            make.width.equalTo(@18);
        }];
    }
}

- (void)reload {
    [self setUpUI];
    [self refreshUI];
}

- (int)getHashCode:(NSString *)string {
    int hash = 0;
    for (int i = 0; i < string.length; i++) {
        NSString *s = [string substringWithRange:NSMakeRange(i, 1)];
        char *unicode = (char *)[s cStringUsingEncoding:NSUTF8StringEncoding];
        int charactorUnicode = 0;
        size_t length = strlen(unicode);
        for (int n = 0; n < length; n ++) {
            charactorUnicode += (int)((unicode[n] & 0xff) << (n * sizeof(char) * 8));
        }
        hash = hash * 31 + charactorUnicode;
    }
    return hash;
}

- (void)refreshUI {
    if (self.seatModel.seatInfo.userId == nil) {
        self.captainView.alpha = 0;
        self.gamingImageView.alpha = 0;
        self.nameLabel.alpha = 0;
        self.stateLabel.alpha = 0;
        self.headImageView.alpha = 0;
        self.placeHolderView.alpha = 1;
        return;
    }
    
    self.nameLabel.alpha = 1;
    self.headImageView.alpha = 1;
    self.placeHolderView.alpha = 0;
    
    /// 设置队长状态
    if (self.seatModel.isCaptain) {
        self.captainView.alpha = 1;
    } else {
        self.captainView.alpha = 0;
    }
    
    /// 如果在游戏中，先优先游戏中状态
    if (self.seatModel.gameState == GameState_Playing) {
        self.gamingImageView.alpha = 1;
    } else {
        self.gamingImageView.alpha = 0;
    }
    
    self.nameLabel.text = self.seatModel.seatInfo.userId;
    
    if (self.seatModel.gameState == GameState_unJoin) {
        self.stateLabel.alpha = 0;
    } else {
        self.stateLabel.alpha = 1;
    }
    
    if (self.seatModel.gameState == GameState_unPrepare) {
        self.stateLabel.backgroundColor = [UIColor colorWithRed:250/255. green:65/255. blue:30/255. alpha:1.0];
        self.stateLabel.text = @"未准备";
    } else if (self.seatModel.gameState == GameState_prepared) {
        self.stateLabel.backgroundColor = [UIColor colorWithRed:0/255. green:200/255. blue:80/255. alpha:1.0];
        self.stateLabel.text = @"已准备";
    }else if (self.seatModel.gameState == GameState_painting) {
        self.stateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        self.stateLabel.text = @"绘画中";
    } else if (self.seatModel.gameState == GameState_selecting) {
        self.stateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        self.stateLabel.text = @"选词中";
    }
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}

- (UIImageView *)headImageView {
    if (!_headImageView) {
        _headImageView = [[UIImageView alloc]init];
        _headImageView.layer.cornerRadius = 20;
        _headImageView.clipsToBounds = YES;
    }
    return _headImageView;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc]init];
        _stateLabel.layer.cornerRadius = 7;
        _stateLabel.layer.borderWidth = 1;
        _stateLabel.layer.masksToBounds = YES;
        _stateLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightMedium];
        _stateLabel.textColor = [UIColor whiteColor];
    }
    return _stateLabel;
}

- (UIImageView *)gamingImageView {
    if (!_gamingImageView) {
        _gamingImageView = [[UIImageView alloc]init];
        _gamingImageView.image = [UIImage imageNamed:@"playing"];
    }
    return _gamingImageView;
}

- (UIImageView *)captainView {
    if (!_captainView) {
        _captainView = [[UIImageView alloc]init];
        _captainView.image = [UIImage imageNamed:@"captain"];
    }
    return _captainView;
}

- (UIView *)placeHolderView {
    if (!_placeHolderView) {
        _placeHolderView = [[UIView alloc]init];
        _placeHolderView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
        _placeHolderView.layer.cornerRadius = 20;
        _placeHolderView.layer.masksToBounds = YES;
        _placeHolderView.layer.borderWidth = 1;
        _placeHolderView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2].CGColor;
        UIView * vline = [[UIView alloc]init];
        vline.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        UIView * hline = [[UIView alloc]init];
        hline.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        [_placeHolderView addSubview:vline];
        [_placeHolderView addSubview:hline];
        [vline mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@1.48);
            make.height.equalTo(@14.8);
            make.center.equalTo(_placeHolderView);
        }];
        [hline mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@1.48);
            make.width.equalTo(@14.8);
            make.center.equalTo(_placeHolderView);
        }];
    }
    return _placeHolderView;
}

@end
