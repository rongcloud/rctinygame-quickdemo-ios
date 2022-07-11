
#ifndef SeatDefine_h
#define SeatDefine_h

typedef NS_ENUM(NSUInteger, GameState) {
    GameState_unJoin = 0,
    GameState_unPrepare,
    GameState_prepared,
    GameState_selecting,
    GameState_painting,
    GameState_Playing,
};


#endif /* SeatDefine_h */
