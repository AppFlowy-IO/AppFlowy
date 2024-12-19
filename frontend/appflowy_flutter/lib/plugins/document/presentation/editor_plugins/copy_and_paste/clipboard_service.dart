import 'dart:async';
import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Used for in-app copy and paste without losing the format.
///
/// It's a Json string representing the copied editor nodes.
const inAppJsonFormat = CustomValueFormat<String>(
  applicationId: 'io.appflowy.InAppJsonType',
  onDecode: _defaultDecode,
  onEncode: _defaultEncode,
);

/// Used for table nodes when coping a row or a column.
const tableJsonFormat = CustomValueFormat<String>(
  applicationId: 'io.appflowy.TableJsonType',
  onDecode: _defaultDecode,
  onEncode: _defaultEncode,
);

class ClipboardServiceData {
  const ClipboardServiceData({
    this.plainText,
    this.html,
    this.image,
    this.inAppJson,
    this.tableJson,
  });

  /// The [plainText] is the plain text string.
  ///
  /// It should be used for pasting the plain text from the clipboard.
  final String? plainText;

  /// The [html] is the html string.
  ///
  /// It should be used for pasting the html from the clipboard.
  /// For example, copy the content in the browser, and paste it in the editor.
  final String? html;

  /// The [image] is the image data.
  ///
  /// It should be used for pasting the image from the clipboard.
  /// For example, copy the image in the browser or other apps, and paste it in the editor.
  final (String, Uint8List?)? image;

  /// The [inAppJson] is the json string of the editor nodes.
  ///
  /// It should be used for pasting the content in-app.
  /// For example, pasting the content from document A to document B.
  final String? inAppJson;

  /// The [tableJson] is the json string of the table nodes.
  ///
  /// It only works for the table nodes when coping a row or a column.
  /// Don't use it for another scenario.
  final String? tableJson;
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
    final tableJson = data.tableJson;

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
    if (tableJson != null) {
      item.add(tableJsonFormat(tableJson));
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
      Log.info('availableFormats: $availableFormats');
    }

    final plainText = await reader.readValue(Formats.plainText);
    final html = await reader.readValue(Formats.htmlText);
    final inAppJson = await reader.readValue(inAppJsonFormat);
    final tableJson = await reader.readValue(tableJsonFormat);
    (String, Uint8List?)? image;
    if (reader.canProvide(Formats.png)) {
      image = ('png', await reader.readFile(Formats.png));
    } else if (reader.canProvide(Formats.jpeg)) {
      image = ('jpeg', await reader.readFile(Formats.jpeg));
    } else if (reader.canProvide(Formats.gif)) {
      image = ('gif', await reader.readFile(Formats.gif));
    } else if (reader.canProvide(Formats.webp)) {
      image = ('webp', await reader.readFile(Formats.webp));
    }

    return ClipboardServiceData(
      plainText: plainText,
      html: html,
      image: image,
      inAppJson: inAppJson,
      tableJson: tableJson,
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

/// The default decode function for the clipboard service.
Future<String?> _defaultDecode(Object value, String platformType) async {
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
}

/// The default encode function for the clipboard service.
Future<Object> _defaultEncode(String value, String platformType) async {
  return utf8.encode(value);
}
