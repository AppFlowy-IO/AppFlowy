enum ToolbarId {
  bold,
  underline,
  italic,
  code,
  highlightColor,
  textColor,
  link,
  placeholder,
  paddingPlaceHolder,
  textAlign,
  moreOption,
  textHeading,
  suggestions,
}

extension ToolbarIdExtension on ToolbarId {
  String get id => 'editor.$name';
}
