import 'dart:ui';

/// Abstract random color picker as a service to implement dependency injection.
abstract class ColorPickerService {
  Color generateRandomNameColor(String name) =>
      throw UnimplementedError('generateNameColor() has not been implemented.');
}
