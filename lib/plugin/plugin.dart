import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:warble/stream/stream.dart';
import 'package:warble/warble.dart';

const MethodChannel channel = const MethodChannel('warble');

/// Warble is a Flutter plugin for the go-flutter desktop embedding
/// which can play audio from files, assets, or in-memory buffers.
class Warble {
  static Future<Directory> _cachedAssetDir() async {
    Directory root = await getApplicationSupportDirectory();
    Directory assetCache = await Directory(root.path + Platform.pathSeparator + "asset-cache").create();

    return assetCache;
  }

  static String _cachedName(String name) {
    return name.replaceAll(r"/", "-").replaceAll(r"\", "-");
  }

  static Future<String> _cachedPath(String name) async {
    return (await _cachedAssetDir()).path + Platform.pathSeparator + _cachedName(name);
  }

  /// ensureAsset ensures that an audio asset has been inflated and cached to
  /// the filesystem.
  static Future<bool> ensureAsset(AssetBundle source, String name) async {
    var assetCache = await _cachedAssetDir();
    var cachedName = _cachedName(name);

    try {
      bool exists = false;
      assetCache.listSync().forEach((element) {
        if(element.path.endsWith(cachedName)) {
          exists = true;
          return;
        }
      });

      if(exists) return true;

      File f = File(await _cachedPath(name));
      var bytes = Uint8List.sublistView(await rootBundle.load(name));
      await f.writeAsBytes(bytes);
      return true;
    }
    catch(e, stackTrace) {
      // TODO
      print("error: $e $stackTrace");
      return false;
    }
  }

  /// wrapAsset inflates an audio asset to the filesystem (if it has not been inflated
  /// by a previous call to [wrapAsset] or [ensureAsset]), and returns a [WarbleStream]
  /// which can be used to play the asset.
  ///
  /// [name] should have an extension corresponding to a supported file type: one of
  /// .mp3, .wav, or .ogg.
  ///
  /// If [buffered] is true, Warble loads the asset as a buffered stream. See [WarbleStream]
  /// for more.
  static Future<WarbleStream?> wrapAsset(AssetBundle source, String name, {bool buffered = false}) async {
    var result = await ensureAsset(source, name);
    if(!result) return null;

    return wrapFile(File(await _cachedPath(name)), name: name);
  }

  /// wrapFile accepts a file and returns a [WarbleStream] which can be used to play it.
  ///
  /// [file]'s name should end in an extension corresponding to a supported file type: one of
  /// .mp3, .wav, or .ogg.
  ///
  /// [name], if present, is used for [WarbleStream.name]. Otherwise, the file's path is used.
  ///
  /// If [buffered] is true, Warble loads the asset as a buffered stream. See [WarbleStream]
  /// for more.
  static Future<WarbleStream?> wrapFile(File file, {String? name, bool buffered = false}) async {
    String n = name ?? file.path;

    try {
      var info = await channel.invokeMapMethod<String, dynamic>('wrapFile', {'name': n, 'file': file.absolute.path, 'buffered': false});
      if(info == null) return null;
      return WarbleStream.fromInfo(StreamInfo.fromMap(info));
    }
    catch(err) {
      return null;
    }
  }

  /// wrapBuffer accepts a byte buffer and returns a [WarbleStream] which can be used to play it.
  ///
  /// [name] is used for [WarbleStream.name].
  ///
  /// [format] is the [AudioFormat] that the buffer contains.
  ///
  /// If [buffered] is true (the default), Warble loads the asset as a buffered stream. See [WarbleStream]
  /// for more.
  static Future<WarbleStream?> wrapBuffer(String name, Uint8List buffer, AudioFormat format, {bool buffered = true}) async {
    try {
      var info = await channel.invokeMapMethod<String, dynamic>('wrapBuffer', {'name': name, 'buffer': buffer, 'format': format.toChannelString(), 'buffered': true});
      if(info == null) return null;
      return WarbleStream.fromInfo(StreamInfo.fromMap(info));
    }
    catch(err) {
      return null;
    }
  }

  /// listStreams returns a list of all currently-loaded [WarbleStream]s known to the
  /// plugin.
  static Future<List<WarbleStream>> listStreams() async {
    var streams = <WarbleStream>[];
    try {
      var ids = await channel.invokeListMethod<String>('listStreams');
      if(ids == null) return streams;

      for(var id in ids) {
        streams.add((await getStream(id))!);
      }
      return streams;
    }
    catch(err) {
      return [];
    }
  }

  /// getStream returns a [WarbleStream] corresponding to a given ID.
  static Future<WarbleStream?> getStream(String id) async {
    try {
      var info = await StreamMethods.getStreamInfo(id);
      if(info == null) return null;
      return WarbleStream.fromInfo(info);
    }
    catch(err) {
      return null;
    }
  }
}

class StreamMethods {
  static Future<bool> seekStream(String id, int position) async {
    try {
      await channel.invokeMethod('seekStream', {'id': id, 'position': position});
      return true;
    }
    catch(err) {
      return false;
    }
  }

  static Future<bool> playStream(String id) async {
    try {
      await channel.invokeMethod('playStream', {'id': id});
      return true;
    }
    catch(err) {
      return false;
    }
  }

  static Future<bool> playBuffered(String id, int from, int to) async {
    try {
      await channel.invokeMethod('playStream', {'id': id, 'from': from, 'to': to});
      return true;
    }
    catch(err) {
      return false;
    }
  }

  static Future<bool> pauseStream(String id) async {
    try {
      await channel.invokeMethod('closeStream', {'id': id});
      return true;
    }
    catch(err) {
      return false;
    }
  }

  static Future<StreamInfo?> getStreamInfo(String id) async {
    try {
      var info = await channel.invokeMapMethod<String, dynamic>('streamInfo', {'id': id});
      if(info == null) return null;
      return StreamInfo.fromMap(info);
    }
    catch(err) {
      return null;
    }
  }

  static Future<bool> closeStream(String id) async {
    try {
      await channel.invokeMethod('closeStream', {'id': id});
      return true;
    }
    catch(err) {
      return false;
    }
  }
}

class StreamInfo {
  String id;
  String name;
  int position;
  int length;
  int sampleRate;
  bool buffered;

  StreamInfo.fromMap(Map<String, dynamic> map) :
      id = map["id"]!,
      name = map["name"]!,
      position = map["position"]!,
      length = map["length"]!,
      sampleRate = map["sampleRate"],
      buffered = map["buffered"]!;
}