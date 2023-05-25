import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/text_edit.dart';

import 'text_completion.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';

import 'error.dart';
import 'package:http/http.dart' as http;

// Please fill in your own API key
const apiKey = '';

enum OpenAIRequestType {
  textCompletion,
  textEdit;

  Uri get uri {
    switch (this) {
      case OpenAIRequestType.textCompletion:
        return Uri.parse('https://api.openai.com/v1/completions');
      case OpenAIRequestType.textEdit:
        return Uri.parse('https://api.openai.com/v1/edits');
    }
  }
}

abstract class OpenAIRepository {
  /// Get completions from GPT-3
  ///
  /// [prompt] is the prompt text
  /// [suffix] is the suffix text
  /// [maxTokens] is the maximum number of tokens to generate
  /// [temperature] is the temperature of the model
  ///
  Future<Either<OpenAIError, TextCompletionResponse>> getCompletions({
    required String prompt,
    String? suffix,
    int maxTokens = 2048,
    double temperature = .3,
  });

  Future<void> getStreamedCompletions({
    required String prompt,
    required Future<void> Function() onStart,
    required Future<void> Function(TextCompletionResponse response) onProcess,
    required Future<void> Function() onEnd,
    required void Function(OpenAIError error) onError,
    String? suffix,
    int maxTokens = 2048,
    double temperature = 0.3,
    bool useAction = false,
  });

  ///  Get edits from GPT-3
  ///
  /// [input] is the input text
  /// [instruction] is the instruction text
  /// [temperature] is the temperature of the model
  ///
  Future<Either<OpenAIError, TextEditResponse>> getEdits({
    required String input,
    required String instruction,
    double temperature = 0.3,
  });
}

class HttpOpenAIRepository implements OpenAIRepository {
  const HttpOpenAIRepository({
    required this.client,
    required this.apiKey,
  });

  final http.Client client;
  final String apiKey;

  Map<String, String> get headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  @override
  Future<Either<OpenAIError, TextCompletionResponse>> getCompletions({
    required String prompt,
    String? suffix,
    int maxTokens = 2048,
    double temperature = 0.3,
  }) async {
    final parameters = {
      'model': 'text-davinci-003',
      'prompt': prompt,
      'suffix': suffix,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': false,
    };

    final response = await client.post(
      OpenAIRequestType.textCompletion.uri,
      headers: headers,
      body: json.encode(parameters),
    );

    if (response.statusCode == 200) {
      return Right(
        TextCompletionResponse.fromJson(
          json.decode(
            utf8.decode(response.bodyBytes),
          ),
        ),
      );
    } else {
      return Left(OpenAIError.fromJson(json.decode(response.body)['error']));
    }
  }

  @override
  Future<void> getStreamedCompletions({
    required String prompt,
    required Future<void> Function() onStart,
    required Future<void> Function(TextCompletionResponse response) onProcess,
    required Future<void> Function() onEnd,
    required void Function(OpenAIError error) onError,
    String? suffix,
    int maxTokens = 2048,
    double temperature = 0.3,
    bool useAction = false,
  }) async {
    final parameters = {
      'model': 'text-davinci-003',
      'prompt': prompt,
      'suffix': suffix,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': true,
    };

    final request = http.Request('POST', OpenAIRequestType.textCompletion.uri);
    request.headers.addAll(headers);
    request.body = jsonEncode(parameters);

    final response = await client.send(request);

    // NEED TO REFACTOR.
    // WHY OPENAI USE TWO LINES TO INDICATE THE START OF THE STREAMING RESPONSE?
    // AND WHY OPENAI USE [DONE] TO INDICATE THE END OF THE STREAMING RESPONSE?
    int syntax = 0;
    var previousSyntax = '';
    if (response.statusCode == 200) {
      await for (final chunk in response.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())) {
        syntax += 1;
        if (!useAction) {
          if (syntax == 3) {
            await onStart();
            continue;
          } else if (syntax < 3) {
            continue;
          }
        } else {
          if (syntax == 2) {
            await onStart();
            continue;
          } else if (syntax < 2) {
            continue;
          }
        }
        final data = chunk.trim().split('data: ');
        if (data.length > 1) {
          if (data[1] != '[DONE]') {
            final response = TextCompletionResponse.fromJson(
              json.decode(data[1]),
            );
            if (response.choices.isNotEmpty) {
              final text = response.choices.first.text;
              if (text == previousSyntax && text == '\n') {
                continue;
              }
              await onProcess(response);
              previousSyntax = response.choices.first.text;
            }
          } else {
            await onEnd();
          }
        }
      }
    } else {
      final body = await response.stream.bytesToString();
      onError(
        OpenAIError.fromJson(json.decode(body)['error']),
      );
    }
    return;
  }

  @override
  Future<Either<OpenAIError, TextEditResponse>> getEdits({
    required String input,
    required String instruction,
    double temperature = 0.3,
    int n = 1,
  }) async {
    final parameters = {
      'model': 'text-davinci-edit-001',
      'input': input,
      'instruction': instruction,
      'temperature': temperature,
      'n': n,
    };

    final response = await client.post(
      OpenAIRequestType.textEdit.uri,
      headers: headers,
      body: json.encode(parameters),
    );

    if (response.statusCode == 200) {
      return Right(
        TextEditResponse.fromJson(
          json.decode(
            utf8.decode(response.bodyBytes),
          ),
        ),
      );
    } else {
      return Left(OpenAIError.fromJson(json.decode(response.body)['error']));
    }
  }
}
