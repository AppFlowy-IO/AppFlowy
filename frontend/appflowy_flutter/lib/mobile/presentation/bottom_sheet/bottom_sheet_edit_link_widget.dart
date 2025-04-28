import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_header.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_edit_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_search_text_field.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_styles.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/util/link_util.dart';

class MobileBottomSheetEditLinkWidget extends StatefulWidget {
  const MobileBottomSheetEditLinkWidget({
    super.key,
    required this.linkInfo,
    required this.onApply,
    required this.onRemoveLink,
    required this.currentViewId,
    required this.onDispose,
  });

  final LinkInfo linkInfo;
  final ValueChanged<LinkInfo> onApply;
  final ValueChanged<LinkInfo> onRemoveLink;
  final VoidCallback onDispose;
  final String currentViewId;

  @override
  State<MobileBottomSheetEditLinkWidget> createState() =>
      _MobileBottomSheetEditLinkWidgetState();
}

class _MobileBottomSheetEditLinkWidgetState
    extends State<MobileBottomSheetEditLinkWidget> {
  ValueChanged<LinkInfo> get onApply => widget.onApply;

  ValueChanged<LinkInfo> get onRemoveLink => widget.onRemoveLink;

  late TextEditingController linkNameController =
      TextEditingController(text: linkInfo.name);
  final textFocusNode = FocusNode();
  late LinkInfo linkInfo = widget.linkInfo;
  late LinkSearchTextField searchTextField;
  bool isShowingSearchResult = false;
  ViewPB? currentView;
  bool showErrorText = false;
  bool showRemoveLink = false;

  AppFlowyThemeData get theme => AppFlowyTheme.of(context);

  @override
  void initState() {
    super.initState();
    final isPageLink = linkInfo.isPage;
    if (isPageLink) getPageView();
    searchTextField = LinkSearchTextField(
      initialSearchText: isPageLink ? '' : linkInfo.link,
      initialViewId: linkInfo.viewId,
      currentViewId: widget.currentViewId,
      onEnter: () {},
      onEscape: () {},
      onDataRefresh: () {
        if (mounted) setState(() {});
      },
    )..searchRecentViews();
    if (linkInfo.link.isEmpty) {
      isShowingSearchResult = true;
    } else {
      showRemoveLink = true;
      textFocusNode.requestFocus();
    }
    textFocusNode.addListener(() {
      if (!mounted) return;
      if (textFocusNode.hasFocus) {
        setState(() {
          isShowingSearchResult = false;
        });
      }
    });
  }

  @override
  void dispose() {
    linkNameController.dispose();
    textFocusNode.dispose();
    searchTextField.dispose();
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: SingleChildScrollView(
        child: Column(
          children: [
            BottomSheetHeader(
              title: LocaleKeys.editor_editLink.tr(),
              onClose: () => context.pop(),
              confirmButton: FlowyTextButton(
                LocaleKeys.button_done.tr(),
                constraints:
                    const BoxConstraints.tightFor(width: 62, height: 30),
                padding: const EdgeInsets.only(left: 12),
                fontColor: theme.textColorScheme.onFill,
                fillColor: Theme.of(context).primaryColor,
                onPressed: () {
                  if (isShowingSearchResult) {
                    onConfirm();
                    return;
                  }
                  if (linkInfo.link.isEmpty || !isUri(linkInfo.link)) {
                    setState(() {
                      showErrorText = true;
                    });
                    return;
                  }
                  widget.onApply.call(linkInfo);
                  context.pop();
                },
              ),
            ),
            const VSpace(20.0),
            buildNameTextField(),
            const VSpace(16.0),
            buildLinkField(),
            const VSpace(20.0),
            buildRemoveLink(),
          ],
        ),
      ),
    );
  }

  Widget buildNameTextField() {
    return SizedBox(
      height: 48,
      child: TextFormField(
        focusNode: textFocusNode,
        textAlign: TextAlign.left,
        controller: linkNameController,
        style: TextStyle(
          fontSize: 16,
          height: 20 / 16,
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
          contentPadding: EdgeInsets.all(14),
          radius: 12,
          context,
        ),
      ),
    );
  }

  Widget buildLinkField() {
    final width = MediaQuery.of(context).size.width;
    final showPageView = linkInfo.isPage && !isShowingSearchResult;
    Widget child;
    if (showPageView) {
      child = buildPageView();
    } else if (!isShowingSearchResult) {
      child = buildLinkView();
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchTextField.buildTextField(
            autofocus: true,
            context: context,
            contentPadding: EdgeInsets.all(14),
            textStyle: TextStyle(
              fontSize: 16,
              height: 20 / 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          VSpace(6),
          searchTextField.buildResultContainer(
            context: context,
            onPageLinkSelected: onPageSelected,
            onLinkSelected: onLinkSelected,
            width: width - 32,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (showErrorText)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FlowyText.regular(
              LocaleKeys.document_plugins_file_networkUrlInvalid.tr(),
              color: theme.textColorScheme.error,
              fontSize: 12,
              figmaLineHeight: 16,
            ),
          ),
      ],
    );
  }

  Widget buildPageView() {
    final height = 48.0;
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
        child: Container(
          height: height,
          color: Colors.grey.withAlpha(1),
          padding: EdgeInsets.all(14),
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
      );
    }
    return Container(
      height: height,
      decoration: buildBorderDecoration(),
      child: child,
    );
  }

  Widget buildLinkView() {
    return Container(
      height: 48,
      decoration: buildBorderDecoration(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: showSearchResult,
        child: Padding(
          padding: EdgeInsets.all(12),
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
    );
  }

  Widget buildRemoveLink() {
    if (!showRemoveLink) return SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onRemoveLink(linkInfo);
        context.pop();
      },
      child: SizedBox(
        height: 32,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlowySvg(
                FlowySvgs.mobile_icon_remove_link_m,
                color: theme.iconColorScheme.secondary,
              ),
              HSpace(8),
              FlowyText.regular(
                LocaleKeys.editor_removeLink.tr(),
                overflow: TextOverflow.ellipsis,
                figmaLineHeight: 20,
                color: theme.textColorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onConfirm() {
    searchTextField.onSearchResult(
      onLink: onLinkSelected,
      onRecentViews: () => onPageSelected(searchTextField.currentRecentView),
      onSearchViews: () => onPageSelected(searchTextField.currentSearchedView),
      onEmpty: () {
        searchTextField.unfocus();
      },
    );
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

  void onLinkSelected() {
    if (mounted) {
      linkInfo = LinkInfo(
        name: linkInfo.name,
        link: searchTextField.searchText,
      );
      hideSearchResult();
    }
  }

  void hideSearchResult() {
    setState(() {
      isShowingSearchResult = false;
      searchTextField.unfocus();
      textFocusNode.unfocus();
    });
  }

  void showSearchResult() {
    setState(() {
      if (linkInfo.isPage) searchTextField.updateText('');
      isShowingSearchResult = true;
      searchTextField.requestFocus();
    });
  }

  Future<void> getPageView() async {
    if (!linkInfo.isPage) return;
    final (view, isInTrash, isDeleted) =
        await ViewBackendService.getMentionPageStatus(linkInfo.viewId);
    if (mounted) {
      setState(() {
        currentView = view;
      });
    }
  }

  BoxDecoration buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(theme.borderRadius.l),
      boxShadow: theme.shadow.medium,
    );
  }

  BoxDecoration buildBorderDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(theme.borderRadius.l),
      border: Border.all(color: theme.borderColorScheme.greyPrimary),
    );
  }
}
