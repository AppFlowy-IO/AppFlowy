import 'dart:async';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/menu/menu_extension.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'mention_menu.dart';

class MentionMenuService extends InlineActionsMenuService {
  MentionMenuService({
    required this.context,
    required this.editorState,
    required this.workspaceBloc,
    required this.documentBloc,
    required this.reminderBloc,
    this.startCharAmount = 1,
  });

  final BuildContext context;
  final EditorState editorState;
  final UserWorkspaceBloc workspaceBloc;
  final DocumentBloc documentBloc;
  final ReminderBloc reminderBloc;
  final int startCharAmount;

  OverlayEntry? _menuEntry;

  @override
  void dismiss() {
    if (_menuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
      keepEditorFocusNotifier.decrease();
    }

    _menuEntry?.remove();
    _menuEntry = null;
  }

  @override
  Future<void> show() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _show(
        MentionMenuBuilderInfo(
          builder: (service, ltrb) => _buildMentionMenu(ltrb),
          menuSize: Size.square(400),
        ),
      );
      completer.complete();
    });
    return completer.future;
  }

  @override
  InlineActionsMenuStyle get style => throw UnimplementedError();

  void _show(MentionMenuBuilderInfo builderInfo) {
    dismiss();

    final menuPosition = editorState.calculateMenuOffset(
      menuSize: builderInfo.menuSize,
      menuOffset: Offset.zero,
    );
    if (menuPosition == null) return;
    final ltrb = menuPosition.ltrb;

    final editorSize = editorState.renderBox!.size;
    _menuEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: SizedBox(
          height: editorSize.height,
          width: editorSize.width,
          // GestureDetector handles clicks outside of the context menu,
          // to dismiss the context menu.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: dismiss,
            child: Stack(
              children: [
                ltrb.buildPositioned(
                  child: builderInfo.builder.call(this, ltrb),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuEntry!);

    final editorService = editorState.service;

    editorService.keyboardService?.disable(showCursor: true);
    editorService.scrollService?.disable();
  }

  Widget _buildMentionMenu(LTRB ltrb) {
    final editorHeight = editorState.renderBox!.size.height;
    return buildMultiBlocProvider(
      (_) => Provider(
        create: (_) => MentionMenuServiceInfo(
          onDismiss: dismiss,
          startCharAmount: startCharAmount,
          startOffset: editorState.selection?.endIndex ?? 0,
          editorState: editorState,
          top: ltrb.top ?? (editorHeight - (ltrb.bottom ?? 0.0) - 400),
          onMenuReplace: (info) {
            keepEditorFocusNotifier.increase();
            _show(info);
          },
        ),
        dispose: (context, value) => value._dispose(),
        child: MentionMenu(),
      ),
    );
  }

  MultiBlocProvider buildMultiBlocProvider(WidgetBuilder builder) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: workspaceBloc),
        BlocProvider.value(value: documentBloc),
        BlocProvider.value(value: reminderBloc),
      ],
      child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
        builder: (context, __) => builder.call(context),
      ),
    );
  }
}

typedef MentionMenuBuilder = Widget Function(
  MentionMenuService service,
  LTRB ltrb,
);

class MentionMenuBuilderInfo {
  MentionMenuBuilderInfo({
    required this.builder,
    required this.menuSize,
  });

  final MentionMenuBuilder builder;
  final Size menuSize;
}

class MentionMenuServiceInfo {
  MentionMenuServiceInfo({
    required this.onDismiss,
    required this.startCharAmount,
    required this.startOffset,
    required this.editorState,
    required this.top,
    required this.onMenuReplace,
  });

  final VoidCallback onDismiss;
  final int startCharAmount;
  final int startOffset;
  final EditorState editorState;
  final double top;
  final Map<String, ValueGetter<double>> _itemYMap = {};
  final ValueChanged<MentionMenuBuilderInfo> onMenuReplace;

  void addItemHeightGetter(String id, ValueGetter<double> yGetter) {
    _itemYMap[id] = yGetter;
  }

  void removeItemHeightGetter(String id) => _itemYMap.remove(id);

  void _dispose() {
    _itemYMap.clear();
  }

  double? getItemPositionY(String id) => _itemYMap[id]?.call();

  bool isTopArea(String id) {
    final itemY = getItemPositionY(id);
    if (itemY == null) return false;
    return itemY <= top + 200;
  }

  TextRange textRange(String queryText) => TextRange(
        start: startOffset - startCharAmount,
        end: queryText.length + startCharAmount,
      );
}
