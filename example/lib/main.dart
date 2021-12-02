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

  late WarbleStream stream;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    example();
  }

  String _text = "Playing!";

  Future<void> example() async {
    var s = (await Warble.wrapAsset(rootBundle, "assets/musicbox.mp3", buffered: true))!;

    setState(() {
      stream = s;
      loaded = true;
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
          child: !loaded ? Text("Loading...") : Player(stream: stream,)
        ),
      ),
    );
  }
}

class Player extends StatefulWidget {
  const Player({Key? key, required this.stream}) : super(key: key);
  final WarbleStream stream;

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  bool paused = false;
  bool playing = false;

  double gain = 1;
  double pan = 0;

  @override
  void initState() {
    super.initState();

    // update the stream about once per second
    Timer.periodic(Duration(milliseconds: 16), (timer) async {
      await widget.stream.update();

      // plugin-level looping: a someday feature
      if(widget.stream.position == widget.stream.length && playing) {
        await widget.stream.seek(0);
        widget.stream.play();
      }
      setState(() {
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Stream info"),
        SizedBox(height: 5),
        Text("Position/Length (samples): ${widget.stream.position}/${widget.stream.length}"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: !playing ? Icon(Icons.play_arrow) : (playing && !paused ? Icon(Icons.pause) : Icon(Icons.play_arrow)),
              onPressed: () async {
                if(playing) {
                  paused = !paused;
                  var res = await widget.stream.pause(paused);
                  setState(() {
                    paused = paused;
                  });
                  debugPrint("Stream pause state: $paused $res");
                }
                else {
                  var res = await widget.stream.play();
                  debugPrint("Starting stream: $res");
                  setState(() {
                    playing = true;
                  });
                }
              },
            ),
            TextButton(
              child: Icon(Icons.stop),
              onPressed: () {
                setState(() {
                  playing = false;
                });
                widget.stream.seek(widget.stream.length);
              },
            ),
          ],
        ),
        Text("Gain: $gain", style: Theme.of(context).textTheme.caption,),
        Slider(
          value: gain,
          onChanged: (v) {
            setState(() {
              gain = v;
            });
          },
          onChangeEnd: (_) {
            widget.stream.gain(gain);
          },
          min: 0,
          max: 1.25,
        ),
        SizedBox(height: 5),
        Text("Pan: $pan", style: Theme.of(context).textTheme.caption,),
        Slider(
          value: pan,
          onChanged: (v) {
            setState(() {
              pan = v;
            });
          },
          onChangeEnd: (_) {
            widget.stream.pan(pan);
          },
          min: -1,
          max: 1,
        ),
      ],
    );
  }
}
