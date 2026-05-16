enum FormFactor {
  mobile._(600),
  tablet._(840),
  desktop._(1280);

  const FormFactor._(this.width);

  factory FormFactor.fromWidth(double width) {
    if (width < FormFactor.mobile.width) {
      return FormFactor.mobile;
    } else if (width < FormFactor.tablet.width) {
      return FormFactor.tablet;
    } else {
      return FormFactor.desktop;
    }
  }

  final double width;
}
