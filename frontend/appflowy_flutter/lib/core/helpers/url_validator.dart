import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'url_validator.freezed.dart';

Either<UriFailure, Uri> parseValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      return left(const UriFailure.invalidSchemeHost());
    }
    return right(uri);
  } on FormatException {
    return left(const UriFailure.invalidUriFormat());
  }
}

@freezed
class UriFailure with _$UriFailure {
  const factory UriFailure.invalidSchemeHost() = _InvalidSchemeHost;
  const factory UriFailure.invalidUriFormat() = _InvalidUriFormat;
}
