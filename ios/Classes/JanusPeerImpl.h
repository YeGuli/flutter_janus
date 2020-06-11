//
//  JanusPeerImpl.h
//  testApp
//
//  Created by YeGuli on 2020/6/6.
//  Copyright © 2020 YeGuli. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "JanusPeer.h"
#import "JanusPeerDelegate.h"

@interface JanusPeerImpl :NSObject<JanusPeer>
{
    id<JanusPeerDelegate> peerDelegate;
    NSString * publisherId;
    NSNumber * peerId;
}

- (void)setParam:(NSNumber*_Nullable)pId
     publisherId:(NSString *_Nullable)plId
    peerDelegate:(id<JanusPeerDelegate>_Nullable)pd
           owner:(nullable id<JanusProtocol>)owner;

- (void)createOffer:(nonnull JanusConstraints *)constraints
            context:(nullable JanusBundle *)context;

- (void)createAnswer:(nonnull JanusConstraints *)constraints
             context:(nullable JanusBundle *)context;

- (void)setLocalDescription:(JanusSdpType)type
                        sdp:(nonnull NSString *)sdp;

- (void)setRemoteDescription:(JanusSdpType)type
                         sdp:(nonnull NSString *)sdp;

- (void)addIceCandidate:(nonnull NSString *)mid
                  index:(int32_t)index
                    sdp:(nonnull NSString *)sdp;

- (void)close;

@end


