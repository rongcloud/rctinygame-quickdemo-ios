
#import "UserManager.h"

@interface UserManager ()
@property (nonatomic, strong, readwrite) User *currentUser;
@end

@implementation UserManager

- (instancetype)init {
    if (self = [super init]) {
        self.currentUser = [User currentUser];
    }
    return self;
}

+ (UserManager *)sharedManager {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^
                  {
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (BOOL)isLogin {
    return [self sharedManager].currentUser.token != nil && [self sharedManager].currentUser.token.length > 0;
}


+ (BOOL)isGameEngineLogin {
    return [self sharedManager].currentUser.gameSDKCode != nil && [self sharedManager].currentUser.gameSDKCode.length > 0;
}



+ (NSString *)userId {
    return [self sharedManager].currentUser.userId;
}

+ (NSString *)token {
    return [self sharedManager].currentUser.token;
}

+ (NSString *)userName {
    return [self sharedManager].currentUser.userName;
}

+ (NSString *)authorization {
    return [self sharedManager].currentUser.authorization;
}
@end
