import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../../model/document/node/leaf.dart';
import '../../widget/embed.dart';

/* --------------------------------- Sample --------------------------------- */

///
/// {
///   "insert": {
///     "flutter_logo": ""
///   },
///   "attributes" : {
///     "size": 100.0
///   }
/// }
///

/* --------------------------------- Builder -------------------------------- */

class LogoEmbedBuilder extends EmbedWidgetBuilder {
  const LogoEmbedBuilder() : super();

  static const kImageTypeKey = 'flutter_logo';

  @override
  bool canHandle(String type) {
    return type == kImageTypeKey;
  }

  @override
  Widget? buildeWidget(BuildContext context, Embed node) {
    final size = node.style.attributes['size'];
    var logoSize = size != null ? size.value as double? ?? 100.0 : 100.0;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: logoSize,
        height: logoSize,
        child: GestureDetector(
          onTap: () {
            print('Flutter logo tapped');
          },
          child: FlutterLogo(size: logoSize),
        ),
      ),
    );
  }
}
