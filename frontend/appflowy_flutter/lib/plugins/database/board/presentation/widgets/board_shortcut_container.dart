import 'dart:io';

import 'package:appflowy/plugins/database/board/application/board_actions_bloc.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/shared/callback_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'board_focus_scope.dart';

class BoardShortcutContainer extends StatelessWidget {
  const BoardShortcutContainer({
    super.key,
    required this.focusScope,
    required this.child,
  });

  final BoardFocusScope focusScope;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AFCallbackShortcuts(
      canAcceptEvent: (_, __) =>
          context.read<AFCallbackShortcutsProvider>().isShortcutsEnabled.value,
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            focusScope.focusPrevious,
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            focusScope.focusNext,
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            focusScope.adjustRangeUp,
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            focusScope.adjustRangeDown,
        const SingleActivator(LogicalKeyboardKey.escape): focusScope.clear,
        const SingleActivator(LogicalKeyboardKey.keyE): () {
          if (focusScope.value.length != 1) {
            return;
          }
          context
              .read<BoardActionsCubit>()
              .startEditingRow(focusScope.value.first);
        },
        const SingleActivator(LogicalKeyboardKey.keyN): () {
          if (focusScope.value.length != 1) {
            return;
          }
          context
              .read<BoardActionsCubit>()
              .startCreateBottomRow(focusScope.value.first.groupId);
          focusScope.clear();
        },
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            _removeHandler(context),
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            _removeHandler(context),
        SingleActivator(
          LogicalKeyboardKey.arrowUp,
          shift: true,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): () => _shiftCmdUpHandler(context),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            _enterHandler(context),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
            _enterHandler(context),
        const SingleActivator(LogicalKeyboardKey.enter, shift: true): () =>
            _shitEnterHandler(context),
        const SingleActivator(LogicalKeyboardKey.comma): () =>
            _moveGroupToAdjacentGroup(context, true),
        const SingleActivator(LogicalKeyboardKey.period): () =>
            _moveGroupToAdjacentGroup(context, false),
      },
      child: FocusScope(
        child: Focus(
          child: Builder(
            builder: (context) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final focusNode = Focus.of(context);
                  focusNode.requestFocus();
                  focusScope.clear();
                },
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }

  void _enterHandler(BuildContext context) {
    if (focusScope.value.length != 1) {
      return;
    }
    context
        .read<BoardActionsCubit>()
        .openCardWithRowId(focusScope.value.first.rowId);
  }

  void _shitEnterHandler(BuildContext context) {
    if (focusScope.value.isEmpty) {
      context
          .read<BoardActionsCubit>()
          .createRow(null, CreateBoardCardRelativePosition.after);
    } else if (focusScope.value.length == 1) {
      context.read<BoardActionsCubit>().createRow(
            focusScope.value.first,
            CreateBoardCardRelativePosition.after,
          );
    }
  }

  void _shiftCmdUpHandler(BuildContext context) {
    if (focusScope.value.isEmpty) {
      context
          .read<BoardActionsCubit>()
          .createRow(null, CreateBoardCardRelativePosition.before);
    } else if (focusScope.value.length == 1) {
      context.read<BoardActionsCubit>().createRow(
            focusScope.value.first,
            CreateBoardCardRelativePosition.before,
          );
    }
  }

  void _removeHandler(BuildContext context) {
    if (focusScope.value.isEmpty) {
      return;
    }
    context.read<BoardBloc>().add(BoardEvent.deleteCards(focusScope.value));
  }

  void _moveGroupToAdjacentGroup(BuildContext context, bool toPrevious) {
    if (focusScope.value.length != 1) {
      return;
    }
    context.read<BoardBloc>().add(
          BoardEvent.moveGroupToAdjacentGroup(
            focusScope.value.first,
            toPrevious,
          ),
        );
    focusScope.clear();
  }
}
