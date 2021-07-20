import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

void main() {
  const MethodChannel channel = MethodChannel('flowy_infra_ui');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlowyInfraUi.platformVersion, '42');
  });
}
