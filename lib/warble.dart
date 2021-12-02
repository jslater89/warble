
/// Warble is a library for the go-flutter desktop embedding engine that
/// plays audio from files, assets, and in-memory buffers.
library warble;

export 'package:warble/src/plugin/plugin.dart' show Warble;
export 'package:warble/src/stream/stream.dart' show WarbleStream;

/// AudioFormat represents the audio formats supported by Warble.
enum AudioFormat {
  mp3,
  wav,
  ogg
}

extension AudioFormatMethods on AudioFormat {
  String toChannelString() {
    return this.toString().replaceFirst("AudioFormat.", "");
  }
}
