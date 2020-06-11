//
//  JanusPeerFactoryImpl.h
//  testApp
//
//  Created by YeGuli on 2020/6/5.
//  Copyright © 2020 YeGuli. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "JanusPeerFactory.h"
#import "JanusPeerImpl.h"

@interface JanusPeerFactoryImpl :NSObject<JanusPeerFactory>
- (nullable id<JanusPeer>)create:(int64_t)peerId
publisher:(nonnull NSString *)publisher
owner:(nullable id<JanusProtocol>)owner;
@end
