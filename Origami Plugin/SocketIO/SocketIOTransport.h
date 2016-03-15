//
//  SocketIOTransport.h
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

@protocol SocketIOTransportDelegate <NSObject>

- (void) onData:(id)message;
- (void) onDisconnect:(NSError*)error;
- (void) onError:(NSError*)error;

@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSInteger port;
@property (nonatomic, readonly) NSString *sid;
@property (nonatomic, readonly) NSTimeInterval heartbeatTimeout;
@property (nonatomic) BOOL useSecure;

@end

@protocol SocketIOTransport <NSObject>

- (id) initWithDelegate:(id <SocketIOTransportDelegate>)delegate;
- (void) open;
- (void) close;
- (BOOL) isReady;
- (void) send:(NSString *)request;

@property (nonatomic, unsafe_unretained) id <SocketIOTransportDelegate> delegate;

@end
