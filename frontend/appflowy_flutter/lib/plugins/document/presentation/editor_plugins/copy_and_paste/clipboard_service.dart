import 'dart:async';
import 'dart:convert';

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
);

class ClipboardData {
  const ClipboardData({
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
  Future<void> setData(ClipboardData data) async {
    final plainText = data.plainText;
    final html = data.html;
    final inAppJson = data.inAppJson;

    assert(data.image == null, 'not support image yet');

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
    await ClipboardWriter.instance.write([item]);
  }

  Future<ClipboardData> getData() async {
    final reader = await ClipboardReader.readClipboard();
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

    return ClipboardData(
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
