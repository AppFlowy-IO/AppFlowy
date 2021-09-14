import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../model/quill_delta.dart';
import '../util/delta_diff.dart';
import '../model/document/attribute.dart';
import '../model/document/document.dart';
import '../model/document/style.dart';
import '../model/document/node/embed.dart';

abstract class EditorPersistence {
  Future<bool> save(List<dynamic> jsonList);
}

class EditorController extends ChangeNotifier {
  final Document document;
  TextSelection selection;
  final EditorPersistence? persistence;
  Style toggledStyle = Style();

  EditorController({
    required this.document,
    required this.selection,
    this.persistence,
  });

  // item1: Document state before [change].
  // item2: Change delta applied to the document.
  // item3: The source of this change.
  Stream<Tuple3<Delta, Delta, ChangeSource>> get changes => document.changes;

  TextEditingValue get plainTextEditingValue => TextEditingValue(
        text: document.toPlainText(),
        selection: selection,
      );

  Style getSelectionStyle() =>
      document.collectStyle(selection.start, selection.end - selection.start)
        ..mergeAll(toggledStyle);

  bool get hasUndo => document.hasUndo;

  bool get hasRedo => document.hasRedo;

  void undo() {
    final action = document.undo();
    if (action.item1) {
      _handleHistoryChange(action.item2);
    }
  }

  void redo() {
    final action = document.redo();
    if (action.item1) {
      _handleHistoryChange(action.item2);
    }
  }

  void save() {
    if (persistence != null) {
      persistence!.save(document.toDelta().toJson());
    }
  }

  @override
  void dispose() {
    document.close();
    super.dispose();
  }

  void updateSelection(TextSelection textSelection, ChangeSource source) {
    _updateSelection(textSelection, source);
    notifyListeners();
  }

  void formatSelection(Attribute? attribute) {
    formatText(selection.start, selection.end - selection.start, attribute);
  }

  void formatText(int index, int length, Attribute? attribute) {
    if (length == 0 &&
        attribute!.isInline &&
        attribute.key != Attribute.link.key) {
      toggledStyle = toggledStyle.put(attribute);
    }

    // final change =
    //     document.format(index, length, LinkAttribute("www.baidu.com"));
    final change = document.format(index, length, attribute);

    final adjustedSelection = selection.copyWith(
      baseOffset: change.transformPosition(selection.baseOffset),
      extentOffset: change.transformPosition(selection.extentOffset),
    );
    if (selection != adjustedSelection) {
      _updateSelection(adjustedSelection, ChangeSource.LOCAL);
    }
    notifyListeners();
  }

  void replaceText(
      int index, int length, Object? data, TextSelection? textSelection) {
    assert(data is String || data is Embeddable);

    Delta? delta;
    if (length > 0 || data is! String || data.isNotEmpty) {
      delta = document.replace(index, length, data);

      var shouldRetainDelta = toggledStyle.isNotEmpty &&
          delta.isNotEmpty &&
          delta.length <= 2 &&
          delta.last.isInsert;
      if (shouldRetainDelta &&
          toggledStyle.isNotEmpty &&
          delta.length == 2 &&
          delta.last.data == '\n') {
        // if all attributes are inline, shouldRetainDelta should be false
        final anyAttributeNotInline =
            toggledStyle.values.any((attr) => !attr.isInline);
        shouldRetainDelta &= anyAttributeNotInline;
      }
      if (shouldRetainDelta) {
        final retainDelta = Delta()
          ..retain(index)
          ..retain(
            data is String ? data.length : 1,
            toggledStyle.toJson(),
          );
        document.compose(retainDelta, ChangeSource.LOCAL);
      }
    }

    toggledStyle = Style();
    if (textSelection != null) {
      if (delta == null || delta.isEmpty) {
        _updateSelection(textSelection, ChangeSource.LOCAL);
      } else {
        final user = Delta()
          ..retain(index)
          ..insert(data)
          ..delete(length);
        final positionDelta = getPositionDelta(user, delta);
        _updateSelection(
            textSelection.copyWith(
              baseOffset: textSelection.baseOffset + positionDelta,
              extentOffset: textSelection.extentOffset + positionDelta,
            ),
            ChangeSource.LOCAL);
      }
    }
    notifyListeners();
  }

  void compose(Delta delta, TextSelection textSelection, ChangeSource source) {
    if (delta.isNotEmpty) {
      document.compose(delta, source);
    }

    textSelection = selection.copyWith(
      baseOffset: delta.transformPosition(selection.baseOffset, force: false),
      extentOffset:
          delta.transformPosition(selection.extentOffset, force: false),
    );
    if (selection != textSelection) {
      _updateSelection(textSelection, source);
    }

    notifyListeners();
  }

/* --------------------------------- Helper --------------------------------- */

  void _handleHistoryChange(int? length) {
    if (length != 0) {
      updateSelection(
        TextSelection.collapsed(offset: selection.baseOffset + length!),
        ChangeSource.LOCAL,
      );
    } else {
      // no need to move cursor
      notifyListeners();
    }
  }

  void _updateSelection(TextSelection textSelection, ChangeSource source) {
    selection = textSelection;
    final end = document.length - 1;
    selection = selection.copyWith(
      baseOffset: math.min(selection.baseOffset, end),
      extentOffset: math.min(selection.extentOffset, end),
    );
  }
}
