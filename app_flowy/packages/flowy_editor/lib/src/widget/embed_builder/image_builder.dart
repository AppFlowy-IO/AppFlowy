import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

import '../../model/document/node/leaf.dart' show Embed;
import '../embed.dart';

/* --------------------------------- Sample --------------------------------- */

///
/// {
///   "insert": {
///     "image": "https://test.com/sample.png"
///   },
///   "attributes" : {
///     "width": "100.0"
///   }
/// }
///

/* --------------------------------- Builder -------------------------------- */

class ImageEmbedBuilder extends EmbedWidgetBuilder {
  const ImageEmbedBuilder() : super();

  static const kImageTypeKey = 'image';

  @override
  bool canHandle(String type) {
    return type == kImageTypeKey;
  }

  @override
  Widget? buildeWidget(BuildContext context, Embed node) {
    final imageUrl = _standardizeImageUrl(node.value.data);
    return imageUrl.startsWith('http')
        ? Image.network(imageUrl)
        : isBase64(imageUrl)
            ? Image.memory(base64.decode(imageUrl))
            : Image.file(io.File(imageUrl));
  }

  String _standardizeImageUrl(String url) {
    if (url.contains('base64')) {
      return url.split(',')[1];
    }
    return url;
  }
}
