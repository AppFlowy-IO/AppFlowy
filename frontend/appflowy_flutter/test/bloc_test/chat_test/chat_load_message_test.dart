import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  // ignore: unused_local_variable
  late AppFlowyChatTest chatTest;

  setUpAll(() async {
    chatTest = await AppFlowyChatTest.ensureInitialized();
  });

  test('send message', () async {
    // final context = await chatTest.createChat();
  });
}
