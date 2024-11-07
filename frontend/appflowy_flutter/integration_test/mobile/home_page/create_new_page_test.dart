// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:appflowy/mobile/presentation/home/section_folder/mobile_home_section_folder_header.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/plugins/document/document_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../shared/dir.dart';
import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('create new page in home page:', () {
    testWidgets('create document', (tester) async {
      await tester.launchInAnonymousMode();

      // tap the create page button
      final createPageButton = find.byWidgetPredicate(
        (widget) =>
            widget is FlowySvg &&
            widget.svg.path == FlowySvgs.m_home_add_m.path,
      );
      await tester.tapButton(createPageButton);
      await tester.pumpAndSettle();
      expect(find.byType(MobileDocumentScreen), findsOneWidget);
    });
  });
}
