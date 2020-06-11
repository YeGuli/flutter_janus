//
//  JanusServiceDelegate.h
//  flutter_janus
//
//  Created by YeGuli on 2020/6/9.
//
#import <Foundation/Foundation.h>
#import "JanusJanusEvent.h"
#import "JanusJanusError.h"
#import "JanusBundle.h"

@protocol JanusServiceDelegate

- (void)onJanusEvent:(nonnull JanusJanusEvent *)event
              bundle:(nullable JanusBundle *)payload;

- (void)onJanusError:(nonnull JanusJanusError *)error
              bundle:(nullable JanusBundle *)payload;

- (void)onJanusReady;

- (void)onJanusClose;

- (void)onJanusHangup:(NSString *_Nullable)reason;

@end
