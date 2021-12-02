# Warble

Warble is an audio-playing plugin for go-flutter-desktop, based on the Golang beep audio library.

```dart
var stream = (await Warble.wrapAsset(rootBundle, "assets/musicbox.mp3"))!;
await stream.play();

stream.pan(-0.25); // bias audio to left channel
stream.gain(0.6); // reduce volume

stream.pause(true)
```