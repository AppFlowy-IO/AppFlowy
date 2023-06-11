import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/banner.dart';
import 'package:appflowy/plugins/document/presentation/share/share_button.dart';
import 'package:appflowy/user/presentation/skip_log_in_screen.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

const String readme = 'Read me';

extension CommonOperations on WidgetTester {
  Future<void> tapGoButton() async {
    final goButton = find.byType(GoButton);
    await tapButton(goButton);
  }

  Future<void> tapCreateButton() async {
    await tapButtonWithName(LocaleKeys.settings_files_create.tr());
  }

  void expectToSeeWelcomePage() {
    expect(find.byType(HomeStack), findsOneWidget);
    expect(find.textContaining('Read me'), findsOneWidget);
  }

  Future<void> tapAddButton() async {
    final addButton = find.byType(AddButton);
    await tapButton(addButton);
  }

  Future<void> tapCreateDocumentButton() async {
    await tapButtonWithName(LocaleKeys.document_menuName.tr());
  }

  Finder findPageName(String name) {
    return find.byWidgetPredicate(
      (widget) => widget is ViewSectionItem && widget.view.name == name,
    );
  }

  void expectToSeePageName(String name) {
    final pageName = findPageName(name);
    expect(pageName, findsOneWidget);
  }

  void expectNotToSeePageName(String name) {
    final pageName = findPageName(name);
    expect(pageName, findsNothing);
  }

  Future<void> hoverOnPageName(String name) async {
    final pageName = find.byWidgetPredicate(
      (widget) => widget is ViewSectionItem && widget.view.name == name,
    );

    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await pump();
    await gesture.moveTo(getCenter(pageName));
    await pumpAndSettle();
  }

  Future<void> tapPageOptionButton() async {
    final optionButton = find.byType(ViewDisclosureButton);
    await tapButton(optionButton);
  }

  Future<void> tapDeletePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewDisclosureAction.delete.name);
  }

  void expectToSeeDocumentBanner() {
    expect(find.byType(DocumentBanner), findsOneWidget);
  }

  void expectNotToSeeDocumentBanner() {
    expect(find.byType(DocumentBanner), findsNothing);
  }

  Future<void> tapRestoreButton() async {
    final restoreButton = find.textContaining(
      LocaleKeys.deletePagePrompt_restore.tr(),
    );
    await tapButton(restoreButton);
  }

  Future<void> tapDeletePermanentlyButton() async {
    final restoreButton = find.textContaining(
      LocaleKeys.deletePagePrompt_deletePermanent.tr(),
    );
    await tapButton(restoreButton);
  }

  Future<void> tapShareButton() async {
    final shareButton = find.byWidgetPredicate(
      (widget) => widget is DocumentShareButton,
    );
    await tapButton(shareButton);
  }

  Future<void> tapMarkdownButton() async {
    final markdownButton = find.textContaining(
      LocaleKeys.shareAction_markdown.tr(),
    );
    await tapButton(markdownButton);
  }

  void expectToExportSuccess() {
    final exportSuccess = find.byWidgetPredicate(
      (widget) =>
          widget is FlowyText &&
          widget.title == LocaleKeys.settings_files_exportFileSuccess.tr(),
    );
    expect(exportSuccess, findsOneWidget);
  }

  Future<void> hoverOnCoverPluginAddButton() async {
    final editor = find.byWidgetPredicate(
      (widget) => widget is AppFlowyEditor,
    );

    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await pump();
    final topLeft = getTopLeft(editor).translate(20, 20);
    await gesture.moveTo(topLeft);
    await pumpAndSettle();
  }

  Future<void> expectToSeePluginAddCoverAndIconButton() async {
    final addCover = find.textContaining(
      LocaleKeys.document_plugins_cover_addCover.tr(),
    );
    final addIcon = find.textContaining(
      LocaleKeys.document_plugins_cover_addIcon.tr(),
    );
    expect(addCover, findsOneWidget);
    expect(addIcon, findsOneWidget);
  }

  void expectToSeeUserName(String name) {
    final userName = find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.title == name,
    );
    expect(userName, findsOneWidget);
  }
}
