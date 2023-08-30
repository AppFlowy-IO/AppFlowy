import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-plugins/protobuf.dart';
import 'package:dartz/dartz.dart';

class OpenAIService {
  static Future<Either<TextCompletionDataPB, FlowyError>>
      requestTextCompletion({
    String model = 'text-davinci-003',
    required prompt,
  }) {
    final payload = TextCompletionPayloadPB.create()
      ..model = model
      ..prompt = prompt;

    return OpenAIEventRequestTextCompletion(payload).send();
  }
}
