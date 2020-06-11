//
//  JanusService.m
//  flutter_janus
//
//  Created by YeGuli on 2020/6/8.
//
#import "JanusService.h"

@implementation JanusService

-(void) init:(JanusConfImpl * _Nullable)conf
peerDelegate:(id<JanusPeerDelegate>) pDelegate
serviceDelegate:(id<JanusServiceDelegate>_Nullable) sDelegate{
    status = 0;
    serviceDelegate = sDelegate;
    
    JanusPeerFactoryImpl * factory = [JanusPeerFactoryImpl new];
    JanusPlatform * platform = [JanusPlatform create:factory];
    janus = [JanusJanus create:conf platform:platform delegate:self];
}

-(int) getStatus{
    return status;
}

-(void) start{
    if(janus != nil){
        [janus init];
    }
}

-(void) stop{
    if(janus != nil){
        [janus close];
    }
}

-(void) hangup{
    if(janus != nil){
        [janus hangup];
    }
}

-(void) dispatch:(NSString *)command
         payload:(JanusBundle *)payload{
    if(janus != nil){
        [janus dispatch:command payload:payload];
    }
}

- (void)onClose {
    status = -1;
    if(serviceDelegate!=nil){
        [serviceDelegate onJanusClose];
    }
}

- (void)onError:(nonnull JanusJanusError *)error context:(nullable JanusBundle *)context {
    if(serviceDelegate!=nil){
        [serviceDelegate onJanusError:error bundle:context];
    }
}

- (void)onEvent:(nullable JanusJanusEvent *)event context:(nullable JanusBundle *)context {
    if(serviceDelegate!=nil){
        [serviceDelegate onJanusEvent:event bundle:context];
    }
}

- (void)onHangup:(nonnull NSString *)reason {
    status = 1;
    if(serviceDelegate!=nil){
        [serviceDelegate onJanusHangup:reason];
    }
}

- (void)onReady {
    status = 1;
    if(serviceDelegate!=nil){
        [serviceDelegate onJanusReady];
    }
}

@end
