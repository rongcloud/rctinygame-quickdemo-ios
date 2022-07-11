
#import <Foundation/Foundation.h>
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserManager : NSObject

@property (nonatomic, strong, readonly) User *currentUser;

+ (UserManager *)sharedManager;

+ (BOOL)isLogin;
+ (BOOL)isGameEngineLogin;

+ (NSString *)userId;

+ (NSString *)token;

+ (NSString *)userName;

+ (NSString *)authorization;
@end

NS_ASSUME_NONNULL_END
