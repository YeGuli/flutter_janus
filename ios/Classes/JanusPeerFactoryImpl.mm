//
//  JanusPeerFactoryImpl.m
//  testApp
//
//  Created by YeGuli on 2020/6/5.
//  Copyright © 2020 YeGuli. All rights reserved.
//
#import "JanusPeerFactoryImpl.h"

@implementation JanusPeerFactoryImpl

- (nullable id<JanusPeer>)create:(int64_t)peerId publisher:(nonnull NSString *)publisher owner:(nullable id<JanusProtocol>)owner {
    JanusPeerImpl *peer = [JanusPeerImpl new];
    NSNumber *idNum = [NSNumber numberWithLongLong:peerId];
    [peer setParam:idNum publisherId:publisher peerDelegate:nil owner:owner];
    
    return peer;
}

@end
