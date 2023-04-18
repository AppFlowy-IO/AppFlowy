import 'package:dartz/dartz.dart';

Either<Uri, FormatException> parseValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      throw const FormatException('Invalid URL');
    }
    return left(uri);
  } on FormatException catch (e) {
    return right(e);
  }
}
