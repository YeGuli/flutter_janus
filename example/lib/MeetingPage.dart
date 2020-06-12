import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_janus/Janus.dart';

class MeetingPage extends StatefulWidget {
  final Map arguments;

  MeetingPage({Key key, this.arguments}) : super(key: key);

  @override
  _MeetingPageState createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  JanusService janus;
  String meetingCode;

  List<RTCVideoRenderer> streams = [];

  onJoinRoom(String code) {
    print('[MeetingPage][onJoinRoom]$code');
    if (code != meetingCode) return;
    startPublish();
//    getCurPublisher();
  }

  MediaStream localStream;
  MediaStreamTrack localTrack;
  List<MediaStream> streamList = List();

//  RTCVideoRenderer streamRender;
//
//  addLocal(MediaStream stream, bool mirror) async {
//    streamRender = new RTCVideoRenderer();
//    await streamRender.initialize();
//    streamRender.srcObject = stream;
//    streamRender.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
//    streamRender.mirror = mirror;
//    setState(() {
//      streams.add(streamRender);
//    });
//  }
//
//  addRemote(MediaStream stream, bool mirror) async {
//    streamRender.srcObject = stream;
//    streamRender.mirror = mirror;
//    setState(() {
//      print('[MeetingPage]addRemote');
//    });
//  }

  freshRender(MediaStream stream, bool mirror) async {
    RTCVideoRenderer streamRender = new RTCVideoRenderer();
    await streamRender.initialize();
    streamRender.srcObject = stream;
    streamRender.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    streamRender.mirror = mirror;
    setState(() {
      streams.add(streamRender);
    });
  }

  onLocalStream(
      int id,
      String publisherId,
      MediaStream stream,
      MediaStreamTrack localTrack) async {
    print(
        "[onLocalStream], _trackId = ${localTrack.id}, kind = ${localTrack.kind}, label = ${localTrack.label}, enabled = ${localTrack.enabled}");
    this.localStream = stream;
    this.localTrack = localTrack;
    await freshRender(stream, false);
//    await addLocal(stream, false);
  }

  onRemoteStream(
      int id,
      String publisherId,
      MediaStream stream,
      ) async {
    print(
        "[onRemoteStream], stream.videoListSize = ${stream.getVideoTracks().length}, stream.audioListSize = ${stream.getAudioTracks().length}, label = ${stream.id}");
    print(
        "[onRemoteStream], video, _trackId = ${stream.getVideoTracks()[0].id}, kind = ${stream.getVideoTracks()[0].kind}, label = ${stream.getVideoTracks()[0].label}, enabled = ${stream.getVideoTracks()[0].enabled}");
    print(
        "[onRemoteStream], audio, _trackId = ${stream.getAudioTracks()[0].id}, kind = ${stream.getAudioTracks()[0].kind}, label = ${stream.getAudioTracks()[0].label}, enabled = ${stream.getAudioTracks()[0].enabled}");
    if (stream != null && !streamList.contains(stream)) {
      this.streamList.add(stream);
      await freshRender(stream, false);
//      await addRemote(stream, false);
    }
  }

  onPublisherIn(List publisherList) {
    print('[MeetingPage][onPublisherIn]$publisherList');
    resolvePublisherIn(publisherList);
  }

  onPublisherOut(List publisherList) {
    print('[MeetingPage][onPublisherOut]$publisherList');
    resolvePublisherOut(publisherList);
  }

  onGetPublisherList(List publisherList) {
    print('[MeetingPage][onGetPublisherList]$publisherList');
    resolvePublisherIn(publisherList);
  }

  onLeave() {
    print('[MeetingPage][onLeave]');
    streams.forEach((element) {
      element.srcObject = null;
      element.dispose();
    });
    if (localStream != null) {
      localStream.dispose();
    }
    streamList.forEach((element) {
      element.dispose();
    });
    streams.clear();
    streamList.clear();
    Navigator.of(context).pop();
  }

  Future resolvePublisherIn(List publisherList) async {
    publisherList.forEach((element) {
      Map<String, Object> publisher = Map.castFrom(element);
      janus.subscribe(meetingCode, publisher["id"]);
    });
  }

  Future resolvePublisherOut(List publisherList) async {
    publisherList.forEach((element) {
      Map<String, Object> publisher = Map.castFrom(element);
      janus.unSubscribe(publisher["id"]);
    });
  }

  Future leaveRoom() async {
    await janus.leaveRoom(meetingCode);
  }

  Future joinRoom() async {
    janus.onJoinRoom.add(this.onJoinRoom);
    janus.onPublisherIn.add(this.onPublisherIn);
    janus.onPublisherOut.add(this.onPublisherOut);
    janus.onLeave.add(this.onLeave);
    janus.joinRoom(meetingCode, "");
  }

  Future startPublish() async {
    janus.onLocalStream.add(this.onLocalStream);
    janus.onRemoteStream.add(this.onRemoteStream);
    await janus.publish();
  }

  Future getCurPublisher() async {
    janus.onGetParticipantsList.add(this.onGetPublisherList);
    janus.getParticipantsList(meetingCode);
  }

  @override
  void initState() {
    super.initState();
    janus = widget.arguments["janus"];
    meetingCode = widget.arguments["meetingCode"];

    joinRoom();
  }

  Future<bool> onBackPressed() async {
    await leaveRoom();
    return Future.value(false);
  }

  @override
  void dispose() {
    super.dispose();
    janus.onJoinRoom.remove(this.onJoinRoom);
    janus.onPublisherIn.remove(this.onPublisherIn);
    janus.onPublisherOut.remove(this.onPublisherOut);
    janus.onLeave.remove(this.onLeave);
    janus.onLocalStream.remove(this.onLocalStream);
    janus.onRemoteStream.remove(this.onRemoteStream);
    janus.onGetParticipantsList.remove(this.onGetPublisherList);
  }

  @override
  Widget build(BuildContext context) {
    var streamsWidgets = streams
        .map((var streamRender) => new Expanded(
              child: new RTCVideoView(streamRender),
            ))
        .toList();
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text("MeetingCode = $meetingCode"),
        ),
        body: Center(
          child: new Container(
            child: new Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: streamsWidgets),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Make Call',
          child: Icon(Icons.cached),
          onPressed: () {
            if (localTrack != null) {
              localTrack.switchCamera();
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
