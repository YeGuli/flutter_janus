import 'package:flutter_webrtc/webrtc.dart';

import 'JanusConf.dart';

class JanusPeer {
  static final String TAG = '[JanusPeer]';

  final Map<String, dynamic> configurationPC = {
    "iceServers": [
      {"url": "stun:stun.l.google.com:19302"},
      {"url": "stun:stun1.l.google.com:19302"},
      {"url": "stun:stun2.l.google.com:19302"},
      {"url": "stun:stun3.l.google.com:19302"},
      {"url": "stun:stun4.l.google.com:19302"},
    ]
  };

  final Map<String, dynamic> constraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [
      {"DtlsSrtpKeyAgreement": true},
      {"googIPv6": true},
    ],
  };

  RTCPeerConnection peer;
  Function onPeerLocalStream;
  Function onPeerRemoteStream;
  Function onPeerClosed;

  int id;
  String publisherId;

  JanusPeer();

  Future initPeer(int id, String publisherId) async {
    this.id = id;
    this.publisherId = publisherId;
    peer = await createPeerConnection(configurationPC, constraints);
    print("$TAG[initPeer]protolId = $id, publisherId = $publisherId");
    peer.onAddStream = onRemoteStream;
    peer.onIceCandidate = onIceCandidate;
    peer.onIceConnectionState = onIceConnectionState;
  }

  void onRemoteStream(MediaStream stream) {
    onPeerRemoteStream(id, publisherId, stream);
  }

  void onIceCandidate(RTCIceCandidate candidate) {
    print(
        "$TAG[onIceCandidate]protolId = $id, candidate= ${candidate.toMap()}");
    Janus.onPeerIceCandidate(
      id,
      candidate.sdpMid,
      candidate.sdpMlineIndex,
      candidate.candidate,
    );
  }

  void onIceConnectionState(RTCIceConnectionState state) {
    String statusStr = "";
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateNew:
        statusStr = "new";
        break;
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        statusStr = "checking";
        break;
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        statusStr = "completed";
        break;
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        statusStr = "connected";
        break;
      case RTCIceConnectionState.RTCIceConnectionStateCount:
        statusStr = "count";
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        statusStr = "failed";
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        statusStr = "disconnected";
        break;
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        statusStr = "closed";
        break;
    }
    print("$TAG[onIceConnectionState]protolId = $id,  state= $statusStr");
    Janus.onIceGatheringChange(id, statusStr);
  }

  Future<String> onCreateOffer(Map<String, Object> data) async {
    print("$TAG[onCreateOffer]protolId = $id,  data = $data");
    MediaStream localStream = await getUsersMedia(data);
    peer.addStream(localStream);
    onPeerLocalStream(
        id, publisherId, localStream, localStream.getVideoTracks()[0]);
    RTCSessionDescription offer = await peer.createOffer(createSdp(data));
    print(
        "$TAG[onCreateOffer]protolId = $id,  RTCSessionDescription = ${offer
            .toMap()}");
    return offer.sdp;
  }

  Future<String> onCreateAnswer(Map<String, Object> data) async {
    print("$TAG[onCreateAnswer]protolId = $id,  data = $data");
    RTCSessionDescription answer = await peer.createAnswer(createSdp(data));
    print(
        "$TAG[onCreateAnswer]protolId = $id,  RTCSessionDescription = ${answer
            .toMap()}");
    return answer.sdp;
  }

  Future onAddIceCandidate(Map<String, Object> data) async {
    print("$TAG[onAddIceCandidate]protolId = $id,  data = $data");
    await peer
        .addCandidate(RTCIceCandidate(data["sdp"], data["mid"], data["index"]));
  }

  Future onSetLocalDescription(Map<String, Object> data) async {
    print("$TAG[onSetLocalDescription]protolId = $id,  data = $data");
    await peer.setLocalDescription(RTCSessionDescription(
        data["sdp"], data["isOffer"] ? "offer" : "answer"));
  }

  Future onSetRemoteDescription(Map<String, Object> data) async {
    print("$TAG[onSetRemoteDescription]protolId = $id,  data = $data");
    await peer.setRemoteDescription(RTCSessionDescription(
        data["sdp"], data["isOffer"] ? "offer" : "answer"));
  }

  Future onPeerClose(Map<String, Object> data) async {
    print("$TAG[onPeerClose]protolId = $id,  data = $data");
    await peer.dispose();
    onPeerClosed(id);
  }

  Future startSceenCapture() async {
    print("$TAG[onPeerClose]startSceenCapture = $id");
    MediaStream scStream = await getScreenCapture();
    peer.addStream(scStream);
//    onPeerLocalStream(
//        publisherId, localStream, localStream.getVideoTracks()[0]);
  }

  Future<MediaStream> getUsersMedia(Map<String, Object> data) async {
    final Map<String, dynamic> mediaConstraints = {
      "audio": data['sendAudio'],
      "video": {
        "mandatory": {
          "minWidth": data['width'],
          "minHeight": data['height'],
          "minFrameRate": data['fps'],
        },
        "facingMode": "user",
      }
    };
    return navigator.getUserMedia(mediaConstraints);
  }

  Map<String, dynamic> createSdp(Map<String, Object> data) {
    final Map<String, dynamic> mediaConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": data['receiveVideo'],
        "OfferToReceiveVideo": data['receiveAudio'],
      },
      "optional": [
        {"DtlsSrtpKeyAgreement": true},
        {"googIPv6": true},
      ],
    };
    return mediaConstraints;
  }

  Future<MediaStream> getScreenCapture() async {
    final Map<String, dynamic> mediaConstraints = {
      "audio": false,
      "video": true
    };
    return navigator.getDisplayMedia(mediaConstraints);
  }
}
