import 'package:flutter/foundation.dart';

import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/document/text_delta.dart';

/// [Operation] represents a change to a [Document].
abstract class Operation {
  Operation(
    this.path,
  );

  factory Operation.fromJson() => throw UnimplementedError();

  final Path path;

  /// Inverts the operation.
  ///
  /// Returns the inverted operation.
  Operation invert();

  /// Returns the JSON representation of the operation.
  Map<String, dynamic> toJson();

  Operation copyWith({Path? path});
}

/// [InsertOperation] represents an insert operation.
class InsertOperation extends Operation {
  InsertOperation(
    super.path,
    this.nodes,
  );

  factory InsertOperation.fromJson(Map<String, dynamic> json) {
    final path = json['path'] as Path;
    final nodes = (json['nodes'] as List)
        .map((n) => Node.fromJson(n))
        .toList(growable: false);
    return InsertOperation(path, nodes);
  }

  final Iterable<Node> nodes;

  @override
  Operation invert() => DeleteOperation(path, nodes);

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': 'insert',
      'path': path,
      'nodes': nodes.map((n) => n.toJson()).toList(growable: false),
    };
  }

  @override
  Operation copyWith({Path? path}) {
    return InsertOperation(path ?? this.path, nodes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InsertOperation &&
        other.path.equals(path) &&
        other.nodes.equals(nodes);
  }

  @override
  int get hashCode => path.hashCode ^ Object.hashAll(nodes);
}

/// [DeleteOperation] represents a delete operation.
class DeleteOperation extends Operation {
  DeleteOperation(
    super.path,
    this.nodes,
  );

  factory DeleteOperation.fromJson(Map<String, dynamic> json) {
    final path = json['path'] as Path;
    final nodes = (json['nodes'] as List)
        .map((n) => Node.fromJson(n))
        .toList(growable: false);
    return DeleteOperation(path, nodes);
  }

  final Iterable<Node> nodes;

  @override
  Operation invert() => InsertOperation(path, nodes);

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': 'delete',
      'path': path,
      'nodes': nodes.map((n) => n.toJson()).toList(growable: false),
    };
  }

  @override
  Operation copyWith({Path? path}) {
    return DeleteOperation(path ?? this.path, nodes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeleteOperation &&
        other.path.equals(path) &&
        other.nodes.equals(nodes);
  }

  @override
  int get hashCode => path.hashCode ^ Object.hashAll(nodes);
}

/// [UpdateOperation] represents an attributes update operation.
class UpdateOperation extends Operation {
  UpdateOperation(
    super.path,
    this.attributes,
    this.oldAttributes,
  );

  factory UpdateOperation.fromJson(Map<String, dynamic> json) {
    final path = json['path'] as Path;
    final oldAttributes = json['oldAttributes'] as Attributes;
    final attributes = json['attributes'] as Attributes;
    return UpdateOperation(
      path,
      attributes,
      oldAttributes,
    );
  }

  final Attributes attributes;
  final Attributes oldAttributes;

  @override
  Operation invert() => UpdateOperation(
        path,
        oldAttributes,
        attributes,
      );

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': 'update',
      'path': path,
      'attributes': {...attributes},
      'oldAttributes': {...oldAttributes},
    };
  }

  @override
  Operation copyWith({Path? path}) {
    return UpdateOperation(
      path ?? this.path,
      {...attributes},
      {...oldAttributes},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UpdateOperation &&
        other.path.equals(path) &&
        mapEquals(other.attributes, attributes) &&
        mapEquals(other.oldAttributes, oldAttributes);
  }

  @override
  int get hashCode =>
      path.hashCode ^ attributes.hashCode ^ oldAttributes.hashCode;
}

/// [UpdateTextOperation] represents a text update operation.
class UpdateTextOperation extends Operation {
  UpdateTextOperation(
    super.path,
    this.delta,
    this.inverted,
  );

  factory UpdateTextOperation.fromJson(Map<String, dynamic> json) {
    final path = json['path'] as Path;
    final delta = Delta.fromJson(json['delta']);
    final inverted = Delta.fromJson(json['inverted']);
    return UpdateTextOperation(path, delta, inverted);
  }

  final Delta delta;
  final Delta inverted;

  @override
  Operation invert() => UpdateTextOperation(path, inverted, delta);

  @override
  Map<String, dynamic> toJson() {
    return {
      'op': 'update_text',
      'path': path,
      'delta': delta.toJson(),
      'inverted': inverted.toJson(),
    };
  }

  @override
  Operation copyWith({Path? path}) {
    return UpdateTextOperation(path ?? this.path, delta, inverted);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UpdateTextOperation &&
        other.path.equals(path) &&
        other.delta == delta &&
        other.inverted == inverted;
  }

  @override
  int get hashCode => delta.hashCode ^ inverted.hashCode;
}

// TODO(Lucas.Xu): refactor this part
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
    final newPath = transformPath(a.path, b.path, a.nodes.length);
    return b.copyWith(path: newPath);
  } else if (a is DeleteOperation) {
    final newPath = transformPath(a.path, b.path, -1 * a.nodes.length);
    return b.copyWith(path: newPath);
  }
  // TODO: transform update and textedit
  return b;
}
