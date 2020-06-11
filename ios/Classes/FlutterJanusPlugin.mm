#import "FlutterJanusPlugin.h"

@implementation FlutterJanusPlugin{
    FlutterMethodChannel *_methodChannel;
    FlutterEventChannel *_eventChannel;
    id _registry;
    id _messenger;
}

@synthesize messenger = _messenger;

NSString * const TAG = @"flutter_janus_method_channel";

NSString * const METHOD_CHANNEL = @"flutter_janus_method_channel";
NSString * const EVENT_CHANNEL = @"flutter_janus_event_channel";

NSString * const  METHOD_CONNECT = @"connect";
NSString * const  METHOD_DISCONNECT = @"disconnect";
NSString * const  METHOD_GET_ROOM_LIST = @"getRoomList";
NSString * const  METHOD_JOIN = @"join";
NSString * const  METHOD_LEAVE = @"leave";
NSString * const  METHOD_PUBLISH = @"publish";
NSString * const  METHOD_UNPUBLISH = @"unPublish";
NSString * const  METHOD_SUBSCRIBE = @"subscribe";
NSString * const  METHOD_UNSUBSCRIBE = @"unSubscribe";
NSString * const  METHOD_GET_PARTICIPANTS_LIST = @"getParticipantsList";
NSString * const  METHOD_ON_PEER_ICE_CANDIDATE = @"onPeerIceCandidate";
NSString * const  METHOD_ON_ICE_GATHERING_CHANGE = @"onIceGatheringChange";

NSString * const  EVENT_PUBLISHER_IN = @"publisherIn";
NSString * const  EVENT_PUBLISHER_OUT = @"publisherOut";

NSString * const  EVENT_CREATE_OFFER = @"onCreateOffer";
NSString * const  EVENT_CREATE_ANSWER = @"onCreateAnswer";
NSString * const  EVENT_ADD_ICE_CANDIDATE = @"onAddIceCandidate";
NSString * const  EVENT_SET_LOCAL_DESCRIPTION = @"onSetLocalDescription";
NSString * const  EVENT_SET_REMOTE_DESCRIPTION = @"onSetRemoteDescription";
NSString * const  EVENT_PEER_CLOSE = @"onPeerClose";

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:METHOD_CHANNEL
                                     binaryMessenger:[registrar messenger]];
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:EVENT_CHANNEL
                                         binaryMessenger:[registrar messenger]];
    FlutterJanusPlugin* instance = [[FlutterJanusPlugin alloc] initWithChannel:channel
                                                                  eventChannel:eventChannel
                                                                     registrar:registrar
                                                                     messenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];
}

#pragma mark - Utils
-  (BOOL)isBlankString:(NSString *)aStr {
    if (!aStr) {
        return YES;
    }
    if ([aStr isKindOfClass:[NSNull class]]) {
        return YES;
    }
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [aStr stringByTrimmingCharactersInSet:set];
    if (!trimmedStr.length) {
        return YES;
    }
    return NO;
}

-(void) invokeMethod:(NSString *)action data:(NSDictionary*)data result:(FlutterResult _Nullable)callback{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [_methodChannel invokeMethod:action arguments:data result:callback];
    });
}

-(void) sendEventSucces:(NSDictionary*)data{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.eventSink(data);
    });
}

-(void) sendEventError:(NSString *)errorMsg detail:(NSDictionary*)detail{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.eventSink([FlutterError errorWithCode:@"500" message: errorMsg details: detail]);
    });
}

#pragma mark - InitWithChannel
- (instancetype)initWithChannel:(FlutterMethodChannel *)channel
                   eventChannel:(FlutterEventChannel *)eventChannel
                      registrar:(NSObject<FlutterPluginRegistrar>*)registrar
                      messenger:(NSObject<FlutterBinaryMessenger>*)messenger{
    
    self = [super init];
    
    if (self) {
        _methodChannel = channel;
        _eventChannel = eventChannel;
        _registry = registrar;
    }
    
    [eventChannel setStreamHandler:self];
    
    self.janusProtocolMap = [NSMutableDictionary new];
    
    return self;
}

#pragma mark - FlutterStreamHandler
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)eventSink{
    _eventSink = eventSink;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.eventSink = nil;
    return nil;
}

#pragma mark - HandleMethodCall
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"%s:%d obj=: %@", __func__, __LINE__, call.method);
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if([METHOD_CONNECT isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSString *host = [args objectForKey:@"host"];
        [self initJanus:result host:host];
    } else if([METHOD_DISCONNECT isEqualToString:call.method]){
        [self unInitJanus:result];
    } else if([METHOD_GET_ROOM_LIST isEqualToString:call.method]){
        [self getRoomList:result];
    } else if([METHOD_JOIN isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSString *roomId = [args objectForKey:@"roomId"];
        NSString *peerId = [args objectForKey:@"id"];
        [self joinRoom:result roomId:roomId userId:peerId];
    } else if([METHOD_LEAVE isEqualToString:call.method]){
        [self leaveRoom:result];
    } else if([METHOD_PUBLISH isEqualToString:call.method]){
        [self publish:result];
    } else if([METHOD_UNPUBLISH isEqualToString:call.method]){
        [self unPublish:result];
    } else if([METHOD_SUBSCRIBE isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSString *roomId = [args objectForKey:@"roomId"];
        NSString *publisherId = [args objectForKey:@"publisherId"];
        [self subscribe:result roomId:roomId publisherId:publisherId];
    } else if([METHOD_UNSUBSCRIBE isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSString *publisherId = [args objectForKey:@"publisherId"];
        [self unSubscribe:result publisherId: publisherId];
    } else if([METHOD_GET_PARTICIPANTS_LIST isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        NSString *roomId = [args objectForKey:@"roomId"];
        [self getParticipantsList:result roomId:roomId];
    } else if([METHOD_ON_PEER_ICE_CANDIDATE isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        long long peerId = [[args objectForKey:@"id"] longLongValue];
        NSString *sdpMid = [args objectForKey:@"sdpMid"];
        int sdpMLineIndex = [[args objectForKey:@"sdpMLineIndex"] intValue];
        NSString *sdp = [args objectForKey:@"sdp"];
        [self onPeerIceCandidate:peerId sdpMid:sdpMid sdpMLineIndex:sdpMLineIndex sdp:sdp];
    } else if([METHOD_ON_ICE_GATHERING_CHANGE isEqualToString:call.method]){
        NSDictionary *args = call.arguments;
        long long peerId = [[args objectForKey:@"id"] longLongValue];
        NSString *status = [args objectForKey:@"status"];
        [self onIceGatheringChange:peerId sdpMid:status];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initJanus:(FlutterResult)result host:(nullable NSString *)host{
    if ([self isBlankString:host]) {
        NSString * error = @"initJanus(): host is null or blank";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"initJanus" message: error details: nil]);
        return;
    }
    
    JanusConfImpl *conf = [JanusConfImpl new];
    [conf setPlugin:JanusJanusPluginsVIDEOROOM];
    [conf setUrl:host];
    
    self.janusService = [JanusService new];
    [self.janusService init:conf peerDelegate: self serviceDelegate: self];
    [self.janusService start];
    result(@"");
}

- (void)unInitJanus:(FlutterResult)result{
    if (self.janusService == nil) {
        NSString * error = @"unInitJanus(): janus not init";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"unInitJanus" message: error details: nil]);
        return;
    }
    [self.janusService stop];
    self.janusService = nil;
    result(@"");
}

- (void)getRoomList:(FlutterResult)result{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"getRoomList(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"getRoomList" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [self.janusService dispatch:JanusJanusCommandsLIST payload:bundle];
    result(@"");
}

- (void)joinRoom:(FlutterResult)result roomId:(nullable NSString *)roomId userId:(nullable NSString *)userId{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"joinRoom(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"joinRoom" message: error details: nil]);
        return;
    }
    if ([self isBlankString:roomId]) {
        NSString * error = @"joinRoom(): roomId is null or blank";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"joinRoom" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [bundle setString:@"room" value:roomId];
    [bundle setString:@"id" value:userId];
    [bundle setString:@"display" value:userId];
    [self.janusService dispatch:JanusJanusCommandsJOIN payload:bundle];
    result(@"");
}

- (void)leaveRoom:(FlutterResult)result{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"leaveRoom(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"leaveRoom" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [self.janusService dispatch:JanusJanusCommandsLEAVE payload:bundle];
    result(@"");
}

- (void)publish:(FlutterResult)result{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"publish(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"publish" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [bundle setBool:@"audio" value:true];
    [bundle setBool:@"video" value:true];
    [bundle setBool:@"data" value:true];
    [self.janusService dispatch:JanusJanusCommandsPUBLISH payload:bundle];
    result(@"");
}

- (void)unPublish:(FlutterResult)result{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"unPublish(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"unPublish" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [self.janusService dispatch:JanusJanusCommandsUNPUBLISH payload:bundle];
    result(@"");
}

- (void)subscribe:(FlutterResult)result roomId:(nullable NSString *)roomId publisherId:(nullable NSString *)publisherId{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"subscribe(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"subscribe" message: error details: nil]);
        return;
    }
    if ([self isBlankString:roomId]) {
        NSString * error = @"subscribe(): roomId is null or blank";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"subscribe" message: error details: nil]);
        return;
    }
    if ([self isBlankString:publisherId]) {
        NSString * error = @"subscribe(): publisherId is null or blank";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"subscribe" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [bundle setString:@"room" value:roomId];
    [bundle setString:@"feed" value:publisherId];
    [self.janusService dispatch:JanusJanusCommandsSUBSCRIBE payload:bundle];
    result(@"");
}

- (void)unSubscribe:(FlutterResult)result publisherId:(nullable NSString *)publisherId{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"unSubscribe(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"unSubscribe" message: error details: nil]);
        return;
    }
    if ([self isBlankString:publisherId]) {
        NSString * error = @"unSubscribe(): publisherId is null or blank";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"unSubscribe" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [bundle setString:@"feed" value:publisherId];
    [self.janusService dispatch:JanusJanusCommandsUNSUBSCRIBE payload:bundle];
    result(@"");
}

- (void)getParticipantsList:(FlutterResult)result roomId:(nullable NSString *)roomId{
    if (self.janusService == nil || [self.janusService getStatus] != 1) {
        NSString * error = @"getParticipantsList(): janus not ready";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"getParticipantsList" message: error details: nil]);
        return;
    }
    if ([self isBlankString:roomId]) {
        NSString * error = @"getParticipantsList(): roomId is null or blank";
        NSLog(@"%s:%d obj=%@", __func__, __LINE__, error);
        //        OKPrint("\(SwiftFlutterJanusPlugin.TAG): \(error)");
        result([FlutterError errorWithCode:@"getParticipantsList" message: error details: nil]);
        return;
    }
    JanusBundle *bundle = [JanusBundle create];
    [bundle setString:@"room" value:roomId];
    [self.janusService dispatch:JanusJanusCommandsLISTPARTICIPANTS payload:bundle];
    result(@"");
}

- (void)onPeerIceCandidate:(long long)peerId sdpMid:(NSString *)sdpMid sdpMLineIndex:(int)sdpMLineIndex sdp:(NSString *)sdp{
    NSNumber *realId = [NSNumber numberWithLongLong:peerId];
    id<JanusProtocol> owner = [self.janusProtocolMap objectForKey:realId];
    if(owner != nil){
        [owner onIceCandidate:sdpMid index:sdpMLineIndex sdp:sdp id:peerId];
    }
}

- (void)onIceGatheringChange:(long long)peerId sdpMid:(NSString *)status{
    NSNumber *realId = [NSNumber numberWithLongLong:peerId];
    id<JanusProtocol> owner = [self.janusProtocolMap objectForKey:realId];
    if(owner != nil && [status isEqualToString:@"completed"]){
        [owner onIceCompleted:peerId];
    }
}

#pragma mark - JanusServiceDelegate

- (void)onJanusReady {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onJanusReady");
    [self sendEventSucces:@{
        @"action":METHOD_CONNECT,
        @"event":@"onJanusReady",
    }];
}

- (void)onJanusClose {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onJanusClose");
    [self sendEventSucces:@{
        @"action":METHOD_CONNECT,
        @"event":@"onJanusClose",
    }];
}

- (void)onJanusHangup:(NSString * _Nullable)reason {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onJanusHangup");
    [self sendEventSucces:@{
        @"action":METHOD_CONNECT,
        @"event":@"onJanusHangup",
        @"reason":reason,
    }];
}

- (void)onJanusError:(nonnull JanusJanusError *)error bundle:(nullable JanusBundle *)payload {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onJanusError");
    NSString* errorType =[payload getString:@"common" fallback:@""];
    if([errorType isEqualToString:JanusJanusCommandsLIST]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_GET_ROOM_LIST,
            @"error":[error message],
        }];
    } else if([errorType isEqualToString:JanusJanusCommandsJOIN]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_JOIN,
            @"error":[error message],
        }];
    } else if([errorType isEqualToString:JanusJanusCommandsLEAVE]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_LEAVE,
            @"error":[error message],
        }];
    } else if([errorType isEqualToString:JanusJanusCommandsPUBLISH]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_PUBLISH,
            @"error":[error message],
        }];
    } else if([errorType isEqualToString:JanusJanusCommandsUNPUBLISH]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_UNPUBLISH,
            @"error":[error message],
        }];
    } else if([errorType isEqualToString:JanusJanusCommandsSUBSCRIBE]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_SUBSCRIBE,
            @"error":[error message],
        }];
    } else if([errorType isEqualToString:JanusJanusCommandsUNSUBSCRIBE]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_UNSUBSCRIBE,
            @"error":[error message],
        }];
    } else if([errorType isEqualToString:JanusJanusCommandsLISTPARTICIPANTS]){
        [self sendEventError:@"" detail:@{
            @"action":METHOD_GET_PARTICIPANTS_LIST,
            @"error":[error message],
        }];
    }
}

- (void)onJanusEvent:(nonnull JanusJanusEvent *)event bundle:(nullable JanusBundle *)payload {
    if(event == nil || payload == nil){
        return;
    }
    JanusJanusData *data = [event data];
    NSString* cmd = [payload getString:@"command" fallback:@""];
    NSString* status = [data getString:@"janus" fallback:@""];
    NSLog(@"%s:%d onJanusEvent: data=%@, cmd=%@, status=%@,", __func__, __LINE__, data, cmd, status);
    
    if([status isEqualToString:@"success"] && [cmd isEqualToString:JanusJanusCommandsLIST]){
        NSArray<JanusJanusData*> * list = [[[data getObject:@"plugindata"] getObject:@"data"] getList:@"list"];
        NSMutableArray<NSString*> * roomList = [NSMutableArray new];
        [list enumerateObjectsUsingBlock:^(JanusJanusData* obj, NSUInteger idx, BOOL *stop) {
            [roomList addObject:[obj getString:@"room" fallback:@""]];
        }];
        
        [self sendEventSucces:@{
            @"action":METHOD_GET_ROOM_LIST,
            @"roomList":roomList,
        }];
        return;
    }
    
    if([cmd isEqualToString:JanusJanusCommandsLISTPARTICIPANTS]){
        JanusJanusData *info = [[data getObject:@"plugindata"] getObject:@"data"];
        NSString* roomId = [info getString:@"room" fallback:@""];
        NSArray<JanusJanusData*> * list = [info getList:@"participants"];
        
        NSMutableArray<NSDictionary*> * participantsList = [NSMutableArray new];
        [list enumerateObjectsUsingBlock:^(JanusJanusData* obj, NSUInteger idx, BOOL *stop) {
            [participantsList addObject:@{
                @"id":[obj getString:@"id" fallback:@""],
                @"name":[obj getString:@"display" fallback:@""],
            }];
        }];
        
        [self sendEventSucces:@{
            @"action":METHOD_GET_PARTICIPANTS_LIST,
            @"roomId":roomId,
            @"participantsList":participantsList,
        }];
        return;
    }
    
    if([cmd isEqualToString:JanusJanusCommandsLEAVE]){
        [self sendEventSucces:@{
            @"action":METHOD_LEAVE,
        }];
        return;
    }
    
    NSString* room = [data getString:@"room" fallback:@""];
    NSString* roomValue = [data getString:@"videoroom" fallback:@""];
    
    if([roomValue isEqualToString:@"joined"]){
        [self sendEventSucces:@{
            @"action":METHOD_JOIN,
            @"roomId":room,
        }];
    }
    
    NSArray<JanusJanusData*> * publishers = [data getList:@"publishers"];
    if([publishers count] > 0 && ![self isBlankString:room]){
        NSMutableArray<NSDictionary*> * publisherList = [NSMutableArray new];
        [publishers enumerateObjectsUsingBlock:^(JanusJanusData* obj, NSUInteger idx, BOOL *stop) {
            [publisherList addObject:@{
                @"id":[obj getString:@"id" fallback:@""],
                @"name":[obj getString:@"display" fallback:@""],
            }];
        }];
        [self sendEventSucces:@{
            @"action":EVENT_PUBLISHER_IN,
            @"roomId":room,
            @"publisherList":publisherList,
        }];
        return;
    }
    
    NSString* unPublisher = [data getString:@"unpublished" fallback:@""];
    if(![self isBlankString:unPublisher]){
        [self sendEventSucces:@{
            @"action":EVENT_PUBLISHER_OUT,
            @"roomId":room,
            @"publisherList":unPublisher,
        }];
        return;
    }
}

#pragma mark - JanusPeerDelegate
- (void)onInitProtocol:(nonnull NSNumber *)peerId publisherId:(nullable NSString *)publisherId owner:(id<JanusProtocol> _Nullable)owner {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onInitProtocol");
    [self.janusProtocolMap setObject:owner forKey:peerId];
}

- (void)onCreateAnswer:(nonnull NSNumber *)peerId publisherId:(nullable NSString *)publisherId constraints:(nullable JanusConstraints *)constraints bundle:(nullable JanusBundle *)bundle {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onCreateAnswer");
    [self invokeMethod:EVENT_CREATE_ANSWER data:@{
        @"id": peerId,
        @"publisherId": publisherId,
        @"constraints": constraints,
        @"sdpConstraints": constraints.sdp,
        @"videoConstraints": constraints.video,
        @"sendVideo":[NSNumber numberWithBool:constraints.sdp.sendVideo],
        @"sendAudio": [NSNumber numberWithBool:constraints.sdp.sendAudio],
        @"receiveVideo": [NSNumber numberWithBool:constraints.sdp.receiveVideo],
        @"receiveAudio": [NSNumber numberWithBool:constraints.sdp.receiveAudio],
        @"dataChannel": [NSNumber numberWithBool:constraints.sdp.datachannel],
        @"width": [NSNumber numberWithInt:constraints.video.width],
        @"height": [NSNumber numberWithInt:constraints.video.height],
        @"fps": [NSNumber numberWithInt:constraints.video.fps],
        @"camera": constraints.video.camera,
    } result:^(id  _Nullable result) {
        if([result isKindOfClass:[FlutterError class]]){
            //        NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onCreateAnswerError");
        } else if([result isKindOfClass:[FlutterMethodNotImplemented class]]){
            
        } else if(result!=nil){
            //        NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onCreateAnswerSuccess");
            NSDictionary *args = result;
            long long pId = [[args objectForKey:@"id"] longLongValue];
            NSString *sdp = [args objectForKey:@"sdp"];
            
            NSNumber *realId = [NSNumber numberWithLongLong:pId];
            id<JanusProtocol> owner = [self.janusProtocolMap objectForKey:realId];
            if(owner != nil){
                [owner onAnswer:sdp context:bundle];
            }
        }
    }];
}

- (void)onCreateOffer:(nonnull NSNumber *)peerId publisherId:(nullable NSString *)publisherId constraints:(nullable JanusConstraints *)constraints bundle:(nullable JanusBundle *)bundle {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onCreateOffer");
    [self invokeMethod:EVENT_CREATE_OFFER data:@{
        @"id": peerId,
        @"publisherId": publisherId,
        @"constraints": constraints,
        @"sdpConstraints": constraints.sdp,
        @"videoConstraints": constraints.video,
        @"sendVideo":[NSNumber numberWithBool:constraints.sdp.sendVideo],
        @"sendAudio": [NSNumber numberWithBool:constraints.sdp.sendAudio],
        @"receiveVideo": [NSNumber numberWithBool:constraints.sdp.receiveVideo],
        @"receiveAudio": [NSNumber numberWithBool:constraints.sdp.receiveAudio],
        @"dataChannel": [NSNumber numberWithBool:constraints.sdp.datachannel],
        @"width": [NSNumber numberWithInt:constraints.video.width],
        @"height": [NSNumber numberWithInt:constraints.video.height],
        @"fps": [NSNumber numberWithInt:constraints.video.fps],
        @"camera": constraints.video.camera,
    } result:^(id  _Nullable result) {
        if([result isKindOfClass:[FlutterError class]]){
            NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onCreateOfferError");
        } else if([result isKindOfClass:[FlutterMethodNotImplemented class]]){
            
        } else if(result!=nil){
            NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onCreateOfferSuccess");
            NSDictionary *args = result;
            long long pId = [[args objectForKey:@"id"] longLongValue];
            NSString *sdp = [args objectForKey:@"sdp"];
            
            NSNumber *realId = [NSNumber numberWithLongLong:pId];
            id<JanusProtocol> owner = [self.janusProtocolMap objectForKey:realId];
            if(owner != nil){
                [owner onOffer:sdp context:bundle];
            }
        }
    }];
}

- (void)onAddIceCandidate:(nonnull NSNumber *)peerId publisherId:(nullable NSString *)publisherId mid:(nullable NSString *)mid index:(nullable NSNumber *)index sdp:(nullable NSString *)sdp {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onAddIceCandidate");
    [self invokeMethod:EVENT_ADD_ICE_CANDIDATE data:@{
        @"id": peerId,
        @"publisherId": publisherId,
        @"mid": mid,
        @"index": index,
        @"sdp": sdp,
    } result:nil];
}

- (void)onSetLocalDescription:(nonnull NSNumber *)peerId publisherId:(nullable NSString *)publisherId type:(JanusSdpType)type sdp:(nullable NSString *)sdp {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onSetLocalDescription");
    [self invokeMethod:EVENT_SET_LOCAL_DESCRIPTION data:@{
        @"id": peerId,
        @"publisherId": publisherId,
        @"isOffer": [NSNumber numberWithBool:type==JanusSdpTypeOFFER],
        @"sdp": sdp,
    } result:nil];
}

- (void)onSetRemoteDescription:(nonnull NSNumber *)peerId publisherId:(nullable NSString *)publisherId type:(JanusSdpType)type sdp:(nullable NSString *)sdp {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onSetRemoteDescription");
    [self invokeMethod:EVENT_SET_REMOTE_DESCRIPTION data:@{
        @"id": peerId,
        @"publisherId": publisherId,
        @"isOffer": [NSNumber numberWithBool:type==JanusSdpTypeOFFER],
        @"sdp": sdp,
    } result:nil];
}

- (void)onPeerClose:(nonnull NSNumber *)peerId publisherId:(nullable NSString *)publisherId {
    NSLog(@"%s:%d obj=%@", __func__, __LINE__, @"onPeerClose");
    [self invokeMethod:EVENT_SET_LOCAL_DESCRIPTION data:@{
        @"id": peerId,
        @"publisherId": publisherId,
    } result:nil];
}

@end
