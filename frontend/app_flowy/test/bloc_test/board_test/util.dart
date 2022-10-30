import '../grid_test/util.dart';

class AppFlowyBoardTest {
  final AppFlowyGridTest context;
  AppFlowyBoardTest(this.context);

  static Future<AppFlowyBoardTest> ensureInitialized() async {
    final inner = await AppFlowyGridTest.ensureInitialized();
    return AppFlowyBoardTest(inner);
  }
}

Future<void> boardResponseFuture() {
  return Future.delayed(boardResponseDuration(milliseconds: 200));
}

Duration boardResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
