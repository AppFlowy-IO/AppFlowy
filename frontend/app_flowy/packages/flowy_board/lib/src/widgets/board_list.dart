import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../utils/log.dart';
import 'board_list_content/content.dart';
import 'board_overlay.dart';
import 'drag_target.dart';

typedef OnDragStarted = void Function(String listId, int index);
typedef OnDragEnded = void Function(String listId);
typedef OnReorder = void Function(String listId, int fromIndex, int toIndex);
typedef OnDeleted = void Function(String listId, int deletedIndex);
typedef OnInserted = void Function(String listId, int insertedIndex);
typedef OnWillInsert = void Function(String listId, InsertedPhantom insertedPhantom);

class BoardListData extends ChangeNotifier with EquatableMixin {
  final String id;
  final _phantomNotifier = PhantomNotifier();

  final List<BoardListItem> _items;
  List<BoardListItem> get items => _items;

  BoardListData({
    required this.id,
    required List<BoardListItem> items,
  }) : _items = items;

  @override
  List<Object?> get props => [id, ..._items];

  BoardListItem removeAt(int index) {
    Log.debug('[$BoardListData] List$id remove item at $index');
    final item = _items.removeAt(index);
    notifyListeners();
    return item;
  }

  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }
    Log.debug('[$BoardListData] List$id move item from $fromIndex to $toIndex');
    final item = _items.removeAt(fromIndex);
    _items.insert(toIndex, item);
    notifyListeners();
  }

  void insert(int index, BoardListItem item) {
    Log.debug('[$BoardListData] List$id insert item at $index');
    _items.insert(index, item);
    notifyListeners();
  }

  /// Insert the [Phantom] at [insertedIndex] and remove the existing [Phantom]
  /// if it exists.
  void insertPhantom(InsertedPhantom insertedPhantom) {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      if (index != insertedPhantom.index) {
        Log.debug('[Phantom] Move phantom from $id:$index to $id:${insertedPhantom.index}');
        move(index, insertedPhantom.index);
      }
    } else {
      Log.debug('[Phantom] insert phantom at $id:${insertedPhantom.index}');
      insert(insertedPhantom.index, BoardListPhantomItem(insertedPhantom));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phantomNotifier.insert(insertedPhantom);
      });
    }
  }

  void removePhantom() {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      Log.debug('[Phantom] Remove phantom at $id:$index');
      removeAt(index);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phantomNotifier.delete(index);
      });
    }
  }

  void addPhantomListener({
    void Function(InsertedPhantom? insertedPhantom)? onInserted,
    void Function(int index)? onDeleted,
  }) {
    _phantomNotifier.addListener(
      onInserted: onInserted,
      onDeleted: onDeleted,
    );
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
  final InsertedPhantom _insertedPhantom;

  BoardListPhantomItem(InsertedPhantom insertedPhantom) : _insertedPhantom = insertedPhantom;

  @override
  bool get isPhantom => true;

  @override
  String get id => _insertedPhantom.itemData.id;

  Size? get feedbackSize => _insertedPhantom.feedbackSize;

  Widget get draggingWidget =>
      _insertedPhantom.draggingWidget == null ? const SizedBox() : _insertedPhantom.draggingWidget!;
}

typedef BoardListItemWidgetBuilder = Widget Function(BuildContext context, BoardListItem item);

class BoardList extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final BoardListData listData;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnDragStarted? onDragStarted;
  final OnReorder onReorder;
  final OnDragEnded? onDragEnded;
  final OnDeleted onDeleted;
  final OnInserted onInserted;
  final OnWillInsert onWillInserted;

  String get listId => listData.id;
  final BoardListItemWidgetBuilder _builder;

  BoardList({
    Key? key,
    this.header,
    this.footer,
    required this.listData,
    required BoardListItemWidgetBuilder builder,
    this.scrollController,
    this.config = const BoardListConfig(),
    this.onDragStarted,
    required this.onReorder,
    this.onDragEnded,
    required this.onDeleted,
    required this.onInserted,
    required this.onWillInserted,
  })  : _builder = ((BuildContext context, BoardListItem item) {
          if (item is BoardListPhantomItem) {
            return PassedInPhantomWidget(
              key: UniqueKey(),
              feedbackSize: item.feedbackSize,
              opacity: config.draggingWidgetOpacity,
              child: item.draggingWidget,
            );
          } else {
            return builder(context, item);
          }
        }),
        super(key: key);

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
          final children = widget.listData.items.map((item) => widget._builder(context, item)).toList();

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
            onWillInserted: (insertedPhantom) {
              widget.onWillInserted(widget.listId, insertedPhantom);
            },
            listData: widget.listData,
            builder: widget._builder,
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

class PhantomNotifier {
  final _insertNotifier = PhantomInsertNotifier();

  final _deleteNotifier = PhantomDeleteNotifier();

  void insert(InsertedPhantom insertedIndex) {
    _insertNotifier.insert(insertedIndex);
  }

  void delete(int deletedIndex) {
    _deleteNotifier.delete(deletedIndex);
  }

  void addListener({
    void Function(InsertedPhantom? insertedPhantom)? onInserted,
    void Function(int index)? onDeleted,
  }) {
    if (onInserted != null) {
      _insertNotifier.addListener(() {
        onInserted(_insertNotifier.insertedPhantom);
      });
    }

    if (onDeleted != null) {
      _deleteNotifier.addListener(() {
        onDeleted(_deleteNotifier.deletedIndex);
      });
    }
  }
}

class PhantomInsertNotifier extends ChangeNotifier {
  InsertedPhantom? insertedPhantom;

  void insert(InsertedPhantom insertedPhantom) {
    if (this.insertedPhantom != insertedPhantom) {
      this.insertedPhantom = insertedPhantom;
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

class InsertedPhantom {
  final int index;
  final Widget? draggingWidget;
  final Size? feedbackSize;
  final BoardListItem itemData;

  InsertedPhantom({
    required this.draggingWidget,
    required this.feedbackSize,
    required this.index,
    required this.itemData,
  });
}
