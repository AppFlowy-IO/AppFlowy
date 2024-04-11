class ToggleStyle {
  ToggleStyle({
    required this.height,
    required this.width,
    required this.thumbRadius,
  });

  final double height;
  final double width;
  final double thumbRadius;

  static ToggleStyle get big =>
      ToggleStyle(height: 16, width: 27, thumbRadius: 14);

  static ToggleStyle get small =>
      ToggleStyle(height: 10, width: 16, thumbRadius: 8);

  static ToggleStyle get mobile =>
      ToggleStyle(height: 24, width: 42, thumbRadius: 18);
}
