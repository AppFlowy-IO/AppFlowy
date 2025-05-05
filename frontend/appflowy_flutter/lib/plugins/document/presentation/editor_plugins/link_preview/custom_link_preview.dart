import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

import 'custom_link_parser.dart';

class CustomLinkPreviewWidget extends StatelessWidget {
  const CustomLinkPreviewWidget({
    super.key,
    required this.node,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.isHovering = false,
    this.status = LinkLoadingStatus.loading,
  });

  final Node node;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;
  final bool isHovering;
  final LinkLoadingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context),
        borderScheme = theme.borderColorScheme,
        textScheme = theme.textColorScheme;
    final documentFontSize = context
            .read<EditorState>()
            .editorStyle
            .textStyleConfiguration
            .text
            .fontSize ??
        16.0;
    final isInDarkCallout = node.parent?.type == CalloutBlockKeys.type &&
        !Theme.of(context).isLightMode;
    final (fontSize, width) = UniversalPlatform.isDesktopOrWeb
        ? (documentFontSize, 160.0)
        : (documentFontSize - 2, 120.0);
    final Widget child = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(
          color: isHovering || isInDarkCallout
              ? borderScheme.greyTertiaryHover
              : borderScheme.greyTertiary,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildImage(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 58, 12),
                child: status != LinkLoadingStatus.idle
                    ? buildLoadingOrErrorWidget()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (title != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: FlowyText.medium(
                                title!,
                                overflow: TextOverflow.ellipsis,
                                fontSize: fontSize,
                                color: textScheme.primary,
                                figmaLineHeight: 20,
                              ),
                            ),
                          if (description != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: FlowyText(
                                description!,
                                overflow: TextOverflow.ellipsis,
                                fontSize: fontSize - 4,
                                figmaLineHeight: 16,
                                color: textScheme.primary,
                              ),
                            ),
                          FlowyText(
                            url.toString(),
                            overflow: TextOverflow.ellipsis,
                            color: textScheme.secondary,
                            fontSize: fontSize - 4,
                            figmaLineHeight: 16,
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
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => afLaunchUrlString(url, addingHttpSchemeWhenFailed: true),
          child: child,
        ),
      );
    }

    return MobileBlockActionButtons(
      node: node,
      editorState: context.read<EditorState>(),
      extendActionWidgets: _buildExtendActionWidgets(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => afLaunchUrlString(url, addingHttpSchemeWhenFailed: true),
        child: child,
      ),
    );
  }

  // only used on mobile platform
  List<Widget> _buildExtendActionWidgets(BuildContext context) {
    return [
      FlowyOptionTile.text(
        showTopBorder: false,
        text: LocaleKeys.document_plugins_urlPreview_convertToLink.tr(),
        leftIcon: const FlowySvg(
          FlowySvgs.m_toolbar_link_m,
          size: Size.square(18),
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

  Widget buildImage(BuildContext context) {
    if (imageUrl?.isEmpty ?? true) {
      return SizedBox.shrink();
    }
    final theme = AppFlowyTheme.of(context),
        fillScheme = theme.fillColorScheme,
        iconScheme = theme.iconColorScheme;
    final width = UniversalPlatform.isDesktopOrWeb ? 160.0 : 120.0;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16.0),
        bottomLeft: Radius.circular(16.0),
      ),
      child: Container(
        width: width,
        color: fillScheme.quaternary,
        child: FlowyNetworkImage(
          url: imageUrl!,
          width: width,
          errorWidgetBuilder: (_, __, ___) => Center(
            child: FlowySvg(
              FlowySvgs.toolbar_link_earth_m,
              color: iconScheme.secondary,
              size: Size.square(30),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoadingOrErrorWidget() {
    if (status == LinkLoadingStatus.loading) {
      return const Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    } else if (status == LinkLoadingStatus.error) {
      return const Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }
}
