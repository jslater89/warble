// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum AudioFormat {
  mp3,
}

extension AudioFormatMethods on AudioFormat {
  String toChannelString() {
    return this.toString().replaceFirst("AudioFormat.", "");
  }
}

class Vibrato {
  static const MethodChannel _channel =
      const MethodChannel('vibrato');

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

  // TODO: cache
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

  static Future<bool> playAsset(AssetBundle source, String name) async {
    var result = await ensureAsset(source, name);
    if(!result) return false;

    return playFile(File(await _cachedPath(name)));
  }

  static Future<bool> playFile(File file) async {
    try {
      await _channel.invokeMethod('playFile', {'file': file.absolute.path});
      return true;
    }
    catch(err) {
      return false;
    }
  }

  static Future<bool> playBuffer(Uint8List buffer, AudioFormat format) async {
    try {
      await _channel.invokeMethod('playBuffer', {'buffer': buffer, 'format': format.toChannelString()});
      return true;
    }
    catch(err) {
      return false;
    }
  }
}
