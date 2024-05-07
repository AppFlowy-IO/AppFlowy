import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
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
    return CallbackShortcuts(
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
              .read<BoardBloc>()
              .add(BoardEvent.startEditingRow(focusScope.value.first));
        },
        const SingleActivator(LogicalKeyboardKey.keyN): () {
          if (focusScope.value.length != 1) {
            return;
          }
          context.read<BoardBloc>().add(
                BoardEvent.startCreatingBottomRow(
                  focusScope.value.first.groupId,
                ),
              );
        },
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            _removeHandler(context),
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            _removeHandler(context),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            _enterHandler(context),
        const SingleActivator(LogicalKeyboardKey.enter, shift: true): () {
          if (focusScope.value.length != 1) {
            return;
          }
          context.read<BoardBloc>().add(
                BoardEvent.createRow(
                  focusScope.value.first.groupId,
                  OrderObjectPositionTypePB.After,
                  null,
                  focusScope.value.first.rowId,
                ),
              );
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
            _enterHandler(context),
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
    final isEditing = context.read<BoardBloc>().state.maybeMap(
          orElse: () => false,
          ready: (value) => value.editingRow != null,
        );
    if (!isEditing) {
      context
          .read<BoardBloc>()
          .add(BoardEvent.openCard(focusScope.value.first));
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
