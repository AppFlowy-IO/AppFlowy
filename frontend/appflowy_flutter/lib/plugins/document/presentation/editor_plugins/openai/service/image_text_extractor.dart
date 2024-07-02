import 'dart:convert';
import 'dart:io';

import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

enum ImageTextExtractorError {
  failedToEncodeImage,
  failedToExtractText;

  FlowyError toFlowyError({int? errorCode}) {
    switch (this) {
      case ImageTextExtractorError.failedToEncodeImage:
        return FlowyError(
          code: ErrorCode.Internal,
          msg:
              'Failed to encode image${errorCode != null ? ' ($errorCode)' : ''}',
        );
      case ImageTextExtractorError.failedToExtractText:
        return FlowyError(
          code: ErrorCode.Internal,
          msg:
              'Failed to extract text${errorCode != null ? ' ($errorCode)' : ''}',
        );
    }
  }
}

class ImageTextExtractor {
  ImageTextExtractor({
    required this.apiKey,
    required this.imagePath,
    this.maxTokens = 1024,
  });

  final String apiKey;
  final String imagePath;
  final int maxTokens;

  Future<FlowyResult<String, FlowyError>> extractText() async {
    final imageResult = await _encodeImage();
    return imageResult.fold(
      (base64Image) => _sendImageToOpenAI(base64Image),
      (error) => Future.value(FlowyResult.failure(error)),
    );
  }

  Future<FlowyResult<String, FlowyError>> _sendImageToOpenAI(
    String base64Image,
  ) async {
    final headers = {
      'Content-Type': 'application/json;charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };
    final payload = json.encode({
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Extract the text from this image, and provide the result with formatting. (The output should only contain the result text)',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            }
          ],
        }
      ],
      'max_tokens': maxTokens,
    });
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: headers,
      body: payload,
    );
    if (response.statusCode == 200) {
      try {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final text = data['choices'][0]['message']['content'];
        return FlowyResult.success(text);
      } catch (e) {
        return FlowyResult.failure(
          ImageTextExtractorError.failedToExtractText.toFlowyError(),
        );
      }
    } else {
      return FlowyResult.failure(
        ImageTextExtractorError.failedToExtractText.toFlowyError(
          errorCode: response.statusCode,
        ),
      );
    }
  }

  Future<FlowyResult<String, FlowyError>> _encodeImage() async {
    try {
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      return FlowyResult.success(base64Encode(imageBytes));
    } catch (e) {
      return FlowyResult.failure(
        ImageTextExtractorError.failedToEncodeImage.toFlowyError(),
      );
    }
  }
}
