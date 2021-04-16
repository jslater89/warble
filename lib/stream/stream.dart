import 'package:vibrato/plugin/plugin.dart';

class VibratoStream {
  final String id;
  String name;

  /// The length of the stream in samples.
  int length = 0;

  /// The position of the stream in samples.
  int position = 0;

  /// The sample rate of the stream in samples per second.
  int sampleRate = 0;

  VibratoStream(this.id, {this.name = ""});

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