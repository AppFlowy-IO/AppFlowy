import 'package:appflowy_editor/appflowy_editor.dart';

abstract class NodeParser {
  const NodeParser();

  String get id;
  String transform(Node node);
}
