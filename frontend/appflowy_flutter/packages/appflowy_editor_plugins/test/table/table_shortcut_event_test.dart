import 'package:flutter_test/flutter_test.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('table_shortcut_event.dart', () {
    testWidgets('enter key on middle cells', (tester) async {});

    testWidgets('enter key on last cell', (tester) async {});

    testWidgets('backspace on beginning of cell', (tester) async {});

    testWidgets('backspace on multiple cell selection', (tester) async {});

    testWidgets(
        'backspace on cell and after table node selection', (tester) async {});
  });
}
