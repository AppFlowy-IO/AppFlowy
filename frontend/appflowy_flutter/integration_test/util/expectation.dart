import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/cover_node_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/emoji_icon_widget.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const String readme = 'Read me';

extension Expectation on WidgetTester {
  /// Expect to see the home page and with a default read me page.
  void expectToSeeHomePage() {
    expect(find.byType(HomeStack), findsOneWidget);
    expect(find.textContaining(readme), findsWidgets);
  }

  /// Expect to see the page name on the home page.
  void expectToSeePageName(String name) {
    final pageName = findPageName(name);
    expect(pageName, findsOneWidget);
  }

  /// Expect not to see the page name on the home page.
  void expectNotToSeePageName(String name) {
    final pageName = findPageName(name);
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

  /// Expect to see the cover toolbar empty
  void expectNotToSeeAddCoverAndIconButton() {
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

  void expectToSeeDocumentCover(CoverType type, String details) {
    Finder findCover;
    switch (type) {
      case CoverType.asset:
        findCover = find.image(AssetImage(details));
        break;
      case CoverType.color:
        final color = details.toColor();
        findCover = find.byWidgetPredicate(
          (widget) => widget is Container && widget.color == color,
        );
      default:
        return;
    }
    expect(findCover, findsOneWidget);
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

  /// Find the page name on the home page.
  Finder findPageName(String name) {
    return find.byWidgetPredicate(
      (widget) => widget is ViewSectionItem && widget.view.name == name,
      skipOffstage: false,
    );
  }
}
