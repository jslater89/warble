/// {@nodoc}
library stream;

import 'package:warble/plugin/plugin.dart';

/// A WarbleStream encapsulates a loaded audio file.
///
/// Streams can be buffered or unbuffered. An unbuffered
/// stream is streamed from disk, reducing memory usage and
/// startup delay. It cannot be played in overlapping fashion:
/// each play must finish before the next play starts.
///
/// A buffered stream is loaded into memory, and can be played
/// in overlapping fashion using [playBuffered].
///
/// Multiple streams may be created for a given audio source.
class WarbleStream {
  /// A unique ID for this stream.
  final String id;

  /// A readable name for the stream. It may not be unique:
  /// multiple streams created from the same file will have
  /// the same name.
  String name;

  /// The length of the stream in samples.
  int length = 0;

  /// The position of the stream in samples.
  int position = 0;

  /// The sample rate of the stream in samples per second.
  int sampleRate = 0;

  /// If true, this is a buffered stream, and can be played
  /// in overlapping fashion.
  bool buffered = false;

  WarbleStream(this.id, {this.name = ""});
  WarbleStream.fromInfo(StreamInfo info) :
      id = info.id,
      name = info.name,
      length = info.length,
      position = info.position,
      sampleRate = info.sampleRate,
      buffered = info.buffered;

  /// The percentage progress this stream has made through its total length.
  double get percentage => position / (length == 0 ? 1 : length);

  /// Update fetches the latest position for this stream.
  Future<bool> update() async {
    var info = await StreamMethods.getStreamInfo(id);
    if(info == null) return false;

    length = info.length;
    position = info.position;
    sampleRate = info.sampleRate;
    name = info.name;
    return true;
  }

  /// Plays this stream starting from the current seek point.
  ///
  /// Any changes to the effects settings for this [WarbleStream]
  /// (gain, pan, etc.) will affect the audio being played.
  ///
  /// Calling [play] on a stream that is already being played
  /// will result in distorted playback. Use [update] to determine
  /// if a stream is being played: if [position] is advancing, the
  /// stream is being played.
  ///
  /// Calling [play] on a stream that has ended ([position] ==
  /// [length]) will seek to position 0, then play.
  Future<bool> play() {
    return StreamMethods.playStream(id);
  }

  /// Plays a copy of this stream created from the underlying buffer.
  ///
  /// [from] and [to] indicate, in samples, where the stream should
  /// start playing and where it should stop. [from] must be less than [to],
  /// [from] must be greater than 0, and to must be less than [length].
  ///
  /// Copied streams cannot be controlled in any way: they inherit effects
  /// settings from their parent stream, and play in their entirety.
  Future<bool> playBuffered(int from, int to) {
    return StreamMethods.playBuffered(id, from, to);
  }

  /// Sets the pan for this stream.
  ///
  /// -1 is entirely in the left channel, 1 is entirely in the right channel.
  Future<bool> pan(double pan) {
    return StreamMethods.panStream(id, pan);
  }

  /// Sets the gain for this stream.
  ///
  /// 0 is silent. 1 is original volume.
  Future<bool> gain(double gain) {
    return StreamMethods.gainStream(id, gain - 1);
  }

  /// Closes this stream, releasing resources.
  Future<bool> close() {
    return StreamMethods.closeStream(id);
  }

  /// Pauses this stream, silencing its output.
  Future<bool> pause() {
    return StreamMethods.pauseStream(id);
  }

  /// Seeks this stream, moving to [position] (given in samples).
  ///
  /// Seeking a stream currently playing will cause it to continue playing
  /// from the new position.
  ///
  /// Seeking a stream that has finished playing, or has not started playing,
  /// will cause it to start playing from that position on the next call to
  /// [play].
  Future<bool> seek(int position) {
    return StreamMethods.seekStream(id, position);
  }
}