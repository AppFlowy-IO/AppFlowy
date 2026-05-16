extension HexOpacityExtension on String {
  /// Only used in a valid color String like '0xff00bcf0'
  String extractHex() {
    return substring(4);
  }

  /// Only used in a valid color String like '0xff00bcf0'
  String extractOpacity() {
    final opacityString = substring(2, 4);
    final opacityInt = int.parse(opacityString, radix: 16) / 2.55;
    return opacityInt.toStringAsFixed(0);
  }

  /// Apply on the hex string like '00bcf0', with opacity like '100'
  String combineHexWithOpacity(String opacity) {
    final opacityInt = (int.parse(opacity) * 2.55).round().toRadixString(16);
    return '0x$opacityInt$this';
  }
}
