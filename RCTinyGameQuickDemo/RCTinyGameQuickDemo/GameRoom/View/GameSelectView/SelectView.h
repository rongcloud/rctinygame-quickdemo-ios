
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef void(^selectBtnDidClickedCallback)(RCGameInfo *gameInfo);

@interface SelectView : UIView
/// 选项按钮
- (UIButton *)selectBtn;
/// 已选择内容
@property (nonatomic, readonly) NSString   *selectString;
/// 选择完事件回调
@property (nonatomic, copy) selectBtnDidClickedCallback selectBtnDidClickedCb;
/// 初始化在这里添加选项
- (instancetype)initWithGameInfos:(NSArray *)gameInfos;
/// 隐藏tableview
- (void)hideTableView;
@end

NS_ASSUME_NONNULL_END
