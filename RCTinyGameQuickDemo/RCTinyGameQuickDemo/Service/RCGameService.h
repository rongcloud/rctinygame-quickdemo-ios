#import <YYModel/YYModel.h>
#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

typedef NS_ENUM(NSUInteger, StatusCode) {
    StatusCodeSuccess = 10000,
};

 
typedef NS_ENUM(NSUInteger, RoomType) {
    RoomTypeVoice = 1,
    RoomTypeRadio,
    RoomTypeVideo,
};

typedef void(^SuccessCompletion)(id _Nullable responseObject);
typedef void(^FailureCompletion)(NSError * _Nonnull error);


NS_ASSUME_NONNULL_BEGIN

@interface RCGameService : AFHTTPSessionManager

@property (nonatomic, copy, class) NSString *rcBusinessToken;
@property (nonatomic, copy, class) NSString *rcBaseUrl;
@property (nonatomic, copy, class) NSString *authorization;

/// 获取实例
+ (instancetype)shareInstance;

/// 登录
/// @param number 电话号码
/// @param verifyCode 验证码   //测试环境验证码可以输入任意值
/// @param deviceId  设备ID UUIDString
/// @param userName 昵称
/// @param portrait 头像
/// @param success 成功回调
/// @param failure 失败回调
+ (void)loginWithPhoneNumber:(NSString *)number
                  verifyCode:(NSString *)verifyCode
                    deviceId:(NSString *)deviceId
                    userName:(nullable NSString *)userName
                    portrait:(nullable NSString *)portrait
               responseClass:(nullable Class)responseClass
                     success:(nullable SuccessCompletion)success
                     failure:(nullable FailureCompletion)failure;


+ (void)loginGameWithUserId:(NSString *)userId
              responseClass:(nullable Class)responseClass
                    success:(nullable SuccessCompletion)success
                    failure:(nullable FailureCompletion)failure;

+ (void)getGameList:(nullable Class)responseClass
            success:(nullable SuccessCompletion)success
            failure:(nullable FailureCompletion)failure;


+ (void)gameReportAppId:(NSString *)appId
                 gameId:(NSString *)gameId
                 userId:(NSString *)userId
                 isTestEnv:(BOOL)isTestEnv;


/// 创建房间列表
/// @param name 房间名
/// @param isPrivate  是否是私密房间  0 否  1 是
/// @param backgroundUrl 背景图片
/// @param themePictureUrl 主题照片
/// @param password  私密房间密码MD5
/// @param type  房间类型  1.语聊 2.电台  3.直播
/// @param kv  保留值，可缺省传空
/// @param success 成功回调
/// @param failure 失败回调
+ (void)createRoomWithName:(NSString *)name
                 isPrivate:(NSInteger)isPrivate
             backgroundUrl:(NSString *)backgroundUrl
           themePictureUrl:(NSString *)themePictureUrl
                  password:(NSString *)password
                      type:(NSInteger)type
                        kv:(NSArray <NSDictionary *>*)kv
             responseClass:(nullable Class)responseClass
                   success:(nullable SuccessCompletion)success
                   failure:(nullable FailureCompletion)failure;


/// 删除房间
/// @param roomId 房间ID
/// @param success 成功回调
/// @param failure 失败回调
+ (void)deleteRoomWithRoomId:(NSString *)roomId
                     success:(nullable SuccessCompletion)success
                     failure:(nullable FailureCompletion)failure;



/// 更新房间在线状态
/// @param roomId 房间ID
+ (void)updateOnlineRoomStatusWithRoomId:(NSString *)roomId
                           responseClass:(nullable Class)responseClass
                                 success:(nullable SuccessCompletion)success
                                 failure:(nullable FailureCompletion)failure;
@end

NS_ASSUME_NONNULL_END
