import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

class LinkEmbedKeys {
  const LinkEmbedKeys._();
  static const String previewType = 'preview_type';
  static const String embed = 'embed';
}

Node linkEmbedNode({required String url}) => Node(
      type: LinkPreviewBlockKeys.type,
      attributes: {
        LinkPreviewBlockKeys.url: url,
        LinkEmbedKeys.previewType: LinkEmbedKeys.embed,
      },
    );
