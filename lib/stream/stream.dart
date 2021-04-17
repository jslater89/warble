import 'package:warble/plugin/plugin.dart';

/// A WarbleStream is a
class WarbleStream {
  final String id;
  String name;

  /// The length of the stream in samples.
  int length = 0;

  /// The position of the stream in samples.
  int position = 0;

  /// The sample rate of the stream in samples per second.
  int sampleRate = 0;

  /// If true, this is a buffered stream, and can be played
  /// repeatedly using playBuffer.
  bool buffered = false;

  WarbleStream(this.id, {this.name = ""});
  WarbleStream.fromInfo(StreamInfo info) :
      id = info.id,
      name = info.name,
      length = info.length,
      position = info.position,
      sampleRate = info.sampleRate,
      buffered = info.buffered;

  double get percentage => position / (length == 0 ? 1 : length);

  Future<bool> update() async {
    var info = await StreamMethods.getStreamInfo(id);
    if(info == null) return false;

    length = info.length;
    position = info.position;
    sampleRate = info.sampleRate;
    name = info.name;
    return true;
  }

  Future<bool> play() {
    return StreamMethods.playStream(id);
  }

  Future<bool> playBuffered(int from, int to) {
    return StreamMethods.playBuffered(id, from, to);
  }

  Future<bool> close() {
    return StreamMethods.closeStream(id);
  }

  Future<bool> pause() {
    return StreamMethods.pauseStream(id);
  }

  Future<bool> seek(int position) {
    return StreamMethods.seekStream(id, position);
  }
}