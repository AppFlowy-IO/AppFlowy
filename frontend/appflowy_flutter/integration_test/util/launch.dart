import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/skip_log_in_screen.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension AppFlowyLaunch on WidgetTester {
  Future<void> tapGoButton() async {
    final goButton = find.byType(GoButton);
    await tapButton(goButton);
  }

  Future<void> tapCreateButton() async {
    await tapButtonWithName(LocaleKeys.settings_files_create.tr());
  }

  void expectToSeeWelcomePage() {
    expect(find.byType(HomeStack), findsOneWidget);
    expect(find.textContaining('Read me'), findsNWidgets(2));
  }

  Future<void> tapAddButton() async {
    final addButton = find.byType(AddButton);
    await tapButton(addButton);
  }

  Future<void> tapCreateDocumentButton() async {
    await tapButtonWithName(LocaleKeys.document_menuName.tr());
  }

  void expectToSeePageName(String name) {
    find.byWidgetPredicate(
      (widget) => widget is ViewSectionItem && widget.view.name == name,
    );
  }
}
