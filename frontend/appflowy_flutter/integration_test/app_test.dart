import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'open_ai_smart_menu_test.dart' as smart_menu_test;
import 'switch_folder_test.dart' as switch_folder_test;

void main() async{
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('run all tests',(){
  switch_folder_test.run();
  smart_menu_test.run();
  });
}