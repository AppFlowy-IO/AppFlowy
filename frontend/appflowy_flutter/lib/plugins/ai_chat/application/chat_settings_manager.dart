import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';

/// Manages settings for a chat
class ChatSettingsManager {
  ChatSettingsManager({
    required this.chatId,
  }) : selectedSourcesNotifier = ValueNotifier([]);
  final String chatId;

  /// Notifies listeners when selected sources change
  final ValueNotifier<List<String>> selectedSourcesNotifier;

  /// Load settings from backend
  Future<void> loadSettings() async {
    final getChatSettingsPayload =
        AIEventGetChatSettings(ChatId(value: chatId));

    await getChatSettingsPayload.send().then((result) {
      result.fold(
        (settings) {
          selectedSourcesNotifier.value = settings.ragIds;
        },
        (err) => Log.error("Failed to load chat settings: $err"),
      );
    });
  }

  /// Update selected sources
  Future<void> updateSelectedSources(List<String> selectedSourcesIds) async {
    selectedSourcesNotifier.value = [...selectedSourcesIds];

    final payload = UpdateChatSettingsPB(
      chatId: ChatId(value: chatId),
      ragIds: selectedSourcesIds,
    );

    await AIEventUpdateChatSettings(payload).send().onFailure(Log.error);
  }

  /// Clean up resources
  void dispose() {
    selectedSourcesNotifier.dispose();
  }
}
