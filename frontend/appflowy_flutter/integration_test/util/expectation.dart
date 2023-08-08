import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/document_header_node_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// const String readme = 'Read me';
const String gettingStarted = '⭐️ Getting started';

extension Expectation on WidgetTester {
  /// Expect to see the home page and with a default read me page.
  void expectToSeeHomePage() {
    expect(find.byType(HomeStack), findsOneWidget);
    expect(find.textContaining(gettingStarted), findsWidgets);
  }

  /// Expect to see the page name on the home page.
  void expectToSeePageName(
    String name, {
    String? parentName,
    ViewLayoutPB layout = ViewLayoutPB.Document,
    ViewLayoutPB parentLayout = ViewLayoutPB.Document,
  }) {
    final pageName = findPageName(
      name,
      layout: layout,
      parentName: parentName,
      parentLayout: parentLayout,
    );
    expect(pageName, findsOneWidget);
  }

  /// Expect not to see the page name on the home page.
  void expectNotToSeePageName(
    String name, {
    String? parentName,
    ViewLayoutPB layout = ViewLayoutPB.Document,
    ViewLayoutPB parentLayout = ViewLayoutPB.Document,
  }) {
    final pageName = findPageName(
      name,
      layout: layout,
      parentName: parentName,
      parentLayout: parentLayout,
    );
    expect(pageName, findsNothing);
  }

  /// Expect to see the document banner.
  void expectToSeeDocumentBanner() {
    expect(find.byType(DocumentBanner), findsOneWidget);
  }

  /// Expect not to see the document banner.
  void expectNotToSeeDocumentBanner() {
    expect(find.byType(DocumentBanner), findsNothing);
  }

  /// Expect to the markdown file export success dialog.
  void expectToExportSuccess() {
    final exportSuccess = find.byWidgetPredicate(
      (widget) =>
          widget is FlowyText &&
          widget.text == LocaleKeys.settings_files_exportFileSuccess.tr(),
    );
    expect(exportSuccess, findsOneWidget);
  }

  /// Expect to see the add button and icon button in the cover toolbar
  void expectToSeePluginAddCoverAndIconButton() {
    final addCover = find.textContaining(
      LocaleKeys.document_plugins_cover_addCover.tr(),
    );
    final addIcon = find.textContaining(
      LocaleKeys.document_plugins_cover_addIcon.tr(),
    );
    expect(addCover, findsOneWidget);
    expect(addIcon, findsOneWidget);
  }

  /// Expect to see the document header toolbar empty
  void expectToSeeEmptyDocumentHeaderToolbar() {
    final addCover = find.textContaining(
      LocaleKeys.document_plugins_cover_addCover.tr(),
    );
    final addIcon = find.textContaining(
      LocaleKeys.document_plugins_cover_addIcon.tr(),
    );
    expect(addCover, findsNothing);
    expect(addIcon, findsNothing);
  }

  void expectToSeeDocumentIcon(String? emoji) {
    if (emoji == null) {
      final iconWidget = find.byType(EmojiIconWidget);
      expect(iconWidget, findsNothing);
      return;
    }
    final iconWidget = find.byWidgetPredicate(
      (widget) => widget is EmojiIconWidget && widget.emoji == emoji,
    );
    expect(iconWidget, findsOneWidget);
  }

  void expectToSeeDocumentCover(CoverType type) {
    final findCover = find.byWidgetPredicate(
      (widget) => widget is DocumentCover && widget.coverType == type,
    );
    expect(findCover, findsOneWidget);
  }

  void expectToSeeNoDocumentCover() {
    final findCover = find.byType(DocumentCover);
    expect(findCover, findsNothing);
  }

  void expectChangeCoverAndDeleteButton() {
    final findChangeCover = find.text(
      LocaleKeys.document_plugins_cover_changeCover.tr(),
    );
    final findRemoveIcon = find.byType(DeleteCoverButton);
    expect(findChangeCover, findsOneWidget);
    expect(findRemoveIcon, findsOneWidget);
  }

  /// Expect to see the user name on the home page
  void expectToSeeUserName(String name) {
    final userName = find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.text == name,
    );
    expect(userName, findsOneWidget);
  }

  /// Expect to see a text
  void expectToSeeText(String text) {
    Finder textWidget = find.textContaining(text, findRichText: true);
    if (textWidget.evaluate().isEmpty) {
      textWidget = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == text,
      );
    }
    expect(textWidget, findsOneWidget);
  }

  /// Find if the page is favorite
  Finder findFavoritePageName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
    String? parentName,
    ViewLayoutPB parentLayout = ViewLayoutPB.Document,
  }) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is ViewItem &&
          widget.view.isFavorite &&
          widget.categoryType == FolderCategoryType.favorite &&
          widget.view.name == name &&
          widget.view.layout == layout,
      skipOffstage: false,
    );
  }

  Finder findPageName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
    String? parentName,
    ViewLayoutPB parentLayout = ViewLayoutPB.Document,
  }) {
    if (parentName == null) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is SingleInnerViewItem &&
            widget.view.name == name &&
            widget.view.layout == layout,
        skipOffstage: false,
      );
    }

    return find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is ViewItem &&
            widget.view.name == parentName &&
            widget.view.layout == parentLayout,
        skipOffstage: false,
      ),
      matching: findPageName(name, layout: layout),
    );
  }
}
