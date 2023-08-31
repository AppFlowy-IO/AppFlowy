import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-plugins/protobuf.dart';
import 'package:dartz/dartz.dart';

class OpenAIService {
  static Future<Either<TextCompletionDataPB, FlowyError>>
      requestTextCompletion({
    required model,
    required prompt,
    required openAIKey,
  }) {
    final payload = TextCompletionPayloadPB.create()
      ..model = model
      ..prompt = prompt
      ..openAiKey = openAIKey;

    return OpenAIEventRequestTextCompletion(payload).send();
  }
}
