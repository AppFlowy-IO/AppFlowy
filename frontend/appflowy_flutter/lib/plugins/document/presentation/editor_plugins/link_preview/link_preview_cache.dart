import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

class LinkPreviewDataCache implements LinkPreviewDataCacheInterface {
  @override
  Future<LinkPreviewData?> get(String url) async {
    final option =
        await getIt<KeyValueStorage>().getWithFormat<LinkPreviewData?>(
      url,
      (value) => LinkPreviewData.fromJson(jsonDecode(value)),
    );
    return option;
  }

  @override
  Future<void> set(String url, LinkPreviewData data) async {
    await getIt<KeyValueStorage>().set(
      url,
      jsonEncode(data.toJson()),
    );
  }
}
