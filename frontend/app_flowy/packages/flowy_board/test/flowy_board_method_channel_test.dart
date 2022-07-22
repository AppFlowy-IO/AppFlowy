import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_board/flowy_board_method_channel.dart';

void main() {
  MethodChannelFlowyBoard platform = MethodChannelFlowyBoard();
  const MethodChannel channel = MethodChannel('flowy_board');

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
