import 'package:appflowy/shared/clipboard_state.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:provider/provider.dart';

import '../plugins.dart';
import '../transaction_handler/mention_transaction_handler.dart';

const _pasteIdentifier = 'date_transaction';

class DateTransactionHandler extends MentionTransactionHandler {
  DateTransactionHandler();

  @override
  Future<void> onTransaction(
    BuildContext context,
    String viewId,
    EditorState editorState,
    List<MentionBlockData> added,
    List<MentionBlockData> removed, {
    bool isCut = false,
    bool isUndoRedo = false,
    bool isPaste = false,
    bool isDraggingNode = false,
    bool isTurnInto = false,
    String? parentViewId,
  }) async {
    if (isDraggingNode || isTurnInto) {
      return;
    }

    // Remove the mentions that were both added and removed in the same transaction.
    // These were just moved around.
    final moved = <MentionBlockData>[];
    for (final mention in added) {
      if (removed.any((r) => r.$2 == mention.$2)) {
        moved.add(mention);
      }
    }

    for (final mention in removed) {
      if (!context.mounted || moved.any((m) => m.$2 == mention.$2)) {
        return;
      }

      if (mention.$2[MentionBlockKeys.type] != MentionType.date.name) {
        continue;
      }

      _handleDeletion(context, mention);
    }

    if (isPaste || isUndoRedo) {
      if (context.mounted) {
        context.read<ClipboardState>().startHandlingPaste(_pasteIdentifier);
      }

      for (final mention in added) {
        if (!context.mounted || moved.any((m) => m.$2 == mention.$2)) {
          return;
        }

        if (mention.$2[MentionBlockKeys.type] != MentionType.date.name) {
          continue;
        }

        _handleAddition(
          context,
          viewId,
          editorState,
          mention,
          isPaste,
          isCut,
        );
      }

      if (context.mounted) {
        context.read<ClipboardState>().endHandlingPaste(_pasteIdentifier);
      }
    }
  }

  void _handleDeletion(
    BuildContext context,
    MentionBlockData data,
  ) {
    final reminderId = data.$2[MentionBlockKeys.reminderId];

    if (reminderId case String _ when reminderId.isNotEmpty) {
      getIt<ReminderBloc>().add(ReminderEvent.remove(reminderId: reminderId));
    }
  }

  void _handleAddition(
    BuildContext context,
    String viewId,
    EditorState editorState,
    MentionBlockData data,
    bool isPaste,
    bool isCut,
  ) {
    final dateData = _MentionDateBlockData.fromData(data.$2);
    if (dateData.dateString.isEmpty) {
      Log.error("mention date block doesn't have a valid date string");
      return;
    }

    if (isPaste && !isCut) {
      _handlePasteFromCopy(
        context,
        viewId,
        editorState,
        data.$1,
        data.$3,
        dateData,
      );
    } else {
      _handlePasteFromCut(viewId, data.$1, dateData);
    }
  }

  void _handlePasteFromCut(
    String viewId,
    Node node,
    _MentionDateBlockData data,
  ) {
    final dateTime = DateTime.tryParse(data.dateString);

    if (data.reminderId == null || dateTime == null) {
      return;
    }

    getIt<ReminderBloc>().add(
      ReminderEvent.addById(
        reminderId: data.reminderId!,
        objectId: viewId,
        scheduledAt: Int64(
          data.reminderOption
                  .getNotificationDateTime(dateTime)
                  .millisecondsSinceEpoch ~/
              1000,
        ),
        meta: {
          ReminderMetaKeys.includeTime: data.includeTime.toString(),
          ReminderMetaKeys.blockId: node.id,
        },
      ),
    );
  }

  void _handlePasteFromCopy(
    BuildContext context,
    String viewId,
    EditorState editorState,
    Node node,
    int index,
    _MentionDateBlockData data,
  ) async {
    final dateTime = DateTime.tryParse(data.dateString);

    if (data.reminderId == null || dateTime == null) {
      return;
    }

    final reminderId = nanoid();
    getIt<ReminderBloc>().add(
      ReminderEvent.addById(
        reminderId: reminderId,
        objectId: viewId,
        scheduledAt: Int64(
          data.reminderOption
                  .getNotificationDateTime(dateTime)
                  .millisecondsSinceEpoch ~/
              1000,
        ),
        meta: {
          ReminderMetaKeys.includeTime: data.includeTime.toString(),
          ReminderMetaKeys.blockId: node.id,
        },
      ),
    );

    final newMentionAttributes = {
      MentionBlockKeys.mention: {
        MentionBlockKeys.type: MentionType.date.name,
        MentionBlockKeys.date: dateTime.toIso8601String(),
        MentionBlockKeys.reminderId: reminderId,
        MentionBlockKeys.includeTime: data.includeTime,
        MentionBlockKeys.reminderOption: data.reminderOption.name,
      },
    };

    // The index is the index of the delta, to get the index of the mention character
    // in all the text, we need to calculate it based on the deltas before the current delta.
    int mentionIndex = 0;
    for (final (i, delta) in node.delta!.indexed) {
      if (i >= index) {
        break;
      }

      mentionIndex += delta.length;
    }

    // Required to prevent editing the same spot at the same time
    await Future.delayed(const Duration(milliseconds: 100));

    final transaction = editorState.transaction
      ..formatText(
        node,
        mentionIndex,
        MentionBlockKeys.mentionChar.length,
        newMentionAttributes,
      );

    await editorState.apply(
      transaction,
      options: const ApplyOptions(recordUndo: false),
    );
  }
}

/// A helper class to parse and store the mention date block data
class _MentionDateBlockData {
  _MentionDateBlockData.fromData(Map<String, dynamic> data) {
    dateString = switch (data[MentionBlockKeys.date]) {
      final String string when DateTime.tryParse(string) != null => string,
      _ => "",
    };
    includeTime = switch (data[MentionBlockKeys.includeTime]) {
      final bool flag => flag,
      _ => false,
    };
    reminderOption = switch (data[MentionBlockKeys.reminderOption]) {
      final String name =>
        ReminderOption.values.firstWhereOrNull((o) => o.name == name) ??
            ReminderOption.none,
      _ => ReminderOption.none,
    };
    reminderId = switch (data[MentionBlockKeys.reminderId]) {
      final String id
          when id.isNotEmpty && reminderOption != ReminderOption.none =>
        id,
      _ => null,
    };
  }

  late final String dateString;
  late final bool includeTime;
  late final String? reminderId;
  late final ReminderOption reminderOption;
}
