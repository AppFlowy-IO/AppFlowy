import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/cover_image_gradient_colors.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

double kDocumentCoverHeight = 98.0;

class DocumentImmersiveCover extends StatelessWidget {
  const DocumentImmersiveCover({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DocumentImmersiveCoverBloc(view: view)
        ..add(const DocumentImmersiveCoverEvent.initial()),
      child:
          BlocBuilder<DocumentImmersiveCoverBloc, DocumentImmersiveCoverState>(
        builder: (_, state) {
          final cover = state.cover;
          final type = cover.type;
          final naviBarHeight = MediaQuery.of(context).padding.top;
          final height = naviBarHeight + kDocumentCoverHeight;

          if (type == PageStyleCoverImageType.customImage ||
              type == PageStyleCoverImageType.unsplashImage) {
            return SizedBox(
              height: height,
              child: FlowyNetworkImage(url: cover.value),
            );
          }

          if (type == PageStyleCoverImageType.builtInImage) {
            return SizedBox(
              height: height,
              child: Image.asset(
                PageStyleCoverImageType.builtInImagePath(cover.value),
                fit: BoxFit.cover,
              ),
            );
          }

          if (type == PageStyleCoverImageType.pureColor) {
            return Container(
              height: height,
              color: FlowyTint.fromId(cover.value).color(context),
            );
          }

          if (type == PageStyleCoverImageType.gradientColor) {
            return Container(
              height: height,
              decoration: BoxDecoration(
                gradient: FlowyGradientColor.fromId(cover.value).linear,
              ),
            );
          }

          return SizedBox(
            height: naviBarHeight,
          );
        },
      ),
    );
  }
}
