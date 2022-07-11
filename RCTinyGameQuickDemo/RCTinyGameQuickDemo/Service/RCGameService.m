#import "RCGameService.h"
#import <CommonCrypto/CommonDigest.h>

static NSString * _rcBusinessToken = nil;
static NSString * _rcBaseUrl = nil;
static NSString * _authorization = nil;

//登录
static NSString *const np_login = @"user/login";

//游戏SDK 登陆
static NSString *const mic_game_login = @"/mic/game/login";

//游戏列表
static NSString *const mic_game_list = @"/mic/game/list";

//游戏数据上报
static NSString *const mic_game_report = @"/mic/game/report";

//创建房间
static NSString *const np_room_creat = @"mic/room/create";

//删除房间
static NSString *const np_room_delete = @"mic/room/%@/delete";

//同步房间在线状态
static NSString *const np_update_room_online_status = @"user/change";

static inline void _responseHandler(Class responseClase, NSDictionary *responseObject, SuccessCompletion success) {
    if (responseClase == nil) {
        success(responseObject);
    } else {
        id resobj = [responseClase yy_modelWithDictionary:responseObject];
        success(resobj);
    }
}

@implementation RCGameService

+ (instancetype)shareInstance {
    static dispatch_once_t once;
    static id shareInstance;
    dispatch_once(&once, ^{
        shareInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:RCGameService.rcBaseUrl]];
        [shareInstance setRequestSerializer:[AFJSONRequestSerializer serializer]];
    });
    return shareInstance;
}

+ (void)loginWithPhoneNumber:(NSString *)number
                  verifyCode:(NSString *)verifyCode
                    deviceId:(NSString *)deviceId
                    userName:(nullable NSString *)userName
                    portrait:(nullable NSString *)portrait
               responseClass:(nullable Class)responseClass
                     success:(nullable SuccessCompletion)success
                     failure:(nullable FailureCompletion)failure {
    
    NSMutableDictionary *param = [@{
        @"mobile":number,
        @"verifyCode":verifyCode,
        @"deviceId":deviceId,
    } mutableCopy];
    
    if (userName != nil && userName.length > 0) {
        param[@"userName"] = userName;
    }
    
    if (portrait != nil && portrait.length > 0) {
        param[@"portrait"] = portrait;
    }
    
    [[self shareInstance] POST:np_login parameters:param auth:NO responseClass:responseClass success:success failure:failure];
}


+ (void)getGameList:(nullable Class)responseClass
            success:(nullable SuccessCompletion)success
            failure:(nullable FailureCompletion)failure {

    [[self shareInstance] GET:mic_game_list parameters:nil auth:NO responseClass:responseClass success:success failure:failure];
}


+ (void)loginGameWithUserId:(NSString *)userId
               responseClass:(nullable Class)responseClass
                     success:(nullable SuccessCompletion)success
                     failure:(nullable FailureCompletion)failure {
    NSMutableDictionary *param = [@{ @"userId":userId } mutableCopy];
    [[self shareInstance] POST:mic_game_login parameters:param auth:NO responseClass:responseClass success:success failure:failure];
}


//sha1加密方式
+ (NSString *)sha1:(NSString *)input {
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for(int i=0; i<CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (NSString *)currentTimeStamp {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a = [date timeIntervalSince1970];
    return [NSString stringWithFormat:@"%0.f", a];
}



+ (void)gameReportAppId:(NSString *)appId
                 gameId:(NSString *)gameId
                 userId:(NSString *)userId
              isTestEnv:(BOOL)isTestEnv {
    NSString *key = @"eyJhbGciOiJIUzI1NiJ9";
    NSString *timeStamp = [self currentTimeStamp];
    NSString *nonce = [timeStamp substringFromIndex:timeStamp.length - 6];
    NSString *signature = [NSString stringWithFormat:@"%@%@%@",key,nonce,timeStamp];
    signature = [self sha1:signature];
    
    NSString *url = [NSString stringWithFormat:@"%@?nonce=%@&signTimestamp=%@&signature=%@",mic_game_report,nonce,timeStamp,signature];
    
    NSMutableDictionary *param = [@{@"appId":appId,
                                    @"gameId":gameId,
                                    @"userId":userId,
                                    @"gameId":gameId,
                                  } mutableCopy];
    [[self shareInstance] POST:url parameters:param auth:NO responseClass:nil success:^(id  _Nullable responseObject) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

+ (void)createRoomWithName:(NSString *)name
                 isPrivate:(NSInteger)isPrivate
             backgroundUrl:(NSString *)backgroundUrl
           themePictureUrl:(NSString *)themePictureUrl
                  password:(NSString *)password
                      type:(NSInteger)type
                        kv:(NSArray <NSDictionary *>*)kv
             responseClass:(nullable Class)responseClass
                   success:(nullable SuccessCompletion)success
                   failure:(nullable FailureCompletion)failure {
    NSDictionary *param = @{
        @"name":name,
        @"isPrivate":@(isPrivate),
        @"backgroundUrl":backgroundUrl,
        @"themePictureUrl":themePictureUrl,
        @"roomType":@(type),
        @"password":password,
        @"kv":kv,
    };
    
    [[self shareInstance] POST:np_room_creat parameters:param auth:YES responseClass:responseClass success:success failure:failure];
    
}

+ (void)deleteRoomWithRoomId:(NSString *)roomId
                     success:(nullable SuccessCompletion)success
                     failure:(nullable FailureCompletion)failure {
    [[self shareInstance] GET:[NSString stringWithFormat:np_room_delete,roomId] parameters:nil auth:YES responseClass:nil success:success failure:failure];
}


+ (void)updateOnlineRoomStatusWithRoomId:(NSString *)roomId
                           responseClass:(nullable Class)responseClass
                                 success:(nullable SuccessCompletion)success
                                 failure:(nullable FailureCompletion)failure {
    [[self shareInstance] GET:np_update_room_online_status parameters:@{@"roomId":roomId} auth:YES responseClass:nil success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable id)parameters
                          auth:(BOOL)auth
                 responseClass:(nullable Class)responseClass
                       success:(nullable SuccessCompletion)success
                       failure:(nullable FailureCompletion)failure {
    
    NSDictionary *header = [self buildHeader:auth];

    return [self POST:URLString parameters:parameters headers:header progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            _responseHandler(responseClass, responseObject, success);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
            NSLog(@"request error \n url = %@ \n error code = %ld \n msg = %@ \n",URLString,(long)error.code,error.description);
        }
    }];
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(nullable id)parameters
                         auth:(BOOL)auth
                responseClass:(nullable Class)responseClass
                      success:(nullable SuccessCompletion)success
                      failure:(nullable FailureCompletion)failure  {
    
    NSDictionary *header = [self buildHeader:auth];
    
    return [self GET:URLString parameters:parameters headers:header progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            _responseHandler(responseClass, responseObject, success);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
            NSLog(@"request error \n url = %@ \n error code = %ld \n msg = %@ \n",URLString,(long)error.code,error.description);
        }
    }];
}

- (NSDictionary *)buildHeader:(BOOL)auth {
    NSString *businessToken = RCGameService.rcBusinessToken;
    if (businessToken == nil || businessToken.length == 0) {
        NSCAssert(NO, @"当前 BusinessToken 不存在或者为空，请前往 https://rcrtc-api.rongcloud.net/code 获取 BusinessToken");
    }

    NSMutableDictionary *header = [NSMutableDictionary dictionary];
    header[@"Content-Type"] = @"application/json;charset=UTF-8";
    header[@"BusinessToken"] = businessToken;
    
    if (auth && RCGameService.authorization.length != 0) {
        header[@"Authorization"] = RCGameService.authorization;
    }

    return header;
}


+ (void)setAuthorization:(NSString *)authorization {
    _authorization = authorization;
}
+ (NSString *)authorization {
    return _authorization;
}

+ (void)setRcBaseUrl:(NSString *)rcBaseUrl {
    _rcBaseUrl = rcBaseUrl;
}
+ (NSString *)rcBaseUrl {
    return _rcBaseUrl;
}

+ (void)setRcBusinessToken:(NSString *)rcBusinessToken {
    _rcBusinessToken = rcBusinessToken;
}
+ (NSString *)rcBusinessToken {
    return _rcBusinessToken;
}
@end
