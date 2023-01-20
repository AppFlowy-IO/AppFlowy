import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

// Please fill in your own API key
const apiKey = '';

enum GPT3API {
  completion,
  edit,
}

extension on GPT3API {
  Uri get uri {
    switch (this) {
      case GPT3API.completion:
        return Uri.parse('https://api.openai.com/v1/completions');
      case GPT3API.edit:
        return Uri.parse('https://api.openai.com/v1/edits');
    }
  }
}

class GPT3APIClient {
  const GPT3APIClient({
    required this.apiKey,
  });

  final String apiKey;

  /// Get completions from GPT-3
  ///
  /// [prompt] is the prompt text
  /// [suffix] is the suffix text
  /// [onResult] is the callback function to handle the result
  /// [maxTokens] is the maximum number of tokens to generate
  /// [temperature] is the temperature of the model
  ///
  /// See https://beta.openai.com/docs/api-reference/completions/create
  Future<void> getGPT3Completion(
    String prompt,
    String suffix, {
    required Future<void> Function(String result) onResult,
    required Future<void> Function() onError,
    int maxTokens = 200,
    double temperature = .3,
  }) async {
    final data = {
      'model': 'text-davinci-003',
      'prompt': prompt,
      'suffix': suffix,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': false,
    };

    final headers = {
      'Authorization': apiKey,
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      GPT3API.completion.uri,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final choices = result['choices'];
      if (choices != null && choices is List) {
        for (final choice in choices) {
          final text = choice['text'];
          await onResult(text);
        }
      }
    } else {
      await onError();
    }
  }

  Future<void> getGPT3Edit(
    String apiKey,
    String input,
    String instruction, {
    required Future<void> Function(List<String> result) onResult,
    required Future<void> Function() onError,
    int n = 1,
    double temperature = .3,
  }) async {
    final data = {
      'model': 'text-davinci-edit-001',
      'input': input,
      'instruction': instruction,
      'temperature': temperature,
      'n': n,
    };

    final headers = {
      'Authorization': apiKey,
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/edits'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final choices = result['choices'];
      if (choices != null && choices is List) {
        await onResult(choices.map((e) => e['text'] as String).toList());
      }
    } else {
      await onError();
    }
  }
}
