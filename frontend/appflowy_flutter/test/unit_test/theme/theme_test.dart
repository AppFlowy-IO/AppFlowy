import 'package:flowy_infra/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme tests', () {
    test(
      'AppTheme.fromName succeeds when builtin theme is requested',
      () async {
        expect(
          () => AppTheme.fromName(BuiltInTheme.defaultTheme),
          returnsNormally,
        );
      },
    );

    test(
      'AppTheme.fromName fails when a garbage theme name is provided',
      () async {
        expect(
          () => AppTheme.fromName('garbage'),
          throwsException,
        );
      },
    );
  });
}
