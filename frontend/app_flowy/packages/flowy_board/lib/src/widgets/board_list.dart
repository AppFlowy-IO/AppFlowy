import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../utils/log.dart';
import 'board_list_content/content.dart';
import 'board_list_content/state.dart';
import 'board_overlay.dart';
import 'drag_target.dart';

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
  final PassedInPhantomContext phantomContext;

  BoardListPhantomItem(PassedInPhantomContext insertedPhantom) : phantomContext = insertedPhantom;

  @override
  bool get isPhantom => true;

  @override
  String get id => phantomContext.itemData.id;

  Size? get feedbackSize => phantomContext.feedbackSize;

  Widget get draggingWidget =>
      phantomContext.draggingWidget == null ? const SizedBox() : phantomContext.draggingWidget!;
}

typedef BoardListItemWidgetBuilder = Widget Function(BuildContext context, BoardListItem item);

class BoardList extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final BoardListData listData;
  final ScrollController? scrollController;
  final BoardListConfig config;
  final OnListDragStarted? onDragStarted;
  final OnListReorder onReorder;
  final OnListDragEnded? onDragEnded;
  final OnListInsertPassedInPhantom onPassedInPhantom;

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
    required this.onPassedInPhantom,
  })  : _builder = ((BuildContext context, BoardListItem item) {
          if (item is BoardListPhantomItem) {
            return PassedInPhantomWidget(
              key: UniqueKey(),
              opacity: config.draggingWidgetOpacity,
              phantomContext: item.phantomContext,
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
            onPassedInPhantom: (draggingContext, phantomIndex) {
              widget.onPassedInPhantom(widget.listId, draggingContext, phantomIndex);
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

  void insert(PassedInPhantomContext insertedIndex) {
    _insertNotifier.insert(insertedIndex);
  }

  void delete(int deletedIndex) {
    _deleteNotifier.delete(deletedIndex);
  }

  void addListener({
    void Function(PassedInPhantomContext? insertedPhantom)? onInserted,
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
  PassedInPhantomContext? insertedPhantom;

  void insert(PassedInPhantomContext insertedPhantom) {
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

class PassedInPhantomContext {
  int index;
  final DraggingContext draggingContext;

  Size? get feedbackSize => draggingContext.state.feedbackSize;

  Widget? get draggingWidget => draggingContext.draggingWidget;

  BoardListItem get itemData => draggingContext.bindData;

  VoidCallback? onInserted;

  VoidCallback? onDeleted;

  PassedInPhantomContext({
    required this.index,
    required this.draggingContext,
  });
}

typedef OnListDragStarted = void Function(String listId, int index);
typedef OnListDragEnded = void Function(String listId);
typedef OnListReorder = void Function(String listId, int fromIndex, int toIndex);
typedef OnListDeleted = void Function(String listId, int deletedIndex);
typedef OnListInserted = void Function(String listId, int insertedIndex);
typedef OnListInsertPassedInPhantom = void Function(String listId, DraggingContext draggingContext, int phantomIndex);

class BoardListData extends ChangeNotifier with EquatableMixin {
  final String id;
  final phantomNotifier = PhantomNotifier();

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
    Log.debug('[$BoardListData] List$id move item from $fromIndex to $toIndex');
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
  void insertPhantom(DraggingContext draggingContext, int phantomIndex) {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      if (index != phantomIndex) {
        Log.debug('[PassedInPhantom] List$id move $id:$index to $id:$phantomIndex');
        final item = _items.removeAt(index);
        _items.insert(phantomIndex, item);

        // move(index, insertedPhantom.index);
      }
    } else {
      Log.debug('[PassedInPhantom] List$id insert $id:$phantomIndex');
      final insertedPhantom = PassedInPhantomContext(
        index: phantomIndex,
        draggingContext: draggingContext,
      );

      phantomNotifier.addListener(
        onInserted: (c) => insertedPhantom.onInserted?.call(),
        onDeleted: (c) => insertedPhantom.onDeleted?.call(),
      );

      insert(phantomIndex, BoardListPhantomItem(insertedPhantom));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        phantomNotifier.insert(insertedPhantom);
      });
    }
  }

  void removePassedInPhantom() {
    final index = _items.indexWhere((item) => item.isPhantom);
    if (index != -1) {
      Log.debug('[PassedInPhantom] List$id delete $id:$index');
      _items.removeAt(index);
      phantomNotifier.delete(index);
    }
  }
}
