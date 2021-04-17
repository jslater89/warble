import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:warble/warble.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    example();
  }

  String _text = "Playing!";

  Future<void> example() async {
    WarbleStream stream = (await Warble.wrapAsset(rootBundle, "assets/chime.wav", buffered: true))!;

    stream.play();
    Future.delayed(Duration(seconds:3)).then((_) {
      stream.playBuffered(0, stream.length);
      setState(() {
        _text = "Playing buffered";
      });
    });
    Future.delayed(Duration(seconds:6)).then((_) {
      stream.play();
      setState(() {
        _text = "Seeking and replaying";
      });
    });
    Future.delayed(Duration(milliseconds:7500)).then((_) {
      stream.seek(0);
      setState(() {
        _text = "Seeking during playback";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(_text),
        ),
      ),
    );
  }
}
