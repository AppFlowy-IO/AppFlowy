import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  group('DocumentAppearanceCubit', () {
    late SharedPreferences preferences;
    late DocumentAppearanceCubit cubit;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      preferences = await SharedPreferences.getInstance();
      cubit = DocumentAppearanceCubit();
    });

    tearDown(() async {
      await preferences.clear();
      await cubit.close();
    });

    test('Initial state', () {
      expect(cubit.state.fontSize, 16.0);
      expect(cubit.state.fontFamily, builtInFontFamily);
    });

    test('Fetch document appearance from SharedPreferences', () async {
      await preferences.setDouble(KVKeys.kDocumentAppearanceFontSize, 18.0);
      await preferences.setString(
        KVKeys.kDocumentAppearanceFontFamily,
        'Arial',
      );

      await cubit.fetch();

      expect(cubit.state.fontSize, 18.0);
      expect(cubit.state.fontFamily, 'Arial');
    });

    test('Sync font size to SharedPreferences', () async {
      await cubit.syncFontSize(20.0);

      final fontSize =
          preferences.getDouble(KVKeys.kDocumentAppearanceFontSize);
      expect(fontSize, 20.0);
      expect(cubit.state.fontSize, 20.0);
    });

    test('Sync font family to SharedPreferences', () async {
      await cubit.syncFontFamily('Helvetica');

      final fontFamily =
          preferences.getString(KVKeys.kDocumentAppearanceFontFamily);
      expect(fontFamily, 'Helvetica');
      expect(cubit.state.fontFamily, 'Helvetica');
    });
  });
}
