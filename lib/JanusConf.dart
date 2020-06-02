import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io';

class Janus {
  static const MethodChannel _channel =
  const MethodChannel('flutter_janus_method_channel');
  static const EventChannel _event =
  const EventChannel('flutter_janus_event_channel');

  static MethodChannel methodChannel() => _channel;

  static bool get platformIsDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool get platformIsMobile => Platform.isIOS || Platform.isAndroid;

  static addEventStream(void onData(Object onEvent), Function onError) {
    _event.receiveBroadcastStream().listen(onData, onError: onError);
  }

  static addPlatformMethodHandler(platformCallHandler) {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<dynamic> platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "getFlutterName":
        return "Flutter name flutter";
        break;
    }
  }

  static Future<void> connect(host) async {
    try {
      await _channel.invokeMethod('connect', {
        'host': host,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> getRoomList() async {
    try {
      await _channel.invokeMethod('getRoomList');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> join(roomId, id) async {
    try {
      await _channel.invokeMethod('join', {
        'roomId': roomId,
        'id': id,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> leave() async {
    try {
      await _channel.invokeMethod('leave');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> getParticipantsList(roomId) async {
    try {
      await _channel.invokeMethod('getParticipantsList', {
        'roomId': roomId,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> publish() async {
    try {
      await _channel.invokeMethod('publish');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> unPublish() async {
    try {
      await _channel.invokeMethod('unPublish');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> subscribe(roomId, publisherId) async {
    try {
      await _channel.invokeMethod('subscribe', {
        'roomId': roomId,
        'publisherId': publisherId,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> unSubscribe(publisherId) async {
    try {
      await _channel.invokeMethod('unSubscribe', {
        'publisherId': publisherId,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> onPeerIceCandidate(int id, String sdpMid,
      int sdpMLineIndex, String sdp) async {
    try {
      await _channel.invokeMethod('onPeerIceCandidate', {
        'id': id,
        'sdpMid': sdpMid,
        'sdpMLineIndex': sdpMLineIndex,
        'sdp': sdp,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static Future<void> onIceGatheringChange(int id, status) async {
    try {
      await _channel.invokeMethod('onIceGatheringChange', {
        'id': id,
        'status': status,
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }
}

class CameraSwitch {
  static const String CAMERA_FRONT = "CameraSwitchFront";
  static const String CAMERA_BACK = "CameraSwitchBack";
}

class JanusConf {}
