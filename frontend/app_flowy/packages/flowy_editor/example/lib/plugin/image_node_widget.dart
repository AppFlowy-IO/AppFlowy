import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImageNodeBuilder extends NodeWidgetBuilder {
  ImageNodeBuilder.create({
    required super.node,
    required super.editorState,
  }) : super.create();

  String get src => node.attributes['image_src'] as String;

  @override
  Widget build(BuildContext buildContext) {
    // Future.delayed(const Duration(seconds: 5), () {
    //   node.updateAttributes({
    //     'image_src':
    //         "https://images.pexels.com/photos/9995076/pexels-photo-9995076.png?cs=srgb&dl=pexels-temmuz-uzun-9995076.jpg&fm=jpg&w=640&h=400"
    //   });
    // });
    return GestureDetector(
      child: ChangeNotifierProvider.value(
        value: node,
        builder: (context, child) {
          return Consumer<Node>(
            builder: (context, value, child) {
              return _build(context);
            },
          );
        },
      ),
      onTap: () {
        const newImageSrc =
            "https://images.pexels.com/photos/9995076/pexels-photo-9995076.png?cs=srgb&dl=pexels-temmuz-uzun-9995076.jpg&fm=jpg&w=640&h=400";
        final newAttribute = Attributes.from(node.attributes)
          ..update(
            'image_src',
            (value) => newImageSrc,
          );
        editorState.update(node, newAttribute);
      },
    );
  }

  Widget _build(BuildContext buildContext) {
    final image = Image.network(src);
    Widget? children;
    if (node.children.isNotEmpty) {
      children = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: node.children
            .map(
              (e) => renderPlugins.buildWidget(
                context: NodeWidgetContext(
                  buildContext: buildContext,
                  node: e,
                  editorState: editorState,
                ),
              ),
            )
            .toList(),
      );
    }
    if (children != null) {
      return Column(
        children: [
          image,
          children,
        ],
      );
    } else {
      return image;
    }
  }
}
