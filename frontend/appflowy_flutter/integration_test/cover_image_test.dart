import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('cover image', () {
    const location = 'cover_image';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(location);
    });

    tearDownAll(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets(
        'hovering on cover image will display change and delete cover image buttons',
        (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapGoButton();
      await tester.hoverOnCoverPluginAddButton();

      tester.expectToSeePluginAddCoverAndIconButton();
    });
  });
}
