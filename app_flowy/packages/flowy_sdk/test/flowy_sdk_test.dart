import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_sdk/flowy_sdk.dart';

void main() {
  const MethodChannel channel = MethodChannel('flowy_sdk');

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
    expect(await FlowySDK.platformVersion, '42');
  });
}
