import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_janus_example/MeetingPage.dart';
import 'package:flutter_janus/Janus.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> list = List();
  JanusService janus;

  @override
  void initState() {
    super.initState();
    initList();
  }

  @override
  void dispose() {
    super.dispose();
    janus.onGetRoomList.remove(onGetRoomList);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initList() async {
    janus = JanusService("http://192.165.56.150:8088/janus", 'hires');
    janus.onGetRoomList.add(onGetRoomList);
    janus.connect().then((value) {
      janus.getMeetingRoomList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Material(
              child: InkWell(
                onTap: () {
                  goMeetingPage(context, list[index]);
                },
                child: Text(
                  list[index],
                  style: TextStyle(fontSize: 100),
                ),
              ),
            );
          },
          itemCount: list.length,
        ),
      ),
    );
  }

  void goMeetingPage(BuildContext context, String code) {
    Navigator.push(
      context,
      CupertinoPageRoute<void>(
        builder: (ctx) => MeetingPage(
          arguments: {
            "janus": janus,
            "meetingCode": code,
          },
        ),
      ),
    );
  }

  void onGetRoomList(roomList) {
    if (!mounted) return;
    setState(() {
      list.clear();
      list.addAll(List.from(roomList));
    });
  }
}
