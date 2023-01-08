import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_backend/appflowy_backend_method_channel.dart';

void main() {
  MethodChannelFlowySdk platform = MethodChannelFlowySdk();
  const MethodChannel channel = MethodChannel('appflowy_backend');

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
    expect(await platform.getPlatformVersion(), '42');
  });
}
