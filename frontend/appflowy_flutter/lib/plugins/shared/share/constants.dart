import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';

class ShareConstants {
  static const String testBaseWebDomain = 'test.appflowy.com';
  static const String defaultBaseWebDomain = 'https://appflowy.com';

  static String buildPublishUrl({
    required String nameSpace,
    required String publishName,
  }) {
    final baseShareDomain =
        getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_web_domain;
    final url = '$baseShareDomain/$nameSpace/$publishName'.addSchemaIfNeeded();
    return url;
  }

  static String buildNamespaceUrl({
    required String nameSpace,
    bool withHttps = false,
  }) {
    final baseShareDomain =
        getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_web_domain;
    String url = baseShareDomain.addSchemaIfNeeded();
    if (!withHttps) {
      url = url.replaceFirst('https://', '');
    }
    return '$url/$nameSpace';
  }

  static String buildShareUrl({
    required String workspaceId,
    required String viewId,
    String? blockId,
  }) {
    final baseShareDomain =
        getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_web_domain;
    final url = '$baseShareDomain/app/$workspaceId/$viewId'.addSchemaIfNeeded();
    if (blockId == null || blockId.isEmpty) {
      return url;
    }
    return '$url?blockId=$blockId';
  }
}

extension on String {
  String addSchemaIfNeeded() {
    final schema = Uri.parse(this).scheme;
    // if the schema is empty, add https schema by default
    if (schema.isEmpty) {
      return 'https://$this';
    }
    return this;
  }
}
