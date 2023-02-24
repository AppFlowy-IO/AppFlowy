class ToggleStyle {
  final double height;
  final double width;

  final double thumbRadius;

  ToggleStyle({
    required this.height,
    required this.width,
    required this.thumbRadius,
  });

  static ToggleStyle get big =>
      ToggleStyle(height: 16, width: 27, thumbRadius: 14);

  static ToggleStyle get small =>
      ToggleStyle(height: 10, width: 16, thumbRadius: 8);
}
