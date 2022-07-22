import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_board/flowy_board.dart';
import 'package:flowy_board/flowy_board_platform_interface.dart';
import 'package:flowy_board/flowy_board_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlowyBoardPlatform 
    with MockPlatformInterfaceMixin
    implements FlowyBoardPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlowyBoardPlatform initialPlatform = FlowyBoardPlatform.instance;

  test('$MethodChannelFlowyBoard is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlowyBoard>());
  });

  test('getPlatformVersion', () async {
    FlowyBoard flowyBoardPlugin = FlowyBoard();
    MockFlowyBoardPlatform fakePlatform = MockFlowyBoardPlatform();
    FlowyBoardPlatform.instance = fakePlatform;
  
    expect(await flowyBoardPlugin.getPlatformVersion(), '42');
  });
}
