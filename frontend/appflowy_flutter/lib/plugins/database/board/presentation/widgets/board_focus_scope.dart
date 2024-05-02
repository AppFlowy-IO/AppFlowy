import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class CardFocusScope extends ChangeNotifier
    implements ValueListenable<List<GroupedRowId>> {
  CardFocusScope({
    required this.boardController,
  });

  final AppFlowyBoardController boardController;
  List<GroupedRowId> _focusedCards = [];

  @override
  List<GroupedRowId> get value => _focusedCards;

  UnmodifiableListView<GroupedRowId> get focusedGroupedRows =>
      UnmodifiableListView(_focusedCards);

  bool isFocused(GroupedRowId groupedRowId) =>
      _focusedCards.contains(groupedRowId);

  void focus(List<GroupedRowId> groupedRowIds) {
    _deepCopy();
    _focusedCards.addAll(groupedRowIds);
    notifyListeners();
  }

  void unFocus(List<GroupedRowId> groupedRowIds) {
    _deepCopy();
    _focusedCards.removeWhere(groupedRowIds.contains);
    notifyListeners();
  }

  void toggle(GroupedRowId groupedRowId) {
    _deepCopy();
    if (_focusedCards.contains(groupedRowId)) {
      _focusedCards.remove(groupedRowId);
    } else {
      _focusedCards.add(groupedRowId);
    }
    notifyListeners();
  }

  void focusNext() {
    _deepCopy();

    // if no card is focused, focus on the first card in the board
    if (_focusedCards.isEmpty) {
      _focusFirstCard();
      notifyListeners();
      return;
    }

    final lastFocusedCard = _focusedCards.last;
    final groupController = boardController.controller(lastFocusedCard.groupId);
    final iterable = groupController?.items
        .skipWhile((item) => item.id != lastFocusedCard.rowId);

    // if the last-focused card's group cannot be found, or if the last-focused card cannot be found in the group, focus on the first card in the board
    if (iterable == null || iterable.isEmpty) {
      _focusFirstCard();
      notifyListeners();
      return;
    }

    if (iterable.length == 1) {
      // focus on the first card in the next group
      final group = boardController.groupDatas
          .skipWhile((item) => item.id != lastFocusedCard.groupId)
          .skip(1)
          .firstWhereOrNull((groupData) => groupData.items.isNotEmpty);
      if (group != null) {
        _focusedCards
          ..clear()
          ..add(
            GroupedRowId(
              rowId: group.items.first.id,
              groupId: group.id,
            ),
          );
      }
    } else {
      // focus on the next card in the same group
      _focusedCards
        ..clear()
        ..add(
          GroupedRowId(
            rowId: iterable.elementAt(1).id,
            groupId: lastFocusedCard.groupId,
          ),
        );
    }

    notifyListeners();
  }

  void focusPrevious() {
    _deepCopy();

    // if no card is focused, focus on the last card in the board
    if (_focusedCards.isEmpty) {
      _focusLastCard();
      notifyListeners();
      return;
    }

    final lastFocusedCard = _focusedCards.last;
    final groupController = boardController.controller(lastFocusedCard.groupId);
    final iterable = groupController?.items.reversed
        .skipWhile((item) => item.id != lastFocusedCard.rowId);

    // if the last-focused card's group cannot be found or if the last-focused card cannot be found in the group, focus on the last card in the board
    if (iterable == null || iterable.isEmpty) {
      _focusLastCard();
      notifyListeners();
      return;
    }

    if (iterable.length == 1) {
      // focus on the last card in the previous group
      final group = boardController.groupDatas.reversed
          .skipWhile((item) => item.id != lastFocusedCard.groupId)
          .skip(1)
          .firstWhereOrNull((groupData) => groupData.items.isNotEmpty);
      if (group != null) {
        _focusedCards
          ..clear()
          ..add(
            GroupedRowId(
              rowId: group.items.last.id,
              groupId: group.id,
            ),
          );
      }
    } else {
      // focus on the next card in the same group
      _focusedCards
        ..clear()
        ..add(
          GroupedRowId(
            rowId: iterable.elementAt(1).id,
            groupId: lastFocusedCard.groupId,
          ),
        );
    }

    notifyListeners();
  }

  void adjustRangeDown() {
    _deepCopy();

    // if no card is focused, focus on the first card in the board
    if (_focusedCards.isEmpty) {
      _focusFirstCard();
      notifyListeners();
      return;
    }

    final firstFocusedCard = _focusedCards.first;
    final lastFocusedCard = _focusedCards.last;

    // determine whether to shrink or expand the selection
    bool isExpand = false;
    if (_focusedCards.length == 1) {
      isExpand = true;
    } else {
      final firstGroupIndex = boardController.groupDatas
          .indexWhere((element) => element.id == firstFocusedCard.groupId);
      final lastGroupIndex = boardController.groupDatas
          .indexWhere((element) => element.id == lastFocusedCard.groupId);

      if (firstGroupIndex == -1 || lastGroupIndex == -1) {
        _focusFirstCard();
        notifyListeners();
        return;
      }

      if (firstGroupIndex < lastGroupIndex) {
        isExpand = true;
      } else if (firstGroupIndex > lastGroupIndex) {
        isExpand = false;
      } else {
        final groupItems =
            boardController.groupDatas.elementAt(firstGroupIndex).items;
        final firstCardIndex =
            groupItems.indexWhere((item) => item.id == firstFocusedCard.rowId);
        final lastCardIndex =
            groupItems.indexWhere((item) => item.id == lastFocusedCard.rowId);

        if (firstCardIndex == -1 || lastCardIndex == -1) {
          _focusFirstCard();
          notifyListeners();
          return;
        }

        isExpand = firstCardIndex < lastCardIndex;
      }
    }

    if (isExpand) {
      final groupController =
          boardController.controller(lastFocusedCard.groupId);

      if (groupController == null) {
        _focusFirstCard();
        notifyListeners();
        return;
      }

      final iterable = groupController.items
          .skipWhile((item) => item.id != lastFocusedCard.rowId);

      if (iterable.length == 1) {
        // focus on the first card in the next group
        final group = boardController.groupDatas
            .skipWhile((item) => item.id != lastFocusedCard.groupId)
            .skip(1)
            .firstWhereOrNull((groupData) => groupData.items.isNotEmpty);
        if (group != null) {
          _focusedCards.add(
            GroupedRowId(
              rowId: group.items.first.id,
              groupId: group.id,
            ),
          );
        }
      } else {
        _focusedCards.add(
          GroupedRowId(
            rowId: iterable.elementAt(1).id,
            groupId: lastFocusedCard.groupId,
          ),
        );
      }
    } else {
      _focusedCards.removeLast();
    }

    notifyListeners();
  }

  void adjustRangeUp() {
    _deepCopy();

    // if no card is focused, focus on the first card in the board
    if (_focusedCards.isEmpty) {
      _focusLastCard();
      notifyListeners();
      return;
    }

    final firstFocusedCard = _focusedCards.first;
    final lastFocusedCard = _focusedCards.last;

    // determine whether to shrink or expand the selection
    bool isExpand = false;
    if (_focusedCards.length == 1) {
      isExpand = true;
    } else {
      final firstGroupIndex = boardController.groupDatas
          .indexWhere((element) => element.id == firstFocusedCard.groupId);
      final lastGroupIndex = boardController.groupDatas
          .indexWhere((element) => element.id == lastFocusedCard.groupId);

      if (firstGroupIndex == -1 || lastGroupIndex == -1) {
        _focusLastCard();
        notifyListeners();
        return;
      }

      if (firstGroupIndex < lastGroupIndex) {
        isExpand = false;
      } else if (firstGroupIndex > lastGroupIndex) {
        isExpand = true;
      } else {
        final groupItems =
            boardController.groupDatas.elementAt(firstGroupIndex).items;
        final firstCardIndex =
            groupItems.indexWhere((item) => item.id == firstFocusedCard.rowId);
        final lastCardIndex =
            groupItems.indexWhere((item) => item.id == lastFocusedCard.rowId);

        if (firstCardIndex == -1 || lastCardIndex == -1) {
          _focusLastCard();
          notifyListeners();
          return;
        }

        isExpand = firstCardIndex > lastCardIndex;
      }
    }

    if (isExpand) {
      final groupController =
          boardController.controller(lastFocusedCard.groupId);

      if (groupController == null) {
        _focusLastCard();
        notifyListeners();
        return;
      }

      final iterable = groupController.items.reversed
          .skipWhile((item) => item.id != lastFocusedCard.rowId);

      if (iterable.length == 1) {
        // focus on the last card in the previous group
        final group = boardController.groupDatas.reversed
            .skipWhile((item) => item.id != lastFocusedCard.groupId)
            .skip(1)
            .firstWhereOrNull((groupData) => groupData.items.isNotEmpty);
        if (group != null) {
          _focusedCards.add(
            GroupedRowId(
              rowId: group.items.last.id,
              groupId: group.id,
            ),
          );
        }
      } else {
        _focusedCards.add(
          GroupedRowId(
            rowId: iterable.elementAt(1).id,
            groupId: lastFocusedCard.groupId,
          ),
        );
      }
    } else {
      _focusedCards.removeLast();
    }

    notifyListeners();
  }

  void clear() {
    _deepCopy();
    _focusedCards.clear();
    notifyListeners();
  }

  void _focusFirstCard() {
    _focusedCards.clear();
    final firstGroup = boardController.groupDatas
        .firstWhereOrNull((group) => group.items.isNotEmpty);
    final firstCard = firstGroup?.items.firstOrNull;
    if (firstCard != null) {
      _focusedCards
          .add(GroupedRowId(rowId: firstCard.id, groupId: firstGroup!.id));
    }
  }

  void _focusLastCard() {
    _focusedCards.clear();
    final lastGroup = boardController.groupDatas
        .lastWhereOrNull((group) => group.items.isNotEmpty);
    final lastCard = lastGroup?.items.lastOrNull;
    if (lastCard != null) {
      _focusedCards
          .add(GroupedRowId(rowId: lastCard.id, groupId: lastGroup!.id));
    }
  }

  void _deepCopy() {
    _focusedCards = [..._focusedCards];
  }
}

class ConditionalListenableBuilder<T> extends StatefulWidget {
  const ConditionalListenableBuilder({
    super.key,
    required this.valueListenable,
    required this.buildWhen,
    required this.builder,
    this.child,
  });

  /// The [ValueListenable] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [ValueListenable]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  final ValueListenable<T> valueListenable;

  /// The [buildWhen] function will be called on each value change of the
  /// [valueListenable]. If the [buildWhen] function returns true, the [builder]
  /// will be called with the new value of the [valueListenable].
  ///
  final bool Function(T previous, T current) buildWhen;

  /// A [ValueWidgetBuilder] which builds a widget depending on the
  /// [valueListenable]'s value.
  ///
  /// Can incorporate a [valueListenable] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  final ValueWidgetBuilder<T> builder;

  /// A [valueListenable]-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree the
  /// [builder] builds depends on the value of the [valueListenable]. For
  /// example, in the case where the [valueListenable] is a [String] and the
  /// [builder] returns a [Text] widget with the current [String] value, there
  /// would be no useful [child].
  final Widget? child;

  @override
  State<ConditionalListenableBuilder> createState() =>
      _ConditionalListenableBuilderState<T>();
}

class _ConditionalListenableBuilderState<T>
    extends State<ConditionalListenableBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ConditionalListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    if (widget.buildWhen(value, widget.valueListenable.value)) {
      setState(() {
        value = widget.valueListenable.value;
      });
    } else {
      value = widget.valueListenable.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}
