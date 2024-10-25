class ShareConstants {
  static const String publishBaseUrl = 'test.appflowy.com';
  static const String shareBaseUrl = 'test.appflowy.com/app';

  static String buildPublishUrl({
    required String nameSpace,
    required String publishName,
  }) {
    return 'https://$publishBaseUrl/$nameSpace/$publishName';
  }

  static String buildNamespaceUrl({
    required String nameSpace,
  }) {
    return '$publishBaseUrl/$nameSpace';
  }

  static String buildShareUrl({
    required String workspaceId,
    required String viewId,
    String? blockId,
  }) {
    final url = 'https://$shareBaseUrl/$workspaceId/$viewId';
    if (blockId == null || blockId.isEmpty) {
      return url;
    }
    return 'https://$url?blockId=$blockId';
  }
}
