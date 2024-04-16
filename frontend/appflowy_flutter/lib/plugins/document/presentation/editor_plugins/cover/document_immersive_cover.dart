import 'dart:io';

import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/build_context_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

double kDocumentCoverHeight = 98.0;
double kDocumentTitlePadding = 20.0;

class DocumentImmersiveCover extends StatelessWidget {
  const DocumentImmersiveCover({
    super.key,
    required this.view,
    required this.userProfilePB,
  });

  final ViewPB view;
  final UserProfilePB userProfilePB;

  @override
  Widget build(BuildContext context) {
    return IgnoreParentGestureWidget(
      child: BlocProvider(
        create: (context) => DocumentImmersiveCoverBloc(view: view)
          ..add(const DocumentImmersiveCoverEvent.initial()),
        child: BlocBuilder<DocumentImmersiveCoverBloc,
            DocumentImmersiveCoverState>(
          builder: (_, state) {
            final iconAndTitle = _buildIconAndTitle(context, state);
            if (state.cover.type == PageStyleCoverImageType.none) {
              return Padding(
                padding: EdgeInsets.only(
                  top: context.statusBarAndAppBarHeight + kDocumentTitlePadding,
                ),
                child: iconAndTitle,
              );
            }

            return Stack(
              children: [
                _buildCover(context, state),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: iconAndTitle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIconAndTitle(
    BuildContext context,
    DocumentImmersiveCoverState state,
  ) {
    final title = state.name;
    final icon = state.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (icon != null && icon.isNotEmpty) ...[
            GestureDetector(
              child: EmojiIconWidget(
                emoji: icon,
                emojiSize: 26,
              ),
              onTap: () async {
                final result = await context.push<EmojiPickerResult>(
                  MobileEmojiPickerScreen.routeName,
                );
                if (result != null && context.mounted) {
                  context
                      .read<ViewBloc>()
                      .add(ViewEvent.updateIcon(result.emoji));
                }
              },
            ),
            const HSpace(8.0),
          ],
          FlowyText(
            title,
            fontSize: 28.0,
            fontWeight: FontWeight.w700,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context, DocumentImmersiveCoverState state) {
    final cover = state.cover;
    final type = cover.type;
    final naviBarHeight = MediaQuery.of(context).padding.top;
    final height = naviBarHeight + kDocumentCoverHeight;

    if (type == PageStyleCoverImageType.customImage ||
        type == PageStyleCoverImageType.unsplashImage) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child:
            FlowyNetworkImage(url: cover.value, userProfilePB: userProfilePB),
      );
    }

    if (type == PageStyleCoverImageType.builtInImage) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          PageStyleCoverImageType.builtInImagePath(cover.value),
          fit: BoxFit.cover,
        ),
      );
    }

    if (type == PageStyleCoverImageType.pureColor) {
      return Container(
        height: height,
        width: double.infinity,
        color: FlowyTint.fromId(cover.value).color(context),
      );
    }

    if (type == PageStyleCoverImageType.gradientColor) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: FlowyGradientColor.fromId(cover.value).linear,
        ),
      );
    }

    if (type == PageStyleCoverImageType.localImage) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.file(
          File(cover.value),
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      height: naviBarHeight,
      width: double.infinity,
    );
  }
}
