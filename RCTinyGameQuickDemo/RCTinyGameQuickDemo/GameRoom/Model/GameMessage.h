#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GameMessage : NSObject <RCChatroomSceneMessageProtocol>

- (instancetype)initWithAttributedMessage:(NSAttributedString *)message;

@end

NS_ASSUME_NONNULL_END
