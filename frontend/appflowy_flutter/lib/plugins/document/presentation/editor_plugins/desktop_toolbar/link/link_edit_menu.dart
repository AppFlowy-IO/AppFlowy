import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'link_create_menu.dart';
import 'link_search_text_field.dart';
import 'link_styles.dart';

class LinkEditMenu extends StatefulWidget {
  const LinkEditMenu({
    super.key,
    required this.linkInfo,
    required this.onDismiss,
    required this.onApply,
    required this.onRemoveLink,
  });

  final LinkInfo linkInfo;
  final ValueChanged<LinkInfo> onApply;
  final VoidCallback onRemoveLink;
  final VoidCallback onDismiss;

  @override
  State<LinkEditMenu> createState() => _LinkEditMenuState();
}

class _LinkEditMenuState extends State<LinkEditMenu> {
  ValueChanged<LinkInfo> get onApply => widget.onApply;

  VoidCallback get onRemoveLink => widget.onRemoveLink;

  VoidCallback get onDismiss => widget.onDismiss;

  late TextEditingController linkNameController =
      TextEditingController(text: linkInfo.name);
  final textFocusNode = FocusNode();
  late LinkInfo linkInfo = widget.linkInfo;
  late LinkSearchTextField searchTextField;
  bool isShowingSearchResult = false;
  ViewPB? currentView;

  bool get enableApply =>
      linkNameController.text.isNotEmpty &&
      searchTextField.isButtonEnable &&
      !isShowingSearchResult;

  @override
  void initState() {
    super.initState();
    final isPageLink = linkInfo.isPage;
    if (isPageLink) getPageView();
    searchTextField = LinkSearchTextField(
      initialSearchText: isPageLink ? '' : linkInfo.link,
      onEnter: () {
        searchTextField.onSearchResult(
          onLink: onLinkSelected,
          onRecentViews: () =>
              onPageSelected(searchTextField.currentRecentView),
          onSearchViews: () =>
              onPageSelected(searchTextField.currentSearchedView),
          onEmpty: () {
            searchTextField.unfocus();
          },
        );
      },
      onEscape: () {
        if (isShowingSearchResult) {
          hideSearchResult();
        } else {
          onDismiss();
        }
      },
      onDataRefresh: () {
        if (mounted) setState(() {});
      },
    )..searchRecentViews();
  }

  @override
  void dispose() {
    linkNameController.dispose();
    textFocusNode.dispose();
    searchTextField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showingRecent =
        searchTextField.showingRecent && isShowingSearchResult;
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        width: 400,
        height: 250 + (showingRecent ? 32 : 0),
        color: Colors.white.withAlpha(1),
        child: Stack(
          children: [
            GestureDetector(
              onTap: hideSearchResult,
              child: Container(
                width: 400,
                height: 192,
                decoration: buildToolbarLinkDecoration(context),
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              ),
            ),
            Positioned(
              top: 16,
              left: 20,
              child: FlowyText.semibold(
                LocaleKeys.document_toolbar_pageOrURL.tr(),
                color: LinkStyle.textTertiary,
                fontSize: 12,
                figmaLineHeight: 16,
              ),
            ),
            Positioned(
              top: 80,
              left: 20,
              child: FlowyText.semibold(
                LocaleKeys.document_toolbar_linkName.tr(),
                color: LinkStyle.textTertiary,
                fontSize: 12,
                figmaLineHeight: 16,
              ),
            ),
            Positioned(
              top: 152,
              left: 20,
              child: buildButtons(),
            ),
            Positioned(
              top: 100,
              left: 20,
              child: buildNameTextField(),
            ),
            Positioned(
              top: 36,
              left: 20,
              child: buildLinkField(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLinkField() {
    final showPageView = linkInfo.isPage && !isShowingSearchResult;
    if (showPageView) return buildPageView();
    if (!isShowingSearchResult) return buildLinkView();
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            height: 32,
            child: searchTextField.buildTextField(
              autofocus: true,
            ),
          ),
          VSpace(6),
          searchTextField.buildResultContainer(
            context: context,
            width: 360,
            onPageLinkSelected: onPageSelected,
            onLinkSelected: onLinkSelected,
          ),
        ],
      ),
    );
  }

  Widget buildButtons() {
    return GestureDetector(
      onTap: hideSearchResult,
      child: SizedBox(
        width: 360,
        height: 32,
        child: Row(
          children: [
            FlowyIconButton(
              icon: FlowySvg(FlowySvgs.toolbar_link_unlink_m),
              width: 32,
              height: 32,
              tooltipText: LocaleKeys.editor_removeLink.tr(),
              preferBelow: false,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: LinkStyle.borderColor),
              ),
              onPressed: onRemoveLink,
            ),
            Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: LinkStyle.borderColor),
              ),
              child: FlowyTextButton(
                LocaleKeys.button_cancel.tr(),
                padding: EdgeInsets.zero,
                mainAxisAlignment: MainAxisAlignment.center,
                constraints: BoxConstraints(maxWidth: 78, minHeight: 32),
                fontSize: 14,
                lineHeight: 20 / 14,
                fontColor: Theme.of(context).isLightMode
                    ? LinkStyle.textPrimary
                    : Theme.of(context).iconTheme.color,
                fillColor: Colors.transparent,
                fontWeight: FontWeight.w400,
                onPressed: onDismiss,
              ),
            ),
            HSpace(12),
            ValueListenableBuilder(
              valueListenable: linkNameController,
              builder: (context, _, __) {
                final isLight = Theme.of(context).isLightMode;
                return FlowyTextButton(
                  LocaleKeys.settings_appearance_documentSettings_apply.tr(),
                  padding: EdgeInsets.zero,
                  mainAxisAlignment: MainAxisAlignment.center,
                  constraints: BoxConstraints(maxWidth: 78, minHeight: 32),
                  fontSize: 14,
                  lineHeight: 20 / 14,
                  hoverColor: LinkStyle.fillThemeThick.withAlpha(200),
                  fontColor: enableApply || !isLight
                      ? Colors.white
                      : LinkStyle.textTertiary,
                  fillColor: enableApply
                      ? LinkStyle.fillThemeThick
                      : LinkStyle.borderColor.withAlpha(isLight ? 255 : 122),
                  fontWeight: FontWeight.w400,
                  onPressed:
                      enableApply ? () => widget.onApply.call(linkInfo) : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNameTextField() {
    return SizedBox(
      width: 360,
      height: 32,
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        focusNode: textFocusNode,
        textAlign: TextAlign.left,
        controller: linkNameController,
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w400,
        ),
        onChanged: (text) {
          linkInfo = LinkInfo(
            name: text,
            link: linkInfo.link,
            isPage: linkInfo.isPage,
          );
        },
        decoration: LinkStyle.buildLinkTextFieldInputDecoration(
          LocaleKeys.document_toolbar_linkNameHint.tr(),
        ),
      ),
    );
  }

  Widget buildPageView() {
    late Widget child;
    final view = currentView;
    if (view == null) {
      child = Center(
        child: SizedBox.fromSize(
          size: Size(10, 10),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      final viewName = view.name;
      final displayName = viewName.isEmpty
          ? LocaleKeys.document_title_placeholder.tr()
          : viewName;
      child = GestureDetector(
        onTap: showSearchResult,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: 32,
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              children: [
                searchTextField.buildIcon(view),
                HSpace(4),
                Flexible(
                  child: FlowyText.regular(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    figmaLineHeight: 20,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      width: 360,
      height: 32,
      decoration: buildDecoration(),
      child: child,
    );
  }

  Widget buildLinkView() {
    return Container(
      width: 360,
      height: 32,
      decoration: buildDecoration(),
      child: GestureDetector(
        onTap: showSearchResult,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                FlowySvg(FlowySvgs.toolbar_link_earth_m),
                HSpace(8),
                Flexible(
                  child: FlowyText.regular(
                    linkInfo.link,
                    overflow: TextOverflow.ellipsis,
                    figmaLineHeight: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getPageView() async {
    if (!linkInfo.isPage) return;
    final link = linkInfo.link;
    final viewId = link.split('/').lastOrNull ?? '';
    final (view, isInTrash, isDeleted) =
        await ViewBackendService.getMentionPageStatus(viewId);
    if (mounted) {
      setState(() {
        currentView = view;
      });
    }
  }

  void showSearchResult() {
    setState(() {
      if (linkInfo.isPage) searchTextField.updateText('');
      isShowingSearchResult = true;
      searchTextField.requestFocus();
    });
  }

  void hideSearchResult() {
    setState(() {
      isShowingSearchResult = false;
      searchTextField.unfocus();
      textFocusNode.unfocus();
    });
  }

  void onLinkSelected() {
    if (mounted) {
      linkInfo = LinkInfo(
        name: linkInfo.name,
        link: searchTextField.searchText,
      );
      hideSearchResult();
    }
  }

  Future<void> onPageSelected(ViewPB view) async {
    currentView = view;
    final link = ShareConstants.buildShareUrl(
      workspaceId: await UserBackendService.getCurrentWorkspace().fold(
        (s) => s.id,
        (f) => '',
      ),
      viewId: view.id,
    );
    linkInfo = LinkInfo(
      name: linkInfo.name,
      link: link,
      isPage: true,
    );
    searchTextField.updateText(linkInfo.link);
    if (mounted) {
      setState(() {
        isShowingSearchResult = false;
        searchTextField.unfocus();
      });
    }
  }

  BoxDecoration buildDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LinkStyle.borderColor),
      );
}

class LinkInfo {
  LinkInfo({this.isPage = false, required this.name, required this.link});

  final bool isPage;
  final String name;
  final String link;

  Attributes toAttribute() =>
      {AppFlowyRichTextKeys.href: link, kIsPageLink: isPage};
}
