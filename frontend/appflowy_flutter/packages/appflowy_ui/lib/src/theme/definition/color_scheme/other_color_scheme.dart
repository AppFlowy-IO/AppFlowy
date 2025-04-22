import 'dart:ui';

class AppFlowyOtherColorsColorScheme {
  const AppFlowyOtherColorsColorScheme({
    required this.textHighlight,
  });

  final Color textHighlight;

  AppFlowyOtherColorsColorScheme lerp(
    AppFlowyOtherColorsColorScheme other,
    double t,
  ) {
    return AppFlowyOtherColorsColorScheme(
      textHighlight: Color.lerp(textHighlight, other.textHighlight, t)!,
    );
  }
}
