//
//  JanusConfImpl.m
//  testApp
//
//  Created by YeGuli on 2020/6/5.
//  Copyright © 2020 YeGuli. All rights reserved.
//
#import "JanusConfImpl.h"

@implementation JanusConfImpl
- (void) setUrl:(NSString *)str{
    url = str;
}

- (void) setPlugin:(NSString *)str{
    plugin = str;
}

- (nonnull NSString *)plugin {
    return plugin;
}

- (nonnull NSString *)url {
    return url;
}

@end
