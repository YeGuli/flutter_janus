#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import "JanusPeerDelegate.h"
#import "JanusServiceDelegate.h"
#import "JanusConfImpl.h"
#import "JanusService.h"
#import "JanusJanusPlugins.h"
#import "JanusBundle.h"
#import "JanusJanusCommands.h"
#import "JanusProtocol.h"
#import "JanusSdpType.h"
#import "JanusJanusData.h"
#import "JanusJanus.h"

@interface FlutterJanusPlugin : NSObject<FlutterPlugin,FlutterStreamHandler,JanusPeerDelegate,JanusServiceDelegate>
@property (nonatomic, strong) JanusService *janusService;
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, strong) NSObject<FlutterBinaryMessenger>* messenger;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<JanusProtocol>> *janusProtocolMap;

@end
