//
//  SocketIOTransportWebsocket.h
//  v0.4 ARC
//
//  based on
//  socketio-cocoa https://github.com/fpotter/socketio-cocoa
//  by Fred Potter <fpotter@pieceable.com>
//
//  using
//  https://github.com/square/SocketRocket
//  https://github.com/stig/json-framework/
//
//  reusing some parts of
//  /socket.io/socket.io.js
//
//  Created by Philipp Kyeck http://beta-interactive.de
//
//  Updated by
//    samlown   https://github.com/samlown
//    kayleg    https://github.com/kayleg
//    taiyangc  https://github.com/taiyangc
//

#import <Foundation/Foundation.h>

#import "SRWebSocket.h"
#import "SocketIOTransport.h"

@interface SocketIOTransportWebsocket : NSObject <SocketIOTransport, SRWebSocketDelegate>
{
    SRWebSocket *_webSocket;
}

@property (nonatomic, unsafe_unretained) id <SocketIOTransportDelegate> delegate;

@end
