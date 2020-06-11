//
//  JanusConfImpl.h
//  testApp
//
//  Created by YeGuli on 2020/6/5.
//  Copyright © 2020 YeGuli. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "JanusJanusConf.h"

@interface JanusConfImpl :NSObject<JanusJanusConf>
{
    NSString *url;
    NSString *plugin;
}

- (void)setUrl:(NSString*) url;
- (void)setPlugin:(NSString*) plugin;
@end
