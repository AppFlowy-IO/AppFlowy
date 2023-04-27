class TrashSizes {
  static double scale = 0.8;
  static double get headerHeight => 60 * scale;
  static double get fileNameWidth => 320 * scale;
  static double get lashModifyWidth => 230 * scale;
  static double get createTimeWidth => 230 * scale;
  // padding between createTime and action icon
  static double get padding => 40 * scale;
  static double get actionIconWidth => 40 * scale;
  static double get totalWidth =>
      TrashSizes.fileNameWidth +
      TrashSizes.lashModifyWidth +
      TrashSizes.createTimeWidth +
      TrashSizes.padding +
      // restore and delete icon
      2 * TrashSizes.actionIconWidth;
}
