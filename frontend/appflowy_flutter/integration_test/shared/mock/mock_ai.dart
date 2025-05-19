import 'dart:async';

import 'package:appflowy/ai/service/ai_entities.dart';
import 'package:appflowy/ai/service/appflowy_ai_service.dart';
import 'package:appflowy/ai/service/error.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/operations/ai_writer_entities.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pbenum.dart';
import 'package:mocktail/mocktail.dart';

final _mockAiMap = <CompletionTypePB, Map<String, List<String>>>{
  CompletionTypePB.ImproveWriting: {
    "I have an apple": [
      "I",
      "have",
      "an",
      "apple",
      "and",
      "a",
      "banana",
    ],
  },
  CompletionTypePB.SpellingAndGrammar: {
    "We didn’t had enough money": [
      "We",
      "didn’t",
      "have",
      "enough",
      "money",
    ],
  },
  CompletionTypePB.UserQuestion: {
    "Explain the concept of TPU": [
      "TPU",
      "is",
      "a",
      "tensor",
      "processing",
      "unit",
      "that",
      "is",
      "designed",
      "to",
      "accelerate",
      "machine",
    ],
    "How about GPU?": [
      "GPU",
      "is",
      "a",
      "graphics",
      "processing",
      "unit",
      "that",
      "is",
      "designed",
      "to",
      "accelerate",
      "machine",
      "learning",
      "tasks",
    ],
  },
};

abstract class StreamCompletionValidator {
  bool validate(
    String text,
    String? objectId,
    CompletionTypePB completionType,
    PredefinedFormat? format,
    List<String> sourceIds,
    List<AiWriterRecord> history,
  );
}

class MockCompletionStream extends Mock implements CompletionStream {}

class MockAIRepository extends Mock implements AppFlowyAIService {
  MockAIRepository({this.validator});
  StreamCompletionValidator? validator;

  @override
  Future<(String, CompletionStream)?> streamCompletion({
    String? objectId,
    required String text,
    PredefinedFormat? format,
    String? promptId,
    List<String> sourceIds = const [],
    List<AiWriterRecord> history = const [],
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) processMessage,
    required Future<void> Function(String text) processAssistMessage,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
    required void Function(LocalAIStreamingState state)
        onLocalAIStreamingStateChange,
  }) async {
    if (validator != null) {
      if (!validator!.validate(
        text,
        objectId,
        completionType,
        format,
        sourceIds,
        history,
      )) {
        throw Exception('Invalid completion');
      }
    }
    final stream = MockCompletionStream();
    unawaited(
      Future(() async {
        await onStart();
        final lines = _mockAiMap[completionType]?[text.trim()];

        if (lines == null) {
          throw Exception('No mock ai found for $text and $completionType');
        }

        for (final line in lines) {
          await processMessage('$line ');
        }
        await onEnd();
      }),
    );
    return ('mock_id', stream);
  }
}
