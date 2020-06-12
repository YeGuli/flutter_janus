import 'package:flutter/services.dart';
import 'package:flutter_janus/JanusPeer.dart';
import 'Janus.dart';

class JanusService {
  static final String TAG = '[JanusService]';

  String serverUrl;
  String videoQuality;

  Map<int, JanusPeer> peerMap = Map();

  List<Function> onLocalStream = List();
  List<Function> onRemoteStream = List();
  List<Function> onGetRoomList = List();
  List<Function> onJoinRoom = List();
  List<Function> onPublish = List();
  List<Function> onGetParticipantsList = List();
  List<Function> onPublisherIn = List();
  List<Function> onPublisherOut = List();
  List<Function> onLeave = List();
  List<Function> onJanusConnectReady = List();
  List<Function> onJanusConnectError = List();

  JanusService(this.serverUrl, this.videoQuality);

  onPeerLocalStream(int id, String publisherId, MediaStream stream,
      MediaStreamTrack localTrack,) {
    onLocalStream.forEach((element) {
      element(id, publisherId, stream, localTrack);
    });
  }

  onPeerRemoteStream(int id, String publisherId, MediaStream stream,) {
    onRemoteStream.forEach((element) {
      element(id, publisherId, stream);
    });
  }

  onPeerClosed(id) {
    removePeer(id);
  }

  Future connect() async {
    print(' $TAG[open connection] $serverUrl');
    Janus.addEventStream(onJanusStreamEvent, onJanusStreamError);
    Janus.addPlatformMethodHandler(platformCallHandler);
    await Janus.connect(serverUrl);
    print('$TAG[janus connected]');
    return Future.value();
  }

  Future disconnect() async {
    print(' $TAG[close connection] $serverUrl');
    await Janus.disconnect();
    return Future.value();
  }

  Future getMeetingRoomList() async {
    print('$TAG[get room list]');
    await Janus.getRoomList();
    return Future.value();
  }

  Future joinRoom(roomId, id) async {
    print('$TAG[join room $roomId,id $id]');
    await Janus.join(roomId, id);
    return Future.value();
  }

  Future leaveRoom(roomId) async {
    print('$TAG[leave room $roomId]');
    await Janus.leave();
    return Future.value();
  }

  Future publish() async {
    print('$TAG[publish]');
    await Janus.publish();
    return Future.value();
  }

  Future unPublish() async {
    print('$TAG[unPublish]');
    await Janus.unPublish();
    return Future.value();
  }

  Future subscribe(roomId, publisherId) async {
    print('$TAG[subscribe]');
    await Janus.subscribe(roomId, publisherId);
    return Future.value();
  }

  Future unSubscribe(publisherId) async {
    print('$TAG[unSubscribe]');
    await Janus.unSubscribe(publisherId);
    return Future.value();
  }

  Future getParticipantsList(roomId) async {
    print('$TAG[get participants list]');
    await Janus.getParticipantsList(roomId);
    return Future.value();
  }

  Future startScreenCapture(id) {
    print('$TAG[start screen capture]');
    if (peerMap[id] != null) {
      peerMap[id].startSceenCapture();
    }
  }

  void onJanusStreamEvent(Object event) {
    print('$TAG[onJanusStreamEvent]$event');
    if (event == null) {
      return;
    }
    Map<String, Object> data = Map.castFrom(event);
    if (data['action'] == null) {
      return;
    }

    switch (data['action']) {
      case 'connect':
        String event = data['event'];
        if (event == "onJanusReady") {
          if (onJanusConnectReady != null) {
            onJanusConnectReady.forEach((element) {
              element();
            });
          }
        } else if (event == "onJanusHangup") {
          if (onJanusConnectError != null) {
            onJanusConnectError.forEach((element) {
              element();
            });
          }
        } else if (event == "onJanusClose") {
          if (onJanusConnectError != null) {
            onJanusConnectError.forEach((element) {
              element();
            });
          }
        }
        break;
      case 'getRoomList':
        if (onGetRoomList != null) {
          onGetRoomList.forEach((element) {
            element(data['roomList']);
          });
        }
        return;
      case 'join':
        if (onJoinRoom != null) {
          onJoinRoom.forEach((element) {
            element(data['roomId']);
          });
        }
        return;
      case 'getParticipantsList':
        if (onGetParticipantsList != null) {
          onGetParticipantsList.forEach((element) {
            element(data['participantsList']);
          });
        }
        return;
      case 'publisherIn':
        if (onPublisherIn != null) {
          onPublisherIn.forEach((element) {
            element(data['publisherList']);
          });
        }
        return;
      case 'publisheOut':
        if (onPublisherOut != null) {
          onPublisherOut.forEach((element) {
            element(data['publisherId']);
          });
        }
        return;
      case 'leave':
        if (onLeave != null) {
          onLeave.forEach((element) {
            element();
          });
        }
        return;
    }
  }

  onJanusStreamError(error) {
    print('$TAG[onJanusStreamError]$error');
  }

  Future<dynamic> platformCallHandler(MethodCall call) async {
    Map<String, Object> data = Map.castFrom(call.arguments);
    print('$TAG[platformCallHandler]method : ${call.method}');

    int id = data["id"];
    switch (call.method) {
      case "onCreateOffer":
        if (peerMap[id] == null) {
          String publisherId = data["publisherId"];
          await addPeer(id, publisherId);
        }
        String sdp = await peerMap[id].onCreateOffer(data);
        return {
          "sdp": sdp,
          "id": id,
        };
      case "onCreateAnswer":
        await waitPeerAdded(id);
        String sdp = await peerMap[id].onCreateAnswer(data);
        return {
          "sdp": sdp,
          "id": id,
        };
      case "onAddIceCandidate":
        await peerMap[id].onAddIceCandidate(data);
        return "";
      case "onSetLocalDescription":
        await peerMap[id].onSetLocalDescription(data);
        return "";
      case "onSetRemoteDescription":
        if (peerMap[id] == null) {
          String publisherId = data["publisherId"];
          await addPeer(id, publisherId);
        }
        await peerMap[id].onSetRemoteDescription(data);
        return "";
      case "onPeerClose":
        await peerMap[id].onPeerClose(data);
        return "";
    }
  }

  Future addPeer(int id, String publisherId) async {
    print('$TAG[addPeer]id = $id, publisherId = $publisherId');
    JanusPeer peer = JanusPeer();
    await peer.initPeer(id, publisherId);
    peer.onPeerLocalStream = onPeerLocalStream;
    peer.onPeerRemoteStream = onPeerRemoteStream;
    peer.onPeerClosed = onPeerClosed;
    peerMap[id] = peer;
  }

  Future waitPeerAdded(int id) async {
    int waitCount = 0;
    while (peerMap[id] == null) {
      print('$TAG[waitPeerAdded]wait = $waitCount');
      waitCount++;
      await Future.delayed(Duration(milliseconds: 200));
    }
    Future.value();
  }

  Future removePeer(int id) async {
    print('$TAG[removePeer]id = $id');
    peerMap.remove(peerMap[id]);
  }
}
