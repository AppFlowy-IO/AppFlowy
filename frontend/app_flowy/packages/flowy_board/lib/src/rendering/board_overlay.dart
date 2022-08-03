import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class BoardOverlayEntry {
  /// This entry will include the widget built by this builder in the overlay at
  /// the entry's position.
  /// The builder will be called again after calling [markNeedsBuild] on this entry.
  final WidgetBuilder builder;

  /// Whether this entry occludes the entire overlay.
  ///
  /// If an entry claims to be opaque, then, for efficiency, the overlay will
  /// skip building entries below that entry unless they have [maintainState]
  /// set.
  bool get opaque => _opaque;
  bool _opaque;

  BoardOverlayState? _overlay;
  final GlobalKey<_OverlayEntryWidgetState> _key =
      GlobalKey<_OverlayEntryWidgetState>();

  set opaque(bool value) {
    if (_opaque == value) return;

    _opaque = value;
    assert(_overlay != null);
    _overlay!._didChangeEntryOpacity();
  }

  BoardOverlayEntry({
    required this.builder,
    bool opaque = false,
  }) : _opaque = opaque;

  /// If this method is called while the [SchedulerBinding.schedulerPhase] is
  /// [SchedulerPhase.persistentCallbacks], i.e. during the build, layout, or
  /// paint phases (see [WidgetsBinding.drawFrame]), then the removal is
  /// delayed until the post-frame callbacks phase.  Otherwise the removal is done synchronously.
  void remove() {
    assert(_overlay != null, 'Should only call once');
    final BoardOverlayState overlay = _overlay!;
    _overlay = null;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        overlay._remove(this);
      });
    } else {
      overlay._remove(this);
    }
  }

  /// Cause this entry to rebuild during the next pipeline flush.
  /// You need to call this function if the output of [builder] has changed.
  void markNeedsBuild() {
    _key.currentState?._markNeedsBuild();
  }
}

/// A [Stack] of entries that can be managed independently.
///
/// Overlays let independent child widgets "float" visual elements on top of
/// other widgets by inserting them into the overlay's [Stack]. The overlay lets
/// each of these widgets manage their participation in the overlay using
/// [OverlayEntry] objects.
class BoardOverlay extends StatefulWidget {
  final List<BoardOverlayEntry> initialEntries;

  const BoardOverlay({
    this.initialEntries = const <BoardOverlayEntry>[],
    Key? key,
  }) : super(key: key);

  static BoardOverlayState of(BuildContext context,
      {Widget? debugRequiredFor}) {
    final BoardOverlayState? result =
        context.findAncestorStateOfType<BoardOverlayState>();
    assert(() {
      if (debugRequiredFor != null && result == null) {
        final String additional = context.widget != debugRequiredFor
            ? '\nThe context from which that widget was searching for an overlay was:\n  $context'
            : '';
        throw FlutterError('No Overlay widget found.\n'
            '${debugRequiredFor.runtimeType} widgets require an Overlay widget ancestor for correct operation.\n'
            'The most common way to add an Overlay to an application is to include a MaterialApp or Navigator widget in the runApp() call.\n'
            'The specific widget that failed to find an overlay was:\n'
            '  $debugRequiredFor'
            '$additional');
      }
      return true;
    }());
    return result!;
  }

  @override
  BoardOverlayState createState() => BoardOverlayState();
}

class BoardOverlayState extends State<BoardOverlay>
    with TickerProviderStateMixin {
  final List<BoardOverlayEntry> _entries = <BoardOverlayEntry>[];

  @override
  void initState() {
    super.initState();
    insertAll(widget.initialEntries);
  }

  /// Insert the given entry into the overlay.
  ///
  /// If [above] is non-null, the entry is inserted just above [above].
  /// Otherwise, the entry is inserted on top.
  void insert(BoardOverlayEntry entry, {BoardOverlayEntry? above}) {
    assert(entry._overlay == null);
    assert(
        above == null || (above._overlay == this && _entries.contains(above)));
    entry._overlay = this;
    setState(() {
      final int index =
          above == null ? _entries.length : _entries.indexOf(above) + 1;
      _entries.insert(index, entry);
    });
  }

  /// Insert all the entries in the given iterable.
  ///
  /// If [above] is non-null, the entries are inserted just above [above].
  /// Otherwise, the entries are inserted on top.
  void insertAll(Iterable<BoardOverlayEntry> entries,
      {BoardOverlayEntry? above}) {
    assert(
        above == null || (above._overlay == this && _entries.contains(above)));
    if (entries.isEmpty) return;
    for (BoardOverlayEntry entry in entries) {
      assert(entry._overlay == null);
      entry._overlay = this;
    }
    setState(() {
      final int index =
          above == null ? _entries.length : _entries.indexOf(above) + 1;
      _entries.insertAll(index, entries);
    });
  }

  void _remove(BoardOverlayEntry entry) {
    if (mounted) {
      _entries.remove(entry);
      setState(() {
        /* entry was removed */
      });
    }
  }

  void _didChangeEntryOpacity() {
    setState(() {
      // We use the opacity of the entry in our build function, which means we
      // our state has changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    // These lists are filled backwards. For the offstage children that
    // does not matter since they aren't rendered, but for the onstage
    // children we reverse the list below before adding it to the tree.
    final List<Widget> onstageChildren = <Widget>[];
    final List<Widget> offstageChildren = <Widget>[];
    bool onstage = true;
    for (int i = _entries.length - 1; i >= 0; i -= 1) {
      final BoardOverlayEntry entry = _entries[i];
      if (onstage) {
        onstageChildren.add(_OverlayEntryWidget(entry));
        if (entry.opaque) onstage = false;
      }
    }
    return _BoardStack(
      onstage: Stack(
        fit: StackFit.passthrough,
        //HanSheng changed it to passthrough so that this widget doesn't change layout constraints
        children: onstageChildren.reversed.toList(growable: false),
      ),
      offstage: offstageChildren,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<List<BoardOverlayEntry>>('entries', _entries));
  }
}

class _OverlayEntryWidget extends StatefulWidget {
  _OverlayEntryWidget(this.entry) : super(key: entry._key);

  final BoardOverlayEntry entry;

  @override
  _OverlayEntryWidgetState createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<_OverlayEntryWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.entry.builder(context);
  }

  void _markNeedsBuild() {
    setState(() {});
  }
}

/// A widget that has one [onstage] child which is visible, and one or more
/// [offstage] widgets which are kept alive, and are built, but are not laid out
/// or painted.
///
/// The onstage widget must be a Stack.
///
/// For convenience, it is legal to use [Positioned] widgets around the offstage
/// widgets.
class _BoardStack extends RenderObjectWidget {
  final Stack? onstage;
  final List<Widget> offstage;

  const _BoardStack({
    required this.offstage,
    this.onstage,
  });

  @override
  _BoardStackElement createElement() => _BoardStackElement(this);

  @override
  _RenderBoardObject createRenderObject(BuildContext context) =>
      _RenderBoardObject();
}

class _BoardStackElement extends RenderObjectElement {
  Element? _onstage;
  static final Object _onstageSlot = Object();
  late List<Element> _offstage;
  final Set<Element> _forgottenOffstageChildren = HashSet<Element>();

  _BoardStackElement(_BoardStack widget)
      : assert(!debugChildrenHaveDuplicateKeys(widget, widget.offstage)),
        super(widget);

  @override
  _BoardStack get widget => super.widget as _BoardStack;

  @override
  _RenderBoardObject get renderObject =>
      super.renderObject as _RenderBoardObject;

  @override
  void insertRenderObjectChild(RenderBox child, dynamic slot) {
    assert(renderObject.debugValidateChild(child));
    if (slot == _onstageSlot) {
      assert(child is RenderStack);
      renderObject.child = child as RenderStack?;
    } else {
      assert(slot == null || slot is Element);
      renderObject.insert(child, after: slot?.renderObject);
    }
  }

  @override
  void moveRenderObjectChild(RenderBox child, dynamic oldSlot, dynamic slot) {
    if (slot == _onstageSlot) {
      renderObject.remove(child);
      assert(child is RenderStack);
      renderObject.child = child as RenderStack?;
    } else {
      assert(slot == null || slot is Element);
      if (renderObject.child == child) {
        renderObject.child = null;
        renderObject.insert(child, after: slot?.renderObject);
      } else {
        renderObject.move(child, after: slot?.renderObject);
      }
    }
  }

  @override
  void removeRenderObjectChild(RenderBox child, dynamic slot) {
    if (renderObject.child == child) {
      renderObject.child = null;
    } else {
      renderObject.remove(child);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_onstage != null) visitor(_onstage!);
    for (Element child in _offstage) {
      if (!_forgottenOffstageChildren.contains(child)) visitor(child);
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (_onstage != null) visitor(_onstage!);
  }

  @override
  void forgetChild(Element child) {
    if (child == _onstage) {
      _onstage = null;
    } else {
      assert(_offstage.contains(child));
      assert(!_forgottenOffstageChildren.contains(child));
      _forgottenOffstageChildren.add(child);
    }
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _onstage = updateChild(_onstage, widget.onstage, _onstageSlot);
    _offstage = [];
  }

  @override
  void update(_BoardStack newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _onstage = updateChild(_onstage, widget.onstage, _onstageSlot);
    _offstage = updateChildren(_offstage, widget.offstage,
        forgottenChildren: _forgottenOffstageChildren);
    _forgottenOffstageChildren.clear();
  }
}

// A render object which lays out and paints one subtree while keeping a list
// of other subtrees alive but not laid out or painted.
//
// The subtree that is laid out and painted must be a [RenderStack].
//
// This class uses [StackParentData] objects for its parent data so that the
// children of its primary subtree's stack can be moved to this object's list
// of zombie children without changing their parent data objects.
class _RenderBoardObject extends RenderBox
    with
        RenderObjectWithChildMixin<RenderStack>,
        RenderProxyBoxMixin<RenderStack>,
        ContainerRenderObjectMixin<RenderBox, StackParentData> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! StackParentData) {
      child.parentData = StackParentData();
    }
  }

  @override
  void redepthChildren() {
    if (child != null) redepthChild(child!);
    super.redepthChildren();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (child != null) visitor(child!);
    super.visitChildren(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];

    if (child != null) children.add(child!.toDiagnosticsNode(name: 'onstage'));

    if (firstChild != null) {
      RenderBox child = firstChild!;

      int count = 1;
      while (true) {
        children.add(
          child.toDiagnosticsNode(
            name: 'offstage $count',
            style: DiagnosticsTreeStyle.offstage,
          ),
        );
        if (child == lastChild) break;
        final StackParentData childParentData =
            child.parentData! as StackParentData;
        child = childParentData.nextSibling!;
        count += 1;
      }
    } else {
      children.add(
        DiagnosticsNode.message(
          'no offstage children',
          style: DiagnosticsTreeStyle.offstage,
        ),
      );
    }
    return children;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null) visitor(child!);
  }
}
