import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

import '../model/document/node/leaf.dart' show Embed;

abstract class EmbedWidgetBuilder {
  bool canHandle(String type);

  Widget? buildeWidget(BuildContext context, Embed node);
}

/* ---------------------------------- Embed --------------------------------- */

class EmbedBuilder {
  static const kImageTypeKey = 'image';
  static const kFlutterLogoTypeKey = 'flutter_logo';

  static const builtInTypes = [kImageTypeKey, kFlutterLogoTypeKey];

  static Widget defaultBuilder(BuildContext context, Embed node) {
    assert(!kIsWeb, 'Please provide EmbedBuilder for Web');
    switch (node.value.type) {
      case kImageTypeKey:
        return _generateImageEmbed(context, node);
      case kFlutterLogoTypeKey:
        return _generateFlutterLogoEmbed(context, node);
      default:
        return Align(
          alignment: Alignment.center,
          child: _UnsupportedHintBlock(node),
        );
    }
  }

  // Generator

  static Widget _generateImageEmbed(BuildContext context, Embed node) {
    final imageUrl = standardizeImageUrl(node.value.data);
    return imageUrl.startsWith('http')
        ? Image.network(imageUrl)
        : isBase64(imageUrl)
            ? Image.memory(base64.decode(imageUrl))
            : Image.file(io.File(imageUrl));
  }

  static Widget _generateFlutterLogoEmbed(BuildContext context, Embed node) {
    final size = node.style.attributes['size'];
    var logoSize = size != null ? size.value as double? ?? 100.0 : 100.0;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: logoSize,
        height: logoSize,
        color: Colors.red,
        child: GestureDetector(
          onTap: () {
            print('Flutter logo tapped');
          },
          child: FlutterLogo(size: logoSize),
        ),
      ),
    );
  }

  // Helper

  static String standardizeImageUrl(String url) {
    if (url.contains('base64')) {
      return url.split(',')[1];
    }
    return url;
  }
}

/* ---------------------------- Unsupported Hint ---------------------------- */

class _UnsupportedHintBlock extends StatelessWidget {
  final Embed node;
  final double height;

  const _UnsupportedHintBlock(
    this.node, {
    Key? key,
    this.height = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Column(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red,
          ),
          Text('Unsupported block type "${node.value.type}"'),
        ],
      ),
    );
  }
}
