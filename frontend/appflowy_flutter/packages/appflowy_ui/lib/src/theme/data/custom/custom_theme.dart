import 'package:appflowy_ui/appflowy_ui.dart';

class CustomTheme implements AppFlowyThemeBuilder {
  const CustomTheme({
    required this.lightThemeJson,
    required this.darkThemeJson,
  });

  final Map<String, dynamic> lightThemeJson;
  final Map<String, dynamic> darkThemeJson;

  @override
  AppFlowyBaseThemeData dark() {
    // TODO: implement dark
    throw UnimplementedError();
  }

  @override
  AppFlowyBaseThemeData light() {
    // TODO: implement light
    throw UnimplementedError();
  }
}
