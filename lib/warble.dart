// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

export 'package:warble/plugin/plugin.dart' show Warble;
export 'package:warble/stream/stream.dart' show WarbleStream;

enum AudioFormat {
  mp3,
}

extension AudioFormatMethods on AudioFormat {
  String toChannelString() {
    return this.toString().replaceFirst("AudioFormat.", "");
  }
}
