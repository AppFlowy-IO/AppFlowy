import 'dart:async';
import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/base/mobile_view_page_bloc.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/unsplash_image_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_cover_bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/feedback_gesture_detector.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/shared/permission/permission_checker.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flowy_infra/theme_extension.dart';

class PageStyleCoverImage extends StatelessWidget {
  PageStyleCoverImage({
    super.key,
  });

  late final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.pageStyleBackgroundColor;
    return BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildOptionGroup(context, backgroundColor, state),
            const VSpace(16.0),
            _buildPreview(context, state),
          ],
        );
      },
    );
  }

  Widget _buildOptionGroup(
    BuildContext context,
    Color backgroundColor,
    DocumentPageStyleState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(12),
          right: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          _CoverOptionButton(
            showLeftCorner: true,
            showRightCorner: false,
            selected: state.coverImage.isPresets,
            onTap: () => _showPresets(context),
            child: const _PresetCover(),
          ),
          _CoverOptionButton(
            showLeftCorner: false,
            showRightCorner: false,
            selected: state.coverImage.isPhoto,
            onTap: () => _pickImage(context),
            child: const _PhotoCover(),
          ),
          _CoverOptionButton(
            showLeftCorner: false,
            showRightCorner: true,
            selected: state.coverImage.isUnsplashImage,
            onTap: () => _showUnsplash(context),
            child: const _UnsplashCover(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    DocumentPageStyleState state,
  ) {
    final cover = state.coverImage;
    if (cover.isNone) {
      return const SizedBox.shrink();
    }

    final value = cover.value;
    final type = cover.type;

    Widget preview = const SizedBox.shrink();

    if (type == PageStyleCoverImageType.customImage ||
        type == PageStyleCoverImageType.unsplashImage) {
      final userProfilePB =
          context.read<MobileViewPageBloc>().state.userProfilePB;
      preview = FlowyNetworkImage(
        url: value,
        userProfilePB: userProfilePB,
      );
    }

    if (type == PageStyleCoverImageType.builtInImage) {
      preview = Image.asset(
        PageStyleCoverImageType.builtInImagePath(value),
        fit: BoxFit.cover,
      );
    }

    if (type == PageStyleCoverImageType.pureColor) {
      final color = value.coverColor(context);
      if (color != null) {
        preview = ColoredBox(
          color: color,
        );
      }
    }

    if (type == PageStyleCoverImageType.gradientColor) {
      preview = Container(
        decoration: BoxDecoration(
          gradient: FlowyGradientColor.fromId(value).linear,
        ),
      );
    }

    if (type == PageStyleCoverImageType.localImage) {
      preview = Image.file(
        File(value),
        fit: BoxFit.cover,
      );
    }

    return Row(
      children: [
        FlowyText(LocaleKeys.pageStyle_image.tr()),
        const Spacer(),
        Container(
          width: 40,
          height: 28,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6.0)),
            border: Border.all(color: const Color(0x1F222533)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
            child: preview,
          ),
        ),
      ],
    );
  }

  void _showPresets(BuildContext context) {
    final pageStyleBloc = context.read<DocumentPageStyleBloc>();

    context.pop();

    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      showDoneButton: true,
      showHeader: true,
      showRemoveButton: true,
      onRemove: () {
        pageStyleBloc.add(
          DocumentPageStyleEvent.updateCoverImage(
            PageStyleCover.none(),
          ),
        );
      },
      title: LocaleKeys.pageStyle_presets.tr(),
      backgroundColor: AFThemeExtension.of(context).background,
      builder: (_) {
        return BlocProvider.value(
          value: pageStyleBloc,
          child: const PageCoverBottomSheet(),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final photoPermission =
        await PermissionChecker.checkPhotoPermission(context);
    if (!photoPermission) {
      Log.error('Has no permission to access the photo library');
      return;
    }

    XFile? result;
    try {
      result = await _imagePicker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      Log.error('Error while picking image: $e');
      return;
    }

    final path = result?.path;
    if (path != null && context.mounted) {
      final String? result;
      final userProfile = await UserBackendService.getCurrentUserProfile().fold(
        (s) => s,
        (f) => null,
      );
      final isAppFlowyCloud =
          userProfile?.authenticator == AuthenticatorPB.AppFlowyCloud;
      final PageStyleCoverImageType type;
      if (!isAppFlowyCloud) {
        result = await saveImageToLocalStorage(path);
        type = PageStyleCoverImageType.localImage;
      } else {
        // else we should save the image to cloud storage
        (result, _) = await saveImageToCloudStorage(path);
        type = PageStyleCoverImageType.customImage;
      }
      if (!context.mounted) {
        return;
      }
      if (result == null) {
        showSnapBar(
          context,
          LocaleKeys.document_plugins_image_imageUploadFailed,
        );
        return;
      }

      context.read<DocumentPageStyleBloc>().add(
            DocumentPageStyleEvent.updateCoverImage(
              PageStyleCover(
                type: type,
                value: result,
              ),
            ),
          );
    }
  }

  void _showUnsplash(BuildContext context) {
    final pageStyleBloc = context.read<DocumentPageStyleBloc>();
    context.pop();

    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      showDoneButton: true,
      showHeader: true,
      showRemoveButton: true,
      title: LocaleKeys.pageStyle_unsplash.tr(),
      backgroundColor: AFThemeExtension.of(context).background,
      onRemove: () {
        pageStyleBloc.add(
          DocumentPageStyleEvent.updateCoverImage(
            PageStyleCover.none(),
          ),
        );
      },
      builder: (_) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            minHeight: 80,
          ),
          child: BlocProvider.value(
            value: context.read<DocumentPageStyleBloc>(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: UnsplashImageWidget(
                type: UnsplashImageType.fullScreen,
                onSelectUnsplashImage: (url) {
                  pageStyleBloc.add(
                    DocumentPageStyleEvent.updateCoverImage(
                      PageStyleCover(
                        type: PageStyleCoverImageType.unsplashImage,
                        value: url,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnsplashCover extends StatelessWidget {
  const _UnsplashCover();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FlowySvg(FlowySvgs.m_page_style_unsplash_m),
        const VSpace(4.0),
        FlowyText(
          LocaleKeys.pageStyle_unsplash.tr(),
          fontSize: 12.0,
        ),
      ],
    );
  }
}

class _PhotoCover extends StatelessWidget {
  const _PhotoCover();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FlowySvg(FlowySvgs.m_page_style_photo_m),
        const VSpace(4.0),
        FlowyText(
          LocaleKeys.pageStyle_photo.tr(),
          fontSize: 12.0,
        ),
      ],
    );
  }
}

class _PresetCover extends StatelessWidget {
  const _PresetCover();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FlowySvg(
          FlowySvgs.m_page_style_presets_m,
          blendMode: null,
        ),
        const VSpace(4.0),
        FlowyText(
          LocaleKeys.pageStyle_presets.tr(),
          fontSize: 12.0,
        ),
      ],
    );
  }
}

class _CoverOptionButton extends StatelessWidget {
  const _CoverOptionButton({
    required this.showLeftCorner,
    required this.showRightCorner,
    required this.child,
    required this.onTap,
    required this.selected,
  });

  final Widget child;
  final bool showLeftCorner;
  final bool showRightCorner;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FeedbackGestureDetector(
        feedbackType: HapticFeedbackType.medium,
        onTap: onTap,
        child: AnimatedContainer(
          height: 64,
          duration: Durations.medium1,
          decoration: selected
              ? ShapeDecoration(
                  color: const Color(0x141AC3F2),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1.50,
                      color: Color(0xFF1AC3F2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                )
              : null,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
