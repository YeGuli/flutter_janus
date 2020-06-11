//
//  JanusPeerDelegate.h
//  testApp
//
//  Created by YeGuli on 2020/6/6.
//  Copyright © 2020 YeGuli. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "JanusProtocol.h"
#import "JanusConstraints.h"
#import "JanusSdpType.h"
#import "JanusBundle.h"

@protocol JanusPeerDelegate

- (void)onInitProtocol:(nonnull NSNumber *)peerId
           publisherId:(nullable NSString *)publisherId
                 owner:(_Nullable id<JanusProtocol>)owner;

- (void)onCreateOffer:(nonnull NSNumber *)peerId
          publisherId:(nullable NSString *)publisherId
          constraints:(nullable JanusConstraints *)constraints
               bundle:(nullable JanusBundle *)bundle;

- (void)onCreateAnswer:(nonnull NSNumber *)peerId
           publisherId:(nullable NSString *)publisherId
           constraints:(nullable JanusConstraints *)constraints
                bundle:(nullable JanusBundle *)bundle;

- (void)onSetLocalDescription:(nonnull NSNumber *)peerId
                  publisherId:(nullable NSString *)publisherId
                         type:(JanusSdpType)type
                          sdp:(nullable NSString *)sdp;

- (void)onSetRemoteDescription:(nonnull NSNumber *)peerId
                   publisherId:(nullable NSString *)publisherId
                          type:(JanusSdpType)type
                           sdp:(nullable NSString *)sdp;

- (void)onAddIceCandidate:(nonnull NSNumber *)peerId
              publisherId:(nullable NSString *)publisherId
                      mid:(nullable NSString *)mid
                    index:(nullable NSNumber *)index
                      sdp:(nullable NSString *)sdp;

- (void)onPeerClose:(nonnull NSNumber *)peerId
        publisherId:(nullable NSString *)publisherId;

@end
