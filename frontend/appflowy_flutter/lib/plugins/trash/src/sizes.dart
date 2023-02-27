class TrashSizes {
  static double scale = 0.8;
  static double get headerHeight => 60 * scale;
  static double get fileNameWidth => 320 * scale;
  static double get lashModifyWidth => 230 * scale;
  static double get createTimeWidth => 230 * scale;
  static double get padding => 100 * scale;
  static double get totalWidth =>
      TrashSizes.fileNameWidth + TrashSizes.lashModifyWidth + TrashSizes.createTimeWidth + TrashSizes.padding;
}
