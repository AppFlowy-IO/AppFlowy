
import './text_delta.dart';
import './node.dart';

class TextNode extends Node {
  final Delta delta;

  TextNode(
      {required super.type,
      required super.children,
      required super.attributes,
      required this.delta});
}
