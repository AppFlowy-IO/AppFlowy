import 'package:appflowy_ui/appflowy_ui.dart';

class CustomTheme implements AppFlowyThemeBuilder {
  const CustomTheme({
    required this.lightThemeJson,
    required this.darkThemeJson,
  });

  final Map<String, dynamic> lightThemeJson;
  final Map<String, dynamic> darkThemeJson;

  @override
  AppFlowyThemeData light() {
    // TODO: implement light
    throw UnimplementedError();
  }

  @override
  AppFlowyThemeData dark() {
    // TODO: implement dark
    throw UnimplementedError();
  }
}
