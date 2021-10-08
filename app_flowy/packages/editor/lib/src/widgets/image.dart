import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';

class ImageTapWrapper extends StatelessWidget {
  const ImageTapWrapper({
    this.imageProvider,
  });

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: GestureDetector(
          onTapDown: (_) {
            Navigator.pop(context);
          },
          child: PhotoView(
            imageProvider: imageProvider,
          ),
        ),
      ),
    );
  }
}
