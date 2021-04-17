import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:warble/stream/stream.dart';
import 'package:warble/warble.dart';

const MethodChannel channel = const MethodChannel('warble');
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

  // TODO: cache more of it, put it in memory
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

  static Future<WarbleStream?> wrapAsset(AssetBundle source, String name) async {
    var result = await ensureAsset(source, name);
    if(!result) return null;

    return wrapFile(name, File(await _cachedPath(name)));
  }

  static Future<WarbleStream?> wrapFile(String name, File file, {bool buffered = false}) async {
    try {
      var info = await channel.invokeMapMethod<String, dynamic>('wrapFile', {'name': name, 'file': file.absolute.path, 'buffered': false});
      if(info == null) return null;
      return WarbleStream.fromInfo(StreamInfo.fromMap(info));
    }
    catch(err) {
      return null;
    }
  }

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

  // TODO: return info
  static Future<List<WarbleStream>> listStreams() async {
    try {
      var ids = await channel.invokeMapMethod<String, String>('listStreams');
      return ids?.map<String, WarbleStream>((id, name) => MapEntry(id, WarbleStream(id, name: name))).values.toList() ?? [];
    }
    catch(err) {
      return [];
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