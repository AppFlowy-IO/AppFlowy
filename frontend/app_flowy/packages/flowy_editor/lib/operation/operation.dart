import 'package:flowy_editor/document/attributes.dart';
import 'package:flowy_editor/flowy_editor.dart';

abstract class Operation {
  final Path path;
  Operation({required this.path});
  Operation copyWithPath(Path path);
  Operation invert();
}

class InsertOperation extends Operation {
  final Node value;

  InsertOperation({
    required super.path,
    required this.value,
  });

  InsertOperation copyWith({Path? path, Node? value}) =>
      InsertOperation(path: path ?? this.path, value: value ?? this.value);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return DeleteOperation(
      path: path,
      removedValue: value,
    );
  }
}

class UpdateOperation extends Operation {
  final Attributes attributes;
  final Attributes oldAttributes;

  UpdateOperation({
    required super.path,
    required this.attributes,
    required this.oldAttributes,
  });

  UpdateOperation copyWith(
          {Path? path, Attributes? attributes, Attributes? oldAttributes}) =>
      UpdateOperation(
          path: path ?? this.path,
          attributes: attributes ?? this.attributes,
          oldAttributes: oldAttributes ?? this.oldAttributes);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return UpdateOperation(
      path: path,
      attributes: oldAttributes,
      oldAttributes: attributes,
    );
  }
}

class DeleteOperation extends Operation {
  final Node removedValue;

  DeleteOperation({
    required super.path,
    required this.removedValue,
  });

  DeleteOperation copyWith({Path? path, Node? removedValue}) => DeleteOperation(
      path: path ?? this.path, removedValue: removedValue ?? this.removedValue);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return InsertOperation(
      path: path,
      value: removedValue,
    );
  }
}

class TextEditOperation extends Operation {
  final Delta delta;
  final Delta inverted;

  TextEditOperation({
    required super.path,
    required this.delta,
    required this.inverted,
  });

  TextEditOperation copyWith({Path? path, Delta? delta, Delta? inverted}) =>
      TextEditOperation(
          path: path ?? this.path,
          delta: delta ?? this.delta,
          inverted: inverted ?? this.inverted);

  @override
  Operation copyWithPath(Path path) => copyWith(path: path);

  @override
  Operation invert() {
    return TextEditOperation(path: path, delta: inverted, inverted: delta);
  }
}

Path transformPath(Path preInsertPath, Path b, [int delta = 1]) {
  if (preInsertPath.length > b.length) {
    return b;
  }
  if (preInsertPath.isEmpty || b.isEmpty) {
    return b;
  }
  // check the prefix
  for (var i = 0; i < preInsertPath.length - 1; i++) {
    if (preInsertPath[i] != b[i]) {
      return b;
    }
  }
  final prefix = preInsertPath.sublist(0, preInsertPath.length - 1);
  final suffix = b.sublist(preInsertPath.length);
  final preInsertLast = preInsertPath.last;
  final bAtIndex = b[preInsertPath.length - 1];
  if (preInsertLast <= bAtIndex) {
    prefix.add(bAtIndex + delta);
  } else {
    prefix.add(bAtIndex);
  }
  prefix.addAll(suffix);
  return prefix;
}

Operation transformOperation(Operation a, Operation b) {
  if (a is InsertOperation) {
    final newPath = transformPath(a.path, b.path);
    return b.copyWithPath(newPath);
  } else if (b is DeleteOperation) {
    final newPath = transformPath(a.path, b.path, -1);
    return b.copyWithPath(newPath);
  }
  // TODO: transform update and textedit
  return b;
}
