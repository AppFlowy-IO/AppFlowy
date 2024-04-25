import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/service/text_edit.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

import 'error.dart';
import 'text_completion.dart';

enum OpenAIRequestType {
  textCompletion,
  textEdit,
  imageGenerations;

  Uri get uri {
    switch (this) {
      case OpenAIRequestType.textCompletion:
        return Uri.parse('https://api.openai.com/v1/completions');
      case OpenAIRequestType.textEdit:
        return Uri.parse('https://api.openai.com/v1/completions');
      case OpenAIRequestType.imageGenerations:
        return Uri.parse('https://api.openai.com/v1/images/generations');
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
  Future<FlowyResult<TextCompletionResponse, OpenAIError>> getCompletions({
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
  Future<FlowyResult<TextEditResponse, OpenAIError>> getEdits({
    required String input,
    required String instruction,
    double temperature = 0.3,
  });

  /// Generate image from GPT-3
  ///
  /// [prompt] is the prompt text
  /// [n] is the number of images to generate
  ///
  /// the result is a list of urls
  Future<FlowyResult<List<String>, OpenAIError>> generateImage({
    required String prompt,
    int n = 1,
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
  Future<FlowyResult<TextCompletionResponse, OpenAIError>> getCompletions({
    required String prompt,
    String? suffix,
    int maxTokens = 2048,
    double temperature = 0.3,
  }) async {
    final parameters = {
      'model': 'gpt-3.5-turbo-instruct',
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
      return FlowyResult.success(
        TextCompletionResponse.fromJson(
          json.decode(
            utf8.decode(response.bodyBytes),
          ),
        ),
      );
    } else {
      return FlowyResult.failure(
        OpenAIError.fromJson(json.decode(response.body)['error']),
      );
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
      'model': 'gpt-3.5-turbo-instruct',
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
  Future<FlowyResult<TextEditResponse, OpenAIError>> getEdits({
    required String input,
    required String instruction,
    double temperature = 0.3,
    int n = 1,
  }) async {
    final parameters = {
      'model': 'gpt-4',
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
      return FlowyResult.success(
        TextEditResponse.fromJson(
          json.decode(
            utf8.decode(response.bodyBytes),
          ),
        ),
      );
    } else {
      return FlowyResult.failure(
        OpenAIError.fromJson(json.decode(response.body)['error']),
      );
    }
  }

  @override
  Future<FlowyResult<List<String>, OpenAIError>> generateImage({
    required String prompt,
    int n = 1,
  }) async {
    final parameters = {
      'prompt': prompt,
      'n': n,
      'size': '512x512',
    };

    try {
      final response = await client.post(
        OpenAIRequestType.imageGenerations.uri,
        headers: headers,
        body: json.encode(parameters),
      );

      if (response.statusCode == 200) {
        final data = json.decode(
          utf8.decode(response.bodyBytes),
        )['data'] as List;
        final urls = data
            .map((e) => e.values)
            .expand((e) => e)
            .map((e) => e.toString())
            .toList();
        return FlowyResult.success(urls);
      } else {
        return FlowyResult.failure(
          OpenAIError.fromJson(json.decode(response.body)['error']),
        );
      }
    } catch (error) {
      return FlowyResult.failure(OpenAIError(message: error.toString()));
    }
  }
}
