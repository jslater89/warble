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

    await stream.gain(0.25);
    await stream.pan(-1);
    stream.play();
    Future.delayed(Duration(seconds:3)).then((_) async {
      await stream.gain(0.50);
      await stream.pan(-0.25);
      stream.playBuffered(0, stream.length);
      setState(() {
        _text = "Playing buffered";
      });
    });
    Future.delayed(Duration(seconds:6)).then((_) async {
      await stream.gain(0.875);
      await stream.pan(0.25);
      stream.play();
      setState(() {
        _text = "Seeking and replaying";
      });
    });
    Future.delayed(Duration(milliseconds:7500)).then((_) async {
      await stream.gain(1);
      await stream.pan(1);
      stream.seek(0);
      setState(() {
        _text = "Seeking during playback";
      });
    });
    Future.delayed(Duration(milliseconds:10500)).then((_) => setState(() {
      _text = "Done!";
    }));
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
