#import "GameMessage.h"

@interface GameMessage ()

@property (nonatomic, strong) NSAttributedString *message;

@end

@implementation GameMessage

- (instancetype)initWithAttributedMessage:(NSAttributedString *)message {
    self = [super init];
    if (self) {
        self.message = message;
    }
    return self;
}

/// 富文本消息体
- (NSAttributedString *)attributeString {
    return self.message;
}

@end
