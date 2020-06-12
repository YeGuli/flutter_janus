//
//  JanusPeerImpl.m
//  testApp
//
//  Created by YeGuli on 2020/6/6.
//  Copyright © 2020 YeGuli. All rights reserved.
//
#import "JanusPeerImpl.h"

@implementation JanusPeerImpl

- (void)setParam:(NSNumber*_Nullable)pId publisherId:(NSString *_Nullable)plId peerDelegate:(id<JanusPeerDelegate>_Nullable)pd owner:(nullable id<JanusProtocol>)owner {
    peerId = pId;
    publisherId = plId;
    peerDelegate = pd;
    [peerDelegate onInitProtocol:peerId publisherId:publisherId owner:owner];
}


- (void)addIceCandidate:(nonnull NSString *)mid index:(int32_t)index sdp:(nonnull NSString *)sdp {
    if(peerDelegate != nil){
        NSNumber *indexNum = [NSNumber numberWithInt:index];
        [peerDelegate onAddIceCandidate:peerId publisherId:publisherId mid:mid index:indexNum sdp:sdp];
    }
}

- (void)close {
    if(peerDelegate != nil){
        [peerDelegate onPeerClose:peerId publisherId:publisherId];
    }
}

- (void)createAnswer:(nonnull JanusConstraints *)constraints context:(nullable JanusBundle *)context {
    if(peerDelegate != nil){
        [peerDelegate onCreateAnswer:peerId publisherId:publisherId constraints:constraints bundle:context];
    }
}

- (void)createOffer:(nonnull JanusConstraints *)constraints context:(nullable JanusBundle *)context {
    if(peerDelegate != nil){
        [peerDelegate onCreateOffer:peerId publisherId:publisherId constraints:constraints bundle:context];
    }
}

- (void)setLocalDescription:(JanusSdpType)type sdp:(nonnull NSString *)sdp {
    if(peerDelegate != nil){
        [peerDelegate onSetLocalDescription:peerId publisherId:publisherId type:type sdp:sdp];
    }
}

- (void)setRemoteDescription:(JanusSdpType)type sdp:(nonnull NSString *)sdp {
    if(peerDelegate != nil){
        [peerDelegate onSetRemoteDescription:peerId publisherId:publisherId type:type sdp:sdp];
    }
}

@end
