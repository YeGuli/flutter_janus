//
//  JanusService.h
//  flutter_janus
//
//  Created by YeGuli on 2020/6/8.
//
#import <Foundation/Foundation.h>
#import "JanusJanusPlugins.h"
#import "JanusConfImpl.h"
#import "JanusPeerFactoryImpl.h"
#import "JanusPlatform.h"
#import "JanusJanus.h"
#import "JanusBundle.h"
#import "JanusPeerDelegate.h"
#import "JanusProtocolDelegate.h"
#import "JanusServiceDelegate.h"

@interface JanusService : NSObject<JanusProtocolDelegate>
{
    JanusJanus *janus;
    id<JanusServiceDelegate> serviceDelegate;
    int status;
}

-(void) init:(JanusConfImpl * _Nullable)conf
peerDelegate:(id<JanusPeerDelegate>_Nullable) peerDelegate
serviceDelegate:(id<JanusServiceDelegate>_Nullable) serviceDelegate;

-(int) getStatus;

-(void) start;

-(void) stop;

-(void) hangup;

-(void) dispatch:(NSString *_Nullable)command
         payload:(JanusBundle *_Nullable)payload;

@end
