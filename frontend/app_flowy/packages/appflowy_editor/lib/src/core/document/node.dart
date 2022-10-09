import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';

class Node extends ChangeNotifier with LinkedListEntry<Node> {
  Node({
    required this.type,
    Attributes? attributes,
    this.parent,
    LinkedList<Node>? children,
  })  : children = children ?? LinkedList<Node>(),
        _attributes = attributes ?? {} {
    for (final child in this.children) {
      child.parent = this;
    }
  }

  factory Node.fromJson(Map<String, Object> json) {
    assert(json['type'] is String);

    final jType = json['type'] as String;
    final jChildren = json['children'] as List?;
    final jAttributes = json['attributes'] != null
        ? Attributes.from(json['attributes'] as Map)
        : Attributes.from({});

    final children = LinkedList<Node>();
    if (jChildren != null) {
      children.addAll(
        jChildren.map(
          (jChild) => Node.fromJson(
            Map<String, Object>.from(jChild),
          ),
        ),
      );
    }

    Node node;

    if (jType == 'text') {
      final jDelta = json['delta'] as List<dynamic>?;
      final delta = jDelta == null ? Delta() : Delta.fromJson(jDelta);
      node = TextNode(
        children: children,
        attributes: jAttributes,
        delta: delta,
      );
    } else {
      node = Node(
        type: jType,
        children: children,
        attributes: jAttributes,
      );
    }

    for (final child in children) {
      child.parent = node;
    }

    return node;
  }

  final String type;
  final LinkedList<Node> children;
  Node? parent;
  Attributes _attributes;

  // Renderable
  GlobalKey? key;
  final layerLink = LayerLink();

  Attributes get attributes => {..._attributes};

  String get id {
    if (subtype != null) {
      return '$type/$subtype';
    }
    return type;
  }

  String? get subtype {
    if (attributes[BuiltInAttributeKey.subtype] is String) {
      return attributes[BuiltInAttributeKey.subtype] as String;
    }
    return null;
  }

  Path get path => _computePath();

  void updateAttributes(Attributes attributes) {
    final oldAttributes = this.attributes;

    _attributes = composeAttributes(this.attributes, attributes) ?? {};

    // Notifies the new attributes
    // if attributes contains 'subtype', should notify parent to rebuild node
    // else, just notify current node.
    bool shouldNotifyParent =
        this.attributes['subtype'] != oldAttributes['subtype'];
    shouldNotifyParent ? parent?.notifyListeners() : notifyListeners();
  }

  Node? childAtIndex(int index) {
    if (children.length <= index || index < 0) {
      return null;
    }

    return children.elementAt(index);
  }

  Node? childAtPath(Path path) {
    if (path.isEmpty) {
      return this;
    }

    return childAtIndex(path.first)?.childAtPath(path.sublist(1));
  }

  void insert(Node entry, {int? index}) {
    final length = children.length;
    index ??= length;

    if (children.isEmpty) {
      entry.parent = this;
      children.add(entry);
      notifyListeners();
      return;
    }

    // If index is out of range, insert at the end.
    // If index is negative, insert at the beginning.
    // If index is positive, insert at the index.
    if (index >= length) {
      children.last.insertAfter(entry);
    } else if (index <= 0) {
      children.first.insertBefore(entry);
    } else {
      childAtIndex(index)?.insertBefore(entry);
    }
  }

  @override
  void insertAfter(Node entry) {
    entry.parent = parent;
    super.insertAfter(entry);

    // Notifies the new node.
    parent?.notifyListeners();
  }

  @override
  void insertBefore(Node entry) {
    entry.parent = parent;
    super.insertBefore(entry);

    // Notifies the new node.
    parent?.notifyListeners();
  }

  @override
  void unlink() {
    super.unlink();

    parent?.notifyListeners();
    parent = null;
  }

  Map<String, Object> toJson() {
    var map = <String, Object>{
      'type': type,
    };
    if (children.isNotEmpty) {
      map['children'] =
          children.map((node) => node.toJson()).toList(growable: false);
    }
    if (attributes.isNotEmpty) {
      map['attributes'] = attributes;
    }
    return map;
  }

  Node copyWith({
    String? type,
    LinkedList<Node>? children,
    Attributes? attributes,
  }) {
    final node = Node(
      type: type ?? this.type,
      attributes: attributes ?? {...this.attributes},
      children: children,
    );
    if (children == null && this.children.isNotEmpty) {
      for (final child in this.children) {
        node.children.add(
          child.copyWith()..parent = node,
        );
      }
    }
    return node;
  }

  Path _computePath([Path previous = const []]) {
    if (parent == null) {
      return previous;
    }
    var index = 0;
    for (final child in parent!.children) {
      if (child == this) {
        break;
      }
      index += 1;
    }
    return parent!._computePath([index, ...previous]);
  }
}

class TextNode extends Node {
  TextNode({
    required Delta delta,
    LinkedList<Node>? children,
    Attributes? attributes,
  })  : _delta = delta,
        super(
          type: 'text',
          children: children,
          attributes: attributes ?? {},
        );

  TextNode.empty({Attributes? attributes})
      : _delta = Delta([TextInsert('')]),
        super(
          type: 'text',
          attributes: attributes ?? {},
        );

  Delta _delta;
  Delta get delta => _delta;
  set delta(Delta v) {
    _delta = v;
    notifyListeners();
  }

  @override
  Map<String, Object> toJson() {
    final map = super.toJson();
    map['delta'] = delta.toJson();
    return map;
  }

  @override
  TextNode copyWith({
    String? type = 'text',
    LinkedList<Node>? children,
    Attributes? attributes,
    Delta? delta,
  }) {
    final textNode = TextNode(
      children: children,
      attributes: attributes ?? this.attributes,
      delta: delta ?? this.delta,
    );
    if (children == null && this.children.isNotEmpty) {
      for (final child in this.children) {
        textNode.children.add(
          child.copyWith()..parent = textNode,
        );
      }
    }
    return textNode;
  }

  String toPlainText() => _delta.toPlainText();
}
