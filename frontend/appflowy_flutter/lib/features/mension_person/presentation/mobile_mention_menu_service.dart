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
import 'mention_menu_service.dart';

class MobileMentionMenuService extends MentionMenuService {
  MobileMentionMenuService({
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
      final screenSize = MediaQuery.of(context).size;
      _show(
        MentionMenuBuilderInfo(
          builder: (service, ltrb) => _buildMentionMenu(ltrb),
          menuSize: Size(screenSize.width - 40, 240),
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
      builder: (context) {
        return Material(
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
                  Positioned(
                    left: 20,
                    right: 20,
                    top: ltrb.top,
                    bottom: ltrb.bottom,
                    child: builderInfo.builder.call(this, ltrb),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_menuEntry!);

    final editorService = editorState.service;

    editorService.keyboardService?.disable(showCursor: true);
    editorService.scrollService?.disable();
  }

  Widget _buildMentionMenu(LTRB ltrb) {
    final editorHeight = editorState.renderBox!.size.height;
    return buildMultiBlocProvider(
      (context) {
        final screenSize = MediaQuery.of(context).size;
        return Provider(
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
          dispose: (context, value) => value.dispose(),
          child: MentionMenu(
            width: screenSize.width - 40,
            maxHeight: 240,
          ),
        );
      },
    );
  }

  @override
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
