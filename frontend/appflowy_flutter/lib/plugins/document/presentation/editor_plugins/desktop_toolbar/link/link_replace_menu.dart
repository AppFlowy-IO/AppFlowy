import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/menu/menu_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/util/link_util.dart';
import 'package:flutter/services.dart';

import 'link_create_menu.dart';
import 'link_styles.dart';

void showReplaceMenu({
  required BuildContext context,
  required EditorState editorState,
  required Node node,
  String? url,
  required LTRB ltrb,
  required ValueChanged<String> onReplace,
}) {
  OverlayEntry? overlay;

  void dismissOverlay() {
    keepEditorFocusNotifier.decrease();
    overlay?.remove();
    overlay = null;
  }

  keepEditorFocusNotifier.increase();
  overlay = FullScreenOverlayEntry(
    top: ltrb.top,
    bottom: ltrb.bottom,
    left: ltrb.left,
    right: ltrb.right,
    dismissCallback: () => keepEditorFocusNotifier.decrease(),
    builder: (context) {
      return LinkReplaceMenu(
        link: url ?? '',
        onSubmitted: (link) async {
          onReplace.call(link);
          dismissOverlay();
        },
        onDismiss: dismissOverlay,
      );
    },
  ).build();

  Overlay.of(context, rootOverlay: true).insert(overlay!);
}

class LinkReplaceMenu extends StatefulWidget {
  const LinkReplaceMenu({
    super.key,
    required this.onSubmitted,
    required this.link,
    required this.onDismiss,
  });

  final ValueChanged<String> onSubmitted;
  final VoidCallback onDismiss;
  final String link;

  @override
  State<LinkReplaceMenu> createState() => _LinkReplaceMenuState();
}

class _LinkReplaceMenuState extends State<LinkReplaceMenu> {
  bool showErrorText = false;
  late FocusNode focusNode = FocusNode(onKeyEvent: onKeyEvent);
  late TextEditingController textEditingController =
      TextEditingController(text: widget.link);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: EdgeInsets.all(8),
      decoration: buildToolbarLinkDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: buildLinkField()),
          HSpace(8),
          buildReplaceButton(),
        ],
      ),
    );
  }

  Widget buildLinkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            autofocus: true,
            focusNode: focusNode,
            textAlign: TextAlign.left,
            controller: textEditingController,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: LinkStyle.buildLinkTextFieldInputDecoration(
              LocaleKeys.document_plugins_linkPreview_linkPreviewMenu_pasteHint
                  .tr(),
              context,
              showErrorBorder: showErrorText,
            ),
          ),
        ),
        if (showErrorText)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FlowyText.regular(
              LocaleKeys.document_plugins_file_networkUrlInvalid.tr(),
              color: LinkStyle.textStatusError,
              fontSize: 12,
              figmaLineHeight: 16,
            ),
          ),
      ],
    );
  }

  Widget buildReplaceButton() {
    return FlowyTextButton(
      LocaleKeys.button_replace.tr(),
      padding: EdgeInsets.zero,
      mainAxisAlignment: MainAxisAlignment.center,
      constraints: BoxConstraints(maxWidth: 78, minHeight: 32),
      fontSize: 14,
      lineHeight: 20 / 14,
      hoverColor: LinkStyle.fillThemeThick.withAlpha(200),
      fontColor: Colors.white,
      fillColor: LinkStyle.fillThemeThick,
      fontWeight: FontWeight.w400,
      onPressed: onSubmit,
    );
  }

  void onSubmit() {
    final link = textEditingController.text.trim();
    if (link.isEmpty || !isUri(link)) {
      setState(() {
        showErrorText = true;
      });
      return;
    }
    widget.onSubmitted.call(link);
  }

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent key) {
    if (key is! KeyDownEvent) return KeyEventResult.ignored;
    if (key.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss.call();
      return KeyEventResult.handled;
    } else if (key.logicalKey == LogicalKeyboardKey.enter) {
      onSubmit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
