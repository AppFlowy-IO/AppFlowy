import 'package:flowy_editor/src/widget/embed_builder/logo_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widget/embed_builder/image_builder.dart';
import '../model/document/node/leaf.dart' show Embed;

abstract class EmbedWidgetBuilder {
  const EmbedWidgetBuilder();

  bool canHandle(String type);

  Widget? buildeWidget(BuildContext context, Embed node);
}

/* ---------------------------------- Embed --------------------------------- */
class EmbedBaseProvider {
  static const kFlutterLogoTypeKey = 'flutter_logo';

  static const builtInProviders = <EmbedWidgetBuilder>[
    ImageEmbedBuilder(),
    LogoEmbedBuilder(),
  ];

  static Widget buildEmbedWidget(BuildContext context, Embed node) {
    Widget? result;
    for (final builder in builtInProviders) {
      if (builder.canHandle(node.value.type)) {
        result = builder.buildeWidget(context, node);
        if (result != null) {
          break;
        }
      }
    }
    return result ?? Align(alignment: Alignment.center, child: _UnsupportedHintBlock(node));
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
