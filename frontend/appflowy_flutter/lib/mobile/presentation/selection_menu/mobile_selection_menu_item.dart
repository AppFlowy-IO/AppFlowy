import 'package:appflowy_editor/appflowy_editor.dart';

class MobileSelectionMenuItem extends SelectionMenuItem {
  MobileSelectionMenuItem({
    required super.getName,
    required super.icon,
    super.keywords = const [],
    required super.handler,
    this.children = const [],
    super.nameBuilder,
    super.deleteKeywords,
    super.deleteSlash,
  });

  final List<SelectionMenuItem> children;

  bool get isNotEmpty => children.isNotEmpty;
}
