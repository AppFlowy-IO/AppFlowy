class ShareConstants {
  static const String publishBaseUrl = 'https://appflowy.com';
  static const String shareBaseUrl = 'https://appflowy.com/app';

  static String buildPublishUrl({
    required String nameSpace,
    required String publishName,
  }) {
    return '$publishBaseUrl/$nameSpace/$publishName';
  }

  static String buildNamespaceUrl({
    required String nameSpace,
  }) {
    return '$publishBaseUrl/$nameSpace'
        .replaceAll('https://', '')
        .replaceAll('http://', '');
  }

  static String buildShareUrl({
    required String workspaceId,
    required String viewId,
    String? blockId,
  }) {
    final url = '$shareBaseUrl/$workspaceId/$viewId';
    if (blockId == null || blockId.isEmpty) {
      return url;
    }
    return '$url?blockId=$blockId';
  }
}
