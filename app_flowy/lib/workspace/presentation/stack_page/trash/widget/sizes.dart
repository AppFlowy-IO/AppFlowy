class TrashSizes {
  static double scale = 1;
  static double get fileNameWidth => 320 * scale;
  static double get lashModifyWidth => 230 * scale;
  static double get createTimeWidth => 230 * scale;
  static double get padding => 100 * scale;
  static double get totalWidth =>
      TrashSizes.fileNameWidth + TrashSizes.lashModifyWidth + TrashSizes.createTimeWidth + TrashSizes.padding;
}
