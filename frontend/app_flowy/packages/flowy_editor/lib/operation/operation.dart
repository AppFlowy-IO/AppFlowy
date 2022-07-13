import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/node.dart';

abstract class Operation {

  Operation invert();

}

class InsertOperation extends Operation {
  final Path path;
  final Node value;

  InsertOperation({
    required this.path,
    required this.value,
  });

  @override
  Operation invert() {
    return DeleteOperation(path: path, removedValue: value);
  }

}

class UpdateOperation extends Operation {
  final Path path;
  final Attributes attributes;
  final Attributes oldAttributes;

  UpdateOperation({
    required this.path,
    required this.attributes,
    required this.oldAttributes,
  });

  @override
  Operation invert() {
    return UpdateOperation(path: path, attributes: oldAttributes, oldAttributes: attributes);
  }

}

class DeleteOperation extends Operation {
  final Path path;
  final Node removedValue;

  DeleteOperation({
    required this.path,
    required this.removedValue,
  });

  @override
  Operation invert() {
    return InsertOperation(path: path, value: removedValue);
  }

}
