import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// Please fill in your own API key
const stabilityAIApiKey = '';

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
  Future<List<String>> generateImage({
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
  Future<List<String>> generateImage({
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

      if (response.statusCode == 200) {
        final data = json.decode(
          utf8.decode(response.bodyBytes),
        )['artifacts'] as List;
        final base64Images = data
            .map(
              (e) => e['base64'].toString(),
            )
            .toList();
        return base64Images;
      } else {
        return [];
      }
    } catch (error) {
      return [];
    }
  }
}
