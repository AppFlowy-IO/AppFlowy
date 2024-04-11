import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/stability_ai/stability_ai_error.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

enum StabilityAIRequestType {
  imageGenerations;

  Uri get uri {
    switch (this) {
      case StabilityAIRequestType.imageGenerations:
        return Uri.parse(
          'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
        );
    }
  }
}

abstract class StabilityAIRepository {
  /// Generate image from Stability AI
  ///
  /// [prompt] is the prompt text
  /// [n] is the number of images to generate
  ///
  /// the return value is a list of base64 encoded images
  Future<FlowyResult<List<String>, StabilityAIRequestError>> generateImage({
    required String prompt,
    int n = 1,
  });
}

class HttpStabilityAIRepository implements StabilityAIRepository {
  const HttpStabilityAIRepository({
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
  Future<FlowyResult<List<String>, StabilityAIRequestError>> generateImage({
    required String prompt,
    int n = 1,
  }) async {
    final parameters = {
      'text_prompts': [
        {
          'text': prompt,
        }
      ],
      'samples': n,
    };

    try {
      final response = await client.post(
        StabilityAIRequestType.imageGenerations.uri,
        headers: headers,
        body: json.encode(parameters),
      );

      final data = json.decode(
        utf8.decode(response.bodyBytes),
      );
      if (response.statusCode == 200) {
        final artifacts = data['artifacts'] as List;
        final base64Images = artifacts
            .map(
              (e) => e['base64'].toString(),
            )
            .toList();
        return FlowyResult.success(base64Images);
      } else {
        return FlowyResult.failure(
          StabilityAIRequestError(
            data['message'].toString(),
          ),
        );
      }
    } catch (error) {
      return FlowyResult.failure(
        StabilityAIRequestError(
          error.toString(),
        ),
      );
    }
  }
}
