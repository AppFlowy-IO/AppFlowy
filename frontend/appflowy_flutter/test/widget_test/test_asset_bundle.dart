import 'dart:convert';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// TestAssetBundle is required in order to avoid issues with large assets
///
/// ref: https://medium.com/@sardox/flutter-test-and-randomly-missing-assets-in-goldens-ea959cdd336a
///
/// "If your AssetManifest.json file exceeds 10kb, it will be
///  loaded with isolate that (most likely) will cause your
///  test to finish before assets are loaded so goldens will
///  get empty assets."
///
class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    // overriding this method to avoid limit of 10KB per asset
    try {
      final data = await load(key);
      return utf8.decode(data.buffer.asUint8List());
    } catch (err) {
      throw FlutterError('Unable to load asset: $key');
    }
  }

  @override
  Future<ByteData> load(String key) async => rootBundle.load(key);
}

final testAssetBundle = TestAssetBundle();

/// Loads from our custom asset bundle
class TestBundleAssetLoader extends AssetLoader {
  const TestBundleAssetLoader();

  String getLocalePath(String basePath, Locale locale) {
    return '$basePath/${locale.toStringWithSeparator(separator: "-")}.json';
  }

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final localePath = getLocalePath(path, locale);
    return json.decode(await testAssetBundle.loadString(localePath));
  }
}
