import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class CustomLinkPreviewWidget extends StatelessWidget {
  const CustomLinkPreviewWidget({
    super.key,
    required this.node,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  final Node node;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;

  @override
  Widget build(BuildContext context) {
    final documentFontSize = context
            .read<EditorState>()
            .editorStyle
            .textStyleConfiguration
            .text
            .fontSize ??
        16.0;
    final (fontSize, width) = UniversalPlatform.isDesktopOrWeb
        ? (documentFontSize, 180.0)
        : (documentFontSize - 2, 120.0);
    final Widget child = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        borderRadius: BorderRadius.circular(
          6.0,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6.0),
                  bottomLeft: Radius.circular(6.0),
                ),
                child: FlowyNetworkImage(
                  url: imageUrl!,
                  width: width,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 4.0,
                          right: 10.0,
                        ),
                        child: FlowyText.medium(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fontSize: fontSize,
                        ),
                      ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: FlowyText(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fontSize: fontSize - 4,
                        ),
                      ),
                    FlowyText(
                      url.toString(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      color: Theme.of(context).hintColor,
                      fontSize: fontSize - 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (UniversalPlatform.isDesktopOrWeb) {
      return InkWell(
        onTap: () => afLaunchUrlString(url),
        child: child,
      );
    }

    return MobileBlockActionButtons(
      node: node,
      editorState: context.read<EditorState>(),
      extendActionWidgets: _buildExtendActionWidgets(context),
      child: child,
    );
  }

  // only used on mobile platform
  List<Widget> _buildExtendActionWidgets(BuildContext context) {
    return [
      FlowyOptionTile.text(
        showTopBorder: false,
        text: LocaleKeys.document_plugins_urlPreview_convertToLink.tr(),
        leftIcon: const FlowySvg(
          FlowySvgs.m_aa_link_s,
          size: Size.square(20),
        ),
        onTap: () {
          context.pop();
          convertUrlPreviewNodeToLink(
            context.read<EditorState>(),
            node,
          );
        },
      ),
    ];
  }
}
