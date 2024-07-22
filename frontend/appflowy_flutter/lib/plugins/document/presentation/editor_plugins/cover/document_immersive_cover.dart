import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/build_context_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/icon/icon_selector.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon_bloc.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

double kDocumentCoverHeight = 98.0;
double kDocumentTitlePadding = 20.0;

class DocumentImmersiveCover extends StatefulWidget {
  const DocumentImmersiveCover({
    super.key,
    required this.view,
    required this.userProfilePB,
  });

  final ViewPB view;
  final UserProfilePB userProfilePB;

  @override
  State<DocumentImmersiveCover> createState() => _DocumentImmersiveCoverState();
}

class _DocumentImmersiveCoverState extends State<DocumentImmersiveCover> {
  final textEditingController = TextEditingController();
  final scrollController = ScrollController();
  final focusNode = FocusNode();

  late PropertyValueNotifier<Selection?>? selectionNotifier =
      context.read<DocumentBloc>().state.editorState?.selectionNotifier;

  @override
  void initState() {
    super.initState();
    selectionNotifier?.addListener(_unfocus);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    scrollController.dispose();
    selectionNotifier?.removeListener(_unfocus);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnoreParentGestureWidget(
      child: BlocProvider(
        create: (context) => DocumentImmersiveCoverBloc(view: widget.view)
          ..add(const DocumentImmersiveCoverEvent.initial()),
        child: BlocConsumer<DocumentImmersiveCoverBloc,
            DocumentImmersiveCoverState>(
          listener: (context, state) {
            if (textEditingController.text.isEmpty) {
              textEditingController.text = state.name;
            }
          },
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
    final icon = state.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (icon != null && icon.isNotEmpty) ...[
            _buildIcon(context, icon),
            const HSpace(8.0),
          ],
          Expanded(child: _buildTitle(context, state)),
        ],
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    DocumentImmersiveCoverState state,
  ) {
    String? fontFamily = defaultFontFamily;
    final documentFontFamily =
        context.read<DocumentPageStyleBloc>().state.fontFamily;
    if (documentFontFamily != null && fontFamily != documentFontFamily) {
      fontFamily = getGoogleFontSafely(documentFontFamily).fontFamily;
    }

    return AutoSizeTextField(
      controller: textEditingController,
      focusNode: focusNode,
      minFontSize: 18.0,
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: '',
        contentPadding: EdgeInsets.zero,
      ),
      scrollController: scrollController,
      style: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
        color:
            state.cover.isNone || state.cover.isPresets ? null : Colors.white,
        overflow: TextOverflow.ellipsis,
      ),
      onChanged: (name) => Debounce.debounce(
        'rename',
        const Duration(milliseconds: 300),
        () => _rename(name),
      ),
      onSubmitted: (name) => Debounce.debounce(
        'rename',
        const Duration(milliseconds: 300),
        () => _rename(name),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, String icon) {
    return GestureDetector(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 34.0),
        child: EmojiIconWidget(
          emoji: icon,
          emojiSize: 26,
        ),
      ),
      onTap: () async {
        final pageStyleIconBloc = PageStyleIconBloc(view: widget.view)
          ..add(const PageStyleIconEvent.initial());
        await showMobileBottomSheet(
          context,
          showDragHandle: true,
          showDivider: false,
          showDoneButton: true,
          showHeader: true,
          title: LocaleKeys.titleBar_pageIcon.tr(),
          backgroundColor: AFThemeExtension.of(context).background,
          enableDraggableScrollable: true,
          minChildSize: 0.6,
          initialChildSize: 0.61,
          showRemoveButton: true,
          onRemove: () {
            pageStyleIconBloc.add(
              const PageStyleIconEvent.updateIcon('', true),
            );
          },
          scrollableWidgetBuilder: (_, controller) {
            return BlocProvider.value(
              value: pageStyleIconBloc,
              child: Expanded(
                child: Scrollbar(
                  controller: controller,
                  child: IconSelector(
                    scrollController: controller,
                  ),
                ),
              ),
            );
          },
          builder: (_) => const SizedBox.shrink(),
        );
      },
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
        child: FlowyNetworkImage(
          url: cover.value,
          userProfilePB: widget.userProfilePB,
        ),
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
        color: cover.value.coverColor(context),
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

  void _unfocus() {
    final selection = selectionNotifier?.value;
    if (selection != null) {
      focusNode.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    }
  }

  void _rename(String name) {
    scrollController.position.jumpTo(0);
    context.read<ViewBloc>().add(ViewEvent.rename(name));
  }
}
