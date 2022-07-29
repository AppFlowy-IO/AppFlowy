import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:equatable/equatable.dart';
import '../utils/log.dart';
import 'board_overlay.dart';
import 'board_mixin.dart';
import 'drag_target.dart';
import 'dart:math';

part 'board_list_content.dart';

typedef OnDragStarted = void Function(String listId, int index);
typedef OnDragEnded = void Function(String listId);
typedef OnReorder = void Function(String listId, int fromIndex, int toIndex);
typedef OnDeleted = void Function(String listId, int deletedIndex);
typedef OnInserted = void Function(String listId, int insertedIndex);
typedef OnWillInsert = void Function(String listId, int insertedIndex,
    BoardListItem item, Widget? draggingWidget);

class BoardListData extends ChangeNotifier with EquatableMixin {
  final String id;
  final phantomNotifier = PhantomChangeNotifier();

  final List<BoardListItem> _items;
  List<BoardListItem> get items => _items;

  BoardListData({
    required this.id,
    required List<BoardListItem> items,
  }) : _items = items;

  @override
  List<Object?> get props => [id, ..._items];

  BoardListItem removeAt(int index) {
    final item = _items.removeAt(index);
    notifyListeners();
    return item;
  }

  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }

    final item = _items.removeAt(fromIndex);
    _items.insert(toIndex, item);
    notifyListeners();
  }

  void insert(int index, BoardListItem item) {
    _items.insert(index, item);
    notifyListeners();
  }

  /// Insert the [Phantom] at [insertedIndex] and remove the existing [Phantom]
  /// if it exists.
  void insertPhantom(
      int insertedIndex, BoardListItem listItem, Widget? draggingWidget) {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      if (index != insertedIndex) {
        Log.debug(
            '[Phantom] Move phantom from $id:$index to $id:$insertedIndex');

        move(index, insertedIndex);

        // _items.removeAt(index);
        // phantomNotifier.delete(index);

        // _items.insert(insertedIndex, BoardListPhantomItem(listItem));
        // phantomNotifier.insert(insertedIndex);
      }
    } else {
      Log.debug('[Phantom] insert phantom at $id:$insertedIndex');
      insert(insertedIndex, BoardListPhantomItem(listItem));

      // _items.insert(insertedIndex, BoardListPhantomItem(listItem));
      // phantomNotifier.insert(insertedIndex);
    }
  }

  void removePhantom() {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      Log.debug('[Phantom] Remove phantom at $id:$index');

      removeAt(index);

      // _items.removeAt(index);
      // phantomNotifier.delete(index);
    }
  }
}

class BoardListConfig {
  final bool needsLongPressDraggable = true;
  final double draggingWidgetOpacity = 0.2;
  final Duration reorderAnimationDuration = const Duration(milliseconds: 250);
  final Duration scrollAnimationDuration = const Duration(milliseconds: 250);
  const BoardListConfig();
}

abstract class BoardListItem {
  String get id;

  bool get isPhantom => false;
}

class BoardListPhantomItem extends BoardListItem {
  final BoardListItem inner;

  BoardListPhantomItem(
    this.inner,
  );

  @override
  bool get isPhantom => true;

  @override
  String get id => inner.id;
}

typedef BoardListItemWidgetBuilder = Widget Function(
    BuildContext context, BoardListItem item);

class BoardList extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final BoardListData listData;
  final BoardListItemWidgetBuilder builder;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final OnDeleted onDeleted;
  final OnInserted onInserted;
  final OnWillInsert onWillInserted;

  String get listId => listData.id;

  const BoardList({
    Key? key,
    this.header,
    this.footer,
    required this.listData,
    required this.builder,
    this.scrollController,
    this.config = const BoardListConfig(),
    this.onDragStarted,
    required this.onReorder,
    this.onDragEnded,
    required this.onDeleted,
    required this.onInserted,
    required this.onWillInserted,
  }) : super(key: key);

  @override
  State<BoardList> createState() => _BoardListState();
}

class _BoardListState extends State<BoardList> {
  final GlobalKey _overlayKey = GlobalKey(debugLabel: '$BoardList overlay key');

  late BoardOverlayEntry _overlayEntry;

  @override
  void initState() {
    _overlayEntry = BoardOverlayEntry(
        builder: (BuildContext context) {
          final children = widget.listData.items
              .map((item) => widget.builder(context, item))
              .toList();

          return BoardListContentWidget(
            key: widget.key,
            header: widget.header,
            footer: widget.footer,
            scrollController: widget.scrollController,
            config: widget.config,
            onDragStarted: (index) {
              widget.onDragStarted?.call(widget.listId, index);
            },
            onReorder: ((fromIndex, toIndex) {
              widget.onReorder(widget.listId, fromIndex, toIndex);
            }),
            onDragEnded: () {
              widget.onDragEnded?.call(widget.listId);
            },
            onDeleted: (deletedIndex) {
              widget.onDeleted(widget.listId, deletedIndex);
            },
            onInserted: (insertedIndex) {
              widget.onInserted(widget.listId, insertedIndex);
            },
            onWillInserted: (insertedIndex, item, draggingWidget) {
              widget.onWillInserted(
                widget.listId,
                insertedIndex,
                item,
                draggingWidget,
              );
            },
            listData: widget.listData,
            builder: (context, item) {
              if (item is BoardListPhantomItem) {
                final child = widget.builder(context, item.inner);
                return PhantomWidget(
                  key: child.key,
                  opacity: widget.config.draggingWidgetOpacity,
                  child: child,
                );
              } else {
                return widget.builder(context, item);
              }
            },
            children: children,
          );
        },
        opaque: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BoardOverlay(
      key: _overlayKey,
      initialEntries: [_overlayEntry],
    );
  }
}

class PhantomChangeNotifier {
  final _insertNotifier = PhantomInsertNotifier();

  final _deleteNotifier = PhantomDeleteNotifier();

  void insert(int insertedIndex) {
    _insertNotifier.insert(insertedIndex);
  }

  void delete(int deletedIndex) {
    _deleteNotifier.delete(deletedIndex);
  }

  void onInsert(void Function(int index) callback) {
    _insertNotifier.addListener(() {
      callback(_insertNotifier.insertedIndex);
    });
  }

  void onDelete(void Function(int index) callback) {
    _deleteNotifier.addListener(() {
      callback(_deleteNotifier.deletedIndex);
    });
  }
}

class PhantomInsertNotifier extends ChangeNotifier {
  int insertedIndex = -1;

  void insert(int insertedIndex) {
    if (this.insertedIndex != insertedIndex) {
      this.insertedIndex = insertedIndex;
      notifyListeners();
    }
  }
}

class PhantomDeleteNotifier extends ChangeNotifier {
  int deletedIndex = -1;

  void delete(int deletedIndex) {
    if (this.deletedIndex != deletedIndex) {
      this.deletedIndex = deletedIndex;
      notifyListeners();
    }
  }
}

class PhantomMoveNotifier extends ChangeNotifier {
  int fromIndex = -1;
  int toIndex = -1;

  void move(int fromIndex, int toIndex) {
    bool isChange = false;
    if (this.fromIndex != fromIndex) {
      this.fromIndex = fromIndex;
      isChange = true;
    }

    if (this.toIndex != toIndex) {
      this.toIndex = toIndex;
      isChange = true;
    }

    if (isChange) notifyListeners();
  }
}
