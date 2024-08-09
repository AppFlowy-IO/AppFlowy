import 'dart:async';
import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Used for in-app copy and paste without losing the format.
///
/// It's a Json string representing the copied editor nodes.
final inAppJsonFormat = CustomValueFormat<String>(
  applicationId: 'io.appflowy.InAppJsonType',
  onDecode: (value, platformType) async {
    if (value is PlatformDataProvider) {
      final data = await value.getData(platformType);
      if (data is List<int>) {
        return utf8.decode(data, allowMalformed: true);
      }
      if (data is String) {
        return Uri.decodeFull(data);
      }
    }
    return null;
  },
  onEncode: (value, platformType) => utf8.encode(value),
);

class ClipboardServiceData {
  const ClipboardServiceData({
    this.plainText,
    this.html,
    this.image,
    this.inAppJson,
  });

  final String? plainText;
  final String? html;
  final (String, Uint8List?)? image;
  final String? inAppJson;
}

class ClipboardService {
  static ClipboardServiceData? _mockData;

  @visibleForTesting
  static void mockSetData(ClipboardServiceData? data) {
    _mockData = data;
  }

  Future<void> setData(ClipboardServiceData data) async {
    final plainText = data.plainText;
    final html = data.html;
    final inAppJson = data.inAppJson;
    final image = data.image;

    final item = DataWriterItem();
    if (plainText != null) {
      item.add(Formats.plainText(plainText));
    }
    if (html != null) {
      item.add(Formats.htmlText(html));
    }
    if (inAppJson != null) {
      item.add(inAppJsonFormat(inAppJson));
    }
    if (image != null && image.$2?.isNotEmpty == true) {
      switch (image.$1) {
        case 'png':
          item.add(Formats.png(image.$2!));
          break;
        case 'jpeg':
          item.add(Formats.jpeg(image.$2!));
          break;
        case 'gif':
          item.add(Formats.gif(image.$2!));
          break;
        default:
          throw Exception('unsupported image format: ${image.$1}');
      }
    }
    await SystemClipboard.instance?.write([item]);
  }

  Future<void> setPlainText(String text) async {
    await SystemClipboard.instance?.write([
      DataWriterItem()..add(Formats.plainText(text)),
    ]);
  }

  Future<ClipboardServiceData> getData() async {
    if (_mockData != null) {
      return _mockData!;
    }

    final reader = await SystemClipboard.instance?.read();

    if (reader == null) {
      return const ClipboardServiceData();
    }

    for (final item in reader.items) {
      final availableFormats = await item.rawReader!.getAvailableFormats();
      Log.debug(
        'availableFormats: $availableFormats',
      );
    }

    final plainText = await reader.readValue(Formats.plainText);
    final html = await reader.readValue(Formats.htmlText);
    final inAppJson = await reader.readValue(inAppJsonFormat);
    (String, Uint8List?)? image;
    if (reader.canProvide(Formats.png)) {
      image = ('png', await reader.readFile(Formats.png));
    } else if (reader.canProvide(Formats.jpeg)) {
      image = ('jpeg', await reader.readFile(Formats.jpeg));
    } else if (reader.canProvide(Formats.gif)) {
      image = ('gif', await reader.readFile(Formats.gif));
    }

    return ClipboardServiceData(
      plainText: plainText,
      html: html,
      image: image,
      inAppJson: inAppJson,
    );
  }
}

extension on DataReader {
  Future<Uint8List?>? readFile(FileFormat format) {
    final c = Completer<Uint8List?>();
    final progress = getFile(
      format,
      (file) async {
        try {
          final all = await file.readAll();
          c.complete(all);
        } catch (e) {
          c.completeError(e);
        }
      },
      onError: (e) {
        c.completeError(e);
      },
    );
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }
}
