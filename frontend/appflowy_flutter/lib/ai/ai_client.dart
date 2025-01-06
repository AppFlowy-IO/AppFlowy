import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'error.dart';
import 'text_completion.dart';

abstract class AIRepository {
  Future<void> getStreamedCompletions({
    required String prompt,
    required Future<void> Function() onStart,
    required Future<void> Function(TextCompletionResponse response) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
    String? suffix,
    int maxTokens = 2048,
    double temperature = 0.3,
    bool useAction = false,
  });

  Future<void> streamCompletion({
    required String text,
    required CompletionTypePB completionType,
    required Future<void> Function() onStart,
    required Future<void> Function(String text) onProcess,
    required Future<void> Function() onEnd,
    required void Function(AIError error) onError,
  });

  Future<FlowyResult<List<String>, AIError>> generateImage({
    required String prompt,
    int n = 1,
  });
}
