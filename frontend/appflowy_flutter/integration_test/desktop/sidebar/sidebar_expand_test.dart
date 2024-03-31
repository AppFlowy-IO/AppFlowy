import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('sidebar expand test', () {
    bool isExpanded({required FolderCategoryType type}) {
      if (type == FolderCategoryType.private) {
        return find
            .descendant(
              of: find.byType(PrivateSectionFolder),
              matching: find.byType(ViewItem),
            )
            .evaluate()
            .isNotEmpty;
      }
      return false;
    }

    testWidgets('first time the personal folder is expanded', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // first time is expanded
      expect(isExpanded(type: FolderCategoryType.private), true);

      // collapse the personal folder
      await tester.tapButton(
        find.byTooltip(LocaleKeys.sideBar_clickToHidePrivate.tr()),
      );
      expect(isExpanded(type: FolderCategoryType.private), false);

      // expand the personal folder
      await tester.tapButton(
        find.byTooltip(LocaleKeys.sideBar_clickToHidePrivate.tr()),
      );
      expect(isExpanded(type: FolderCategoryType.private), true);
    });
  });
}
